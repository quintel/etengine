# frozen_string_literal: true

# Allows the user to choose a custom sorting of flexibility technologies in the
# merit order. Technologies which appear first will receive preference in
# periods of excess electricity.
class FlexibilityOrder < ApplicationRecord
  include UserSortable

  def self.default_order
    Etsource::Config.flexibility_order
  end

  def graph_key
    :flexibility_order
  end
end
