# frozen_string_literal: true

class UserCurve < ApplicationRecord
  belongs_to :scenario

  # Ensure that each user curve has a unique key per scenario
  validates :key, presence: true, uniqueness: { scope: :scenario_id, case_sensitive: false }

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

  # TODO: Check if still necessary
  # Identify that this record is a curve based on the key suffix
  def curve?
    key.ends_with?('_curve')
  end

  # Returns the configuration for the curve using the key (without the suffix)
  def curve_config
    Etsource::Config.user_curves[key.chomp('_curve')]
  end
end
