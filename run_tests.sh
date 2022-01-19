RAILS_ENV=test
echo "Setting: RAILS_ENV=$RAILS_ENV"

docker-compose run --rm test rails test -f --verbose