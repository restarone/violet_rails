require 'sidekiq/web'
class SubdomainConstraint
  def self.matches?(request)
    subdomains = ['www', 'admin', 'help', 'info', 'contact']
    request.subdomain.present? && !subdomains.include?(request.subdomain)
  end
end

Rails.application.routes.draw do

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
    
    resource :mailbox, only: [:show], controller: 'mailbox/mailbox' do
      resources :message_threads, controller: 'mailbox/message_threads' do
        resources :messages
      end
    end
    resources :users, controller: 'comfy/admin/users', as: :admin_users, except: [:create, :show] do
      collection do 
        post 'invite'
      end
    end
    comfy_route :cms_admin, path: "/admin"
    comfy_route :blog, path: "blog"
    comfy_route :blog_admin, path: "admin"
    comfy_route :cms, path: "/"
  end

  # system admin panel login
  devise_scope :user do
    get 'sign_in', to: 'users/sessions#new', as: :new_global_admin_session
    post 'users/sign_in', to: 'users/sessions#create'
    delete 'global_login', to: 'users/sessions#destroy'
  end
  # system admin panel authentication (ensure public schema as well)
  authenticate :user, lambda { |u| u.global_admin? && Apartment::Tenant.current == 'public' } do
    namespace :admin do
      mount Sidekiq::Web => '/sidekiq'
      resources :subdomain_requests, except: [:new, :create] do
        member do
          get 'approve'
          get 'disapprove'
        end
      end
    end
  end

  root to: 'content#index'
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
