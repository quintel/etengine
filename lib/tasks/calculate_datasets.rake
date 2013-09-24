desc <<-DESC
  Calculates the datasets for each region using Atlas and Refinery.

  Expects RAILS_ENV=production (or any environment where the
  etsource_lazy_load_dataset option is set to false).
DESC
task calculate_datasets: [:environment] do
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
end
