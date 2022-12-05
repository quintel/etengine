# frozen_string_literal: true

RSpec.describe Identity::TokenComponent, type: :component do
  def build_token(expires_in: nil, created_at: Time.now, scopes: '')
    PersonalAccessToken.new(
      id: 1,
      name: 'API access',
      oauth_access_token: Doorkeeper::AccessToken.new(
        token: 'etm_1234567890',
        expires_in:,
        scopes:,
        created_at:
      )
    )
  end

  let(:rendered) do
    render_inline(described_class.new(token:))
  end

  context 'with a non-expiring token' do
    let(:token) do
      build_token(expires_in: nil)
    end

    it 'renders that the token never expires' do
      expect(rendered.css('[data-testid="expires"]')).to have_content('Never')
    end
  end

  context 'with a token that expires in one year' do
    let(:token) do
      build_token(expires_in: 1.year)
    end

    it 'renders when the token expires' do
      expect(rendered.css('[data-testid="expires"]')).to have_content('1 year from now')
    end
  end

  context 'when the token was just created' do
    let(:token) do
      build_token(created_at: Time.zone.now)
    end

    it 'renders the full token' do
      expect(rendered).to have_css('input[value="etm_1234567890"]')
    end

    it 'renders the clipboard button' do
      expect(rendered).to have_button('Copy token to clipboard')
    end
  end

  context 'when the token is two minutes old' do
    let(:token) do
      build_token(created_at: 2.minutes.ago)
    end

    it 'does not render the full token' do
      expect(rendered).not_to have_css('input[value="etm_1234567890"]')
      expect(rendered).to have_css('.font-mono', text: 'etm_12345...')
    end

    it 'does not render the clipboard button' do
      expect(rendered).not_to have_button('Copy token to clipboard')
    end
  end

  context 'with scopes="public scenarios:read"' do
    let(:token) do
      build_token(scopes: 'public scenarios:read')
    end

    it 'shows that the token may read public scenarios' do
      expect(rendered).to have_css(
        '[data-testid="scope:public"]:not([aria-hidden="true"])',
        text: 'Read public scenarios'
      )
    end

    it 'shows that the token may read private scenarios' do
      expect(rendered).to have_css(
        '[data-testid="scope:scenarios:read"]:not([aria-hidden="true"])',
        text: 'Read your private scenarios'
      )
    end

    it 'shows that the token may not write scenarios' do
      expect(rendered).to have_css(
        '[data-testid="scope:scenarios:write"][aria-hidden="true"]',
        text: 'Create new scenarios and change your public and private scenarios'
      )
    end

    it 'shows that the token may not delete scenarios' do
      expect(rendered).to have_css(
        '[data-testid="scope:scenarios:delete"][aria-hidden="true"]',
        text: 'Delete your public and private scenarios'
      )
    end
  end
end
