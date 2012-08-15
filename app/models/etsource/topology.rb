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

      # Load the converter groups from the topology/groups.yml
      # and convert the {group_1: [converter_1, converter_2], ...} into
      # {converter_1: [group_1, group_2], ...}
      groups = YAML::load_file("#{base_dir}/groups.yml")
      groups.each do |group, converter_keys|
        group = group.to_sym
        converter_keys.each do |key|
          converter_groups[key.to_sym] << group
        end
      end

      # Loads converters and puts into converters hash. Attaches
      # the previously loaded groups.
      each_file do |lines|
        # Initialize all converters first, before we map slots and links to them.
        lines.select{|l| l =~ /^\w+;/ }.each do |l|
          attrs          = Qernel::Converter.attributes_from_line(l)
          attrs[:groups] = converter_groups[attrs[:key]]

          converter      = Qernel::Converter.new( attrs )
          converters[converter.key] = converter
        end
      end

      # Connect converters with
      graph = Qernel::Graph.new(converters.values)

      each_file do |lines|
        lines.map{|l| Qernel::Slot::Token.find(l) }.flatten.uniq(&:key).each do |token|
          converter = converters[token.converter_key]
          slot = Qernel::Slot.new(token.key, converter, carrier(token), token.direction)
          converter.add_slot(slot) # DEBT: after removing of Blueprint::Models we can simplify this
        end

        lines.map{|l| Qernel::Link::Token.find(l) }.flatten.each do |link|
          link = Qernel::Link.new(link.key, converters[link.input_key], converters[link.output_key], carrier(link), link.link_type)
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

    def each_file(&block)
      Dir.glob("#{export_dir}/*.graph").each do |f|
        lines = File.read(f).lines
        yield lines if block_given?
      end
    end

  protected

    def topology_file
      "#{base_dir}/export.graph"
    end

    # working copy
    def base_dir
      "#{@etsource.base_dir}/topology"
    end

    # export, read-only dir
    def export_dir
      "#{@etsource.export_dir}/topology"
    end

  end
end
