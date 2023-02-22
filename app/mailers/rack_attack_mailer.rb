class RackAttackMailer < ApplicationMailer
  def limit_exceeded(user)
    @user = user
    mail(
      to: [user.email], 
      subject: I18n.t('rack_attack.mailer.limit_exceeded.subject'),
      content_type: "text/html",
    )
  end
end