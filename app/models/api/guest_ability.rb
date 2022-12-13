# frozen_string_literal: true

module Api
  # Describes the abilities of someone accessing the API without a token.
  class GuestAbility
    include CanCan::Ability

    def initialize
      can :create, Scenario
      can :read,   Scenario, private: false
      can :update, Scenario, private: false, user_id: nil

      # Actions that involve reading one scenario and writing to another.
      can :clone,  Scenario, private: false
    end
  end
end
