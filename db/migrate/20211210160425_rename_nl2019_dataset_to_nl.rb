class RenameNl2019DatasetToNl < ActiveRecord::Migration[5.2]
  def up
    say_with_time 'Rename nl dataset to nl2015' do
      Scenario.connection.execute(<<-SQL)
        UPDATE scenarios
        SET area_code = 'nl2015'
        WHERE area_code = 'nl'
      SQL
    end

    say_with_time 'Rename nl2019 dataset to nl' do
      Scenario.connection.execute(<<-SQL)
        UPDATE scenarios
        SET area_code = 'nl'
        WHERE area_code = 'nl2019'
      SQL
    end
  end

  def down
    say_with_time 'Rename nl dataset to nl2019' do
      Scenario.connection.execute(<<-SQL)
        UPDATE scenarios
        SET area_code = 'nl2019'
        WHERE area_code = 'nl'
      SQL
    end

    say_with_time 'Rename nl2015 dataset to nl' do
      Scenario.connection.execute(<<-SQL)
        UPDATE scenarios
        SET area_code = 'nl'
        WHERE area_code = 'nl2015'
      SQL
    end
  end
end
