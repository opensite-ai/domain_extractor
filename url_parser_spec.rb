# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UrlParser do
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

        expect(result[:query_params]).to eq({
          'foo' => 'bar',
          'baz' => 'qux',
          'id' => '123'
        })
      end

      it 'handles URLs with path and multiple query parameters' do
        result = described_class.parse('https://api.example.com/v1/users?page=2&limit=10')

        expect(result[:subdomain]).to eq('api')
        expect(result[:root_domain]).to eq('example.com')
        expect(result[:path]).to eq('/v1/users')
        expect(result[:query_params]).to eq({
          'page' => '2',
          'limit' => '10'
        })
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

      it 'returns nil subdomain instead of empty string' do
        result = described_class.parse('https://example.com/page')

        expect(result[:subdomain]).to be_nil
      end
    end

    context 'with invalid URLs' do
      it 'returns nil for invalid URL' do
        result = described_class.parse('aninvalidurl')

        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = described_class.parse('')

        expect(result).to be_nil
      end

      it 'returns nil for nil input' do
        result = described_class.parse(nil)

        expect(result).to be_nil
      end

      it 'returns nil for malformed URLs' do
        result = described_class.parse('http://')

        expect(result).to be_nil
      end

      it 'returns nil for IP addresses' do
        result = described_class.parse('192.168.1.1')

        expect(result).to be_nil
      end
    end
  end

  describe '.query_to_hash' do
    it 'converts simple query string to hash' do
      result = described_class.query_to_hash('foo=bar')

      expect(result).to eq({ 'foo' => 'bar' })
    end

    it 'converts multiple parameters to hash' do
      result = described_class.query_to_hash('foo=bar&baz=qux&id=123')

      expect(result).to eq({
        'foo' => 'bar',
        'baz' => 'qux',
        'id' => '123'
      })
    end

    it 'returns empty hash for nil query' do
      result = described_class.query_to_hash(nil)

      expect(result).to eq({})
    end

    it 'returns empty hash for empty string query' do
      result = described_class.query_to_hash('')

      expect(result).to eq({})
    end

    it 'handles parameters with empty values' do
      result = described_class.query_to_hash('key=')

      expect(result).to eq({ 'key' => nil })
    end

    it 'handles parameters without values' do
      result = described_class.query_to_hash('flag')

      expect(result).to eq({ 'flag' => nil })
    end

    it 'handles mixed parameters with and without values' do
      result = described_class.query_to_hash('foo=bar&flag&baz=qux')

      expect(result).to eq({
        'foo' => 'bar',
        'flag' => nil,
        'baz' => 'qux'
      })
    end
  end

  describe '.parse_batch' do
    it 'parses multiple URLs' do
      url_strings = [
        'dashtrack.com',
        'www.insurancesite.ai',
        'https://hitting.com/index',
        'aninvalidurl',
        ''
      ]

      results = described_class.parse_batch(url_strings)

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
      url_strings = ['invalid', '', nil]

      results = described_class.parse_batch(url_strings)

      expect(results).to all(be_nil)
    end

    it 'handles all valid URLs' do
      url_strings = [
        'example.com',
        'www.example.com',
        'api.example.com'
      ]

      results = described_class.parse_batch(url_strings)

      expect(results).to all(be_a(Hash))
      expect(results.map { |r| r[:root_domain] }).to all(eq('example.com'))
    end
  end
end
