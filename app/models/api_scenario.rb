# == Schema Information
#
# Table name: scenarios
#
#  id                 :integer(4)      not null, primary key
#  author             :string(255)
#  title              :string(255)
#  description        :text
#  created_at         :datetime
#  updated_at         :datetime
#  user_values        :text
#  end_year           :integer(4)      default(2040)
#  country            :string(255)
#  in_start_menu      :boolean(1)
#  region             :string(255)
#  user_id            :integer(4)
#  preset_scenario_id :integer(4)
#  type               :string(255)
#  use_fce            :boolean(1)
#  present_updated_at :datetime
#  protected          :integer(1)
#

class ApiScenario < Scenario
  # Expired ApiScenario will be deleted by rake task :clean_expired_api_scenarios
  scope :expired, lambda { where(['updated_at < ?', Date.today - 14]) }
  scope :recent, order("created_at DESC").limit(30)

  attr_accessible :scenario_id

  def self.new_attributes(settings = {})
    settings ||= {}
    attributes = Scenario.default_attributes.merge(:title => "API")
    out = attributes.merge(settings)
    # strip invalid attributes
    valid_attributes = [column_names, 'scenario_id'].flatten
    out.delete_if{|key,v| !valid_attributes.include?(key.to_s)}
    out
  end

  def gql(options = {})
    # Passing a scenario as an argument to the gql will load the graph and dataset from ETsource.
    @gql ||= Gql::Gql.new(self)
    # At this point gql is not "prepared" see {Gql::Gql#prepare}.
    # We could force it here to always prepare, but that would slow things down
    # when nothing has changed in a scenario. Uncommenting this would decrease performance
    # but could get rid of bugs introduced by forgetting to prepare in some cases when we
    # access the graph through the gql (e.g. @gql.present_graph.converters.map(&:demand)).

    prepare_gql if options[:prepare] == true
    @gql
  end

  def prepare_gql
    gql.prepare
    gql
  end

  # The values for the sliders for this api_scenario
  #
  def input_values
    prepare_gql

    values = Rails.cache.fetch("inputs.user_values.#{area_code}") do
      Input.static_values(gql)
    end

    Input.dynamic_start_values(gql).each do |id, dynamic_values|
      values[id][:start_value] = dynamic_values[:start_value] if values[id]
    end

    self.user_values.each do |id, user_value|
      values[id][:user_value] = user_value if values[id]
    end

    values
  end

  def save_as_scenario(params = {})
    params ||= {}
    attributes = self.attributes.merge(params)
    Scenario.create!(attributes)
  end

  def scenario_id=(scenario_id)
    return if scenario_id.blank?
    if scenario = Scenario.find_by_id(scenario_id)
      copy_scenario_state(scenario)
      self.preset_scenario_id = scenario_id
    end
  end

  # a identifier for the scenario selector drop down in data.
  # => "#32341 - nl 2040 (2011-01-11)"
  def identifier
    "##{id} - #{area_code} #{end_year} (#{created_at.strftime("%m-%d %H:%M")})"
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

  # API requests make use of this. Check Api::ApiScenariosController#new
  #
  def as_json(options={})
    super(
      :only => [:user_values, :area_code, :end_year, :start_year, :id, :use_fce]
    )
  end
end
