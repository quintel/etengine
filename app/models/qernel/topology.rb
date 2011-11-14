module Qernel
  module Topology
    module Converter
      extend ActiveSupport::Concern

      SEPARATOR = ";"
      GROUPS_SEPARATOR = ','

      module InstanceMethods
        def topology_key
          code = (self.code || self.full_key.to_s.split("_").map{|k| k[0]}.join('').upcase).to_s
          code = "00#{code}" if code.length == 1
          code = "0#{code}" if code.length == 2
          "#{code}"
        end

        def to_topology
          [
            [topology_key, key, sector_key, use_key, energy_balance_group, groups.join(GROUPS_SEPARATOR)].join(";\t"),
            inputs.map(&:to_topology),
            outputs.map(&:to_topology)
          ].join("\n")
        end
      end
      
      module ClassMethods
        def import(line)
          code, key, sector_key, use_key, energy_balance_group, groups = line.split(SEPARATOR).map(&:strip).map(&:to_sym)
          groups = groups.to_s.split(GROUPS_SEPARATOR).map(&:to_sym)
          code = code.to_s.scan(/\w+/).first.to_sym
          
          Qernel::Converter.new(code, key, sector_key, use_key, groups, energy_balance_group)
        end
      end
    end
    
    module Link
      LINK_SEPARATOR = ";\t"

      def topology_key
        "#{input.andand.topology_key} -- #{link_type.to_s[0]} --> #{output.andand.topology_key}"
      end

      def to_topology
        topology_key
      end
    end
    
    module SlotMethods
      SLOT_SEPARATOR = ";\t"

      def topology_key
        first,second = carrier.key.to_s.split("_")
        carrier_code = first[0]+(second.andand[0] || first[1])
        carrier_code.upcase!
        
        if direction == :input
          "#{converter.topology_key}-(#{carrier_code})"
        else
          "(#{carrier_code})-#{converter.topology_key}"
        end
      end

      def to_topology
        arr = []
        if input?
          arr << topology_key if links.empty? && input?
          arr += links.map(&:to_topology)
        elsif output?
          arr << "#{topology_key} # #{links.length} links to: #{links.map{|l| l.child.topology_key}.join(', ')}"
        end
        arr.join("\n")
      end
    end
    
    module CarrierMethods
    end    
  end
end