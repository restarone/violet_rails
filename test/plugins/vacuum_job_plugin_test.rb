require "test_helper"

class VacuumJobPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @api_namespace = api_namespaces(:one)
    @vacuum_job_plugin = external_api_clients(:vacuum_job)
  end

  test "#vacuumjob: deletes specified resources succefully" do
    metadata = {
      'ORDER': 'descending',
      'DIMENSION': 'created_at',
      'BATCH_SIZE': '5',
      'API_NAMESPACE_ID': @api_namespace.id,
      'OLDER_THAN': '2880' # 2 days (in minutes)
    }
    @vacuum_job_plugin.update(metadata: metadata)

    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    @api_namespace.api_resources.order(created_at: :desc).limit(3).each { |resource| resource.update_columns(created_at: 5.days.ago) }

    sign_in(@user)

    perform_enqueued_jobs do
      assert_difference 'ApiResource.count', -3 do
        get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @vacuum_job_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_response :redirect

    # Specified resources are deleted
    @api_namespace.reload.api_resources.each do |resource|
      assert (Time.zone.now - resource.created_at).minutes.in_minutes < @vacuum_job_plugin.metadata['OLDER_THAN'].to_f
    end
  end

  test "#vacuumjob: returns error if resource of another api_namespace is attempted to be deleted" do
    metadata = {
      'ORDER': 'descending',
      'DIMENSION': 'created_at',
      'BATCH_SIZE': '5',
      'API_NAMESPACE_ID': '1',
      'OLDER_THAN': '2880' # 2 days (in minutes)
    }
    @vacuum_job_plugin.update(metadata: metadata)

    api_resource = api_resources(:one)

    (1..5).each do
      new_api_resource = api_resource.dup
      new_api_resource.save!
    end

    @api_namespace.api_resources.order(created_at: :desc).limit(3).each { |resource| resource.update_columns(created_at: 5.days.ago) }

    sign_in(@user)

    perform_enqueued_jobs do
      assert_no_difference 'ApiResource.count' do
        get start_api_namespace_external_api_client_path(api_namespace_id: @api_namespace.id, id: @vacuum_job_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    expected_message = "ApiResource of another ApiNamespace cannot be deleted."

    assert_match expected_message, @vacuum_job_plugin.reload.error_message
    assert_response :redirect
  end

end