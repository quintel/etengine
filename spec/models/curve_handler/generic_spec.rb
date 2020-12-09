# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_examples'

RSpec.describe CurveHandler::Generic do
  include_examples 'a CurveHandler'
  include_examples 'a non-normalizing CurveHandler'
end
