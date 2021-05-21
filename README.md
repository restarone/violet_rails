# Welcome to Violet Rails ![Ruby](https://github.com/restarone/violet_rails/workflows/Ruby/badge.svg)
![alt text](https://user-images.githubusercontent.com/35935196/116006240-49867680-a5d8-11eb-82f6-aea6e333942b.png)


## What's Violet Rails?
`violet_rails` is a Ruby on Rails template that implements a web CMS & blog along with a lightweight email client and server. Violet ships with a two tier authorizatiion strategy that makes building SaaS and XaaS products quickly. 
## An opinionated template (built on top of an opinionated framework)

* database multi-tenancy: Serious SaaS and XaaS apps need to support database multi-tenancy. So if you ship Violet with Postgres you will have schema based multi-tenancy with the option of routing each client at run-time to an external Postgres server. All of this is implemented in a simple way, just by subdomain (eg: design.your-website.com).
* Flexible and code first: The Violet CMS is powered  by `comfortable_mexican_sofa` and offers the customizability of a Rails engine with full WSIWYG functionality (its recommended that you stick to HTML/CSS/JS for static web hosting). Outside of this, its just Ruby on Rails -- the world is your oyster.
* Ready to Deploy: Violet comes with a barebones App Owner UI that helps you hit the ground running by managing subdomain requests. Each subdomain has its own roster of Users and an automatically allocated email-box (eg: design@your-website.com), blog (eg: www.your-website.com/blog) and landing page (www.yourwebsite.com). Granular permissioning for users can be managed at the subdomain level.

## Authorization layers
After Violet application deployment, you will be able to connect and setup your cannonical page and user account (from the Rails console)
### 1. App Owners (Violet Sys Admin)
* If you are a domain owner (eg: https://yourdomain.com) you can find the Violet SysAdmin at https://www.yourdomain.com/sysadmin or https://yourdomain.com/sysadmin
* Any subdomain name on your domain can be reserved for web hosting, blog and email functionality. For example, registering https://hello.yourdomain.com will automatically generate a website for https://hello.yourdomain.com , an email address at hello@yourdomain.com, a blog at https://hello.yourdomain.com/blog and a forum at https://hello.yourdomain.com/forum
* All these components can be administrated at https://hello.yourdomain.com/admin with granular user permissions 
### Subdomain Owners (Web Admin)
To register a subdomain, visit https://yourdomain.com/signup_wizard 
For security purposes, this only generates a request-- so the sysadmin will need to approve the subdomain registration at: https://www.yourdomain.com/sysadmin

* If you are the first user in a subdomain, you are conferred maximum permissions

## Deployment
### There are 2 options for deployment. AWS EC2 and Heroku

The [Demo](https://violet.restarone.solutions/) of `violet_rails` is deployed on AWS EC2 (using Ubuntu 20.04LTS) & requires some server setup/automation with Capistrano. The steps are outlined in-detail here: https://github.com/restarone/violet_rails/wiki/Deploying-to-EC2-(Staging-with-Capistrano)

If you prefer deploying to Heroku, [you can view the guide for that here](https://github.com/restarone/violet_rails/wiki/Deploying-to-Heroku)

## Hacking on top of Violet
The local development environment is supported by docker. After installing `docker` and `docker-compose` take a look at the development cheatsheet for setting up the development environment along with useful scripts: https://github.com/restarone/violet_rails/wiki/development-cheatsheet

