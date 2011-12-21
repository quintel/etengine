module Etsource
  class Graph

    def initialize(etsource = Etsource::Base.new)
      @etsource = etsource
    end

    def graph(country = 'nl')
      @graph ||= import
      @graph.dataset = Etsource::Dataset.new.dataset(country)
      @graph
    end



    def import
      converters = {}

      each_file do |lines| 
        # Initialize all converters first, before we map slots and links to them.
        hsh = lines.select{|l| l =~ /^\w+;/ }. # only match converter lines
                    map{|l| Qernel::Converter.import(l) }.
                    inject({}) {|h,k| h.merge k.code => k}
        converters.merge!(hsh)
      end
      
      graph = Qernel::Graph.new(converters.values).tap{|g| g.connect_qernel }

      each_file do |lines|
        lines.map{|l| Qernel::Slot::Token.find(l) }.flatten.uniq(&:code).each do |token|
          converter = converters[token.converter_key]
          slot = Qernel::Slot.new(token.code, converter, carrier(token), token.direction)
          slot.graph = graph
          converter.add_slot(slot) # DEBT: after removing of Blueprint::Models we can simplify this
        end

        lines.map{|l| Qernel::Link::Token.find(l) }.flatten.each do |link|
          link = Qernel::Link.new(link.code, converters[link.input_key], converters[link.output_key], carrier(link), link.link_type)
          link.graph = graph
        end
      end

      
      graph.carriers.each {|c| c.graph = graph}
      graph
    end
    
    def export
      FileUtils.mkdir_p(base_dir)
      File.open(topology_file, 'w') do |out|
        # Current.gql.prepare
        Current.gql.present_graph.converters.each do |converter|
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

  #########
  protected
  #########

    def each_file(&block)
      Dir.glob("#{base_dir}/*.graph").each do |f|
        lines = File.read(f).lines
        yield lines if block_given?
      end
    end
    
    def topology_file
      "#{base_dir}/export.graph"
    end

    def base_dir
      "#{@etsource.base_dir}/graph"
    end

  end
end