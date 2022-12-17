require "sidekiq/middleware/current_attributes"

# TODO: We need to persist the Current(user, visit) too in a similiar way. But we save user and vist's record in Current.user and Current.Visit which gets converted to string following this approach.
Sidekiq::CurrentAttributes.persist(ActiveStorage::Current)

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "#{ENV['APP_HOST']}_#{Rails.env}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "#{ENV['APP_HOST']}_#{Rails.env}" }
end   

Sidekiq.strict_args!