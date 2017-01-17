class Area
  def self.get(area_code)
    attributes = Etsource::Loader.instance.area_attributes(area_code)
    attributes.with_indifferent_access
  end

  def self.derived?(area_code)
    Atlas::Dataset.exists?(area_code) && get(area_code).fetch(:derived)
  end
end
