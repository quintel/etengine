require 'spec_helper'

class NastyCache
  # used to simulate two different server process
  def self.new_process
    new
  end
end

describe NastyCache do
  before {
    @cache = NastyCache.instance
    @cache.set("to_be_expired", "foo")
  }
    
  describe "SingleTon" do
    a = NastyCache.instance
    b = NastyCache.instance
    a.should == b
  end

  specify { @cache.get("new_key").should be_nil }

  it "should set and get" do
    @cache.set("foo", "bar")
    @cache.get("foo").should == "bar"
  end

  it "should fetch a block" do
    @cache.fetch("foo2") do 
      'bar'
    end
    @cache.get("foo2").should == "bar"
  end

  it "should expire content" do
    @cache.expire!
    @cache.get("to_be_expired").should be_nil
  end

  it "should cache with Rails.cache" do
    @cache_1.fetch_cached('cache_1_baz') { "bar" }.should == "bar"
  end

  context "two processes" do
    before {
      @cache_1 = NastyCache.instance
      @cache_1.set("foo", "bar")
      @cache_2 = NastyCache.new_process
    }

    it "both process should not be expired" do
      @cache_1.expired?.should be_false
      @cache_2.expired?.should be_false
    end

    it "both process should not be expired" do
      @cache_3 = NastyCache.new_process
      @cache_3.mark_expired!
      @cache_3.expired?.should be_true
      @cache_1.expired?.should be_true
      @cache_2.expired?.should be_true
    end

    it "should cache separately" do
      @cache_1.get("foo").should_not == @cache_2.get('foo')
    end

    it "should not be expired" do
      @cache_2.set('baz', 1)
      @cache_2.expire!
      @cache_1.expired?.should be_true
      @cache_1.initialize_request
      @cache_1.get("foo").should be_nil
      @cache_2.get("baz").should be_nil
    end

    it "should cache with Rails.cache" do
      @cache_1.fetch('cache_1_baz', :cache => true) { "bar" }.should == "bar"
      @cache_2.fetch('cache_1_baz', :cache => true) { "baz" }.should == "bar"
    end

    it "should cache with Rails.cache" do
      @cache_1.fetch('cache_1_baz', :cache => true) { "bar" }.should == "bar"
      @cache_2.fetch_cached('cache_1_baz') { "baz" }.should == "bar"

    end
    it "should expire Rails.cache" do
      @cache_1.fetch('cache_1_baz', :cache => true) { "bar" }.should == "bar"
      @cache_1.expire!
      @cache_2.fetch('cache_1_baz', :cache => true) { "baz" }.should == "baz"
    end
  end
end
