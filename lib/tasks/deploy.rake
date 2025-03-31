# frozen_string_literal: true

# Tasks used during deployment of the application.
namespace :deploy do
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

    Provide the desired ETSource commit in a ETSOURCE_REF variable:

    rake etsource:load ETSOURCE_REF=a9b8c7d6e5f4
  DESC
  task load_etsource: :environment do
    etsource    = Pathname.new(ETSOURCE_DIR).expand_path
    destination = Pathname.new(ETSOURCE_EXPORT_DIR).expand_path
    revision    = (ENV['ETSOURCE_REF'] || (Rails.env.production? ? 'production' : 'master')).strip
    real_rev    = nil

    raise "You didn't provide an ETSOURCE_REF to load!" if revision.empty?

    if etsource == destination
      raise <<-MESSAGE.strip_heredoc
        Cannot load a new ETSource version manually when the etsource_export
        and etsource_working_copy paths are the same.
      MESSAGE
    end

    # Mark etsource as safe
    Open3.capture2e("git config --global --add safe.directory #{etsourc}")

    puts 'Refreshing ETSource from GitHub'
    Etsource::Base.instance.refresh

    verbose(false) do
      cd(etsource) do
        real_rev = `git rev-parse 'origin/#{revision}'`.strip
        real_rev = real_rev.split('/').last if real_rev.include?('/')
      end
    end

    puts 'Loading ETSource files...'
    Etsource::Base.instance.export(real_rev)

    NastyCache.instance.expire!(keep_atlas_dataset: ARGV.include?('deploy:calculate_datasets'))

    puts "ETSource #{real_rev[0..6]} ready at #{destination}"
  end

  desc <<-DESC
    Calculates the datasets for each region using Atlas and Refinery.

    Expects RAILS_ENV=production (or any environment where the
    etsource_lazy_load_dataset option is set to false).
  DESC
  task calculate_datasets: :environment do
    if Settings.etsource_lazy_load_dataset
      abort(<<-MESSAGE.strip_heredoc)
        Cannot calculate datasets when etsource_lazy_load_dataset is "true".

        The datasets can only be calculated in a Rails environment where this
        option is set to false. This is typically the case in production and
        staging.

        Try: RAILS_ENV=production bundle exec rake calculate_datasets
      MESSAGE
    end

    path = Pathname.new(
      ENV.fetch('CACHED_DATASETS_PATH') do
        Etsource::Dataset::Import::CACHED_DATASETS_PATH
      end
    )

    path.mkpath

    loader = Etsource::AtlasLoader::PreCalculated.new(path)

    loader.reload!(progress: true) do |region_code, calculator|
      calculator.call
    rescue StandardError => e
      puts
      puts "Error calculating #{region_code}"
      raise e
    end
  end
end
