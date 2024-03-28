class ScenarioInvitationMailerPreview < ActionMailer::Preview
  def invite_user
    ScenarioInvitationMailer.invite_user(
      'someone@example.com',
      'Klaas',
      User::ROLES[2], # collaborator
      { id: 1234, title: 'My first scenario' }
    )
  end
end
