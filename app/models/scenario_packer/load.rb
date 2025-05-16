module ScenarioPacker
  class Load
    # Creates a new Scenario API loader.
    #
    # Loading through here will skip a lot of validations
    def initialize(json_data)
      @data = json_data
      @scenario = Scenario.new(
        @data.slice(*scenario_attributes)
      )
      @scenario.active_couplings = @data[:active_couplings].map(&:to_sym)
    end

    def scenario
      create_sortables
      create_curves

      @scenario.save!

      @scenario
    end

    def scenario_attributes
      %i[
        area_code end_year private keep_compatible
        user_values balanced_values
      ]
    end

    def create_sortables
      @data['user_sortables'].each do |class_name, order|
        if class_name == "HeatNetworkOrder"
          order.each { |attrs| @scenario.heat_network_orders << HeatNetworkOrder.new(attrs)}
        else
          @scenario.public_send(:"#{class_name.underscore}=", class_name.constantize.new(order))
        end
      end
    end

    def create_curves
      @data['user_curves'].each do |key, curve|
        @scenario.user_curves << UserCurve.new(key: key, curve: curve)
      end
    end
  end
end
