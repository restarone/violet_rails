# ex; 
# modmed = ExternalApiClient.find_by(slug: ExternalApiClient::CLIENTS[:modmed][:name])
# supervisor = modmed.run 
# returns => External::ApiClients::Modmed instance so you can for eg:
# supervisor.authenticate
class External::ApiClients::Modmed
  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
    @metadata = @external_api_client.get_metadata
    @clinic_id = @metadata[:clinic_id]
    @auth_root = @metadata[:auth_base_url]
  end

  def start
    self.reset_retries_after_success
    return true
  end

  def log
    return true
  end

  def authenticate
    # returns
    # "{\"scope\":\"dermpmsandbox277\",\"token_type\":\"Bearer\",\"access_token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJmaGlyX2lSSEdZIiwicG9sICAgICAgICAiOiJjaGFuZ2VtZSIsInVybFByZWZpeCI6ImRlcm1wbXNhbmRib3gyNzciLCJ2ZW5kb3IiOiJmaGlyX2lSSEdZQGRlcm1wbXNhbmRib3gyNzciLCJpc3MiOiJtb2RtZWQiLCJ0b2tlblR5cGUiOiJhY2Nlc3MiLCJqdGkiOiIyNTVmNTA3Y2JiMzE0MTNmODA3NmU0NTY1MmU1MjE2ZSJ9.edemcIlcVZBCijO92pTodHoLtTbcfkXiUbMmSOQ57_8\",\"refresh_token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJmaGlyX2lSSEdZIiwidXJsUHJlZml4IjoiZGVybXBtc2FuZGJveDI3NyIsImlzcyI6Im1vZG1lZCIsInRva2VuVHlwZSI6InJlZnJlc2giLCJqdGkiOiI5OWFhNjQyOWM2ZjY0MTRhOGI4MzA4YzNhYmVkOGM5NSJ9.nPUaFhAs82rQWeV_mJP3_qOHn6VMmqPoGWCG1SwfXaI\"}"
    endpoint = "#{@auth_root}/ema-dev/firm/#{@clinic_id}/ema/ws/oauth2/grant"
    payload = {    
      "grant_type": @metadata[:grant_type],
      "username": @metadata[:username],
      "password": @metadata[:password],
    }
    response = HTTParty.post(endpoint,
      body: URI.encode_www_form(payload), 
      headers: { 
        'Content-Type': 'application/x-www-form-urlencoded',
        'x-api-key' => @metadata[:api_key]
      }
    ).body
    response_obj = JSON.parse(response).deep_symbolize_keys
    external_api_client_meta = @external_api_client.get_metadata
    external_api_client_meta[:bearer_token] = response_obj[:access_token]
    @external_api_client.set_metadata(external_api_client_meta)
  end

  def reset_retries_after_success
    @external_api_client.update(retries: 0)
  end
end