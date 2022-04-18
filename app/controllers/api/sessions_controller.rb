class Api::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token
  acts_as_token_authentication_handler_for User, fallback: :none, if: lambda { |controller| controller.request.format.json? }
  def create
    
    self.resource = warden.authenticate!({:scope=>:user, :recall=>"api/sessions#new"})

    sign_in(resource_name, resource)

    yield resource if block_given?

    respond_to do |format|
      format.json do
        data = {
          user_id: resource.id,
          email: resource.email,
          token: resource.authentication_token
        }

        render json: data, status: 201
      end

      format.html do
        respond_with resource, location: after_sign_in_path_for(resource)
      end
    end
  end
end