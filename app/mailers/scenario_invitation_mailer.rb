class ScenarioInvitationMailer < ApplicationMailer
  helper(EmailHelper)

  def invite_user(email, inviter_name, new_role, saved_scenario_details)
    @inviter_name = inviter_name
    @saved_scenario_link = saved_scenario_link(saved_scenario_details[:id])
    @saved_scenario_title = saved_scenario_details[:title]
    @new_role = new_role

    mail(
      to: email,
      from: Settings.mailer.from,
      subject: "#{t('scenario_invitation_mailer.invite_user.subject')} #{@saved_scenario_title}",
      template_name: 'scenario_invitation'
    )
  end

  private

  def saved_scenario_link(saved_scenario_id)
    "#{Settings.etmodel_uri}/saved_scenarios/#{saved_scenario_id}"
  end
end
