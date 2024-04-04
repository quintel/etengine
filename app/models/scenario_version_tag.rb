# frozen_string_literal: true

# Optional to add version tags to scenarios to display in saved scenario
class ScenarioVersionTag < ApplicationRecord
  # scenario          the scenario for the tag, cannot be updated
  # user              the user that created the tag, cannot be updated
  # text

  belongs_to :scenario
  belongs_to :user

  def as_json(*)
    super(except: %i[id scenario_id])
  end
end
