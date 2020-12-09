# frozen_string_literal: true

require 'spec_helper'
require_relative './custom_curve_shared_examples'

RSpec.describe CustomCurveSerializer do
  include_examples 'a custom curve Serializer' do
    let(:attachment) { FactoryBot.create(:scenario_attachment) }
  end
end
