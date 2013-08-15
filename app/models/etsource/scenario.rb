module Etsource
  class Scenario
    def initialize
      @etsource = Etsource::Base.instance
    end

    def presets
      Atlas::Preset.all.map { |preset| Preset.new(preset.attributes) }
    end

  end
end
