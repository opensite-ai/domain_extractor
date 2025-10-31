# frozen_string_literal: true

module DomainExtractor
  # Result encapsulates the final parsed attributes and exposes a hash interface.
  module Result
    EMPTY_PATH = ''.freeze

    module_function

    def build(subdomain:, root_domain:, domain:, tld:, host:, path:, query:)
      {
        subdomain: subdomain,
        root_domain: root_domain,
        domain: domain,
        tld: tld,
        host: host,
        path: path.nil? ? EMPTY_PATH : path,
        query_params: QueryParams.call(query)
      }
    end
  end
end
