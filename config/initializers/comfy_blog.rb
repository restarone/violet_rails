# frozen_string_literal: true
Rails.application.reloader.to_prepare do
  ComfyBlog.configure do |config|
    # application layout to be used to index blog posts
    config.app_layout = 'comfy/blog/application'

    # Number of posts per page. Default is 10
    #   config.posts_per_page = 10
  end
end
