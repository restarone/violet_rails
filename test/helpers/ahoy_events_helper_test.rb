require 'test_helper'

class AhoyEventsHelperTest < ActionView::TestCase
  test 'returns blog_post url_path as event_name_detail for events with name: comfy-blog-page-visit' do
    site = Comfy::Cms::Site.first
    layout = site.layouts.create!(
      label: 'blog',
      identifier: 'blog'
    )

    blog_post = site.blog_posts.create!(
      layout: layout,
      title: 'foo',
      slug: 'foo',
      year: Time.zone.now.year,
      month: Time.zone.now.month,
      published_at: Time.zone.now
    )

    expected_output = comfy_blog_post_path(year: blog_post.year, month: blog_post.month, slug: blog_post.slug)

    event = Ahoy::Visit.last.events.create!(
      name: 'comfy-blog-page-visit',
      time: Time.zone.now,
      properties: { comfy_blog_post_id: blog_post.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns page full_path as event_name_detail for events with name: comfy-cms-page-update' do
    site = Comfy::Cms::Site.first
    layout = site.layouts.create!(
      label: 'blog',
      identifier: 'blog'
    )
    page = layout.pages.create!(
      site: site,
      label: 'page',
      slug: 'page'
    )

    expected_output = page.full_path

    event = Ahoy::Visit.last.events.create!(
      name: 'comfy-cms-page-update',
      time: Time.zone.now,
      properties: { page_id: page.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns root as event_name_detail for events with name: comfy-cms-page-update if the page.full_path is "/"' do
    site = Comfy::Cms::Site.first
    layout = site.layouts.create!(
      label: 'blog',
      identifier: 'blog'
    )
    page = layout.pages.create!(
      site: site,
      label: 'page',
      slug: 'page',
      full_path: '/'
    )
    page.update_column(:full_path, '/')

    expected_output = 'root'

    event = Ahoy::Visit.last.events.create!(
      name: 'comfy-cms-page-update',
      time: Time.zone.now,
      properties: { page_id: page.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns page full_path as event_name_detail for events with name: comfy-cms-page-visit' do
    site = Comfy::Cms::Site.first
    layout = site.layouts.create!(
      label: 'blog',
      identifier: 'blog'
    )
    page = layout.pages.create!(
      site: site,
      label: 'page',
      slug: 'page'
    )

    expected_output = page.full_path

    event = Ahoy::Visit.last.events.create!(
      name: 'comfy-cms-page-visit',
      time: Time.zone.now,
      properties: { page_id: page.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns root as event_name_detail for events with name: comfy-cms-page-visit if the page.full_path is "/"' do
    site = Comfy::Cms::Site.first
    layout = site.layouts.create!(
      label: 'blog',
      identifier: 'blog'
    )
    page = layout.pages.create!(
      site: site,
      label: 'page',
      slug: 'page',
      full_path: '/'
    )
    page.update_column(:full_path, '/')

    expected_output = 'root'

    event = Ahoy::Visit.last.events.create!(
      name: 'comfy-cms-page-visit',
      time: Time.zone.now,
      properties: { page_id: page.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns file label as event_name_detail for events with name: comfy-cms-file-update' do
    site = Comfy::Cms::Site.first
    file = site.files.create(
      label:        "test",
      description:  "test file",
      file:         fixture_file_upload("fixture_image.png", "image/jpeg")
    )

    expected_output = file.label

    event = Ahoy::Visit.last.events.create!(
      name: 'comfy-cms-file-update',
      time: Time.zone.now,
      properties: { file_id: file.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns user email as event_name_detail for events with name: subdomain-user-update' do
    user = User.first

    expected_output = user.email

    event = Ahoy::Visit.last.events.create!(
      name: 'subdomain-user-update',
      time: Time.zone.now,
      properties: { edited_user_id: user.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns "User deleted" as event_name_detail for events with name: subdomain-user-update if the user has been deleted' do
    user = User.first

    event = Ahoy::Visit.last.events.create!(
      name: 'subdomain-user-update',
      time: Time.zone.now,
      properties: { edited_user_id: user.id }
    )

    user.destroy
    expected_output = 'User deleted'
    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns email subject as event_name_detail for events with name: subdomain-email-visit' do
    email = message_threads(:public)

    expected_output = email.subject

    event = Ahoy::Visit.last.events.create!(
      name: 'subdomain-email-visit',
      time: Time.zone.now,
      properties: { message_thread_id: email.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns forum_post_path with updated_forum_post id as event_name_detail for events with name: subdomain-forum-post-update' do
    category = ForumCategory.create!(name: 'test', slug: 'test')
    user = User.first
    forum_thread = user.forum_threads.create!(title: 'Test Thread', forum_category_id: category.id)
    forum_post = ForumPost.create!(forum_thread_id: forum_thread.id, user_id: user.id, body: 'test body')

    expected_output = "#{simple_discussion.forum_thread_path(id: forum_post.forum_thread.slug)}#forum_post_#{forum_post.id}"

    event = Ahoy::Visit.last.events.create!(
      name: 'subdomain-forum-post-update',
      time: Time.zone.now,
      properties: { forum_post_id: forum_post.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns forum_thread_path as event_name_detail for events with name: subdomain-forum-thread-visit' do
    category = ForumCategory.create!(name: 'test', slug: 'test')
    user = User.first
    forum_thread = user.forum_threads.create!(title: 'Test Thread', forum_category_id: category.id)

    expected_output = simple_discussion.forum_thread_path(id: forum_thread.slug)

    event = Ahoy::Visit.last.events.create!(
      name: 'subdomain-forum-thread-visit',
      time: Time.zone.now,
      properties: { forum_thread_id: forum_thread.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end

  test 'returns nil with event_name_detail for events with non-system defined event names' do
    event = Ahoy::Visit.last.events.create!(
      name: 'test-event',
      time: Time.zone.now
    )

    assert_nil event_name_detail(event)
  end

  test 'returns error_message as event_name_detail for events having irregular properties detail' do
    category = ForumCategory.create!(name: 'test', slug: 'test')
    user = User.first
    forum_thread = user.forum_threads.create!(title: 'Test Thread', forum_category_id: category.id)

    pattern = /Couldn\'t find .* without an ID/

    event = Ahoy::Visit.last.events.create!(
      name: 'subdomain-forum-thread-visit',
      time: Time.zone.now,
      properties: { test_id: forum_thread.id } # not setting required property key: forum_thread_id
    )

    assert_match pattern, event_name_detail(event)
  end

  test 'returns api_resource_path' do
    api_resource = api_resources(:one)

    expected_output = api_namespace_resource_path(api_namespace_id: api_resource.api_namespace.id ,id: api_resource.id)

    event = Ahoy::Visit.last.events.create!(
      name: 'api-resource-create',
      time: Time.zone.now,
      properties: { api_resource_id: api_resource.id }
    )

    assert_equal expected_output, event_name_detail(event)
  end
end