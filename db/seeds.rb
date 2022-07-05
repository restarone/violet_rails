require_relative './violet_seeds/violet.rb'

# This user gets created for all tenants
user = User.create!(
  email: 'violet@rails.com', 
  password: '123456', 
  password_confirmation: '123456', 
  global_admin: true, 
  confirmed_at: Time.now
)
user.update!(User::FULL_PERMISSIONS)

# seeds.rb gets run for each tenant, so we must make sure to run
# Subdomain.create only once here.
if Apartment::Tenant.current == 'public'
  Subdomain.unsafe_bootstrap_www_subdomain
  Subdomain.create!(name: 'violet')
end

if Apartment::Tenant.current == 'violet'
  user_orange = User.create!(
    email: 'orange@rails.com', 
    name: 'Orange Tester',
    password: '123456', 
    password_confirmation: '123456', 
    global_admin: false, 
    confirmed_at: Time.now
  )
  user_orange.update!(User::FULL_PERMISSIONS)

  user_red = User.create!(
    email: 'red@rails.com', 
    name: 'Red Tester',
    password: '123456', 
    password_confirmation: '123456', 
    global_admin: false, 
    confirmed_at: Time.now
  )
  user_red.update!(User::FULL_PERMISSIONS)

  user_blue = User.create!(
    email: 'blue@rails.com', 
    name: 'Blue Tester',
    password: '123456', 
    password_confirmation: '123456', 
    global_admin: false, 
    confirmed_at: Time.now
  )
  user_blue.update!(User::FULL_PERMISSIONS)

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
  blog_post = site.blog_posts.create!(
    title: "My first post",
    layout: site.layouts.find_by(identifier: 'default')
  )
  Comfy::Cms::Fragment.create!(
    identifier: 'content',
    record: blog_post,
    tag: 'wysiwyg',
    content: "
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quae duo sunt, unum facit. Uterque enim summo bono fruitur,
      id est voluptate. Magna laus. Eam stabilem appellas. Duo Reges: constructio interrete. Negat esse eam, inquit, propter
      se expetendam. Hunc vos beatum; Qualem igitur hominem natura inchoavit? </p>

      <p>Laboro autem non sine causa; Memini vero, inquam; Bonum incolumis acies: misera caecitas. </p>

      <p>In schola desinis. De quibus cupio scire quid sentias. </p>
    "
  )

  # Forum
  # -----
  ForumCategory.create!(name: "cats", slug: "cats2", color: "#0000CC")
  ForumCategory.create!(name: "dogs", slug: "dogs2", color: "#00CCCC")

  thread = user.forum_threads.create!(title: "Cats are great?", forum_category: ForumCategory.first)
  post = user.forum_posts.create!(forum_thread: thread, body: "I Think they are awesome!")
  post = user_orange.forum_posts.create!(forum_thread: thread, body: "I Think they are not so good!")
  # TODO attachments

  # Emails
  # ------
  email_thread = MessageThread.create!(recipients: ['violet@rails.com', 'red@rails.com'] )
  email_thread.messages.create(content: "An invitation to a meeting. Please come here at 4pm on Friday.")
  email_thread.messages.create(content: "I will be there", from: 'violet@rails.com')
  email_thread.messages.create(content: "Have to skip this one.", from: 'red@rails.com')

  email_thread = MessageThread.create!(recipients: ['violet@rails.com'] )
  email_thread.messages.create(content: "I really like your site!", from: 'violet@rails.com')

  # Analytics
  # ---------
  visit = Ahoy::Visit.create!(
    started_at: Time.now,
    ip: '200.200.200.200', 
    os: 'GNU/Linux', 
    browser: 'Firefox', 
    device_type: 'Desktop', 
    user_agent: 'Mozilla/5.0 (X11; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0', 
    landing_page: 'http://violet.localhost:5250/'
  )
  visit.events.create(name: 'button-click', properties: { target: 'checkbox-one' }, time: Time.now - 5.minutes)
  visit.events.create(name: 'button-click', properties: { target: 'checkbox-two' }, time: Time.now - 4.minutes)
  visit.events.create(name: 'button-click', properties: { target: 'submit' }, time: Time.now - 3.minutes)
end
