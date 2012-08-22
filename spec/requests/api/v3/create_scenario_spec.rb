require 'spec_helper'

describe 'APIv3 Scenarios' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  context 'with valid parameters' do
    it 'should save the scenario' do
      expect { post 'api/v3/scenarios' }.to change { Scenario.count }.by(1)

      response.status.should eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      data.should include('title'      => scenario.title)
      data.should include('id'         => scenario.id)
      data.should include('area_code'  => 'nl')
      data.should include('end_year'   => scenario.end_year)
      data.should include('template'   => nil)
      data.should include('source'     => nil)

      data.should have_key('created_at')

      data['url'].should match(%r{/scenarios/#{ data['id'] }$})

      data.should_not have_key('use_fce')
      data.should_not have_key('description')
    end

    it 'should save custom parameters' do
      running_this = -> {
        post 'api/v3/scenarios', scenario: { end_year: 2031, area_code: 'de' }
      }

      expect(&running_this).to change { Scenario.count }.by(1)
      response.status.should eql(200)

      data = JSON.parse(response.body)

      data['end_year'].should eql(2031)
      data['area_code'].should eql('de')
    end
  end

  context 'with invalid parameters' do
    it 'should not save the scenario' do
      running_this = -> {
        post 'api/v3/scenarios', scenario: { area_code: '' }
      }

      expect(&running_this).to_not change { Scenario.count }
      response.status.should eql(422)

      data = JSON.parse(response.body)

      data.should have_key('errors')
      data['errors']['area_code'].should include("can't be blank")
    end
  end

  context 'when inheriting a preset' do
    before do
      post 'api/v3/scenarios', scenario: { scenario_id: Preset.all.first.id }
    end

    let(:json) { JSON.parse(response.body) }

    it 'should be successful' do
      response.status.should eql(200)
    end

    it 'should save the user values' do
      scenario = Scenario.find(json['id'])

      scenario.user_values.should_not be_blank
      scenario.user_values.should eql(Preset.all.first.user_values)
    end
  end

end
