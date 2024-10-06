# frozen_string_literal: true

module SolidusStarterFrontend
  module TestingSupport
    # Helper methods to test generators
    module Generators
      # Run given generator in the dummy application
      #
      # @param generator [String] Generator to execute as it would be given in
      # the command line, including possible options
      def run(generator)
        `cd #{root} && bin/rails generate #{generator}`
      end

      private

      def root
        Rails.root
      end
    end
  end
end
