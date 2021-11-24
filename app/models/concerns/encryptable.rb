# adding attribute defined by attr_encrypted parameters
# column "encrypted_" attribute name must be created on db
# method attributed will be created as decrypted from column "encrypted_" attribute name
# example attr_encrypted :password will save encrypted password on column encrypted_password
# also create salt if not exist
module Encryptable
    extend ActiveSupport::Concern
    included do
      def build_salt
        self.salt = SecureRandom.random_bytes(
          ActiveSupport::MessageEncryptor.key_len
        )
      end
    end
  
    class_methods do
      def attr_encrypted(*attributes) # rubocop:disable Metrics/AbcSize
        attributes.each do |attribute|
          define_method("#{attribute}=".to_sym) do |value|
            return if value.nil?
  
            build_salt if salt.nil?
  
            public_send(
              "encrypted_#{attribute}=".to_sym,
              EncryptionService.new(salt, value).encrypt
            )
          end
  
          define_method(attribute) do
            value = public_send("encrypted_#{attribute}".to_sym)
            EncryptionService.new(salt, value).decrypt if value.present?
          end
        end
      end
    end
  end