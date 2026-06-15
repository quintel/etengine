# frozen_string_literal: true

# Hourly curve CSV for electricity merit order participants.
# Reuses MeritCSVSerializer filtering (producer/consumer types,
# curtailment exclusion, NodeCustomisation).
class ElectricityCSVSerializer < MeritCSVSerializer
  def filename
    :electricity_profiles
  end
end
