module Qernel
  class InitializerInputs
    def self.for_area(area_code)
      new(area_code).all
    end

    def initialize(area_code)
      @area_attributes =
        Etsource::Loader.instance.area_attributes(area_code)[:init] || {}
    end

    def all
      Hash[@area_attributes
        .map { |key, val| [InitializerInput.fetch(key), val] }
        .sort_by { |input, _| -input.priority }
      ]
    end
  end
end
