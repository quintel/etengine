# frozen_string_literal: true

module ScenarioPacker
  class Load
    # Creates a new Scenario API loader.
    #
    # Loading through here will skip a lot of validations
    # json_data - Hash containing scenario data
    # user_id   - Optional ID of user to assign as owner
    def initialize(json_data, user_id: nil)
      @data = json_data
      @user_id = user_id
      @scenario = Scenario.new(
        @data.slice(*scenario_attributes)
      )
      @scenario.active_couplings = @data[:active_couplings].map(&:to_sym)
    end

    def scenario
      create_sortables
      create_curves
      build_owner if @user_id
      @scenario.save!
      @scenario
    end

    def scenario_attributes
      %i[
        area_code end_year private keep_compatible
        user_values balanced_values metadata
      ]
    end

    def create_sortables
      @data['user_sortables'].each do |class_name, order|
        if class_name == 'HeatNetworkOrder'
          order.each { |attrs| @scenario.heat_network_orders << HeatNetworkOrder.new(attrs) }
        else
          @scenario.public_send(:"#{class_name.underscore}=", class_name.constantize.new(order))
        end
      end
    end

    def create_curves
      @data['user_curves'].each do |key, curve|
        @scenario.user_curves << UserCurve.new(key:, curve:)
      end
    end

    def build_owner


      user = User.find_by(id: @user_id)
      unless user
        Rails.logger.warn("ScenarioPacker::Load: User with id #{@user_id} not found. Owner assignment skipped.")
        return
      end

      @scenario.scenario_users.build(
        user: user,
        role_id: User::ROLES.key(:scenario_owner)
      )
    end
  end
end
