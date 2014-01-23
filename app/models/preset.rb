# Preset contains the preset scenarios that can be selected in the
# dropdown on et-model.com. They are loaded through etsource.
#
class Preset
  include InMemoryRecord
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml


  COLUMNS = [:id, :user_values, :end_year, :area_code, :use_fce, :title,
    :description, :in_start_menu, :ordering, :display_group, :created_at]

  attr_accessor *COLUMNS
  attr_accessor :key

  def initialize(attributes = {})
    attributes = attributes.slice(*COLUMNS)

    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
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
    # DANGER: Mark the scenarios as frozen or unsaveable to avoid disaster!
    Scenario.new(attrs).tap{|scenario| scenario.id = id }
    # DANGER: Mark the scenarios as frozen or unsaveable to avoid disaster!
    # Scenario.new(attrs).tap{|scenario| scenario.id = id; scenario.readonly! }
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
end
