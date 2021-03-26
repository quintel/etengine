# frozen_string_literal: true

# Provides JSON information about gqueries.
class GqueriesSerializer
  # Creates a new Gqueries API serializer.
  #
  # gqueries - The gqueries (Gquery) for which we want JSON.
  #
  def initialize(gqueries)
    @gqueries = gqueries
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # Returns the Hash containing the gqueries and their information.
  #
  def as_json(*)
    @gqueries.map do |gq|
      { 'key' => gq.key, 'unit' => gq.unit, 'description' => gq.description }
    end
  end
end
