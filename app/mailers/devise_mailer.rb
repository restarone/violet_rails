class DeviseMailer < Devise::Mailer
  default "Message-ID" => lambda {"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{ENV['APP_HOST']}"}

  def invitation_instructions(record, token, opts = {})
    @resource = record
    @token = token

    mail_settings = {
      to: @resource.email, 
      subject: "Your invitation to #{@resource.subdomain}",
      from: @from,
    }

    mail(mail_settings) do |format|
      format.text { render plain: render_to_string(template: "users/mailer/invitation_instructions") }
      format.html { render html: render_to_string(template: "users/mailer/invitation_instructions").html_safe }
    end
  end
  
end