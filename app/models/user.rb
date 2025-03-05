# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = {
    1 => :scenario_viewer,
    2 => :scenario_collaborator,
    3 => :scenario_owner
  }.freeze

  attr_accessor :identity_user

  delegate :email, :roles, :admin?, to: :identity_user, allow_nil: true

  has_many :scenario_users, dependent: :destroy
  has_many :scenarios, through: :scenario_users
  has_many :scenario_version_tags
  has_many :personal_access_tokens, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order('name') }

  after_create :couple_scenario_users

  # Links existing scenario users to the new User.
  #
  # It needs to be linked through the scenario user to ensure the scenario
  # user stops being marked as dirty.
  def couple_scenario_users
    ScenarioUser.where(user_email: email).find_each do |su|
      su.couple_to(self)
      su.save
    end
  end

 # Performs sign-in steps for an Identity::User.
  #
  # If a matching user exists in the database, it will be updated with the latest data from the
  # Identity::User. Otherwise, a new user will be created.
  #
  # Returns the user. Raises an error if the user could not be saved.
  def self.from_identity!(identity_user)
    where(id: identity_user.id).first_or_initialize.tap do |user|
      user.identity_user = identity_user
      user.name = identity_user.name

      user.save!
    end
  end

  # Finds or creates a user from a JWT token.
  def self.from_jwt!(token)
    id = token['sub']
    admin = token.dig('user', 'admin')
    name = token.dig('user', 'name')

    raise 'Token does not contain user information' if id.blank? || name.blank?

    User.find_or_create_by!(id: token['sub']) do |u|
      u.admin = admin.presence || false
      u.name = name
    end
  # When a new user is introduced to the engine, this is usually through ETModels
  # play interface. On entering play for the first time, two requests are sent to
  # the engine shortly after each other - one to create a scenario, one to initialise
  # the inputs. In this case it may happen that the first request is still busy creating
  # the user when the second request hits, resulting in a non-unique record on the users
  # id.
  # Also rescue from Deadlock: https://github.com/rails/rails/issues/54281
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout
    User.find(token['sub'])
  end

  def self.from_session_user!(identity_user)
    find(identity_user.id).tap { |u| u.identity_user = identity_user }
  end
end
