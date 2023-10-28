Rails.application.config.to_prepare do
  RailsAdmin::ApplicationController.class_eval do
    before_action :switch_tenant
  
    def switch_tenant
      Apartment::Tenant.switch!(Apartment::Tenant.current)
    end
  
    # def reload_rails_admin
    #   Rails.application.eager_load!
    #   excluded_models = ApplicationRecord.descendants.map { |m| m.name unless m.base_class.table_exists? }.compact
    #   puts "Excluded models: #{excluded_models}"
  
    #   RailsAdmin::Config.reset
    #   RailsAdmin.config do |config|
    #     config.excluded_models = excluded_models
  
    #     config.actions do
    #       dashboard
    #       index
    #       new
    #       export
    #       bulk_delete
    #       show
    #       edit
    #       delete
    #       show_in_app
    #     end
    #   end
    # end
  
  end
end

