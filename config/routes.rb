require 'sidekiq/web'
class SubdomainConstraint
  def self.matches?(request)
    # plug in exclusions model here
    restricted_subdomains = []
    !restricted_subdomains.include?(request.subdomain)
  end
end

Rails.application.routes.draw do
  # analytics dashboard
  get 'dashboard', controller: 'comfy/admin/dashboard'
  resources :signup_wizard
  resources :signin_wizard
  constraints SubdomainConstraint do
    devise_for :users, controllers: {
      confirmations: 'users/confirmations',
      #omniauth_callbacks: 'users/omniauth_callbacks',
      registrations: 'users/registrations',
      passwords: 'users/passwords',
      sessions: 'users/sessions',
      unlocks: 'users/unlocks',
      invitations: 'devise/invitations'
    }
  end

  resource :mailbox, only: [:show], controller: 'mailbox/mailbox' do
    resources :message_threads, controller: 'mailbox/message_threads' do
      resources :messages
      member do
        post 'send_message'
      end
    end
  end

  resource :web_settings, controller: 'comfy/admin/web_settings', only: [:edit, :update]
  resources :users, controller: 'comfy/admin/users', as: :admin_users, except: [:create, :show] do
    collection do 
      post 'invite'
    end
  end

  # api admin
  resources :api_namespaces, controller: 'comfy/admin/api_namespaces' do
    resources :resources, controller: 'comfy/admin/api_resources' 
    resources :api_clients, controller: 'comfy/admin/api_clients'
    resources :api_forms, controller: 'comfy/admin/api_forms', only: [:edit, :update]

    resources :resource, controller: 'resource', only: [:create]

    resources :api_actions, controller: 'comfy/admin/api_actions', only: [:index, :show] do
      collection do 
        get 'action_workflow'
      end
    end

    member do
      post 'discard_failed_api_actions'
      post 'rerun_failed_api_actions'
    end
  end
  resources :non_primitive_properties, controller: 'comfy/admin/non_primitive_properties', only: [:new]
  resources :api_actions, controller: 'comfy/admin/api_actions', only: [:new]

  # system admin panel login
  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new', as: :new_global_admin_session
    post 'users/sign_in', to: 'users/sessions#create'
    delete 'global_login', to: 'users/sessions#destroy'
  end
  # system admin panel authentication (ensure public schema as well)
  get 'sysadmin', to: 'admin/subdomain_requests#index'
  namespace :admin do
    authenticate :user, lambda { |u| u.global_admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
    resources :subdomain_requests, except: [:new, :create] do
      member do
        get 'approve'
        get 'disapprove'
      end
    end
    resources :subdomains
  end

  namespace 'api' do
    get '/resources', to: 'resources#index', as: :show_resources
    scope ':version' do
      scope ':api_namespace' do
        get '/', to: 'resource#index'
        get '/show/:api_resource_id', to: 'resource#show', as: :show_resource
        get '/describe', to: 'resource#describe'
        post '/query', to: 'resource#query'
        post '/', to: 'resource#create', as: :create_resource
        patch '/edit/:api_resource_id', to: 'resource#update', as: :update_resource
        delete '/destroy/:api_resource_id', to: 'resource#destroy', as: :destroy_resource
      end
    end
  end

  post '/query', to: 'search#query'

  # catch web client route before it gets hijacked by the server
  mount_ember_app :client, to: "/app"
  
  comfy_route :cms_admin, path: "/admin"
  comfy_route :blog, path: "blog"
  comfy_route :blog_admin, path: "admin"
  mount SimpleDiscussion::Engine => "/forum"
  # cms comes last because its a catch all
  comfy_route :cms, path: "/"
  
  root to: 'content#index'
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
