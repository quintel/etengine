module Opt
  ##
  # A mission defines all the elements of an optimizer run.
  # - Targets (Gqueries with expected target values and weight)
  # - InputElements (user-defined step_value)
  # - Country, Graph, etc.
  #
  class Mission
    attr_accessor :slider_controls

    ##
    # Put the original attributes of the scenario here.
    # When we reload_gql! the scenario resets its attributes
    # from here before updating the updates from the optimizer. 
    #
    attr_reader :original_scenario_attributes, :original_update_statements

    attr_reader :gquery_controls

    alias_method :slider_controls, :slider_controls

    ##
    #
    # @param [Array<SliderControl>] slider_controls
    # @param [Array<GqueryControl>] gquery_controls
    #
    def initialize(slider_controls, gquery_controls)
      @step_increment = 0
      @slider_controls = slider_controls
      @gquery_controls = gquery_controls

      @original_user_values = Current.scenario.user_values.clone
      @original_update_statements = Current.scenario.update_statements.clone

      assign_groups_to_slider_controls
      move_remainders_to_back
    end

    ##
    # HACK HACK HACK
    # We have to move remainder_sliders to the back, otherwise they
    # get wrong values (because sliders that come after haven't been 
    # properly updated).
    #
    # @deprecated i dont' think this is needed anymore. because the calculation of 
    #   share groups is done differently
    #
    def move_remainders_to_back
      @slider_controls = @slider_controls.sort_by{|sc| (sc.input_element.remainder?) ? 0 : 1}
    end

    ##
    # @return [Hash(String => Array<SliderControl>)] the controls grouped by their share_group
    #
    def groups
      slider_controls.group_by{|sc| sc.input_element.share_group }
    end

    ##
    # Assigns group members to SliderGroupControls
    #
    def assign_groups_to_slider_controls
      groups.each do |group, slider_controls|
        next if group.blank?
        slider_controls.each do |slider_control|
          slider_control.group_sliders = slider_controls
        end
      end
    end

    ##
    # {Step} uses this to count its step increment
    #
    # @return [Integer]
    #
    def next_step_increment!
      @step_increment += 1
    end

    #
    # I don't think anymore they belong here. 
    # When time: move to step.rb
    #


    ##
    # Reset the GQL and apply the given settings.
    #
    # @param [Hash(SliderControl => SliderSetting)]
    #
    def reload_gql!(slider_settings)
      Current.reset_gql
      Current.scenario.user_values = @original_user_values.clone
      Current.scenario.update_statements = @original_update_statements.clone

      slider_settings.each do |slider_control, slider_setting|
        slider_control.update(slider_setting)
      end
    end

    ##
    # Finalizes this step. It updates the slider values with the 
    # slider_settings, so that we can use the present values for
    # the next step.
    #
    def freeze_step!(slider_settings)
      slider_settings.each do |slider_control, slider_setting|
        slider_control.current_step_value = slider_setting.value
      end
    end

    ##
    # @return [true,false] true if all gquery targets met.
    #
    def all_targets_met?
      gquery_controls.all?(&:target_met?)
    end

    ##
    # The total weighted fitness of all gquery controls.
    #
    # The closer it gets to 1.0 the better.
    # Theoretically it should not go below 1.0
    # 
    # 1.0 if all_targets_met
    # 0.0 if nan? or infinite?
    #
    # @return [Float] 
    #
    def fitness
      return 1 if all_targets_met?
      controls = gquery_controls_with_unmet_target

      total = weighted_fitness(controls)
      total_weight = total_weight(controls)

      total_fitness( total, total_weight )
    end

  private
    def total_fitness(total_weighted_fitness, total_weight)
      return 0.0 if total_weight == 0.0

      t = total_weighted_fitness / total_weight
      t = 0.0 if t.nan? or t.infinite?
      t
    end

    def gquery_controls_with_unmet_target
      gquery_controls.reject(&:target_met?)
    end

    def weighted_fitness(controls)
      controls.map(&:weighted_fitness).sum
    end

    def total_weight(controls)
      controls.map(&:weight).sum
    end

  end
end