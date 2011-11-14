module Etsource
  class Dataset
    def initialize(etsource)
      @etsource = etsource || Etsource::Base.new
    end

    def import!
    end

    def base_dir
      "#{@etsource.base_dir}/datasets"
    end

    # @param [String] country shortcut 'de', 'nl', etc
    #
    def country_dir(country)
      "#{base_dir}/#{country}/export.yml"
    end

    def import
      country = 'nl'
      yml = YAML::load(File.read(country_dir(country)))
      fnv = FNV.new
      dataset = {}
      yml.each do |k,v|
        dataset[fnv.fnv1a_32(k.to_s)] = v
      end
      dataset
    end
    
    def export
      country = 'nl'
      
      gql = Gql::Gql.new(::Graph.latest_from_country(country), ::Dataset.latest_from_country(country))
      FileUtils.mkdir_p country_dir(country)
      
      File.open(country_dir(country), 'w') do |out|
        out << '---'
        g = gql.tap(&:assign_dataset).future_graph # the future graph is not calculated.
        g.converters.each do |converter|
          out << YAML::dump({converter.topology_key => converter.object_dataset}).gsub(/^\"/,'').gsub('":',':').gsub('---','')
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