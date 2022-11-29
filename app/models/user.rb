# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable, :registerable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # rubocop:disable Rails/InverseOf
  # rubocop:disable Rails/HasManyOrHasOneDependent

  has_many :access_grants,
  class_name: 'Doorkeeper::AccessGrant',
  foreign_key: :resource_owner_id,
  dependent: :delete_all

  has_many :access_tokens,
    class_name: 'Doorkeeper::AccessToken',
    foreign_key: :resource_owner_id,
    dependent: :delete_all

  has_many :oauth_applications,
    class_name: 'Doorkeeper::Application',
    as: :owner

  # rubocop:enable Rails/InverseOf Rails/HasManyOrHasOneDependent
  # rubocop:enable Rails/HasManyOrHasOneDependent

  has_many :scenarios

  validates :name, presence: true, length: { maximum: 191 }
end
