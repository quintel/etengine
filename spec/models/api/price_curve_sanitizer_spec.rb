# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::PriceCurveSanitizer do
  let(:sanitizer) { described_class.new(curve) }

  context 'with a curve containing 8760 floats' do
    let(:curve) { [1.0] * 8760 }

    it 'is valid' do
      expect(sanitizer).to be_valid
    end

    it 'changes no values when sanitizing' do
      expect(sanitizer.sanitized_curve).to eq(curve)
    end
  end

  context 'with a curve containing 8760 1.2345 floats' do
    let(:curve) { [1.2345] * 8760 }

    it 'is valid' do
      expect(sanitizer).to be_valid
    end

    it 'rounds each value to two decimal places' do
      expect(sanitizer.sanitized_curve).to eq(curve.map { |v| v.round(2) })
    end
  end

  context 'with a curve containing 8760 integers' do
    let(:curve) { [1] * 8760 }

    it 'is valid' do
      expect(sanitizer).to be_valid
    end

    it 'converts each value to a float' do
      expect(sanitizer.sanitized_curve).to eq(curve.map(&:to_f))
    end
  end

  context 'with a curve containing 10 floats' do
    let(:curve) { [1.0] * 10 }

    it 'is not valid' do
      expect(sanitizer).not_to be_valid
    end

    it 'has an error message' do
      sanitizer.valid?

      expect(sanitizer.errors).to include(
        'Curve must have 8760 numeric values, ' \
        'one for each hour in a typical year'
      )
    end

    it 'does not return a sanitized curve' do
      expect(sanitizer.sanitized_curve).to be_nil
    end
  end

  context 'with a curve containing negatives' do
    let(:curve) { [1.0, -1.0] * 4380 }

    it 'is valid' do
      expect(sanitizer).to be_valid
    end

    it 'converts negatives to zero' do
      expect(sanitizer.sanitized_curve.take(4)).to eq([1.0, 0.0, 1.0, 0.0])
    end
  end

  context 'with an empty curve' do
    let(:curve) { [] }

    it 'is not valid' do
      expect(sanitizer).not_to be_valid
    end

    it 'has an error message' do
      sanitizer.valid?

      expect(sanitizer.errors).to include(
        'Curve must have 8760 numeric values, ' \
        'one for each hour in a typical year'
      )
    end

    it 'does not return a sanitized curve' do
      expect(sanitizer.sanitized_curve).to be_nil
    end
  end

  context 'with nil instead of a curve' do
    let(:curve) { nil }

    it 'is not valid' do
      expect(sanitizer).not_to be_valid
    end

    it 'has an error message' do
      sanitizer.valid?

      expect(sanitizer.errors).to include(
        'Curve must be a CSV file containing 8760 numeric values, ' \
        'one for each hour in a typical year'
      )
    end

    it 'does not return a sanitized curve' do
      expect(sanitizer.sanitized_curve).to be_nil
    end
  end

  context 'with a curve containing nil' do
    let(:curve) { [1.0, nil] * 4380 }

    it 'is not valid' do
      expect(sanitizer).not_to be_valid
    end

    it 'has an error message' do
      sanitizer.valid?

      expect(sanitizer.errors).to include(
        'Curve must only contain numeric values'
      )
    end

    it 'does not return a sanitized curve' do
      expect(sanitizer.sanitized_curve).to be_nil
    end
  end

  context 'with a curve containing a string' do
    let(:curve) { [1.0, '1,0'] * 4380 }

    it 'is not valid' do
      expect(sanitizer).not_to be_valid
    end

    it 'has an error message' do
      sanitizer.valid?

      expect(sanitizer.errors).to include(
        'Curve must only contain numeric values'
      )
    end

    it 'does not return a sanitized curve' do
      expect(sanitizer.sanitized_curve).to be_nil
    end
  end

  describe '.from_string' do
    let(:sanitizer) { described_class.from_string(input) }

    context 'when given a string containing 8760 floats' do
      let(:input) { "1.2\n" * 8760 }

      it 'is valid' do
        expect(sanitizer).to be_valid
      end

      it 'sanitizes the curve' do
        expect(sanitizer.sanitized_curve).to eq([1.2] * 8760)
      end
    end

    context 'when given a string containing 8760 integers' do
      let(:input) { "1\n" * 8760 }

      it 'is valid' do
        expect(sanitizer).to be_valid
      end

      it 'sanitizes the curve' do
        expect(sanitizer.sanitized_curve).to eq([1.0] * 8760)
      end
    end

    context 'when given a string containing 8760 values with trailing commas' do
      let(:input) { "1.2,\n" * 8760 }

      it 'is valid' do
        expect(sanitizer).to be_valid
      end

      it 'sanitizes the curve' do
        expect(sanitizer.sanitized_curve).to eq([1.2] * 8760)
      end
    end

    context 'when given an empty string' do
      let(:input) { +'' }

      it 'is not valid' do
        expect(sanitizer).not_to be_valid
      end
    end

    context 'when given a string with mixed values' do
      let(:input) { "1.2\nnope\n" * 4380 }

      it 'is not valid' do
        expect(sanitizer).not_to be_valid
      end
    end

    context 'when given a malformed CSV' do
      let(:input) { "1.2\n1\r2\n" * 4380 }

      it 'is not valid' do
        expect(sanitizer).not_to be_valid
      end
    end

    context 'with given a string with a byte order mark and 8760 floats' do
      let(:input) { "\xEF\xBB\xBF" + ("1.2\n" * 8760) }

      it 'is valid' do
        expect(sanitizer).to be_valid
      end

      it 'sanitizes the curve' do
        expect(sanitizer.sanitized_curve).to eq([1.2] * 8760)
      end
    end
  end
end
