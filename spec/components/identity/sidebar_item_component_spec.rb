# frozen_string_literal: true

RSpec.describe Identity::SidebarItemComponent, type: :component do
  context 'with an inactive item' do
    let(:rendered) do
      render_inline(described_class.new(
        path: '/', title: 'Hello', explanation: 'Hello Person', active: false
      ))
    end

    it 'renders the title and explanation' do
      expect(rendered).to have_text('Hello')
      expect(rendered).to have_text('Hello Person')
    end

    it 'has active item classes' do
      expect(rendered).to have_css('a', class: 'border-gray-200')
    end
  end

  context 'with an active item' do
    let(:rendered) do
      render_inline(described_class.new(
        path: '/', title: 'Hello', explanation: 'Hello Person', active: true
      ))
    end

    it 'renders the title and explanation' do
      expect(rendered).to have_text('Hello')
      expect(rendered).to have_text('Hello Person')
    end

    it 'has active item classes' do
      expect(rendered).to have_css('a', class: 'border-midnight-600')
    end
  end
end
