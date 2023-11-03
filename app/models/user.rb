# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = {
    1 => :scenario_viewer,
    2 => :scenario_collaborator,
    3 => :scenario_owner
  }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable, :registerable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # rubocop:disable Rails/InverseOf

  has_many :access_grants,
    class_name: 'Doorkeeper::AccessGrant',
    foreign_key: :resource_owner_id,
    dependent: :delete_all

  has_many :access_tokens,
    class_name: 'Doorkeeper::AccessToken',
    foreign_key: :resource_owner_id,
    dependent: :delete_all

  has_many :oauth_applications,
    class_name: 'OAuthApplication',
    dependent: :delete_all,
    as: :owner

  has_many :staff_applications, dependent: :destroy

  # rubocop:enable Rails/InverseOf

  has_many :scenario_users, dependent: :destroy
  has_many :scenarios, through: :scenario_users
  has_many :personal_access_tokens, dependent: :destroy

  validates :name, presence: true, length: { maximum: 191 }

  def valid_password?(password)
    return true if super

    # Fallback to salting the password with the salt for users imported from ETModel.
    return super("#{password}#{legacy_password_salt}") if legacy_password_salt.present?

    false
  end

  def roles
    admin? ? %w[user admin] : %w[user]
  end

  def as_json(options = {})
    super(options.merge(except: Array(options[:except]) + [:legacy_password_salt]))
  end

  def active_for_authentication?
    super && deleted_at.nil?
  end
end
