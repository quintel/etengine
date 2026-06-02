# Load module code
Dir[File.expand_path("../../lib/*.rb", __FILE__)].each {|f| require f}

# Load examples
Dir["./spec/validation/**/*.rb"].sort.each { |f| require f }
