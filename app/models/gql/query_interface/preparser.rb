# Performs parsing operations for cleaning/parsing GQL
#
#
class Gql::QueryInterface::Preparser
  @@parser = GqlQueryParser.new

  def initialize(query)
    @query = query || ''
  end

  # Cleans and parses a query for the GQL. 
  #
  # @return <GqlQueryParser>
  #
  def parsed
    @@parser.parse(clean)
  end

  # Cleans a query to be ready for the GQL.
  # Removes all the whitespace.
  #
  # @return [String] Query string without whitespace. Empty string if query_string is nil
  #
  def clean
    query_string = @query
    query_string = remove_gql_modifier(query_string)
    query_string = remove_whitespace(query_string)
    query_string = remove_comments(query_string)
    query_string
  end


  # @return [Boolean] is it a valid query?
  #
  def valid?
    !parsed.nil?
  end


protected

  def remove_gql_modifier(query_string)
    query_string.gsub(Gquery::GQL_MODIFIER_REGEXP,'')
  end

  def remove_whitespace(query_string)
    query_string.gsub(/\s/,'')
  end

  def remove_comments(query_string)
    # regexp matches /* (everything except */) */
    # everything execpt */ => [^(\*\/)]+
    query_string.gsub(/\/\*[^(\*\/)]+\*\//, '')
  end
end
