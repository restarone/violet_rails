RAILS_ENV=test
PARALLEL_MINITEST=true
echo "RUNNING IN PARALLEL, TTY IS NOT SUPPORTED! byebug/binding.pry will cause hangs!"
docker-compose run --rm solutions_test rails db:environment:set RAILS_ENV=test
echo "Setting: RAILS_ENV=$RAILS_ENV"
docker-compose run --rm -e PARALLEL_MINITEST solutions_test rails db:drop && \
docker-compose run --rm -e PARALLEL_MINITEST solutions_test rails db:create && \
docker-compose run --rm -e PARALLEL_MINITEST solutions_test rails db:migrate && \
docker-compose run --rm -e PARALLEL_MINITEST solutions_test rails test -f --verbose