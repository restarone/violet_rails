
Rails.application.reloader.to_prepare do
  class ActiveJob::Base
    include Apartment::ActiveJob
  end
end