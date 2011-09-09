##
# Helpers that are used in the backend area, and not used for the user area
#
module BackendHelper
  def print_array_tree(array_of_arrays)
    haml_tag :ul do
      array_of_arrays.each do |el|
        if el.is_a?(Array)
          haml_tag :li do
            str = el.first.to_s
            str += ": "+@converter.query(el.first).to_s if @converter and @converter.query.respond_to?(el.first)
            haml_concat str
            print_array_tree(el[1..-1])
          end
        else
          haml_tag :li, el.to_s
        end
      end
    end
  end
end
