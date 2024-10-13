require "sidekiq/middleware/current_attributes"



if NextRails.next?
  # Do things "the Rails 7 way"
  Rails.application.config.to_prepare do
    # TODO: We need to persist the Current(user, visit) too in a similiar way. But we save user and vist's record in Current.user and Current.Visit which gets converted to string following this approach.
    Sidekiq::CurrentAttributes.persist(ActiveStorage::Current)
  end

else
  # Do things "the Rails 6 way"
  # TODO: We need to persist the Current(user, visit) too in a similiar way. But we save user and vist's record in Current.user and Current.Visit which gets converted to string following this approach.
  Sidekiq::CurrentAttributes.persist(ActiveStorage::Current)
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "#{ENV['APP_HOST']}_#{Rails.env}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "#{ENV['APP_HOST']}_#{Rails.env}" }
end   

Sidekiq.strict_args!