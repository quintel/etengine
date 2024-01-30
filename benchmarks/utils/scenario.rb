# frozen_string_literal: true

class Benchmarks

  class Utils

    class Scenario
      class << self
        def create_scenario
          attrs = ::Scenario.default_attributes

          scenario = ::Scenario.new
          scenario.descale = attrs[:descale]
          scenario.attributes = attrs
          scenario.owner = User.where(email: 'admin@quintel.com').first

          scenario.save(validate: false)

          scenario
        end

        def clone_scenario(scenario)
          dup_scenario = scenario.dup
          dup_scenario.save(validate: false)

          dup_scenario
        end

        def update_scenario(scenario, user_values = {}, gqueries = [])
          params = {
            autobalance: true,
            scenario: {
              id: scenario.id,
              user_values:
            },
            gqueries:
          }
          updater    = Api::V3::ScenarioUpdater.new(scenario, params)
          serializer = nil

          ::Scenario.transaction do
            updater.apply
            serializer = ::ScenarioUpdateSerializer.new(Api::V3::ScenariosController, updater, params)

            raise ActiveRecord::Rollback if serializer.errors.any?
          end
        end
      end # /self
    end # /class Scenario
  end # /class Utils
end # /class Benchmarks
