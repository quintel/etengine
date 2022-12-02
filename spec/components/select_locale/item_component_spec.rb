# frozen_string_literal: true

RSpec.describe SelectLocale::ItemComponent, type: :component do
  context 'when the item is selected' do
    let(:rendered) do
      render_inline(described_class.new(href: '/', selected: true).with_content('Option'))
    end

    it 'renders a div' do
      expect(rendered).to have_css('div', text: 'Option')
    end

    it 'does not render a link' do
      expect(rendered).not_to have_css('a')
    end
  end

  context 'when the item not selected' do
    let(:rendered) do
      render_inline(described_class.new(href: '/', selected: false).with_content('Option'))
    end

    it 'renders a link' do
      expect(rendered).to have_link(href: '/', text: 'Option')
    end
  end
end
