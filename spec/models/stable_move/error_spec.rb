# frozen_string_literal: true

require 'spec_helper'

describe StableMove::Error do
  it 'lists the items in indented lines of at most 72 columns' do
    lines = described_class.listing((1_000_000..1_000_030).to_a)

    expect(lines).to all(satisfy { |line| line.size <= 72 && line.start_with?('   - ', '     ') })
  end

  it 'lists the first 100 items and counts the rest' do
    expect(described_class.listing((1..250).to_a, 250).last).to end_with('99, 100 and 150 more')
  end
end
