class RackAttackMailer < ApplicationMailer
  def limit_exceeded(user, error_limit_exceeded = false)
    @user = user
    @error_limit_exceeded = error_limit_exceeded
    mail(
      to: [user.email], 
      subject: I18n.t("rack_attack.mailer.limit_exceeded.subject.#{@error_limit_exceeded ? 'error_limit_exceeded' : 'request_limit_exceeded'}"),
      content_type: "text/html",
    )
  end
end