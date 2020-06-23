require 'spec_helper'

module Qernel
  describe do
    describe do # rewrite as part of the etsource/models/reference
      describe Graph, '#initialize' do
        it "should initialize without attributes" do
          @g = Qernel::Graph.new()
        end

        it "should initialize with nodes []" do
          @g = Qernel::Graph.new([Qernel::Node.new(id: 1, key: 'foo')])
        end
      end

      describe Graph, 'valid' do
        before  { @graph = Qernel::Graph.new() }

        subject { @graph }

        it 'has an area assigned' do
          expect(subject.area).to_not be_nil
        end

        it "should #reset_memoized_methods when adding nodes" do
          expect(@graph).to receive(:reset_memoized_methods)
          @graph.nodes = []
        end

        skip "should assign graph to nodes" do
          node = Qernel::Node.new(id: 1, key: 'foo')

          @graph.nodes = [node]
          expect(node.graph).to eq(@graph)
        end
      end

      describe Graph, '#lifecycle' do
        let(:graph) { Qernel::GraphParser.create("lft == s(1.0) ==< rgt(100)") }

        it 'returns a Qernel::LifeCycle' do
          expect(graph.lifecycle).to be_a(Qernel::Lifecycle)
        end

        it 'returns the same object on subsequent calls' do
          expect(graph.lifecycle.object_id).to eq(graph.lifecycle.object_id)
        end

        it 'returns the same object when dataset caching is disabled' do
          graph.without_dataset_caching do
            expect(graph.lifecycle.object_id).to eq(graph.lifecycle.object_id)
          end
        end
      end

      describe Graph, '#without_dataset_caching' do
        let(:graph) { Qernel::GraphParser.create("lft == s(1.0) ==< rgt(100)") }

        context 'with an initial value of true' do
          it 'starts as true' do
            expect(graph.cache_dataset_fetch?).to be(true)
          end

          it 'is false during the block' do
            graph.without_dataset_caching do
              expect(graph.cache_dataset_fetch?).to be(false)
            end
          end

          it 'ends as true' do
            expect { graph.without_dataset_caching {} }
              .not_to change { graph.cache_dataset_fetch? }.from(true)
          end

          it 'ends as true when an exception is raised' do
            begin
              expect { graph.without_dataset_caching { raise 'error' } }
                .not_to change { graph.cache_dataset_fetch? }.from(true)
            rescue RuntimeError
              nil
            else
              throw 'Expected exception to be raised in block'
            end
          end

          context 'and a nested value of false' do
            it 'is false after the inner block' do
              graph.without_dataset_caching do
                graph.without_dataset_caching do
                end

                expect(graph.cache_dataset_fetch?).to be(false)
              end
            end

            it 'is true after the outer block' do
              graph.without_dataset_caching do
                graph.without_dataset_caching {}
              end

              expect(graph.cache_dataset_fetch?).to be(true)
            end
          end
        end

        context 'with an initial value of false' do
          before { graph.cache_dataset_fetch = false }

          it 'is false during the block' do
            graph.without_dataset_caching do
              expect(graph.cache_dataset_fetch?).to be(false)
            end
          end

          it 'ends as false' do
            expect { graph.without_dataset_caching {} }
              .not_to change { graph.cache_dataset_fetch? }.from(false)
          end

          it 'ends as false when an exception is raised' do
            begin
              expect { graph.without_dataset_caching { raise 'error' } }
                .not_to change { graph.cache_dataset_fetch? }.from(false)
            rescue RuntimeError
              nil
            else
              throw 'Expected exception to be raised in block'
            end
          end
        end
      end

      describe Graph do
        before do |example|
          @g = GraphParser.new(example.description).build
          @g.nodes.each do |node|
            instance_variable_set("@#{node.key}", node)
          end
        end

        context 'group_edges' do
          before do
            @g.edges.first.instance_variable_set(:@groups, [:fd])
          end

          it '# returns an array of edges in the given group
              mid(100) == f(1.0) ==> rgt1
              mid      == f(1.0) ==> rgt2' do
            expect(@g.group_edges(:fd)).to eq([@g.edges.first])
          end
        end # #group_edges

        context "Flex Max" do
          it "# Fill flex_max edge upto max_demand
              mid(100) == f(1.0) ==> rgt1
              mid      == f(1.0) ==> rgt2" do

            @rgt1.output_edges.first.dataset_set(:max_demand, 30.0)
            @g.calculate

            expect(@rgt1.demand).to eq(30.0)
            expect(@rgt2.demand).to eq(70.0)
          end

          it "# flexible edges have a default min_demand of 0.0
              mid(100) == c(120) ==> rgt1(nil)
              mid      == f(1.0) ==> rgt2(nil)" do
            @g.calculate

            expect(@mid.demand).to eq(100.0)
            expect(@rgt1.demand).to eq(120.0)
            expect(@rgt2.demand).to eq(0.0)
          end

          it "# flexible with carrier electricity have no such min_demand of 0.0
              electricity: mid(100) == c(120) ==> rgt1(nil)
              electricity: mid      == f(1.0) ==> rgt2(nil)" do
            @g.calculate

            expect(@mid.demand).to eq(100.0)
            expect(@rgt1.demand).to eq(120.0)
            expect(@rgt2.demand).to eq(-20.0)
          end

          # seb: skip implementatio of min_demand because it'll
          #      complicate things quite a bit.
          #
          # it "# rgt1 min_demand: 30. Rgt1 should get all.
          #     mid(100) == f(1.0) ==> rgt1
          #     mid      == f(1.0) ==> rgt2" do
          #
          #   @rgt1.output_edges.first.min_demand = 30.0
          #   @g.calculate
          #
          #   @rgt1.demand.should == 100.0
          #   @rgt2.demand.should ==   0.0
          # end
        end

        context do

          before do
            @g.calculate
          end

          # ----- SYNTAX  ------------------------------------------------

          # defaults:
          # carrier: foo
          # conversion: 1.0
          # edge_share: nil
          # demand: nil
          #
          # so:
          # "foo  == s ==> bar"
          # is equivalent to:
          # "foo[1.0;1.0]: foo(nil) == s(nil) ==> bar(nil)"


          # ----- Mutliple carriers ------------------------------------------------

          it "bar[0.5]: lft(100) == s(1.0) ==> rgt1
              foo[0.5]: lft      == s(1.0) ==> rgt2" do

            expect(@rgt1.demand).to eq(50.0)
            expect(@rgt2.demand).to eq(50.0)
          end

          # ----- Share only ------------------------------------------------

          it "lft(100) == s(0.3) ==> rgt1(nil)
              lft      == s(0.7) ==> rgt2(nil)" do

            expect(@rgt1.demand).to eq(30.0)
            expect(@rgt2.demand).to eq(70.0)
          end

          # ----- Constant ------------------------------------------------

          it "mid(nil) == c(30) ==> rgt1
              mid      == c(20) ==> rgt2" do

            expect(@mid.demand).to eq(0.0)
            expect(@rgt1.demand).to eq(30.0)
            expect(@rgt2.demand).to eq(20.0)
          end

          it "mid(nil) == c(nil) ==> rgt1(80)
              mid      == c(nil) ==> rgt2(20)" do

            expect(@mid.demand).to eq(100.0)
            expect(@rgt1.demand).to eq(80.0)
            expect(@rgt2.demand).to eq(20.0)
          end

          # ----- Flexible & Share  --------------------------------------

          it "mid(100) == s(0.8) ==> rgt1(nil)
              mid      == f(1.0) ==> rgt2(nil)" do

            expect(@rgt1.demand).to eq(80.0)
            expect(@rgt2.demand).to eq(20.0)
          end

          # ----- Flexible & Constant  --------------------------------------

          it "# If mid has no output edge, it becomes 0.0
              mid(nil) == c(80)  ==> rgt1(nil)
              mid      == f(1.0) ==> rgt2(nil)" do

            expect(@mid.demand).to eq(0.0)
            expect(@rgt1.demand).to eq(80.0)
            expect(@rgt2.demand).to eq(0.0)
          end

          it "# This works, because mid gets demand from lft
              lft(100) == s(1)  ==> mid(nil)
              mid(nil) == c(80) ==> rgt1(nil)
              mid      == f(1)  ==> rgt2(nil)" do

            expect(@lft.demand).to eq(100.0)

            expect(@mid.demand).to eq(100.0)
            expect(@rgt1.demand).to eq(80.0)
            expect(@rgt2.demand).to eq(20.0)
          end

          it "# if constant share is nil, assign right demand to the mid
              mid(nil) == c(nil) ==> rgt1(80)
              mid      == f(1.0) ==> rgt2(nil)" do

            expect(@rgt1.demand).to eq(80.0)

            expect(@mid.demand).to eq(80.0)
            expect(@rgt2.demand).to eq(0.0)
          end


          # ----- Inversed Flexible  --------------------------------------

          it "# if outputs are higher then inputs fill up inversed_flexible
              # with the remainder.
              foo:   loss(nil) == i(nil) ==> mid(nil)
              foo:   lft1(50)  == s(1)   ==> mid
              foo:   mid       == c(nil) ==> rgt1(70)" do

            expect(@rgt1.demand).to eq(70.0)
            expect(@lft1.demand).to eq(50.0)

            expect(@mid.demand).to eq(70.0)
            expect(@loss.demand).to eq(20.0)
          end

          it "# we don't want inversed_flexible to become negative
              # if outputs are higher then inputs set inversed_flexible to 0.0
              foo:   loss(nil) == i(nil)   ==> mid(nil)
              foo:   lft1(100) == s(1)   ==> mid
              foo:   mid       == c(nil) ==> rgt1(40)
              foo:   mid       == f(nil) ==> rgt2(30)" do

            expect(@lft1.demand).to eq(100.0)
            expect(@mid.demand).to eq(100.0)
            expect(@rgt1.demand).to eq(40.0)
            expect(@rgt2.demand).to eq(30.0)
            expect(@loss.demand).to eq(0.0)
          end

          it "# dependent consumes everything
              bar:        loss(nil)      == i(nil) ==> mid(nil)
              foo[1;0.5]: el_output(nil) == d(nil) ==> mid
              bar[1;0.5]: hw_demand(60)  == s(1.0) ==> mid
              foo:        mid            == c(nil) ==> rgt1(120)" do

            expect(@rgt1.demand).to eq(120.0)
            expect(@hw_demand.demand).to eq(60.0)

            expect(@mid.demand).to eq(120.0)
            expect(@el_output.demand).to eq(60.0)
            expect(@loss.demand).to eq(0.0)
          end

          it "# dependent takes it's cut from the total demand (120)
              # is not depending on the other output-edges
              bar[1;0.5]: loss(nil)      == i(nil) ==> mid(nil)
              foo[1;0.5]: el_output(nil) == d(nil) ==> mid
              bar[1;0.5]: hw_demand(50)  == s(1.0) ==> mid
              foo:        mid            == c(nil) ==> rgt1(120)" do

            expect(@rgt1.demand).to eq(120.0)
            expect(@hw_demand.demand).to eq(50.0)

            expect(@mid.demand).to eq(120.0)
            expect(@el_output.demand).to eq(60.0)
            expect(@loss.demand).to eq(10.0)
          end

          # ----- Loops  --------------------------------------

          it "# If right side is lower, fill up flexible edge
              loss(nil) == i(nil) ==> mid(nil)
              lft1(100) == s(1)   ==> mid
                                      mid == f(nil) ==> loss
                                      mid == c(nil) ==> rgt1( 40)" do
            expect(@lft1.demand).to eq(100.0)
            expect(@mid.demand).to eq(100.0)
            expect(@rgt1.demand).to eq(40.0)
            expect(@loss.demand).to eq(60.0)
          end

          # This does not work as expected
          skip "# If right side is higher, fill up inversed_flexible edge
              # sb: HELP: but loss demand stays 0.0???
              loss(nil) == i(nil) ==> mid(nil)
              lft1(100) == s(1)   ==> mid
                                      mid == f(nil) ==> loss
                                      mid == c(nil) ==> rgt1(140)" do
            expect(@lft1.demand).to eq(100.0)
            expect(@mid.demand).to eq(140.0)
            expect(@rgt1.demand).to eq(140.0)
            expect(@loss.demand).to eq(40.0)
          end

          # ----- Dependent  --------------------------------------

          it "bar[1.0;0.7]: hw_demand(70) == s(1) ==> chp(nil)
              foo[1.0;0.3]: el_output(nil) == d()  ==> chp(nil)
              foo:          chp(nil)       == s(1) ==> rgt(nil) " do

            expect(@hw_demand.demand).to eq(70.0)
            expect(@el_output.demand).to eq(30.0)
            expect(@chp.demand).to eq(100.0)
            expect(@rgt.demand).to eq(100.0)
          end

          it "bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
              foo[1.0;0.3]: el_output(40)  == d      ==> chp
              foo:          el_output      == f(nil) ==> rgt1
              #foo:          el_output      == s(0.6) ==> rgt2" do

            expect(@hw_demand.demand).to eq(70.0)
            expect(@chp.demand).to eq(100.0)
            expect(@el_output.demand).to eq(40.0)

            expect(@rgt1.demand).to eq(10.0)
          end

          it "# BUG/INCONSISTENCY
              # Dependent together with shares do not work correctly!!
              # Share seems to be calculated first or doesn't take into account
              # dependent value
              bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
              foo[1.0;0.3]: el_output(40)  == d      ==> chp
              foo:          el_output      == f(nil) ==> rgt1
              foo:          el_output      == s(0.6) ==> rgt2" do

            expect(@hw_demand.demand).to eq(70.0)
            expect(@chp.demand).to eq(100.0)
            expect(@el_output.demand).to eq(40.0)

            expect(@rgt2.demand).to eq(24.0)
            expect(@rgt1.demand).to eq(0.0)
          end


          # it "# with same node does not work
          #     foo[1.0]:     hw_demand(70)  == s(1) ==> chp(nil)
          #     foo[1.0]:     el_output(nil) == d()  ==> chp(nil)
          #     foo:          chp(nil)       == s(1) ==> rgt(nil) " do
          #
          #   @hw_demand.demand.should == 70.0
          #   @el_output.demand.should == 30.0
          #   @chp.demand.should == 100.0
          #   @rgt.demand.should == 100.0
          # end

          # ----- Reversed  --------------------------------------

          it "lft == s(1.0) ==< rgt(100)" do
            expect(@lft.demand).to eq(100.0)
            expect(@rgt.demand).to eq(100.0)
          end

          it "lft == s(1.0) ==< rgt(100)
              lft == s(1.0) ==< rgt2(100)" do

            expect(@lft.demand).to eq(200.0)
          end

          it "lft == s(1.0) ==< rgt(100)
              lft == f(nil) ==< rgt2(100)" do

            expect(@lft.demand).to eq(200.0)
          end

          it "lft      == s(1.0) ==< rgt1(100)
              lft      == f(nil) ==< rgt2(100)
              lft2(50) == s(1.0) ==> rgt2" do

            expect(@lft.demand).to eq(150.0)
            expect(@rgt2.demand).to eq(100.0)
          end

          # ----- Reversed Dependent functionality  ------------------

          describe "Reversed Dependent functionality" do

            it "# dependent as reversed share(1)
                bar[1.0;0.7]: hw_demand(70)  == s(1) ==> chp(nil)
                foo[1.0;0.3]: el_output(nil) == s(1) ==< chp(nil)
                foo:          chp(nil)       == s(1) ==> rgt(nil) " do

              expect(@hw_demand.demand).to eq(70.0)
              expect(@el_output.demand).to eq(30.0)
              expect(@chp.demand).to eq(100.0)
              expect(@rgt.demand).to eq(100.0)
            end

            it "# dependent as reversed flexible
                bar[1.0;0.7]: hw_demand(70)  == s(1) ==> chp(nil)
                foo[1.0;0.3]: el_output(nil) == f(nil) ==< chp(nil)
                foo:          chp(nil)       == s(1) ==> rgt(nil) " do

              expect(@hw_demand.demand).to eq(70.0)
              expect(@el_output.demand).to eq(30.0)
              expect(@chp.demand).to eq(100.0)
              expect(@rgt.demand).to eq(100.0)
            end

            it "bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
                foo[1.0;0.3]: el_output(40)  == s(1.0) ==< chp
                foo:          el_output      == f(nil) ==> rgt1" do

              expect(@hw_demand.demand).to eq(70.0)
              expect(@chp.demand).to eq(100.0)
              expect(@el_output.demand).to eq(40.0)

              expect(@rgt1.demand).to eq(10.0)
            end

            it "# BUG/INCONSISTENCY
                # Dependent together with shares do not work correctly!!
                # Share seems to be calculated first or doesn't take into account
                # dependent value
                bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
                foo[1.0;0.3]: el_output(40)  == s(1.0) ==< chp
                foo:          el_output      == f(nil) ==> rgt1
                foo:          el_output      == s(0.6) ==> rgt2" do

              expect(@hw_demand.demand).to eq(70.0)
              expect(@chp.demand).to eq(100.0)
              expect(@el_output.demand).to eq(40.0)

              expect(@rgt2.demand).to eq(24.0)
              expect(@rgt1.demand).to eq(0.0)
            end

          end

          # ----- Reversed & Inversed Flexible functionality  -----------------------

          # not working
          #
          # it "# if outputs are higher then inputs fill up inversed_flexible
          #     # with the remainder.
          #     loss:  loss(nil) == f(nil) ==< mid(nil)
          #     foo:   lft1(50)  == s(1)   ==> mid
          #     foo:   mid       == c(nil) ==> rgt1(70)" do
          #
          #   @rgt1.demand.should == 70.0
          #   @lft1.demand.should == 50.0
          #
          #   @mid.demand.should ==  70.0
          #   @loss.demand.should == 20.0
          # end
        end
      end

      describe "reversed" do
        before do
          @g = Qernel::GraphParser.create("lft == s(1.0) ==< rgt(100)")
          @rgt = @g.node(:rgt)
          @lft = @g.node(:lft)
          @l = @g.edges.first
        end

        it "should have reversed edge" do
          expect(@l).to be_reversed
          expect(Calculation::Edges.calculated_by_parent?(@l)).to be_truthy
          expect(@l.input).to eq(@g.node(:rgt).slots.first)
          expect(@l.input.expected_external_value).to eq(100.0)
        end

        it "ready" do
          expect(@lft.input(:foo).passive_edges.length).to eq(1)
          expect(@rgt.output(:foo).passive_edges.length).to eq(0)
        end

        it "should calculate edge" do
          expect(@l.send(:calculate)).to eq(100.0)
          expect(@l.value).to eq(100.0)
        end

        it "should calculate rgt slot" do
          @rgt.output(:foo).calculate
          expect(@l.value).to eq(100.0)
        end

        it "lft slot not ready, rgt slot ready" do
          expect(@rgt.output(:foo).ready?).to be_truthy
          expect(@lft.input(:foo).ready?).to be_falsey
        end

        it "should calculate edge" do
          expect(@l.calculate).to eq(100.0)
        end

        context "calculated" do
          before do
            @g.calculate
          end

          # specify { @l.value.should == 100.0 }
        end
      end

      describe "Policy Goals" do
        before do
          @graph = Graph.new
        end

        describe "#goals" do
          it "should have no goals on initialize" do
            expect(@graph.goals).to be_empty
          end

          it "should return all goals" do
            goal = Goal.new(:foo)
            @graph.goals << goal
            expect(@graph.goals).to include(goal)
          end
        end

        describe "#goal" do
          it "should get a goal by key" do
            goal = Goal.new(:foo)
            @graph.goals << goal
            expect(@graph.goal(:foo)).to eq(goal)
          end

          it "should return nil if a goal is missing" do
            expect(@graph.goal(:bar)).to be_nil
          end
        end

        describe "#find_or_create_goal" do
          it "should create a goal object as needed" do
            expect(@graph.goals).to be_empty
            expect(@graph.find_or_create_goal(:foobar)).to be_kind_of(Goal)
            expect(@graph.goals.size).to eq(1)
          end
        end

        # Check query_interface_spec.rb to see how we update goals through GQL
      end
    end
  end
end

