# frozen_string_literal: true

# Contains scenario attachments such as custom curves for interconnectors
class ScenarioAttachment < ApplicationRecord
  include ScenarioMetadata

  VALID_FILE_KEYS = %w[
    esdl_file
  ].freeze

  has_one_attached :file
  belongs_to :scenario
  belongs_to :source_scenario, class_name: 'Scenario', optional: true

  validates :key, presence: true, uniqueness: {
    scope: :scenario_id,
    case_sensitive: false,
    message: 'already exists for this scenario'
  }

  validates :key, inclusion: {
    in: ->(*) { valid_keys },
    message: ->(*) { "should be one of: #{valid_keys}" }
  }

  validate :validate_source_scenario_metadata

  def self.valid_keys
    NastyCache.instance.fetch('ScenearioAttachment.valid_keys') do
      Etsource::Config.user_curves.map { |_, conf| conf.db_key }.push(*VALID_FILE_KEYS)
    end
  end

  def self.valid_non_curve_keys
    VALID_FILE_KEYS
  end

  # TODO: Remove these after migrating curves to UserCurve model
  def curve?
    key.ends_with?('_curve')
  end

  def curve_config
    Etsource::Config.user_curves[key.chomp('_curve')]
  end
end
