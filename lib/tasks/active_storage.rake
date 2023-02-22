# https://github.com/rails/rails/blob/main/guides/source/active_storage_overview.md#purging-unattached-uploads
namespace :active_storage do
  desc "Purges unattached Active Storage blobs."

  task purge_unattached: :environment do
    Subdomain.all_with_public_schema.each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        p "** Purging unattached Active Storage blobs for #{subdomain.name}** @ #{Time.now}"
        ActiveStorage::Blob.unattached.where('active_storage_blobs.created_at <= ?', 1.day.ago).find_each(&:purge_later)
      end
    end
  end
end