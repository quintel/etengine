# frozen_string_literal: true

# Optional to add version tags to scenarios to display in saved scenario
class ScenarioVersionTag < ApplicationRecord
  # scenario          the scenario for the tag, cannot be updated
  # description

  belongs_to :scenario
  belongs_to :user

  validates :description, length: { maximum: 60_000 }

  def as_json(*)
    super(except: %i[id scenario_id])
  end
end
