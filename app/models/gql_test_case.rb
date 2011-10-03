# == Schema Information
#
# Table name: gql_test_cases
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  instruction :text(2147483647
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  settings    :text(2147483647
#  inputs      :text(2147483647
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
end
