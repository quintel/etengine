require 'spec_helper'

# Reopening NastyCache below appears to prevent Rails 4 from loading the file in
# app/models; so we do it manually.
require 'app/models/nasty_cache'

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
    it 'is the same instance every time' do
      a = NastyCache.instance
      b = NastyCache.instance
      expect(a).to eq(b)
    end
  end

  specify { expect(@cache.get("new_key")).to be_nil }

  it "should set and get" do
    @cache.set("foo", "bar")
    expect(@cache.get("foo")).to eq("bar")
  end

  it "should fetch a block" do
    @cache.fetch("foo2") do 
      'bar'
    end
    expect(@cache.get("foo2")).to eq("bar")
  end

  it "should expire content" do
    @cache.expire!
    expect(@cache.get("to_be_expired")).to be_nil
  end

  it "should expire load profiles" do
    expect { @cache.expire! }.
      to change { Merit::LoadProfile.reader }

    expect { @cache.expire! }.
      to_not change { Merit::LoadProfile.reader.class }
  end

  it "should cache with Rails.cache" do
    expect(@cache.fetch_cached('cache_1_baz') { "bar" }).to eq("bar")
  end

  context 'delete' do
    context 'when no value is set' do
      it 'does nothing' do
        @cache.delete('no')
        expect(@cache.get('no')).to be_nil
      end
    end

    context 'when an in-memory value is set' do
      before { @cache.set('inmem', 1) }

      it 'removes the in-memory value' do
        expect { @cache.delete('inmem') }
          .to change { @cache.get('inmem') }
          .from(1).to(nil)
      end
    end

    context 'when a Rails cache value is set' do
      before { @cache.fetch_cached('rval') { 2 } }

      it 'removes the in-memory value' do
        expect { @cache.delete('rval') }
          .to change { @cache.get('rval') }
          .from(2).to(nil)
      end
    end
  end

  context "two processes" do
    before {
      @cache_1 = NastyCache.new_process
      @cache_1.set("foo", "bar")
      @cache_2 = NastyCache.new_process
    }

    it "both process should not be expired" do
      expect(@cache_1.expired?).to be_falsey
      expect(@cache_2.expired?).to be_falsey
    end

    it "both process should not be expired" do
      @cache_3 = NastyCache.new_process
      @cache_3.mark_expired!
      expect(@cache_3.expired?).to be_truthy
      expect(@cache_1.expired?).to be_truthy
      expect(@cache_2.expired?).to be_truthy
    end

    it "should cache separately" do
      expect(@cache_1.get("foo")).not_to eq(@cache_2.get('foo'))
    end

    it "should not be expired" do
      @cache_2.set('baz', 1)
      @cache_2.expire!
      expect(@cache_1.expired?).to be_truthy
      @cache_1.initialize_request
      expect(@cache_1.get("foo")).to be_nil
      expect(@cache_2.get("baz")).to be_nil
    end

    it "should cache with Rails.cache" do
      expect(@cache_1.fetch('cache_1_baz', :cache => true) { "bar" }).to eq("bar")
      expect(@cache_2.fetch('cache_1_baz', :cache => true) { "baz" }).to eq("bar")
    end

    it "should cache with Rails.cache" do
      expect(@cache_1.fetch('cache_1_baz', :cache => true) { "bar" }).to eq("bar")
      expect(@cache_2.fetch_cached('cache_1_baz') { "baz" }).to eq("bar")

    end
    it "should expire Rails.cache" do
      expect(@cache_1.fetch('cache_1_baz', :cache => true) { "bar" }).to eq("bar")
      @cache_1.expire!
      expect(@cache_2.fetch('cache_1_baz', :cache => true) { "baz" }).to eq("baz")
    end
  end
end
