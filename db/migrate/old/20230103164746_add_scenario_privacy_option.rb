class AddScenarioPrivacyOption < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :private_scenarios, :boolean, default: false, after: :name
  end
end
