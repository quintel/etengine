require 'spec_helper'

describe 'APIv3 Node details' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario)      { FactoryBot.create(:scenario) }
  let(:json)          { JSON.parse(response.body) }
  let(:user)          { create(:user) }
  let(:token_header)  { access_token_header(user, :read) }

  context "an existing node" do
    before do
      get("/api/v3/scenarios/#{ scenario.id }/nodes/foo", headers: token_header)
    end

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should include the basic node info' do
      expect(json).to include('key' => 'foo')
      expect(json).to have_key('data')
    end
  end

  context "a bad node key" do
    before do
      get("/api/v3/scenarios/#{ scenario.id }/nodes/rick_astley", headers: token_header)
    end

    it "should return 404" do
      expect(response).to be_not_found
    end
  end
end
