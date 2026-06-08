# Load module code
Dir[File.expand_path("../../lib/*.rb", __FILE__)].each {|f| require f}

# Load examples
Dir["./spec/validation/**/*.rb"].sort.each { |f| require f }

RSpec::Matchers.define :match_output do |output|
  match do |input|
    margin = 1.0E-12 * input
    input - output >= -margin
  end

  failure_message do |input|
    "expected input (#{format_float(input)}) to be bigger than output (#{format_float(output)}) \
 difference of #{(format_float(((input - output) / input).round(6).abs * 100))}%"
  end
end

def format_float(number)
  before_dot, after_dot = number.to_s.split('.')
  "#{before_dot.reverse.scan(/.{1,3}/).join(',').reverse}.#{after_dot}"
end
