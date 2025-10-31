# frozen_string_literal: true

require 'uri'
require 'public_suffix'

require_relative 'normalizer'
require_relative 'result'
require_relative 'validators'

module DomainExtractor
  # Parser orchestrates the pipeline for url normalization, validation, and domain extraction.
  module Parser
    module_function

    def call(raw_url)
      components = extract_components(raw_url)
      return unless components

      uri, domain, host = components
      build_result(domain: domain, host: host, uri: uri)
    rescue ::URI::InvalidURIError, ::PublicSuffix::Error
      nil
    end

    def valid?(raw_url)
      !!extract_components(raw_url)
    rescue ::URI::InvalidURIError, ::PublicSuffix::Error
      false
    end

    def build_uri(raw_url)
      normalized = Normalizer.call(raw_url)
      return unless normalized

      ::URI.parse(normalized)
    end
    private_class_method :build_uri

    def invalid_host?(host)
      host.nil? || Validators.ip_address?(host) || !::PublicSuffix.valid?(host)
    end
    private_class_method :invalid_host?

    def extract_components(raw_url)
      uri = build_uri(raw_url)
      return unless uri

      host = uri.host&.downcase
      return if invalid_host?(host)

      domain = ::PublicSuffix.parse(host)
      [uri, domain, host]
    end
    private_class_method :extract_components

    def build_result(domain:, host:, uri:)
      Result.build(
        subdomain: domain.trd,
        root_domain: domain.domain,
        domain: domain.sld,
        tld: domain.tld,
        host: host,
        path: uri.path,
        query: uri.query
      )
    end
    private_class_method :build_result
  end
end
