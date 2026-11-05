# frozen_string_literal: true

module StableMove
  # The tables a stable move copies besides scenarios, found from the schema so that a table added
  # later is copied too.
  module Tables
    STORAGE = %w[
      active_storage_blobs active_storage_attachments active_storage_variant_records
    ].freeze

    module_function

    # Every table with a scenario_id column. Each of their rows belongs to a scenario.
    def related(connection = ActiveRecord::Base.connection)
      connection.tables.sort.select do |table|
        table != 'scenarios' && connection.column_exists?(table, :scenario_id)
      end
    end

    # The ActiveStorage tables this database has, in the order their foreign keys need.
    def storage(connection = ActiveRecord::Base.connection)
      STORAGE.select { |table| connection.table_exists?(table) }
    end

    def all(connection = ActiveRecord::Base.connection)
      ['scenarios', *related(connection), *storage(connection)]
    end
  end
end
