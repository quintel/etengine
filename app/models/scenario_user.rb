# frozen_string_literal: true

class ScenarioUser < ApplicationRecord
  belongs_to :scenario
  belongs_to :user, optional: true

  validate :user_id_or_email
  validates :user_email, format: { with: Devise.email_regexp }, allow_blank: true
  validates :role_id, inclusion: { in: User::ROLES.keys }

  before_create :couple_existing_user

  # Always make sure one owner is left on the Scenario this record is part of
  # before changing its role or removing it.
  before_save :ensure_one_owner_left_before_save
  before_destroy :ensure_one_owner_left_before_destroy

  # If email is supplied on create, see if we can find a user in the system
  def couple_existing_user
    return unless user_email.present? && user_id.blank?

    self.user = User.find_by(email: user_email)
    self.user_email = nil if user
  end

  # Either user_id or user_email should be present, but not both
  def user_id_or_email
    return if user_id.blank? ^ user_email.blank?

    errors.add(:base, 'Either user_id or user_email should be present.')
  end

  def ensure_one_owner_left_before_save
  # Don't check new records and ignore if the role is set to owner.
    return if new_record? || role_id == User::ROLES.key(:scenario_owner)

    # Collect roles for other users of this scenario
    other_role_ids = scenario.scenario_users.where.not(id: id).pluck(:role_id).compact.uniq

    # Cancel this action of none of the other users is an owner
    throw(:abort) if other_role_ids.none?(User::ROLES.key(:scenario_owner))
  end

  def ensure_one_owner_left_before_destroy
    # Collect roles for other users of this scenario
    other_users = scenario.scenario_users.where.not(id: id)
    other_role_ids = other_users.pluck(:role_id).compact.uniq

    # Cancel this action of there are other users and none of them is an owner
    throw(:abort) if other_users.count > 0 && other_role_ids.none?(User::ROLES.key(:scenario_owner))
  end

  # How to recognise the record for error messages
  def email
    user_email || user.email
  end

  def as_json(*)
    params = super

    params[:role] = User::ROLES[role_id]
    params.except(:role_id)
  end
end
