# frozen_string_literal: true

module DomainExtractor
  # Validators hosts fast checks for excluding unsupported hostnames (e.g. IP addresses).
  module Validators
    # Frozen regex patterns for zero allocation
    IPV4_SEGMENT = '(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)'
    IPV4_REGEX = /\A#{IPV4_SEGMENT}(?:\.#{IPV4_SEGMENT}){3}\z/
    IPV6_REGEX = /\A\[?[0-9a-fA-F:]+\]?\z/

    # Valid hostname pattern (RFC 1123)
    # Allows: letters, numbers, hyphens, dots
    # Must start with alphanumeric, can contain hyphens, must end with alphanumeric
    HOSTNAME_REGEX = /\A[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*\z/i

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

    # Check if a string is a valid hostname
    # @param host [String] The hostname to validate
    # @return [Boolean] True if valid hostname
    def valid_hostname?(host)
      return false if host.nil? || host.empty?
      return false if host.length > 253 # Max hostname length

      HOSTNAME_REGEX.match?(host)
    end
  end
end
