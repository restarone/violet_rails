class Mailbox::EmailTemplatesController < Mailbox::BaseController

  def index

  end

  def new
  end

  def show
  end

  def create
    html_doc = params[:htmldoc]
    re_doc = params[:redoc]


    render json: { id: 1 }
  end

  def edit
    html_doc = params[:htmldoc]
    re_doc = params[:redoc]
  end

  def destroy

  end
end