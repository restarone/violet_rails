# frozen_string_literal: true

# Copied/adapted from https://github.com/airbrake/airbrake/blob/master/lib/airbrake/rake.rb

Rake::TaskManager.record_task_metadata = true if Rake.const_defined?(:TaskManager)

module ExceptionNotification
  module RakeTaskExtensions
    # A wrapper around the original +#execute+, that catches all errors and
    # passes them on to ExceptionNotifier.
    #
    # rubocop:disable Lint/RescueException
    def execute(args = nil)
      super(args)
    rescue Exception => e
      ExceptionNotifier.notify_exception(e, data: data_for_exception_notifier(e)) unless e.is_a?(SystemExit)
      raise e
    end
    # rubocop:enable Lint/RescueException

    private

    def data_for_exception_notifier(exception = nil)
      data = {}
      data[:error_class] = exception.class.name if exception
      data[:error_message] = exception.message if exception

      data[:rake] = {}
      data[:rake][:rake_command_line] = reconstruct_command_line
      data[:rake][:name] = name
      data[:rake][:timestamp] = timestamp.to_s
      # data[:investigation] = investigation

      data[:rake][:full_comment] = full_comment if full_comment
      data[:rake][:arg_names] = arg_names if arg_names.any?
      data[:rake][:arg_description] = arg_description if arg_description
      data[:rake][:locations] = locations if locations.any?
      data[:rake][:sources] = sources if sources.any?

      if prerequisite_tasks.any?
        data[:rake][:prerequisite_tasks] = prerequisite_tasks.map do |p|
          p.__send__(:data_for_exception_notifier)[:rake]
        end
      end

      data
    end
    # rubocop:enable

    def reconstruct_command_line
      "rake #{ARGV.join(' ')}"
    end
  end
end

module Rake
  class Task
    prepend ExceptionNotification::RakeTaskExtensions
  end
end
