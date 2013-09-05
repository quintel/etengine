desc <<-DESC
  Calculates the datasets for each region using Atlas and Refinery.

  Expects RAILS_ENV=production (or any environment where the
  etsource_lazy_load_dataset option is set to false).
DESC
task calculate_datasets: [:environment] do
  Etsource::Dataset::Import.loader.reload! do |region_code|
    puts "Calculated #{ region_code.inspect }"
  end
end
