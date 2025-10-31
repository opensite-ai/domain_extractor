# frozen_string_literal: true

module DomainExtractor
  # Validators hosts fast checks for excluding unsupported hostnames (e.g. IP addresses).
  module Validators
    IPV4_SEGMENT = '(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)'
    IPV4_REGEX = /\A#{IPV4_SEGMENT}(?:\.#{IPV4_SEGMENT}){3}\z/
    IPV6_REGEX = /\A\[?[0-9a-fA-F:]+\]?\z/

    module_function

    def ip_address?(host)
      return false if host.nil? || host.empty?

      host.match?(IPV4_REGEX) || host.match?(IPV6_REGEX)
    end
  end
end
