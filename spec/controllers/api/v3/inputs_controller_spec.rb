require 'spec_helper'

describe Api::V3::InputsController do
  let(:scenario) { FactoryGirl.create(:scenario) }

  let(:static_input) do
    FactoryGirl.build(:input, {
      min_value:    5,
      max_value:   15,
      start_value: 10
    })
  end

  let(:gql_input) do
    FactoryGirl.build(:input, {
      start_value_gql: 'present:2 * 4',
      min_value_gql:   'present:2 * 2',
      max_value_gql:   'present:2 * 8'
    })
  end

  before do
    NastyCache.instance.expire!
    Input.stub(:all).and_return([ static_input, gql_input ])
  end

  # --------------------------------------------------------------------------

  describe 'GET /api/v3/scenarios/:scenario_id/inputs' do
    let(:json) { JSON.parse(get(:index, id: scenario.id).body) }

    it 'should contain each input' do
      json.should have_key(static_input.key)
      json.should have_key(gql_input.key)
    end

    it 'does not have a "code" attribute for each input' do
      json[static_input.key].should_not have_key('code')
      json[gql_input.key].should_not    have_key('code')
    end

    it 'should have a "min" attribute for each input' do
      json[static_input.key].should include('min' => 5)
      json[gql_input.key].should    include('min' => 4)
    end

    it 'should have a "max" attribute for each input' do
      json[static_input.key].should include('max' => 15)
      json[gql_input.key].should    include('max' => 16)
    end

    it 'should have a "default" attribute for each input' do
      json[static_input.key].should include('default' => 10)
      json[gql_input.key].should    include('default' =>  8)
    end

    context '"disabled" attribute' do
      before do
        static_input.should_receive(:disabled_in_current_area?) { true }
        gql_input.should_receive(:disabled_in_current_area?)    { false }
      end

      it 'should be present when an input is disabled' do
        json[static_input.key].should include('disabled' => true)
      end

      it 'should not be present when an input is not disabled' do
        json[gql_input.key].should_not have_key('disabled')
      end
    end # "disabled" attribute

    context '"label" attribute' do
      before do
        static_input.label_query = 'present:2 * 16'
        static_input.label       = 'g'
        gql_input.label_query    =  nil
      end

      it 'should be present when an input has a label' do
        json[static_input.key].should \
          include('label' => { 'value' => 32.0, 'suffix' => 'g'})
      end

      it 'should not be present when an input is not disabled' do
        json[gql_input.key].should_not have_key('label')
      end
    end # "label" attribute

    context '"user" attribute' do
      before do
        scenario.update_attributes(user_values: { gql_input.key => 42.0 })
      end

      it 'should be present when an input has a user value' do
        json[gql_input.key].should include('user' => 42.0)
      end

      it 'should not be present when an input does not have a user value' do
        json[static_input.key].should_not have_key('user')
      end
    end # "user" attribute
  end # GET /api/v3/scenarios/:scenario_id/inputs

 # ---------------------------------------------------------------------------

 describe 'GET /api/v3/scenarios/:scenario_id/inputs/:id' do
   let(:json) do
     Input.stub(:records).and_return({
       static_input.key => static_input,
       gql_input.key    => gql_input
     })

     get(:show, scenario_id: scenario.id, id: static_input.key)
     JSON.parse(response.body)
   end

   it 'has a "code" attribute' do
     json['code'].should eql(static_input.key)
   end

   it 'has a "min" attribute' do
     json['min'].should eql(5)
   end

   it 'has a "max" attribute' do
     json['max'].should eql(15)
   end

   it 'has a "default" attribute' do
     json['default'].should eql(10)
   end

   context '"disabled" attribute' do
     it 'is present when an input is disabled' do
       static_input.should_receive(:disabled_in_current_area?) { true }
       json['disabled'].should be_true
     end

     it 'is not present when an input is not disabled' do
       static_input.should_receive(:disabled_in_current_area?) { false }
       json.should_not have_key('disabled')
     end
   end # "disabled" attribute

   context '"label" attribute' do
     it 'is present when an input has a label' do
       static_input.label_query = 'present:2 * 16'
       static_input.label       = 'g'

       json['label'].should eql('value' => 32.0, 'suffix' => 'g')
     end

     it 'is present when an input is not disabled' do
       static_input.label_query =  nil
       json.should_not have_key('label')
     end
   end # "label" attribute

   context '"user" attribute' do
     it 'is present when an input has a user value' do
       scenario.update_attributes(user_values: { static_input.key => 42.0 })
       json['user'].should eql(42.0)
     end

     it 'is not present when an input does not have a user value' do
       json.should_not have_key('user')
     end
   end # "user" attribute
 end # GET /api/v3/scenarios/:scenario_id/inputs

 # ---------------------------------------------------------------------------

 describe 'GET /api/v3/scenarios/:scenario_id/inputs/:id,:id,...' do
   let(:third_input) { FactoryGirl.build(:input) }

   let(:json) do
     Input.stub(:records).and_return({
       static_input.key => static_input,
       gql_input.key    => gql_input,
       third_input.key  => third_input
     })

     Input.stub(:all).and_return(Input.records.values)

     keys = "#{ static_input.key },#{ third_input.key }"
     get(:show, scenario_id: scenario.id, id: keys)
     JSON.parse(response.body)
   end

   it 'returns an array' do
     json.should be_kind_of(Array)
   end

   it 'includes the requested inputs' do
     json.should have(2).inputs

     json.any? { |v| v['code'] == static_input.key }.should be_true
     json.any? { |v| v['code'] == third_input.key  }.should be_true
   end

   it 'does not include unrequested inputs' do
     json.any? { |v| v['code'] == gql_input.key }.should be_false
   end
 end # GET /api/v3/scenarios/:scenario_id/inputs

end
