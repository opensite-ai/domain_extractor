# frozen_string_literal: true

require 'uri'
require 'public_suffix'

require_relative 'domain_extractor/version'
require_relative 'domain_extractor/parser'
require_relative 'domain_extractor/query_params'

# DomainExtractor provides a high-performance API for url parsing and domain parsing.
# It exposes simple helpers for single URL normalization, domain extraction, and batch operations.
module DomainExtractor
  class << self
    # Parse an individual URL and extract domain attributes.
    # @param url [String, #to_s]
    # @return [Hash, nil]
    def parse(url)
      Parser.call(url)
    end

    # Parse many URLs and return their individual parse results.
    # @param urls [Enumerable<String>]
    # @return [Array<Hash, nil>]
    def parse_batch(urls)
      return [] unless urls.respond_to?(:map)

      urls.map { |url| parse(url) }
    end

    # Convert a query string into a Hash representation.
    # @param query_string [String, nil]
    # @return [Hash]
    def parse_query_params(query_string)
      QueryParams.call(query_string)
    end

    alias parse_query parse_query_params
  end
end
