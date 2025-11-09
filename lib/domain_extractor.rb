# frozen_string_literal: true

require 'uri'
require 'public_suffix'

require_relative 'domain_extractor/version'
require_relative 'domain_extractor/errors'
require_relative 'domain_extractor/parsed_url'
require_relative 'domain_extractor/parser'
require_relative 'domain_extractor/query_params'

# Conditionally load Rails validator if ActiveModel is available
begin
  require_relative 'domain_extractor/domain_validator'
rescue LoadError
  # ActiveModel not available - skip loading validator
end

# DomainExtractor provides a high-performance API for url parsing and domain parsing.
# It exposes simple helpers for single URL normalization, domain extraction, and batch operations.
module DomainExtractor
  class << self
    # Parse an individual URL and extract domain attributes.
    # Returns a ParsedURL object that supports hash-style access and method calls.
    # For invalid inputs the returned ParsedURL will be marked invalid and all
    # accessors (without bang) will evaluate to nil/false.
    # @param url [String, #to_s]
    # @return [ParsedURL]
    def parse(url)
      Parser.call(url)
    end

    # Parse an individual URL and raise when extraction fails.
    # This mirrors the legacy behaviour of .parse while giving callers an
    # explicit opt-in to strict validation.
    # @param url [String, #to_s]
    # @return [ParsedURL]
    # @raise [InvalidURLError]
    def parse!(url)
      result = Parser.call(url)
      raise InvalidURLError unless result.valid?

      result
    end

    # Determine if a URL is considered valid by the parser.
    # @param url [String, #to_s]
    # @return [Boolean]
    def valid?(url)
      Parser.valid?(url)
    end

    # Parse many URLs and return their individual parse results.
    # Returns nil for invalid URLs to maintain backward compatibility.
    # @param urls [Enumerable<String>]
    # @return [Array<ParsedURL, nil>]
    def parse_batch(urls)
      return [] unless urls.respond_to?(:map)

      urls.map do |url|
        result = Parser.call(url)
        result.valid? ? result : nil
      end
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
