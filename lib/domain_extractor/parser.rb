# frozen_string_literal: true

require 'uri'
require 'public_suffix'

require_relative 'normalizer'
require_relative 'query_params'
require_relative 'result'
require_relative 'validators'

module DomainExtractor
  # Parser orchestrates the pipeline for url normalization, validation, and domain extraction.
  module Parser
    EMPTY_STRING = ''

    module_function

    def call(url)
      normalized = Normalizer.call(url)
      return if normalized.nil?

      uri = ::URI.parse(normalized)
      host = uri.host&.downcase
      return if invalid?(host)

      domain = ::PublicSuffix.parse(host)
      process_result(domain: domain, host: host, uri: uri)
    rescue ::URI::InvalidURIError, ::PublicSuffix::Error
      nil
    end

    def invalid?(host)
      Validators.ip_address?(host) || !::PublicSuffix.valid?(host)
    end
    private_class_method :invalid?

    def blank_to_nil(value)
      value.nil? || value.empty? ? nil : value
    end
    private_class_method :blank_to_nil

    def process_result(domain:, host:, uri:)
      Result.build(
        subdomain: blank_to_nil(domain.trd),
        root_domain: domain.domain,
        domain: domain.sld,
        tld: domain.tld,
        host: host,
        path: uri.path || EMPTY_STRING,
        query: uri.query
      )
    end
    private_class_method :process_result
  end
end
