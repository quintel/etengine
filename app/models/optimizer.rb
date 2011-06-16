##
# 
#
class Optimizer
  include ActiveSupport::Inflector
  attr_reader :steps, :slider_controls, :gquery_controls, :id

  def initialize(slider_controls, gquery_controls = nil)
    @id = Time.now.to_i
    @slider_controls = slider_controls
    @gquery_controls = gquery_controls
    @scenario = Current.scenario

    @steps = []
  end

  def save
    File.open(File.join("tmp","optimizer.#{self.id}"), 'wb') do |f|
      f << Marshal.dump(self)
    end
  end

  def self.load(id)
    Marshal.load(File.read(File.join("tmp","optimizer.#{id}")))
  end

  def gql
    Current.gql
  end

  ##
  # This is more of a safety measure, run this at the end of a page
  #  prevents screwups. E.g. If you update the gql somewhere in your
  #  view files. I don't think it's needed anymore. Or if, then move this 
  #  #load or #initialize.
  #
  def load_last_step
    mission.reload_gql!(steps.last.step_settings)
  end

  def next_step!
    @next_step = nil
    next_step
  end

  def next_step
    unless @next_step 
      @next_step = Opt::Step.new(mission)
      @next_step.calculate
      add_step(@next_step)
    end
    @next_step
  end

  def add_step(step)
    max_steps_length = -[30, @steps.length].min #
    @steps = @steps[max_steps_length..-1]
    @steps << step
  end

  def input_elements
    @slider_controls.map(&:input_element)
  end

  def mission
    @mission ||= Opt::Mission.new(@slider_controls, @gquery_controls)
  end

  def reset_gql
    Current.teardown_after_request!
  end

  ## DEPRECATED this doesn't seem to be used anywhere anymore (seb 2011-02-01)
  #
  # calculation is put here and not in Input#step_value_in_PJ 
  # because like this we can calculate them in one batch.
  #
  # def step_values_in_pj
  #   @step_values_in_PJ ||= Rails.cache.fetch("optimizer.step_values_in_pj") do
  #     step_values_in_PJ = Hash.new
  #     primary_demand_normal = Current.gql.query('future:SUM(V(G(final_demand_cbs);primary_demand))')
  # 
  #     input_elements.shuffle.each do |input_element|
  #       value = input_element.start_value + input_element.step_value
  #       step_size_100 = (input_element.max_value - input_element.min_value) / 100
  # 
  #       Current.teardown_after_request!
  #       input_element.update_current(value) # Current.user_updates(...)
  # 
  #       primary_demand_after_step = Current.gql.query('future:SUM(V(G(final_demand_cbs);primary_demand))')
  #       difference = primary_demand_after_step - primary_demand_normal
  #       if difference.nil? or difference == 0.0
  #         difference = step_size_100.to_f
  #       end
  # 
  #       step_values_in_PJ[input_element.id] = difference.abs
  #     end
  # 
  #     step_values_in_PJ
  #   end
  # end
  # 
  # def step_value_PJ(input_element)
  #   change = step_values_in_pj[input_element.id]
  #   if change.nil? or change == 0.0
  #     input_element.step_value
  #   else
  #     1_000_000_000 / change
  #   end
  # end

  def to_json
    ActiveSupport::JSON.encode({:slider_controls => self.slider_controls.to_json}) 
  end
  
private
  

end