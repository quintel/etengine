# frozen_string_literal: true

class UserCurve < ApplicationRecord
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

  # TODO: Check if this is still necessary
  # Identify that this record is a curve based on the key suffix
  def curve?
    key.ends_with?('_curve')
  end

  # Returns the configuration for the curve using the key (without the suffix)
  def curve_config
    Etsource::Config.user_curves[key.chomp('_curve')]
  end

  def source_scenario?
    SOURCE_SCENARIO_METADATA.all? { |key| public_send(key).present? }
  end

  def metadata_json
    return {} unless source_scenario?

    SOURCE_SCENARIO_METADATA.to_h { |key| [key, public_send(key)] }
  end

  def update_or_remove_metadata(metadata)
    return update(metadata) if metadata.present?
    return unless source_scenario?

    update(SOURCE_SCENARIO_METADATA.index_with { nil })
  end

  def validate_source_scenario_metadata
    if SOURCE_SCENARIO_METADATA.any? { |key| public_send(key).present? } && !source_scenario?
      errors.add(:base, 'All metadata needs to be set for curves imported from another scenario')
    end
  end
end
