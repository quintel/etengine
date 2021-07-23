namespace :merit do
  task create_stub: :environment do
    require 'zlib'

    facade = Scenario.find(ENV['SCENARIO'].to_i).gql.future.graph.plugin(:merit)

    data = facade.adapters.map do |key, adapter|
      next unless facade.adapters[key].installed?

      part = adapter.participant
      opts = part.instance_variable_get(:@opts)

      opts = opts.transform_values do |value|
        case value
        when Merit::LoadProfile,
             Qernel::FeverFacade::ElectricityDemandCurve,
             Qernel::Causality::LazyCurve
          value.to_a
        else
          value
        end
      end

      { type: part.class, opts: opts.except(:decay) }
    end.compact

    File.open(Rails.root.join('tmp/merit.yml.gz'), 'wb') do |file|
      file.puts(Zlib::Deflate.deflate(YAML.dump(data)))
    end
  end
end
