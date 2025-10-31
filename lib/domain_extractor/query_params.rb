# frozen_string_literal: true

require 'uri'

module DomainExtractor
  # QueryParams transforms URL query strings into Ruby hashes.
  module QueryParams
    EMPTY = {}.freeze

    module_function

    def call(raw_query)
      return EMPTY if raw_query.nil? || raw_query.empty?

      ::URI.decode_www_form(raw_query, Encoding::UTF_8).each_with_object({}) do |(key, value), params|
        next if key.nil? || key.empty?

        params[key] = normalize_value(value)
      end
    rescue ArgumentError
      EMPTY
    end

    def normalize_value(value)
      value.nil? || value.empty? ? nil : value
    end
    private_class_method :normalize_value
  end
end
