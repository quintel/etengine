class ScenarioInvitationMailerPreview < ActionMailer::Preview
  def invite_user
    ScenarioInvitationMailer.invite_user(
      'someone@example.com',
      'Klaas',
      { id: 1234, title: 'My first scenario' }
    )
  end
end
