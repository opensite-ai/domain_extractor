# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DomainExtractor::Formatter do
  describe '.call' do
    context 'with :standard validation mode' do
      it 'formats a simple URL with default options' do
        result = described_class.call('https://example.com')
        expect(result).to eq('https://example.com')
      end

      it 'removes trailing slash by default' do
        result = described_class.call('https://example.com/')
        expect(result).to eq('https://example.com')
      end

      it 'preserves subdomains' do
        result = described_class.call('https://shop.example.com')
        expect(result).to eq('https://shop.example.com')
      end

      it 'preserves www subdomain' do
        result = described_class.call('https://www.example.com')
        expect(result).to eq('https://www.example.com')
      end

      it 'preserves multi-level subdomains' do
        result = described_class.call('https://api.staging.example.com')
        expect(result).to eq('https://api.staging.example.com')
      end

      it 'handles URLs without protocol' do
        result = described_class.call('example.com')
        expect(result).to eq('https://example.com')
      end

      it 'strips path from URL' do
        result = described_class.call('https://example.com/path/to/page')
        expect(result).to eq('https://example.com')
      end

      it 'strips query parameters from URL' do
        result = described_class.call('https://example.com?foo=bar')
        expect(result).to eq('https://example.com')
      end
    end

    context 'with :root_domain validation mode' do
      it 'returns root domain for URL with subdomain' do
        result = described_class.call('https://shop.example.com', validation: :root_domain)
        expect(result).to eq('https://example.com')
      end

      it 'returns root domain for URL with www' do
        result = described_class.call('https://www.example.com', validation: :root_domain)
        expect(result).to eq('https://example.com')
      end

      it 'returns root domain for URL without subdomain' do
        result = described_class.call('https://example.com', validation: :root_domain)
        expect(result).to eq('https://example.com')
      end

      it 'returns root domain for multi-level subdomains' do
        result = described_class.call('https://api.staging.example.com', validation: :root_domain)
        expect(result).to eq('https://example.com')
      end

      it 'handles multi-part TLDs' do
        result = described_class.call('https://shop.example.co.uk', validation: :root_domain)
        expect(result).to eq('https://example.co.uk')
      end
    end

    context 'with :root_or_custom_subdomain validation mode' do
      it 'preserves root domain' do
        result = described_class.call('https://example.com', validation: :root_or_custom_subdomain)
        expect(result).to eq('https://example.com')
      end

      it 'preserves custom subdomains' do
        result = described_class.call('https://shop.example.com', validation: :root_or_custom_subdomain)
        expect(result).to eq('https://shop.example.com')
      end

      it 'strips www subdomain' do
        result = described_class.call('https://www.example.com', validation: :root_or_custom_subdomain)
        expect(result).to eq('https://example.com')
      end

      it 'preserves api subdomain' do
        result = described_class.call('https://api.example.com', validation: :root_or_custom_subdomain)
        expect(result).to eq('https://api.example.com')
      end

      it 'preserves multi-level custom subdomains' do
        result = described_class.call('https://api.staging.example.com', validation: :root_or_custom_subdomain)
        expect(result).to eq('https://api.staging.example.com')
      end
    end

    context 'with use_protocol option' do
      it 'includes protocol by default' do
        result = described_class.call('https://example.com')
        expect(result).to eq('https://example.com')
      end

      it 'includes protocol when use_protocol is true' do
        result = described_class.call('https://example.com', use_protocol: true)
        expect(result).to eq('https://example.com')
      end

      it 'excludes protocol when use_protocol is false' do
        result = described_class.call('https://example.com', use_protocol: false)
        expect(result).to eq('example.com')
      end

      it 'excludes protocol with subdomain' do
        result = described_class.call('https://shop.example.com', use_protocol: false)
        expect(result).to eq('shop.example.com')
      end

      it 'works with root_domain validation' do
        result = described_class.call('https://shop.example.com',
                                      validation: :root_domain,
                                      use_protocol: false)
        expect(result).to eq('example.com')
      end
    end

    context 'with use_https option' do
      it 'uses https by default' do
        result = described_class.call('http://example.com')
        expect(result).to eq('https://example.com')
      end

      it 'uses https when use_https is true' do
        result = described_class.call('http://example.com', use_https: true)
        expect(result).to eq('https://example.com')
      end

      it 'uses http when use_https is false' do
        result = described_class.call('https://example.com', use_https: false)
        expect(result).to eq('http://example.com')
      end

      it 'preserves http when use_https is false' do
        result = described_class.call('http://example.com', use_https: false)
        expect(result).to eq('http://example.com')
      end

      it 'ignores use_https when use_protocol is false' do
        result = described_class.call('https://example.com',
                                      use_protocol: false,
                                      use_https: false)
        expect(result).to eq('example.com')
      end
    end

    context 'with use_trailing_slash option' do
      it 'removes trailing slash by default' do
        result = described_class.call('https://example.com/')
        expect(result).to eq('https://example.com')
      end

      it 'removes trailing slash when use_trailing_slash is false' do
        result = described_class.call('https://example.com/', use_trailing_slash: false)
        expect(result).to eq('https://example.com')
      end

      it 'adds trailing slash when use_trailing_slash is true' do
        result = described_class.call('https://example.com', use_trailing_slash: true)
        expect(result).to eq('https://example.com/')
      end

      it 'preserves trailing slash when use_trailing_slash is true' do
        result = described_class.call('https://example.com/', use_trailing_slash: true)
        expect(result).to eq('https://example.com/')
      end

      it 'works without protocol' do
        result = described_class.call('https://example.com',
                                      use_protocol: false,
                                      use_trailing_slash: true)
        expect(result).to eq('example.com/')
      end

      it 'works with root_domain validation' do
        result = described_class.call('https://shop.example.com',
                                      validation: :root_domain,
                                      use_trailing_slash: true)
        expect(result).to eq('https://example.com/')
      end
    end

    context 'with combined options' do
      it 'formats with all options: root_domain, no protocol, with trailing slash' do
        result = described_class.call('https://shop.example.com/path',
                                      validation: :root_domain,
                                      use_protocol: false,
                                      use_trailing_slash: true)
        expect(result).to eq('example.com/')
      end

      it 'formats with root_or_custom_subdomain, http protocol, no trailing slash' do
        result = described_class.call('https://www.example.com/',
                                      validation: :root_or_custom_subdomain,
                                      use_https: false,
                                      use_trailing_slash: false)
        expect(result).to eq('http://example.com')
      end

      it 'formats with standard, no protocol, http, with trailing slash' do
        result = described_class.call('https://api.example.com',
                                      validation: :standard,
                                      use_protocol: false,
                                      use_trailing_slash: true)
        expect(result).to eq('api.example.com/')
      end

      it 'strips www and adds trailing slash' do
        result = described_class.call('https://www.example.com',
                                      validation: :root_or_custom_subdomain,
                                      use_trailing_slash: true)
        expect(result).to eq('https://example.com/')
      end
    end

    context 'with multi-part TLDs' do
      it 'handles UK domains with standard mode' do
        result = described_class.call('https://shop.example.co.uk')
        expect(result).to eq('https://shop.example.co.uk')
      end

      it 'handles UK domains with root_domain mode' do
        result = described_class.call('https://shop.example.co.uk', validation: :root_domain)
        expect(result).to eq('https://example.co.uk')
      end

      it 'handles Australian domains' do
        result = described_class.call('https://www.example.com.au',
                                      validation: :root_or_custom_subdomain)
        expect(result).to eq('https://example.com.au')
      end
    end

    context 'with invalid input' do
      it 'returns nil for invalid URLs' do
        result = described_class.call('not-a-url')
        expect(result).to be_nil
      end

      it 'returns nil for nil input' do
        result = described_class.call(nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = described_class.call('')
        expect(result).to be_nil
      end

      it 'returns nil for IP addresses' do
        result = described_class.call('https://192.168.1.1')
        expect(result).to be_nil
      end
    end

    context 'with error handling' do
      it 'raises error for invalid validation mode' do
        expect do
          described_class.call('https://example.com', validation: :invalid_mode)
        end.to raise_error(ArgumentError, /Invalid validation mode/)
      end
    end
  end
end

RSpec.describe DomainExtractor do
  describe '.format' do
    it 'delegates to Formatter.call' do
      result = DomainExtractor.format('https://www.example.com/')
      expect(result).to eq('https://www.example.com')
    end

    it 'passes options correctly' do
      result = DomainExtractor.format('https://shop.example.com',
                                      validation: :root_domain,
                                      use_protocol: false)
      expect(result).to eq('example.com')
    end

    it 'returns nil for invalid URLs' do
      result = DomainExtractor.format('invalid-url')
      expect(result).to be_nil
    end
  end
end
