# frozen_string_literal: true

require 'base64'
require 'uri'

module DomainExtractor
  # URIHelpers provides advanced URI manipulation methods
  # Including merge, normalize, authentication helpers, and proxy detection
  # rubocop:disable Metrics/ModuleLength
  module URIHelpers
    CREDENTIAL_ESCAPE_PATTERN = /[^A-Za-z0-9\-._~]/
    DEFAULT_PORTS = {
      'ftp' => 21,
      'ftps' => 990,
      'http' => 80,
      'https' => 443,
      'mongodb' => 27_017,
      'mysql' => 3306,
      'postgresql' => 5432,
      'redis' => 6379,
      'rediss' => 6380,
      'sftp' => 22,
      'ssh' => 22
    }.freeze
    HTTP_PROXY_KEYS = %w[http_proxy HTTP_PROXY].freeze
    ALL_PROXY_KEYS = %w[all_proxy ALL_PROXY].freeze

    module_function

    # Generate Basic Authentication header
    # @param username [String] The username
    # @param password [String] The password
    # @return [String] The Authorization header value
    def basic_auth_header(username, password)
      credentials = "#{username}:#{password}"
      encoded = Base64.strict_encode64(credentials)
      "Basic #{encoded}"
    end

    # Generate Bearer token header
    # @param token [String] The bearer token
    # @return [String] The Authorization header value
    def bearer_auth_header(token)
      "Bearer #{token}"
    end

    # Encode credentials for URL (percent-encoding)
    # @param value [String] The value to encode
    # @return [String] Percent-encoded value
    def encode_credential(value)
      URI::DEFAULT_PARSER.escape(value.to_s, CREDENTIAL_ESCAPE_PATTERN)
    end

    # Decode percent-encoded credential
    # @param value [String] The encoded value
    # @return [String] Decoded value
    def decode_credential(value)
      URI::DEFAULT_PARSER.unescape(value.to_s)
    rescue StandardError
      value
    end

    # Find proxy from environment variables
    # Checks http_proxy, HTTP_PROXY, and no_proxy
    # @param uri [URI::Generic, String] The URI to check
    # @return [URI::Generic, nil] The proxy URI or nil
    def find_proxy(uri)
      uri_obj = coerce_uri(uri)
      return nil unless uri_obj
      return nil if should_bypass_proxy?(uri_obj)

      proxy_url = proxy_url_for(uri_obj.scheme)
      return nil unless proxy_url

      URI.parse(proxy_url)
    rescue URI::InvalidURIError
      nil
    end

    # Check if URI should bypass proxy based on no_proxy
    # @param uri [URI::Generic] The URI to check
    # @return [Boolean] True if should bypass proxy
    def should_bypass_proxy?(uri)
      no_proxy = ENV['no_proxy'] || ENV.fetch('NO_PROXY', nil)
      return false unless no_proxy

      host = proxy_host(uri)
      return false unless host

      no_proxy
        .split(',')
        .map(&:strip)
        .reject(&:empty?)
        .any? { |pattern| proxy_pattern_match?(host, pattern) }
    end
    private_class_method :should_bypass_proxy?

    def coerce_uri(uri)
      uri.is_a?(String) ? URI.parse(uri) : uri
    end
    private_class_method :coerce_uri

    def proxy_url_for(scheme)
      proxy_env_keys(scheme).each do |key|
        value = env_value(key)
        return value if value
      end

      nil
    end
    private_class_method :proxy_url_for

    def env_value(key)
      value = ENV.fetch(key, nil)
      value unless value.nil? || value.empty?
    end
    private_class_method :env_value

    def proxy_host(uri)
      uri.hostname || uri.host
    end
    private_class_method :proxy_host

    def proxy_pattern_match?(host, pattern)
      return true if pattern == '*'

      normalized_pattern = pattern.delete_prefix('.')
      host == normalized_pattern || host.end_with?(".#{normalized_pattern}")
    end
    private_class_method :proxy_pattern_match?

    def proxy_env_keys(scheme)
      scheme_keys = if scheme && !scheme.empty?
                      ["#{scheme.downcase}_proxy", "#{scheme.upcase}_PROXY"]
                    else
                      []
                    end

      (scheme_keys + HTTP_PROXY_KEYS + ALL_PROXY_KEYS).uniq
    end
    private_class_method :proxy_env_keys

    # Normalize a URI (lowercase scheme and host, remove default ports)
    # @param uri [URI::Generic] The URI to normalize
    # @return [URI::Generic] Normalized URI
    def normalize_uri(uri)
      uri.normalize
    end

    # Merge a relative URI with a base URI
    # @param base [URI::Generic] The base URI
    # @param relative [String, URI::Generic] The relative URI
    # @return [URI::Generic] The merged URI
    def merge_uri(base, relative)
      base.merge(relative)
    end

    def default_port_for(uri_or_scheme)
      case uri_or_scheme
      when URI::Generic
        uri_or_scheme.default_port || DEFAULT_PORTS[uri_or_scheme.scheme]
      else
        DEFAULT_PORTS[uri_or_scheme.to_s]
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
