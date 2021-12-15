class RenameNl2019DatasetToNl < ActiveRecord::Migration[5.2]
  def up
    say_with_time 'Rename nl dataset to nl2015' do
      Scenario.where(area_code: 'nl').update_all(area_code: 'nl2015')
    end

    say_with_time 'Rename nl2019 dataset to nl' do
      Scenario.where(area_code: 'nl2019').update_all(area_code: 'nl')
    end
  end

  def down
    say_with_time 'Rename nl dataset to nl2019' do
      Scenario.where(area_code: 'nl').update_all(area_code: 'nl2019')
    end

    say_with_time 'Rename nl2015 dataset to nl' do
      Scenario.where(area_code: 'nl2015').update_all(area_code: 'nl')
    end
  end
end
