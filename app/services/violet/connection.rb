# Utitlity class for external API connection plugins
class Violet::Connection
    def get_blob_url(attachment)
        Rails.application.routes.url_helpers.rails_blob_url(attachment, subdomain: Apartment::Tenant.current, host: ENV['APP_HOST'])
    end

    def get_subdomain_email_address
        subdomain = Subdomain.current
        if subdomain.email_name.present?
            "#{subdomain.email_name} <#{subdomain.name}@#{ENV["APP_HOST"]}>"
        else
            "#{subdomain.name}@#{ENV["APP_HOST"]}"
        end
    end
end