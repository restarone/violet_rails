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
      invitations: 'users/invitations'
    }
    resources :users, controller: 'comfy/admin/users'
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

  root to: 'content#index'
  

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
