class BlackboxScenario < ActiveRecord::Base
  before_validation :copy_scenario_state


  def deviation_total(blackbox_gqueries, blackbox_output_series)
    deviation_of_output_series(blackbox_output_series) +
      deviation_of_gqueries(blackbox_gqueries)
  end

  def deviation_of_output_series(blackbox_output_series)
    unless @deviation_of_output_series
      series = blackbox_output_series.select{|q| q.blackbox_scenario_id == self.id}
      @deviation_of_output_series = series.map(&:deviation).sum
    end
    @deviation_of_output_series
  end

  def deviation_of_gqueries(blackbox_gqueries)
    unless @deviation_of_gqueries
      gqueries = blackbox_gqueries.select{|q| q.blackbox_scenario_id == self.id}
      @deviation_of_gqueries = gqueries.map(&:deviation).sum
    end
    @deviation_of_gqueries
  end

  def scenario_items(blackbox, items)
    items.select{|item| item.blackbox_scenario_id == self.id}
  end

  def load_scenario
    Current.reset_to_default_scenario!
    Current.scenario.update_statements = update_statements
    Current.scenario.user_values = user_values

    Current.gql = Current.graph.create_gql
  end

  def copy_scenario_state
    self[:update_statements] = Current.scenario.update_statements
    self[:user_values] = Current.scenario.user_values
  end

  def user_values
    if self[:user_values].is_a?(String)
      YAML::load(self[:user_values])
    else
      self[:user_values]
    end
  end

  def update_statements
    if self[:update_statements].is_a?(String)
      YAML::load(self[:update_statements])
    else
      self[:update_statements]
    end
  end
end


# == Schema Information
#
# Table name: blackbox_scenarios
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  description       :text
#  user_values       :text
#  update_statements :text
#  created_at        :datetime
#  updated_at        :datetime
#

