## Step to execute
echo "Migration: START"
bundle exec rails db:migrate
echo "Migration: END"

initial_deploy_flag=$(heroku config:get INITIAL_DEPLOY_FLAG)

if [$initial_deploy_flag == false]
then
  bundle exec rails db:seed
  echo "HERE!!!!"
  $(heroku config:set INITIAL_DEPLOY_FLAG=true)
  echo "Updates!!!!"
fi
