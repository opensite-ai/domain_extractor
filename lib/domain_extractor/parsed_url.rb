# frozen_string_literal: true

require_relative 'auth'
require_relative 'query_params'
require_relative 'uri_helpers'

module DomainExtractor
  # ParsedURL wraps the parsing result and provides convenient accessor methods
  # with support for bang (!) and question mark (?) variants.
  #
  # Examples:
  #   parsed = DomainExtractor.parse('https://api.example.com')
  #   parsed.host           # => 'api.example.com'
  #   parsed.subdomain      # => 'api'
  #   parsed.subdomain?     # => true
  #   parsed.www_subdomain? # => false
  #
  #   parsed = DomainExtractor.parse('invalid')
  #   parsed.host           # => nil
  #   parsed.host?          # => false
  #   parsed.host!          # raises InvalidURLError
  # rubocop:disable Metrics/ClassLength
  class ParsedURL
    EMPTY_STRING = ''

    # Expose the underlying hash for backward compatibility
    attr_reader :result

    # Store the original URI object for advanced operations
    attr_reader :uri

    # List of valid result keys that should have method accessors
    RESULT_KEYS = %i[
      subdomain domain tld root_domain host path query_params
      scheme port fragment user password userinfo decoded_user decoded_password
    ].freeze

    def initialize(result, uri = nil)
      @result = (result || {}).dup
      @uri = uri
      sync_uri_state!
    end

    # Hash-style access for backward compatibility
    # result[:subdomain], result[:host], etc.
    def [](key)
      @result[key]
    end

    # Check if the parsed result is valid (not nil/empty)
    def valid?
      !@result.empty?
    end

    # Special helper: check if subdomain is specifically 'www'
    def www_subdomain?
      @result[:subdomain] == 'www'
    end

    # Dynamically handle method calls for all result keys
    # Supports three variants:
    # - method_name: returns value or nil
    # - method_name!: returns value or raises InvalidURLError
    # - method_name?: returns boolean (true if value exists and not nil/empty)
    def method_missing(method_name, *args, &)
      method_str = method_name.to_s

      # Handle bang methods (method_name!)
      return handle_bang_method(method_str) if method_str.end_with?('!')

      # Handle question mark methods (method_name?)
      return handle_question_method(method_str) if method_str.end_with?('?')

      # Handle regular methods (method_name)
      key = method_name.to_sym
      return @result[key] if RESULT_KEYS.include?(key)

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      method_str = method_name.to_s

      # Check for www_subdomain? special case
      return true if method_name == :www_subdomain?

      # Check if it's a bang or question mark variant
      if method_str.end_with?('!') || method_str.end_with?('?')
        key = method_str[0...-1].to_sym
        return true if RESULT_KEYS.include?(key)
      end

      # Check if it's a regular method
      return true if RESULT_KEYS.include?(method_name.to_sym)

      super
    end

    # Provide hash-like inspection
    def inspect
      "#<DomainExtractor::ParsedURL #{@result.inspect}>"
    end

    def to_s
      return EMPTY_STRING unless valid? && @uri

      @uri.to_s
    end

    # Allow to_h conversion for hash compatibility
    def to_h
      @result.dup
    end

    # Allow to_hash as well for better Ruby compatibility
    alias to_hash to_h

    # Alias for URI compatibility
    alias to_str to_s

    def scheme
      @result[:scheme]
    end

    def host
      @result[:host]
    end

    def port
      @result[:port]
    end

    def path
      @result[:path]
    end

    def fragment
      @result[:fragment]
    end

    def user
      @result[:user]
    end

    def password
      @result[:password]
    end

    def userinfo
      @result[:userinfo]
    end

    # hostname returns host without IPv6 brackets (URI compatibility)
    def hostname
      return nil unless @uri || host

      @uri&.hostname || host.to_s.gsub(/^\[|\]$/, '')
    end

    # query returns the query string (not parsed params)
    def query
      return nil unless @uri

      @uri.query
    end

    # Setter methods for URI compatibility
    def scheme=(value)
      mutate_uri! { @uri.scheme = normalize_scheme(value) }
    end

    def host=(value)
      mutate_uri! { replace_host(value) }
    end

    def hostname=(value)
      self.host = value
    end

    def port=(value)
      mutate_uri! { @uri.port = value }
    end

    def path=(value)
      mutate_uri! { @uri.path = value.to_s }
    end

    def query=(value)
      mutate_uri! { @uri.query = value }
    end

    def fragment=(value)
      mutate_uri! { @uri.fragment = value }
    end

    def user=(value)
      mutate_uri! { @uri.user = value }
    end

    def password=(value)
      mutate_uri! { @uri.password = value }
    end

    def userinfo=(value)
      mutate_uri! { @uri.userinfo = value }
    end

    # Advanced URI methods

    # Generate Basic Authentication header from current credentials
    # @return [String, nil] Authorization header value or nil if no credentials
    def basic_auth_header
      return nil if user.nil? || password.nil?

      URIHelpers.basic_auth_header(decoded_user || user, decoded_password || password)
    end

    # Generate Bearer token header
    # @param token [String] The bearer token
    # @return [String] Authorization header value
    def bearer_auth_header(token)
      URIHelpers.bearer_auth_header(token)
    end

    # Find proxy for this URL
    # @return [URI::Generic, nil] Proxy URI or nil
    def find_proxy
      return nil unless @uri

      URIHelpers.find_proxy(@uri)
    end

    # Merge with a relative URI
    # @param relative [String, URI::Generic] The relative URI
    # @return [ParsedURL] New ParsedURL with merged URI
    def merge(relative)
      return self unless @uri

      merged_uri = URIHelpers.merge_uri(@uri, relative)
      DomainExtractor.parse(merged_uri.to_s)
    end

    # Normalize the URI (lowercase scheme/host, remove default ports)
    # @return [ParsedURL] New ParsedURL with normalized URI
    def normalize
      return self unless @uri

      normalized_uri = URIHelpers.normalize_uri(@uri)
      DomainExtractor.parse(normalized_uri.to_s)
    end

    # Check if this is an absolute URI
    # @return [Boolean] True if absolute
    def absolute?
      !@result[:scheme].nil?
    end

    # Check if this is a relative URI
    # @return [Boolean] True if relative
    def relative?
      @result[:scheme].nil?
    end

    # Get the default port for the scheme
    # @return [Integer, nil] Default port or nil
    def default_port
      URIHelpers.default_port_for(@uri || scheme)
    end

    # Build a complete URL string from components
    # @return [String] The complete URL
    def build_url
      to_s
    end

    private

    def mutate_uri!
      return unless @uri

      yield
      sync_from_uri!
    end

    def sync_uri_state!
      return unless @uri && valid?

      current_userinfo = @uri.userinfo
      @uri.scheme = normalize_scheme(@result[:scheme]) if @result[:scheme]
      if @result[:host]
        @uri.host = normalize_host(@result[:host])
        @uri.userinfo = current_userinfo if current_userinfo
      end
      sync_from_uri!
    end

    def sync_from_uri!
      attributes = DomainExtractor::Parser.host_attributes(@uri.host)

      unless attributes
        @result.clear
        return
      end

      @result.replace(
        attributes.merge(
          path: @uri.path || EMPTY_STRING,
          query_params: QueryParams.call(@uri.query),
          scheme: normalize_scheme(@uri.scheme),
          port: @uri.port,
          fragment: @uri.fragment
        ).merge(Auth.extract(@uri))
      )
    end

    def normalize_host(value)
      return nil if value.nil?

      value.to_s.downcase
    end

    def normalize_scheme(value)
      return nil if value.nil?

      value.to_s.downcase
    end

    def replace_host(value)
      current_userinfo = @uri.userinfo
      @uri.host = normalize_host(value)
      @uri.userinfo = current_userinfo if current_userinfo
    end

    # Handle bang methods that raise errors for missing values
    def handle_bang_method(method_str)
      key = method_str[0...-1].to_sym
      return unless RESULT_KEYS.include?(key)

      value = @result[key]
      return value if value_present?(value)

      raise InvalidURLError, "#{key} not found or invalid"
    end

    # Handle question mark methods that return booleans
    def handle_question_method(method_str)
      key = method_str[0...-1].to_sym
      return unless RESULT_KEYS.include?(key)

      value_present?(@result[key])
    end

    # Check if a value is present (not nil and not empty for strings/hashes)
    def value_present?(value)
      return false if value.nil?
      return !value.empty? if value.respond_to?(:empty?)

      true
    end
  end
  # rubocop:enable Metrics/ClassLength
end
