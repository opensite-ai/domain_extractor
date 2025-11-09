# frozen_string_literal: true

module DomainExtractor
  # Formatter provides URL formatting based on validation modes and protocol requirements.
  #
  # Formats a URL string according to the specified options:
  # - Validation modes: :standard, :root_domain, :root_or_custom_subdomain
  # - Protocol options: use_protocol, use_https
  # - Trailing slash: use_trailing_slash
  #
  # @example Standard formatting
  #   DomainExtractor.format('https://www.example.com/')
  #   # => 'https://www.example.com'
  #
  # @example Root domain only
  #   DomainExtractor.format('https://shop.example.com/path', validation: :root_domain)
  #   # => 'https://example.com'
  #
  # @example Without protocol
  #   DomainExtractor.format('https://example.com', use_protocol: false)
  #   # => 'example.com'
  module Formatter
    VALIDATION_MODES = %i[standard root_domain root_or_custom_subdomain].freeze
    WWW_SUBDOMAIN = 'www'

    module_function

    # Format a URL according to the specified options
    #
    # @param url [String] The URL to format
    # @param options [Hash] Formatting options
    # @option options [Symbol] :validation (:standard) Validation mode
    # @option options [Boolean] :use_protocol (true) Include protocol in output
    # @option options [Boolean] :use_https (true) Use https instead of http
    # @option options [Boolean] :use_trailing_slash (false) Include trailing slash
    # @return [String, nil] Formatted URL or nil if invalid
    def call(url, **options)
      validation = options.fetch(:validation, :standard)
      use_protocol = options.fetch(:use_protocol, true)
      use_https = options.fetch(:use_https, true)
      use_trailing_slash = options.fetch(:use_trailing_slash, false)

      validate_options!(validation)

      # Parse the URL
      parsed = DomainExtractor.parse(url)
      return nil unless parsed.valid?

      # Build the formatted URL based on validation mode
      formatted_host = build_host(parsed, validation)
      build_url(formatted_host, use_protocol, use_https, use_trailing_slash)
    end

    def validate_options!(validation)
      return if VALIDATION_MODES.include?(validation)

      raise ArgumentError, "Invalid validation mode: #{validation}. " \
                           "Must be one of: #{VALIDATION_MODES.join(', ')}"
    end
    private_class_method :validate_options!

    # Build the host portion based on validation mode
    def build_host(parsed, validation)
      case validation
      when :standard
        # Return the full host as-is
        parsed.host
      when :root_domain
        # Return only the root domain (no subdomains)
        parsed.root_domain
      when :root_or_custom_subdomain
        # Return root domain or custom subdomain (strip www)
        if parsed.subdomain == WWW_SUBDOMAIN
          parsed.root_domain
        else
          parsed.host
        end
      end
    end
    private_class_method :build_host

    # Build the final URL string with protocol and trailing slash options
    def build_url(host, use_protocol, use_https, use_trailing_slash)
      url = ''

      # Add protocol if requested
      if use_protocol
        protocol = use_https ? 'https://' : 'http://'
        url = protocol + host
      else
        url = host
      end

      # Add or remove trailing slash
      if use_trailing_slash
        url += '/' unless url.end_with?('/')
      else
        url = url.chomp('/')
      end

      url
    end
    private_class_method :build_url
  end
end
