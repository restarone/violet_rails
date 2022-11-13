require "test_helper"

class SimpleDiscussion::UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:public)
    @current_subdomain_name = 'public'

    Apartment::Tenant.switch @current_subdomain_name do
      @other_user = User.create!(email: 'contact1@restarone.com', password: '123456', password_confirmation: '123456', confirmed_at: Time.now)
    end

    @user.update(global_admin: true)

    @forum_category = ForumCategory.create!(name: 'test', slug: 'test')
    @forum_thread = @user.forum_threads.new(title: 'Test Thread', forum_category_id: @forum_category.id)
    @forum_thread.save!
  end

  test 'sends email successfully when the forum-post has non-image attachment' do
    file_path = Rails.root.join('test','fixtures', 'files', 'fixture_file.pdf')
    attachment = ActiveStorage::Blob.create_and_upload!(io: File.open(file_path), filename: 'fixture_file', content_type: 'application/pdf', metadata: nil)
    action_txt_content = ActionText::Content.new(%Q(<action-text-attachment sgid="#{attachment.attachable_sgid}"></action-text-attachment>))

    forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @user.id, body: action_txt_content.to_s)

    assert_difference "SimpleDiscussion::UserMailer.deliveries.size", +1 do
      SimpleDiscussion::UserMailer.new_post(forum_post, @other_user).deliver_now
    end

    assert(action_txt_content.to_s, SimpleDiscussion::UserMailer.deliveries.first.body.to_s)
  end

  test 'sends email successfully when the forum-post has image attachment' do
    file_path = Rails.root.join('test','fixtures', 'files', 'fixture_image.png')
    attachment = ActiveStorage::Blob.create_and_upload!(io: File.open(file_path), filename: 'fixture_image', content_type: 'image/png', metadata: nil)
    action_txt_content = ActionText::Content.new(%Q(<action-text-attachment sgid="#{attachment.attachable_sgid}"></action-text-attachment>))

    forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @user.id, body: action_txt_content.to_s)

    assert_difference "SimpleDiscussion::UserMailer.deliveries.size", +1 do
      SimpleDiscussion::UserMailer.new_post(forum_post, @other_user).deliver_now
    end
    assert(action_txt_content.to_s, SimpleDiscussion::UserMailer.deliveries.first.body.to_s)
  end

  test 'Set mailer email to user own email when set in settings' do
    file_path = Rails.root.join('test','fixtures', 'files', 'fixture_image.png')
    attachment = ActiveStorage::Blob.create_and_upload!(io: File.open(file_path), filename: 'fixture_image', content_type: 'image/png', metadata: nil)
    action_txt_content = ActionText::Content.new(%Q(<action-text-attachment sgid="#{attachment.attachable_sgid}"></action-text-attachment>))
    @user.update(name: "Test name")
 
    # Setting email strategy to send notifications using user personal email
    Subdomain.current.user_email!

    forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @user.id, body: action_txt_content.to_s)

    assert_difference "SimpleDiscussion::UserMailer.deliveries.size", +1 do
      SimpleDiscussion::UserMailer.new_post(forum_post, @other_user).deliver_now
    end
    
    mailer_address = SimpleDiscussion::UserMailer.deliveries.last.from.last
    assert_equal mailer_address, forum_post.user.email
  end

  test 'Set mailer email to restarone email when set in settings' do
    file_path = Rails.root.join('test','fixtures', 'files', 'fixture_image.png')
    attachment = ActiveStorage::Blob.create_and_upload!(io: File.open(file_path), filename: 'fixture_image', content_type: 'image/png', metadata: nil)
    action_txt_content = ActionText::Content.new(%Q(<action-text-attachment sgid="#{attachment.attachable_sgid}"></action-text-attachment>))
    @user.update(name: "Test name")
    ENV["APP_HOST"] = "example_mail.com"

    subdomain = Subdomain.current
 
    # Setting email strategy to send notifications using user's restarone/subdomain email
    subdomain.system_email!

    forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @user.id, body: action_txt_content.to_s)

    assert_difference "SimpleDiscussion::UserMailer.deliveries.size", +1 do
      SimpleDiscussion::UserMailer.new_post(forum_post, @other_user).deliver_now
    end
    
    mailer_address = SimpleDiscussion::UserMailer.deliveries.last.from.last
    assert_equal mailer_address, subdomain.mailing_address
  end

  test 'Set mailer email to restarone email when set in settings for new forum thread' do
    @user.update(name: "Test name")
    ENV["APP_HOST"] = "example_mail.com"

    subdomain = Subdomain.current
 
    # Setting email strategy to send notifications using user's restarone/subdomain email
    subdomain.system_email!

    forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @user.id, body: 'Testing email')
    @forum_thread.reload

    assert_difference "SimpleDiscussion::UserMailer.deliveries.size", +1 do
      SimpleDiscussion::UserMailer.new_thread(@forum_thread, @user).deliver_now
    end
    
    mailer_address = SimpleDiscussion::UserMailer.deliveries.last.from.last
    assert_equal mailer_address, subdomain.mailing_address
  end

  test 'Set mailer email to user email when set in settings for new forum thread' do
    @user.update(name: "Test name")
    ENV["APP_HOST"] = "example_mail.com"

    subdomain = Subdomain.current
 
    # Setting email strategy to send notifications using user's own email
    subdomain.user_email!

    forum_post = ForumPost.create!(forum_thread_id: @forum_thread.id, user_id: @user.id, body: 'Testing email')
    @forum_thread.reload

    assert_difference "SimpleDiscussion::UserMailer.deliveries.size", +1 do
      SimpleDiscussion::UserMailer.new_thread(@forum_thread, @user).deliver_now
    end
    
    mailer_address = SimpleDiscussion::UserMailer.deliveries.last.from.last
    assert_equal mailer_address, @user.email
  end

end