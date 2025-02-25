class SetActiveStorageVariantRecordsCollation < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      alter table active_storage_variant_records
      convert to character set utf8mb4 collate utf8mb4_unicode_ci
    SQL

    # This is already the case for most installs.
    execute <<~SQL
      alter database #{ActiveRecord::Base.connection.current_database}
      character set utf8mb4 collate utf8mb4_unicode_ci
    SQL
  end

  def down
    execute <<~SQL
      alter table active_storage_variant_records
      convert to character set utf8mb4 collate utf8mb4_0900_ai_ci
    SQL
  end
end
