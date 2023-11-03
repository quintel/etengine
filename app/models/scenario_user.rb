# frozen_string_literal: true

class ScenarioUser < ApplicationRecord
  belongs_to :scenario
  belongs_to :user, optional: true

  validate :user_or_email

  def user_or_email
    unless user_id.present? || user_email.present?
      errors.add(:user_email, 'Email should be present if no user_id is given')
    end
  end
end

