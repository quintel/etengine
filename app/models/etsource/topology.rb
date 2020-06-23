module Etsource
  class Topology
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def graph(country = 'nl')
      @graph ||= import
      @graph.dataset = Etsource::Dataset.new(country).import
      @graph
    end

    def import
      graph = Qernel::Graph.new(node_hash.values)

      create_explicit_slots!
      establish_edges!

      graph.assign_graph_to_qernel_objects

      graph
    end

    def carrier(obj)
      key = obj.respond_to?(:carrier_key) ? obj.carrier_key : obj
      @carriers ||= {}
      @carriers[key] ||= Qernel::Carrier.new(key: key)
    end

    #########
    protected
    #########

    # working copy
    def base_dir
      "#{@etsource.export_dir}/topology"
    end

    # export, read-only dir
    def export_dir
      "#{@etsource.export_dir}/topology"
    end

    #######
    private
    #######

    def create_explicit_slots!
      Atlas::Node.all.each do |node|
        (node.in_slots + node.out_slots).each do |slot|
          conv = node(node.key)
          conv.add_slot(FromAtlas.slot(slot, conv, carrier(slot.carrier)))
        end
      end
    end

    def establish_edges!
      Atlas::Edge.all.each do |edge|
        supplier = node(edge.supplier)
        consumer = node(edge.consumer)
        carrier  = carrier(edge.carrier)

        # Some slots are not explicitly defined as "input" or "output"
        # attributes on the node document, so we add them here.

        unless supplier.output(edge.carrier)
          supplier.add_slot(FromAtlas.slot_from_data(supplier, carrier, :out))
        end

        unless consumer.input(edge.carrier)
          consumer.add_slot(FromAtlas.slot_from_data(consumer, carrier, :in))
        end

        FromAtlas.edge!(edge, consumer, supplier, carrier)
      end
    end

    # Internal: Returns a hash of all the node objects, where each key
    # is the key of the node, and each value the node itself.
    #
    # Returns a Hash.
    def node_hash
      @node_hash ||=
        Atlas::Node.all.each_with_object({}) do |node, collection|
          collection[node.key] = FromAtlas.node(node)
        end
    end

    # Internal: Returns an the node whose key matches +key+.
    #
    # Returns a Qernel::Node.
    def node(key)
      node_hash[key]
    end
  end

  # Extract keys from a Slot Topology String
  #    Token.new("FOO-(HW) -- s --> (HW)-BAR")
  #    => <Token carrier_key:HW, output_key:BAR, input_key:FOO, edge_type: :share>
  #
  class EdgeToken
    attr_reader :input_key, :carrier_key, :output_key, :key, :edge_type, :reversed

    LINK_TYPES = {
      's' => :share,
      'f' => :flexible,
      'i' => :inversed_flexible,
      'd' => :dependent,
      'c' => :constant
    }

    def initialize(line)
      line.gsub!(/#.+/, '')
      line.strip!
      line.gsub!(/\s+/,'')
      @key = line

      input, output = SlotToken.find(line)

      Rails.logger.warn("No Slots '#{line}'") if input.nil? or output.nil?
      Rails.logger.warn("Carriers do not match in '#{line}'") if input.carrier_key != output.carrier_key
      @carrier_key = input.carrier_key
      @input_key   = input.node_key
      @output_key  = output.node_key
      @reversed    = line.include?('<')
      @edge_type   = LINK_TYPES[line.gsub(/\s+/,'').scan(/-(\w)-/).flatten.first]
    end

    # Matches:
    #
    # )<--s--(
    # )--s-->(
    #
    def self.find(line)
      if line.gsub(/\s/,'') =~ /\)<?--\w-->?\(/
        new(line)
      else
        []
      end
    end
  end

  # Extract keys from a Slot Topology String
  #    Token.new("(HW)-FOO")
  #    t.node_key # => :FOO
  #    t.carrier_key # => :HW
  #    t.direction # => :output
  #    t.key # => HW-FOO
  #
  class SlotToken
    attr_reader :node_key, :carrier_key, :direction, :key

    MATCHER = /
      (\w+-\(\w+\)|\(\w+\)-\w+)  # (carrier)-node_key
      (?::\s?                    # Non-matching group containing hash data.
       (\{.+\})                  # Data hash.
      )?                         # Data is optional.
    /x

    def initialize(line, data = nil)
      @key  = line.gsub(/#.+/, '').strip
      @data = data

      @node_key, @carrier_key = if line.include?(')-')
        @direction = :output
        @key.split('-').reverse.map(&:to_sym)
      else
        @direction = :input
        @key.split('-').map(&:to_sym)
      end
      @carrier_key = @carrier_key.to_s.gsub(/[\(\)]/, '').to_sym
    end

    def data(key)
      @data && @data[key]
    end

    def eql?(other)
      @key == other.key
    end

    def hash
      @key.hash
    end

    # @return [Array] all the slots in a given string.
    def self.find(line)
      line.scan(SlotToken::MATCHER).map do |(full_key, data)|
        new(full_key, data && eval(data))
      end
    end
  end
end
