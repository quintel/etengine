# frozen_string_literal: true

RSpec.describe ScenarioInvitationMailer, type: :mailer do
  let(:email) { 'test@quintel.com' }
  let(:name) { 'Test user' }
  let(:saved_scenario) { { id: 999, title: 'Some saved scenario' } }

  context 'when inviting an existing user' do
    let(:mail) { described_class.invite_user('existing', email, name, saved_scenario) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Invitation: ETM scenario Some saved scenario')
      expect(mail.to).to eq([email])
      expect(mail.from).to eq(Mail::Field.parse("From: #{Settings.mailer.from}").addresses)
    end

    it 'renders the body' do
      expect(mail.body.raw_source).to include("test@quintel.com just invited you to collaborate on scenario")
      expect(mail.body.raw_source).to include("/saved_scenarios/999")
      expect(mail.body.raw_source).to_not include("If you would like to do so, please create an account")
    end
  end

  context 'when inviting a new user' do
    let(:mail) { described_class.invite_user('new', email, name, saved_scenario) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Invitation: ETM scenario Some saved scenario')
      expect(mail.to).to eq([email])
      expect(mail.from).to eq(Mail::Field.parse("From: #{Settings.mailer.from}").addresses)
    end

    it 'renders the body' do
      expect(mail.body.raw_source).to include("test@quintel.com just invited you to collaborate on scenario")
      expect(mail.body.raw_source).to include("/saved_scenarios/999")
      expect(mail.body.raw_source).to include("If you would like to do so, please create an account")
    end
  end
end
