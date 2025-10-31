# frozen_string_literal: true

require 'uri'
require 'public_suffix'

# Utility module for parsing URLs and extracting domain parts
#
# Usage:
#   UrlParser.parse('https://www.example.co.uk/path')
#   # => { subdomain: 'www', root_domain: 'example.co.uk', domain: 'example', tld: 'co.uk', host: 'www.example.co.uk' }
#
#   UrlParser.parse('invalid-url')
#   # => nil
module UrlParser
  class << self
    # Parse a URL string and extract domain components
    #
    # @param url_string [String] The URL to parse
    # @return [Hash, nil] Hash with :subdomain, :root_domain, :domain, :tld, :host keys, or nil if invalid
    def parse(url_string)
      return nil if url_string.nil? || url_string.empty?

      # Normalize the URL - add scheme if missing
      normalized_url = normalize_url(url_string)

      # Parse with URI
      uri = URI.parse(normalized_url)
      host = uri.host

      # Check if host is valid (handles nil, empty, IP addresses, and invalid domains)
      return nil if ip_address?(host)
      return nil unless PublicSuffix.valid?(host)

      # Use PublicSuffix to properly parse the domain
      parsed = PublicSuffix.parse(host)

      {
        subdomain: parsed.trd,
        root_domain: parsed.domain,
        domain: parsed.sld,
        tld: parsed.tld,
        path: uri.path,
        host: host,
        query_params: query_to_hash(uri.query)
      }
    rescue URI::InvalidURIError, PublicSuffix::DomainInvalid, PublicSuffix::DomainNotAllowed
      nil
    end

    def query_to_hash(query)
      return {} if query.nil? || query.empty?

      query.split('&').each_with_object({}) do |pair, hash|
        key, value = pair.split('=')
        hash[key] = value
      end
    end

    # Batch parse multiple URLs
    #
    # @param url_strings [Array<String>] Array of URLs to parse
    # @return [Array<Hash, nil>] Array of parsed results (nil for invalid URLs)
    def parse_batch(url_strings)
      url_strings.map { |url| parse(url) }
    end

    private

    # Check if host is an IP address
    def ip_address?(host)
      # Check for IPv4
      return true if host.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/)

      # Check for IPv6
      return true if host.match?(/\A\[?[0-9a-f:]+\]?\z/i)

      false
    end

    # Normalize URL by adding scheme if missing
    def normalize_url(url_string)
      url_string = url_string.strip

      # If it looks like a domain without scheme, add https://
      url_string = "https://#{url_string}" unless url_string.match?(%r{\A\w+://})

      url_string
    end
  end
end
