# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_examples'

RSpec.describe CurveHandler::Processors::Generic do
  include_examples 'a CurveHandler processor'
  include_examples 'a non-normalizing CurveHandler processor'
end
