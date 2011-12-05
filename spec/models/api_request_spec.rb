require 'spec_helper'

describe ApiRequest do

  describe "#new" do
    it "should assign settings" do
      ApiRequest.new(:settings => :foo).settings.should == :foo
    end

    it ":id => 'test' => test_scenario?" do
      ApiRequest.new(:id => 'test').should be_test_scenario
    end

    it "should assign :r" do
      keys = %w[foo bar]
      ApiRequest.new(:r => keys.join(ApiRequest::GQUERY_KEY_SEPARATOR)).gquery_keys.should == keys
    end

    it "should assign :result" do
      keys = %w[foo bar]
      ApiRequest.new(:result => keys).gquery_keys.should == keys
    end

    it "should assign :r and :result" do
      keys = %w[foo bar]
      ApiRequest.new(
        :result => keys,
        :r => %w[baz moo].join(ApiRequest::GQUERY_KEY_SEPARATOR)
      ).gquery_keys.sort.should == %w[foo bar baz moo].sort
    end
  end

  describe "#response" do
    before do
      @input1 = Input.create(:query => "UPDATE(V(lft), demand, USER_INPUT())")
      @gquery1 = Gquery.create(:key => 'lft_demand', :query => 'V(lft; demand)')
      @gquery2 = Gquery.create(:key => 'rgt_demand', :query => 'V(rgt; demand)')
      Current.gql = Qernel::GraphParser.gql_stubbed("lft(100) == s(1.0) ==> rgt()")
      ApiRequest.any_instance.stub(:gql).and_return(Current.gql)
    end

    context "test" do
      it "should" do
        request = ApiRequest.response({:id => 'test'})
        request.response['result'].should == nil
      end
    end

    context "existing api_scenario" do
      before do 
        @api_scenario = Factory.create :api_scenario
      end

      it "should" do
        request = ApiRequest.response({:id => @api_scenario.id.to_s})
        request.response['result'].should == nil
      end

      it "should accept 1 gquery ID in :r" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :r => @gquery1.id.to_s
        }).response['result']
        result[@gquery1.id.to_s][0][1].should == 100.0
        result[@gquery1.id.to_s][1][1].should == 100.0
      end

      it "should accept multiple gquery IDs in :r separated by GQUERY_KEY_SEPARATOR" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :r => [@gquery1.id,@gquery2.id].join(ApiRequest::GQUERY_KEY_SEPARATOR)
        }).response['result']

        result[@gquery1.id.to_s][0][1].should == 100.0
        result[@gquery1.id.to_s][1][1].should == 100.0

        result[@gquery2.id.to_s][0][1].should == 100.0
        result[@gquery2.id.to_s][1][1].should == 100.0
      end

      it "should accept multiple gquery KEYs in :r separated by GQUERY_KEY_SEPARATOR" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :r => [@gquery1.key,@gquery2.key].join(ApiRequest::GQUERY_KEY_SEPARATOR)
        }).response['result']

        result[@gquery1.key][1][1].should == 100.0
        result[@gquery2.key][1][1].should == 100.0
      end

      it "should accept an array of gquery keys in :result" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :result => [@gquery1.key,@gquery2.key]
        }).response['result']

        result[@gquery1.key][1][1].should == 100.0
        result[@gquery2.key][1][1].should == 100.0
      end

      it "should accept an array of gquery IDs in :result" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :result => [@gquery1.id.to_s,@gquery2.id.to_s]
        }).response['result']

        result[@gquery1.id.to_s][1][1].should == 100.0
        result[@gquery2.id.to_s][1][1].should == 100.0
      end

      it "should accept a GQL statement in :result" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :result => ["SUM(100,200)"]
        }).response['result']

        result['SUM(100,200)'][1][1].should == 300.0
        result['SUM(100,200)'][1][1].should == 300.0
      end

      it "should accept input and update gql" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :input => {@input1.id.to_s => "5.0"},
          :r => @gquery1.id.to_s
        }).response['result']

        result[@gquery1.id.to_s][0][1].should == 100.0
        result[@gquery1.id.to_s][1][1].should == 5.0
      end
    
      it "should set a goal" do
        input = Input.create(:query => "UPDATE(GOAL(foo),user_value,USER_INPUT())")
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :input => {input.id.to_s => "123"},
          :result => ['V(GOAL(foo);user_value)']
        }).response['result']
        result['V(GOAL(foo);user_value)'][1][1].should == 123
      end
    end

    context "existing api_scenario with existing user_values" do
      before do 
        @api_scenario = Factory.create :api_scenario, :user_values => {@input1.id => 13.0}.to_yaml
      end

      it "should work" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :r => @gquery1.id.to_s
        }).response['result']

        result[@gquery1.id.to_s][0][1].should == 100.0
        result[@gquery1.id.to_s][1][1].should == 13.0
      end

      it "should update input with new value and update gql" do
        result = ApiRequest.response({
          :id => @api_scenario.id.to_s,
          :input => {@input1.id.to_s => "5.0"},
          :r => @gquery1.id.to_s
        }).response['result']

        result[@gquery1.id.to_s][0][1].should == 100.0
        result[@gquery1.id.to_s][1][1].should == 5.0
      end
    end
  end
end
