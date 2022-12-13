# frozen_string_literal: true

# Describes the abilities of users accessing the web interface.
class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, :all if user&.admin?
  end
end
