# frozen_string_literal: true

module DomainExtractor
  # Result encapsulates the final parsed attributes and exposes a hash interface.
  module Result
    EMPTY_PATH = ''

    module_function

    def build(**attributes)
      {
        subdomain: normalize_subdomain(attributes[:subdomain]),
        root_domain: attributes[:root_domain],
        domain: attributes[:domain],
        tld: attributes[:tld],
        host: attributes[:host],
        path: attributes[:path] || EMPTY_PATH,
        query_params: QueryParams.call(attributes[:query])
      }
    end

    def normalize_subdomain(value)
      value.nil? || value.empty? ? nil : value
    end
    private_class_method :normalize_subdomain
  end
end
