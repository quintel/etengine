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

  ##
  # Return the source code of the method.
  # The end line of the method has an end with the same intendation as the method header.
  #
  def method_source(method)
    file, line = method.source_location
    lines = File.read(file).lines.to_a[line-1..-1]

    method_header = lines.first
    intendation = method_header[/^(.*)def/, 1]
    line_of_end_statement = lines.index{|l| l.start_with?("#{intendation}end")}

    lines = lines[0..line_of_end_statement]
    lines.join("")
  end
end
