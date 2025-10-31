# frozen_string_literal: true

module DomainExtractor
  # Validators hosts fast checks for excluding unsupported hostnames (e.g. IP addresses).
  module Validators
    # Frozen regex patterns for zero allocation
    IPV4_SEGMENT = '(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)'
    IPV4_REGEX = /\A#{IPV4_SEGMENT}(?:\.#{IPV4_SEGMENT}){3}\z/
    IPV6_REGEX = /\A\[?[0-9a-fA-F:]+\]?\z/

    # Frozen string constants
    DOT = '.'
    COLON = ':'
    BRACKET_OPEN = '['

    module_function

    def ip_address?(host)
      return false if host.nil? || host.empty?

      # Fast path: check for dot or colon before running regex
      if host.include?(DOT)
        IPV4_REGEX.match?(host)
      elsif host.include?(COLON) || host.include?(BRACKET_OPEN)
        IPV6_REGEX.match?(host)
      else
        false
      end
    end
  end
end
