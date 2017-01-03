namespace :etsource do
  desc "Lists all presets which have input keys that no longer exist."
  task outdated_presets: :environment do
    any_outdated = false
    input_keys   = Input.all.map(&:key)

    Preset.all.each do |preset|
      old_inputs = preset.user_values.keys.reject do |key|
        input_keys.include?(key)
      end

      if old_inputs.any?
        puts "Preset #{ preset.title } (id:#{ preset.id }) references " \
             "outdated inputs:"
        puts old_inputs.sort.map { |key| "  * #{ key }" }.join("\n")
        puts

        any_outdated = true
      end
    end

    if any_outdated == false
      puts 'Congratulations! No presets have out-of-date inputs!'
    end
  end
end
