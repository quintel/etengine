# frozen_string_literal: true

module Api
  # Describes the abilities of anyone using the API with Settings.scenario_access_grants_only on.
  # Access comes from the token's grant, the bound flag and creator_id, never scenario_users.
  # Everyone can read public scenarios, and guests (no token) can write to unbound public ones.
  # Only admins delete, and only MyETM binds.
  class GrantAbility
    include CanCan::Ability

    # TEMPORARY(legacy-pat): legacy_access is the grant MyETM looked up for a personal access token
    def initialize(token, user, legacy_access = nil)
      @scopes = token ? token[:scopes].to_s.split : []
      @user   = user
      @access = legacy_access || ScenarioAccess.new(token && token[ScenarioAccess::CLAIM])

      can :read, Scenario, private: false
      can :bind, Scenario if scope?('bind')
      user ? allow_user : allow_open_writes
    end

    private

    def allow_user
      return unless scope?('read')

      allow_read
      return unless scope?('write')

      allow_write
      can :destroy, Scenario if admin? && scope?('delete')
    end

    def allow_read
      return can(:read, Scenario) if admin?

      can :read, Scenario, id: @access.readable
      can :read, Scenario, unbound_created_by_user
    end

    def allow_write
      return can(%i[create update clone], Scenario) if admin?

      allow_open_writes
      can %i[update clone], Scenario, id: @access.writable
      can %i[update clone], Scenario, unbound_created_by_user
    end

    # Guests and users with the write scope
    def allow_open_writes
      can :create, Scenario
      can :update, Scenario, bound: false, private: false, creator_id: nil
      can :clone, Scenario, private: false
    end

    def unbound_created_by_user
      { bound: false, creator_id: @user.id }
    end

    def scope?(name)
      @scopes.include?("scenarios:#{name}")
    end

    def admin?
      @user.admin?
    end
  end
end
