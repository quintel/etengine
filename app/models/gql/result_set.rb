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
    present[1]
  end

  def future_value
    future[1]
  end
  alias target_value future_value

  def present_year
    present[0]
  end

  def future_year
    future[0]
  end

  def present_time
    present[2] || 0.0
  end

  def future_time
    future[2] || 0.0
  end

  def relative_increase_percent
    ((future_value / present_value) - 1.0) * 100.0 rescue nil
  end

  def relative_increase
    (future_value / present_value) - 1.0 rescue nil
  end

  def absolute_increase
    future_value - present_value
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
