# frozen_string_literal: true

class ScenarioUser < ApplicationRecord
  belongs_to :scenario
  belongs_to :user, optional: true

  validate :user_id_or_email
  validates :user_email, format: { with: Devise.email_regexp }, allow_blank: true
  validates :role_id, inclusion: { in: User::ROLES.keys }

  # Always make sure one owner is left on the Scenario this record is part of
  # before changing its role or removing it.
  # Don't check new records and ignore if the role is set to owner.
  before_save :ensure_one_owner_left,
    unless: proc { |u| u.new_record? || u.role_id == User::ROLES.key(:scenario_owner) }
  before_destroy :ensure_one_owner_left

  # Either user_id or user_email should be present, but not both
  def user_id_or_email
    return if user_id.blank? ^ user_email.blank?

    errors.add(:base, 'Either user_id or user_email should be present.')
  end

  def ensure_one_owner_left
    # Collect roles for other users of this scenario
    role_ids = scenario.scenario_users.where.not(id: id).pluck(:role_id).compact.uniq

    # Cancel this action of none of the other users is an owner
    throw(:abort) if role_ids.none?(User::ROLES.key(:scenario_owner))
  end
end

