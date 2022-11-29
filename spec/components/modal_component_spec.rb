# frozen_string_literal: true

RSpec.describe ModalComponent, type: :component do
  context 'with title="Change your password" and content="Change password form"' do
    let(:rendered) do
      render_inline(
        described_class.new(title: 'Change password')
          .with_content('<p>Change password form</p>'.html_safe)
      )
    end

    it 'renders the title' do
      expect(rendered).to have_css('h2', text: 'Change password')
    end

    it 'renders the content' do
      expect(rendered).to have_css('p', text: 'Change password form')
    end
  end

  context 'when in a Turbo-Frame="modal"' do
    before do
      request.headers['Turbo-Frame'] = 'modal'
    end

    let(:component) { described_class.new(title: 'Change password') }
    let(:rendered) { render_inline(component) }

    it 'renders the modal with the correct Stimulus controller' do
      expect(rendered).to have_css("[data-controller='modal']")
    end

    it 'has a button to close the modal' do
      expect(rendered).to have_css('button[aria-label="Close"]')
    end

    it 'animates the load' do
      expect(rendered).to have_css('.modal:not(.animate-none)')
    end

    it 'renders a close link with a Stimulus action' do
      rendered = render_inline(component) do |modal|
        modal.close_link('Close', '/')
      end

      expect(rendered).to have_css('a[href="/"][data-action="click->modal#close"]', text: 'Close')
    end
  end

  context 'when in a Turbo-Frame=""' do
    let(:component) { described_class.new(title: 'Change password') }
    let(:rendered) { render_inline(component) }

    it 'renders the modal without a correct Stimulus controller' do
      expect(rendered).to have_css("[data-controller='']")
    end

    it 'does not have a button to close the modal' do
      expect(rendered).not_to have_css('button[aria-label="Close"]')
    end

    it 'does not animate the load' do
      expect(rendered).to have_css('.modal.animate-none.transition-none')
    end

    it 'renders a close link without a Stimulus action' do
      rendered = render_inline(component) do |modal|
        modal.close_link('Close', '/')
      end

      expect(rendered)
        .to have_css('a[href="/"]:not([data-action="click->modal#close"])', text: 'Close')
    end
  end
end
