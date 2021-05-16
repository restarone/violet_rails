namespace :deploy do
  desc 'custom deployment tasks'


  task :restart do
    on roles(:app) do
      execute "sudo systemctl restart puma.service"
    end
  end
  
  task :restart_sidekiq do
    on roles(:app) do
      execute "sudo systemctl restart sidekiq.service"
    end
  end
end
