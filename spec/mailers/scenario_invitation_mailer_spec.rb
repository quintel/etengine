# frozen_string_literal: true

RSpec.describe ScenarioInvitationMailer, type: :mailer do
  let(:email) { 'test@quintel.com' }
  let(:name) { 'Test user' }
  let(:saved_scenario) { { id: 999, title: 'Some saved scenario' } }

  context 'when inviting an existing user' do
    let(:mail) { described_class.invite_user(email, name, :scenario_collaborator, saved_scenario) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Invitation: ETM scenario Some saved scenario')
      expect(mail.to).to eq([email])
      expect(mail.from).to eq(Mail::Field.parse("From: #{Settings.mailer.from}").addresses)
    end

    it 'renders the invitee' do
      expect(mail.to_s).to include("Test user has just invited you")
    end

    it 'renders the link' do
      expect(mail.to_s).to include("/saved_scenarios/999")
    end

    it 'renders the acount' do
      expect(mail.to_s).to include("If you don't have an account yet")
    end
  end
end
