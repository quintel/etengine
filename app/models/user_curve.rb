# frozen_string_literal: true

class UserCurve < ApplicationRecord
  include ScenarioMetadata

  belongs_to :scenario
  belongs_to :source_scenario, class_name: 'Scenario', optional: true

  SOURCE_SCENARIO_METADATA = %i[
    source_scenario_id
    source_scenario_title
    source_saved_scenario_id
    source_dataset_key
    source_end_year
  ].freeze

  # Ensure that each user curve has a unique key per scenario
  validates :key, presence: true, uniqueness: { scope: :scenario_id, case_sensitive: false }
  # Check the metadata for the curve
  validate :validate_source_scenario_metadata

  def curve
    @curve ||= MeritCurveSerializer.load(read_attribute(:curve))
  end

  def curve=(val)
    @curve = val
    write_attribute(:curve, MeritCurveSerializer.dump(val))
  end

  # Returns true if a valid curve is stored
  def loadable_curve?
    curve.present? && CurveHandler::Config.db_key?(key)
  end

  # Returns the configuration for the curve using the key (without the suffix)
  def curve_config
    Etsource::Config.user_curves[key.chomp('_curve')]
  end

  def as_csv
    curve.to_a.map { |hour| [hour] }
  end
end
