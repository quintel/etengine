# frozen_string_literal: true

module Scenario::Attachments
  extend ActiveSupport::Concern

  ATTACHMENT_KEYS = %i[
    interconnector_1_price_curve
    interconnector_2_price_curve
    interconnector_3_price_curve
    interconnector_4_price_curve
    interconnector_5_price_curve
    interconnector_6_price_curve
  ].freeze

  included do
    ATTACHMENT_KEYS.each { |key| has_one_attached(key) }
  end

  # Public: An array containing all attached files on the Scenario.
  def attached_files
    ATTACHMENT_KEYS.map do |key|
      file = public_send(key)
      file.attached? ? file : nil
    end.compact
  end
end
