# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DomainExtractor::ParsedURL do
  describe 'method accessor styles' do
    context 'with a valid URL with subdomain' do
      let(:parsed) { DomainExtractor.parse('https://api.dashtrack.com/path?query=value') }

      describe 'default accessor methods' do
        it 'returns subdomain' do
          expect(parsed.subdomain).to eq('api')
        end

        it 'returns domain' do
          expect(parsed.domain).to eq('dashtrack')
        end

        it 'returns tld' do
          expect(parsed.tld).to eq('com')
        end

        it 'returns root_domain' do
          expect(parsed.root_domain).to eq('dashtrack.com')
        end

        it 'returns host' do
          expect(parsed.host).to eq('api.dashtrack.com')
        end

        it 'returns path' do
          expect(parsed.path).to eq('/path')
        end

        it 'returns query_params' do
          expect(parsed.query_params).to eq({ 'query' => 'value' })
        end
      end

      describe 'bang (!) accessor methods' do
        it 'returns subdomain!' do
          expect(parsed.subdomain!).to eq('api')
        end

        it 'returns domain!' do
          expect(parsed.domain!).to eq('dashtrack')
        end

        it 'returns tld!' do
          expect(parsed.tld!).to eq('com')
        end

        it 'returns root_domain!' do
          expect(parsed.root_domain!).to eq('dashtrack.com')
        end

        it 'returns host!' do
          expect(parsed.host!).to eq('api.dashtrack.com')
        end
      end

      describe 'question mark (?) accessor methods' do
        it 'returns true for subdomain?' do
          expect(parsed.subdomain?).to be true
        end

        it 'returns true for domain?' do
          expect(parsed.domain?).to be true
        end

        it 'returns true for tld?' do
          expect(parsed.tld?).to be true
        end

        it 'returns true for root_domain?' do
          expect(parsed.root_domain?).to be true
        end

        it 'returns true for host?' do
          expect(parsed.host?).to be true
        end
      end
    end

    context 'with a valid URL without subdomain' do
      let(:parsed) { DomainExtractor.parse('https://dashtrack.com') }

      describe 'default accessor methods for nil subdomain' do
        it 'returns nil for subdomain' do
          expect(parsed.subdomain).to be_nil
        end

        it 'returns domain' do
          expect(parsed.domain).to eq('dashtrack')
        end

        it 'returns host' do
          expect(parsed.host).to eq('dashtrack.com')
        end
      end

      describe 'bang (!) accessor methods with nil subdomain' do
        it 'raises InvalidURLError for subdomain!' do
          expect { parsed.subdomain! }.to raise_error(
            DomainExtractor::InvalidURLError,
            'subdomain not found or invalid'
          )
        end

        it 'returns domain!' do
          expect(parsed.domain!).to eq('dashtrack')
        end
      end

      describe 'question mark (?) accessor methods with nil subdomain' do
        it 'returns false for subdomain?' do
          expect(parsed.subdomain?).to be false
        end

        it 'returns true for domain?' do
          expect(parsed.domain?).to be true
        end

        it 'returns true for host?' do
          expect(parsed.host?).to be true
        end
      end
    end

    context 'with invalid URL' do
      let(:parsed) { DomainExtractor::ParsedURL.new(nil) }

      describe 'default accessor methods' do
        it 'returns nil for subdomain' do
          expect(parsed.subdomain).to be_nil
        end

        it 'returns nil for domain' do
          expect(parsed.domain).to be_nil
        end

        it 'returns nil for host' do
          expect(parsed.host).to be_nil
        end

        it 'returns nil for root_domain' do
          expect(parsed.root_domain).to be_nil
        end
      end

      describe 'bang (!) accessor methods' do
        it 'raises InvalidURLError for host!' do
          expect { parsed.host! }.to raise_error(
            DomainExtractor::InvalidURLError,
            'host not found or invalid'
          )
        end

        it 'raises InvalidURLError for domain!' do
          expect { parsed.domain! }.to raise_error(
            DomainExtractor::InvalidURLError,
            'domain not found or invalid'
          )
        end

        it 'raises InvalidURLError for subdomain!' do
          expect { parsed.subdomain! }.to raise_error(
            DomainExtractor::InvalidURLError,
            'subdomain not found or invalid'
          )
        end
      end

      describe 'question mark (?) accessor methods' do
        it 'returns false for subdomain?' do
          expect(parsed.subdomain?).to be false
        end

        it 'returns false for domain?' do
          expect(parsed.domain?).to be false
        end

        it 'returns false for host?' do
          expect(parsed.host?).to be false
        end

        it 'returns false for root_domain?' do
          expect(parsed.root_domain?).to be false
        end
      end
    end
  end

  describe '#www_subdomain?' do
    it 'returns true when subdomain is www' do
      parsed = DomainExtractor.parse('https://www.dashtrack.com')
      expect(parsed.www_subdomain?).to be true
    end

    it 'returns false when subdomain is not www' do
      parsed = DomainExtractor.parse('https://api.dashtrack.com')
      expect(parsed.www_subdomain?).to be false
    end

    it 'returns false when there is no subdomain' do
      parsed = DomainExtractor.parse('https://dashtrack.com')
      expect(parsed.www_subdomain?).to be false
    end

    it 'returns false for invalid URL' do
      parsed = DomainExtractor::ParsedURL.new(nil)
      expect(parsed.www_subdomain?).to be false
    end
  end

  describe '#valid?' do
    it 'returns true for valid URL' do
      parsed = DomainExtractor.parse('https://dashtrack.com')
      expect(parsed.valid?).to be true
    end

    it 'returns false for invalid URL' do
      parsed = DomainExtractor::ParsedURL.new(nil)
      expect(parsed.valid?).to be false
    end

    it 'returns false for empty result' do
      parsed = DomainExtractor::ParsedURL.new({})
      expect(parsed.valid?).to be false
    end
  end

  describe 'hash-style access for backward compatibility' do
    let(:parsed) { DomainExtractor.parse('https://www.example.co.uk/path?query=value') }

    it 'supports hash-style access with []' do
      expect(parsed[:subdomain]).to eq('www')
      expect(parsed[:domain]).to eq('example')
      expect(parsed[:tld]).to eq('co.uk')
      expect(parsed[:root_domain]).to eq('example.co.uk')
      expect(parsed[:host]).to eq('www.example.co.uk')
      expect(parsed[:path]).to eq('/path')
    end
  end

  describe '#to_h and #to_hash' do
    let(:parsed) { DomainExtractor.parse('https://api.example.com') }

    it 'converts to hash with to_h' do
      hash = parsed.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:subdomain]).to eq('api')
      expect(hash[:domain]).to eq('example')
    end

    it 'converts to hash with to_hash' do
      hash = parsed.to_hash
      expect(hash).to be_a(Hash)
      expect(hash[:subdomain]).to eq('api')
      expect(hash[:domain]).to eq('example')
    end
  end

  describe 'integration examples from requirements' do
    it 'handles example: DomainExtractor.parse(url).host' do
      url = 'https://www.example.co.uk/path?query=value'
      expect(DomainExtractor.parse(url).host).to eq('www.example.co.uk')
    end

    it 'handles example: DomainExtractor.parse(url).domain' do
      url = 'https://www.example.co.uk/path?query=value'
      expect(DomainExtractor.parse(url).domain).to eq('example')
    end

    it 'handles example: DomainExtractor.parse(url).subdomain' do
      url = 'https://www.example.co.uk/path?query=value'
      expect(DomainExtractor.parse(url).subdomain).to eq('www')
    end

    it 'handles example: no subdomain returns false' do
      expect(DomainExtractor.parse('https://dashtrack.com').subdomain?).to be false
    end

    it 'handles example: with subdomain returns true' do
      expect(DomainExtractor.parse('https://api.dashtrack.com').subdomain?).to be true
    end

    it 'handles example: www_subdomain? returns true for www' do
      expect(DomainExtractor.parse('https://www.dashtrack.com').www_subdomain?).to be true
    end

    it 'handles example: www_subdomain? returns false for non-www' do
      expect(DomainExtractor.parse('https://dashtrack.com').www_subdomain?).to be false
    end

    it 'handles example: host returns value for valid URL' do
      expect(DomainExtractor.parse('https://api.dashtrack.com').host).to eq('api.dashtrack.com')
    end

    it 'handles example: domain returns nil for invalid URL' do
      # Parser returns ParsedURL with empty result for invalid URLs
      # But parse() raises error, so we need to construct directly
      parsed = DomainExtractor::ParsedURL.new(nil)
      expect(parsed.domain).to be_nil
    end
  end

  describe 'edge cases' do
    context 'with multi-part TLD' do
      let(:parsed) { DomainExtractor.parse('shop.example.com.au') }

      it 'correctly identifies subdomain' do
        expect(parsed.subdomain).to eq('shop')
      end

      it 'correctly identifies tld' do
        expect(parsed.tld).to eq('com.au')
      end

      it 'subdomain? returns true' do
        expect(parsed.subdomain?).to be true
      end
    end

    context 'with nested subdomains' do
      let(:parsed) { DomainExtractor.parse('api.staging.example.com') }

      it 'returns nested subdomain' do
        expect(parsed.subdomain).to eq('api.staging')
      end

      it 'subdomain? returns true' do
        expect(parsed.subdomain?).to be true
      end

      it 'subdomain! returns the value' do
        expect(parsed.subdomain!).to eq('api.staging')
      end
    end

    context 'with empty path' do
      let(:parsed) { DomainExtractor.parse('https://example.com') }

      it 'returns empty string for path' do
        expect(parsed.path).to eq('')
      end

      it 'path? returns false for empty path' do
        expect(parsed.path?).to be false
      end
    end

    context 'with query params' do
      let(:parsed) { DomainExtractor.parse('https://example.com?foo=bar&baz=qux') }

      it 'returns query_params hash' do
        expect(parsed.query_params).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
      end

      it 'query_params? returns true' do
        expect(parsed.query_params?).to be true
      end

      it 'query_params! returns the hash' do
        expect(parsed.query_params!).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
      end
    end

    context 'with empty query params' do
      let(:parsed) { DomainExtractor.parse('https://example.com') }

      it 'returns empty hash for query_params' do
        expect(parsed.query_params).to eq({})
      end

      it 'query_params? returns false for empty hash' do
        expect(parsed.query_params?).to be false
      end
    end
  end

  describe '#respond_to_missing?' do
    let(:parsed) { DomainExtractor.parse('https://api.example.com') }

    it 'responds to valid accessor methods' do
      expect(parsed).to respond_to(:host)
      expect(parsed).to respond_to(:domain)
      expect(parsed).to respond_to(:subdomain)
    end

    it 'responds to bang methods' do
      expect(parsed).to respond_to(:host!)
      expect(parsed).to respond_to(:domain!)
      expect(parsed).to respond_to(:subdomain!)
    end

    it 'responds to question mark methods' do
      expect(parsed).to respond_to(:host?)
      expect(parsed).to respond_to(:domain?)
      expect(parsed).to respond_to(:subdomain?)
    end

    it 'responds to www_subdomain?' do
      expect(parsed).to respond_to(:www_subdomain?)
    end

    it 'does not respond to invalid methods' do
      expect(parsed).not_to respond_to(:invalid_method)
      expect(parsed).not_to respond_to(:not_a_real_method!)
    end
  end

  describe '#inspect' do
    it 'provides meaningful inspection output' do
      parsed = DomainExtractor.parse('https://api.example.com')
      output = parsed.inspect
      expect(output).to include('DomainExtractor::ParsedURL')
      expect(output).to include('subdomain')
      expect(output).to include('api')
    end
  end
end
