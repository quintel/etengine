class DisableMeritOrderInOldScenarios < ActiveRecord::Migration
  def up
    skey   = 'settings_enable_merit_order'
    ikey   = skey.to_sym
    count  = Scenario.count
    done   = 0
    updated = 0

    Scenario.find_each do |scenario|
      unless scenario.user_values.key?(skey) || scenario.user_values.key?(ikey)
        scenario.user_values[skey] = 0.0
        scenario.save(validate: false)
        updated += 1
      end

      done += 1

      if (done % 5000).zero?
        puts "Done #{ done } of #{ count } (#{ updated } updated)"
      end
    end

    puts "Finished (#{ updated } updated)"
  end

  def down
    # Nothing to do.
  end
end
