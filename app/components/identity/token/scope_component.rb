# frozen_string_literal: true

class Identity::Token::ScopeComponent < ViewComponent::Base
  def initialize(name:, enabled:, testid: nil)
    @name = name
    @enabled = enabled
    @testid = testid
  end

  def testid
    # rubocop:disable Rails/OutputSafety
    "data-testid=\"#{@testid}\"".html_safe if @testid && (Rails.env.test? || Rails.env.development?)
    # rubocop:enable Rails/OutputSafety
  end
end
