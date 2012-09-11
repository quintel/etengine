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
      # the slots as needed
      slot_tokens = []
      topology_hash.each_pair do |c_key, values|
        slot_lines = ((values['slots'] || []) + (values['links'] || []))
        slot_tokens << slot_lines.map{|line| Qernel::Slot::Token.find(line)}.flatten
      end

      slot_tokens.flatten.uniq_by{|t| t.key.strip}.each do |token|
        converter = converters[token.converter_key.to_sym]
        slot = Qernel::Slot.new(token.key, converter, carrier(token), token.direction)
        converter.add_slot(slot) # DEBT: after removing of Blueprint::Models we can simplify this
      end

      topology_hash.each_pair do |converter_key, values|
        (values['links'] || []).each do |line|
          link = Qernel::Link::Token.find(line)
          next unless link.is_a?(Qernel::Topology::Link::Token)
          link = Qernel::Link.new(link.key,
                                  converters[link.input_key],
                                  converters[link.output_key],
                                  carrier(link),
                                  link.link_type)
          link.graph = graph
        end
      end

      graph.carriers.each {|c| c.graph = graph}
      graph.connect_qernel
      graph
    end

    # writes to disk *in the working copy directory*
    #
    def export
      FileUtils.mkdir_p(base_dir)
      File.open(topology_file, 'w') do |out|
        gql = Scenario.default.gql(prepare: false)
        gql.present_graph.converters.each do |converter|
          out << converter.to_topology
          out << "\n\n"
        end
      end
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
end
