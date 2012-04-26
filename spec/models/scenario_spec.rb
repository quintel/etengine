require 'spec_helper'

describe Scenario do
  before { @scenario = Scenario.new }
  subject { @scenario }

  describe "#default" do
    subject { Scenario.default }
    its(:area_code) { should == 'nl'}
    its(:user_values) { should == {} }
    its(:end_year) { should == 2040 }
    its(:start_year) { should == 2010 }

    describe "#years" do
      its(:years) { should == 30 }
    end
  end

  describe "setting and retrieving user_values" do
    before do
      @input = Input.new
      @scenario.store_user_value(@input, 10)
    end
    specify { @scenario.user_value_for(@input).should == 10}

    it "should return the value when store_user_value" do
      @scenario.store_user_value(@input, 10).should == 10
    end

    describe "overwriting user_value" do
      before { @scenario.store_user_value(@input, 20) }
      specify { @scenario.user_value_for(@input).should == 20}
    end
  end

  describe "#user_values" do
    context ":user_values = YAMLized object (when coming from db)" do
      before {@scenario = Scenario.new(:user_values => {:foo => :bar})}
      it "should unyaml,overwrite and return :user_values" do
        @scenario.user_values.should == {:foo => :bar}
        @scenario.user_values[:foo].should == :bar
      end

    end
    context ":user_values = nil" do
      before {@scenario = Scenario.new(:user_values => {})}
      its(:user_values) { should == {} }
    end
    context ":user_values = obj" do
      before {@scenario = Scenario.new(:user_values => {})}
      its(:user_values) { should == {} }
    end
  end

  describe "#add_update_statements" do
    before do
      @scenario.update_statements = {'converters' => {
        'hot_water_demand_households_energetic' => {'growth_rate' => '0.1', 'other_metric' => '1000'}
      }}
    end

    describe "update existing" do
      before do
        @scenario.add_update_statements({'converters' => {
          'hot_water_demand_households_energetic' => {'growth_rate' => '0.2'}
        }})
      end
      it "should update metric" do
        @scenario.update_statements['converters']['hot_water_demand_households_energetic']['growth_rate'].should eql("0.2")
      end
      it "should keep other metrics" do
        @scenario.update_statements['converters']['hot_water_demand_households_energetic']['other_metric'].should eql("1000")
      end
    end

    describe "creating new" do
      before do
        @scenario.add_update_statements({'converters' => {
          'hot_water_demand_industry_energetic' => {'growth_rate' => '0.2'}
        }})
      end

      it "creates new values" do
        @scenario.update_statements['converters']['hot_water_demand_industry_energetic']['growth_rate'].should eql("0.2")
      end

      it "does not change other items" do
        @scenario.update_statements['converters'].should have(2).items
      end
    end
  end

  # DEBT: find a better way with less stubbing/mocking.
  describe "#update_input" do
    before do
      @value = 13.3
      @input = Input.new
      @input.stub!(:update_statement).with(@value).and_return({})
    end
    it "should store the user value" do
      @scenario.should_receive(:store_user_value).with(@input, @value)
      @scenario.update_input(@input, @value)
    end
    it "should add update_statements" do
      @scenario.should_receive(:add_update_statements).with({}, 'future')
      @scenario.update_input(@input, @value)
    end
  end

  describe "#build_update_statements_for_element" do
    before do
      @input = Input.new()
      Input.stub!(:find).with(any_args).and_return(@input)
    end
    context "if no input found" do
      before { Input.stub!(:find).and_raise(ActiveRecord::RecordNotFound) }
      it "should catch the error" do
        @scenario.build_update_statements_for_element(1, 2.0)
      end
    end
  end

  describe "#reset!" do
    before do
      @scenario.stub!(:area).and_return(mock_model("Area"))
      @scenario.user_values = {}
      @scenario.update_statements = {:foo => :bar}
      @scenario.reset!
    end
    subject {@scenario}
    its(:user_values) { should == {}}
    its(:update_statements) { should == {}}
  end

  describe "#used_groups_add_up?" do
    before do
      @scenario = Scenario.default
      Input.stub!(:inputs_grouped).and_return({
        'share_group' => [
          mock_model(Input, :id => 1, :key => 'element_1', :share_group => 'share_group'),
          mock_model(Input, :id => 2, :key => 'element_2', :share_group => 'share_group'),
          mock_model(Input, :id => 3, :key => 'element_3', :share_group => 'share_group')
        ],
        'share_group_unused' => [
          mock_model(Input, :id => 5, :key => 'element_5', :share_group => 'share_group_unused'),
          mock_model(Input, :id => 6, :key => 'element_6', :share_group => 'share_group_unused'),
        ]
      })
    end
    subject { @scenario }

    describe "#used_groups" do
      context "no user_values" do
        its(:used_groups) { should be_empty }
      end
      context "with 1 user_values" do
        before { @scenario.user_values = {1 => 2}}
        its(:used_groups) { should_not be_empty }
      end
    end

    describe "#used_groups_add_up?" do
      context "no user_values" do
        its(:used_groups_add_up?) { should be_true }
      end
      context "user_valeus but without groups" do
        before { @scenario.user_values = {10 => 2}}
        its(:used_groups_add_up?) { should be_true }
      end
      context "user_values that don't add up to 100" do
        before { @scenario.user_values = {1 => 50}}
        its(:used_groups_add_up?) { should be_false }
        its(:used_groups_not_adding_up) { should have(1).items }
      end
      context "user_values that add up to 100" do
        before { @scenario.user_values = {1 => 50, 2 => 30, 3 => 20}}
        its(:used_groups_add_up?) { should be_true }
      end
    end
  end

  describe "#clone"do
    before do
      @s = Factory :scenario
      @t = @s.clone!
    end

    subject { @t }
    its(:user_values) { should == @s.user_values}
    its(:end_year) { should == @s.end_year}
    its(:area_code) { should == @s.area_code}
  end
end
