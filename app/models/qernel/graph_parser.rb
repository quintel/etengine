module Qernel
  class GraphParser
    attr_reader :lines
    CARRIERS = {
      'loss' => Carrier.new(1, 'loss', '', 1.0),
      'el' => Carrier.new(2, 'el', '', 1.0),
      'hw' => Carrier.new(3, 'hw', '', 1.0),
      'electricity' => Carrier.new(4, 'electricity', '', 1.0)
    }

    LINK_TYPES = {
      's' => :share,
      'c' => :constant,
      'd' => :dependent,
      'f' => :flexible,
      'i' => :inversed_flexible
    }

    def initialize(str)
      @lines = str.lines.map{|l| l.strip.gsub(/\s/, '')}.reject{|l| l.match(/^#/)}.reject(&:blank?)
      @converters = {}
    end

    def self.create(str)
      b = new(str)
      b.build
    end

    def build
      slots = []
      graph = Graph.new.with({})

      # create converters first
      lines.each do |line|
        carrier_key, lft, link, rgt = line.scan(/(.+:)?(.+)\=\=(.+)\=\=\>(.+)/).first

        build_converter(lft)
        build_converter(rgt)
      end
      graph.converters = @converters.values


      lines.each do |line|
        carrier_key, lft, link_str, rgt = line.scan(/(.+:)?(.+)\=\=(.+)\=\=\>(.+)/).first

        link_type, link_share = link(link_str)
        c_lft = build_converter(lft)
        c_rgt = build_converter(rgt)
        carrier = carrier(carrier_key)
        link = graph.
          connect(c_lft, c_rgt, carrier, link_type ).
          with(:share => link_share)
        s_lft, s_rgt = slot(carrier_key)
        c_lft.input(carrier.key).with(s_lft) if s_lft
        c_rgt.output(carrier.key).with(s_rgt) if s_rgt
      end

      graph
    end
  
    # s => :share, nil
    # s(1.0) => :share, 1.0
    def link(str)
      link_type = LINK_TYPES[str[0]]
      link_share = str.gsub(/[^\d^\.]/, '') == '' ? nil : str.gsub(/[^\d^\.]/,'').to_f
      [link_type, link_share]
    end

    # el: => nil
    # el[1.0]: => [{:conversion => 1.0}, nil]
    # el[1.0,dyn]: => [{:conversion => 1.0, :dynamic => 1}, nil]
    # el[1.0,dyn;0.5]: => [{:conversion => 1.0, :dynamic => 1}, {:conversion => 0.5}]
    def slot(carrier_key)
      if carrier_key and slots = carrier_key.match(/.+\[(.+)\]:/).andand.captures.andand.first
        lft_conversion, rgt_conversion = slots.split(';')
        r = []
        r << {:conversion => lft_conversion.to_f} if lft_conversion
        r << {:conversion => rgt_conversion.to_f} if rgt_conversion
        r
      end
    end

    # el:
    # el[1.0,dyn]
    # el[1.0;1.0]
    # el[0.5;1.0]
    def carrier(str)
      carrier_key = str.nil? ? 'el' : str.match(/^(\w+).*:/).captures.first
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
  