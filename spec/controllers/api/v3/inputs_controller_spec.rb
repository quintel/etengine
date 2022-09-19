require 'spec_helper'

describe Api::V3::InputsController do
  let(:scenario) { FactoryBot.create(:scenario) }

  let(:static_input) do
    FactoryBot.build(:input, {
      min_value:    5,
      max_value:   15,
      start_value: 10
    })
  end

  let(:gql_input) do
    FactoryBot.build(:input, {
      start_value_gql: 'present:2 * 4',
      min_value_gql:   'present:2 * 2',
      max_value_gql:   'present:2 * 8'
    })
  end

  before do
    NastyCache.instance.expire!
    allow(Input).to receive(:all).and_return([ static_input, gql_input ])
  end

  # --------------------------------------------------------------------------

  describe 'GET /api/v3/scenarios/:scenario_id/inputs' do
    let(:json) { JSON.parse(get(:index, params: { scenario_id: scenario.id }).body) }

    it 'is successful' do
      json
      expect(response).to be_ok
    end

    it 'should contain each input' do
      expect(json).to have_key(static_input.key)
      expect(json).to have_key(gql_input.key)
    end

    it 'does not have a "code" attribute for each input' do
      expect(json[static_input.key]).not_to have_key('code')
      expect(json[gql_input.key]).not_to    have_key('code')
    end

    it 'should have a "min" attribute for each input' do
      expect(json[static_input.key]).to include('min' => 5)
      expect(json[gql_input.key]).to    include('min' => 4)
    end

    it 'should have a "max" attribute for each input' do
      expect(json[static_input.key]).to include('max' => 15)
      expect(json[gql_input.key]).to    include('max' => 16)
    end

    it 'should have a "default" attribute for each input' do
      expect(json[static_input.key]).to include('default' => 10)
      expect(json[gql_input.key]).to    include('default' =>  8)
    end

    context '"disabled" attribute' do
      before do
        expect(static_input).to receive(:disabled_in_current_area?) { true }
        expect(gql_input).to receive(:disabled_in_current_area?)    { false }
      end

      it 'should be present when an input is disabled' do
        expect(json[static_input.key]).to include('disabled' => true)
      end

      it 'should not be present when an input is not disabled' do
        expect(json[gql_input.key]).not_to have_key('disabled')
      end
    end # "disabled" attribute

    context '"label" attribute' do
      before do
        static_input.label_query = 'present:2 * 16'
        static_input.label       = 'g'
        gql_input.label_query    =  nil
      end

      it 'should be present when an input has a label' do
        expect(json[static_input.key]).to \
          include('label' => { 'value' => 32.0, 'suffix' => 'g'})
      end

      it 'should not be present when an input is not disabled' do
        expect(json[gql_input.key]).not_to have_key('label')
      end
    end # "label" attribute

    context '"user" attribute' do
      before do
        scenario.update(user_values: { gql_input.key => 42.0 })
      end

      it 'should be present when an input has a user value' do
        expect(json[gql_input.key]).to include('user' => 42.0)
      end

      it 'should not be present when an input does not have a user value' do
        expect(json[static_input.key]).not_to have_key('user')
      end
    end # "user" attribute

    context 'with a scaled scenario' do
      before do
        ScenarioScaling.create(
          scenario:       scenario,
          area_attribute: 'number_of_residences',
          value:          1_000_000)
      end

      let(:divisor) do
        Atlas::Dataset.find(:nl).number_of_residences / 1_000_000
      end

      it 'scales static input values' do
        expect(json[static_input.key]).to include(
          'min'     =>  5 / divisor,
          'max'     => 15 / divisor,
          'default' => 10 / divisor
        )
      end

      it 'does not scale GQL-based input values' do
        # GQL inputs are not scaled, since they use the local graph to compute
        # their values.
        expect(json[gql_input.key]).to include(
          'min'     =>  4,
          'max'     => 16,
          'default' =>  8
        )
      end
    end # with a scaled scenario

    context 'with an enum input' do
      let(:gql_input) do
        FactoryBot.build(:input, {
          start_value_gql: 'present:1 + 1',
          unit: 'enum',
          min_value_gql: 'present:[1, 2, 3]'
        })
      end

      it 'omits the min value' do
        expect(json[gql_input.key]).not_to have_key('min')
      end

      it 'omits the max value' do
        expect(json[gql_input.key]).not_to have_key('max')
      end

      it 'omits the step value' do
        # expect(json[gql_input.key].keys).not_to include('step')
        expect(json[gql_input.key]).not_to have_key('step')
      end

      it 'includes the permitted values' do
        expect(json[gql_input.key]).to include(
          'permitted_values' => %w[1 2 3]
        )
      end
    end

    context 'when the scenario has a parent, and defaults=parent' do
      let(:scenario) do
        FactoryBot.create(
          :scenario,
          scenario_id: FactoryBot.create(:scenario, user_values: { gql_input.key => 42.0 }).id
        )
      end

      let(:json) do
        JSON.parse(get(:index, params: { scenario_id: scenario.id, defaults: 'parent' }).body)
      end

      it 'has a "default" attribute for each input based on the parent' do
        expect(json[static_input.key]).to include('default' => 10)
        expect(json[gql_input.key]).to    include('default' => 42)
      end
    end

    context 'when the scenario has a parent, and defaults=dataset' do
      let(:scenario) do
        FactoryBot.create(
          :scenario,
          scenario_id: FactoryBot.create(:scenario, user_values: { gql_input.key => 42.0 }).id
        )
      end

      let(:json) do
        JSON.parse(get(:index, params: { scenario_id: scenario.id, defaults: 'original' }).body)
      end

      it 'has a "default" attribute for each input based on the dataset' do
        expect(json[static_input.key]).to include('default' => 10)
        expect(json[gql_input.key]).to    include('default' => 8)
      end
    end
  end # GET /api/v3/scenarios/:scenario_id/inputs

 # ---------------------------------------------------------------------------

 describe 'GET /api/v3/scenarios/:scenario_id/inputs/:id' do
   let(:json) do
     allow(Input).to receive(:records).and_return({
       static_input.key => static_input,
       gql_input.key    => gql_input
     })

     get(:show, params: { scenario_id: scenario.id, id: static_input.key })
     JSON.parse(response.body)
   end

   it 'has a "code" attribute' do
     expect(json['code']).to eql(static_input.key)
   end

   it 'has a "min" attribute' do
     expect(json['min']).to eql(5)
   end

   it 'has a "max" attribute' do
     expect(json['max']).to eql(15)
   end

   it 'has a "default" attribute' do
     expect(json['default']).to eql(10)
   end

   context '"disabled" attribute' do
     it 'is present when an input is disabled' do
       expect(static_input).to receive(:disabled_in_current_area?) { true }
       expect(json['disabled']).to be_truthy
     end

     it 'is not present when an input is not disabled' do
       expect(static_input).to receive(:disabled_in_current_area?) { false }
       expect(json).not_to have_key('disabled')
     end
   end # "disabled" attribute

   context '"label" attribute' do
     it 'is present when an input has a label' do
       static_input.label_query = 'present:2.0 * 16'
       static_input.label       = 'g'

       expect(json['label']).to eql('value' => 32.0, 'suffix' => 'g')
     end

     it 'is present when an input is not disabled' do
       static_input.label_query =  nil
       expect(json).not_to have_key('label')
     end
   end # "label" attribute

   context '"user" attribute' do
     it 'is present when an input has a user value' do
       scenario.update(user_values: { static_input.key => 42.0 })
       expect(json['user']).to eql(42.0)
     end

     it 'is not present when an input does not have a user value' do
       expect(json).not_to have_key('user')
     end
   end # "user" attribute
 end # GET /api/v3/scenarios/:scenario_id/inputs

 # ---------------------------------------------------------------------------

 describe 'GET /api/v3/scenarios/:scenario_id/inputs/:id,:id,...' do
   let(:third_input) { FactoryBot.build(:input) }

   let(:json) do
     allow(Input).to receive(:records).and_return({
       static_input.key => static_input,
       gql_input.key    => gql_input,
       third_input.key  => third_input
     })

     allow(Input).to receive(:all).and_return(Input.records.values)

     keys = "#{ static_input.key },#{ third_input.key }"
     get(:show, params: { scenario_id: scenario.id, id: keys })
     JSON.parse(response.body)
   end

   it 'returns an array' do
     expect(json).to be_kind_of(Array)
   end

   it 'includes the requested inputs' do
     expect(json.size).to eq(2)

     expect(json.any? { |v| v['code'] == static_input.key }).to be_truthy
     expect(json.any? { |v| v['code'] == third_input.key  }).to be_truthy
   end

   it 'does not include unrequested inputs' do
     expect(json.any? { |v| v['code'] == gql_input.key }).to be_falsey
   end
 end # GET /api/v3/scenarios/:scenario_id/inputs

end
