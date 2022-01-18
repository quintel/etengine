require 'spec_helper'

describe Api::V3::ScenariosController do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:scenarios) { 5.times.map { FactoryBot.create(:scenario) } }

  before do
    allow(Input).to receive(:records).and_return({
      'foo' => FactoryBot.build(:input, key: :foo, priority: 0),
      'bar' => FactoryBot.build(:input, key: :bar, priority: 0)
    })

    allow(Input).to receive(:all).and_return(Input.records.values)
  end

  describe "GET show.json" do
    it "should return a scenario info" do
      get :show, params: { :id => scenario.id }, :format => :json
      expect(response).to be_successful
      expect(assigns(:scenario)).to eq(scenario)
    end
  end

  describe "GET batch.json" do
    it "should return the info of multiple scenarios" do
      get :batch, params: { :id => [scenarios.map(&:id)].join(',') }, :format => :json
      expect(response).to be_successful

      expect(assigns(:serializers)).to all(be_a(ScenarioSerializer))
    end
  end

  describe "GET templates" do
    it "should return the homepage scenarios" do
      get :templates
      expect(response).to be_successful
    end

    it "should not include in_start_menu=false scenarios" do
      get :templates

      parsed = JSON.parse(response.body)

      expect(parsed.length).to eq(Preset.visible.length)
      expect(parsed.map { |v| v['title'] }).to_not include('Hidden Preset')
    end
  end

  describe "PUT scenario" do
    before do
      @scenario = FactoryBot.create(:scenario, :user_values => {'foo' => 23.0})
    end

    it "should reset parameters" do
      put :update, params: { :id => @scenario.id, :reset => true }
      expect(response).to be_successful
      expect(@scenario.reload.user_values).to eq({})
    end

    it "should merge parameters" do
      put :update, params: {:id => @scenario.id, :scenario => {:user_values => {'bar' => 56.0}}}
      expect(response).to be_successful
      expect(@scenario.reload.user_values.to_set).to eq({'foo' => 23.0, 'bar' => 56.0}.to_set)
    end

    it "should merge parameters resetting old values when needed" do
      put :update, params: {:id => @scenario.id, :scenario => {:user_values => {'bar' => 56.0}}, :reset => true}
      expect(response).to be_successful
      expect(@scenario.reload.user_values.to_set).to eq({'bar' => 56.0}.to_set)
    end

    it "should update parameters" do
      put :update, params: {:id => @scenario.id, :scenario => {:user_values => {'foo' => 56.0}}}
      expect(response).to be_successful
      expect(@scenario.reload.user_values.to_set).to eq({'foo' => 56.0}.to_set)
      expect(@scenario.reload.user_values).to eq({'foo' => 56.0})
    end

    it "shouldn't update end_year" do
      put :update, params: {:id => @scenario.id, :scenario => {:end_year => 2050}}
      expect(response).to be_successful
      expect(@scenario.reload.end_year).to eq(2040)
    end

    it "shouldn't update start_year" do
      expect {
        put :update, params: {:id => @scenario.id, :scenario => {:start_year => 2009}}
      }.to_not change { @scenario.reload.start_year }

      expect(response).to be_successful
    end

    it "shouldn't update area" do
      put :update, params: {:id => @scenario.id, :scenario => {:area_code => 'de'}}
      expect(response).to be_successful
      expect(@scenario.reload.area_code).to eq('nl')
    end

    # The whole object should be overwritten
    context 'when updating the metadata' do
      before do
        @scenario.metadata = { 'kittens' => 'milk', 'ctm_scenario_id' => 3445 }
        put :update, params: {
          id: @scenario.id,
          scenario: { metadata: { kittens: 'mew', my_secret: [2, 3, 4] } }
        }
        response
      end

      it 'updates the old fields' do
        expect(@scenario.reload.metadata['kittens']).to eq('mew')
      end

      it 'removes the fields that were already there' do
        expect(@scenario.reload.metadata).not_to have_key('ctm_scenario_id')
      end

      it 'adds the new fields' do
        expect(@scenario.reload.metadata).to have_key('my_secret')
      end
    end
  end

  describe 'POST create' do
    context 'with supplied metadata' do
      before do
        post :create, params: { scenario: { area_code: 'nl', metadata: metadata } }
      end

      let(:metadata) { { ctm_scenario_id: 123 } }

      it 'is successful' do
        expect(response).to be_successful
      end

      it 'sets the metadata' do
        scenario = Scenario.find(JSON.parse(response.body)['id'])
        expect(scenario.metadata).to eq({ 'ctm_scenario_id' => '123' })
      end

      it 'makes the ctm_scenario_id available' do
        scenario = Scenario.find(JSON.parse(response.body)['id'])
        expect(scenario.metadata[:ctm_scenario_id]).to eq('123')
      end

      context 'when metadata is huge' do
        let(:metadata) { (0..15_000).to_h { |i| [i, i] } }

        it 'fails' do
          expect(response).not_to be_successful
        end

        it 'gives an error message' do
          expect(JSON.parse(response.body)['errors']).to have_key('metadata')
        end
      end
    end
  end
end
