# frozen_string_literal: true

# Describes the abilities of users accessing the web interface.
class Ability
  include CanCan::Ability

  def initialize(user)
    if user&.admin?
      can :manage, :all
    else
      can :read, Qernel::Node
    end
  end
end
