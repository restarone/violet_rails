class Comfy::Admin::ApiKeysController < Comfy::Admin::Cms::BaseController
  before_action :set_api_key, only: [:update, :edit, :destroy, :show]

  def index
    @api_keys = ApiKey.all
  end

  def new
    @api_key = ApiKey.new
    @api_key.api_namespace_keys.build
  end

  def edit
  end

  def create
    @api_key = ApiKey.new(api_key_params)

    if @api_key.save
      redirect_to api_key_path(id: @api_key.id), notice: "Api key was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @api_key.update(api_key_params)
      redirect_to api_key_path(id: @api_key.id), notice: "Api key was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_key.destroy
    redirect_to api_keys_path, notice: "Api key was successfully destroyed."
  end

  private

  def set_api_key
    @api_key = ApiKey.find_by(id: params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:label, :authentication_strategy, api_namespace_ids: [])
  end
end