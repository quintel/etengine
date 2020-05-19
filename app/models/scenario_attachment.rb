# Contains metadata about scenario attachments such as custom curves
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
  OTHER_SCENARIO_METADATA = %i[
    other_scenario_title
    other_saved_scenario_id
    other_dataset_key
    other_end_year
  ].freeze

  has_one_attached :custom_curve
  belongs_to :scenario

  validates_presence_of :attachment_key
  validates :attachment_key, inclusion: {
                              in: ATTACHMENT_KEYS,
                              message: "should be one of: #{ATTACHMENT_KEYS}"
                            }
  validate :validate_other_scenario_metadata

  # Returns true for attachments which have all their 'other_scenario' metadata
  # set, indicating the attachment was imported from another scenario
  def from_other_scenario?
    OTHER_SCENARIO_METADATA.all? do |key|
      public_send(key).present?
    end
  end

  # Validates if all scenario metadata is set. When none of the metadata
  # attributes is set, this indicates a user-uploaded attachment. These are
  # allowed as well
  def validate_other_scenario_metadata
    if OTHER_SCENARIO_METADATA.any?{ |key| public_send(key).present? } &&
      !from_other_scenario?
      errors.add(
        :base,
        'All metadata needs to be set for curves imported from another scenario'
      )
    end
  end
end
