require 'spec_helper'

describe 'APIv3 Scenarios' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:json)     { JSON.parse(response.body) }

  context 'with no "detailed" param' do
    before do
      get("api/v3/scenarios/#{ scenario.id }")
    end

    it 'should be successful' do
      response.status.should eql(200)
    end

    it 'should include the basic scenario data' do
      json.should include('title'      => scenario.title)
      json.should include('id'         => scenario.id)
      json.should include('area_code'  => 'nl')
      json.should include('end_year'   => scenario.end_year)
      json.should include('template'   => nil)
      json.should include('source'     => nil)

      json.should have_key('created_at')

      json['url'].should match(%r{/scenarios/#{ scenario.id }$})
    end

    it 'should not include detailed attributes' do
      json.should_not have_key('use_fce')
      json.should_not have_key('description')
    end
  end

  context 'with the "detailed" param' do
    before do
      get("api/v3/scenarios/#{ scenario.id }", detailed: true)
    end

    it 'should be successful' do
      response.status.should eql(200)
    end

    it 'should include the basic scenario data' do
      json.should include('title'      => scenario.title)
      json.should include('id'         => scenario.id)
      json.should include('area_code'  => 'nl')
      json.should include('end_year'   => scenario.end_year)
      json.should include('template'   => nil)
      json.should include('source'     => nil)

      json.should have_key('created_at')

      json['url'].should match(%r{/scenarios/#{ scenario.id }$})
    end

    it 'should include detailed attributes' do
      json.should include('use_fce'     => scenario.use_fce)
      json.should include('description' => scenario.description)
    end
  end

end
