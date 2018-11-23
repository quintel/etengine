class Area
  class << self
    def get(area_code)
      attributes = Etsource::Loader.instance.area_attributes(area_code)
      attributes.with_indifferent_access
    end

    def exists?(area_code)
      Atlas::Dataset.exists?(area_code)
    end

    def derived?(area_code)
      exists?(area_code) && get(area_code).fetch(:derived)
    end
  end
end
