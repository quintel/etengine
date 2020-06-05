# frozen_string_literal: true

# Contains scenario attachments such as custom curves for interconnectors
class ScenarioAttachment < ApplicationRecord
  ATTACHMENT_KEYS = %w[
    interconnector_1_price_curve
    interconnector_2_price_curve
    interconnector_3_price_curve
    interconnector_4_price_curve
    interconnector_5_price_curve
    interconnector_6_price_curve
  ].freeze

  # If the attachment originated from another scenario, the following attributes
  # are set. These metadata are primarily used for display in etmodel.
  SOURCE_SCENARIO_METADATA = %i[
    source_scenario_id
    source_scenario_title
    source_saved_scenario_id
    source_dataset_key
    source_end_year
  ].freeze

  has_one_attached :file
  belongs_to :scenario

  validates :key, presence: true, uniqueness: {
    scope: :scenario_id,
    case_sensitive: false,
    message: 'already exists for this scenario'
  }

  validates :key, inclusion: {
    in: ATTACHMENT_KEYS,
    message: "should be one of: #{ATTACHMENT_KEYS}"
  }

  validate :validate_source_scenario_metadata

  # Returns true for attachments which have all their 'source_scenario' metadata
  # set, indicating the attachment was imported from another scenario
  def source_scenario?
    SOURCE_SCENARIO_METADATA.all? do |key|
      public_send(key).present?
    end
  end

  def metadata_json
    return {} unless source_scenario?

    SOURCE_SCENARIO_METADATA.to_h { |key| [key, public_send(key)] }
  end

  # Updates the source scenario metadata of the attachment. If no metadata is
  # supplied this can indicate the attachment has changed from a
  # scenario-imported curve to a user uploaded curve. Thus we remove all source
  # scenario metadata present.
  def update_or_remove_metadata(metadata)
    return update(metadata) if metadata.present?
    return unless source_scenario?

    update(SOURCE_SCENARIO_METADATA.to_h { |key| [key, nil] })
  end

  # Validates if all scenario metadata is set. When none of the metadata
  # attributes is set, this indicates a user-uploaded attachment. These are
  # allowed as well
  def validate_source_scenario_metadata
    if SOURCE_SCENARIO_METADATA.any? { |key| public_send(key).present? } &&
        !source_scenario?
      errors.add(
        :base,
        'All metadata needs to be set for curves imported from another scenario'
      )
    end
  end
end
