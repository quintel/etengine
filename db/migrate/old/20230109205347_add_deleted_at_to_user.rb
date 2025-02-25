class AddDeletedAtToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :deleted_at, :datetime, null: true
  end
end
