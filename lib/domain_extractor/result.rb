# frozen_string_literal: true

require_relative 'parsed_url'

module DomainExtractor
  # Result encapsulates the final parsed attributes and exposes a hash interface.
  module Result
    # Frozen constants for zero allocation
    EMPTY_PATH = ''
    EMPTY_HASH = {}.freeze

    module_function

    def build(**attributes)
      hash = {
        subdomain: normalize_subdomain(attributes[:subdomain]),
        root_domain: attributes[:root_domain],
        domain: attributes[:domain],
        tld: attributes[:tld],
        host: attributes[:host],
        path: attributes[:path] || EMPTY_PATH,
        query_params: QueryParams.call(attributes[:query])
      }.freeze

      ParsedURL.new(hash)
    end

    def normalize_subdomain(value)
      value.nil? || value.empty? ? nil : value
    end
    private_class_method :normalize_subdomain
  end
end
