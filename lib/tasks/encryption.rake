namespace :encryption do
  desc "tasks for decrypting secrets with old SECRET_KEY_BASE and reencrypting with new key"
  
  task :reencrypt => [:environment] do |t, args|
    Rails.application.eager_load!

    Subdomain.all_with_public_schema.each do |subdomain|
      Apartment::Tenant.switch subdomain.name do
        ActiveRecord::Base.descendants.select { |klass|  klass.respond_to? :encryptables }.each do |klass|
          klass.encryptables&.each do |encrypted_attribute|
            klass.where.not("encrypted_#{encrypted_attribute}".to_sym => nil).in_batches do |records|
              records.each do |record|
                value = EncryptionService.new(record.salt, record.public_send("encrypted_#{encrypted_attribute}".to_sym), ENV["OLD_SECRET_KEY_BASE"]).decrypt
                record.update!("#{encrypted_attribute}".to_sym => value)
              end
            end
          end
        end
      end
    end
  end
end