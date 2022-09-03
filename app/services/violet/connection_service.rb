# Utitlity class for external API connection plugins
class Violet::ConnectionService
    def get_blob_url_with_current_subdomain(attachment)
        Rails.application.routes.url_helpers.rails_blob_url(attachment, subdomain: Apartment::Tenant.current, host: ENV['APP_HOST'])
    end

    def get_current_subdomain_formatted_email
        subdomain = Subdomain.current
        if subdomain.email_name.present?
            "#{subdomain.email_name} <#{subdomain.name}@#{ENV["APP_HOST"]}>"
        else
            "#{subdomain.name}@#{ENV["APP_HOST"]}"
        end
    end
end