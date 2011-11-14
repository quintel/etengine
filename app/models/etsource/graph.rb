module Etsource
  class Graph
    def initialize(etsource)
      @etsource = etsource
    end

    def import!
    end

    def base_dir
      "#{@etsource.base_dir}/topology"
    end

    def import
      ids = []

      converters, slot_lines, link_lines = [], [], []
      
      Dir.glob("#{base_dir}/*.topology").each do |f|
        lines = File.read(f).lines
        converters += lines.select{|l| l =~ /^\[\w+\];/ }.map{|l| Qernel::Converter.import(l) }.group_by(&:code)
        slot_lines += lines.select{|l| l =~ /^\[\w+\]-\(\w+\)/ } # match [ABC0123]-(ADasdf2)
        link_lines += lines.select{|l| l =~ /--\w-->/ } # 
      end
      
    end
    
    def export
    end
    
    def export_topology
      
      File.open("#{base_dir}/#{export.topology}", 'w') do |out|
        Current.gql.tap(&:assign_dataset).present_graph.converters.each do |converter|
          out << converter.to_topology
          out << "\n\n"
        end
      end
    end
    
    def export_dataset
      #File.mkdir_p("#{base_dir}/dataset/")

      File.open("#{base_dir}/dataset/export.yml", 'w') do |out|
        out << '---'
        g = Current.gql.tap(&:assign_dataset).future_graph # the future graph is not calculated.
        g.converters.each do |converter|
          out << YAML::dump({converter.topology_key => converter.object_dataset}).gsub('"[','[').gsub(']"',']').gsub('---','')
          converter.outputs.each do |slot|
            out << "#{slot.topology_key}: #{slot.object_dataset.inspect}\n"
          end
          converter.inputs.each do |slot|
            out << "#{slot.topology_key}: #{slot.object_dataset.inspect}\n"
            slot.links.each do |link|
              out << "#{link.topology_key}: #{link.object_dataset.inspect}\n"
            end
          end
        end
      end
    end
    
  end
end