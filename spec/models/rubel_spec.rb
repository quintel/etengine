require 'spec_helper'


class RubelLookup
  def initialize(hsh) @hsh = hsh.with_indifferent_access; end
  def lookup(key) @hsh[key]; end
end

describe Rubel do
  before { @rubel = Gql::Runtime::Sandbox.new(RubelLookup.new(foo: 3, bar: 2)) }

  it "should accept parameters for MAP" do
    @rubel.execute('MAP(0.12345, "round(1)")').should == 0.1
    @rubel.execute('MAP(0.12345,  round(1) )').should == 0.1
  end

  it "should accept GQL within parameters" do
    @rubel.execute('MAP(0.12345, round(SUM(1,2)))').should == 0.123
    # Following is not supported:
    # @rubel.execute('MAP(0.12345, "round(SUM(1,2))")').should == 0.123
  end

  pending do 
    it "should LOOKUP" do
      @rubel.execute('LOOKUP(foo)').should == [3]
      @rubel.execute('LOOKUP(foo, bar)').should == [3,2]
      @rubel.execute('LOOKUP(foo, bar, nothing)').should == [3,2]
    end

    it "should V" do
      @rubel.execute('V(foo)').should == 3
      @rubel.execute('V(foo, abs2)').should == 9
      @rubel.execute('V(foo, bar, abs2)').should == [9,4]
    end

    it "should" do
      @rubel.execute('MAP("foo", "length")').should == 3
      @rubel.execute('MAP("foo", length)').should == 3
      @rubel.execute('MAP(1,     "inspect")').should == "1"
    end

    it "should use ruby powers" do
      @rubel.execute('V(foo, to_i) + V(bar, to_i)').should == 5
    end

    it "should accept parameters for MAP" do
      @rubel.execute('MAP(0.12345, "round(1)")').should == 0.1
      @rubel.execute('MAP(0.12345,  round(1) )').should == 0.1
    end

    it "should accept GQL within parameters" do
      @rubel.execute('MAP(0.12345, round(SUM(1,2)))').should == 0.123
      # Following is not supported:
      # @rubel.execute('MAP(0.12345, "round(SUM(1,2))")').should == 0.123
    end


    it "should SUM" do
      @rubel.execute("SUM(1,2)").should == 3
      @rubel.execute("SUM(1,2,[3,4])").should == 10
    end

    pending "should IF should not raise if with lambda" do
      @rubel.execute("IF(true,  1, lambda{RAISE()}   )").should == 1
      @rubel.execute("IF(false,    lambda{RAISE()}, 1)").should == 1
    end

    pending "should raise if outside lambda" do
      lambda { @rubel.execute("IF(true,1,RAISE())") }.should raise_error
      lambda { @rubel.execute("IF(false,RAISE(),1)") }.should raise_error
    end

    describe "sandbox" do      
      pending "should return constant as symbol" do
        @rubel.execute("SOME_CONSTANT").should == :SOME_CONSTANT
      end

      pending "should protect form accessing classes and modules" do
        # do else where
        @rubel.execute("File").should   == :File
        @rubel.execute("Object").should == :Object
        @rubel.execute("::File").should   == :File
      end

    end
  end
end

