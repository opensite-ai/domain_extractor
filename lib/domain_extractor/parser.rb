# frozen_string_literal: true

require 'uri'
require 'public_suffix'

require_relative 'normalizer'
require_relative 'result'
require_relative 'validators'
require_relative 'parsed_url'
require_relative 'auth'

# Register custom URI schemes for database and other protocols
# This allows URI.parse to handle redis://, mysql://, postgresql://, etc.
%w[redis rediss mysql postgresql mongodb sftp ftps].each do |scheme|
  URI.scheme_list[scheme.upcase] = URI::Generic
rescue StandardError
  # Ignore if can't register
end

module DomainExtractor
  # Parser orchestrates the pipeline for url normalization, validation, and domain extraction.
  module Parser
    SCHEME_PATTERN = %r{\A([a-z][a-z0-9+.-]*)://}i
    RETRYABLE_URI_MESSAGES = ['bad URI', 'is not URI'].freeze

    module_function

    def call(raw_url)
      uri, host_attributes = extract_components(raw_url)
      return ParsedURL.new(nil) unless uri && host_attributes

      build_result(host_attributes: host_attributes, uri: uri)
    rescue ::URI::InvalidURIError, ::PublicSuffix::Error
      ParsedURL.new(nil)
    end

    def valid?(raw_url)
      !!extract_components(raw_url)
    rescue ::URI::InvalidURIError, ::PublicSuffix::Error
      false
    end

    def host_attributes(host)
      return if invalid_host?(host)

      normalized_host = host.downcase
      domain = parse_domain(normalized_host)

      return domain_attributes(domain, normalized_host) if domain

      hostname_attributes(normalized_host) if Validators.valid_hostname?(normalized_host)
    end

    def build_uri(raw_url, retry_count = 0)
      normalized = Normalizer.call(raw_url)
      return unless normalized

      ::URI.parse(normalized)
    rescue ::URI::InvalidURIError => e
      retry_parse_with_registered_scheme(e, normalized, raw_url, retry_count)
    end
    private_class_method :build_uri

    def invalid_host?(host)
      host.nil? || Validators.ip_address?(host)
    end
    private_class_method :invalid_host?

    def extract_components(raw_url)
      uri = build_uri(raw_url)
      return unless uri

      attributes = host_attributes(uri.host)
      return unless attributes

      [uri, attributes]
    end
    private_class_method :extract_components

    def parse_domain(host)
      ::PublicSuffix.parse(host)
    rescue ::PublicSuffix::Error
      nil
    end
    private_class_method :parse_domain

    def domain_attributes(domain, host)
      {
        subdomain: domain.trd,
        root_domain: domain.domain,
        domain: domain.sld,
        tld: domain.tld,
        host: host
      }
    end
    private_class_method :domain_attributes

    def hostname_attributes(host)
      {
        subdomain: nil,
        root_domain: host,
        domain: host,
        tld: nil,
        host: host
      }
    end
    private_class_method :hostname_attributes

    def retry_parse_with_registered_scheme(error, normalized, raw_url, retry_count)
      return nil unless retryable_scheme_registration?(error.message, normalized, retry_count)

      register_scheme(normalized[SCHEME_PATTERN, 1])
      build_uri(raw_url, 1)
    rescue StandardError
      nil
    end
    private_class_method :retry_parse_with_registered_scheme

    def retryable_scheme_registration?(message, normalized, retry_count)
      retry_count.zero? &&
        RETRYABLE_URI_MESSAGES.any? { |fragment| message.include?(fragment) } &&
        normalized.match?(SCHEME_PATTERN)
    end
    private_class_method :retryable_scheme_registration?

    def register_scheme(scheme)
      URI.scheme_list[scheme.upcase] = URI::Generic
    end
    private_class_method :register_scheme

    def build_result(host_attributes:, uri:)
      auth_components = Auth.extract(uri)

      Result.build(
        **host_attributes,
        path: uri.path,
        query: uri.query,
        scheme: uri.scheme,
        port: uri.port,
        fragment: uri.fragment,
        **auth_components,
        uri: uri
      )
    end
    private_class_method :build_result
  end
end
