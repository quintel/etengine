# frozen_string_literal: true

require 'spec_helper'

describe CurveMetadataRegistry do
  # The registry is global mutable state populated at boot, so snapshot and
  # restore it around examples that register or clear entries.
  around do |example|
    curves = described_class.instance_variable_get(:@curves)&.dup
    exports = described_class.instance_variable_get(:@exports)&.dup
    example.run
    described_class.instance_variable_set(:@curves, curves)
    described_class.instance_variable_set(:@exports, exports)
  end

  describe '.register_curve' do
    before { described_class.clear! }

    it 'stores the curve with a stringified name and <type>_curve type' do
      described_class.register_curve(:my_curve, type: :merit, description: 'desc')

      expect(described_class.all_curves).to eq(
        [{ name: 'my_curve', type: 'merit_curve', description: 'desc' }]
      )
    end

    it 'raises for an unknown type' do
      expect do
        described_class.register_curve(:bad, type: :nope, description: 'd')
      end.to raise_error(ArgumentError, /Unknown curve type: nope/)
    end
  end

  describe '.register_export' do
    before { described_class.clear! }

    it 'stores the export with a stringified name' do
      described_class.register_export(:my_export, description: 'desc')

      expect(described_class.all_exports).to eq([{ name: 'my_export', description: 'desc' }])
    end
  end

  describe '.clear!' do
    it 'removes all registrations' do
      described_class.register_curve(:c, type: :query, description: 'd')
      described_class.register_export(:e, description: 'd')
      described_class.clear!

      expect(described_class.all_curves).to be_empty
      expect(described_class.all_exports).to be_empty
    end
  end

  # Guards against the registry advertising a curve that cannot be downloaded.
  describe 'consistency with routes' do
    let(:curve_route_names) do
      Rails.application.routes.routes.filter_map do |route|
        match = route.path.spec.to_s.match(%r{/curves/([a-z_]+)\(\.:format\)\z})
        match && match[1]
      end
    end

    it 'registers only curves that have a download route' do
      registered = described_class.all_curves.map { |curve| curve[:name] }
      missing = registered - curve_route_names

      expect(missing).to be_empty, "registered curves without a route: #{missing.join(', ')}"
    end

    # Guards against the registry advertising an export that cannot be downloaded.
    let(:export_route_names) do
      Rails.application.routes.routes.filter_map do |route|
        match = route.path.spec.to_s.match(%r{/scenarios/:id/([a-z_]+)\(\.:format\)\z})
        match && match[1]
      end
    end

    it 'registers only exports that have a download route' do
      registered = described_class.all_exports.map { |export| export[:name] }
      missing = registered - export_route_names

      expect(missing).to be_empty, "registered exports without a route: #{missing.join(', ')}"
    end
  end
end
