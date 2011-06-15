# == Schema Information
#
# Table name: blackbox_gqueries
#
#  id                   :integer(4)      not null, primary key
#  blackbox_id          :integer(4)
#  blackbox_scenario_id :integer(4)
#  gquery_id            :integer(4)
#  present_value        :integer(30)
#  future_value         :integer(30)
#  created_at           :datetime
#  updated_at           :datetime
#

class BlackboxGquery < ActiveRecord::Base
  belongs_to :blackbox
  belongs_to :gquery
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
    if gquery
      @result ||= Current.gql.query(Gql::Gquery::CleanerParser.clean(gquery.query))
      @result.map(&:last).map{|re| re.respond_to?(:to_i) ? re.to_i : nil }
    else # if gquery has been deleted
      [nil,nil]
    end
  end

  def current_present_value
    result.first
  end

  def current_future_value
    result.last
  end
end

