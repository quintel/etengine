# Tasks used during deployment of the application.
namespace :deploy do
  desc 'Creates the production config.yml file'
  task :app_config do
    require 'pathname'

    root       = Pathname.new(__FILE__).join('../../..').realpath
    defaults   = YAML.load_file(root.join('config/config.sample.yml'))
    local_path = root.join('../..').join('shared/config/config.local.yml')

    unless local_path.file?
      fail 'This does not appear to be a production/beta server'
    end

    # Server-specific configuration is stored in config.local.yml in the
    # deployment "shared/config" directory.
    local  = YAML.load_file(local_path)['production']
    config = { 'production' => defaults['production'].merge(local) }

    File.write(root.join('config/config.yml'), YAML.dump(config))
  end # app_config

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
  task load_etsource: :environment do
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

    puts 'Refreshing ETSource from GitHub'
    Etsource::Base.instance.refresh

    verbose(false) do
      cd(etsource) do
        # Ensure the revision is real...
        sh("git rev-parse '#{ revision }'")
        real_rev = `git rev-parse '#{ revision }'`.strip
      end
    end

    puts 'Loading ETSource files...'
    Etsource::Base.instance.export(real_rev)

    NastyCache.instance.expire!

    puts "ETSource #{ real_rev[0..6] } ready at #{ destination }"
  end # load_etsource

  desc <<-DESC
    Calculates the datasets for each region using Atlas and Refinery.

    Expects RAILS_ENV=production (or any environment where the
    etsource_lazy_load_dataset option is set to false).
  DESC
  task calculate_datasets: :environment do
    if APP_CONFIG[:etsource_lazy_load_dataset]
      abort <<-MESSAGE.strip_heredoc
        Cannot calculate datasets when etsource_lazy_load_dataset is "true".

        The datasets can only be calculated in a Rails environment where this
        option is set to false. This is typically the case in production and
        staging.

        Try: RAILS_ENV=production bundle exec rake calculate_datasets
      MESSAGE
    end

    Etsource::Dataset::Import.loader.reload! do |region_code|
      puts "Calculated #{ region_code.inspect }"
    end
  end # calculate_datasets
end # deploy
