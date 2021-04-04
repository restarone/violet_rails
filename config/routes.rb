class SubdomainConstraint
  def self.matches?(request)
    subdomains = ['www', 'admin', 'help', 'info', 'contact']
    request.subdomain.present? && !subdomains.include?(request.subdomain)
  end
end

Rails.application.routes.draw do
  constraints SubdomainConstraint do
    resources :users
    # default, username password
    comfy_route :cms_admin, path: "/admin"
    comfy_route :cms, path: "/"
  end
  root to: 'content#index'
  resources :customers

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
