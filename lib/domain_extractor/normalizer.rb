# frozen_string_literal: true

module DomainExtractor
  # Normalizer ensures URLs include a scheme and removes extraneous whitespace
  # before passing them into the URI parser.
  module Normalizer
    SCHEME_PATTERN = %r{\A[A-Za-z][A-Za-z0-9+\-.]*://}

    module_function

    def call(input)
      return if input.nil?

      string = coerce_to_string(input)
      return if string.empty?

      string.match?(SCHEME_PATTERN) ? string : "https://#{string}"
    end

    def coerce_to_string(value)
      value.respond_to?(:to_str) ? value.to_str.strip : value.to_s.strip
    end
    private_class_method :coerce_to_string
  end
end
