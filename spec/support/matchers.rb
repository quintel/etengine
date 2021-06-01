# frozen_string_literal: true

# A matcher which can be given a graph value which has a `query` method, and asserts that the value
# of an attribute matches an expectation.
#
# For example:
#
#   expect(graph.node(:thing)).to have_query_value(:demand, 100)
#
RSpec::Matchers.define(:have_query_value) do |attribute, expected|
  match do |object|
    values_match?(expected, object.query.public_send(attribute))
  end

  description do
    "have #{attribute} of #{expected.inspect}"
  end

  failure_message do |object|
    "  object: #{object.inspect} #{attribute}\n" \
    "expected: #{expected.inspect}\n" \
    "     got: #{object.query.public_send(attribute).inspect}"
  end
end
