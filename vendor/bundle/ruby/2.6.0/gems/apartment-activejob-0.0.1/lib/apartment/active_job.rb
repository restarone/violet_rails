module Apartment
  module ActiveJob
    extend ActiveSupport::Concern

    class_methods do
      def execute(job_data)
        Apartment::Tenant.switch(job_data['tenant']) do
          super
        end
      end
    end

    def serialize
      super.merge('tenant' => Apartment::Tenant.current)
    end
  end
end
