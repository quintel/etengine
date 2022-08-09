require 'spec_helper'

describe 'APIv3 Scenarios', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  context 'without a title' do
    before do
      post '/api/v3/scenarios'
    end

    it 'it has no title' do
      expect(JSON.parse(response.body)).to include('title' => nil)
    end

    it 'saves no title with the metadata' do
      expect(JSON.parse(response.body)).to include('metadata' => {})
    end
  end

  context 'with a title (DEPRECATED)' do
    before do
      post '/api/v3/scenarios', params: { scenario: { title: 'Hello world!' } }
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'includes the title with the main scenario data' do
      expect(JSON.parse(response.body)).to include('title' => 'Hello world!')
    end

    it 'saves the title with metadata' do
      expect(JSON.parse(response.body)).to include('metadata' => { 'title' => 'Hello world!' })
    end
  end

  context 'with a description (DEPRECATED)' do
    before do
      post '/api/v3/scenarios', params: { scenario: { description: 'Hello world!' } }
    end

    it 'is successful' do
      expect(response).to be_ok
    end

    it 'includes the description with the main scenario data' do
      expect(JSON.parse(response.body)).to include('description' => 'Hello world!')
    end

    it 'saves the description with the metadata' do
      expect(JSON.parse(response.body))
        .to include('metadata' => { 'description' => 'Hello world!' })
    end
  end

  context 'with valid parameters' do
    it 'should save the scenario' do
      expect { post '/api/v3/scenarios' }.to change { Scenario.count }.by(1)

      expect(response.status).to eql(200)

      data     = JSON.parse(response.body)
      scenario = Scenario.last

      expect(data).to include('id'         => scenario.id)
      expect(data).to include('area_code'  => 'nl')
      expect(data).to include('start_year' => scenario.start_year)
      expect(data).to include('end_year'   => scenario.end_year)
      expect(data).to include('template'   => nil)
      expect(data).to include('source'     => nil)

      expect(data).to have_key('created_at')

      expect(data['url']).to match(%r{/scenarios/#{ data['id'] }$})

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

      expect(data).to have_key('user_values')
      expect(data).to have_key('metadata')
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

  context 'when inheriting from another scenario' do
    let(:parent) do
      FactoryBot.create(:scenario_with_user_values)
    end

    before do
      post '/api/v3/scenarios', params: { scenario: { scenario_id: parent.id } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'should be successful' do
      expect(response.status).to eql(200)
    end

    it 'should save the user values' do
      scenario = Scenario.find(json['id'])

      expect(scenario.user_values).not_to be_blank
      expect(scenario.user_values).to eql(parent.user_values.stringify_keys)
    end
  end

  context 'when inheriting from a non-existant scenario' do
    before do
      post '/api/v3/scenarios', params: { scenario: { scenario_id: 99_999 } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'is not successful' do
      expect(response.status).to eq(422)
    end

    it 'has an error' do
      expect(JSON.parse(response.body)['errors']).to include('scenario_id' => ['does not exist'])
    end
  end

  context 'when setting read_only to true' do
    before do
      post '/api/v3/scenarios', params: { scenario: { read_only: true } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'sets the scenario to be read-only' do
      expect(json['read_only']).to be(true)
    end

    it 'sets the scenario to be kept compatible' do
      expect(json['keep_compatible']).to be(true)
    end

    it 'includes protected=true in the response' do
      expect(json['protected']).to be(true)
    end
  end

  context 'when setting keep_compatible to true' do
    before do
      post '/api/v3/scenarios', params: { scenario: { keep_compatible: true } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'sets the scenario to be kept compatible' do
      expect(json['keep_compatible']).to be(true)
    end

    it 'includes protected=false in the response' do
      expect(json['protected']).to be(false)
    end
  end

  # Legacy attribute.
  context 'when setting protected to true' do
    before do
      post '/api/v3/scenarios', params: { scenario: { protected: true } }
    end

    let(:json) { JSON.parse(response.body) }

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'sets the scenario to be read-only' do
      expect(json['read_only']).to be(true)
    end

    it 'sets the scenario to be kept compatible' do
      expect(json['keep_compatible']).to be(true)
    end

    it 'includes protected=false in the response' do
      expect(json['protected']).to be(true)
    end
  end

  context 'when inheriting a read-only scenario' do
    before do
      post '/api/v3/scenarios', params: { scenario: { scenario_id: parent.id } }
    end

    let(:parent) do
      FactoryBot.create(
        :scenario,
        api_read_only: true,
        keep_compatible: true,
        user_values: { unrelated_one: 1.0 }
      )
    end

    let(:json) { JSON.parse(response.body) }

    it 'is successful' do
      expect(response.status).to be(200)
    end

    it 'saves the user values' do
      expect(Scenario.find(json['id']).user_values).to eq(parent.user_values)
    end

    it 'does not mark the new scenario as read-only' do
      expect(Scenario.find(json['id'])).not_to be_api_read_only
    end

    it 'does not mark the new scenario as kept compatible' do
      expect(Scenario.find(json['id'])).not_to be_keep_compatible
    end
  end

  context 'when inheriting a scaled scenario' do
    before do
      post '/api/v3/scenarios', params: {
        scenario: { scenario_id: FactoryBot.create(:scaled_scenario).id }
      }
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

      let(:preset) { FactoryBot.create(:scenario_with_user_values) }
      let(:json)   { JSON.parse(response.body) }
      let(:multi)  { 500_000 / Atlas::Dataset.find(:nl).number_of_residences.to_f }

      it 'should be successful' do
        expect(response.status).to eql(200)
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

      context 'when the preset has a heat network order' do
        let(:preset) do
          FactoryBot.create(:scenario_with_heat_network)
        end

        it 'creates a heat network order' do
          expect(HeatNetworkOrder.where(scenario_id: json['id']).count).to eq(1)
        end
      end
    end

    context 'with an already-scaled scenario' do
      let(:preset) { FactoryBot.create(:scenario_with_user_values) }

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
            to be_within(1e-5).of(preset.user_values[:foo_demand])

          expect(scenario.user_values['input_2']).
            to be_within(1e-5).of(preset.user_values[:input_2])

          # Input 3 is a non-scaled input
          expect(scenario.user_values['input_3']).
            to be_within(1e-5).of(preset.user_values[:input_3])
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
          unscaled = Scenario.find(json['template'])
          scaled   = Scenario.find(json['id'])

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
        end

        let(:create_scenario) do
          post '/api/v3/scenarios', params: {
            scenario: {
              scenario_id: Scenario.last.id, descale: true
            }
          }
        end

        let(:json) { JSON.parse(response.body) }

        it 'should be successful' do
          create_scenario
          expect(response.status).to eq(200)
        end

        it 'should create a second scenario from the base dataset' do
          expect { create_scenario }.to change(Scenario, :count).by(1)
        end
      end
    end # with a derived dataset
  end # when scaling the area

end
