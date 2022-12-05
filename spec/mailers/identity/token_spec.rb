# frozen_string_literal: true

RSpec.describe Identity::TokenMailer, type: :mailer do
  describe 'created_token' do
    let(:user) { create(:user) }

    let(:token) do
      CreatePersonalAccessToken.call(user:, params: { name: 'test' }).value!
    end

    let(:mail) { described_class.created_token(token) }

    it 'renders the headers' do
      expect(mail.subject).to eq('You created a new token')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(Mail::Field.parse("From: #{Settings.mailer.from}").addresses)
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('You just created a new personal access token')
      expect(mail.body.encoded).to match('- View your public scenarios')
      expect(mail.body.encoded).to match("- View other people's public scenarios")
      expect(mail.body.encoded).not_to match('- View your private scenarios')
    end
  end

  describe 'expiring_token' do
    let(:user) { create(:user) }

    let(:token) do
      CreatePersonalAccessToken.call(user:, params: { name: 'test' }).value!
    end

    let(:mail) { described_class.expiring_token(token) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Your personal access token will expire soon')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(Mail::Field.parse("From: #{Settings.mailer.from}").addresses)
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('You have an access token which will expire soon')
      expect(mail.body.encoded).to match('- View your public scenarios')
      expect(mail.body.encoded).to match("- View other people's public scenarios")
      expect(mail.body.encoded).not_to match('- View your private scenarios')
    end
  end
end
