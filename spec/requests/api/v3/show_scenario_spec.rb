require 'spec_helper'

describe 'APIv3 Scenarios' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { FactoryBot.create(:scenario) }
  let(:json)     { JSON.parse(response.body) }

  context 'with no "detailed" param' do
    before do
      get("/api/v3/scenarios/#{ scenario.id }")
    end

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should include the basic scenario data' do
      expect(json).to include('title'      => scenario.title)
      expect(json).to include('id'         => scenario.id)
      expect(json).to include('area_code'  => 'nl')
      expect(json).to include('start_year' => scenario.start_year)
      expect(json).to include('end_year'   => scenario.end_year)
      expect(json).to include('template'   => nil)
      expect(json).to include('source'     => nil)

      expect(json).to have_key('created_at')

      expect(json['url']).to match(%r{/scenarios/#{ scenario.id }$})
    end
  end

  context 'with the "detailed" param' do
    before do
      get("/api/v3/scenarios/#{ scenario.id }", params: { detailed: true })
    end

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should include the basic scenario data' do
      expect(json).to include('title'      => scenario.title)
      expect(json).to include('id'         => scenario.id)
      expect(json).to include('area_code'  => 'nl')
      expect(json).to include('end_year'   => scenario.end_year)
      expect(json).to include('template'   => nil)
      expect(json).to include('source'     => nil)

      expect(json).to have_key('created_at')

      expect(json['url']).to match(%r{/scenarios/#{ scenario.id }$})
    end
  end

  context 'with the "include_inputs" param' do
    before do
      get("/api/v3/scenarios/#{ scenario.id }", params: { include_inputs: true })
    end

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should include the basic scenario data' do
      expect(json).to include('title'      => scenario.title)
      expect(json).to include('id'         => scenario.id)
      expect(json).to include('area_code'  => 'nl')
      expect(json).to include('end_year'   => scenario.end_year)
      expect(json).to include('template'   => nil)
      expect(json).to include('source'     => nil)

      expect(json).to have_key('created_at')

      expect(json['url']).to match(%r{/scenarios/#{ scenario.id }$})
    end

    it 'should include the inputs' do
      expect(json).to have_key('inputs')
    end
  end

end
