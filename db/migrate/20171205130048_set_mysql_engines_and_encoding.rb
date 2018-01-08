class SetMysqlEnginesAndEncoding < ActiveRecord::Migration[5.1]
  def up
    unless ActiveRecord::Base.connection.adapter_name.downcase =~ /^mysql/
      return
    end

    # https://stackoverflow.com/a/31474509
    change_column :users, :trackable, :string, default: '0', limit: 191

    tables = %i(
      fce_values
      flexibility_orders
      gquery_groups
      query_table_cells
      query_tables
      roles
      scenario_scalings
      scenarios
      schema_migrations
      users
    )

    tables.each do |table|
      say_with_time "Updating #{table}" do
        ActiveRecord::Base.connection.execute(
          "ALTER TABLE `#{table}` ENGINE = InnoDB"
        )

        ActiveRecord::Base.connection.execute(
          "ALTER TABLE #{table} " \
          "CONVERT TO CHARACTER SET utf8mb4 " \
          "COLLATE utf8mb4_general_ci"
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
