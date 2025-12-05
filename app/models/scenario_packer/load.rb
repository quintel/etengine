# frozen_string_literal: true

module ScenarioPacker
  class Load
    include Dry::Monads[:result]

    # Creates a new Scenario API loader.
    #
    # json_data - Hash containing scenario data
    # user_id   - Optional ID of user to assign as owner
    def initialize(json_data, user_id: nil)
      @data = json_data
      @user_id = user_id
      @scenario = Scenario.new(@data.slice(*scenario_attributes))
      if @data[:active_couplings]
        @scenario.active_couplings = @data[:active_couplings].map(&:to_sym)
      end
    end

    # Result-based API
    def call
      validate_data
        .bind { |_| create_sortables(@scenario) }
        .bind { |scenario| create_curves(scenario) }
        .bind { |scenario| build_owner(scenario) }
        .bind { |scenario| save_scenario(scenario) }
    end

    private

    def validate_data
      return Failure('json_data is required') if @data.nil?
      return Failure('json_data must be a hash') unless @data.is_a?(Hash)

      Success(@data)
    end

    def save_scenario(scenario)
      scenario.save!
      Success(scenario)
    rescue ActiveRecord::RecordInvalid => e
      Failure("Failed to save scenario: #{e.message}")
    end

    def scenario_attributes
      %i[
        area_code end_year private keep_compatible
        user_values balanced_values metadata
      ]
    end

    def create_sortables(scenario)
      return Success(scenario) unless @data['user_sortables']

      @data['user_sortables'].each do |class_name, order|
        if class_name == 'HeatNetworkOrder'
          order.each { |attrs| scenario.heat_network_orders << HeatNetworkOrder.new(attrs) }
        else
          scenario.public_send(:"#{class_name.underscore}=", class_name.constantize.new(order))
        end
      end

      Success(scenario)
    rescue StandardError => e
      Failure("Failed to create sortables: #{e.message}")
    end

    def create_curves(scenario)
      return Success(scenario) unless @data['user_curves']

      @data['user_curves'].each do |key, curve|
        scenario.user_curves << UserCurve.new(key:, curve:)
      end

      Success(scenario)
    rescue StandardError => e
      Failure("Failed to create curves: #{e.message}")
    end

    def build_owner(scenario)
      return Success(scenario) unless @user_id

      user = User.find_by(id: @user_id)
      unless user
        Rails.logger.warn("ScenarioPacker::Load: User with id #{@user_id} not found. Owner assignment skipped.")
        return Success(scenario)
      end

      scenario.scenario_users.build(
        user:,
        role_id: User::ROLES.key(:scenario_owner)
      )

      Success(scenario)
    rescue StandardError => e
      Failure("Failed to build owner: #{e.message}")
    end
  end
end
