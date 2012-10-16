require 'spec_helper'

describe 'APIv3 Topology Data' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { FactoryGirl.create(:scenario) }

  before do
    get("api/v3/scenarios/#{ scenario.id }/converters/topology")
  end

  it 'should be successful' do
    response.status.should eql(200)
  end
end
