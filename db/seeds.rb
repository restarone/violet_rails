require 'faker'
require_relative './violet_seeds/violet.rb'

# set a deterministic seed
Faker::Config.random = Random.new(123)

# admin
user_violet = User.create!(
  email: 'violet@rails.com', 
  name: 'Violet Rails Admin',
  password: '123456', 
  password_confirmation: '123456', 
  global_admin: true, 
  confirmed_at: Time.now
)
user_violet.update!(User::FULL_PERMISSIONS)

Subdomain.unsafe_bootstrap_www_subdomain

# other users
users = []
5.times do
  new_user = User.create!(
    email: Faker::Internet.unique.email, 
    name: Faker::Name.name,
    password: '123456', 
    password_confirmation: '123456', 
    global_admin: false, 
    confirmed_at: Time.now
  )
  new_user.update!(User::FULL_PERMISSIONS)
  users.push new_user
end

# Site
# ----
site = Comfy::Cms::Site.first
site.layouts.find_by(identifier: 'default').update(
  content: "
{{cms:snippet navbar}}
{{cms:wysiwyg content}}
{{cms:snippet footer}}
  ",
  css: VioletSeeds::SITE_CSS
  )

# Assets
# ------

VioletSeeds::ASSETS.each do |asset|
  blob = ActiveStorage::Blob::create_and_upload!(
    io: File.open("#{Rails.root}/db/violet_seeds/assets/#{asset[:filename]}"),
    filename: asset[:filename]
  )
  file = site.files.create!(id: asset[:id], label: asset[:filename], file: blob)
end

# Pages
# -----
page = site.pages.first
page.update(label: 'landing page')
page.fragments.first.update(
  content: VioletSeeds::LANDING_PAGE_CONTENT
  )

# Snippets
# --------
site.snippets.create(
  label: 'navbar', 
  identifier: 'navbar',
  content: VioletSeeds::NAVBAR_CONTENT
)
site.snippets.create(
  label: 'footer', 
  identifier: 'footer',
  content: VioletSeeds::FOOTER_CONTENT
)
  
# Blog posts
# ----------
5.times do
  blog_post = site.blog_posts.create!(
    title: Faker::Marketing.unique.buzzwords,
    layout: site.layouts.find_by(identifier: 'default')
  )
  Comfy::Cms::Fragment.create!(
    identifier: 'content',
    record: blog_post,
    tag: 'wysiwyg',
    content: "
      <p>#{Faker::GreekPhilosophers.quote}</p>
      <p>#{Faker::GreekPhilosophers.quote}</p>
      <p>#{Faker::GreekPhilosophers.quote}</p>
    "
  )
end

# Forum
# -----
ForumCategory.create!(name: Faker::Educator.subject, slug: "cat1", color: "#0000CC")
ForumCategory.create!(name: Faker::Educator.subject, slug: "cat2", color: "#00CCCC")

5.times do
  thread = users.first.forum_threads.create!(title: Faker::Educator.course_name, forum_category: ForumCategory.first)
  post = users.first.forum_posts.create!(forum_thread: thread, body: Faker::GreekPhilosophers.quote)
  post = users.second.forum_posts.create!(forum_thread: thread, body: Faker::GreekPhilosophers.quote)
  post = users.first.forum_posts.create!(forum_thread: thread, body: Faker::GreekPhilosophers.quote)
  post = users.third.forum_posts.create!(forum_thread: thread, body: Faker::GreekPhilosophers.quote)
end

# Emails
# ------
3.times do
  recipients = [Faker::Internet.email, Faker::Internet.email] 
  email_thread = MessageThread.create!(recipients: recipients)
  3.times do
    email_thread.messages.create(content: "
                                 <h5>#{Faker::Movie.quote}</h5>
                                 <p>#{Faker::Movie.quote} <b>#{Faker::Movie.quote}</b></p>
                                 ")
    email_thread.messages.create(content: "<p>#{Faker::Movie.quote} <b>#{Faker::Movie.quote}</b> #{Faker::Movie.quote}</p>",
                                 from: recipients.first)
  end
end

email_thread = MessageThread.create!(recipients: ['violet@rails.com'] )
email_thread.messages.create(content: "I really like your site!", from: 'violet@rails.com')

# Analytics
# ---------
10.times do
  visit = Ahoy::Visit.create!(
    started_at: Time.now,
    ip: Faker::Internet.ip_v4_address, 
    os: 'GNU/Linux', 
    browser: 'Firefox', 
    device_type: 'Desktop', 
    user_agent: Faker::Internet.user_agent, 
    landing_page: 'http://localhost:5250/'
  )
  visit.events.create(name: 'button-click', properties: { target: 'checkbox-one' }, time: Time.now - 5.minutes)
  visit.events.create(name: 'button-click', properties: { target: 'checkbox-two' }, time: Time.now - 4.minutes)
  visit.events.create(name: 'button-click', properties: { target: 'submit' }, time: Time.now - 3.minutes)
end
