class SplitProtectedIntoTwoAttributes < ActiveRecord::Migration[7.0]
  def up
    change_table :scenarios do |t|
      t.boolean :api_read_only, default: false, after: :end_year
      t.boolean :keep_compatible,  default: false, after: :api_read_only
    end

    Scenario.reset_column_information

    say_with_time 'Updating attributes for scenarios' do
      Scenario
        .where(protected: true)
        .update_all(api_read_only: true, keep_compatible: true)
    end

    remove_column :scenarios, :protected
  end

  def down
    change_table :scenarios do |t|
      t.boolean :protected, default: false, after: :present_updated_at
    end

    Scenario.reset_column_information

    say_with_time 'Updating attributes for scenarios' do
      Scenario
        .where(api_read_only: true)
        .or(Scenario.where(keep_compatible: true))
        .update_all(protected: true)
    end

    remove_column :scenarios, :api_read_only
    remove_column :scenarios, :keep_compatible
  end
end
