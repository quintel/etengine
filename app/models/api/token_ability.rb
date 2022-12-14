# frozen_string_literal: true

module Api
  # Describes the abilities of someone accessing the API with an access a token.
  class TokenAbility
    include CanCan::Ability

    def initialize(token, user)
      can :read, Scenario, user_id: nil

      # scenarios:read
      # --------------

      return unless token.scopes.include?('scenarios:read')

      can :read, Scenario, user_id: user.id

      # scenarios:write
      # ---------------

      return unless token.scopes.include?('scenarios:write')

      can :create, Scenario

      # Unowned public scenario.
      can :update, Scenario, private: false, user_id: nil

      # Self-owned scenario.
      can :update, Scenario, user_id: user.id

      # Actions that involve reading one scenario and writing to another.
      can :clone,  Scenario, private: false
      can :clone,  Scenario, user_id: user.id

      # scenarios:delete
      # ----------------

      return unless token.scopes.include?('scenarios:delete')

      can :destroy, Scenario, user_id: user.id
    end
  end
end
