class External::ApiClients::Modmed

  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
    @metadata = @external_api_client.get_metadata
    @clinic_id = @metadata[:clinic_id]
    @auth_root = @metadata[:auth_base_url]
  end

  def start
    return true
  end

  def log
    return true
  end

  def authenticate
    endpoint = "#{@auth_root}/ema-dev/firm/#{@clinic_id}/ema/ws/oauth2/grant"

  end
end