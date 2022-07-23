module AhoyEventsHelper
  def event_name_detail(event)
    begin
      if Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['comfy-blog-page-visit']
        blog_post = Comfy::Blog::Post.find(event.properties['comfy_blog_post_id'])

        comfy_blog_post_path(year: blog_post.year, month: blog_post.month, slug: blog_post.slug)
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['comfy-cms-page-update']
        page = Comfy::Cms::Page.find(event.properties['page_id'])
        page_info = page.full_path == '/' ? 'root' : page.full_path

        page_info
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['comfy-cms-page-visit']
        page = Comfy::Cms::Page.find(event.properties['page_id'])
        page_info = page.full_path == '/' ? 'root' : page.full_path

        page_info
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['comfy-cms-file-update']
        file = Comfy::Cms::File.find(event.properties['file_id'])

        file.label
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['subdomain-user-update']
        user = User.find_by(id: event.properties['edited_user_id'])
        return 'User deleted' if user.nil?

        user_info = user.name.present? ? "#{user.name}: #{user.email}" : user.email

        user_info
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['subdomain-email-visit']
        message_thread = MessageThread.find(event.properties['message_thread_id'])

        message_thread.subject
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['subdomain-forum-post-update']
        forum_post = ForumPost.find_by(id: event.properties['forum_post_id'])
        return 'ForumPost deleted' if forum_post.nil?

        forum_post_info = "#{simple_discussion.forum_thread_path(id: forum_post.forum_thread.slug)}#forum_post_#{forum_post.id}"

        forum_post_info
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['subdomain-forum-thread-visit']
        forum_thread = ForumThread.find_by(id: event.properties['forum_thread_id'])
        return 'ForumThread deleted' if forum_thread.nil?

        simple_discussion.forum_thread_path(id: forum_thread.slug)
      elsif Ahoy::Event::SYSTEM_EVENTS[event.name] == Ahoy::Event::SYSTEM_EVENTS['api-resource-create']
        api_resource = ApiResource.find(event.properties['api_resource_id'])

        api_namespace_resource_path(api_namespace_id: api_resource.api_namespace.id ,id: api_resource.id)
      end
    rescue => e
      e.message
    end
  end

end