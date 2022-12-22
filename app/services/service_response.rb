# frozen_string_literal: true

# Helpers for returning failures from services which contain both a response body and status code.
ServiceResponse = Struct.new(:json, :status) do
  def self.not_found
    new({ errors: ['Not found'] }, :not_found)
  end

  def to_response
    { json:, status: }
  end
end
