# frozen_string_literal: true

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
  class ParsedURL
    # Expose the underlying hash for backward compatibility
    attr_reader :result

    # List of valid result keys that should have method accessors
    RESULT_KEYS = %i[subdomain domain tld root_domain host path query_params].freeze

    def initialize(result)
      @result = result || {}
      freeze
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
      @result.to_s
    end

    # Allow to_h conversion for hash compatibility
    def to_h
      @result.dup
    end

    # Allow to_hash as well for better Ruby compatibility
    alias to_hash to_h

    private

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
end
