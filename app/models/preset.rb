# Preset contains the preset scenarios that can be selected in the
# dropdown on et-model.com. They are loaded through etsource.
#
class Preset
  include InMemoryRecord
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

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

    if scenario.scaler
      attrs[:scaling] = Atlas::Preset::Scaling.new(scenario.scaler.attributes)
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

    Scenario.new(attrs.except(:scaling)).tap do |scenario|
      scenario.id = id
      scenario.scaler = scaler.dup if scaler

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

    "#{ Atlas::HashToTextParser.new(attrs.compact).to_text }\n"
  end
end
