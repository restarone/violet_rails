require 'test_helper'
require 'rake'

class PurgeOldApiResourcesTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks if Rake::Task.tasks.empty?

    @api_namespace = api_namespaces(:one)
    @api_namespace.update(purge_resources_older_than: '1.week')

    @api_namespace_2 = api_namespaces(:two)
    @api_namespace_2.update(purge_resources_older_than: '6.months')
  end

  test "purges outdated api resources" do
    ApiResource.create(api_namespace: @api_namespace, created_at: 2.weeks.ago )
    ApiResource.create(api_namespace: @api_namespace, created_at: 8.days.ago )
    ApiResource.create(api_namespace: @api_namespace)

    assert_difference "@api_namespace.reload.api_resources.count", -2 do
      assert_no_difference "@api_namespace_2.reload.api_resources.count" do
        Rake::Task['maintenance:purge_old_api_resources'].invoke
      end
    end

    Rake::Task['maintenance:purge_old_api_resources'].reenable

    travel 5.months

    resources_1_count = @api_namespace.api_resources.count

    assert_operator resources_1_count, :>, 0

    assert_difference "@api_namespace.reload.api_resources.count", -(resources_1_count) do
      assert_no_difference "@api_namespace_2.reload.api_resources.count" do
        Rake::Task['maintenance:purge_old_api_resources'].invoke
      end
    end

    Rake::Task['maintenance:purge_old_api_resources'].reenable

    assert_equal 0, @api_namespace.reload.api_resources.count

    travel 2.months

    resources_2_count = @api_namespace_2.reload.api_resources.count

    assert_operator resources_2_count, :>, 0

    assert_no_difference "@api_namespace.reload.api_resources.count" do
      assert_difference "@api_namespace_2.reload.api_resources.count", -(resources_2_count) do
        Rake::Task['maintenance:purge_old_api_resources'].invoke
      end
    end
    assert_equal 0, @api_namespace_2.reload.api_resources.count
  end
end