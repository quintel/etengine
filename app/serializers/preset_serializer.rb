class PresetSerializer
  # Creates a new Preset API serializer.
  #
  # @param [#api_v3_scenario_url] controller
  #   The controller which created the serializer.
  # @param [Preset] preset
  #   The scenario preset for which we want JSON.
  #
  def initialize(controller, preset)
    @controller = controller
    @resource   = preset
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the preset scenario attributes.
  #
  def as_json(*)
    json = Hash.new

    json[:id]             = @resource.id
    json[:title]          = @resource.try(:metadata)&.[]('title')
    json[:area_code]      = @resource.area_code
    json[:start_year]     = @resource.start_year
    json[:end_year]       = @resource.end_year
    json[:description]    = @resource.try(:metadata)&.[]('description')
    json[:url]            = @controller.api_v3_scenario_url(@resource)
    json[:ordering]       = @resource.ordering
    json[:display_group]  = @resource.display_group
    json[:scaling]        = @resource.scaler

    json
  end
end
