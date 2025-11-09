# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DomainExtractor::DomainValidator do
  # Mock record class for testing
  let(:record_class) do
    Class.new do
      attr_accessor :url
      attr_reader :errors

      def initialize
        @errors = ErrorsCollection.new
      end
    end
  end

  # Mock errors collection
  let(:errors_collection_class) do
    Class.new do
      attr_reader :messages

      def initialize
        @messages = []
      end

      def add(attribute, message)
        @messages << { attribute: attribute, message: message }
      end

      def empty?
        @messages.empty?
      end

      def full_messages
        @messages.map { |m| "#{m[:attribute]} #{m[:message]}" }
      end
    end
  end

  let(:record) { record_class.new }

  before(:each) do
    stub_const('ErrorsCollection', errors_collection_class)
  end

  describe 'validation modes' do
    context 'with :standard validation' do
      let(:validator) { described_class.new(attributes: [:url], validation: :standard) }

      it 'accepts valid URLs with subdomains' do
        record.url = 'https://shop.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts valid URLs without subdomains' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts www subdomain' do
        record.url = 'https://www.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'rejects invalid URLs' do
        record.url = 'not-a-url'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
        expect(record.errors.messages.first[:message]).to include('not a valid URL')
      end

      it 'allows blank values' do
        record.url = ''
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end
    end

    context 'with :root_domain validation' do
      let(:validator) { described_class.new(attributes: [:url], validation: :root_domain) }

      it 'accepts root domain URLs' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'rejects URLs with subdomains' do
        record.url = 'https://shop.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
        expect(record.errors.messages.first[:message]).to include('no subdomains allowed')
      end

      it 'rejects www subdomain' do
        record.url = 'https://www.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
        expect(record.errors.messages.first[:message]).to include('no subdomains allowed')
      end

      it 'rejects custom subdomains' do
        record.url = 'https://api.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
        expect(record.errors.messages.first[:message]).to include('no subdomains allowed')
      end
    end

    context 'with :root_or_custom_subdomain validation' do
      let(:validator) do
        described_class.new(attributes: [:url], validation: :root_or_custom_subdomain)
      end

      it 'accepts root domain URLs' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts custom subdomain URLs' do
        record.url = 'https://shop.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts api subdomain' do
        record.url = 'https://api.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'rejects www subdomain' do
        record.url = 'https://www.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
        expect(record.errors.messages.first[:message]).to include('cannot use www subdomain')
      end
    end
  end

  describe 'protocol options' do
    context 'with use_protocol: true (default)' do
      let(:validator) { described_class.new(attributes: [:url], validation: :standard) }

      it 'accepts URLs with https protocol' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts URLs without protocol by auto-adding https' do
        record.url = 'mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end
    end

    context 'with use_protocol: false' do
      let(:validator) do
        described_class.new(attributes: [:url], validation: :standard, use_protocol: false)
      end

      it 'accepts URLs without protocol' do
        record.url = 'mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts URLs with protocol by stripping it' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'works with root_domain validation' do
        validator = described_class.new(
          attributes: [:url],
          validation: :root_domain,
          use_protocol: false
        )
        record.url = 'mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'rejects subdomains with root_domain validation' do
        validator = described_class.new(
          attributes: [:url],
          validation: :root_domain,
          use_protocol: false
        )
        record.url = 'shop.mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
      end
    end

    context 'with use_https: true (default)' do
      let(:validator) { described_class.new(attributes: [:url], validation: :standard) }

      it 'accepts https URLs' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'rejects http URLs' do
        record.url = 'http://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).not_to be_empty
        expect(record.errors.messages.first[:message]).to include('must use https://')
      end
    end

    context 'with use_https: false' do
      let(:validator) do
        described_class.new(attributes: [:url], validation: :standard, use_https: false)
      end

      it 'accepts https URLs' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts http URLs' do
        record.url = 'http://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end
    end

    context 'with use_protocol: false and use_https: false' do
      let(:validator) do
        described_class.new(
          attributes: [:url],
          validation: :standard,
          use_protocol: false,
          use_https: false
        )
      end

      it 'accepts domain without protocol' do
        record.url = 'mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts domain with http protocol' do
        record.url = 'http://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end

      it 'accepts domain with https protocol' do
        record.url = 'https://mysite.com'
        validator.validate_each(record, :url, record.url)
        expect(record.errors.messages).to be_empty
      end
    end
  end

  describe 'complex scenarios' do
    it 'validates root_domain without protocol' do
      validator = described_class.new(
        attributes: [:url],
        validation: :root_domain,
        use_protocol: false
      )
      record.url = 'mysite.com'
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end

    it 'validates root_or_custom_subdomain with https only' do
      validator = described_class.new(
        attributes: [:url],
        validation: :root_or_custom_subdomain,
        use_https: true
      )
      record.url = 'https://shop.mysite.com'
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end

    it 'rejects www in root_or_custom_subdomain mode' do
      validator = described_class.new(
        attributes: [:url],
        validation: :root_or_custom_subdomain,
        use_protocol: false
      )
      record.url = 'www.mysite.com'
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).not_to be_empty
      expect(record.errors.messages.first[:message]).to include('cannot use www subdomain')
    end

    it 'handles URLs with paths' do
      validator = described_class.new(attributes: [:url], validation: :standard)
      record.url = 'https://mysite.com/path/to/page'
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end

    it 'handles URLs with query parameters' do
      validator = described_class.new(attributes: [:url], validation: :standard)
      record.url = 'https://mysite.com?foo=bar&baz=qux'
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end

    it 'handles multi-level subdomains with root_or_custom_subdomain' do
      validator = described_class.new(
        attributes: [:url],
        validation: :root_or_custom_subdomain
      )
      record.url = 'https://api.staging.mysite.com'
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end
  end

  describe 'error handling' do
    it 'raises error for invalid validation mode' do
      expect do
        validator = described_class.new(attributes: [:url], validation: :invalid_mode)
        validator.validate_each(record, :url, 'https://mysite.com')
      end.to raise_error(ArgumentError, /Invalid validation mode/)
    end

    it 'handles nil values gracefully' do
      validator = described_class.new(attributes: [:url], validation: :standard)
      record.url = nil
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end

    it 'handles whitespace-only values' do
      validator = described_class.new(attributes: [:url], validation: :standard)
      record.url = '   '
      validator.validate_each(record, :url, record.url)
      expect(record.errors.messages).to be_empty
    end
  end
end
