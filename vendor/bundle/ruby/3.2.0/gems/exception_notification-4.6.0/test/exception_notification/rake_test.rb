# frozen_string_literal: true

require 'test_helper'

require 'rake'
require 'exception_notification/rake'

class RakeTest < ActiveSupport::TestCase
  setup do
    Rake::Task.define_task :dependency_1 do
      puts :dependency_1
    end
    Rake::Task.define_task raise_exception: :dependency_1 do
      raise 'test exception'
    end
    @task = Rake::Task[:raise_exception]
  end

  test 'notifies of exception' do
    ExceptionNotifier.expects(:notify_exception).with do |ex, opts|
      data = opts[:data]
      ex.is_a?(RuntimeError) &&
        ex.message == 'test exception' &&
        data[:error_class] == 'RuntimeError' &&
        data[:error_message] == 'test exception' &&
        data[:rake][:rake_command_line] == 'rake ' &&
        data[:rake][:name] == 'raise_exception' &&
        data[:rake][:timestamp] &&
        data[:rake][:sources] == ['dependency_1'] &&
        data[:rake][:prerequisite_tasks][0][:name] == 'dependency_1'
    end

    # The original error is re-raised
    assert_raises(RuntimeError) do
      @task.invoke
    end
  end
end
