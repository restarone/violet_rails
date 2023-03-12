require 'test_helper'
require 'rake'

class PurgeUnattachedTaskTest < ActiveSupport::TestCase
  include Rake::DSL

  def setup
    Sidekiq::Testing.fake!

    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test "purges only unattached Active Storage blobs that are older than 1 day" do
    attached_blob = create_attached_blob
    unattached_blob = create_unattached_blob

    # Wait for the unattached blob to be older than 1 day
    travel 2.days

    another_unattached_blob = create_unattached_blob

    perform_enqueued_jobs do
      Rake::Task['active_storage:purge_unattached'].invoke
      Sidekiq::Worker.drain_all
    end

    # purges unattached blob older than 1 day
    assert_not ActiveStorage::Blob.exists?(unattached_blob.id)

    # does not purge attached blob
    assert ActiveStorage::Blob.exists?(attached_blob.id)

    # does not purge unattached blob newer than 1 day
    assert ActiveStorage::Blob.exists?(another_unattached_blob.id)
  end

  private

  def create_attached_blob
    user = users(:public)
    user.avatar.attach(io: File.open(Rails.root.join('test', 'fixtures', 'files', 'fixture_image.png')), filename: 'fixture_image.png', content_type: 'image/png')
    user.avatar.blob
  end

  def create_unattached_blob
    ActiveStorage::Blob.create_after_upload!(io: StringIO.new('unattached blob data'), filename: 'unattached.txt', content_type: 'text/plain')
  end
end