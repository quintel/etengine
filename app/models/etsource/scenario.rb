module Etsource
  class Scenario
    def initialize
      @etsource = Etsource::Base.instance
    end

    def presets
      Atlas::Preset.all.map do |preset|
        Preset.new(preset.attributes.merge(key: preset.key))
      end
    end

  end
end
