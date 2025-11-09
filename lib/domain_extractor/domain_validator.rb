# frozen_string_literal: true

# Try to load ActiveModel, but don't fail if it's not available
begin
  require 'active_model'
rescue LoadError
  # Create a stub for testing environments without Rails
  module ActiveModel
    class EachValidator
      attr_reader :options

      def initialize(options)
        @options = options
      end
    end
  end
end

# DomainValidator is a custom ActiveModel validator for URL/domain validation.
#
# This validator is defined at the top level so Rails can find it when using:
#   validates :url, domain: { validation: :standard }
#
# Validation modes:
# - :standard - Validates any valid URL using DomainExtractor.valid?
# - :root_domain - Only allows root domains (no subdomains) like https://mysite.com
# - :root_or_custom_subdomain - Allows root or custom subdomains but excludes 'www'
#
# Optional flags:
# - use_protocol (default: true) - Whether protocol (http/https) is required
# - use_https (default: true) - Whether https is required (only if use_protocol is true)
#
# @example Standard validation
#   validates :url, domain: { validation: :standard }
#
# @example Root domain only, no protocol required
#   validates :url, domain: { validation: :root_domain, use_protocol: false }
#
# @example Root or custom subdomain with https required
#   validates :url, domain: { validation: :root_or_custom_subdomain, use_https: true }
class DomainValidator < ActiveModel::EachValidator
  VALIDATION_MODES = %i[standard root_domain root_or_custom_subdomain].freeze
  WWW_SUBDOMAIN = 'www'

  def validate_each(record, attribute, value)
    return if blank?(value)

    validation_mode = extract_validation_mode
    use_protocol = options.fetch(:use_protocol, true)
    use_https = options.fetch(:use_https, true)

    normalized_url = normalize_url(value, use_protocol, use_https)

    return unless protocol_valid?(record, attribute, normalized_url, use_protocol, use_https)

    parsed = parse_and_validate_url(record, attribute, normalized_url)
    return unless parsed

    apply_validation_mode(record, attribute, parsed, validation_mode)
  end

  private

  # Extract and validate the validation mode option
  def extract_validation_mode
    validation_mode = options.fetch(:validation, :standard)
    return validation_mode if VALIDATION_MODES.include?(validation_mode)

    raise ArgumentError, "Invalid validation mode: #{validation_mode}. " \
                         "Must be one of: #{VALIDATION_MODES.join(', ')}"
  end

  # Check protocol requirements
  def protocol_valid?(record, attribute, url, use_protocol, use_https)
    return true unless use_protocol
    return true if valid_protocol?(url, use_https)

    protocol = use_https ? 'https://' : 'http:// or https://'
    record.errors.add(attribute, "must use #{protocol}")
    false
  end

  # Parse URL and validate it's valid
  def parse_and_validate_url(record, attribute, url)
    parsed = DomainExtractor.parse(url)
    return parsed if parsed.valid?

    record.errors.add(attribute, 'is not a valid URL')
    nil
  end

  # Apply the validation mode rules
  def apply_validation_mode(record, attribute, parsed, validation_mode)
    case validation_mode
    when :standard
      # Already validated - any valid URL passes
      nil
    when :root_domain
      validate_root_domain(record, attribute, parsed)
    when :root_or_custom_subdomain
      validate_root_or_custom_subdomain(record, attribute, parsed)
    end
  end

  # Check if value is blank (nil, empty string, or whitespace-only)
  def blank?(value)
    value.nil? || (value.respond_to?(:empty?) && value.empty?) ||
      (value.is_a?(String) && value.strip.empty?)
  end

  # Normalize URL for validation based on protocol requirements
  def normalize_url(url, use_protocol, use_https)
    return url if blank?(url)

    url = url.strip

    # If protocol is not required, strip any existing protocol
    url = url.gsub(%r{\A[A-Za-z][A-Za-z0-9+\-.]*://}, '') unless use_protocol

    # Add protocol if needed for parsing
    unless url.match?(%r{\A[A-Za-z][A-Za-z0-9+\-.]*://})
      scheme = use_https ? 'https://' : 'http://'
      url = scheme + url
    end

    url
  end

  # Check if URL has valid protocol
  def valid_protocol?(url, use_https)
    return true unless url.match?(%r{\A[A-Za-z][A-Za-z0-9+\-.]*://})

    if use_https
      url.start_with?('https://')
    else
      url.start_with?('http://', 'https://')
    end
  end

  # Validate that URL is a root domain (no subdomain)
  def validate_root_domain(record, attribute, parsed)
    return unless parsed.subdomain?

    record.errors.add(attribute, 'must be a root domain (no subdomains allowed)')
  end

  # Validate that URL is either root domain or has custom subdomain (not 'www')
  def validate_root_or_custom_subdomain(record, attribute, parsed)
    return unless parsed.subdomain == WWW_SUBDOMAIN

    record.errors.add(attribute, 'cannot use www subdomain')
  end
end

# Also register in DomainExtractor namespace for backwards compatibility
module DomainExtractor
  # DomainValidator is now defined at the top level for Rails autoloading.
  # This constant provides a reference for explicit usage.
  #
  # Validation modes:
  # - :standard - Validates any valid URL using DomainExtractor.valid?
  # - :root_domain - Only allows root domains (no subdomains) like https://mysite.com
  # - :root_or_custom_subdomain - Allows root or custom subdomains, but excludes 'www'
  #
  # Optional flags:
  # - use_protocol (default: true) - Whether protocol (http/https) is required
  # - use_https (default: true) - Whether https is required (only if use_protocol is true)
  #
  # @example Standard validation
  #   validates :url, domain: { validation: :standard }
  #
  # @example Root domain only, no protocol required
  #   validates :url, domain: { validation: :root_domain, use_protocol: false }
  DomainValidator = ::DomainValidator
end
