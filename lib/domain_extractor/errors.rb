# frozen_string_literal: true

module DomainExtractor
  class InvalidURLError < StandardError
    DEFAULT_MESSAGE = 'Invalid URL Value'

    def initialize(message = DEFAULT_MESSAGE)
      super
    end
  end
end
