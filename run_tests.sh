RAILS_ENV=test
echo "Setting: RAILS_ENV=$RAILS_ENV"

docker-compose run --rm -e DISABLE_SPRING=true solutions_test rails test -f --verbose