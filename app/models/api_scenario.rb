# == Schema Information
#
# Table name: scenarios
#
#  id                 :integer(4)      not null, primary key
#  author             :string(255)
#  title              :string(255)
#  description        :text
#  user_updates       :text
#  created_at         :datetime
#  updated_at         :datetime
#  user_values        :text
#  end_year           :integer(4)      default(2040)
#  country            :string(255)
#  in_start_menu      :boolean(1)
#  region             :string(255)
#  user_id            :integer(4)
#  complexity         :integer(4)      default(3)
#  scenario_type      :string(255)
#  preset_scenario_id :integer(4)
#  type               :string(255)
#  use_fce            :boolean(1)
#  present_updated_at :datetime
#

class ApiScenario < Scenario
  # Expired ApiScenario will be deleted by rake task :clean_expired_api_scenarios
  scope :expired, lambda { where(['updated_at < ?', Date.today - 14]) }
  scope :recent, order("created_at DESC").limit(20)

  def self.new_attributes(settings = {})
    settings ||= {}
    attributes = Scenario.default_attributes.merge(:title => "API")
    attributes.merge(settings)
  end

  def save_as_scenario(params = {})
    params ||= {}
    attributes = self.attributes.merge(params)
    Scenario.create!(attributes)
  end

  def scenario_id=(scenario_id)
    unless scenario_id.blank?
      if scenario = Scenario.find(scenario_id)
        copy_scenario_state(scenario)
        preset_scenario_id = scenario_id
      end
    end
  end

  def identifier
    "##{id} - #{country} (#{end_year}) "
  end

  def api_errors
    if used_groups_add_up?
       []
    else
      groups = used_groups_not_adding_up
      remove_groups_and_elements_not_adding_up!
      groups.map do |group, elements|
        element_ids = elements.map{|e| "#{e.id} [#{e.key || 'no_key'}]" }.join(', ')
        "Group '#{group}' does not add up to 100. Elements (#{element_ids}) "
      end
    end
  end

  # used for api/v1/api_scenarios.json
  def as_json(options={})
    super(
      :only => [:user_values, :country, :region, :end_year, :start_year, :id, :use_fce]
    )
  end
end
