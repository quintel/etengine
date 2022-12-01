# frozen_string_literal: true

RSpec.describe Identity::ProfileEmailComponent, type: :component do
  context 'with a confirmed e-mail address' do
    let(:rendered) do
      render_inline(described_class.new(
        title: 'E-mail', email: 'hello@example.org', confirmed: true
      ))
    end

    it 'renders the e-mail' do
      expect(rendered).to have_text('hello@example.org')
    end

    it 'shows that the e-mail has been confirmed' do
      expect(rendered).to have_css('span', text: 'Verified')
    end
  end

  context 'with an unconfirmed e-mail address' do
    let(:rendered) do
      render_inline(described_class.new(
        title: 'E-mail', email: 'hello@example.org', confirmed: false
      ))
    end

    it 'renders the e-mail' do
      expect(rendered).to have_text('hello@example.org')
    end

    it 'shows that the e-mail has not been confirmed' do
      expect(rendered).to have_css('span', text: 'Not verified')
    end

    it 'renders a link to resend confirmation instructions' do
      expect(rendered).to have_button(text: 'Resend confirmation instructions')
    end
  end
end
