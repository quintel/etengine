##
# Performs parsing operations for cleaning/parsing GQL
#

module Gql::Gquery::CleanerParser

  ##
  # Cleans and parses a query for the GQL.
  #
  # @param query_string [String] The query string
  # @return <GqlQueryParser>
  #
  def self.clean_and_parse(query_string)
    parser.parse(clean(query_string))
  end

  ##
  # Cleans a query to be ready for the GQL.
  # Removes all the whitespace.
  #
  # @param query_string [String] The query string
  # @return [String] Query string without whitespace. Empty string if query_string is nil
  #
  def self.clean(query_string)
    query_string ||= ''
    query_string = remove_gql_modifier(query_string)
    query_string = remove_whitespace(query_string)
    query_string = remove_comments(query_string)
    query_string
  end

  ##
  # An instance of GqlParser.
  # e.g.
  # Gql::Gquery.parser.parse("foo")
  #
  # @return <GqlQueryParser>
  #
  def self.parser
    @@parser ||= GqlQueryParser.new
  end

  # checks whether a query can be parsed
  # @param query_string [String] The query string
  # @return [Boolean] true if parsing successful

  def self.check_query(query_string)
    !clean_and_parse(query_string).nil?
  end

private
  def self.remove_gql_modifier(query_string)
    query_string.gsub(Gquery::GQL_MODIFIER_REGEXP,'')
  end

  def self.remove_whitespace(query_string)
    query_string.gsub(/\s/,'')
  end

  def self.remove_comments(query_string)
    # regexp matches /* (everything except */) */
    # everything execpt */ => [^(\*\/)]+
    query_string.gsub(/\/\*[^(\*\/)]+\*\//, '')
  end
end
