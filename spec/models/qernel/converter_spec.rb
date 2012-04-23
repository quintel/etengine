require 'spec_helper'

module Qernel

  describe Converter do
    describe 'when no type is specified' do
      it 'should use the default converter API' do
        api = Converter.new(id: 1).converter_api
        api.should be_kind_of(Qernel::ConverterApi)
      end
    end

    describe 'when the type is :default' do
      it 'should use the default converter API' do
        api = Converter.new(id: 1, type: :default).converter_api
        api.should be_kind_of(Qernel::ConverterApi)
      end
    end

    describe 'when the type is :demand_driven' do
      it 'should use the demand-driven converter API' do
        api = Converter.new(id: 1, type: :demand_driven).converter_api
        api.should be_kind_of(Qernel::DemandDrivenConverterApi)
      end
    end
  end

end
