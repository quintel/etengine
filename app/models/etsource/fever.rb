module Etsource
  module Fever
    module_function

    # Public: Reads the Fever information from the Atlas node list.
    #
    # Returns a Hash where each key is the Fever participant "group"
    # ("hot_water",  "space_heating", etc), and each value is a Hash in
    # the form {Node#key => Node#fever}.
    def data
      Rails.cache.fetch('fever_data') do
        grouped = Atlas::Node.all.select(&:fever).group_by do |node|
          node.fever.group
        end

        grouped.each_with_object({}) do |(group, nodes), data|
          data[group] =
            nodes.each_with_object({}) do |node, bt|
              (bt[node.fever.type] ||= []).push(node.key)
            end
        end
      end
    end
  end
end
