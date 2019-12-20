# Preset contains the preset scenarios that can be selected in the
# dropdown on et-model.com. They are loaded through etsource.
#
class Preset
  include InMemoryRecord
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  # include ActiveModel::Serializers::Xml

  COLUMNS = Atlas::Preset.attribute_set.map(&:name)
  SCALING_COLUMNS = Atlas::Preset::Scaling.attribute_set.map(&:name).freeze

  attr_accessor *COLUMNS
  attr_accessor :key

  # Returns an array of all presets which are visible to end-users.
  def self.visible
    all.reject { |p| p.in_start_menu == false }
  end

  def self.from_scenario(scenario)
    attrs = scenario.attributes.symbolize_keys

    if scenario.scaled?
      attrs[:scaling] = Atlas::Preset::Scaling.new(
        ScenarioScaling.from_scenario(scenario).attributes
      )
    end

    unless scenario.flexibility_order.default?
      attrs[:flexibility_order] = scenario.flexibility_order.order.dup
    end

    unless scenario.heat_network_order.default?
      attrs[:heat_network_order] = scenario.heat_network_order.order.dup
    end

    Preset.new(attrs)
  end

  def initialize(attributes = {})
    self.key = attributes[:key]

    attributes = attributes.slice(*COLUMNS)

    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def scaler
    @scaling && ScenarioScaling.new(@scaling.attributes)
  end

  # Public: The preset flexibility order, if one is assigned.
  #
  # If Atlas returns an empty array, no custom flexibility order is set. In this
  # case, a FlexibilityOrder is not returned and the app will use the defaults.
  #
  # Returns a FlexibilityOrder.
  def flexibility_order
    @flexibility_order&.any? &&
      FlexibilityOrder.new(order: @flexibility_order.dup)
  end

  # Public: The preset heat network order, if one is assigned.
  #
  # If Atlas returns an empty array, no custom heat network order is set. In
  # this case, a HeatNetworkOrder is not returned and the app will use the
  # defaults.
  #
  # Returns a HeatNetworkOrder.
  def heat_network_order
    @heat_network_order&.any? &&
      HeatNetworkOrder.new(order: @heat_network_order.dup)
  end

  # Public: The year on which the analysis for the preset's area is based.
  #
  # Returns an integer.
  def start_year
    @start_year ||= Atlas::Dataset.find(area_code).analysis_year
  end

  # provide legacy support by pretending to be a scenario
  def to_scenario
    attrs = attributes
    id = attrs.delete(:id)

    Scenario.new(
      attrs.except(:scaling, :flexibility_order, :heat_network_order)
    ).tap do |scenario|
      scenario.id = id

      scenario.scaler = scaler.dup if scaler

      if flexibility_order
        scenario.flexibility_order = flexibility_order.dup.tap(&:readonly!)
      end

      if heat_network_order
        scenario.heat_network_order = heat_network_order.dup.tap(&:readonly!)
      end

      scenario.readonly!
    end
  end

  def attributes(attrs = {})
    COLUMNS.inject({}.with_indifferent_access) {|hsh, key| hsh.merge key.to_s => self.send(key) }
  end

  def serializable_hash(options = {})
    hsh = super(options)
    hsh.delete('user_values')
    hsh
  end

  # needed by InMemoryRecord
  def self.load_records
    h = {}
    Etsource::Loader.instance.presets.sort_by(&:id).each do |preset|
      h[preset.id]      = preset
      h[preset.id.to_s] = preset
    end
    h
  end

  def to_param
    id.to_s
  end

  # Public: Converts the Preset to a string representing its contents in the
  # ActiveDocument format.
  #
  # Returns a String.
  def to_active_document
    attrs = attributes

    if scaler
      attrs[:scaling] = scaler.attributes.symbolize_keys.slice(*SCALING_COLUMNS)
    end

    %i[flexibility_order heat_network_order].each do |sortable|
      if (record = public_send(sortable)) && !record.default?
        attrs[sortable] = record.order
      else
        attrs.delete(sortable)
      end
    end

    "#{ Atlas::HashToTextParser.new(attrs.compact).to_text }\n"
  end
end
