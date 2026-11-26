# frozen_string_literal: true

module StableMove
  # Replaces the scenarios in this engine with those in a file written by StableMove::Export, keeping
  # their ids and rows as they are.
  #
  # Every scenario here is deleted first, so the ids in the file are free: those not in the file are
  # the hidden period's test data. Once the version is shown they're users' scenarios: MyETM only
  # plans a move to a hidden version, and the import refuses while a scenario here was created or
  # changed after the export. Everything happens in one transaction, so a failed import leaves the
  # database as it was.
  class Import
    MAX_STATEMENT = 4.megabytes
    ATTACHMENT_TYPE = Export::ATTACHMENT_TYPE

    # The column of each ActiveStorage table that holds a scenario attachment's blob id.
    BLOB_COLUMNS = {
      'active_storage_blobs' => 'id',
      'active_storage_attachments' => 'blob_id',
      'active_storage_variant_records' => 'blob_id'
    }.freeze

    def initialize(io)
      @io = io
      @counts = Hash.new(0)
      @uploaded = Set.new
    end

    # Returns what the import would delete and bring, as lines of text for a person to confirm.
    # Reads only the file's header, and refuses what the import refuses.
    def preview
      header = start
      ids = header['scenario_ids']

      [
        "Importing into #{header['version']} the export from #{header['from_version']} " \
        "made at #{header['exported_at']}",
        '',
        "Scenarios in the file: #{header['scenarios_found']} of the plan's #{ids.size}",
        '',
        *cleanup_lines(Scenario.count, Scenario.where.not(id: ids).count)
      ]
    end

    # Returns a report of what was replaced and imported, as lines of text.
    def call
      header = start
      others = Scenario.where.not(id: header['scenario_ids']).count
      replaced = nil

      ActiveRecord::Base.transaction do
        replaced = delete_all
        import_messages
      end

      delete_files(replaced[:files])
      report(replaced[:scenarios], others)
    end

    private

    # Reads the file's header and checks that the file can be imported here. Returns the header.
    def start
      @unpacker = MessagePack::Unpacker.new(Zlib::GzipReader.new(@io))

      read.tap do |header|
        check!(header)
        check_newer!(Time.iso8601(header['exported_at']))
      end
    end

    def check!(header)
      raise Error, 'the file is not a stable move export' unless header['type'] == 'header'

      unless header['code_fingerprint'] == Export.code_fingerprint
        raise Error, 'this engine runs other move code than the engine that exported the file. ' \
                     'Deploy the same code to both, then export and import again'
      end

      unless header['version'] == Settings.version_tag
        raise Error, "the file moves scenarios to #{header['version']}, " \
                     "this engine is #{Settings.version_tag}"
      end

      missing = header['tables'].flat_map do |table, columns|
        next ["#{table} (table)"] unless connection.table_exists?(table)

        (columns - connection.columns(table).map(&:name)).map { |name| "#{table}.#{name}" }
      end

      return if missing.empty?

      raise Error, [
        "this engine's schema lacks what the file holds.",
        '',
        "Missing here: #{missing.size}",
        *Error.listing(missing),
        '',
        "Bring this engine's schema level with the one the file came from, then import again."
      ].join("\n")
    end

    def check_newer!(exported_at)
      newer = Scenario.where('created_at > :at OR updated_at > :at', at: exported_at)
      count = newer.count
      return if count.zero?

      raise Error, [
        "scenarios here were created or changed after the export (#{exported_at.iso8601}).",
        '',
        "Scenarios newer than the export: #{count}",
        *Error.listing(newer.order(:id).limit(Error::LISTED).pluck(:id), count),
        '',
        'Delete them to import this file, or export again.'
      ].join("\n")
    end

    # Deletes every scenario, the rows that belong to them and their attachments' blobs. Returns
    # how many scenarios were deleted and the files to delete once the import is committed.
    def delete_all
      blob_ids = ActiveStorage::Attachment.where(record_type: ATTACHMENT_TYPE).pluck(:blob_id)
      files = ActiveStorage::Blob.where(id: blob_ids).pluck(:service_name, :key)

      Tables.storage.reverse_each do |table|
        blob_ids.each_slice(Export::SLICE) do |ids|
          connection.execute(
            "DELETE FROM #{connection.quote_table_name(table)} " \
            "WHERE #{BLOB_COLUMNS.fetch(table)} IN (#{ids.join(',')})"
          )
        end
      end

      Tables.related.each do |table|
        connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
      end

      { scenarios: Scenario.delete_all, files: }
    end

    def import_messages
      while (message = read)['type'] != 'end'
        case message['type']
        when 'rows' then insert(message['table'], message['columns'], message['rows'])
        when 'file' then upload(message)
        else raise Error, "the file holds an unknown record: #{message['type']}"
        end
      end

      return if message['counts'] == @counts

      raise Error, "the file says it holds #{message['counts']}, it held #{@counts}"
    end

    def insert(table, columns, rows)
      binary = connection.columns(table).select { |column| column.type == :binary }.map(&:name)
      binary_at = columns.each_index.select { |index| binary.include?(columns[index]) }.to_set
      names = columns.map { |column| connection.quote_column_name(column) }
      prefix = "INSERT INTO #{connection.quote_table_name(table)} (#{names.join(', ')}) VALUES "

      values = []
      size = 0

      rows.each do |row|
        quoted = row.each_with_index.map { |value, index| quote(value, binary_at.include?(index)) }
        tuple = "(#{quoted.join(', ')})"
        values << tuple
        size += tuple.bytesize

        next if size < MAX_STATEMENT

        connection.execute(prefix + values.join(', '))
        values = []
        size = 0
      end

      connection.execute(prefix + values.join(', ')) if values.any?
      @counts[table] += rows.size
    end

    def quote(value, binary)
      return 'NULL' if value.nil?
      return "x'#{value.unpack1('H*')}'" if binary

      connection.quote(value)
    end

    def upload(message)
      ActiveStorage::Blob.services.fetch(message['service'])
        .upload(message['key'], StringIO.new(message['data']), checksum: message['checksum'])

      @uploaded << message['key']
      @counts['files'] += 1
    end

    def delete_files(files)
      files.each do |service, key|
        ActiveStorage::Blob.services.fetch(service).delete(key) unless @uploaded.include?(key)
      end
    end

    def report(replaced, others)
      rows = @counts.except('files')

      [
        *cleanup_lines(replaced, others),
        '',
        "Rows imported: #{rows.values.sum}",
        *rows.map { |table, count| "   - #{count} #{table}" },
        '',
        "Attachment files imported: #{@counts['files']}"
      ]
    end

    def cleanup_lines(deleted, others)
      [
        "#{Settings.version_tag} cleanup in ETEngine (created while hidden): #{deleted}",
        "   - #{deleted - others} in the plan: replaced by their copy in the file",
        "   - #{others} not in the plan: test data, deleted"
      ]
    end

    def read
      @unpacker.read
    rescue EOFError
      raise Error, 'the file ends early'
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
