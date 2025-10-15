# frozen_string_literal: true

class ScenarioUpdater
  # Base class for ScenarioUpdater components
  # Provides common initialization pattern
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
