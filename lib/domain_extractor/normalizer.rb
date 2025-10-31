# frozen_string_literal: true

module DomainExtractor
  # Normalizer ensures URLs include a scheme and removes extraneous whitespace
  # before passing them into the URI parser.
  module Normalizer
    # Frozen constants for zero allocation
    SCHEME_PATTERN = %r{\A[A-Za-z][A-Za-z0-9+\-.]*://}
    HTTPS_SCHEME = 'https://'
    HTTP_SCHEME = 'http://'

    module_function

    def call(input)
      return if input.nil?

      string = coerce_to_string(input)
      return if string.empty?

      # Fast path: check if already has http or https scheme
      return string if string.start_with?(HTTPS_SCHEME, HTTP_SCHEME)

      # Check for any scheme
      string.match?(SCHEME_PATTERN) ? string : HTTPS_SCHEME + string
    end

    def coerce_to_string(value)
      value.respond_to?(:to_str) ? value.to_str.strip : value.to_s.strip
    end
    private_class_method :coerce_to_string
  end
end
