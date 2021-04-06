#!/bin/sh

set -e

echo "Environment: $RAILS_ENV"

# Check if we need to install new gems
bundle check || bundle install --jobs 20 --retry 5

# Remove a potentially pre-existing server.pid for Rails.
rm -f $APP_PATH/tmp/pids/server.pid

# Then run any passed command
bundle exec ${@}
