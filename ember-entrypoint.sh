#!/bin/sh

set -e


bundle exec rake assets:precompile RAILS_ENV=development
echo "Environment: $RAILS_ENV"

cd client 
npm rebuild node-sass


# Then run any passed command
${@}
