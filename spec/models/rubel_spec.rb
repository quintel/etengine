require 'spec_helper'

class Rubel::Base
  def RAISE()
    raise "ERROR"
  end
end

class RubelLookup
  def initialize(hsh) @hsh = hsh.with_indifferent_access; end
  def lookup(key) @hsh[key]; end
end

describe Rubel do
  before { @rubel = Rubel::Base.new(RubelLookup.new(foo: 3, bar: 2)) }
  
  it "should LOOKUP" do
    @rubel.query('LOOKUP(foo)').should == [3]
    @rubel.query('LOOKUP(foo, bar)').should == [3,2]
    @rubel.query('LOOKUP(foo, bar, nothing)').should == [3,2]
  end

  it "should V" do
    @rubel.query('V(foo)').should == 3
    @rubel.query('V(foo, abs2)').should == 9
    @rubel.query('V(foo, bar, abs2)').should == [9,4]
  end

  it "should" do
    @rubel.query('ATTR("foo", "length")').should == 3
    @rubel.query('ATTR("foo", length)').should == 3
    @rubel.query('ATTR(1, "inspect")').should == "1"
  end

  it "should use ruby powers" do
    @rubel.query('V(foo, to_i) + V(bar, to_i)').should == 5
  end

  it "should accept parameters for ATTR" do
    @rubel.query('ATTR(0.12345, "round(1)")').should == 0.1
    @rubel.query('ATTR(0.12345, round(1))').should == 0.1
  end

  it "should accept GQL within parameters" do
    @rubel.query('ATTR(0.12345, round(SUM(1,2)))').should == 0.123
    # Following is not supported:
    # @rubel.query('ATTR(0.12345, "round(SUM(1,2))")').should == 0.123
  end


  it "should SUM" do
    @rubel.query("SUM(1,2)").should == 3
    @rubel.query("SUM(1,2,[3,4])").should == 10
  end

  pending "should IF should not raise if with lambda" do
    @rubel.query("IF(true,  1, lambda{RAISE()}   )").should == 1
    @rubel.query("IF(false,    lambda{RAISE()}, 1)").should == 1
  end

  pending "should raise if outside lambda" do
    lambda { @rubel.query("IF(true,1,RAISE())") }.should raise_error
    lambda { @rubel.query("IF(false,RAISE(),1)") }.should raise_error
  end

  describe "sandbox" do      
    pending "should return constant as symbol" do
      @rubel.query("SOME_CONSTANT").should == :SOME_CONSTANT
    end

    pending "should protect form accessing classes and modules" do
      # do else where
      @rubel.query("File").should   == :File
      @rubel.query("Object").should == :Object
      @rubel.query("::File").should   == :File
    end

  end
end
