# frozen_string_literal: true

module Api
  # Describes the abilities of users accessing the ETM through the API.
  class Ability
    include CanCan::Ability

    def initialize(_user)
      # Anyone can read any scenario.
      can :read, Scenario

      # Obscure actions which equal reading a scenario.
      can %i[batch dashboard interpolate merge merit templates], Scenario

      # Anyone can create a scenario.
      can :create, Scenario

      # Anyone can write to an unprotected scenario.
      can :update, Scenario

      # ... but not to a protected one.
      cannot :update, Scenario, protected: true
    end
  end
end
