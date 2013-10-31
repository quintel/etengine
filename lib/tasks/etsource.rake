namespace :etsource do
  desc "Validate before pushing an etsource commit."
  task :validate do
    Rake::Task["etsource:validate:hashes"].invoke
    Rake::Task["etsource:validate:duplicate_keys"].invoke
    Rake::Task["etsource:validate:duplicate_input_ids"].invoke
  end

  namespace :validate do
    desc "Check there is no collision when hashing the keys of graph elements"
    task :hashes => :environment do
      hashes = {}
      Etsource::Base.loader(ETSOURCE_DIR) unless ENV['ETSOURCE_DIR']
      Etsource::Topology.new.each_file do |lines|
        lines.reject(&:empty?).each do |line|
          # extract converter keys for converter lines (;-separated lines)
          line = line.split(";").first.strip
          if line.present?
            if existing_key = hashes[Hashpipe.hash(line)]
              raise "FATAL: The keys #{line.inspect} and #{existing_key.inspect} produce the same hash: #{Hashpipe.hash(line)}"
            end
            hashes[Hashpipe.hash(line)] = line
          end
        end
      end

      puts "** validate:hashes. OK. No conflicts found for #{hashes.keys.length} hashed keys."
    end

    desc "Check for gquery duplicates"
    task :duplicate_keys => :environment do
      puts "** validate:duplicate_keys"
      Etsource::Base.loader(ETSOURCE_DIR) unless ENV['ETSOURCE_DIR']
      gqueries = Etsource::Gqueries.new.import
      
      keys = Hash.new(0)
      gqueries.map(&:key).each do |key| 
        keys[key] += 1 
        puts "FATAL: Gquery key #{key} is duplicate" if keys[key] > 1
      end
      gqueries.map(&:deprecated_key).compact.each do |key| 
        keys[key] += 1 
        if keys[key] > 1
          puts "WARNING: Deprecated gquery key #{key.inspect} already exists as non-deprecated" 
        end
      end
    end

    desc "Check for gquery duplicates"
    task :duplicate_input_ids => :environment do
      Etsource::Base.loader(ETSOURCE_DIR) unless ENV['ETSOURCE_DIR']
      inputs = Etsource::Inputs.new.import
      
      inputs.group_by(&:lookup_id).each do |id, inputs|
        if inputs.length > 1
          puts "FATAL: #{inputs.map(&:key)} have the same id: #{id}"
        end
      end
      puts "** validate:duplicate_input_ids. OK"
    end
  end

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
