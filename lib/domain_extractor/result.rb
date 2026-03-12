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
      ParsedURL.new(result_hash(attributes), attributes[:uri])
    end

    def normalize_subdomain(value)
      value.nil? || value.empty? ? nil : value
    end
    private_class_method :normalize_subdomain

    def result_hash(attributes)
      domain_attributes(attributes)
        .merge(uri_attributes(attributes))
        .merge(auth_attributes(attributes))
        .freeze
    end
    private_class_method :result_hash

    def domain_attributes(attributes)
      {
        subdomain: normalize_subdomain(attributes[:subdomain]),
        root_domain: attributes[:root_domain],
        domain: attributes[:domain],
        tld: attributes[:tld],
        host: attributes[:host]
      }
    end
    private_class_method :domain_attributes

    def uri_attributes(attributes)
      {
        path: attributes[:path] || EMPTY_PATH,
        query_params: QueryParams.call(attributes[:query]),
        scheme: attributes[:scheme],
        port: attributes[:port],
        fragment: attributes[:fragment]
      }
    end
    private_class_method :uri_attributes

    def auth_attributes(attributes)
      {
        user: attributes[:user],
        password: attributes[:password],
        userinfo: attributes[:userinfo],
        decoded_user: attributes[:decoded_user],
        decoded_password: attributes[:decoded_password]
      }
    end
    private_class_method :auth_attributes
  end
end
