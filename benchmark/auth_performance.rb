# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark/ips'
require 'uri'
require_relative '../lib/domain_extractor'

puts "Ruby Version: #{RUBY_VERSION}"
puts 'DomainExtractor Auth Performance Benchmarks'
puts '=' * 80
puts

# Sample URLs for benchmarking
SIMPLE_URL = 'https://example.com/path'
AUTH_URL = 'https://user:password@example.com/path'
REDIS_URL = 'redis://default:my_password@localhost:6379/0'
POSTGRES_URL = 'postgresql://dbuser:dbpass@db.example.com:5432/production'
COMPLEX_AUTH_URL = 'https://user%40email.com:P%40ss%3Aword@api.example.com:8443/v1/endpoint?key=value#section'

puts 'Benchmark 1: URL Parsing (DomainExtractor vs URI)'
puts '-' * 80

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('DomainExtractor: Simple URL') do
    DomainExtractor.parse(SIMPLE_URL)
  end

  x.report('URI: Simple URL') do
    URI.parse(SIMPLE_URL)
  end

  x.report('DomainExtractor: Auth URL') do
    DomainExtractor.parse(AUTH_URL)
  end

  x.report('URI: Auth URL') do
    URI.parse(AUTH_URL)
  end

  x.compare!
end

puts "\nBenchmark 2: Auth Component Extraction"
puts '-' * 80

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('DomainExtractor: Extract user/password') do
    result = DomainExtractor.parse(AUTH_URL)
    result.user
    result.password
  end

  x.report('URI: Extract user/password') do
    uri = URI.parse(AUTH_URL)
    uri.user
    uri.password
  end

  x.report('DomainExtractor: Decoded credentials') do
    result = DomainExtractor.parse(COMPLEX_AUTH_URL)
    result.decoded_user
    result.decoded_password
  end

  x.compare!
end

puts "\nBenchmark 3: Database URL Parsing"
puts '-' * 80

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('DomainExtractor: Redis URL') do
    DomainExtractor.parse(REDIS_URL)
  end

  x.report('URI: Redis URL') do
    URI.parse(REDIS_URL)
  end

  x.report('DomainExtractor: PostgreSQL URL') do
    DomainExtractor.parse(POSTGRES_URL)
  end

  x.report('URI: PostgreSQL URL') do
    URI.parse(POSTGRES_URL)
  end

  x.compare!
end

puts "\nBenchmark 4: Authentication Helpers"
puts '-' * 80

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('Basic Auth Header Generation') do
    DomainExtractor.basic_auth_header('username', 'password')
  end

  x.report('Bearer Token Header Generation') do
    DomainExtractor.bearer_auth_header('eyJhbGciOiJIUzI1NiIs...')
  end

  x.report('Credential Encoding') do
    DomainExtractor.encode_credential('P@ss:word!')
  end

  x.report('Credential Decoding') do
    DomainExtractor.decode_credential('P%40ss%3Aword%21')
  end

  x.compare!
end

puts "\nBenchmark 5: Complete Auth Workflow"
puts '-' * 80

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('DomainExtractor: Parse + Extract + Header') do
    result = DomainExtractor.parse(AUTH_URL)
    result.basic_auth_header
  end

  x.report('URI: Parse + Extract + Manual Base64') do
    uri = URI.parse(AUTH_URL)
    require 'base64'
    credentials = "#{uri.user}:#{uri.password}"
    "Basic #{Base64.strict_encode64(credentials)}"
  end

  x.compare!
end

puts "\nBenchmark 6: Batch Processing"
puts '-' * 80

BATCH_URLS = [
  'https://example.com',
  'redis://localhost:6379',
  'postgresql://user:pass@db.local:5432/app',
  'https://user:pass@api.example.com',
  'mysql://root:password@localhost:3306/database'
].freeze

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('DomainExtractor: Batch parse') do
    DomainExtractor.parse_batch(BATCH_URLS)
  end

  x.report('URI: Batch parse') do
    BATCH_URLS.map do |url|
      URI.parse(url)
    rescue StandardError
      nil
    end
  end

  x.compare!
end

puts "\n#{'=' * 80}"
puts 'Benchmark Complete!'
puts '=' * 80
