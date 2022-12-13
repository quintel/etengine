class AddPrivateAttributeToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :private, :boolean, default: false, after: :user_id
  end
end
