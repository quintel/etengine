module Gql
##
# ResultSet of a GQL query.
# Currently inherits from Array for backwards compatibility.
#
class GqueryResult < Array
  include ActiveModel::Serialization

  def present
    first
  end

  def future
    last
  end

  def present_value
    present.last
  end

  def future_value
    future.last
  end
  alias target_value future_value

  def present_year
    present.first
  end

  def future_year
    future.first
  end

  ##
  # Method to easily convert "old" results.
  # @deprecated
  #
  def self.create(arr)
    result = GqueryResult.new
    arr.each {|row| result << row}
    result
  end
end
end
