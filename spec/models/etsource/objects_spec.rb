require 'spec_helper'

describe Etsource do
  describe "fixtures/../gquery.txt" do
    before do
      @import = Etsource::Gqueries.new
      @txt = File.read('spec/fixtures/etsource/gqueries/category/gquery.txt')
      @gq = Gquery.new(:key => 'gquery', :unit => 'kg', :query => 'SUM(1,1)', :deprecated_key => "foo_bar")
    end

    it "should export" do
      @import.to_file(@gq).should == @txt
    end

    it "should import correctly" do
      gq = @import.from_file('spec/fixtures/etsource/gqueries/category/gquery.txt')
      gq.key.should   == @gq.key
      gq.unit.should  == @gq.unit
      gq.query.should == @gq.query
      gq.deprecated_key.should == @gq.deprecated_key
    end
  end

  describe "fixtures/../gquery2.txt" do
    before do
      @import = Etsource::Gqueries.new
      @txt = File.read('spec/fixtures/etsource/gqueries/category/gquery2.txt')
      @gq = Gquery.new(:key => 'gquery2', :unit => 'kg', :query => "FOO(\n  BAR(x,y)\n)", :deprecated_key => nil,
        :description => "It has a comment and no deprecated_key"
      )
    end

    it "should export correctly" do
      @import.to_file(@gq).should == @txt
    end

    it "should import correctly" do
      gq = @import.from_file('spec/fixtures/etsource/gqueries/category/gquery2.txt')
      gq.key.should   == @gq.key
      gq.unit.should  == @gq.unit
      gq.query.should == @gq.query
      gq.deprecated_key.should == @gq.deprecated_key
      gq.description.should == @gq.description
    end
  end

end
