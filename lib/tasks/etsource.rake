namespace :etsource do
  desc <<-DESC
    Forcefully loads a specific ETSource commit

    This does not calculate the dataset (production environment must still
    run "rake calculate_datasets" afterwards) nor will it run in any environment
    where your "etsource_export" and "etsource_working_copy" paths (found in
    config/config.yml) are the same; i.e., in development.

    This is used as an aid during deployment so that new ETEngine versions,
    which may be incompatible with the currently-imported ETSource, can load the
    desired ETSource version before starting the app. It is not intended for use
    on local development machines.

    Provide the desired ETSource commit in a REV variable:

    rake etsource:load REF=a9b8c7d6e5f4
  DESC
  task load: :environment do
    etsource    = Pathname.new(ETSOURCE_DIR).expand_path
    destination = Pathname.new(ETSOURCE_EXPORT_DIR).expand_path
    revision    = (ENV['REV'] || '').strip
    real_rev    = nil

    fail "You didn't provide a REV to load!" if revision.empty?

    if etsource == destination
      fail <<-MESSAGE.strip_heredoc
        Cannot load a new ETSource version manually when the etsource_export
        and etsource_working_copy paths are the same.
      MESSAGE
    end

    cd(etsource) do
      # Ensure the revision is real...
      sh("git rev-parse '#{ revision }'")
      real_rev = `git rev-parse '#{ revision }'`.strip
    end

    puts 'Refreshing ETSource from GitHub'
    Etsource::Base.instance.refresh

    puts 'Loading ETSource files...'
    Etsource::Base.instance.export(real_rev)

    puts "ETSource #{ real_rev[0..6] } ready at #{ destination }"
  end

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
