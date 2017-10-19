require 'spec_helper'


class RubelLookup
  def initialize(hsh) @hsh = hsh.with_indifferent_access; end
  def lookup(key) @hsh[key]; end
end

RSpec.describe Rubel do
  before { @rubel = Gql::Runtime::Sandbox.new(RubelLookup.new(foo: 3, bar: 2)) }

  it "should accept parameters for MAP" do
    expect(@rubel.execute('MAP(0.12345, "round(1)")')).to eq(0.1)
    expect(@rubel.execute('MAP(0.12345,  round(1) )')).to eq(0.1)
  end

  it "should accept GQL within parameters" do
    expect(@rubel.execute('MAP(0.12345, round(SUM(1,2)))')).to eq(0.123)
    # Following is not supported:
    # @rubel.execute('MAP(0.12345, "round(SUM(1,2))")').should == 0.123
  end

  skip do
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

    pending "should IF should not raise if with lambda"
    expect(@rubel.execute("IF(true,  1, lambda{RAISE()}   )")).to eq(1)
    expect(@rubel.execute("IF(false,    lambda{RAISE()}, 1)")).to eq(1)

    pending "should raise if outside lambda"
    expect { @rubel.execute("IF(true,1,RAISE())") }.to raise_error
    expect { @rubel.execute("IF(false,RAISE(),1)") }.to raise_error

    describe "sandbox" do
      skip "should return constant as symbol" do
        expect(@rubel.execute("SOME_CONSTANT")).to eq(:SOME_CONSTANT)
      end

      skip "should protect form accessing classes and modules" do
        # do else where
        expect(@rubel.execute("File")).to   eq(:File)
        expect(@rubel.execute("Object")).to eq(:Object)
        expect(@rubel.execute("::File")).to   eq(:File)
      end

    end
  end
end

