class SetMysqlCollationToUtf8mb4Unicode < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.adapter_name.downcase =~ /^mysql/
      return
    end

    reversible do |dir|
      dir.up do
        # Indexed VARCHAR columns must have length 191 or less when using MySQL
        # 5.6 or older (*cough* Semaphore). https://stackoverflow.com/a/31474509
        change_column :active_storage_attachments, :name, :string, limit: 191
        change_column :active_storage_attachments, :record_type, :string, limit: 191
        change_column :active_storage_blobs, :key, :string, limit: 191

        update_collation!('utf8mb4_unicode_ci')

        # Updating to mb4 switches TEXT columns to MEDIUMTEXT. This isn't needed
        # for commit messages.
        limit = 64.kilobytes - 1

        change_column :active_storage_blobs, :metadata, :text, limit: limit
        change_column :flexibility_orders, :order, :text, limit: limit
        change_column :gquery_groups, :description, :text, limit: limit
        change_column :query_table_cells, :gquery, :text, limit: limit
        change_column :query_tables, :description, :text, limit: limit
        change_column :scenarios, :description, :text, limit: limit
      end

      dir.down do
        update_collation!('utf8mb4_general_ci')
      end
    end
  end

  private

  def update_collation!(collation)
    say_with_time 'Updating database' do
      ActiveRecord::Base.connection.execute(<<~SQL)
        ALTER DATABASE #{ActiveRecord::Base.connection.current_database}
        CHARACTER SET = utf8mb4
        COLLATE = #{collation}
      SQL
    end

    ActiveRecord::Base.connection.tables.each do |table|
      say_with_time "Updating #{table}" do
        ActiveRecord::Base.connection.execute(<<~SQL)
          ALTER TABLE #{table}
          CONVERT TO CHARACTER SET utf8mb4
          COLLATE #{collation}
        SQL
      end
    end
  end
end
