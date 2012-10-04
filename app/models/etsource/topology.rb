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
      converters = {}
      converter_groups = Hash.new { |hash, key| hash[key] = [] }

      # Load the converter groups from the topology/groups/*.yml
      # creating a in this format:
      # {converter_1: [group_1, group_2], ...}
      Dir.glob("#{base_dir}/groups/*.yml").each do |file|
        group_name = File.basename(file, '.yml').to_sym
        items = YAML::load_file(file)
        items.each do |key|
          converter_groups[key.to_sym] << group_name
        end
      end

      # Loads converters and puts into converters hash. Attaches
      # the previously loaded groups.
      topology_hash.each_pair do |key, attrs|
        # Initialize all converters first, before we map slots and links to them.
        converter_key = key.to_sym

        converter = Qernel::Converter.new({
          key:                  converter_key,
          sector_id:            attrs['sector'].try(:to_sym),
          use_id:               attrs['use'].try(:to_sym),
          energy_balance_group: attrs['energy_balance_group'].try(:to_sym),
          groups:               converter_groups[converter_key]
        })
        converters[converter_key] = converter
      end

      # Connect converters with
      graph = Qernel::Graph.new(converters.values)

      # The new export.graph uses yaml. The old format was parsed line by line,
      # now we must parse the entire structure. A slot object can be built from
      # a link and a slot line, so we merge them, remove duplicates and create
      # the slots as needed.
      slot_tokens      = Set.new
      slots_from_links = Set.new

      topology_hash.each_pair do |c_key, values|
        # First we create slot tokens by parsing the defined "slots"; this
        # data will contain the most precise definition of the slot (with
        # optional data).
        (values['slots'] || []).each do |line|
          slot_tokens.add(SlotToken.find(line).first)
        end

        # Then we go through each link to add any slots which weren't
        # explicitly defined in the "slots" section.
        (values['links'] || []).each do |line|
          SlotToken.find(line).each { |token| slots_from_links.add(token) }
        end
      end

      slot_tokens.merge(slots_from_links).each do |token|
        converter = converters[token.converter_key]

        slot = Qernel::Slot.factory(
          token.data(:type), token.key, converter,
          carrier(token), token.direction)

        converter.add_slot(slot) # DEBT: after removing of Blueprint::Models we can simplify this
      end

      topology_hash.each_pair do |converter_key, values|
        (values['links'] || []).each do |line|
          link = LinkToken.find(line)
          next unless link.is_a?(LinkToken)
          link = Qernel::Link.new(link.key,
                                  converters[link.input_key],
                                  converters[link.output_key],
                                  carrier(link),
                                  link.link_type,
                                  link.reversed )
        end
      end

      graph.assign_graph_to_qernel_objects
      graph
    end

    def carrier(obj)
      key = obj.respond_to?(:carrier_key) ? obj.carrier_key : obj
      @carriers ||= {}
      @carriers[key] ||= Qernel::Carrier.new(key: key)
    end

  protected

    def topology_hash
      @topology_hash ||= YAML::load(File.read(topology_file))
    end

    def topology_file
      "#{base_dir}/export.graph"
    end

    # working copy
    def base_dir
      "#{@etsource.export_dir}/topology"
    end

    # export, read-only dir
    def export_dir
      "#{@etsource.export_dir}/topology"
    end
  end

  # Extract keys from a Slot Topology String
  #    Token.new("FOO-(HW) -- s --> (HW)-BAR")
  #    => <Token carrier_key:HW, output_key:BAR, input_key:FOO, link_type: :share>
  #
  class LinkToken
    attr_reader :input_key, :carrier_key, :output_key, :key, :link_type, :reversed

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
      @input_key   = input.converter_key
      @output_key  = output.converter_key
      @reversed    = line.include?('<')
      @link_type   = LINK_TYPES[line.gsub(/\s+/,'').scan(/-(\w)-/).flatten.first]
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
  #    t.converter_key # => :FOO
  #    t.carrier_key # => :HW
  #    t.direction # => :output
  #    t.key # => HW-FOO
  #
  class SlotToken
    attr_reader :converter_key, :carrier_key, :direction, :key

    MATCHER = /
      (\w+-\(\w+\)|\(\w+\)-\w+)  # (carrier)-converter_key
      (?::\s?                    # Non-matching group containing hash data.
       (\{.+\})                  # Data hash.
      )?                         # Data is optional.
    /x

    def initialize(line, data = nil)
      @key  = line.gsub(/#.+/, '').strip
      @data = data

      @converter_key, @carrier_key = if line.include?(')-')
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
