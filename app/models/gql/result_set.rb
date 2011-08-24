module Gql
# ResultSet of a GQL query.
# Currently inherits from Array for backwards compatibility.
#
# DEBT remove that Array dependency. only asks for trouble
class ResultSet < Array
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

  def results
    [present_value, future_value]
  end

  # Method to easily convert "old" results.
  #
  def self.create(arr)
    result = ResultSet.new
    arr.each {|row| result << row}
    result
  end

  INVALID = ResultSet.create([[2010, 'ERROR'], [2040, 'ERROR']])

end
end
