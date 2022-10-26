module Webhook
  module VerificationMethod
    class Custom
      attr_accessor :request, :verification_method

      def initialize(request, verification_method)
        @request = request
        @verification_method = verification_method
      end

      def call
        # TODO: validate that this method always returns array with verification status and message
        # eg: [true, 'verification success']
        eval(@verification_method.custom_method_defination)
      end
    end
  end
end