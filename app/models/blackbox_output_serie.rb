# == Schema Information
#
# Table name: blackbox_output_series
#
#  id                      :integer(4)      not null, primary key
#  blackbox_id             :integer(4)
#  blackbox_scenario_id    :integer(4)
#  output_element_serie_id :integer(4)
#  present_value           :integer(30)
#  future_value            :integer(30)
#  created_at              :datetime
#  updated_at              :datetime
#

class BlackboxOutputSerie < ActiveRecord::Base
  belongs_to :blackbox
  belongs_to :output_element_serie
  belongs_to :blackbox_scenario

  before_create :calculate_values

  def calculate_values
    self[:present_value] = current_present_value
    self[:future_value] = current_future_value
  end

  def difference_absolute_future
    current_future_value.abs - expected_future_value.abs rescue 0
  end

  def difference_absolute_present
    current_present_value.abs - expected_present_value.abs rescue 0
  end

  def difference_absolute
    [
      difference_absolute_present,
      difference_absolute_future
    ].sum
  end

  def deviation
    return 0 if present_change.nil? or future_change.nil?
    (present_change.abs + future_change.abs).round(4)
  end

  def present_change
    return nil if expected_present_value.nil? or current_present_value.nil?
    return 0.0 if expected_present_value == 0.0 #and current_present_value == 0.0
    ((current_present_value.to_f / expected_present_value) - 1)
  end

  def future_change
    return nil if expected_future_value.nil? or current_future_value.nil?
    return 0.0 if expected_future_value == 0.0 #and current_future_value == 0.0
    ((current_future_value.to_f / expected_future_value) - 1)
  end

  def expected_present_value
    present_value
  end

  def expected_future_value
    future_value
  end

  def reset
    @result = nil
  end

  def result
    @result ||= Current.gql.query(output_element_serie.key)
    return @result.map(&:last).map(&:to_i)
  end

  def current_present_value
    result.first
  end

  def current_future_value
    result.last
  end

end

