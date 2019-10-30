class CastFlexibilityOrdersToStrings < ActiveRecord::Migration[5.2]
  def up
    orders = FlexibilityOrder.where('flexibility_orders.order LIKE ?', '%- :%')
    num = orders.count
    changed = 0

    orders.find_each.with_index do |fo, index|
      if index > 0 && (index % 100).zero?
        puts "#{index}/#{num} - #{changed} changed"
      end

      fo.order = fo.order.map(&:to_s)

      fo.save(touch: false, validate: false)
      changed += 1
    end

    puts "Finished - #{changed} changed"
  end

  def down
    ActiveRecord::IrreversibleMigration
  end
end
