class MigrateMarketShareInputs < ActiveRecord::Migration
  def self.up
    Input.find(383).update_attribute :keys, 'gas_fired_heater_buildings_energetic'
    
    Gql::UpdateInterface::MarketShareCommand::UPDATES.each do |key, opts|
      Input.where(:attr_name => key).each do |input|
        base, flex = opts

        query = 
          "EACH(
            UPDATE(LINK(#{input.keys},#{base}), share, DIVIDE(USER_INPUT(),100)),
            UPDATE(LINK(#{base},#{flex}), share, 
              SUM(NEG(SUM(V(EXCLUDE(INPUT_LINKS(V(#{base})),UPDATE_COLLECTION()); share))), 1)
            )
          )"
        # The following statement can be removed when the remainder link is changed to a flexible link
        # else
        #   "UPDATE(LINK(#{input.keys},#{base}), share, DIVIDE(USER_INPUT(),100))"
        # end
        input.query = query
        input.save!
      end
    end
  end

  def self.down
    Gql::UpdateInterface::MarketShareCommand::UPDATES.each do |key, opts|
      Input.where(:attr_name => key).each do |input|
        input.update_attribute :query, nil
      end
    end
  end
end
