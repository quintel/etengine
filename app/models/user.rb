# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = {
    1 => :scenario_viewer,
    2 => :scenario_collaborator,
    3 => :scenario_owner
  }.freeze

  attr_accessor :identity_user

  delegate :roles, :admin?, to: :identity_user, allow_nil: true
  has_many :scenario_users, dependent: :destroy
  has_many :scenarios, through: :scenario_users
  has_many :scenario_version_tags
  has_many :personal_access_tokens, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order('name') }

  after_create :couple_scenario_users

  # If users are initialized from JWT, then their email is not available
  # from identity_user. In that case, a db field user_email is used. The email is
  # needed on create to enter the couple_scenario_users hook.
  def email
    identity_user&.email || user_email
  end

  # Links existing scenario users to the new User.
  #
  # It needs to be linked through the scenario user to ensure the scenario
  # user stops being marked as dirty.
  def couple_scenario_users
    return unless email

    ScenarioUser.where(user_email: email).find_each do |su|
      su.couple_to(self)
      su.save
    end
  end

  # Override admin? to fall back to the attribute when identity_user is nil.
  def admin?
    identity_user&.admin? || admin
  end

  # Finds or creates a user from a JWT token.
  #
  # The token's claims are also set as identity_user: admin?/email/roles all prefer this fresh,
  # per-request identity data over the persisted columns, which are only ever set at creation, so a
  # role granted/revoked at the identity provider after that first login is still reflected here.
  def self.from_jwt!(token)
    id = token['sub']
    admin = token.dig('user', 'admin')
    name = token.dig('user', 'name')
    email = token.dig('user', 'email')

    raise 'Token does not contain user information' if id.blank? || name.blank? || email.blank?

    user = find_or_create_from_jwt(id:, admin:, name:, email:)
    user&.identity_user = Identity::User.from_jwt_claims(token)
    user
  end

  def self.find_or_create_from_jwt(id:, admin:, name:, email:)
    User.find_or_create_by!(id: id) do |u|
      u.admin = admin.presence || false
      u.name = name
      u.user_email = email
    end
  # When a new user is introduced to the engine, this is usually through ETModels
  # play interface. On entering play for the first time, multiple requests are sent to
  # the engine shortly after each other - one to create a scenario, one to initialise
  # the inputs, etc. In this case it may happen that the first request is still busy creating
  # the user when the second request hits, resulting in a non-unique record on the users
  # id.
  # Also rescue from Deadlock: https://github.com/rails/rails/issues/54281
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout
    User.find_by(id: id)
  end
  private_class_method :find_or_create_from_jwt
end
