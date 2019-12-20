require 'spec_helper'

describe 'APIv3 Scenarios', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  context 'with valid parameters' do
    it 'should save the scenario' do
      expect { post '/api/v3/scenarios' }.to change { Scenario.count }.by(1)

      expect(response.status).to eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      expect(data).to include('title'      => scenario.title)
      expect(data).to include('id'         => scenario.id)
      expect(data).to include('area_code'  => 'nl')
      expect(data).to include('start_year' => scenario.start_year)
      expect(data).to include('end_year'   => scenario.end_year)
      expect(data).to include('template'   => nil)
      expect(data).to include('source'     => nil)

      expect(data).to have_key('created_at')

      expect(data['url']).to match(%r{/scenarios/#{ data['id'] }$})

      expect(data).not_to have_key('use_fce')
      expect(data).not_to have_key('description')
      expect(data).not_to have_key('inputs')
    end

    it 'should save user values' do
      post '/api/v3/scenarios',
        params: { scenario: { user_values: { foo_demand: 10.0 } } }

      expect(response.status).to eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.find(data['id'])

      expect(scenario.user_values).to eq('foo_demand' => 10.0)
      expect(scenario.user_values).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    it 'should optionally include detailed params' do
      expect do
        post '/api/v3/scenarios', params: { detailed: true }
      end.to change { Scenario.count }.by(1)

      expect(response.status).to eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      expect(data).to have_key('use_fce')
      expect(data).to have_key('description')

      expect(data).not_to have_key('inputs')
    end

    it 'should optionally include inputs' do
      expect do
        post '/api/v3/scenarios', params: { include_inputs: true }
      end.to change { Scenario.count }.by(1)

      expect(response.status).to eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      expect(data).to have_key('inputs')
    end

    it 'should save custom end years' do
      running_this = -> {
        post '/api/v3/scenarios', params: { scenario: { end_year: 2031 } }
      }

      expect(&running_this).to change { Scenario.count }.by(1)
      expect(response.status).to eql(200)

      data = JSON.parse(response.body)

      expect(data['end_year']).to eql(2031)
    end

    it 'should save custom end years' do
      pending 'awaiting reintroduction of non-NL regions'
      running_this = -> {
        post '/api/v3/scenarios', params: { scenario: { area_code: 'uk' } }
      }

      expect(&running_this).to change { Scenario.count }.by(1)
      expect(response.status).to eql(200)

      data = JSON.parse(response.body)

      expect(data['area_code']).to eql('de')
    end
  end

  context 'with invalid parameters' do
    it 'should not save the scenario' do
      running_this = -> {
        post '/api/v3/scenarios', params: { scenario: { area_code: '' } }
      }

      expect(&running_this).to_not change { Scenario.count }
      expect(response.status).to eql(422)

      data = JSON.parse(response.body)

      expect(data).to have_key('errors')
      expect(data['errors']['area_code']).to include("can't be blank")
    end
  end

  context 'when inheriting a preset' do
    before do
      post '/api/v3/scenarios', params: { scenario: { scenario_id: Preset.all.first.id } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should save the user values' do
      scenario = Scenario.find(json['id'])

      expect(scenario.user_values).not_to be_blank

      expect(scenario.user_values).to eql(
        Preset.all.first.user_values.stringify_keys)
    end
  end

  context 'when inheriting a scaled preset' do
    before do
      post '/api/v3/scenarios', params: { scenario: { scenario_id: Preset.get(6000).id } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should copy the scaling data' do
      scenario = Scenario.find(JSON.parse(response.body)['id'])

      expect(scenario.scaler).to_not be_nil
      expect(scenario.scaler.area_attribute).to eq('number_of_residences')
      expect(scenario.scaler.value).to eq(100)
    end
  end

  context 'when scaling the area' do
    context 'with all valid attributes' do
      before do
        post '/api/v3/scenarios', params: {
          scenario: {
            scale: { area_attribute: 'number_of_residences', value: 500_000 } }
        }
      end

      it 'should be successful' do
        expect(response.status).to eql(200)
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
        post '/api/v3/scenarios', params: {
          scenario: {
            scale: { area_attribute: :illegal, value: 500_000 } }
        }
      end

      it 'should not save the scenario' do
        running_this = -> {
          post '/api/v3/scenarios', params: {
            scenario: {
              scale: { area_attribute: :illegal, value: 500_000 } }
          }
        }

        expect(&running_this).to_not change { Scenario.count }
        expect(response.status).to eql(422)
      end
    end

    context 'with a preset' do
      before do
        post '/api/v3/scenarios', params: {
          scenario: {
            scenario_id: preset.id,
            scale: { area_attribute: 'number_of_residences', value: 500_000 }
          }
        }
      end

      let(:preset) { Preset.all.detect {|p| p.key == :test } }
      let(:json)   { JSON.parse(response.body) }
      let(:multi)  { 500_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

      it 'should be successful' do
        expect(response.status).to eql(200)
      end

      it 'does not create a default flexibility order' do
        expect(FlexibilityOrder.where(scenario_id: json['id']).count).to be_zero
      end

      it 'does not create a default heat network order' do
        expect(HeatNetworkOrder.where(scenario_id: json['id']).count).to be_zero
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

      context 'when the preset has a flexibility order' do
        let(:preset) do
          Preset.all.detect { |p| p.key == :with_flexibility_order }
        end

        it 'creates a flexibility order' do
          expect(FlexibilityOrder.where(scenario_id: json['id']).count).to eq(1)
        end
      end

      context 'when the preset has a heat network order' do
        let(:preset) do
          Preset.all.detect { |p| p.key == :with_flexibility_order }
        end

        it 'creates a heat network order' do
          expect(HeatNetworkOrder.where(scenario_id: json['id']).count).to eq(1)
        end
      end
    end # with a preset

    context 'with an already-scaled scenario' do
      let(:preset) { Preset.all.detect {|p| p.key == :test } }

      context '(re-scaling)' do
        before do
          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: preset.id,
              scale: { area_attribute: 'number_of_residences', value: 500_000 }
            }
          }

          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: Scenario.last.id,
              scale: { area_attribute: 'number_of_residences', value: 250_000 }
            }
          }
        end

        let(:json)  { JSON.parse(response.body) }
        let(:multi) { 250_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

        it 'should be successful' do
          expect(response.status).to eql(200)
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
          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: preset.id,
              scale: { area_attribute: 'number_of_residences', value: 500_000 }
            }
          }

          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: Scenario.last.id, descale: true
            }
          }
        end

        let(:json) { JSON.parse(response.body) }

        it 'should be successful' do
          expect(response.status).to eql(200)
        end

        it 'should not change the user values' do
          scenario = Scenario.find(json['id'])

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
          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: preset.id,
              scale: { area_attribute: 'number_of_residences', value: 500_000 }
            }
          }

          @scaled = post '/api/v3/scenarios', params: { scenario: { scenario_id: Scenario.last.id } }
        end

        let(:json) { JSON.parse(response.body) }
        let(:multi) { 500_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

        it 'should be successful' do
          expect(response.status).to eql(200)
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

    context "with a derived dataset" do
      context "(providing a derived area code)" do
        before do
          post '/api/v3/scenarios', params: {
            scenario: {
              area_code: 'ameland',
              user_values: {
                foo_demand: 100.0
              }
            }
          }

          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: Scenario.last.id,
              area_code: 'ameland',
              scale: { area_attribute: 'number_of_residences', value: 100 }
            }
          }
        end

        let(:json) { JSON.parse(response.body) }
        let(:multi) { 100 / Atlas::Dataset.find(:ameland).number_of_residences.to_f }

        it 'should be successful' do
          expect(response.status).to eql(200)
        end

        it 'should retain the scaled user values' do
          unscaled = Scenario.first
          scaled   = Scenario.last

          expect(scaled.user_values['foo_demand']).
            to eq(unscaled.user_values[:foo_demand].to_f * multi)
        end
      end

      context "(descale with a derived area code)" do
        before do
          post '/api/v3/scenarios', params: {
            scenario: {
              area_code: 'ameland',
              scale: { area_attribute: 'number_of_residences', value: 500_000 }
            }
          }

          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: Scenario.last.id, descale: true
            }
          }
        end

        let(:json) { JSON.parse(response.body) }

        it 'should be successful' do
          expect(response.status).to eql(200)
        end

        it 'should create a second scenario from the base dataset' do
          expect(Scenario.count).to eq(2)
        end
      end
    end # with a derived dataset
  end # when scaling the area

end
