![Domain Extractor and Parsing Ruby Gem](https://github.com/user-attachments/assets/b3fbe605-3a3e-4d45-b0ed-b061a807d61b)

# DomainExtractor

[![Gem Version](https://badge.fury.io/rb/domain_extractor.svg?v=020)](https://badge.fury.io/rb/domain_extractor)
[![CI](https://github.com/opensite-ai/domain_extractor/actions/workflows/ci.yml/badge.svg)](https://github.com/opensite-ai/domain_extractor/actions/workflows/ci.yml)

A lightweight, robust Ruby library for url parsing and domain parsing with **accurate multi-part TLD support**. DomainExtractor delivers a high-throughput url parser and domain parser that excels at domain extraction tasks while staying friendly to analytics pipelines. Perfect for web scraping, analytics, url manipulation, query parameter parsing, and multi-environment domain analysis.

Use **DomainExtractor** whenever you need a dependable tld parser for tricky multi-part tld registries or reliable subdomain extraction in production systems.

## Why DomainExtractor?

✅ **Accurate Multi-part TLD Parser** - Handles complex multi-part TLDs (co.uk, com.au, gov.br) using the [Public Suffix List](https://publicsuffix.org/)
✅ **Nested Subdomain Extraction** - Correctly parses multi-level subdomains (api.staging.example.com)
✅ **Smart URL Normalization** - Automatically handles URLs with or without schemes
✅ **Powerful URL Formatting** - Transform and standardize URLs with flexible options
✅ **Rails Integration** - Custom ActiveModel validator for declarative URL validation
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

# Guard a parse with the validity helper
url = 'https://www.example.co.uk/path?query=value'
if DomainExtractor.valid?(url)
  DomainExtractor.parse(url)
else
  # handle invalid input
end

# New intuitive method-style access
result.subdomain      # => 'www'
result.domain         # => 'example'
result.host           # => 'www.example.co.uk'
```

## ParsedURL API - Intuitive Method Access

DomainExtractor now returns a `ParsedURL` object that supports three accessor styles, making your intent clear and your code more robust:

### Method Accessor Styles

#### 1. Default Methods (Silent Nil)

Returns the value or `nil` - perfect for exploratory code or when handling invalid data gracefully.

```ruby
result = DomainExtractor.parse('https://api.example.com')
result.subdomain    # => 'api'
result.domain       # => 'example'
result.host         # => 'api.example.com'

# Without subdomain
result = DomainExtractor.parse('https://example.com')
result.subdomain    # => nil (no error)
result.domain       # => 'example'
```

#### 2. Bang Methods (!) - Explicit Errors

Returns the value or raises `InvalidURLError` - ideal for production code where missing data should fail fast.

```ruby
result = DomainExtractor.parse('https://example.com')
result.domain!      # => 'example'
result.subdomain!   # raises InvalidURLError: "subdomain not found or invalid"
```

#### 3. Question Methods (?) - Boolean Checks

Always returns `true` or `false` - perfect for conditional logic without exceptions.

```ruby
DomainExtractor.parse('https://dashtrack.com').subdomain?        # => false
DomainExtractor.parse('https://api.dashtrack.com').subdomain?   # => true
DomainExtractor.parse('https://www.dashtrack.com').www_subdomain? # => true
```

### Quick Examples

```ruby
url = 'https://api.staging.example.com/path'
parsed = DomainExtractor.parse(url)

# Method-style access
parsed.host           # => 'api.staging.example.com'
parsed.subdomain      # => 'api.staging'
parsed.domain         # => 'example'
parsed.root_domain    # => 'example.com'
parsed.tld            # => 'com'
parsed.path           # => '/path'

# Question methods for conditionals
if parsed.subdomain?
  puts "Has subdomain: #{parsed.subdomain}"
end

# Bang methods when values are required
begin
  subdomain = parsed.subdomain!  # Safe - has subdomain
  domain = parsed.domain!        # Safe - has domain
rescue DomainExtractor::InvalidURLError => e
  puts "Missing required component: #{e.message}"
end

# Hash-style access still works (backward compatible)
parsed[:subdomain]    # => 'api.staging'
parsed[:host]         # => 'api.staging.example.com'
```

### Additional Examples

#### Boolean Checks with Question Methods

```ruby
# Check for subdomain presence
DomainExtractor.parse('https://dashtrack.com').subdomain?        # => false
DomainExtractor.parse('https://api.dashtrack.com').subdomain?   # => true

# Check for www subdomain specifically
DomainExtractor.parse('https://www.dashtrack.com').www_subdomain? # => true
DomainExtractor.parse('https://api.dashtrack.com').www_subdomain? # => false

```

#### Handling Unknown or Invalid Data

```ruby
# Default accessors fail silently with nil
DomainExtractor.parse(nil).domain                 # => nil
DomainExtractor.parse('').host                    # => nil
DomainExtractor.parse('asdfasdfds').domain        # => nil

# Boolean checks never raise
DomainExtractor.parse(nil).subdomain?             # => false
DomainExtractor.parse('').domain?                 # => false
DomainExtractor.parse('https://dashtrack.com').subdomain? # => false

# Bang methods raise when a component is missing
DomainExtractor.parse('').host!                   # => raises DomainExtractor::InvalidURLError
DomainExtractor.parse('asdfasdfds').domain!       # => raises DomainExtractor::InvalidURLError
```

#### Safe Batch Processing

```ruby
urls = [
  'https://api.example.com',
  'https://example.com',
  'https://www.example.com'
]

urls.each do |url|
  result = DomainExtractor.parse(url)

  info = {
    url: url,
    has_subdomain: result.subdomain?,
    is_www: result.www_subdomain?,
    host: result.host
  }

  puts "#{info[:url]} - subdomain: #{info[:has_subdomain]}, www: #{info[:is_www]}"
end
```

#### Production URL Validation

```ruby
def validate_api_url(url)
  result = DomainExtractor.parse(url)

  # Ensure all required components exist
  result.subdomain!  # Must have subdomain
  result.domain!     # Must have domain

  # Additional validation
  return false unless result.subdomain.start_with?('api')

  true
rescue DomainExtractor::InvalidURLError => e
  puts "Validation failed: #{e.message}"
  false
end

validate_api_url('https://api.example.com/endpoint')  # => true
validate_api_url('https://example.com/endpoint')      # => false (no subdomain)
validate_api_url('https://www.example.com/endpoint')  # => false (not api subdomain)
```

#### Guard Clauses with Question Methods

```ruby
def process_url(url)
  result = DomainExtractor.parse(url)

  return 'Invalid URL' unless result.valid?
  return 'No subdomain present' unless result.subdomain?
  return 'WWW redirect needed' if result.www_subdomain?

  "Processing subdomain: #{result.subdomain}"
end

process_url('https://api.example.com')  # => "Processing subdomain: api"
process_url('https://www.example.com')  # => "WWW redirect needed"
process_url('https://example.com')      # => "No subdomain present"
```

#### Converting to Hash

```ruby
url = 'https://api.example.com/path'
result = DomainExtractor.parse(url)

hash = result.to_h
# => {
#   subdomain: "api",
#   domain: "example",
#   tld: "com",
#   root_domain: "example.com",
#   host: "api.example.com",
#   path: "/path",
#   query_params: {}
# }
```

**[Comprehensive documentation and real-world examples of parsed URL quick start guide](https://github.com/opensite-ai/domain_extractor/blob/master/docs/PARSED_URL_QUICK_START.md)**

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

### Validation and Error Handling

```ruby
DomainExtractor.valid?('https://www.example.com') # => true

# DomainExtractor.parse raises DomainExtractor::InvalidURLError on invalid input
DomainExtractor.parse('not-a-url')
# => raises DomainExtractor::InvalidURLError (message: "Invalid URL Value")
```

## API Reference

```ruby
DomainExtractor.parse(url_string)

# => Parses a URL string and extracts domain components.

# Returns: Hash with keys :subdomain, :domain, :tld, :root_domain, :host, :path
# Raises: DomainExtractor::InvalidURLError when the URL fails validation
```

```ruby
DomainExtractor.parse_batch(urls)

# => Parses multiple URLs efficiently.

# Returns: Array of parsed results
```

```ruby
DomainExtractor.valid?(url_string)

# => Checks if a URL can be parsed successfully without raising.

# Returns: true or false
```

```ruby
DomainExtractor.parse_query_params(query_string)

# => Parses a query string into a hash of parameters.

# Returns: Hash of query parameters
```

```ruby
DomainExtractor.format(url_string, **options)

# => Formats a URL according to the specified options.

# Returns: Formatted URL string or nil if invalid
# Options:
#   :validation (:standard, :root_domain, :root_or_custom_subdomain)
#   :use_protocol (true/false)
#   :use_https (true/false)
#   :use_trailing_slash (true/false)
```

## URL Formatting

DomainExtractor provides powerful URL formatting capabilities to normalize, transform, and standardize URLs according to your application's requirements.

### Basic Formatting

```ruby
# Remove trailing slash (default)
DomainExtractor.format('https://example.com/')
# => 'https://example.com'

# Strip paths and query parameters
DomainExtractor.format('https://example.com/path?query=value')
# => 'https://example.com'

# Normalize to HTTPS
DomainExtractor.format('http://example.com')
# => 'https://example.com'
```

### Validation Modes

#### Standard Mode (Default)

Preserves the full host as-is while normalizing protocol and trailing slashes.

```ruby
DomainExtractor.format('https://shop.example.com')
# => 'https://shop.example.com'

DomainExtractor.format('https://www.example.com/')
# => 'https://www.example.com'

DomainExtractor.format('https://api.staging.example.com')
# => 'https://api.staging.example.com'
```

#### Root Domain Mode

Strips all subdomains and returns only the root domain.

```ruby
DomainExtractor.format('https://shop.example.com', validation: :root_domain)
# => 'https://example.com'

DomainExtractor.format('https://www.example.com/', validation: :root_domain)
# => 'https://example.com'

DomainExtractor.format('https://api.staging.example.com', validation: :root_domain)
# => 'https://example.com'

# Works with multi-part TLDs
DomainExtractor.format('https://shop.example.co.uk', validation: :root_domain)
# => 'https://example.co.uk'
```

#### Root or Custom Subdomain Mode

Preserves custom subdomains but specifically removes the 'www' subdomain.

```ruby
DomainExtractor.format('https://example.com', validation: :root_or_custom_subdomain)
# => 'https://example.com'

DomainExtractor.format('https://shop.example.com', validation: :root_or_custom_subdomain)
# => 'https://shop.example.com'

# Strips www subdomain
DomainExtractor.format('https://www.example.com', validation: :root_or_custom_subdomain)
# => 'https://example.com'

DomainExtractor.format('https://api.example.com', validation: :root_or_custom_subdomain)
# => 'https://api.example.com'
```

### Protocol Options

#### Without Protocol

Remove the protocol entirely from the output.

```ruby
DomainExtractor.format('https://example.com', use_protocol: false)
# => 'example.com'

DomainExtractor.format('https://shop.example.com', use_protocol: false)
# => 'shop.example.com'

# Combine with root_domain
DomainExtractor.format('https://shop.example.com',
                       validation: :root_domain,
                       use_protocol: false)
# => 'example.com'
```

#### HTTP vs HTTPS

Control which protocol to use in the output.

```ruby
# Default: use HTTPS
DomainExtractor.format('http://example.com')
# => 'https://example.com'

# Allow HTTP
DomainExtractor.format('https://example.com', use_https: false)
# => 'http://example.com'

DomainExtractor.format('http://example.com', use_https: false)
# => 'http://example.com'
```

### Trailing Slash Options

```ruby
# Remove trailing slash (default)
DomainExtractor.format('https://example.com/')
# => 'https://example.com'

# Add trailing slash
DomainExtractor.format('https://example.com', use_trailing_slash: true)
# => 'https://example.com/'

DomainExtractor.format('https://example.com/', use_trailing_slash: true)
# => 'https://example.com/'

# Works with other options
DomainExtractor.format('https://shop.example.com',
                       validation: :root_domain,
                       use_trailing_slash: true)
# => 'https://example.com/'
```

### Combined Options

Mix and match options for precise URL formatting:

```ruby
# Root domain, no protocol, with trailing slash
DomainExtractor.format('https://shop.example.com/path',
                       validation: :root_domain,
                       use_protocol: false,
                       use_trailing_slash: true)
# => 'example.com/'

# Strip www, use HTTP, with trailing slash
DomainExtractor.format('https://www.example.com',
                       validation: :root_or_custom_subdomain,
                       use_https: false,
                       use_trailing_slash: true)
# => 'http://example.com/'

# Standard mode, no protocol, with trailing slash
DomainExtractor.format('https://api.example.com',
                       use_protocol: false,
                       use_trailing_slash: true)
# => 'api.example.com/'
```

### Real-World Use Cases

#### Canonical URL Generation

```ruby
def canonical_url(url)
  DomainExtractor.format(url,
                         validation: :root_or_custom_subdomain,
                         use_https: true,
                         use_trailing_slash: false)
end

canonical_url('http://www.example.com/')      # => 'https://example.com'
canonical_url('https://shop.example.com/')    # => 'https://shop.example.com'
```

#### Domain Normalization for Allowlists

```ruby
def normalize_domain_for_allowlist(url)
  DomainExtractor.format(url,
                         validation: :root_domain,
                         use_protocol: false)
end

normalize_domain_for_allowlist('https://shop.example.com/path')  # => 'example.com'
normalize_domain_for_allowlist('http://www.example.com')         # => 'example.com'
```

#### Multi-Tenant URL Standardization

```ruby
class Tenant < ApplicationRecord
  before_validation :normalize_custom_domain

  private

  def normalize_custom_domain
    return if custom_domain.blank?

    self.custom_domain = DomainExtractor.format(
      custom_domain,
      validation: :root_or_custom_subdomain,
      use_https: true,
      use_trailing_slash: false
    )
  end
end
```

#### API Endpoint Formatting

```ruby
def format_api_endpoint(url)
  DomainExtractor.format(url,
                         validation: :standard,
                         use_https: true,
                         use_trailing_slash: true)
end

format_api_endpoint('http://api.example.com')  # => 'https://api.example.com/'
```

## Rails Integration

DomainExtractor provides a custom ActiveModel validator for Rails applications, enabling declarative URL/domain validation with multiple modes and options.

### Installation

The Rails validator is automatically available when using DomainExtractor in a Rails application (or any application with ActiveModel). No additional setup is required.

### Basic Usage

```ruby
class Website < ApplicationRecord
  # Standard validation - accepts any valid URL
  validates :url, domain: { validation: :standard }
end
```

### Validation Modes

#### `:standard` - Accept Any Valid URL

Validates that the URL is parseable and valid. This is the default mode.

```ruby
class Website < ApplicationRecord
  validates :url, domain: { validation: :standard }
end

# Valid URLs
website = Website.new(url: 'https://mysite.com')        # ✅ Valid
website = Website.new(url: 'https://shop.mysite.com')   # ✅ Valid
website = Website.new(url: 'https://www.mysite.com')    # ✅ Valid
website = Website.new(url: 'https://api.staging.mysite.com') # ✅ Valid

# Invalid URLs
website = Website.new(url: 'not-a-url')                 # ❌ Invalid
```

#### `:root_domain` - Root Domain Only

Only allows root domains without any subdomains.

```ruby
class PrimaryDomain < ApplicationRecord
  validates :domain, domain: { validation: :root_domain }
end

# Valid URLs
domain = PrimaryDomain.new(domain: 'https://mysite.com')      # ✅ Valid

# Invalid URLs
domain = PrimaryDomain.new(domain: 'https://shop.mysite.com') # ❌ Invalid (has subdomain)
domain = PrimaryDomain.new(domain: 'https://www.mysite.com')  # ❌ Invalid (has www subdomain)
```

#### `:root_or_custom_subdomain` - Root or Custom Subdomain (No WWW)

Allows root domains or custom subdomains, but specifically excludes the 'www' subdomain.

```ruby
class CustomDomain < ApplicationRecord
  validates :url, domain: { validation: :root_or_custom_subdomain }
end

# Valid URLs
domain = CustomDomain.new(url: 'https://mysite.com')       # ✅ Valid (root domain)
domain = CustomDomain.new(url: 'https://shop.mysite.com')  # ✅ Valid (custom subdomain)
domain = CustomDomain.new(url: 'https://api.mysite.com')   # ✅ Valid (custom subdomain)

# Invalid URLs
domain = CustomDomain.new(url: 'https://www.mysite.com')   # ❌ Invalid (www not allowed)
```

### Protocol Options

#### `use_protocol` (default: `true`)

Controls whether the protocol (http:// or https://) is required in the URL.

```ruby
class Website < ApplicationRecord
  # Require protocol (default behavior)
  validates :url, domain: { validation: :standard, use_protocol: true }

  # Don't require protocol
  validates :domain_without_protocol, domain: {
    validation: :standard,
    use_protocol: false
  }
end

# With use_protocol: true (default)
Website.new(url: 'https://mysite.com')  # ✅ Valid
Website.new(url: 'mysite.com')          # ✅ Valid (auto-adds https://)

# With use_protocol: false
Website.new(domain_without_protocol: 'mysite.com')        # ✅ Valid
Website.new(domain_without_protocol: 'https://mysite.com') # ✅ Valid (protocol stripped)
```

#### `use_https` (default: `true`)

Controls whether HTTPS is required. Only relevant when `use_protocol` is `true`.

```ruby
class SecureWebsite < ApplicationRecord
  # Require HTTPS (default behavior)
  validates :url, domain: { validation: :standard, use_https: true }
end

class FlexibleWebsite < ApplicationRecord
  # Allow both HTTP and HTTPS
  validates :url, domain: { validation: :standard, use_https: false }
end

# With use_https: true (default)
SecureWebsite.new(url: 'https://mysite.com')  # ✅ Valid
SecureWebsite.new(url: 'http://mysite.com')   # ❌ Invalid

# With use_https: false
FlexibleWebsite.new(url: 'https://mysite.com') # ✅ Valid
FlexibleWebsite.new(url: 'http://mysite.com')  # ✅ Valid
```

### Real-World Examples

#### Multi-Tenant Application with Custom Domains

```ruby
class Tenant < ApplicationRecord
  # Allow custom subdomains but not www
  validates :custom_domain, domain: {
    validation: :root_or_custom_subdomain,
    use_https: true
  }

  # Primary domain must be root only
  validates :primary_domain, domain: {
    validation: :root_domain,
    use_protocol: false
  }
end

# Valid configurations
tenant = Tenant.create(
  custom_domain: 'https://shop.example.com',    # ✅ Custom subdomain
  primary_domain: 'example.com'                 # ✅ Root without protocol
)

# Invalid configurations
tenant = Tenant.new(
  custom_domain: 'https://www.example.com'      # ❌ www not allowed
)
```

#### E-commerce Store Configuration

```ruby
class Store < ApplicationRecord
  # Main storefront can be root or custom subdomain
  validates :storefront_url, domain: {
    validation: :root_or_custom_subdomain,
    use_https: true
  }

  # Admin panel must be a subdomain (not root, not www)
  validates :admin_url, domain: { validation: :standard }
  validate :admin_must_have_subdomain

  private

  def admin_must_have_subdomain
    parsed = DomainExtractor.parse(admin_url)
    if parsed.valid? && !parsed.subdomain?
      errors.add(:admin_url, 'must have a subdomain')
    end
  end
end
```

#### API Service Registration

```ruby
class ApiEndpoint < ApplicationRecord
  # API endpoints must use HTTPS
  validates :url, domain: {
    validation: :standard,
    use_https: true
  }

  # Custom validation for API subdomain
  validate :must_be_api_subdomain

  private

  def must_be_api_subdomain
    return unless url.present?

    parsed = DomainExtractor.parse(url)
    if parsed.valid? && parsed.subdomain.present?
      unless parsed.subdomain.start_with?('api')
        errors.add(:url, 'must use an api subdomain')
      end
    end
  end
end
```

#### Domain Allowlist with Flexible Protocol

```ruby
class AllowedDomain < ApplicationRecord
  # Accept domains with or without protocol
  validates :domain, domain: {
    validation: :root_domain,
    use_protocol: false,
    use_https: false
  }
end

# All these are valid
AllowedDomain.create(domain: 'example.com')
AllowedDomain.create(domain: 'https://example.com')
AllowedDomain.create(domain: 'http://example.com')
```

### Combining with Other Validators

The domain validator works seamlessly with other Rails validators:

```ruby
class Website < ApplicationRecord
  validates :url, presence: true,
                  domain: { validation: :standard },
                  uniqueness: { case_sensitive: false }

  validates :backup_url, domain: {
    validation: :root_or_custom_subdomain,
    use_https: true
  }, allow_blank: true
end
```

### Error Messages

The validator provides clear, specific error messages:

```ruby
website = Website.new(url: 'not-a-url')
website.valid?
website.errors[:url]
# => ["is not a valid URL"]

domain = PrimaryDomain.new(domain: 'https://shop.example.com')
domain.valid?
domain.errors[:domain]
# => ["must be a root domain (no subdomains allowed)"]

custom = CustomDomain.new(url: 'https://www.example.com')
custom.valid?
custom.errors[:url]
# => ["cannot use www subdomain"]

secure = SecureWebsite.new(url: 'http://example.com')
secure.valid?
secure.errors[:url]
# => ["must use https://"]
```

## Use Cases

**Web Scraping**

```ruby
urls = scrape_page_links(page)
domains = urls.map { |url| DomainExtractor.parse(url).root_domain }.compact.uniq
```

**Analytics & Tracking**

```ruby
referrer = request.referrer
parsed = DomainExtractor.parse(referrer)
track_event('page_view', source_domain: parsed[:root_domain])
```

**Domain Validation**

```ruby
def internal_link?(url, base_domain)
  return false unless DomainExtractor.valid?(url)

  DomainExtractor.parse(url).root_domain == base_domain
end
```

## Performance

Optimized for high-throughput production use:

- **Single URL parsing**: 15-30μs per URL (50,000+ URLs/second)
- **Batch processing**: 50,000+ URLs/second sustained throughput
- **Memory efficient**: <100KB overhead, ~200 bytes per parse
- **Thread-safe**: Stateless modules, safe for concurrent use
- **Zero-allocation hot paths**: Frozen constants, pre-compiled regex

View [performance analysis](https://github.com/opensite-ai/domain_extractor/blob/master/docs/PERFORMANCE.md) for detailed benchmarks and optimization strategies and benchmark results along with a full set of enhancements made in order to meet the highly performance centric requirements of the OpenSite AI site rendering engine, showcased in the [optimization summary](https://github.com/opensite-ai/domain_extractor/blob/master/docs/OPTIMIZATION_SUMMARY.md)

## Comparison with Alternatives

| Feature                     | DomainExtractor | Addressable | URI (stdlib) |
| --------------------------- | --------------- | ----------- | ------------ |
| Multi-part TLD parser       | ✅              | ❌          | ❌           |
| Subdomain extraction        | ✅              | ❌          | ❌           |
| Domain component separation | ✅              | ❌          | ❌           |
| Built-in url normalization  | ✅              | ❌          | ❌           |
| Lightweight                 | ✅              | ❌          | ✅           |

## Requirements

- Ruby 3.2.0 or higher
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
