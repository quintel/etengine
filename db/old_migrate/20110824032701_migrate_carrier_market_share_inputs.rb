class MigrateCarrierMarketShareInputs < ActiveRecord::Migration
  def self.up
    Gql::UpdateInterface::MarketShareCarrierCommand::UPDATES.each do |key, opts|
      Input.where(:attr_name => key).each do |input|
        base, flex = opts

        query = "UPDATE(LINK(#{input.keys},#{base}), share, DIVIDE(USER_INPUT(),100))"
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
    Gql::UpdateInterface::MarketShareCarrierCommand::UPDATES.each do |key, opts|
      Input.where(:attr_name => key).each do |input|
        input.update_attribute :query, nil
      end
    end
  end
end
