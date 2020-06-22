namespace :merit do
  desc <<-DESC
    Dumps data about Merit Order runs

    Exports data about a Merit Order run into tmp/merit-archive. The final
    output path will include the scenario area and date.

    Examples:

      # Export a default NL scenario:
      rake merit:archive

      # Export a default DE scenario:
      rake merit:archive AREA=de

      # Export data for a specific scenario in the database OR preset ID:
      rake merit:archive SCENARIO=23548

      # Export data for a preset (by ID):
      rake merit:archive PRESET=2996

      # Export data for a preset (by key):
      rake merit:archive PRESET=80_procent_co2_reductie
  DESC
  task archive: :environment do
    env = ENV.to_h.slice('PRESET', 'SCENARIO', 'AREA')

    if env['PRESET']
      if env['PRESET'].match(/^\d+$/)
        env['SCENARIO'] = env['PRESET']
      else
        env['SCENARIO'] = Atlas::Preset.find(env['PRESET']).id
      end
    end

    if env['SCENARIO']
      scenario_id = env['SCENARIO'].to_i

      if preset = Preset.get(scenario_id)
        puts "Creating archive using preset ##{ preset.id } (#{ preset.key })"
        scenario = Scenario.default(scenario_id: scenario_id)
      else
        puts "Creating archive using scenario ##{ scenario_id }"
        scenario = Scenario.find(scenario_id)
      end
    else
      puts "Creating archive with a new " \
           "#{ (env['AREA'] || 'NL').upcase } scenario"

      scenario = Scenario.default(area_code: (env['AREA'] || 'nl').downcase)
    end

    graph = scenario.gql.future_graph

    order = Qernel::MeritFacade::Manager.new(graph).order.calculate

    # Save the data.
    area  = scenario.area_code.upcase
    stamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')

    if scenario.id
      stamp = "#{ scenario.id }_#{ stamp }"
    elsif Preset.get(scenario_id)
      stamp = "#{ Preset.get(scenario_id).key }_#{ stamp }"
    end

    dir = Rails.root.join('tmp/merit-archive').join("#{ area }_#{ stamp }")

    FileUtils.mkdir_p(dir.join('producers'))

    # Demand Data
    # -----------

    dispatchable_keys = %w(
      key marginal_costs output_capacity_per_unit number_of_units availability
      fixed_costs_per_unit fixed_om_costs_per_unit
    )

    additional_keys = %w( full_load_hours )

    order.participants.producers.each do |producer|
      data = dispatchable_keys.each_with_object({}) do |key, data|
        data[key.to_sym] = producer.public_send(key)
      end

      unless producer.is_a?(Merit::DispatchableProducer)
        additional_keys.each do |key|
          data[key.to_sym] = producer.public_send(key)
        end

        data[:load_profile_key] = graph.node(producer.key).
          node_api.load_profile_key
      end

      data[:type] = producer.class.name.split('::').last

      File.write(dir.join("producers/#{ producer.key }.yml"), YAML.dump(data))
    end

    # Area Price Data
    # ---------------

    write_curve = ->(path, curve) do
      File.write(dir.join(path), curve.to_a.map { |line| "#{ line }\n" }.join)
    end

    user = order.participants[:total_demand]

    write_curve.call('price.csv',  order.price_curve)
    write_curve.call('demand.csv', user.load_curve)

    File.write(dir.join('archive-info.yml'), YAML.dump(
      area:          area.downcase,
      calculated_at: Time.now.utc,
      total_demand:  user.load_curve.reduce(:+) * 3600
    ))

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
