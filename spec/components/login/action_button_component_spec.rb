# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Login::ActionButtonComponent, type: :component do
  let(:form) do
    ActionView::Helpers::FormBuilder.new(:user, User.new, template, {})
  end

  context 'with content="Continue" and name="hello"' do
    let(:rendered) do
      render_inline(described_class.new(form:, name: 'hello').with_content('Continue'))
    end

    it 'renders a submit button' do
      expect(rendered).to have_button('Continue', name: 'hello', type: 'submit')
    end
  end

  context 'with color=:success and type="button"' do
    let(:rendered) do
      render_inline(
        described_class.new(form:, color: :success, type: 'button').with_content('Continue')
      )
    end

    it 'renders a submit button' do
      expect(rendered).to have_button('Continue', type: 'button')
    end

    it 'uses the emerald color styles' do
      expect(rendered).to have_button(class: 'bg-emerald-600')
    end
  end
end
