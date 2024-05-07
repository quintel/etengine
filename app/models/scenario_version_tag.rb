# frozen_string_literal: true

# Optional to add version tags to scenarios to display in saved scenario
class ScenarioVersionTag < ApplicationRecord
  # scenario          the scenario for the tag, cannot be updated
  # user              the user that created the tag
  # text

  belongs_to :scenario
  belongs_to :user

  validate :validate_user_in_scenario_users

  def as_json(*)
    super(except: %i[id scenario_id])
  end

  def validate_user_in_scenario_users
    return if scenario.users.exists?(user.id)

    errors.add(:user, 'is not a user of the scenario')
  end
end
