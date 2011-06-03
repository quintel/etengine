# == Schema Information
#
# Table name: gql_test_cases
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  instruction :text
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

# Simple Syntax for accessing the api
# Settings: end_year=2050 country=nl
# Sliders: 335=1.0
# Results: co2_emission_total=80.0
#
#
#
#
class GqlTestCase < ActiveRecord::Base
  strip_attributes!

  def api_params
    [
      param_string(setting_params, 'settings'),
      param_string(update_params, 'input'),
      result_params
    ].join('&')
  end

  def param_string(args, prefix)
    args.map do |key, value|
      "#{prefix}[#{key}]=#{value}"
    end.join("&")
  end

  def update_params
    lines = instruction_lines.select{|l| l.include?("Sliders: ")}
    params = lines.map do |line|
      line.scan(/[\w\d_]+=[0-9_\.]+/)
    end.flatten
    params_to_hash(params)
  end

  def setting_params
    lines = instruction_lines.select{|l| l.include?("Settings: ")}
    params = lines.map do |line|
      line.scan(/[\w_]+=[a-z0-9_]+/)
    end.flatten
    
    params_to_hash(params)
  end

  def result_queries
    lines = instruction_lines.select{|l| l.include?("Results: ")}
    params = lines.map do |line|
      line.scan(/[\w\d_]+=[KMB0-9_\.\-\+\%]+/)
    end.flatten
    params_to_hash(params)
  end

  def result_params
    queries = result_queries.keys
    queries.map{|q| "result[]=#{q}"}.join('&')
  end

  def params_to_hash(params)
    params.inject({}) do |hsh, setting| 
      key, value = setting.split('=')
      hsh.merge key => value
    end
  end

  def instruction_lines
    @instruction_lines ||= instruction.split("\n").map(&:strip)
  end

  ##
  #
  # =100_000_000-150_000_000
  # =100_000_000+/-5%
  # =100_000_000+/-50_000_000
  #
  # Default:
  # =100_000_000 => =100_000_000+/-2%
  #
  def self.min_max_of(line)
    line = line.gsub(/[\w\d_]+=/, '')

    line = line.gsub('K', '000')
    line = line.gsub('M', '000_000')
    line = line.gsub('B', '000_000_000')

    base_number, range_number = line.scan(/[0-9KMB_\.\%]+/).map(&:to_f)

    strategy = line.include?('+/-') ? :plus_minus : :range

    if range_number.nil?
      # If no modifier apply defaults
      range_number = '2%'.to_f
      strategy = :plus_minus
    end
    
    if strategy == :plus_minus
      delta = base_number * range_number / 100      
      [base_number - delta, base_number + delta]
    else
      [base_number, range_number]
    end
  end
end
