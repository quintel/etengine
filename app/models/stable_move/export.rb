# frozen_string_literal: true

module StableMove
  # Writes the scenarios of a stable move plan, written by MyETM's stable_move:plan, to a file for
  # StableMove::Import: their rows as they are in the database, every row of the related tables, and
  # the files behind their attachments. Reads only. Ids are kept: the stable version's engine starts
  # empty, so they are free there.
  #
  # Two things change on the way. A preset, curve source or attachment source that doesn't move with
  # the scenario is cleared, and the scenarios MyETM protects are written with keep_compatible.
  #
  # The file is a gzipped MessagePack stream: a header, the rows of each table in batches, the
  # attachment files, and an end record with the counts, so that a truncated file is refused.
  class Export
    FORMAT = 1
    SLICE = 500
    ATTACHMENT_TYPE = 'ScenarioAttachment'

    def initialize(plan, io)
      @plan = plan
      @io = io
      @ids = plan.dig('engine', 'scenario_ids').map(&:to_i)
      @moving = @ids.to_set
      @protected = plan.dig('engine', 'protect').to_set(&:to_i)
      @counts = Hash.new(0)
    end

    # Returns a report of what was written, what is missing and where MyETM and the engine disagree.
    def call
      unless @plan['from_version'] == Settings.version_tag
        raise Error, "The plan moves scenarios from #{@plan['from_version']}, " \
                     "this engine is #{Settings.version_tag}"
      end

      gzip = Zlib::GzipWriter.new(@io)
      @packer = MessagePack::Packer.new(gzip)

      write(header)
      areas = write_scenarios
      attachment_ids = write_related
      missing_files = write_storage(attachment_ids)
      write('type' => 'end', 'counts' => @counts)

      gzip.finish
      report(areas, missing_files)
    end

    private

    def header
      {
        'type' => 'header',
        'format' => FORMAT,
        'from_version' => Settings.version_tag,
        'version' => @plan['version'],
        'version_hidden' => @plan['version_hidden'],
        'exported_at' => Time.now.utc.iso8601,
        'scenario_ids' => @ids,
        'roles' => @plan.dig('engine', 'roles'),
        'tables' => Tables.all.index_with { |table| connection.columns(table).map(&:name) }
      }
    end

    # Returns the area code of every scenario found, by id.
    def write_scenarios
      areas = {}

      write_rows('scenarios', 'id', @ids) do |columns, rows|
        id, area, preset, keep =
          columns.values_at('id', 'area_code', 'preset_scenario_id', 'keep_compatible')

        rows.each do |row|
          areas[row[id].to_i] = row[area]
          row[preset] = nil if row[preset] && @moving.exclude?(row[preset].to_i)
          row[keep] = '1' if @protected.include?(row[id].to_i)
        end
      end

      areas
    end

    # Returns the ids of the scenario attachments written.
    def write_related
      attachment_ids = []

      Tables.related.each do |table|
        write_rows(table, 'scenario_id', @ids) do |columns, rows|
          source = columns['source_scenario_id']

          rows.each do |row|
            row[source] = nil if source && row[source] && @moving.exclude?(row[source].to_i)
          end

          next unless table == 'scenario_attachments'

          attachment_ids.concat(rows.map { |row| row[columns['id']].to_i })
        end
      end

      attachment_ids
    end

    # Writes the blobs, attachments and variants of the scenario attachments, then the files.
    # Returns the keys of the blobs whose file is gone.
    def write_storage(attachment_ids)
      attachments = ActiveStorage::Attachment.where(record_type: ATTACHMENT_TYPE)
      blob_ids = attachment_ids.each_slice(SLICE).flat_map do |ids|
        attachments.where(record_id: ids).pluck(:blob_id)
      end

      write_rows('active_storage_blobs', 'id', blob_ids)
      write_rows(
        'active_storage_attachments', 'record_id', attachment_ids,
        "record_type = '#{ATTACHMENT_TYPE}'"
      )

      if Tables.storage.include?('active_storage_variant_records')
        write_rows('active_storage_variant_records', 'blob_id', blob_ids)
      end

      write_files(blob_ids)
    end

    def write_files(blob_ids)
      missing = []

      ActiveStorage::Blob.where(id: blob_ids).find_each do |blob|
        write(
          'type' => 'file',
          'service' => blob.service_name,
          'key' => blob.key,
          'checksum' => blob.checksum,
          'data' => blob.download
        )
        @counts['files'] += 1
      rescue ActiveStorage::FileNotFoundError
        missing << blob.key
      end

      missing
    end

    # Writes the rows of a table whose column is in the ids, a slice at a time, uncast so they are
    # written back byte for byte. The block may change a slice's rows before they're written; it
    # receives the column positions by name.
    def write_rows(table, column, ids, condition = nil)
      ids.each_slice(SLICE) do |slice|
        sql = "SELECT * FROM #{connection.quote_table_name(table)} " \
              "WHERE #{connection.quote_column_name(column)} IN (#{slice.map(&:to_i).join(',')})"
        sql += " AND #{condition}" if condition

        result = connection.raw_connection.query(sql, as: :array, cast: false)
        rows = result.to_a
        next if rows.empty?

        yield(result.fields.each_with_index.to_h, rows) if block_given?

        write('type' => 'rows', 'table' => table, 'columns' => result.fields, 'rows' => rows)
        @counts[table] += rows.size
      end
    end

    def write(message)
      @packer.write(message).flush
    end

    def report(areas, missing_files)
      area_codes = @plan.dig('engine', 'area_codes')

      {
        'scenarios' => @ids.size,
        'missing_scenarios' => (@ids - areas.keys).sort,
        'area_mismatches' => area_codes.filter_map do |id, area|
          found = areas[id.to_i]
          { 'scenario_id' => id.to_i, 'myetm' => area, 'engine' => found } if found && found != area
        end,
        'rows' => @counts.except('files'),
        'files' => @counts['files'],
        'missing_files' => missing_files
      }
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
