require 'spec_helper'

module Qernel::Plugins::MeritOrder
  describe "CalculationBreakpoints" do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    pending "fixtures" do
      before do

      end

      it "orders by default" do
      end
    end
  end
end