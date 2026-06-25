require_relative 'spec_helper'
require_relative '../lib/datasets'
require_relative '../lib/emissions_csv_reconciler'
require_relative 'validation/emissions'

describe 'Validating 1990 emissions inventory' do
  GraphDataValidation::Datasets.from_collection(:emissions_1990_validation).each do |dataset|
    context "with area_code #{dataset.scenario.area_code}" do
      it_behaves_like 'emissions_1990_reconciliation', dataset
    end
  end
end
