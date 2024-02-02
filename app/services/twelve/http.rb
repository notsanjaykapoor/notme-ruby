# frozen_string_literal: true

require "http"

module Service
  module Twelve
    class Http

      @@http = nil

      def self.instance
        @@http ||= ::HTTP.use(logging: {logger: _logger_null})

        @@http
      end

      def self._logger_null
        ::Logger.new("/dev/null")
      end

    end
  end
end
