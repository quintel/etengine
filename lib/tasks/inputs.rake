namespace :inputs do
  desc "Computes input min, max, start values; saves to YAML"
  task dump: :environment do
    Atlas::Dataset.all.each do |dataset|
      next unless dataset.enabled[:etengine]

      puts "Creating data for #{ dataset.key.to_s.upcase }"

      scenario = Scenario.default(area_code: dataset.key.to_s)

      data = Input.all.map do |input|
        [input.key.to_sym, {
          min:   input.min_value_for(scenario),
          max:   input.max_value_for(scenario),
          start: input.start_value_for(scenario)
        }]
      end

      filename = Rails.root.join("tmp/input_values/#{ dataset.key }.yml")
      FileUtils.mkdir_p(filename.dirname)

      File.write(filename, YAML.dump(Hash[data]))
    end
  end # dump
end # inputs
