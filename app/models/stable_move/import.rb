# frozen_string_literal: true

module StableMove
  # Replaces the scenarios in this engine with those in a file written by StableMove::Export, keeping
  # their ids and rows as they are, then gives the current scenario of each moved saved scenario the
  # users MyETM has for it. Copying the engine's own roles is not enough: most of them predate
  # ETEngine roles, so they have none.
  #
  # Every scenario here is deleted first, so the ids in the file are free: those not in the file are
  # the hidden period's test data. Once the version is shown they're users' scenarios, so the import
  # only accepts a file whose plan MyETM made while the version was hidden. Everything happens in
  # one transaction, so a failed import leaves the database as it was.
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

    # Returns a report of what was replaced and imported, and the scenarios whose roles failed.
    def call
      @unpacker = MessagePack::Unpacker.new(Zlib::GzipReader.new(@io))
      header = read
      check!(header)

      others = Scenario.where.not(id: header['scenario_ids']).count
      replaced = nil
      role_failures = nil

      ActiveRecord::Base.transaction do
        replaced = delete_all
        import_messages
        role_failures = apply_roles(header['roles'])
      end

      delete_files(replaced[:files])
      report(replaced[:scenarios], others, header['roles'], role_failures)
    end

    private

    def check!(header)
      raise Error, 'Not a stable move export' unless header['type'] == 'header'

      unless header['format'] == Export::FORMAT
        raise Error, "Unknown export format #{header['format']}"
      end

      unless header['version'] == Settings.version_tag
        raise Error, "The file moves scenarios to #{header['version']}, " \
                     "this engine is #{Settings.version_tag}"
      end

      unless header['version_hidden'] == true
        raise Error, "The file's plan was not made while #{header['version']} was hidden"
      end

      missing = header['tables'].flat_map do |table, columns|
        next ["#{table} (table)"] unless connection.table_exists?(table)

        (columns - connection.columns(table).map(&:name)).map { |name| "#{table}.#{name}" }
      end

      return if missing.empty?

      raise Error, "This engine's schema lacks what the file holds: #{missing.join(', ')}"
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
        else raise Error, "Unknown record #{message['type']}"
        end
      end

      return if message['counts'] == @counts

      raise Error, "The file says it holds #{message['counts']}, it held #{@counts}"
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

    # Roles are set the way MyETM sets them when a saved scenario is created: they are added or
    # updated, never removed. Returns the scenarios whose roles failed.
    def apply_roles(roles)
      failures = []

      Scenario.where(id: roles.keys.map(&:to_i)).find_each do |scenario|
        scenario.sync_users_from_params(roles[scenario.id.to_s])
      rescue ActiveRecord::ActiveRecordError => e
        failures << { 'scenario_id' => scenario.id, 'error' => e.message }
      end

      failures
    end

    def delete_files(files)
      files.each do |service, key|
        ActiveStorage::Blob.services.fetch(service).delete(key) unless @uploaded.include?(key)
      end
    end

    def report(replaced, wiped, roles, role_failures)
      owner = User::ROLES.key(:scenario_owner)
      owned = ScenarioUser.where(scenario_id: roles.keys.map(&:to_i), role_id: owner)
        .distinct.count(:scenario_id)

      {
        'deleted_scenarios' => replaced,
        'of_which_not_in_file' => wiped,
        'rows' => @counts.except('files'),
        'files' => @counts['files'],
        'roles' => {
          'scenarios' => roles.size,
          'without_owner' => roles.size - owned,
          'failures' => role_failures
        }
      }
    end

    def read
      @unpacker.read
    rescue EOFError
      raise Error, 'The file ends early'
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
