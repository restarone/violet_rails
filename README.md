![violet-logo-horizontal-with-wordmark](https://user-images.githubusercontent.com/35935196/121615020-efc5f880-ca2d-11eb-9e0c-08e2c7926b3a.png)
------
![Ruby/Node.js Build](https://github.com/restarone/violet_rails/workflows/Ruby/badge.svg)
[![Brakeman Scan](https://github.com/restarone/violet_rails/actions/workflows/brakeman-analysis.yml/badge.svg)](https://github.com/restarone/violet_rails/actions/workflows/brakeman-analysis.yml)
[![Heroku Deployments](https://github.com/restarone/violet_rails/actions/workflows/heroku-deploy.yml/badge.svg)](https://github.com/restarone/violet_rails/actions/workflows/heroku-deploy.yml)
[![AWS EC2 Deployments](https://github.com/restarone/violet_rails/actions/workflows/deploy.yml/badge.svg)](https://github.com/restarone/violet_rails/actions/workflows/deploy.yml)
## The Ultimate Rails-based, Web and Automation Platform 🌐 

Built for your digital needs, trusted by startups and founders 🚀

Violet enables subdomain based:

- 📧 Email
- ✍️ Blog
- ℹ️ Forum 
- 📊 Analytics 
- 🦾 Automation 
- 🤝 Collaboration  

So you can have your marketing site hosted on `www.mywebsite.com`, while recieving support requests under `support@mywebsite.com` and building the Next Big Thing®️™️ at `app.mywebsite.com`-- all powered by Violet Rails.

Feel the power & productivity of the Majestic Monolith! 🐘

## Architecture overview

![Document systems-2](https://user-images.githubusercontent.com/35935196/179869983-2ab95b29-ce67-4835-b649-7ac33a0eef39.png)



## Features ✨
### ✨ **A powerful website builder** 🌍
Powered by a rich Content Management System with out of the box support for Bootstrap 4 and jQuery, you can edit HTML templates either with a content first or markup first approach. Create both public and private web pages with ease. 
![Screenshot from 2021-05-21 17-21-45](https://user-images.githubusercontent.com/35935196/119199494-288b3700-ba59-11eb-8f6b-b97255ab3273.png)
***
#### Examples of inspirational websites built with Violet Rails 🚀

1. Coffee Oysters Champagne: https://www.sipshucksip.com
2. Marked Restaurant: http://markedrestaurant.com
3. a toi: https://a-toi.ca
***

### ✨ **A flexible app, automation and analytics platform** 🦾
Build apps and automation with Violet Rails API Namespace: https://github.com/restarone/violet_rails/wiki/API:-Entities,-Form-Rendering,-Interfaces-and-Actions
#### **Building forms** 📜
Build spam-resistant forms with Google Recaptcha v2 or v3. Since all systems in Violet Rails are vertically intergrated, your forms can talk to your automations and analytics. 
<img width="1728" alt="Screen Shot 2022-06-26 at 5 59 10 PM" src="https://user-images.githubusercontent.com/35935196/175835386-4dca9672-425b-4be0-b415-f488470d22c8.png">
#### **Automation** 🤖
Build custom automation (eg mailchimp: https://github.com/restarone/violet_rails/issues/720) with ease with Ruby code or our HTTP API Editor (https://github.com/restarone/violet_rails/wiki/API:-Entities,-Form-Rendering,-Interfaces-and-Actions#http-api-editor-example-discord-bot)

#### **Analytics** 📈
Easily build funnels and data analytics systems with Violet Rails Data pipeline. 
<img width="1728" alt="Screen Shot 2022-06-26 at 6 08 34 PM" src="https://user-images.githubusercontent.com/35935196/175835577-3752a1f1-8c00-4b41-93c1-50878d04bdf6.png">
<img width="1728" alt="Screen Shot 2022-06-26 at 6 08 46 PM" src="https://user-images.githubusercontent.com/35935196/175835586-c75a5f16-0113-4141-8057-2269c5e48255.png">

#### ✨ **Native iOS support** 📱 🍎
Every Violet Rails app transition seamlessly between web (left) and iOS (right)
<img width="1728" alt="Screen Shot 2022-06-26 at 1 46 32 PM" src="https://user-images.githubusercontent.com/35935196/175827355-b7d7e41b-c116-4d22-b9c2-226bd9ca0dad.png">

iOS repository: https://github.com/restarone/violet_rails_ios_client


#### Examples of inspirational ✨ apps 🗺️ built with Violet Rails 🚀

1. Nikean Foundation: https://www.nikean.org
2. Restarone Solutions Tech Support: https://support.restarone.solutions
3. Restarone Software Solutions: https://restarone.com
4. Marked Restaurant: http://markedrestaurant.com
5. Opportunities at Restarone: http://contractors.restarone.solutions

***

### ✨ **Rich user management system with invites and granular permissions** 🧑‍🤝‍🧑
Allow your outreach team to support the forum and blog, while the designers and developers work on the web pages. 
![Screenshot from 2021-05-21 17-25-15](https://user-images.githubusercontent.com/35935196/119199693-86b81a00-ba59-11eb-8543-96df36b44968.png)

### ✨ **Simplest Email Service** 📧
Each Violet Rails 
subdomain will have access to its own emailbox for sending and recieving emails:
<img width="1728" alt="Screen Shot 2022-06-26 at 5 55 10 PM" src="https://user-images.githubusercontent.com/35935196/175835219-831a78f9-809f-4b9e-a99e-d3406983cf7b.png">

### ✨ **Forum** 🤝
Full fledged community support with moderators and user permissions
<img width="1728" alt="Screen Shot 2022-06-26 at 6 16 51 PM" src="https://user-images.githubusercontent.com/35935196/175835826-ffa7f1c7-6bcc-416a-9dab-915bc90697a9.png">



### ✨ **Blog** ✍️
Blogging, everyone needs it right?
![Screenshot from 2021-05-21 17-31-21](https://user-images.githubusercontent.com/35935196/119200274-997f1e80-ba5a-11eb-917c-c8cf64a28a10.png)

### ✨ **Two-tier admin system** 📋
Domain admins have control over which subdomains can be created (via approval) and destroyed. Subdomain admins have full control over their subdomain only.
![Screenshot from 2021-05-23 14-04-06](https://user-images.githubusercontent.com/35935196/119271643-65c60500-bbd0-11eb-8f1e-28367c4d62ff.png)

## ✨ **Sensible architecture and safe defaults**

* database multi-tenancy: Serious SaaS and XaaS apps need to support database multi-tenancy. So if you ship Violet with Postgres you will have schema based multi-tenancy with the option of routing each client at run-time to an external Postgres server. All of this is implemented in a simple way, just by subdomain (eg: design.your-website.com).
* Flexible and code first: The Violet CMS is powered  by `comfortable_mexican_sofa` and offers the customizability of a Rails engine with full WSIWYG functionality (its recommended that you stick to HTML/CSS/JS for static web hosting). Outside of this, its just Ruby on Rails -- the world is your oyster.
* Ready to Deploy: Violet comes with a barebones App Owner UI that helps you hit the ground running by managing subdomain requests. Each subdomain has its own roster of Users and an automatically allocated email-box (eg: design@your-website.com), blog (eg: www.your-website.com/blog) and landing page (www.yourwebsite.com). Granular permissioning for users can be managed at the subdomain level.

## ✨ **Authorization layers**
After deploying violet, you will be able to connect and setup your cannonical page and user account from the Rails console
### 1. App Owners (Violet Sys Admin)
* If you are a domain owner (eg: https://yourdomain.com) you can find the Violet SysAdmin at https://www.yourdomain.com/sysadmin or https://yourdomain.com/sysadmin
* Any subdomain name on your domain can be reserved for web hosting, blog and email functionality. For example, registering https://hello.yourdomain.com will automatically generate a website for https://hello.yourdomain.com , an email address at hello@yourdomain.com, a blog at https://hello.yourdomain.com/blog and a forum at https://hello.yourdomain.com/forum
* All these components can be administrated at https://hello.yourdomain.com/admin with granular user permissions 
### Subdomain Owners (Web Admin)
To register a subdomain, visit https://yourdomain.com/signup_wizard 
For security purposes, this only generates a request-- so the sysadmin will need to approve the subdomain registration at: https://www.yourdomain.com/sysadmin

* If you are the first user in a subdomain, you are conferred maximum permissions

## Deployment 🚀
### There are 2 options for deployment. AWS EC2 and Heroku

The [Demo](https://violet.restarone.solutions/) of `violet_rails` is deployed on AWS EC2 (using Ubuntu 20.04LTS) & requires some server setup/automation with Capistrano. The steps are outlined in-detail here: https://github.com/restarone/violet_rails/wiki/Deploying-to-EC2-(with-Capistrano)

If you prefer deploying to Heroku, [you can view the guide for that here](https://github.com/restarone/violet_rails/wiki/Deploying-to-Heroku)

## Want to build on top of Violet Rails?
The local development environment is supported by docker. After installing `docker` and `docker-compose` take a look at the development cheatsheet for setting up the development environment along with useful scripts: https://github.com/restarone/violet_rails/wiki/Getting-started-(development-cheatsheet)

