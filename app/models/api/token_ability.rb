# frozen_string_literal: true

module Api
  # Describes the abilities of someone accessing the API with an access a token.
  class TokenAbility
    include CanCan::Ability

    def initialize(token, user)
      can :read, Scenario, private: false

      # scenarios:read
      # --------------

      return unless token.scopes.include?('scenarios:read')

      can :read, Scenario, id: ScenarioUser.where(user_id: user.id, role_id: User::ROLES.key(:scenario_viewer)..).pluck(:scenario_id)

      # scenarios:write
      # ---------------

      return unless token.scopes.include?('scenarios:write')

      can :create, Scenario

      # Unowned public scenario.
      can :update, Scenario, private: false
      cannot :update, Scenario, private: false, id: ScenarioUser.pluck(:scenario_id)

      # Self-owned scenario.
      can :update, Scenario, id: ScenarioUser.where(user_id: user.id, role_id: User::ROLES.key(:scenario_collaborator)..).pluck(:scenario_id)

      # Actions that involve reading one scenario and writing to another.
      can :clone, Scenario, private: false
      can :clone, Scenario, id: ScenarioUser.where(user_id: user.id, role_id: User::ROLES.key(:scenario_collaborator)..).pluck(:scenario_id)

      # scenarios:delete
      # ----------------

      return unless token.scopes.include?('scenarios:delete')

      can :destroy, Scenario, id: ScenarioUser.where(user_id: user.id, role_id: User::ROLES.key(:scenario_owner)).pluck(:scenario_id)
    end
  end
end
