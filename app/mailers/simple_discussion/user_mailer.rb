class SimpleDiscussion::UserMailer < ApplicationMailer
  # You can set the default `from` address in ApplicationMailer

  helper SimpleDiscussion::ForumPostsHelper
  helper SimpleDiscussion::Engine.routes.url_helpers

  def new_thread(forum_thread, recipient)
    @forum_thread = forum_thread
    @forum_post = forum_thread.forum_posts.first
    @recipient = recipient
    mailer_address = Subdomain.current.system_email? ? Subdomain.current.mailing_address : forum_thread.user.email
    mail(
      from: "#{forum_thread.user.name} <#{mailer_address}>",
      to: "#{@recipient.name} <#{@recipient.email}>",
      subject: @forum_thread.title
    )
  end

  def new_post(forum_post, recipient)
    @forum_post = forum_post
    @forum_thread = forum_post.forum_thread
    @recipient = recipient
    mailer_address = Subdomain.current.system_email? ? Subdomain.current.mailing_address : forum_post.user.email
    mail(
      from: "#{forum_post.user.name} <#{mailer_address}>",
      to: "#{@recipient.name} <#{@recipient.email}>",
      subject: "New post in #{@forum_thread.title}"
    )
  end
end
