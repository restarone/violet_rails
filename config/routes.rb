require 'sidekiq/web'
class SubdomainConstraint
  def self.matches?(request)
    # plug in exclusions model here
    restricted_subdomains = []
    !restricted_subdomains.include?(request.subdomain)
  end
end

Rails.application.routes.draw do
  get 'cookies', to: 'cookies#index' 
  # analytics dashboard
  get 'dashboard', controller: 'comfy/admin/dashboard'
  get 'dashboard/sessions/:ahoy_visit_id', to: 'comfy/admin/dashboard#visit', as: :dashboard_visits
  get 'dashboard/events/:ahoy_event_type', to: 'comfy/admin/dashboard#events_detail', as: :dashboard_events
  get 'dashboard/events_list', to: 'comfy/admin/dashboard#events_list', as: :dashboard_events_list
  delete 'dashboard/events/:ahoy_event_type/destroy_event', to: 'comfy/admin/dashboard#destroy_event', as: :dashboard_destroy_event
  delete 'dashboard/events/:ahoy_event_type/destroy_visits', to: 'comfy/admin/dashboard#destroy_visits', as: :dashboard_destroy_visits

  post 'import_api_namespace', to: 'comfy/admin/api_namespaces#import_as_json', as: :import_as_json_api_namespaces

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
      invitations: 'users/invitations'
    }
  end

  resource :mailbox, only: [:show], controller: 'mailbox/mailbox' do
    resources :message_threads, controller: 'mailbox/message_threads' do
      resources :messages
      member do
        post 'send_message'
        patch 'add_categories'
      end
    end
  end

  resource :web_settings, controller: 'comfy/admin/web_settings', only: [:edit, :update]
  resources :users, controller: 'comfy/admin/users', as: :admin_users, except: [:create, :show] do
    collection do
      post 'invite'
    end
    member do
      get 'edit/sessions/:ahoy_visit_id', to: 'comfy/admin/dashboard#visit', as: :user_sessions_visit
    end
  end

  # api admin
  resources :api_namespaces, controller: 'comfy/admin/api_namespaces' do
    member do
      post 'duplicate_with_associations'
      post 'duplicate_without_associations'
      get 'export_with_associations_as_json'
      get 'export_without_associations_as_json'
    end

    resources :resources, except: [:index], controller: 'comfy/admin/api_resources'
    resources :api_clients, controller: 'comfy/admin/api_clients'
    resources :external_api_clients, controller: 'comfy/admin/external_api_clients' do
      member do
        get 'start'
        get 'stop'
        get 'clear_errors'
        get 'clear_state'
      end
    end
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
      get 'export'
      get 'export_api_resources'
    end
end
  resources :non_primitive_properties, controller: 'comfy/admin/non_primitive_properties', only: [:new]
  resources :api_actions, controller: 'comfy/admin/api_actions', only: [:new]

  # system admin panel login
  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new', as: :new_global_admin_session
    delete 'global_login', to: 'users/sessions#destroy'
    get 'resend_otp', to: "users/registrations#resend_otp"
  end
  # system admin panel authentication (ensure public schema as well)
  get 'sysadmin', to: 'admin/subdomain_requests#index'
  namespace :admin do
    authenticate :user, lambda { |u| u.global_admin? } do
      mount Sidekiq::Web => '/sidekiq'
      mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
      get 'web_console', to: 'web_console#index'
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

  # ahoy analytics
  mount Ahoy::Engine => "/ahoy", as: :my_ahoy

  # to query CMS pages
  post '/query', to: 'search#query'
  # to query the rest of the system
  post "/graphql", to: "graphql#execute"

  # catch web client route before it gets hijacked by the server
  if RUBY_VERSION != "3.0.0"
    mount_ember_app :client, to: "/app"
  end

  comfy_route :cms_admin, path: "/admin"
  comfy_route :blog, path: "blog"
  comfy_route :blog_admin, path: "admin"
  mount SimpleDiscussion::Engine => "/forum"
  # cms comes last because its a catch all
  comfy_route :cms, path: "/"

  root to: 'content#index'


  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
