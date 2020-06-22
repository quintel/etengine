require 'spec_helper'

describe 'APIv3 Topology Data' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { FactoryBot.create(:scenario) }

  before do
    get("/api/v3/scenarios/#{ scenario.id }/nodes/topology")
  end

  it 'should be successful' do
    expect(response.status).to eql(200)
  end
end
