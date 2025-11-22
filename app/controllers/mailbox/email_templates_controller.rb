class Mailbox::EmailTemplatesController < Mailbox::BaseController

  def index
    @email_templates = EmailTemplate.all
  end

  def new
  end

  def show
  end

  def create
    html_doc = params[:htmldoc]
    re_doc = params[:redoc]
    name = params[:name]
    email_template = EmailTemplate.create!(html: html_doc, template: re_doc, name: name)

    render json: { id: email_template.id }
  end

  def edit
    @email_template = EmailTemplate.find(params[:id])
  end

  def update
    email_template = EmailTemplate.find(params[:id])
    html_doc = params[:htmldoc]
    re_doc = params[:redoc]
    name = params[:name]
    email_template.update!(html: html_doc, template: re_doc, name: name)

    render json: { id: email_template.id }
  end

  def test_send
    email_template = EmailTemplate.find(params[:id])
    dynamic_segments = email_template.dynamic_segments
    symbol_mapping = ActiveSupport::HashWithIndifferentAccess.new
    dynamic_segments.each do |segment|
      symbol_mapping[segment] = params[segment]
    end

    email_body = email_template.inject_dynamic_segments(symbol_mapping)
    from_address = "#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
    email_subject = "#{email_template.name} test email"
    email_thread = MessageThread.create!(recipients: [current_user.email], subject: email_subject)
    email_message = email_thread.messages.create!(
      content: email_body,
      from: from_address
    )
    EMailer.with(message: email_message, message_thread: email_thread).ship.deliver_later

    flash.notice = "Template test email sent to #{current_user.email}"
    redirect_to edit_mailbox_email_template_path(email_template.id)
  end

  def destroy
    email_template = EmailTemplate.find(params[:id])
    flash.notice = "#{email_template.name} destroyed!"
    email_template.destroy!
    redirect_to mailbox_email_templates_path
  end
end