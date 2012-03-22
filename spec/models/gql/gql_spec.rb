require 'spec_helper'

describe Gql do
  pending do
    describe "Integration Testing" do
      before do
        @gql = Qernel::GraphParser.gql_stubbed("lft(100) == s(1.0) ==> rgt()")
        @gql.present_graph.year = 2010
        @gql.future_graph.year = 2040
      end

      it "should properly calculate" do
        @gql.query("present:V(lft; demand)").should == 100.0
        @gql.query("present:V(rgt; demand)").should == 100.0
        @gql.query("future:V(lft; demand)").should == 100.0
        @gql.query("future:V(rgt; demand)").should == 100.0
      end

      it "should properly calculate when running manually" do
        @input = Input.new(:query => "UPDATE(V(lft),demand,USER_INPUT())")
        @gql.future.query(@input, 300)

        @gql.query("future:V(lft; demand)").should  == 300.0
        @gql.query("present:V(lft; demand)").should == 100.0
      end

      it "should properly calculate when defined in user_values" do
        @input = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())")
        @gql.scenario.user_values = {@input.id => 300}

        @gql.query("present:V(lft; demand)").should == 100.0
        @gql.query("future:V(lft; demand)").should  == 300.0
      end

      it "should update only present with updateable_period = 'present'" do
        @input = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'present')
        @gql.scenario.user_values = {@input.id => 300}

        @gql.query("present:V(lft; demand)").should == 300.0
        @gql.query("future:V(lft; demand)").should  == 100.0
      end

      it "should update both with updateable_period = 'both'" do
        @input = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'both')
        @gql.scenario.user_values = {@input.id => 300}

        @gql.query("present:V(lft; demand)").should == 300.0
        @gql.query("future:V(lft; demand)").should  == 300.0
      end

      it "should work with mutliple updates" do
        @input1 = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'future' )
        @input2 = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'present')
        @input3 = Input.create!(:query => "UPDATE(V(rgt),demand,USER_INPUT())", :updateable_period => 'future')

        @gql.scenario.user_values = {@input1.id => 300, @input2.id => 200, @input3.id => 250}

        @gql.query("future:V(lft; demand)").should == 300.0
        @gql.query("future:V(rgt; demand)").should  == 250.0
        @gql.query("present:V(lft; demand)").should  == 200.0
      end

      it "should update a converter only once when appears multple times" do
        @input = Input.create!(:query => "UPDATE(V(lft,lft),demand,USER_INPUT())")

        @gql.scenario.user_values = {@input.id => "10%"}

        @gql.query("future:V(lft; demand)").should == 110.0
      end



      # --------- Updating ----------------------------------------------------

      context "v1 to v2" do
        describe "attr_name = growth_rate" do
          before do
            @old_input = Input.create!(
              :keys => 'lft', :attr_name => 'growth_rate',
            :update_type => 'converters', :factor => 100)
            @new_input = Input.create!(:query => 'UPDATE(V(lft), demand, USER_INPUT())', :v1_legacy_unit => '%y')
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 5.0}
            @gql.scenario.load!
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (1.05**30)
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "5.0"}
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (1.05**30)
          end
        end

        describe "attr_name = decrease_rate" do
          before do
            @old_input = Input.create!(
              :keys => 'lft', :attr_name => 'decrease_rate',
            :update_type => 'converters', :factor => 100)
            @new_input = Input.create!(:query => 'UPDATE(V(lft), demand, NEG(USER_INPUT()))', :v1_legacy_unit => '%y')
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 5.0}
            @gql.scenario.load!
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (0.95**30)
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "5.0"}
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (0.95**30)
          end
        end

        describe "attr_name = decrease_total" do
          before do
            @old_input = Input.create!(
              :keys => 'lft', :attr_name => 'decrease_total',
            :update_type => 'converters', :factor => 100)
            @new_input = Input.create!(:query => 'UPDATE(V(lft), demand, NEG(USER_INPUT()))', :v1_legacy_unit => '%')
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 5.0}
            @gql.scenario.load!
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (0.95)
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "5.0"}
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (0.95)
          end
        end

        describe "attr_name = decrease_total with weird factor" do
          before do
            @old_input = Input.create!(
              :keys => 'lft', :attr_name => 'decrease_total',
            :update_type => 'converters', :factor => 250)
            @new_input = Input.create!(:query => 'UPDATE(V(lft), demand, NEG(DIVIDE(USER_INPUT(),V(2.5))))', :v1_legacy_unit => '%')
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 5.0}
            @gql.scenario.load!
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (0.98)
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "5.0"}
            @gql.query("V(lft;demand)").future_value.should == 100.0 * (0.98)
          end
        end
        describe "MarketShare 'market_share' with flexible link" do
          before do
            @gql = Qernel::GraphParser.gql_stubbed("
            cooling_buildings_energetic(100) == s(0.0) ==> city_cooling_network_buildings_energetic(nil)
            cooling_buildings_energetic(100) == s(0.0) ==> gasheatpump_cooling_buildings_energetic(nil)
            cooling_buildings_energetic(100) == s(0.0) ==> heatpump_ts_cooling_buildings_energetic(nil)
            cooling_buildings_energetic(100) == f(1.0) ==> airco_buildings_energetic(nil)
          ")
            @old_input =  Input.create!(:keys => 'gasheatpump_cooling_buildings_energetic', :attr_name => 'cooling_buildings_market_share', :update_type => 'converters', :factor => 100)
            @old_input2 = Input.create!(:keys => 'heatpump_ts_cooling_buildings_energetic', :attr_name => 'cooling_buildings_market_share', :update_type => 'converters', :factor => 100)
            @new_input =  Input.create!(:query => 'UPDATE(LINK(cooling_buildings_energetic,gasheatpump_cooling_buildings_energetic), share, DIVIDE(USER_INPUT(),100))')
            @new_input2 = Input.create!(:query => 'UPDATE(LINK(cooling_buildings_energetic,heatpump_ts_cooling_buildings_energetic), share, DIVIDE(USER_INPUT(),100))')
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 30.0, @old_input2.id => 30.0}
            @gql.scenario.load!
            @gql.query("V(cooling_buildings_energetic;demand)").future_value.should == 100.0
            @gql.query("V(gasheatpump_cooling_buildings_energetic;demand)").future_value.should == 30.0
            @gql.query("V(heatpump_ts_cooling_buildings_energetic;demand)").future_value.should == 30.0
            @gql.query("V(airco_buildings_energetic;demand)").future_value.should == 40.0
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "30", @new_input2.id => "30"}
            @gql.query("V(cooling_buildings_energetic;demand)").future_value.should == 100.0
            @gql.query("V(gasheatpump_cooling_buildings_energetic;demand)").future_value.should == 30.0
            @gql.query("V(heatpump_ts_cooling_buildings_energetic;demand)").future_value.should == 30.0
            @gql.query("V(airco_buildings_energetic;demand)").future_value.should == 40.0
          end
        end

        describe "MarketShare 'market_share' without flexible" do
          before do
            @gql = Qernel::GraphParser.gql_stubbed("
            cooling_buildings_energetic(100) == s(0.0) ==> city_cooling_network_buildings_energetic(nil)
            cooling_buildings_energetic(100) == s(0.0) ==> gasheatpump_cooling_buildings_energetic(nil)
            cooling_buildings_energetic(100) == s(0.0) ==> heatpump_ts_cooling_buildings_energetic(nil)
            cooling_buildings_energetic(100) == s(1.0) ==> airco_buildings_energetic(nil)
          ")

            @old_input =  Input.create!(:keys => 'gasheatpump_cooling_buildings_energetic', :attr_name => 'cooling_buildings_market_share', :update_type => 'converters', :factor => 100)
            @new_input =  Input.create!(:query => '
            EACH(
              UPDATE(LINK(cooling_buildings_energetic,gasheatpump_cooling_buildings_energetic), share, DIVIDE(USER_INPUT(),100)),
              UPDATE(LINK(cooling_buildings_energetic,airco_buildings_energetic), share, 
                SUM(NEG(SUM(V(EXCLUDE(INPUT_LINKS(V(cooling_buildings_energetic)),UPDATE_COLLECTION()); share))), 1)
              )
            )')
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 30.0}
            @gql.scenario.load!
            @gql.query("V(cooling_buildings_energetic;demand)").future_value.should == 100.0
            @gql.query("V(gasheatpump_cooling_buildings_energetic;demand)").future_value.should == 30.0
            @gql.query("V(airco_buildings_energetic;demand)").future_value.should == 70.0
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "30.0"}
            @gql.query("V(cooling_buildings_energetic;demand)").future_value.should == 100.0
            @gql.query("V(gasheatpump_cooling_buildings_energetic;demand)").future_value.should == 30.0
            @gql.query("SUM(1.0, NEG(SUM(V(EXCLUDE(INPUT_LINKS(V(cooling_buildings_energetic)),V(LINK(cooling_buildings_energetic,airco_buildings_energetic))); share))))").future_value.should == 0.7
            @gql.query("V(airco_buildings_energetic;demand)").future_value.should == 70.0
          end
        end


        describe "MarketShareCarrier cooling_market_share" do
          before do
            @gql = Qernel::GraphParser.gql_stubbed("
            cooling: cooling_demand_households_energetic(100) == s(0.0) ==> heatpump_cooling_households_energetic(nil)
            cooling: cooling_demand_households_energetic(100) == s(0.0) ==> gasheatpump_cooling_households_energetic(nil)
            cooling: cooling_demand_households_energetic(100) == s(0.0) ==> heatpump_ts_cooling_households_energetic(nil)
            cooling: cooling_demand_households_energetic(100) == f(1.0) ==> airco_households_energetic(nil)
          ")

            @old_input =  Input.create!(:keys => 'heatpump_cooling_households_energetic', :attr_name => 'cooling_market_share', :update_type => 'converters', :factor => 100)
            @new_input =  Input.create!(:query => 'UPDATE(LINK(heatpump_cooling_households_energetic,cooling_demand_households_energetic), share, DIVIDE(USER_INPUT(),100))')
          end

          pending "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 30.0}
            @gql.scenario.load!
            @gql.query("V(cooling_demand_households_energetic;demand)").future_value.should == 100.0
            @gql.query("V(heatpump_cooling_households_energetic;demand)").future_value.should == 30.0
            @gql.query("V(airco_households_energetic;demand)").future_value.should == 70.0
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "30.0"}
            @gql.query("V(cooling_demand_households_energetic;demand)").future_value.should == 100.0
            @gql.query("V(heatpump_cooling_households_energetic;demand)").future_value.should == 30.0
            @gql.query("V(airco_households_energetic;demand)").future_value.should == 70.0
          end
        end

        # def number_of_units_update
        #   converter = converter_proxy.converter
        #   converter_proxy.number_of_units = value.to_f
        #
        #   converter.outputs.each do |slot|
        #     slot.links.select(&:constant?).each do |link|
        #       link.share = converter.query.production_based_on_number_of_units
        #     end
        #   end
        #   nil
        # end
        describe "attr_name = number_of_units" do
          before do
            @gql = Qernel::GraphParser.gql_stubbed("lft(nil) == c(nil) ==> rgt(100)")

            @old_input = Input.create!(:keys => 'rgt', :attr_name => 'number_of_units', :update_type => 'converters', :factor => 1)
            @new_input = Input.create!(:query => "
            EACH(
              UPDATE(V(rgt), number_of_units, USER_INPUT()),
              UPDATE(OUTPUT_LINKS(V(rgt);constant), share, V(rgt; production_based_on_number_of_units)),
            )")
            @gql.future.graph.converter(:rgt).query.number_of_units = 1.0
            @gql.future.graph.converter(:rgt).query.stub!(:typical_electricity_production_per_unit).and_return(8.0)
          end

          pending "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 5.0}
            @gql.scenario.load!

            @gql.query("V(rgt;number_of_units)").future_value.should == 5.0
            @gql.query("V(OUTPUT_LINKS(V(rgt);constant);value)").future_value.should == 40.0
            @gql.query("V(rgt;demand)").future_value.should == 100.0
          end

          pending "lft demands do not calculate" do
            @gql.query("V(lft;demand)").future_value.should == 40.0
            @gql.query("V(OUTPUT_LINKS(V(rgt);constant);share)").future_value.should == 0.4
          end

          pending "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "5.0"}
            @gql.query("V(rgt;number_of_units)").future_value.should == 5.0
            @gql.query("V(OUTPUT_LINKS(V(rgt);constant);value)").future_value.should == 40.0
            @gql.query("V(rgt;demand)").future_value.should == 100.0
          end
        end

        describe "attr_name = cost_per_mj_growth_total for carrier" do
          before do
            @old_input = Input.create!(
              :keys => 'foo', :attr_name => 'cost_per_mj_growth_total',
            :update_type => 'carriers', :factor => 100.0, :unit => '%')
            @new_input = Input.create!(:query => 'UPDATE(CARRIER(foo), cost_per_mj, USER_INPUT())', :v1_legacy_unit => '%')
            @gql.future.graph.carrier(:foo).cost_per_mj = 100
          end

          it "should work with old" do
            @gql.scenario.user_values = {@old_input.id => 5.0}
            @gql.scenario.load!
            @gql.query("V(CARRIER(foo);cost_per_mj)").future_value.should == 100.0 * 1.05
          end

          it "should work with new" do
            @gql.scenario.user_values = {@new_input.id => "5.0"}
            @gql.query("V(CARRIER(foo);cost_per_mj)").future_value.should == 100.0 * 1.05
          end
        end
      end
    end

    context "basic graph" do
      before do
        @graph = Qernel::GraphParser.new("lft(100) == s(1.0) ==> rgt(120)").build
        Current.instance.stub_chain(:gql, :calculated?).and_return(true)
        @q = QueryInterface.new(nil, @graph)
      end

      describe "update statement: UPDATE(V(lft),demand,USER_INPUT())" do
        {
          "5"    => 5.0,
          "-5"   => -5.0,
          "5%"   => 105.0,
          "-5%"  => 95.0,
          "5%y"  => 100 * (1.05 ** 30),
          "-5%y" => 100 * (0.95 ** 30)
        }.each do |input, expected_demand|
          it "should assign #{expected_demand} with input: #{input}" do
            @q.query(Input.new(:query => "UPDATE(V(lft),demand,USER_INPUT())"), input)
            @q.query("V(lft; demand)").should == expected_demand
          end
        end
      end

      pending "more update statements" do
        it "should update 5%y as growth_rate per year (easy example)" do
          Current.instance.stub_chain(:scenario, :years).and_return(2)
          @q.query("UPDATE(V(lft),demand,USER_INPUT())", "5%y")
          @q.query("V(lft; demand)").should == 100 * 1.05 * 1.05
        end

        it "should update 10 + USER_INPUT as absolute value" do
          @q.query("UPDATE(V(lft),demand,SUM(10, USER_INPUT()))", "5")
          @q.query("V(lft; demand)").should == 15.0
        end

        it "should update 10 + 5% as relative value" do
          @q.query("UPDATE(V(lft),demand,SUM(10, USER_INPUT()))", "5%")
          @q.query("V(lft; demand)").should == 115.0
        end
      end

      describe "UPDATE" do
        it "should query" do
          @q.query("V(lft; demand)").should == 100.0
          @q.query("V(rgt; demand)").should == 120.0
        end

        describe "UPDATE with static values" do
          it "should UPDATE" do
            @q.query("UPDATE(V(lft), demand, 130)")
            @q.query("V(lft; demand)").should == 130.0
          end

          it "should UPDATE multiple" do
            @q.query("UPDATE(V(lft, rgt), demand, 130)")
            @q.query("V(lft; demand)").should == 130.0
            @q.query("V(rgt; demand)").should == 130.0
          end
        end

        describe "UPDATE with dynamic USER_INPUT()" do
          it "should UPDATE using USER_INPUT()" do
            @q.query("UPDATE(V(lft),demand,USER_INPUT())", 300)
            @q.query("V(lft; demand)").should == 300.0
          end
        end


        describe "UPDATE_OBJECT" do
          it "should UPDATE referencing an attribute from UPDATE_OBJECT()" do
            @q.query("UPDATE(V(lft), demand, PRODUCT(V(UPDATE_OBJECT();demand),3))")
            @q.query("V(lft; demand)").should == 300.0
          end

          it "should UPDATE mulitple referencing an attribute from UPDATE_OBJECT()" do
            @q.query("UPDATE(V(lft, rgt), demand, PRODUCT(V(UPDATE_OBJECT();demand),3))")
            @q.query("V(lft; demand)").should == 300.0
            @q.query("V(rgt; demand)").should == 360.0
          end
        end

        describe "UPDATE_COLLECTION" do
          it "should UPDATE mulitple referencing an attribute from UPDATE_COLLECTION()" do
            # updates the demand with how many objects there are to be update
            @q.query("UPDATE(V(lft, rgt), demand, COUNT(UPDATE_COLLECTION()))")
            @q.query("V(lft; demand)").should == 2
            @q.query("V(rgt; demand)").should == 2
          end
        end

        describe "EACH" do
          it "should UPDATE mulitple commands defined in EACH" do
            @q.query("EACH( UPDATE(V(lft),demand,1), UPDATE(V(rgt),demand,2) )")
            @q.query("V(lft; demand)").should == 1.0
            @q.query("V(rgt; demand)").should == 2.0
          end
        end
      end
    end
  end
end
