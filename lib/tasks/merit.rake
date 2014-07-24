namespace :merit do
  # Exports data about a Merit Order run into tmp/convergence. The final output
  # path will include the scenario area and date.
  #
  # Examples:
  #
  #   # Export a default NL scenario:
  #   rake merit:archive
  #
  #   # Export a default DE scenario:
  #   rake merit:archive AREA=de
  #
  #   # Export data for a specific scenario in the database:
  #   rake merit:archive SCENARIO=23548
  task archive: :environment do
    if ENV['SCENARIO']
      scenario = Scenario.find(ENV['SCENARIO'].to_i)
    else
      scenario = Scenario.default(area_code: ENV['AREA'] || 'nl')
    end

    # Disable the merit order processing during graph calculation; we're doing
    # to do it manually.
    scenario.user_values['settings_enable_merit_order'] = false

    graph = scenario.gql.future_graph

    # Why does the Injector check this when the graph has already done so? :/
    def graph.use_merit_order_demands?
      true
    end

    injector = Qernel::Plugins::MeritOrder::MeritOrderInjector.new(graph)
    injector.run

    # Save the data.
    area  = scenario.area_code.upcase
    stamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    stamp = "#{ scenario.id }_#{ stamp }" if scenario.id
    dir   = Rails.root.join('tmp/convergence').join("#{ area }_#{ stamp }")

    FileUtils.mkdir_p(dir.join('producers'))

    # Demand Data
    # -----------

    dispatchable_keys = %w(
      key marginal_costs output_capacity_per_unit number_of_units availability
      fixed_costs_per_unit fixed_om_costs_per_unit
    )

    additional_keys = %w( full_load_hours load_profile_key )

    injector.m.producers.each do |producer|
      data = dispatchable_keys.each_with_object({}) do |key, data|
        data[key.to_sym] = producer.public_send(key)
      end

      unless producer.is_a?(Merit::DispatchableProducer)
        additional_keys.each do |key|
          data[key.to_sym] = producer.public_send(key)
        end
      end

      data[:type] = producer.class.name.split('::').last

      File.write(dir.join("producers/#{ producer.key }.yml"), YAML.dump(data))
    end

    # Area Price Data
    # ---------------

    write_curve = ->(path, curve) do
      File.write(dir.join(path), curve.to_a.map { |line| "#{ line }\n" }.join)
    end

    user = injector.m.participant(:total_demand)

    write_curve.call('price.csv',  injector.m.price_curve)
    write_curve.call('demand.csv', user.load_curve)

    File.write(dir.join('total_demand.txt'), "#{ user.total_consumption }\n")
    File.write(dir.join('area.txt'), "#{ area.downcase }\n")

    puts "Data dumped to ./#{ dir.relative_path_from(Rails.root) }"
    puts
    puts 'Saved prices to price.csv'
    puts 'Saved demand curve to demand.csv'
    puts 'Saved total demand to total_demand.txt'
    puts 'Saved producer data to producers/*.yml'
    puts
    puts "open ./#{ dir.relative_path_from(Rails.root) }"
  end
end
