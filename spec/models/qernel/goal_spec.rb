require 'spec_helper'

module Qernel
  describe Goal do
    describe "#new" do
      it "should have a key" do
        g = Goal.new(:foo)
        expect(g.key).to eq(:foo)
      end
    end

    describe "#is_set?" do
      it "should return false if the user value is nil" do
        g = Goal.new(:foo)
        expect(g.is_set?).to be_falsey
      end

      it "should return true if the user value is not nil" do
        g = Goal.new(:foo)
        g.user_value = 123
        expect(g.is_set?).to be_truthy
      end
    end

    describe "#[]=" do
      it "should assign an attribute using the [key]= value syntax" do
        g = Goal.new(:foo)
        g[:user_value] = 123
        expect(g.user_value).to eq(123)
      end

      it "should not assign invalid attributes" do
        g = Goal.new(:foo)
        expect { g[:bar] = 123 }.not_to raise_error
        expect { g.bar }.to raise_error(NoMethodError)
      end
    end
  end
end
