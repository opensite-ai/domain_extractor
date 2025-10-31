# DomainExtractor

[![Gem Version](https://badge.fury.io/rb/domain_extractor.svg)](https://badge.fury.io/rb/domain_extractor)
[![CI](https://github.com/opensite-ai/domain_extractor/actions/workflows/ci.yml/badge.svg)](https://github.com/opensite-ai/domain_extractor/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/opensite-ai/domain_extractor/badges/gpa.svg)](https://codeclimate.com/github/opensite-ai/domain_extractor)

A lightweight, robust Ruby library for url parsing and domain parsing with **accurate multi-part TLD support**. DomainExtractor delivers a high-throughput url parser and domain parser that excels at domain extraction tasks while staying friendly to analytics pipelines. Perfect for web scraping, analytics, url manipulation, query parameter parsing, and multi-environment domain analysis.

Use DomainExtractor whenever you need a dependable tld parser for tricky multi-part tld registries or reliable subdomain extraction in production systems.

## Why DomainExtractor?

✅ **Accurate Multi-part TLD Parser** - Handles complex multi-part TLDs (co.uk, com.au, gov.br) using the [Public Suffix List](https://publicsuffix.org/)
✅ **Nested Subdomain Extraction** - Correctly parses multi-level subdomains (api.staging.example.com)
✅ **Smart URL Normalization** - Automatically handles URLs with or without schemes
✅ **Query Parameter Parsing** - Parse query strings into structured hashes
✅ **Batch Processing** - Parse multiple URLs efficiently
✅ **IP Address Detection** - Identifies and handles IPv4 and IPv6 addresses
✅ **Zero Configuration** - Works out of the box with sensible defaults
✅ **Well-Tested** - Comprehensive test suite covering edge cases

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'domain_extractor'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install domain_extractor
```

## Quick Start

```ruby
require 'domain_extractor'

# Parse a URL
result = DomainExtractor.parse('https://www.example.co.uk/path?query=value')

result[:subdomain]    # => 'www'
result[:domain]       # => 'example'
result[:tld]          # => 'co.uk'
result[:root_domain]  # => 'example.co.uk'
result[:host]         # => 'www.example.co.uk'
```

## Usage Examples

### Basic Domain Parsing

```ruby
# Parse a simple domain (fast domain extraction)
DomainExtractor.parse('example.com')
# => { subdomain: nil, domain: 'example', tld: 'com', ... }

# Parse domain with subdomain
DomainExtractor.parse('blog.example.com')
# => { subdomain: 'blog', domain: 'example', tld: 'com', ... }
```

### Multi-Part TLD Support

```ruby
# UK domain
DomainExtractor.parse('www.bbc.co.uk')
# => { subdomain: 'www', domain: 'bbc', tld: 'co.uk', ... }

# Australian domain
DomainExtractor.parse('shop.example.com.au')
# => { subdomain: 'shop', domain: 'example', tld: 'com.au', ... }
```

### Nested Subdomains

```ruby
DomainExtractor.parse('api.staging.example.com')
# => { subdomain: 'api.staging', domain: 'example', tld: 'com', ... }
```

### Query Parameter Parsing

```ruby
params = DomainExtractor.parse_query_params('?utm_source=google&page=1')
# => { 'utm_source' => 'google', 'page' => '1' }

# Or via the shorter helper
DomainExtractor.parse_query('?search=ruby&flag')
# => { 'search' => 'ruby', 'flag' => nil }
```

### Batch URL Processing

```ruby
urls = ['https://example.com', 'https://blog.example.org']
results = DomainExtractor.parse_batch(urls)
```

## API Reference

### `DomainExtractor.parse(url_string)`

Parses a URL string and extracts domain components.

**Returns:** Hash with keys `:subdomain`, `:domain`, `:tld`, `:root_domain`, `:host`, `:path` or `nil`

### `DomainExtractor.parse_batch(urls)`

Parses multiple URLs efficiently.

**Returns:** Array of parsed results

### `DomainExtractor.parse_query_params(query_string)`

Parses a query string into a hash of parameters.

**Returns:** Hash of query parameters

## Use Cases

**Web Scraping**

```ruby
urls = scrape_page_links(page)
domains = urls.map { |url| DomainExtractor.parse(url)&.dig(:root_domain) }.compact.uniq
```

**Analytics & Tracking**

```ruby
referrer = request.referrer
parsed = DomainExtractor.parse(referrer)
track_event('page_view', source_domain: parsed[:root_domain]) if parsed
```

**Domain Validation**

```ruby
def internal_link?(url, base_domain)
  parsed = DomainExtractor.parse(url)
  parsed && parsed[:root_domain] == base_domain
end
```

## Performance

Optimized for high-throughput production use:

- **Single URL parsing**: 15-30μs per URL (50,000+ URLs/second)
- **Batch processing**: 50,000+ URLs/second sustained throughput
- **Memory efficient**: <100KB overhead, ~200 bytes per parse
- **Thread-safe**: Stateless modules, safe for concurrent use
- **Zero-allocation hot paths**: Frozen constants, pre-compiled regex

See [PERFORMANCE.md](https://github.com/opensite-ai/domain_extractor/docs/PERFORMANCE.md) for detailed benchmarks and optimization strategies and benchmark results along with a full set of enhancements made in order to meet the highly performance centric requirements of the OpenSite AI site rendering engine, showcased in the [OPTIMIZATION_SUMMARY.md](https://github.com/opensite-ai/domain_extractor/docs/OPTIMIZATION_SUMMARY.md)

## Comparison with Alternatives

| Feature                     | DomainExtractor | Addressable | URI (stdlib) |
| --------------------------- | --------------- | ----------- | ------------ |
| Multi-part TLD parser       | ✅              | ❌          | ❌           |
| Subdomain extraction        | ✅              | ❌          | ❌           |
| Domain component separation | ✅              | ❌          | ❌           |
| Built-in url normalization  | ✅              | ❌          | ❌           |
| Lightweight                 | ✅              | ❌          | ✅           |

## Requirements

- Ruby 3.0.0 or higher
- public_suffix gem (~> 6.0)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/opensite-ai/domain_extractor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

- Built on Ruby's standard [URI library](https://ruby-doc.org/stdlib/libdoc/uri/rdoc/URI.html)
- Uses the [public_suffix gem](https://github.com/weppos/publicsuffix-ruby) for accurate TLD parsing

---

Made with ❤️ by [OpenSite AI](https://opensite.ai)
