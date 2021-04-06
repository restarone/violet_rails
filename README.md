# README
### Dev setup
app should be accessible at: test.lvh.me:3000/










<!-- new -->

# Deploying to EC2
## install app dependencies

```  bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt install curl -y 
sudo apt install nodejs -y && sudo apt install npm -y

sudo apt-get install htop imagemagick build-essential zlib1g-dev openssl libreadline6-dev git-core zlib1g libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf automake libtool bison libgecode-dev -y && sudo apt-get install libpq-dev -y



echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && echo 'eval "$(rbenv init -)"' >> ~/.bashrc
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv && git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
source ~/.bashrc
rbenv install 2.6.6 && rbenv global 2.6.6 && echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc && source ~/.bashrc && gem install bundler:2.1.4 && gem install rails


curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update -y
sudo apt install yarn -y

sudo apt-get install nginx -y
```

## env vars
create these at /var/www/violet/.rbenv-vars
``` bash
RAILS_ENV=staging
DATABASE_HOST=ec2-3-83-199-128.compute-1.amazonaws.com
DATABASE_USERNAME=violet_staging_ubuntu
DATABASE_PASSWORD=xxx
DATABASE_NAME=violet_staging
DATABASE_PORT=5432
APP_HOST=restarone.solutions
RAILS_SERVE_STATIC_FILES=true
SECRET_KEY_BASE=foo
```

## service files
for the server (in /etc/systemd/system/puma.service)
``` bash
[Unit]
Description=violet rails server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/var/www/violet/current
EnvironmentFile=/var/www/violet/.rbenv-vars
ExecStart=/home/ubuntu/.rbenv/bin/rbenv exec bundle exec puma -C /var/www/violet/current/config/puma.rb
ExecStop=/home/ubuntu/.rbenv/bin/rbenv exec bundle exec pumactl -S /var/www/violet/current/config/puma.rb stop
ExecReload=/home/ubuntu/.rbenv/bin/rbenv exec bundle exec pumactl -F /var/www/violet/current/config/puma.rb phased-restart
TimeoutSec=15
Restart=always


[Install]
WantedBy=multi-user.target
```

enable the service by running
``` bash
sudo systemctl daemon-reload
sudo systemctl enable puma.service
sudo systemctl start puma.service
sudo systemctl status puma.service
```

## nginx setup (/etc/nginx/sites-available/restarone.solutions.conf)
setup the server block for restarone.solutions
``` bash
server {
    listen 80;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    client_max_body_size 4G;
}
```
then symlink it and restart nginx
``` bash
sudo ln -s /etc/nginx/sites-available/restarone.solutions.conf /etc/nginx/sites-enabled/restarone.solutions.conf
sudo service nginx configtest
sudo service nginx reload
```
## allow ubuntu to write to /var/www
``` bash
sudo chown -R ubuntu /var/www
```

setup SSL and certbot
``` bash
sudo apt-get install python3-certbot-nginx
sudo certbot --nginx -d restarone.solutions
sudo certbot renew
```
## setup the postgres user
connect to the server
``` bash
psql -h ec2-3-83-199-128.compute-1.amazonaws.com -p 5432 -d postgres -U postgres
```
create the role with permissions
``` SQL
CREATE ROLE violet_staging_ubuntu;
ALTER ROLE  violet_staging_ubuntu  WITH LOGIN;
ALTER USER  violet_staging_ubuntu  CREATEDB;
ALTER USER  violet_staging_ubuntu  WITH PASSWORD 'passwordhere';
```

## make env variables available to the app (for rbenv and rbenv vars)
to load env variables in rails console put this in in ~/.bashrc
``` bash
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$HOME/.rbenv/bin:$PATH"
```

## creating the database
``` bash
psql -h ec2-3-83-199-128.compute-1.amazonaws.com -p 5432 -U violet_staging_ubuntu -d postgres -c 'CREATE DATABASE violet_staging'
```

