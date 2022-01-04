class EncryptionService
    ENCRYPT_KEY_BASE = Rails.application.secrets.secret_key_base
    KEY_LEN = ActiveSupport::MessageEncryptor.key_len.freeze
  
    delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor
  
    def initialize(salt, value)
      @value = value
  
      key = ActiveSupport::KeyGenerator.new(ENCRYPT_KEY_BASE).generate_key(salt, KEY_LEN)
      @crypt = ActiveSupport::MessageEncryptor.new(key)
    end
  
    def encrypt
      @crypt.encrypt_and_sign(@value)
    end
  
    def decrypt
      @crypt.decrypt_and_verify(@value)
    end
end