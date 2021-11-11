class Comfy::Admin::ApiFormsController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_web
  before_action :set_api_namespace

  before_action :set_api_form, only: %i[show edit update]

  def edit
  end

  def update
    respond_to do |format|
      if @api_form.update(api_form_params)
        format.html { redirect_to api_namespace_path(id: @api_namespace.slug), notice: "Api Form was successfully updated." }
        format.json { render :show, status: :ok, location: @api_form }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @api_form.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_api_namespace
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
  end

  def set_api_form
    @api_form = ApiForm.find(params[:id])
  end

  def api_form_params
    params.require(:api_form).permit(:api_namespace_id, :show_recaptcha, :submit_button_label, :title, :success_message, :failure_message, properties: {}).merge({api_namespace_id: @api_namespace.id})
  end
end