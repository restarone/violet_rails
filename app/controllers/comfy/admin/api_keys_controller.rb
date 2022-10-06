class Comfy::Admin::ApiKeysController < Comfy::Admin::Cms::BaseController
  def index
    @api_keys = ApiKey.all
  end
end