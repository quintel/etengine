require_relative 'spec_helper'
require_relative '../lib/datasets'
require_relative 'validation/emissions'

describe 'Validating country dataset' do
  GraphDataValidation::Datasets.from_collection(:countries).each do |country|
    context "with area_code #{country.scenario.area_code}" do
      include_examples 'emissions', country
    end
  end
end

