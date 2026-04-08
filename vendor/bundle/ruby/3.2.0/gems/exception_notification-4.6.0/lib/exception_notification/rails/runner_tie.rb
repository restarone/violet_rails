# frozen_string_literal: true

module ExceptionNotification
  module Rails
    class RunnerTie
      # Registers an at_exit callback, which checks if there was an exception. This is a pretty
      # crude way to detect exceptions from runner commands, but Rails doesn't provide a better API.
      #
      # This should only be called from a runner callback in your Rails config; otherwise you may
      # register the at_exit callback in more places than you need or want it.
      def call
        at_exit do
          exception = $ERROR_INFO
          if exception && !exception.is_a?(SystemExit)
            ExceptionNotifier.notify_exception(exception, data: data_for_exception_notifier(exception))
          end
        end
      end

      private

      def data_for_exception_notifier(exception = nil)
        data = {}
        data[:error_class] = exception.class.name if exception
        data[:error_message] = exception.message if exception

        data
      end
    end
  end
end
