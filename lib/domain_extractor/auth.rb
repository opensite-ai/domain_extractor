# frozen_string_literal: true

require 'uri'

module DomainExtractor
  # Auth module extracts authentication components from URIs
  # Handles userinfo parsing with support for special characters and percent-encoding
  module Auth
    # Frozen constants for zero allocation
    COLON = ':'
    EMPTY_AUTH = {
      user: nil,
      password: nil,
      userinfo: nil,
      decoded_user: nil,
      decoded_password: nil
    }.freeze

    module_function

    # Extract userinfo components from a URI object
    # @param uri [URI::Generic] The parsed URI object
    # @return [Hash] Hash containing :user, :password, :userinfo, :decoded_user, :decoded_password
    def extract(uri)
      return empty_auth unless uri&.userinfo

      user, password = split_userinfo(uri.userinfo)

      {
        user: user,
        password: password,
        userinfo: uri.userinfo,
        decoded_user: decode_component(user),
        decoded_password: decode_component(password)
      }
    end

    # Split userinfo into user and password components
    # Handles edge cases like password-only (":password") and user-only ("user")
    # @param userinfo [String] The userinfo string from URI
    # @return [Array<String, String>] Array of [user, password]
    def split_userinfo(userinfo)
      return [nil, nil] if userinfo.nil? || userinfo.empty?

      # Find first colon to split user:password
      colon_index = userinfo.index(COLON)

      if colon_index.nil?
        # No colon means user-only
        [userinfo, nil]
      elsif colon_index.zero?
        # Starts with colon means password-only (Redis pattern: ":password")
        [nil, userinfo[1..]]
      else
        # Normal case: "user:password"
        [userinfo[0...colon_index], userinfo[(colon_index + 1)..]]
      end
    end
    private_class_method :split_userinfo

    # Decode percent-encoded component
    # @param component [String, nil] The component to decode
    # @return [String, nil] Decoded component or nil
    def decode_component(component)
      return nil if component.nil?
      return component if component.empty?

      URI::DEFAULT_PARSER.unescape(component)
    rescue StandardError
      # If decoding fails, return original
      component
    end
    private_class_method :decode_component

    # Return empty auth hash
    # @return [Hash] Empty auth components
    def empty_auth
      EMPTY_AUTH
    end
    private_class_method :empty_auth
  end
end
