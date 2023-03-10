# frozen_string_literal: true
require "rack-mini-profiler"

# initialization is skipped so trigger it
Rack::MiniProfilerRails.initialize!(Rails.application)
Rack::MiniProfiler.config.position = 'bottom-right'
Rack::MiniProfiler.config.authorization_mode = :allow_authorized
Rack::MiniProfiler.config.enable_hotwire_turbo_drive_support = true