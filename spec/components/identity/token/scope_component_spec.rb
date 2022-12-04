# frozen_string_literal: true

RSpec.describe Identity::Token::ScopeComponent, type: :component do
  context 'when the scope is enabled' do
    let(:rendered) do
      render_inline(described_class.new(name: 'My scope', enabled: true))
    end

    it 'renders the scope name' do
      expect(rendered).to have_content('My scope')
    end

    it 'does not hide the scope from screen readers' do
      expect(rendered).not_to have_css('[aria-hidden="true"]')
    end
  end

  context 'when the scope is disabled' do
    let(:rendered) do
      render_inline(described_class.new(name: 'My scope', enabled: false))
    end

    it 'renders the scope name' do
      expect(rendered).to have_content('My scope')
    end

    it 'hides the scope from screen readers' do
      expect(rendered).to have_css('[aria-hidden="true"]')
    end
  end
end
