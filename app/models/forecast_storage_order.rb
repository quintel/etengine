# frozen_string_literal: true

# Allows the user to choose a custom sorting of forecastable storage.
class ForecastStorageOrder < ApplicationRecord
  include UserSortable

  def self.default_order
    Etsource::Config.forecast_storage_order
  end

  def graph_key
    :forecast_storage_order
  end
end
