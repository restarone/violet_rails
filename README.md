# Welcome to Violet Rails
## What's Violet Rails?
`violet_rails` is a Ruby on Rails template that implements a web CMS & Blog along with a lightweight Email Client and Server. Violet ships with a two tier authorizatiion strategy that makes building SaaS and XaaS products a breeze. 
## An opinionated template (built on top of an opinionated framework)
* Serious SaaS and XaaS apps need to support database multi-tenancy. So if you ship Violet with Postgres you will have schema based multi-tenancy with the option of routing each client at run-time to an external Postgres server. All of this is implemented in a simple way, just by subdomain (eg: design.your-website.com).
* Flexible and code first. The Violet CMS is powered  by `comfortable_mexican_sofa` and offers the customizability of a Rails engine with full WSIWYG functionality (its recommended you stick to HTML/CSS/JS for static web hosting). Outside of this, its just Ruby on Rails -- the world is your oyster.
* Ready to Deploy. Violet comes with a barebones App Owner UI that helps you hit the ground running by managing subdomain requests. Each subdomain has its own roster of Users and an automatically allocated email-box (eg: design@your-website.com), blog (eg: www.your-website.com/blog) and landing page (www.yourwebsite.com). Granular permissioning for users can be managed at the subdomain level.

## Authorization layer
### App Owners (Violet Owner Admin)
After Violet application deployment
* If you are a domain owner (eg: https://yourdomain.com) you can find the Violet OwnerAdmin at https://www.yourdomain.com/admin 
* For security, the `www` subdomain is protected for use by the internal system. Therefore visiting https://www.yourdomain.com/admin before signing in results in a error, visit https://www.yourdomain.com/sign_in  and login with your owner credentials first.
* Any subdomain name on your domain can be reserved for Web hosting, Blog and Email functionality. For example, registering https://hello.yourdomain.com will automatically generate a website for https://hello.yourdomain.com , an email address at hello@yourdomain.com and a simple blog at https://hello.yourdomain.com/blog
### Subdomain Owners (Web Admin)
After the subdomain request has been granted by the App/Domain owner
* you can find the Violet WebAdmin at https://yoursubdomain.yourdomain.com/admin 
* If you are the first user in a subdomain, you are conferred maximum permissions

## Deployment
To keep costs low, the demo version of `violet_rails` is deployed on EC2 & requires a decent bit of manual setup. Every step is outlined here: https://github.com/restarone/violet_rails/wiki/Deploying-to-EC2-(Staging-with-Capistrano)

## Hacking on top of Violet
The local development env is supported by docker. After installing `docker` and `docker-compose` take a look at the development cheatsheet for setting up the development environment along with useful scripts: https://github.com/restarone/violet_rails/wiki/development-cheatsheet











<!-- new -->

