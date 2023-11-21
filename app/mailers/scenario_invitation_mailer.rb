class ScenarioInvitationMailer < ApplicationMailer
  def invite_user(user_type, email, inviter_name, saved_scenario_details)
    @inviter_name = inviter_name
    @saved_scenario_id = saved_scenario_details[:id]
    @saved_scenario_title = saved_scenario_details[:title]

    mail(
      to: email,
      from: Settings.mailer.from,
      subject: t("scenario_invitation_mailer.invite_user.subject"),
      template_name: "invite_#{user_type}_user"
    )
  end
end

