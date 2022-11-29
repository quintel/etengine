# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordFieldComponent, type: :component do
  let(:form) do
    ActionView::Helpers::FormBuilder.new(:user, User.new, template, {})
  end

  let(:rendered) do
    render_inline(described_class.new(form:, name: 'hello'))
  end

  it 'renders a password field' do
    expect(rendered).to have_field(name: 'user[hello]', type: 'password')
  end
end
