module ScenarioUpdater
  class Base
    include ActiveModel::Validations

    attr_reader :scenario, :params, :current_user

    def initialize(scenario, params, current_user)
      @scenario = scenario
      @params = params
      @current_user = current_user
    end
  end
end
