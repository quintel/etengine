desc 'Generates list node keys and demands from a static.yml file'

task :generate_key_demand_file => [:environment] do
  path              = ENV['path']
  output_file_name  = 'tmp/node_demand.csv'

  unless path && !path.blank?
    abort 'Please specify: path=<path_to_file/filename>'
  end

  node_data = YAML.load_file(path)[:nodes]
  demands   = node_data.map { |key, data| "#{ key },#{ data[:demand] }" }

  File.write(output_file_name, demands.join("\n"))

  puts "Successfully wrote keys and demands to ./#{output_file_name}"
end
