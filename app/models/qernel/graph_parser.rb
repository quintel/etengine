module Qernel
  class GraphParser
    attr_reader :lines

    CARRIERS_FOR_SPECS = {
      # Carriers used in the Specs
      'foo'          => Carrier.new(id: 2, key: 'foo',  infinite: 1.0).with({}),
      'bar'          => Carrier.new(id: 3, key: 'bar',  infinite: 1.0).with({}),
      'loss'         => Carrier.new(id: 1, key: 'loss', infinite: 0.0),
      'electricity'  => Carrier.new(id: 5, key: 'electricity', infinite: 0.0),
      'cooling'      => Carrier.new(id: 6, key: 'cooling', infinite: 0.0),
      'useable_heat' => Carrier.new(id: 7, key: 'useable_heat', infinite: 0.0)
    }

    CARRIERS = {}.merge(CARRIERS_FOR_SPECS)

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

    def self.gql_stubbed(g)
      raise "GraphParser.gql_stubbed only workds in test" unless Rails.env.test?
      gql = Gql::Gql.new(nil)
      gql.scenario = Scenario.default

      p = new(g).build
      f = new(g).build

      p.stub!(:dataset).and_return(Dataset.new)
      f.stub!(:dataset).and_return(Dataset.new)

      gql.stub!(:present_graph).and_return( p )
      gql.stub!(:future_graph ).and_return( f )

      gql
    end

    def build
      slots = []
      graph = Graph.new.with({})
      graph.area = Area.new.with({})

      # create converters first
      lines.each do |line|
        carrier_key, lft, link, rgt = line.scan(/(.+:)?(.+)\=\=(.+)\=\=[\>\<](.+)/).first

        build_converter(lft)
        build_converter(rgt)
      end
      graph.converters = @converters.values


      lines.each do |line|
        carrier_key, lft, link_str, rgt = line.scan(/(.+:)?(.+)\=\=(.+\=\=[\>\<])(.+)/).first

        link_type, link_share, reversed = link(link_str)
        c_lft = build_converter(lft)
        c_rgt = build_converter(rgt)
        carrier = carrier(carrier_key)

        link = graph.
          connect(c_lft, c_rgt, carrier, link_type, *slot_types(line)).
          with(:share => link_share)
        link.reversed = reversed

        s_lft, s_rgt = slot(carrier_key)
        c_lft.input(carrier.key).with(s_lft) if s_lft
        c_rgt.output(carrier.key).with(s_rgt) if s_rgt
      end

      graph.assign_graph_to_qernel_objects
      graph.refresh_dataset_attributes
      graph
    end

    # s => :share, nil
    # s(1.0) => :share, 1.0
    def link(str)
      reversed = str[-1] == "<"
      str = str[0..-2]
      link_type = LINK_TYPES[str[0]]
      link_share = str.gsub(/[^\d^\.]/, '') == '' ? nil : str.gsub(/[^\d^\.]/,'').to_f
      [link_type, link_share, reversed]
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

    # Given a full converter/link line, returns any custom slot types to be
    # used at either end of the link.
    #
    # @example
    #   "electricity: l == s ==> r"                  # => []
    #   "electricity[0.4;0.4]: l == s ==> r"         # => []
    #   "electricity[0.4(elastic);0.4] l == s ==> r" # => [:elastic, nil]
    #   "electricity[0.4;0.4(elastic)] l == s ==> r" # => [nil, :elastic]
    def slot_types(str)
      if match = str.match(/\[(.*)\]/)
        match[1].split(';').map do |slot_str|
          (type = slot_str.match(/\((.*)\)/)) && type[1].to_sym
        end
      else
        Array.new
      end
    end

    # el:
    # el[1.0,dyn]
    # el[1.0;1.0]
    # el[0.5;1.0]
    def carrier(str)
      carrier_key = str.nil? ? 'foo' : str.match(/^(\w+).*:/).captures.first
      CARRIERS[carrier_key]
    end

    def build_converter(str, carrier = nil)
      key, dataset = str.scan(/([A-Za-z_0-9]+)(\(\d+\))?/).first
      key = key.to_sym

      unless @converters[key]
        id = @converters.keys.length+1
        demand = dataset.nil? ? nil : dataset.gsub(/\D/,'').to_f
        dataset = {:demand => demand, :preset_demand => demand } # preset_demand needed to make old Input v1 updates working
        @converters[key] = Converter.new(id: id, key: key).with(dataset)
      end

      @converters[key]
    end


  end
end

