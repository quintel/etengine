require 'spec_helper'

describe 'APIv3 Converter details' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { FactoryBot.create(:scenario) }
  let(:json)     { JSON.parse(response.body) }

  context "an existing converter" do
    before do
      get("/api/v3/scenarios/#{ scenario.id }/converters/foo")
    end

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should include the basic converter info' do
      expect(json).to include('key' => 'foo')
      expect(json).to have_key('data')
    end
  end

  context "a bad converter key" do
    before do
      get("/api/v3/scenarios/#{ scenario.id }/converters/rick_astley")
    end

    it "should return 404" do
      expect(response).to be_not_found
    end
  end
end
