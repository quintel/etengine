# frozen_string_literal: true

require 'spec_helper'

module Gql
  describe Command do
    describe 'cleaning the source' do
      it 'strips whitespace outside string literals' do
        expect(described_class.new("SUM(\n  1,\t2\n)").source).to eq('SUM(1,2)')
      end

      it 'preserves whitespace inside single-quoted strings' do
        expect(described_class.new("SECTOR(emissions_subsector, 'Fuels production')").source)
          .to eq("SECTOR(emissions_subsector,'Fuels production')")
      end

      it 'preserves whitespace inside double-quoted strings' do
        expect(described_class.new('V(foo, "demand * conversion")').source)
          .to eq('V(foo,"demand * conversion")')
      end

      it 'removes a label prefix' do
        expect(described_class.new('future:SUM(1, 2)').source).to eq('SUM(1,2)')
      end

      it 'does not remove label-like text inside a string literal' do
        expect(described_class.new("'future:keep me'").source).to eq("'future:keep me'")
      end

      it 'cleans a nil source to an empty string' do
        expect(described_class.new(nil).source).to eq('')
      end
    end
  end
end
