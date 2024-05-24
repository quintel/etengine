# frozen_string_literal: true

class ScenarioUser < ApplicationRecord
  belongs_to :scenario
  belongs_to :user, optional: true

  validate :user_id_or_email
  validates :user_email, format: { with: Devise.email_regexp }, allow_blank: true
  validates :role_id, inclusion: { in: User::ROLES.keys, message: 'unknown' }

  before_save :ensure_one_owner_left_before_save
  before_create :couple_existing_user
  before_destroy :ensure_one_owner_left_before_destroy

  # If email is supplied on create, see if we can find a user in the system
  def couple_existing_user
    return unless user_email.present? && user_id.blank?

    couple_to(User.find_by(email: user_email))
  end

  # Couples the record to an existing User.
  def couple_to(user)
    self.user = user
    self.user_email = nil if user
  end

  def update_role(role_sym)
    self.role_id = User::ROLES.key(role_sym)
  end

  # How to recognise the record for error messages
  def email
    user_email || user&.email
  end

  def as_json(*)
    params = super

    params[:role] = User::ROLES[role_id]
    params.except(:role_id)
  end

  private

  def last_owner?
    scenario
      .scenario_users.where.not(id: id)
      .pluck(:role_id).compact.uniq
      .none?(User::ROLES.key(:scenario_owner))
  end

  # Private: validation. Always make sure one owner is left on the Scenario this
  # record is part of before changing its role or removing it.
  def ensure_last_owner
    return unless last_owner?

    errors.add(:base, :ownership, message: 'Last owner cannot be altered')
    throw(:abort)
  end

  def ensure_one_owner_left_before_destroy
    return if destroyed_by_association
    return unless role_id == User::ROLES.key(:scenario_owner)

    ensure_last_owner
  end

  def ensure_one_owner_left_before_save
    # Don't check new records and ignore if the role is set to owner.
    return if new_record? || role_id == User::ROLES.key(:scenario_owner)

    ensure_last_owner
  end

  # Either user_id or user_email should be present, but not both
  def user_id_or_email
    return if user_id.blank? ^ user_email.blank?

    errors.add(
      :base,
      :user_or_email_blank,
      message: 'Either user_id or user_email should be present.'
    )
  end
end
