# frozen_string_literal: true

class Inspect::Scenarios::SearchComponent < ApplicationComponent
  def initialize(query:)
    @query = query
  end
end
