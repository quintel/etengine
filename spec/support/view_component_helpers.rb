# frozen_string_literal: true

module ViewComponentHelpers
  extend ActiveSupport::Concern

  included do
    include ViewComponent::TestHelpers
    include Capybara::RSpecMatchers
    include Devise::Test::IntegrationHelpers
  end

  # Make a template method available for RSpec matchers.
  def template
    lookup_context = ActionView::LookupContext.new(ActionController::Base.view_paths)
    ActionView::Base.new(lookup_context, {}, ApplicationController.new)
  end
end
