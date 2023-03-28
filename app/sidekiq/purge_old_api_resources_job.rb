class PurgeOldApiResourcesJob
  include Sidekiq::Job

  def perform(api_namespace_id)
    api_namespace = ApiNamespace.find_by(id: api_namespace_id)
    api_namespace&.destroy_old_api_resources_in_batches
  end
end