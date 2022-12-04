# frozen_string_literal: true

class Identity::Token::ScopeComponent < ApplicationComponent
  option :name
  option :enabled
  option :testid, optional: true

  def testid
    # rubocop:disable Rails/OutputSafety
    "data-testid=\"#{@testid}\"".html_safe if @testid && (Rails.env.test? || Rails.env.development?)
    # rubocop:enable Rails/OutputSafety
  end
end
