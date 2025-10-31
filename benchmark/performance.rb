#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require_relative '../lib/domain_extractor'

# Test URLs covering different scenarios
test_urls = [
  'example.com',
  'www.example.com',
  'https://example.com',
  'https://blog.example.co.uk',
  'https://api.staging.example.com',
  'https://example.com/path/to/page',
  'https://example.com/path?query=1&foo=bar',
  'https://user:pass@example.com:8080/path?query=1',
  'https://example.co.uk',
  'https://example.com.au',
  '192.168.1.1',
  'localhost:3000'
]

puts 'Domain Extractor Performance Benchmark'
puts '=' * 60
puts

# Single URL benchmarks
puts 'Single URL Parsing (1000 iterations per URL)'
puts '-' * 60

test_urls.each do |url|
  time = Benchmark.realtime do
    1000.times { DomainExtractor.parse(url) }
  end

  avg_time = (time / 1000.0) * 1_000_000 # convert to microseconds
  puts "#{url.ljust(45)} #{avg_time.round(2)}μs"
end

puts
puts 'Batch Processing Performance'
puts '-' * 60

[100, 1_000, 10_000].each do |count|
  urls = test_urls.cycle.take(count)

  time = Benchmark.realtime do
    DomainExtractor.parse_batch(urls)
  end

  throughput = count / time
  puts "#{count.to_s.rjust(6)} URLs: #{time.round(4)}s (#{throughput.round(0)} URLs/sec)"
end

puts
puts '=' * 60
puts 'Benchmark Complete'
