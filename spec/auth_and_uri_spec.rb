# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Auth Extraction and URI Features' do
  describe 'Redis URL parsing' do
    it 'parses Redis URL with username and password' do
      url = 'redis://username:password@localhost:6379/0'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('redis')
      expect(result.user).to eq('username')
      expect(result.password).to eq('password')
      expect(result.host).to eq('localhost')
      expect(result.port).to eq(6379)
      expect(result.path).to eq('/0')
    end

    it 'parses Redis URL with password only (no username)' do
      url = 'redis://:my_password@localhost:6379/0'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.user).to be_nil
      expect(result.password).to eq('my_password')
      expect(result.userinfo).to eq(':my_password')
    end

    it 'parses Rediss (SSL) URL' do
      url = 'rediss://default:my_secret_pw@redissubdomain.dragonflydb.cloud:6385'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(DomainExtractor.valid?(url)).to be(true)
      expect(result.scheme).to eq('rediss')
      expect(result.user).to eq('default')
      expect(result.password).to eq('my_secret_pw')
      expect(result.host).to eq('redissubdomain.dragonflydb.cloud')
      expect(result.port).to eq(6385)
    end

    it 'parses Redis URL with special characters in password' do
      url = 'redis://user:P%40ss%3Aword@localhost:6379'
      result = DomainExtractor.parse(url)

      expect(result.password).to eq('P%40ss%3Aword')
      expect(result.decoded_password).to eq('P@ss:word')
    end
  end

  describe 'Database URL parsing' do
    it 'parses PostgreSQL URL' do
      url = 'postgresql://janedoe:mypassword@localhost:5432/mydb'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('postgresql')
      expect(result.user).to eq('janedoe')
      expect(result.password).to eq('mypassword')
      expect(result.host).to eq('localhost')
      expect(result.port).to eq(5432)
      expect(result.path).to eq('/mydb')
    end

    it 'parses MySQL URL' do
      # Password with @ must be percent-encoded
      url = 'mysql://webapp:P%40ssw0rd@db-server.example.com:3306/app_database'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('mysql')
      expect(result.user).to eq('webapp')
      expect(result.password).to eq('P%40ssw0rd')
      expect(result.decoded_password).to eq('P@ssw0rd')
      expect(result.host).to eq('db-server.example.com')
      expect(result.port).to eq(3306)
    end

    it 'parses MongoDB URL' do
      url = 'mongodb+srv://root:password123@cluster0.ab1cd.mongodb.net/myDatabase'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('mongodb+srv')
      expect(result.user).to eq('root')
      expect(result.password).to eq('password123')
    end
  end

  describe 'FTP/SFTP URL parsing' do
    it 'parses FTP URL with credentials' do
      url = 'ftp://ftpuser:ftppass@ftp.example.com/path/to/file'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('ftp')
      expect(result.user).to eq('ftpuser')
      expect(result.password).to eq('ftppass')
      expect(result.host).to eq('ftp.example.com')
      # FTP paths may not include leading slash depending on URI parsing
      expect(result.path).to match(%r{^/?path/to/file$})
    end

    it 'parses SFTP URL' do
      url = 'sftp://deploy_user:DeployKey123@deployment.internal:22/var/www/app'
      result = DomainExtractor.parse(url)

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('sftp')
      expect(result.user).to eq('deploy_user')
      expect(result.password).to eq('DeployKey123')
      expect(result.port).to eq(22)
    end
  end

  describe 'Special character handling in credentials' do
    it 'handles @ symbol in username' do
      url = 'https://user%40domain.com:password@example.com'
      result = DomainExtractor.parse(url)

      expect(result.user).to eq('user%40domain.com')
      expect(result.decoded_user).to eq('user@domain.com')
    end

    it 'handles colon in password' do
      url = 'https://user:Pass%3Aword@example.com'
      result = DomainExtractor.parse(url)

      expect(result.password).to eq('Pass%3Aword')
      expect(result.decoded_password).to eq('Pass:word')
    end

    it 'handles multiple special characters in password' do
      url = 'https://user:P%40%24%24w0rd%21@example.com'
      result = DomainExtractor.parse(url)

      expect(result.password).to eq('P%40%24%24w0rd%21')
      expect(result.decoded_password).to eq('P@$$w0rd!')
    end

    it 'handles empty password' do
      url = 'https://user:@example.com'
      result = DomainExtractor.parse(url)

      expect(result.user).to eq('user')
      expect(result.password).to eq('')
    end

    it 'handles username only (no password)' do
      url = 'https://user@example.com'
      result = DomainExtractor.parse(url)

      expect(result.user).to eq('user')
      expect(result.password).to be_nil
    end
  end

  describe 'Authentication helper methods' do
    it 'generates Basic Auth header from credentials' do
      url = 'https://researcher:secure_pwd123@api.example.com'
      result = DomainExtractor.parse(url)

      header = result.basic_auth_header
      expect(header).to start_with('Basic ')

      # Verify it's properly base64 encoded
      encoded_part = header.sub('Basic ', '')
      decoded = Base64.strict_decode64(encoded_part)
      expect(decoded).to eq('researcher:secure_pwd123')
    end

    it 'generates Basic Auth header using module method' do
      header = DomainExtractor.basic_auth_header('user', 'pass')
      expect(header).to start_with('Basic ')

      encoded_part = header.sub('Basic ', '')
      decoded = Base64.strict_decode64(encoded_part)
      expect(decoded).to eq('user:pass')
    end

    it 'generates Bearer token header' do
      token = 'eyJhbGciOiJIUzI1NiIs...'
      header = DomainExtractor.bearer_auth_header(token)

      expect(header).to eq("Bearer #{token}")
    end

    it 'encodes credentials for URL use' do
      password = 'P@ss:word\!'
      encoded = DomainExtractor.encode_credential(password)

      expect(encoded).to eq('P%40ss%3Aword%5C%21')
    end

    it 'decodes percent-encoded credentials' do
      encoded = 'P%40ss%3Aword%21'
      decoded = DomainExtractor.decode_credential(encoded)

      expect(decoded).to eq('P@ss:word!')
    end

    it 'encodes spaces as %20 and preserves literal plus signs' do
      encoded = DomainExtractor.encode_credential('a+b c')

      expect(encoded).to eq('a%2Bb%20c')
      expect(DomainExtractor.decode_credential(encoded)).to eq('a+b c')
    end
  end

  describe 'URI component accessors' do
    it 'provides scheme accessor' do
      result = DomainExtractor.parse('https://example.com')
      expect(result.scheme).to eq('https')
    end

    it 'provides port accessor' do
      result = DomainExtractor.parse('https://example.com:8443')
      expect(result.port).to eq(8443)
    end

    it 'provides fragment accessor' do
      result = DomainExtractor.parse('https://example.com/page#section')
      expect(result.fragment).to eq('section')
    end

    it 'provides hostname (without IPv6 brackets)' do
      result = DomainExtractor.parse('https://example.com')
      expect(result.hostname).to eq('example.com')
    end

    it 'provides query string reconstruction' do
      result = DomainExtractor.parse('https://example.com?foo=bar&baz=qux')
      expect(result.query).to include('foo=bar')
      expect(result.query).to include('baz=qux')
    end
  end

  describe 'URI manipulation methods' do
    it 'checks if URI is absolute' do
      result = DomainExtractor.parse('https://example.com')
      expect(result.absolute?).to be(true)
    end

    it 'checks if URI is relative' do
      result = DomainExtractor.parse('example.com')
      expect(result.relative?).to be(false) # We normalize to https://
    end

    it 'provides default port for scheme' do
      https_result = DomainExtractor.parse('https://example.com')
      expect(https_result.default_port).to eq(443)

      http_result = DomainExtractor.parse('http://example.com')
      expect(http_result.default_port).to eq(80)

      redis_result = DomainExtractor.parse('redis://localhost')
      expect(redis_result.default_port).to eq(6379)

      postgres_result = DomainExtractor.parse('postgresql://db.example.com/app')
      expect(postgres_result.default_port).to eq(5432)

      mysql_result = DomainExtractor.parse('mysql://db.example.com/app')
      expect(mysql_result.default_port).to eq(3306)
    end

    it 'preserves the raw query string and duplicate keys' do
      result = DomainExtractor.parse('https://example.com/path?foo=bar&foo=baz&empty=#frag')

      expect(result.query).to eq('foo=bar&foo=baz&empty=')
      expect(result.to_s).to eq('https://example.com/path?foo=bar&foo=baz&empty=#frag')
      expect(result.to_str).to eq(result.to_s)
    end

    it 'normalizes scheme and host while keeping URI-compatible port behavior' do
      normalized = DomainExtractor.parse('HTTP://EXAMPLE.COM:80/Path').normalize

      expect(normalized.to_s).to eq('http://example.com/Path')
      expect(normalized.scheme).to eq('http')
      expect(normalized.host).to eq('example.com')
      expect(normalized.port).to eq(80)
    end

    it 'merges relative paths using URI semantics' do
      base = DomainExtractor.parse('https://example.com/api/v1/')
      merged = base.merge('users/123')

      expect(merged.to_s).to eq('https://example.com/api/v1/users/123')
      expect(merged.path).to eq('/api/v1/users/123')
    end

    it 'builds a URL string from the current URI state' do
      result = DomainExtractor.parse('https://user:pass@example.com:8443/path?foo=bar#frag')

      expect(result.build_url).to eq('https://user:pass@example.com:8443/path?foo=bar#frag')
    end
  end

  describe 'URI setters' do
    it 'updates core URI components and keeps query params in sync' do
      result = DomainExtractor.parse('http://example.com')

      result.scheme = 'https'
      result.host = 'api.secure.example.co.uk'
      result.port = 8443
      result.path = '/v1/users'
      result.query = 'page=2&empty='
      result.fragment = 'results'

      expect(result.scheme).to eq('https')
      expect(result.host).to eq('api.secure.example.co.uk')
      expect(result.subdomain).to eq('api.secure')
      expect(result.root_domain).to eq('example.co.uk')
      expect(result.port).to eq(8443)
      expect(result.path).to eq('/v1/users')
      expect(result.query).to eq('page=2&empty=')
      expect(result.query_params).to eq({ 'page' => '2', 'empty' => nil })
      expect(result.fragment).to eq('results')
      expect(result.to_s).to eq('https://api.secure.example.co.uk:8443/v1/users?page=2&empty=#results')
    end

    it 'preserves authentication when the host changes' do
      result = DomainExtractor.parse('https://user:pass@example.com')

      result.host = 'api.example.com'

      expect(result.user).to eq('user')
      expect(result.password).to eq('pass')
      expect(result.to_s).to eq('https://user:pass@api.example.com')
    end

    it 'updates auth-derived fields when userinfo changes' do
      result = DomainExtractor.parse('https://example.com')

      result.userinfo = 'deploy%40site.com:secret%3Avalue'

      expect(result.user).to eq('deploy%40site.com')
      expect(result.password).to eq('secret%3Avalue')
      expect(result.decoded_user).to eq('deploy@site.com')
      expect(result.decoded_password).to eq('secret:value')
      expect(result.basic_auth_header).to eq('Basic ZGVwbG95QHNpdGUuY29tOnNlY3JldDp2YWx1ZQ==')
      expect(result.to_s).to eq('https://deploy%40site.com:secret%3Avalue@example.com')
    end
  end

  describe 'Proxy detection' do
    around do |example|
      proxy_keys = %w[http_proxy HTTP_PROXY https_proxy HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY]
      previous_env = proxy_keys.to_h { |key| [key, ENV.fetch(key, nil)] }

      begin
        proxy_keys.each { |key| ENV.delete(key) }
        example.run
      ensure
        previous_env.each do |key, value|
          value.nil? ? ENV.delete(key) : ENV[key] = value
        end
      end
    end

    it 'prefers the scheme-specific proxy when available' do
      ENV['https_proxy'] = 'http://secure-proxy.internal:8443'

      result = DomainExtractor.parse('https://api.example.com')

      expect(result.find_proxy.to_s).to eq('http://secure-proxy.internal:8443')
    end

    it 'respects no_proxy exclusions' do
      ENV['https_proxy'] = 'http://secure-proxy.internal:8443'
      ENV['no_proxy'] = 'api.example.com'

      result = DomainExtractor.parse('https://api.example.com')

      expect(result.find_proxy).to be_nil
    end

    it 'falls back to http_proxy for custom schemes' do
      ENV['http_proxy'] = 'http://fallback-proxy.internal:8080'

      result = DomainExtractor.parse('redis://localhost:6379/0')

      expect(result.find_proxy.to_s).to eq('http://fallback-proxy.internal:8080')
    end
  end

  describe 'Backward compatibility' do
    it 'maintains hash-style access' do
      url = 'https://user:pass@example.com:8080/path?query=value#fragment'
      result = DomainExtractor.parse(url)

      expect(result[:host]).to eq('example.com')
      expect(result[:path]).to eq('/path')
      expect(result[:domain]).to eq('example')
    end

    it 'maintains method-style access for original fields' do
      url = 'https://www.example.com/path'
      result = DomainExtractor.parse(url)

      expect(result.subdomain).to eq('www')
      expect(result.domain).to eq('example')
      expect(result.tld).to eq('com')
      expect(result.root_domain).to eq('example.com')
    end

    it 'maintains to_h conversion' do
      url = 'https://user:pass@example.com'
      result = DomainExtractor.parse(url)
      hash = result.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:user]).to eq('user')
      expect(hash[:password]).to eq('pass')
    end
  end

  describe 'Edge cases' do
    it 'keeps internal database hosts valid' do
      result = DomainExtractor.parse('postgresql://appuser:SecurePass@db.prod.internal:5432/production')

      expect(result.valid?).to be(true)
      expect(result.scheme).to eq('postgresql')
      expect(result.host).to eq('db.prod.internal')
      expect(result.subdomain).to eq('db')
      expect(result.domain).to eq('prod')
      expect(result.root_domain).to eq('prod.internal')
      expect(result.tld).to eq('internal')
    end

    it 'handles URLs without auth' do
      result = DomainExtractor.parse('https://example.com')

      expect(result.user).to be_nil
      expect(result.password).to be_nil
      expect(result.userinfo).to be_nil
    end

    it 'handles invalid URLs gracefully' do
      result = DomainExtractor.parse(':::invalid:::')

      expect(result.valid?).to be(false)
      expect(result.user).to be_nil
      expect(result.password).to be_nil
    end

    it 'handles nil input' do
      result = DomainExtractor.parse(nil)

      expect(result.valid?).to be(false)
      expect(result.user).to be_nil
    end
  end
end
