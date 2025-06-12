# frozen_string_literal: true

module Inspect
  module Scenarios
    class SearchComponent < ApplicationComponent
      def initialize(query:)
        @query = query
      end
    end
  end
end
