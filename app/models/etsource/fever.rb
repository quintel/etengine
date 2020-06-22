module Etsource
  module Fever
    module_function

    FeverConfig = Struct.new(:name, :keys_by_type) do
      # Public: Retrieves an array of node keys for the given Fever participant
      # type.
      #
      # For example:
      #   conf.keys(:producer)
      #   # => [:node_one, :node_two, ...]
      #
      # Returns an array of symbols.
      def keys(type)
        keys_by_type[type] || []
      end

      # Public: Returns if there are any nodes belonging to the given type.
      #
      # Returns true or false.
      def any_of_type?(type)
        keys_by_type[type]&.any?
      end
    end

    # Public: Reads the Fever information from the Atlas node list.
    #
    # Returns a Hash where each key is the Fever participant "group"
    # ("hot_water",  "space_heating", etc), and each value is a Hash in
    # the form {Node#key => Node#fever}.
    def groups
      Rails.cache.fetch('fever_data') do
        grouped_nodes = Atlas::Node.all.select(&:fever).group_by do |node|
          node.fever.group
        end

        Config.fever.map do |group_name|
          FeverConfig.new(
            group_name,
            grouped_nodes[group_name]
              .group_by { |node| node.fever.type }
              .transform_values { |nodes| nodes.map(&:key) }
          )
        end
      end
    end

    # Public: Retrieves the configuration for a single named Fever group.
    def group(name)
      groups.detect { |group| group.name == name } ||
        raise("No such Fever group: #{name.inspect}")
    end
  end
end
