# frozen_string_literal: true

module Api
  # Describes the abilities of someone accessing the API with an access token.
  # Admins can read, write, and delete all scenarios, provided they have the correct scope in the token.
  # Users can read public scenarios and scenarios where they are viewers.
  # Users with write scope can create, update, and clone scenarios where they are collaborators.
  # Users with delete scope can delete scenarios where they are owners.
  class TokenAbility
    include CanCan::Ability

    def initialize(token, user)
      @scopes = token[:scopes]
      @user   = user

      allow_public_read
      return unless read_scope?

      allow_read
      return unless write_scope?

      allow_write
      return unless delete_scope?

      allow_delete
    end

    private

    # Methods to allow access to scenarios based on the role.
    # Everyone can read public scenarios.
    def allow_public_read
      can :read, Scenario, private: false
    end

    def allow_read
      if admin?
        can :read, Scenario
      else
        can :read, Scenario, id: viewer_scenario_ids
      end
    end

    def allow_write
      can :create, Scenario

      if admin?
        # Admins with write scope can update and clone all scenarios.
        can :update, Scenario
        can :clone, Scenario
      else
        # Non-admins
        # Allow updating unowned public scenarios except when any association exists.
        can :update, Scenario, private: false
        cannot :update, Scenario, private: false, id: ScenarioUser.pluck(:scenario_id)
        # Allow updating scenarios where the user is a collaborator.
        can :update, Scenario, id: collaborator_scenario_ids

        # Allow cloning both unowned public scenarios and self-owned scenarios.
        can :clone, Scenario, private: false
        can :clone, Scenario, id: collaborator_scenario_ids
      end
    end

    def allow_delete
      if admin?
        can :destroy, Scenario
      else
        can :destroy, Scenario, id: owner_scenario_ids
      end
    end

    # Methods to get the scenario ids for the user based on the role.
    def viewer_scenario_ids
      ScenarioUser.where(
        user_id: @user.id,
        role_id: User::ROLES.key(:scenario_viewer)..
      ).pluck(:scenario_id)
    end

    def collaborator_scenario_ids
      ScenarioUser.where(
        user_id: @user.id,
        role_id: User::ROLES.key(:scenario_collaborator)..
      ).pluck(:scenario_id)
    end

    def owner_scenario_ids
      ScenarioUser.where(
        user_id: @user.id,
        role_id: User::ROLES.key(:scenario_owner)
      ).pluck(:scenario_id)
    end

    # Methods to check the scopes of the token.
    def read_scope?
      @scopes.include?('scenarios:read')
    end

    def write_scope?
      @scopes.include?('scenarios:write')
    end

    def delete_scope?
      @scopes.include?('scenarios:delete')
    end

    def admin?
      @user&.admin?
    end
  end
end
