# frozen_string_literal: true

require "faraday"
require "faraday_middleware"

require "fmrest/version"
require "fmrest/v1"
require "fmrest/connection_settings"

module FmRest
  class << self
    attr_accessor :token_store

    def default_connection_settings=(settings)
      @default_connection_settings = ConnectionSettings.wrap(settings, skip_validation: true)
    end

    def default_connection_settings
      @default_connection_settings || ConnectionSettings.new({}, skip_validation: true)
    end

    def config=(connection_hash)
      warn "[DEPRECATION] `FmRest.config=` is deprecated, use `FmRest.default_connection_settings=` instead"
      self.default_connection_settings = connection_hash
    end

    def config
      warn "[DEPRECATION] `FmRest.config` is deprecated, use `FmRest.default_connection_settings` instead"
      default_connection_settings
    end
  end
end
