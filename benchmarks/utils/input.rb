# frozen_string_literal: true

require 'yaml'

class Benchmarks

  class Utils
    ###
    # This utility class provides a collection of methods that help
    # to dynamically structure and obtain inputs that are suitable to be used
    # in benchmarking of scenarios.
    #
    class Input
      INTERFACE_FILE_DIR = '../etmodel/config/interface'.freeze
      SLIDES_DIR = 'slides'.freeze
      INPUT_GROUP_DIR = 'input_elements'.freeze

      TABS_FILE = 'tabs.yml'.freeze
      DASHBOARD_ITEMS_FILE = 'dashboard_items.yml'.freeze
      SIDEBAR_ITEMS_FILE = 'sidebar_items.yml'.freeze

      IGNORED_TAB_KEYS = %w[overview].freeze
      IGNORED_SLIDE_KEYS = %w[introduction other].freeze
      IGNORED_GROUP_KEYS = %w[].freeze
      IGNORED_INPUT_KEYS = %w[
        agriculture_useful_demand_electricity
        agriculture_useful_demand_useable_heat
        demand_agriculture_demand_growth
        demand_agriculture_heat
      ].freeze

      class << self
        def tab_keys
          YAML \
            .load_file("#{INTERFACE_FILE_DIR}/#{TABS_FILE}")
            .pluck('key')
            .reject { |key| IGNORED_TAB_KEYS.include?(key) }
        end

        def slide_keys_for_tab(tab_key)
          return [] unless File.exist?("#{INTERFACE_FILE_DIR}/#{SIDEBAR_ITEMS_FILE}")

          YAML \
            .load_file("#{INTERFACE_FILE_DIR}/#{SIDEBAR_ITEMS_FILE}")
            .select { |si| si['tab_key'] == tab_key }
            .pluck('key')
            .reject { |key| IGNORED_SLIDE_KEYS.include?(key) }
        end

        def input_group_keys_for_slide(slide_key)
          return [] unless File.exist?("#{INTERFACE_FILE_DIR}/#{SLIDES_DIR}/#{slide_key}.yml")

          YAML \
            .load_file("#{INTERFACE_FILE_DIR}/#{SLIDES_DIR}/#{slide_key}.yml")
            .pluck('key')
        end

        def input_keys_for_input_group(input_group_key)
          return [] unless File.exist?("#{INTERFACE_FILE_DIR}/#{INPUT_GROUP_DIR}/#{input_group_key}.yml")

          YAML \
            .load_file("#{INTERFACE_FILE_DIR}/#{INPUT_GROUP_DIR}/#{input_group_key}.yml")
            .pluck('key')
            .reject { |key| IGNORED_INPUT_KEYS.include?(key) }
        end

        def input_keys_for_slide(slide_key)
          get_input_group_keys_for_slide(slide_key).map do |group_key|
            get_input_keys_for_input_group(group_key)
          end.flatten.compact
        end

        def general_input_keys
          dashboard_item_keys = YAML \
            .load_file("#{INTERFACE_FILE_DIR}/#{DASHBOARD_ITEMS_FILE}")
            .select { |di| !di['disabled'] && di['position'].present? }
            .pluck('key')

          sidebar_item_keys = YAML \
            .load_file("#{INTERFACE_FILE_DIR}/#{SIDEBAR_ITEMS_FILE}")
            .pluck('percentage_bar_query')

          (dashboard_item_keys + sidebar_item_keys).compact
        end

        def all_slide_keys
          Dir \
            .new("#{INTERFACE_FILE_DIR}/#{SLIDES_DIR}")
            .children
            .map { |slide_file| slide_file.chomp('.yml') }
            .reject { |key| IGNORED_SLIDE_KEYS.include?(key) }
        end

        def all_input_keys
          Dir \
            .new("#{INTERFACE_FILE_DIR}/#{INTERFACE_FILE_DIR}")
            .children
            .reject { |group_file| IGNORED_GROUP_KEYS.include?(group_file.chomp('.yml')) }
            .map do |group_file|
              YAML \
                .load_file("#{INTERFACE_FILE_DIR}/#{INPUT_GROUP_DIR}/#{group_file}")
                .pluck('key')
            end
            .reject { |key| IGNORED_INPUT_KEYS.include?(key) }
        end

        def nested_input_keys
          input_keys = []

          get_tab_keys.each do |tab_key|
            input_keys[tab_key] = get_slide_keys_for_tab(tab_key)
            input_keys[tab_key].each do |slide_key|
              input_keys[tab_key][slide_key] = get_input_group_keys_for_slide(slide_key)
              input_keys[tab_key][slide_key].each do |group_key|
                input_keys[tab_key][slide_key][group_key] = get_input_keys_for_input_group(group_key)
              end
            end
          end

          input_keys
        end

        def inputs_per_slide(max_inputs_per_slide = nil)
          general_input_keys = self.get_general_input_keys

          inputs = {}

          self.get_tab_keys.each do |tab_key|
            self.get_slide_keys_for_tab(tab_key).each do |slide_key|
              group_keys = self.get_input_group_keys_for_slide(slide_key)

              group_keys.each do |group_key|
                input_keys = self.get_input_keys_for_input_group(group_key)
                input_keys = input_keys.sample(max_inputs_per_slide) if max_inputs_per_slide.present?

                input_keys.each { |ik| inputs[ik] = general_input_keys + group_keys }
              end
            end
          end

          inputs
        end
      end # /self
    end # /class Input
  end # /class Utils
end # /class Benchmarks
