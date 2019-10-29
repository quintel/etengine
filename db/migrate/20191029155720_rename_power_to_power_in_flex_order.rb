class RenamePowerToPowerInFlexOrder < ActiveRecord::Migration[5.2]
  def up
    num = FlexibilityOrder.count
    changed = 0

    FlexibilityOrder.find_each.with_index do |fo, index|
      if index > 0 && (index % 100).zero?
        puts "#{index}/#{num} - #{changed} changed"
      end

      unless replace(fo.order, :power_to_power, :household_batteries) ||
          replace(fo.order, 'power_to_power', 'household_batteries')
        next
      end

      fo.save(touch: false, validate: false)
      changed += 1
    end

    puts "Finished - #{changed} changed"
  end

  def down
    ActiveRecord::IrreversibleMigration
  end

  private

  def replace(order, from, to)
    index = order.index(from)
    index && order[index] = to
  end
end
