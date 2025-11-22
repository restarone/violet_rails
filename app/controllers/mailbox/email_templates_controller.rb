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

  def destroy

  end
end