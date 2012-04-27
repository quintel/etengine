# Preset contains the preset scenarios that can be selected in the 
# dropdown on et-model.com. They are loaded through etsource.
#
class Preset 
  include InMemoryRecord

  COLUMNS = [:id, :user_values, :end_year, :area_code, :use_fce, :title, :description]

  attr_accessor *COLUMNS

  def initialize(attributes = {})
    attributes = attributes.slice(*COLUMNS)

    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  # needed by InMemoryRecord
  def self.load_records
    h = {}
    Etsource::Loader.instance.presets.each do |preset|
      h[preset.id]      = preset
      h[preset.id.to_s] = preset
    end
    h
  end

end