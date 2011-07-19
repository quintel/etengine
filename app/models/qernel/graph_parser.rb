module Qernel
  class GraphParser
    attr_reader :lines
    CARRIERS = {
      'loss' => Carrier.new(1, 'loss', '', 1.0),
      'el' => Carrier.new(2, 'el', '', 1.0),
      'hw' => Carrier.new(3, 'hw', '', 1.0)
    }

    LINK_TYPES = {
      's' => :share,
      'c' => :constant,
      'd' => :dependent,
      'f' => :flexible,
      'i' => :inversed_flexible
    }

    def initialize(str)
      @lines = str.lines.map{|l| l.strip.gsub(/\s/, '')}.reject{|l| l.match(/^#/)}
      @converters = {}
    end

    def build
      slots = []
      graph = Graph.new.with({})

      # create converters first
      lines.each do |line|
        carrier_key, lft, link, rgt = line.scan(/([a-z]+:)?(.+)\=\=(.+)\=\=\>(.+)/).first

        build_converter(lft)
        build_converter(rgt)
      end
      graph.converters = @converters.values


      lines.each do |line|
        carrier_key, lft, link_str, rgt = line.scan(/([a-z]+:)?(.+)\=\=(.+)\=\=\>(.+)/).first

        link_type, link_share = link(link_str)

        graph.
          connect(build_converter(lft), build_converter(rgt), carrier(carrier_key), link_type ).
          with(:share => link_share)
      end

      graph
    end
  
    def link(str)
      link_type = LINK_TYPES[str[0]]
      link_share = str.gsub(/[^\d^\.]/, '') == '' ? nil : str.gsub(/[^\d^\.]/,'').to_f
      [link_type, link_share]
    end

    def carrier(str)
      carrier_key = str.nil? ? 'el' : str.gsub(':', '')
      CARRIERS[carrier_key]
    end

    def build_converter(str, carrier = nil)
      key, dataset = str.scan(/([A-Za-z_0-9]+)(\(\d+\))?/).first
      key = key.to_sym

      unless @converters[key]
        id = @converters.keys.length+1
        dataset = {:demand => dataset.nil? ? nil : dataset.gsub(/\D/,'').to_f }
        @converters[key] = Converter.new(id, key).with(dataset)
      end

      @converters[key]
    end

  end
end
  