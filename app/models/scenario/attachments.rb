# frozen_string_literal: true

class Scenario < ApplicationRecord
  # Utility methods for accessing user-attached files on a scenario.
  module Attachments
    # Public: Returns a list of keys of attachted curves
    def attached_curve_keys
      user_curves.pluck(:key)
    end

    # Public: Returns if a curve with this key is installed by the user
    def attached_curve?(key)
      attached_curve_keys.include?(key)
    end

    # Public: Returns the UserCurve with the given key
    def attached_curve(key)
      user_curves.find_by(key: key)
    end

    # Public: Returns if an attachment has been added matching the key.
    def attachment?(key)
      attachment(key)&.file&.attached?
    end

    # Public: Returns the ScenarioAttachment matching the key, or nil if no attachment has been
    # added for the key.
    def attachment(key)
      # Use to_a.find to take advantage of the eager-loaded attachments and blobs.
      attachments.to_a.find { |a| a.key == key && a.file&.attached? }
    end
  end
end
