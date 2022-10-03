release: bundle exec rails db:migrate
worker: bundle exec sidekiq -C config/sidekiq.yml
web: bundle exec puma -C config/puma.rb