require 'spec_helper'

describe 'APIv3 Scenarios', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
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
      data.should include('start_year' => scenario.start_year)
      data.should include('end_year'   => scenario.end_year)
      data.should include('template'   => nil)
      data.should include('source'     => nil)

      data.should have_key('created_at')

      data['url'].should match(%r{/scenarios/#{ data['id'] }$})

      data.should_not have_key('use_fce')
      data.should_not have_key('description')
      data.should_not have_key('inputs')
    end

    it 'should optionally include detailed params' do
      expect do
        post 'api/v3/scenarios', detailed: true
      end.to change { Scenario.count }.by(1)

      response.status.should eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      data.should have_key('use_fce')
      data.should have_key('description')

      data.should_not have_key('inputs')
    end

    it 'should optionally include inputs' do
      expect do
        post 'api/v3/scenarios', include_inputs: true
      end.to change { Scenario.count }.by(1)

      response.status.should eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      data.should have_key('inputs')
    end

    it 'should save custom end years' do
      running_this = -> {
        post 'api/v3/scenarios', scenario: { end_year: 2031 }
      }

      expect(&running_this).to change { Scenario.count }.by(1)
      response.status.should eql(200)

      data = JSON.parse(response.body)

      data['end_year'].should eql(2031)
    end

    it 'should save custom end years' do
      pending 'awaiting reintroduction of non-NL regions' do
        running_this = -> {
          post 'api/v3/scenarios', scenario: { area_code: 'uk' }
        }

        expect(&running_this).to change { Scenario.count }.by(1)
        response.status.should eql(200)

        data = JSON.parse(response.body)

        data['area_code'].should eql('de')
      end
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

      scenario.user_values.should eql(
        Preset.all.first.user_values.stringify_keys)
    end
  end

  context 'when scaling the area' do
    context 'with all valid attributes' do
      before do
        post 'api/v3/scenarios', scenario: {
          scale: { area_attribute: 'number_of_residences', value: 500_000 } }
      end

      it 'should be successful' do
        response.status.should eql(200)
      end

      it 'should save the custom scaling' do
        scenario = Scenario.find(JSON.parse(response.body)['id'])

        expect(scenario.scaler).to_not be_nil
        expect(scenario.scaler.area_attribute).to eq('number_of_residences')
        expect(scenario.scaler.value).to eq(500_000)
      end
    end # with all valid attributes

    context 'with an invalid attribute' do
      before do
        post 'api/v3/scenarios', scenario: {
          scale: { area_attribute: :illegal, value: 500_000 } }
      end

      it 'should not save the scenario' do
        running_this = -> {
          post 'api/v3/scenarios', scenario: {
            scale: { area_attribute: :illegal, value: 500_000 } }
        }

        expect(&running_this).to_not change { Scenario.count }
        response.status.should eql(422)
      end
    end

    context 'with a preset' do
      before do
        post 'api/v3/scenarios', scenario: {
          scenario_id: preset.id,
          scale: { area_attribute: 'number_of_residences', value: 500_000 }
        }
      end

      let(:preset) { Preset.all.detect {|p| p.key == :test } }
      let(:json)   { JSON.parse(response.body) }
      let(:multi)  { 500_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

      it 'should be successful' do
        response.status.should eql(200)
      end

      it 'should scale the user values' do
        scenario = Scenario.find(json['id'])

        expect(scenario.user_values['foo_demand']).
          to eq(preset.user_values[:foo_demand] * multi)

        expect(scenario.user_values['input_2']).
          to eq(preset.user_values[:input_2] * multi)

        # Input 3 is a non-scaled input
        expect(scenario.user_values['input_3']).
          to eq(preset.user_values[:input_3])
      end
    end # with a preset

    context 'with an already-scaled scenario' do
      let(:preset) { Preset.all.detect {|p| p.key == :test } }

      context '(re-scaling)' do
        before do
          post 'api/v3/scenarios', scenario: {
            scenario_id: preset.id,
            scale: { area_attribute: 'number_of_residences', value: 500_000 }
          }

          post 'api/v3/scenarios', scenario: {
            scenario_id: Scenario.last.id,
            scale: { area_attribute: 'number_of_residences', value: 250_000 }
          }
        end

        let(:json)  { JSON.parse(response.body) }
        let(:multi) { 250_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

        it 'should be successful' do
          response.status.should eql(200)
        end

        it 'should scale the user values' do
          scenario = Scenario.find(json['id'])

          expect(scenario.user_values['foo_demand']).
            to eq(preset.user_values[:foo_demand] * multi)

          expect(scenario.user_values['input_2']).
            to eq(preset.user_values[:input_2] * multi)

          # Input 3 is a non-scaled input
          expect(scenario.user_values['input_3']).
            to eq(preset.user_values[:input_3])
        end
      end

      context '(un-scaling)' do
        before do
          post 'api/v3/scenarios', scenario: {
            scenario_id: preset.id,
            scale: { area_attribute: 'number_of_residences', value: 500_000 }
          }

          post 'api/v3/scenarios', scenario: {
            scenario_id: Scenario.last.id, descale: true
          }
        end

        let(:json) { JSON.parse(response.body) }

        it 'should be successful' do
          response.status.should eql(200)
        end

        it 'should not change the user values' do
          scenario = Scenario.find(json['id'])
          attrs    = %w( foo_demand input_2 input_3 )

          expect(scenario.user_values['foo_demand']).
            to eq(preset.user_values[:foo_demand])

          expect(scenario.user_values['input_2']).
            to eq(preset.user_values[:input_2])

          # Input 3 is a non-scaled input
          expect(scenario.user_values['input_3']).
            to eq(preset.user_values[:input_3])
        end
      end # unscaling

      context '(retaining existing scaling)' do
        before do
          post 'api/v3/scenarios', scenario: {
            scenario_id: preset.id,
            scale: { area_attribute: 'number_of_residences', value: 500_000 }
          }

          @scaled = post 'api/v3/scenarios', scenario: { scenario_id: Scenario.last.id }
        end

        let(:json) { JSON.parse(response.body) }
        let(:multi) { 500_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

        it 'should be successful' do
          response.status.should eql(200)
        end

        it 'should retain the scaled user values' do
          scenario = Scenario.find(json['id'])

          expect(scenario.user_values['foo_demand']).
            to eq(preset.user_values[:foo_demand] * multi)

          expect(scenario.user_values['input_2']).
            to eq(preset.user_values[:input_2] * multi)

          # Input 3 is a non-scaled input
          expect(scenario.user_values['input_3']).
            to eq(preset.user_values[:input_3])
        end
      end # retaining existing scaling
    end # with an already-scaled scenario
  end # when scaling the area

end
