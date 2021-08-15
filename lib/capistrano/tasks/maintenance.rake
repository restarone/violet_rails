namespace :maintenance do
  task :update_cron do
    on roles(:app) do
      within current_path do
        execute "crontab -r || exit 0"
        execute "whenever --update-crontab"
      end
    end
  end
end
