# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DomainExtractor do
  describe '.parse' do
    context 'with valid URLs' do
      it 'parses a simple domain without subdomain' do
        result = described_class.parse('dashtrack.com')

        expect(result[:subdomain]).to be_nil
        expect(result[:root_domain]).to eq('dashtrack.com')
        expect(result[:domain]).to eq('dashtrack')
        expect(result[:tld]).to eq('com')
        expect(result[:host]).to eq('dashtrack.com')
      end

      it 'parses a domain with www subdomain' do
        result = described_class.parse('www.insurancesite.ai')

        expect(result[:subdomain]).to eq('www')
        expect(result[:root_domain]).to eq('insurancesite.ai')
        expect(result[:domain]).to eq('insurancesite')
        expect(result[:tld]).to eq('ai')
        expect(result[:host]).to eq('www.insurancesite.ai')
      end

      it 'parses a full URL with path' do
        result = described_class.parse('https://hitting.com/index')

        expect(result[:subdomain]).to be_nil
        expect(result[:root_domain]).to eq('hitting.com')
        expect(result[:domain]).to eq('hitting')
        expect(result[:tld]).to eq('com')
        expect(result[:host]).to eq('hitting.com')
      end

      it 'parses domains with multi-part TLDs' do
        result = described_class.parse('https://subdomain.example.co.uk')

        expect(result[:subdomain]).to eq('subdomain')
        expect(result[:root_domain]).to eq('example.co.uk')
        expect(result[:domain]).to eq('example')
        expect(result[:tld]).to eq('co.uk')
        expect(result[:host]).to eq('subdomain.example.co.uk')
      end

      it 'parses domains with multiple subdomain levels' do
        result = described_class.parse('https://api.staging.example.com')

        expect(result[:subdomain]).to eq('api.staging')
        expect(result[:root_domain]).to eq('example.com')
        expect(result[:domain]).to eq('example')
        expect(result[:tld]).to eq('com')
        expect(result[:host]).to eq('api.staging.example.com')
      end

      it 'handles URLs with ports' do
        result = described_class.parse('https://www.example.com:8080/path')

        expect(result[:subdomain]).to eq('www')
        expect(result[:root_domain]).to eq('example.com')
        expect(result[:domain]).to eq('example')
        expect(result[:tld]).to eq('com')
        expect(result[:host]).to eq('www.example.com')
      end

      it 'handles URLs with query parameters' do
        result = described_class.parse('https://example.com/page?param=value')

        expect(result[:subdomain]).to be_nil
        expect(result[:root_domain]).to eq('example.com')
        expect(result[:domain]).to eq('example')
        expect(result[:tld]).to eq('com')
        expect(result[:host]).to eq('example.com')
        expect(result[:path]).to eq('/page')
        expect(result[:query_params]).to eq({ 'param' => 'value' })
      end

      it 'extracts path from URLs' do
        result = described_class.parse('https://example.com/path/to/page')

        expect(result[:path]).to eq('/path/to/page')
        expect(result[:query_params]).to eq({})
      end

      it 'extracts multiple query parameters' do
        result = described_class.parse('https://example.com/page?foo=bar&baz=qux&id=123')

        expect(result[:query_params]).to eq(
          'foo' => 'bar',
          'baz' => 'qux',
          'id' => '123'
        )
      end

      it 'handles URLs with path and multiple query parameters' do
        result = described_class.parse('https://api.example.com/v1/users?page=2&limit=10')

        expect(result[:subdomain]).to eq('api')
        expect(result[:root_domain]).to eq('example.com')
        expect(result[:path]).to eq('/v1/users')
        expect(result[:query_params]).to eq(
          'page' => '2',
          'limit' => '10'
        )
      end

      it 'handles URLs with empty query string' do
        result = described_class.parse('https://example.com/page?')

        expect(result[:path]).to eq('/page')
        expect(result[:query_params]).to eq({})
      end

      it 'handles URLs without path (root)' do
        result = described_class.parse('https://example.com')

        expect(result[:path]).to eq('')
        expect(result[:query_params]).to eq({})
      end

      it 'handles query parameters with empty values' do
        result = described_class.parse('https://example.com?key=')

        expect(result[:query_params]).to eq({ 'key' => nil })
      end

      it 'handles query parameters without values' do
        result = described_class.parse('https://example.com?flag')

        expect(result[:query_params]).to eq({ 'flag' => nil })
      end

      it 'normalizes URLs without a scheme' do
        result = described_class.parse('example.com/path?id=1')

        expect(result[:root_domain]).to eq('example.com')
        expect(result[:path]).to eq('/path')
        expect(result[:query_params]).to eq({ 'id' => '1' })
      end
    end

    context 'with invalid URLs' do
      let(:invalid_inputs) { ['http://', 'not_a_url', '192.168.1.1', '[2001:db8::1]', '', nil] }

      it 'returns an invalid ParsedURL that safely yields nil values' do
        invalid_inputs.each do |input|
          result = described_class.parse(input)

          expect(result).to be_a(DomainExtractor::ParsedURL)
          expect(result.valid?).to be(false)
          expect(result.domain).to be_nil
          expect(result.domain?).to be(false)
          expect(result.host).to be_nil
          expect(result.host?).to be(false)
        end
      end

      it 'allows bang accessors to raise explicit errors' do
        result = described_class.parse('not_a_url')

        expect { result.domain! }.to raise_error(
          DomainExtractor::InvalidURLError,
          'domain not found or invalid'
        )

        expect { result.host! }.to raise_error(
          DomainExtractor::InvalidURLError,
          'host not found or invalid'
        )
      end

      it 'provides strict parsing via parse!' do
        invalid_inputs.each do |input|
          expect { described_class.parse!(input) }.to raise_error(
            DomainExtractor::InvalidURLError,
            'Invalid URL Value'
          )
        end
      end
    end
  end

  describe '.valid?' do
    it 'returns true for a normalized domain' do
      expect(described_class.valid?('dashtrack.com')).to be(true)
    end

    it 'returns true for a full URL with subdomain and query' do
      expect(described_class.valid?('https://www.example.co.uk/path?query=value')).to be(true)
    end

    it 'returns false for malformed URLs' do
      expect(described_class.valid?('http://')).to be(false)
    end

    it 'returns false for invalid domains' do
      expect(described_class.valid?('not_a_url')).to be(false)
    end

    it 'returns false for IP addresses' do
      expect(described_class.valid?('192.168.1.1')).to be(false)
    end

    it 'returns false for nil values' do
      expect(described_class.valid?(nil)).to be(false)
    end
  end

  describe '.parse_query_params' do
    it 'converts simple query string to hash' do
      result = described_class.parse_query_params('foo=bar')

      expect(result).to eq({ 'foo' => 'bar' })
    end

    it 'converts multiple parameters to hash' do
      result = described_class.parse_query_params('foo=bar&baz=qux&id=123')

      expect(result).to eq(
        'foo' => 'bar',
        'baz' => 'qux',
        'id' => '123'
      )
    end

    it 'returns empty hash for nil query' do
      result = described_class.parse_query_params(nil)

      expect(result).to eq({})
    end

    it 'returns empty hash for empty string query' do
      result = described_class.parse_query_params('')

      expect(result).to eq({})
    end

    it 'handles parameters with empty values' do
      result = described_class.parse_query_params('key=')

      expect(result).to eq({ 'key' => nil })
    end

    it 'handles parameters without values' do
      result = described_class.parse_query_params('flag')

      expect(result).to eq({ 'flag' => nil })
    end

    it 'handles mixed parameters with and without values' do
      result = described_class.parse_query_params('foo=bar&flag&baz=qux')

      expect(result).to eq(
        'foo' => 'bar',
        'flag' => nil,
        'baz' => 'qux'
      )
    end

    it 'ignores blank keys' do
      result = described_class.parse_query_params('=value&foo=bar')

      expect(result).to eq({ 'foo' => 'bar' })
    end
  end

  describe '.parse_batch' do
    it 'parses multiple URLs' do
      urls = [
        'dashtrack.com',
        'www.insurancesite.ai',
        'https://hitting.com/index',
        'aninvalidurl',
        ''
      ]

      results = described_class.parse_batch(urls)

      expect(results[0][:root_domain]).to eq('dashtrack.com')
      expect(results[0][:subdomain]).to be_nil

      expect(results[1][:root_domain]).to eq('insurancesite.ai')
      expect(results[1][:subdomain]).to eq('www')

      expect(results[2][:root_domain]).to eq('hitting.com')
      expect(results[2][:subdomain]).to be_nil

      expect(results[3]).to be_nil
      expect(results[4]).to be_nil
    end

    it 'handles all invalid URLs' do
      results = described_class.parse_batch(['invalid', '', nil])

      expect(results).to all(be_nil)
    end

    it 'handles all valid URLs' do
      urls = ['example.com', 'www.example.com', 'api.example.com']

      results = described_class.parse_batch(urls)

      expect(results).to all(be_a(DomainExtractor::ParsedURL))
      expect(results.map { |result| result[:root_domain] }).to all(eq('example.com'))
    end

    it 'returns empty array for non-enumerable inputs' do
      expect(described_class.parse_batch(nil)).to eq([])
    end
  end
end
