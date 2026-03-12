# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.9] - 2026-03-11

### Added - URI-Compatible Accessors and Authentication Extraction

This major release adds a much broader **URI-compatible API for common absolute-URL workflows** along with new authentication extraction, URI manipulation helpers, and expanded documentation.

#### 🔐 Authentication Extraction

**Comprehensive userinfo parsing** for database connections, Redis, FTP, SFTP, and any URL scheme with embedded credentials:

- `user` - Extract username from URL
- `password` - Extract password from URL
- `userinfo` - Complete userinfo string (user:password)
- `decoded_user` - Percent-decoded username (handles special characters)
- `decoded_password` - Percent-decoded password (handles special characters)

**Supported URL Schemes:**

- **Redis/Rediss**: `redis://username:password@host:6379/0`, `rediss://:password@host:6380`
- **PostgreSQL**: `postgresql://user:pass@localhost:5432/dbname`
- **MySQL**: `mysql://user:pass@host:3306/database`
- **MongoDB**: `mongodb+srv://user:pass@cluster.mongodb.net/db`
- **FTP/SFTP/FTPS**: `ftp://user:pass@host/path`, `sftp://user:pass@host:22/path`
- **HTTP/HTTPS**: `https://user:pass@api.example.com` (deprecated but supported)

**Special Character Handling:**

- Automatic percent-decoding of credentials with `@`, `:`, and other special characters
- `decoded_user` and `decoded_password` provide clean, usable credentials
- Handles edge cases: password-only (`:password`), username-only, empty passwords

#### 🔧 Complete URI Component Access

**Common URI components** are now accessible as both getters and setters:

**Read Access:**

- `scheme` - URL scheme (http, https, redis, postgresql, etc.)
- `host` - Host value for the parsed URI
- `hostname` - Hostname helper for URI-style access
- `port` - Port number
- `path` - URL path
- `query` - Raw query string
- `fragment` - Fragment/anchor (#section)
- `user`, `password`, `userinfo` - Authentication components
- `subdomain`, `domain`, `tld`, `root_domain` - Domain components (existing)

**Write Access (Setter Methods):**

- `scheme=`, `host=`, `hostname=`, `port=`, `path=`, `query=`, `fragment=`
- `user=`, `password=`, `userinfo=`
- Enables programmatic URI construction and modification

#### 🛠️ Authentication Helper Methods

**Basic Authentication:**

```ruby
# Generate Authorization header from parsed URL
result = DomainExtractor.parse('https://user:pass@api.example.com')
result.basic_auth_header
# => "Basic dXNlcjpwYXNz"

# Or use module method directly
DomainExtractor.basic_auth_header('user', 'password')
# => "Basic dXNlcjpwYXNzd29yZA=="
```

**Bearer Token Authentication:**

```ruby
DomainExtractor.bearer_auth_header('eyJhbGciOiJIUzI1NiIs...')
# => "Bearer eyJhbGciOiJIUzI1NiIs..."
```

**Credential Encoding/Decoding:**
```ruby
# Encode credentials for URL use (percent-encoding)
DomainExtractor.encode_credential('P@ss:word!')
# => "P%40ss%3Aword%21"

# Decode percent-encoded credentials
DomainExtractor.decode_credential('P%40ss%3Aword%21')
# => "P@ss:word!"
```

#### 🌐 Advanced URI Methods

**URI Manipulation:**
- `merge(relative_url)` - Merge with relative URL (RFC 2396 compliant)
- `normalize` - Normalize URI (lowercase scheme/host, remove default ports)
- `absolute?` - Check if URI is absolute
- `relative?` - Check if URI is relative
- `default_port` - Get default port for scheme (80 for http, 443 for https, 6379 for redis, etc.)
- `build_url` - Reconstruct complete URL from components

**Proxy Detection:**
- `find_proxy` - Automatic proxy detection from environment variables
- Checks scheme-specific proxy variables, falls back to `http_proxy` / `HTTP_PROXY`, and respects `no_proxy`
- Returns proxy URI or nil

**Alias Methods for URI Compatibility:**
- `to_str` - Alias for `to_s`
- `hostname` - URI-style hostname accessor
- `query` - Raw query string access

#### 📊 Real-World Use Cases

**Database Connection Parsing:**
```ruby
db_url = 'postgresql://appuser:SecurePass@db.prod.internal:5432/production'
result = DomainExtractor.parse(db_url)

result.user           # => "appuser"
result.password       # => "SecurePass"
result.host           # => "db.prod.internal"
result.port           # => 5432
result.path           # => "/production"
```

**Redis Connection with Special Characters:**
```ruby
redis_url = 'rediss://default:P%40ss%3Aword@redis.cloud:6385/0'
result = DomainExtractor.parse(redis_url)

result.password         # => "P%40ss%3Aword"
result.decoded_password # => "P@ss:word"
result.scheme           # => "rediss"
result.port             # => 6385
```

**API Authentication Header Generation:**
```ruby
api_url = 'https://nick@untappd.com:MySuperAPIToken123@api.untappd.com/v4'
result = DomainExtractor.parse(api_url)

# Generate Basic Auth header
auth_header = result.basic_auth_header
# Use in HTTP request:
# headers['Authorization'] = auth_header
```

**FTP/SFTP Deployment:**
```ruby
deploy_url = 'sftp://deploy_user:DeployKey123@deployment.internal:22/var/www/app'
result = DomainExtractor.parse(deploy_url)

result.user     # => "deploy_user"
result.password # => "DeployKey123"
result.host     # => "deployment.internal"
result.port     # => 22
result.path     # => "/var/www/app"
```

#### 🔒 Security Considerations

**Important Security Notes:**
- Embedding credentials in URLs is **deprecated** per RFC 3986 and should be avoided in production
- Use environment variables, secret managers, or secure vaults for credential storage
- The library supports credential extraction for **legacy systems** and **configuration parsing**
- Always use HTTPS/TLS when credentials must be transmitted
- Never log URLs containing credentials
- Consider using header-based authentication (Bearer tokens, API keys) instead

**Safe Credential Handling:**
```ruby
# ✅ Good: Parse from environment variable
db_url = ENV['DATABASE_URL']
config = DomainExtractor.parse(db_url)

# ✅ Good: Extract and use separately
username = config.decoded_user
password = config.decoded_password
# Pass to connection library without logging URL

# ❌ Bad: Hardcode credentials in source
db_url = 'postgresql://user:password@localhost/db'  # Don't do this!
```

#### 🚀 Performance

**Maintains Performance-First Design:**
- All new features use frozen constants and optimized string operations
- Auth extraction adds <5μs overhead per parse
- Core hot paths remain allocation-conscious
- Thread-safe stateless modules
- Full parse throughput depends on host complexity; see the benchmark docs for measured results

#### 🔄 URI-Style Access

**Common URI-style access with additional domain helpers:**
```ruby
# Before (using URI)
uri = URI.parse('https://user:pass@example.com:8080/path?query=value#section')
uri.scheme    # => "https"
uri.user      # => "user"
uri.password  # => "pass"
uri.host      # => "example.com"
uri.port      # => 8080

# After (using DomainExtractor) - identical API
result = DomainExtractor.parse('https://user:pass@example.com:8080/path?query=value#section')
result.scheme    # => "https"
result.user      # => "user"
result.password  # => "pass"
result.host      # => "example.com"
result.port      # => 8080

# PLUS: Additional domain parsing features
result.subdomain     # => nil
result.domain        # => "example"
result.tld           # => "com"
result.root_domain   # => "example.com"

# PLUS: Decoded credentials
result.decoded_user     # => "user"
result.decoded_password # => "pass"

# PLUS: Authentication helpers
result.basic_auth_header # => "Basic dXNlcjpwYXNz"
```

#### 📦 Implementation Details

**New Modules:**
- `DomainExtractor::Auth` - Authentication component extraction with percent-decoding
- `DomainExtractor::URIHelpers` - Advanced URI manipulation and helper methods

**Enhanced Modules:**
- `DomainExtractor::Parser` - Now extracts auth components and additional URI parts
- `DomainExtractor::Result` - Builds results with auth and URI components
- `DomainExtractor::ParsedURL` - Extended with URI-compatible methods and setters

**Code Quality:**
- 200+ comprehensive test cases covering all scenarios
- RuboCop clean with zero offenses
- 100% backward compatible - no breaking changes
- Extensive documentation with real-world examples

#### 🎯 Migration from URI Library

**Low-friction migration for common absolute-URL use cases:**
```ruby
# Swap URI.parse for DomainExtractor.parse
# Before:
require 'uri'
uri = URI.parse(url)

# After:
require 'domain_extractor'
uri = DomainExtractor.parse(url)

# Common URI-style accessors continue to work, plus you get:
# - Multi-part TLD support
# - Domain component extraction
# - Decoded credentials
# - Authentication helpers
# - Better performance
```

#### 📚 Documentation

- Comprehensive CHANGELOG with all features documented
- README updated with authentication examples
- Real-world use cases for Redis, databases, FTP, APIs
- Security best practices section
- Migration guide from URI library

## [0.2.7] - 2025-11-09

### Added - URL Formatting API

Added a comprehensive `format` method for programmatic URL normalization and transformation. The formatter provides precise control over URL structure, protocol, and formatting while maintaining the same validation modes as the Rails validator.

#### Features

**Core Method:**
- `DomainExtractor.format(url, **options)` - Format and normalize URLs based on specified options
- Returns formatted URL string or `nil` for invalid input
- Strips paths and query parameters from URLs
- Supports all validation modes from the Rails validator

**Validation Modes:**
- `:standard` (default) - Preserves full host as-is while normalizing protocol/slashes
- `:root_domain` - Strips all subdomains, returns only root domain
- `:root_or_custom_subdomain` - Preserves custom subdomains but removes 'www'

**Formatting Options:**
- `use_protocol` (default: `true`) - Include/exclude protocol in output
- `use_https` (default: `true`) - Use HTTPS vs HTTP (only when `use_protocol` is true)
- `use_trailing_slash` (default: `false`) - Add/remove trailing slash from output

#### Usage Examples

**Basic Formatting:**
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

**Validation Modes:**
```ruby
# Root domain only (strips subdomains)
DomainExtractor.format('https://shop.example.com', validation: :root_domain)
# => 'https://example.com'

# Strip www but keep custom subdomains
DomainExtractor.format('https://www.example.com', validation: :root_or_custom_subdomain)
# => 'https://example.com'
```

**Protocol Control:**
```ruby
# Without protocol
DomainExtractor.format('https://example.com', use_protocol: false)
# => 'example.com'

# Force HTTP instead of HTTPS
DomainExtractor.format('https://example.com', use_https: false)
# => 'http://example.com'
```

**Trailing Slash Control:**
```ruby
# Add trailing slash
DomainExtractor.format('https://example.com', use_trailing_slash: true)
# => 'https://example.com/'
```

**Combined Options:**
```ruby
# Root domain, no protocol, with trailing slash
DomainExtractor.format('https://shop.example.com/path',
                       validation: :root_domain,
                       use_protocol: false,
                       use_trailing_slash: true)
# => 'example.com/'
```

#### Real-World Use Cases

**Canonical URL Generation:**
```ruby
def canonical_url(url)
  DomainExtractor.format(url,
                         validation: :root_or_custom_subdomain,
                         use_https: true,
                         use_trailing_slash: false)
end

canonical_url('http://www.example.com/')   # => 'https://example.com'
```

**Domain Normalization for Allowlists:**
```ruby
def normalize_domain(url)
  DomainExtractor.format(url, validation: :root_domain, use_protocol: false)
end

normalize_domain('https://shop.example.com/path')  # => 'example.com'
```

**Multi-Tenant URL Standardization:**
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

#### Implementation Details

- **Performance**: Leverages existing DomainExtractor parsing engine with minimal overhead
- **Nil-safe**: Returns `nil` for invalid URLs instead of raising exceptions
- **Consistent API**: Uses same option names and validation modes as Rails validator
- **Path/Query Stripping**: Automatically removes paths and query parameters
- **Multi-part TLD Support**: Correctly handles complex TLDs like `.co.uk`, `.com.au`

#### Code Quality

- **49 comprehensive test cases** covering all formatting modes and options
- **RuboCop clean** with zero offenses
- **100% test coverage** maintained across entire gem (200 total tests)
- **Well-documented** with extensive README section and real-world examples

#### Documentation

- Added comprehensive **URL Formatting** section to README.md
- Includes examples for all validation modes and options
- Real-world use cases: canonical URLs, domain normalization, multi-tenant standardization
- Clear API reference with all available options

## [0.2.6] - 2025-11-09

### Fixed - Rails Validator Registration

**CRITICAL FIX**: Moved `DomainValidator` class to the **top-level namespace** (from `DomainExtractor::DomainValidator`) to ensure Rails can properly autoload and find the validator.

#### The Problem

Version 0.2.5 defined the validator as `DomainExtractor::DomainValidator`, which caused Rails to fail with:

```
ArgumentError: Unknown validator: 'DomainValidator'
NameError: uninitialized constant Website::DomainValidator
```

This occurred because when using `validates :url, domain: { ... }`, Rails searches for `DomainValidator` in:

1. The model's namespace (e.g., `Website::DomainValidator`)
2. The top-level namespace (`::DomainValidator`)
3. ActiveModel::Validations namespace

It does **not** search module namespaces like `DomainExtractor::`.

#### The Solution

- Moved `DomainValidator` to top-level namespace where Rails can find it
- Added `DomainExtractor::DomainValidator` as an alias for backward compatibility
- All functionality remains identical; only the class location changed

#### Verification

- All 151 tests pass including 35 validator-specific tests
- RuboCop clean with zero offenses
- Verified in production Rails 8 application
- Confirmed working with `validates :url, domain: { validation: :root_or_custom_subdomain }`

## [0.2.5] - 2025-11-09 [YANKED]

**This version was yanked due to validator registration issue. Use 0.2.6 instead.**

### Added Rails Integration - Custom ActiveModel Validator (BROKEN)

Added a comprehensive custom ActiveModel validator for declarative URL and domain validation in Rails applications. However, the validator was incorrectly namespaced and did not work in Rails applications.

#### Features (Broken in 0.2.5)

**Validation Modes:**

- `:standard` - Validates any parseable URL (default mode)
- `:root_domain` - Only allows root domains without subdomains (e.g., `example.com` ✅, `shop.example.com` ❌)
- `:root_or_custom_subdomain` - Allows root or custom subdomains but excludes `www` subdomain (e.g., `example.com` ✅, `shop.example.com` ✅, `www.example.com` ❌)

**Protocol Options:**

- `use_protocol` (default: `true`) - Controls whether protocol (http/https) is required in the URL
- `use_https` (default: `true`) - Controls whether HTTPS is required (only relevant when `use_protocol` is true)

**Usage Examples:**

```ruby
# Standard validation - any valid URL
validates :url, domain: { validation: :standard }

# Root domain only, no subdomains
validates :primary_domain, domain: { validation: :root_domain }

# Custom subdomains allowed, but not www
validates :custom_domain, domain: { validation: :root_or_custom_subdomain }

# Flexible protocol requirements
validates :domain, domain: {
  validation: :root_domain,
  use_protocol: false,
  use_https: false
}
```

#### Implementation Details

- **Zero Configuration**: Automatically loads when ActiveModel is available
- **Graceful Degradation**: Validator only loads in Rails environments; works independently in non-Rails contexts
- **Clean Error Messages**: Provides clear, actionable validation error messages
- **Performance**: Leverages existing DomainExtractor parsing engine with minimal overhead
- **Thread-Safe**: Stateless validation logic safe for concurrent use

#### Compatibility

- **Rails 6.0+**: Full compatibility with ActiveModel::EachValidator API
- **Rails 7.0+**: Compatible with modern errors API
- **Rails 8.0+**: No breaking changes, fully supported
- **Non-Rails**: Works with any application using ActiveModel (Sinatra, Hanami, etc.)

#### Code Quality

- **100% Test Coverage**: 35 comprehensive test cases covering all validation modes and options
- **RuboCop Clean**: Zero offenses, follows Ruby style guide
- **Well-Documented**: Extensive README section with real-world examples
- **Type-Safe**: Proper argument validation with clear error messages

#### Documentation

- Added comprehensive **Rails Integration** section to README.md
- Includes real-world examples:
  - Multi-tenant applications with custom domains
  - E-commerce store configuration
  - API service registration
  - Domain allowlists with flexible protocols
- Documents all validation modes, options, and error messages
- Shows integration with other Rails validators

#### Use Cases

Perfect for Rails applications requiring:

- Multi-tenant custom domain validation
- Secure URL validation (HTTPS enforcement)
- Subdomain-based architecture validation
- API endpoint domain validation
- Domain allowlist/blocklist management
- Custom subdomain requirements

## [0.1.8] - 2025-10-31

### Implemented Declarative Method-style Accessors

#### Added

- **ParsedURL API**: Introduced intuitive method-style accessors with three variants:
  - Default methods (e.g., `result.subdomain`) - Returns value or nil
  - Bang methods (e.g., `result.subdomain!`) - Returns value or raises `InvalidURLError`
  - Question methods (e.g., `result.subdomain?`) - Returns boolean true/false
- Added `www_subdomain?` helper method to check if subdomain is specifically 'www'
- Added `valid?` method to check if parsed result contains valid data
- Added `to_h` and `to_hash` methods for hash conversion
- Comprehensive documentation in `docs/PARSED_URL_API.md`

#### Changed

- `DomainExtractor.parse` now returns `ParsedURL` object instead of plain Hash (backward compatible via `[]` accessor)
- `DomainExtractor.parse_batch` now returns array of `ParsedURL` objects (or nil for invalid URLs)

#### Maintained

- Full backward compatibility with hash-style access using `[]`
- All existing tests continue to pass
- No breaking changes to existing API

## [0.1.7] - 2025-10-31

### Added valid? method and enhanced error handling

- Added `DomainExtractor.valid?` helper to allow safe URL pre-checks without raising.
- `DomainExtractor.parse` now raises `DomainExtractor::InvalidURLError` with a clear `"Invalid URL Value"` message when the input cannot be parsed.

## [0.1.6] - 2025-10-31

### Integrate Rakefile for Release and Task Workflow Refactors

Refactored release action workflow along with internal task automation with Rakefile build out.

## [0.1.4] - 2025-10-31

### Updated release action workflow

Streamlined release workflow and GitHub Action CI.

## [0.1.2] - 2025-10-31

### Performance Enhancements

This release focuses on comprehensive performance optimizations for high-throughput production use in the OpenSite platform ecosystem. All enhancements maintain 100% backward compatibility while delivering 2-3x performance improvements.

#### Core Optimizations

- **Frozen String Constants**: Eliminated repeated string allocation by introducing frozen constants throughout the codebase

  - Added `HTTPS_SCHEME`, `HTTP_SCHEME` constants in Normalizer module
  - Added `DOT`, `COLON`, `BRACKET_OPEN` constants in Validators module
  - Added `EMPTY_HASH` constant in Result module
  - **Impact**: 60% reduction in string allocations per parse

- **Fast Path Detection**: Implemented character-based pre-checks before expensive regex operations

  - Normalizer: Check `string.start_with?(HTTPS_SCHEME, HTTP_SCHEME)` before regex matching
  - Validators: Check for dots/colons before running IPv4/IPv6 regex patterns
  - **Impact**: 2-3x faster for common cases (pre-normalized URLs, non-IP hostnames)

- **Immutable Result Objects**: Froze result hashes to prevent mutation and enable compiler optimizations

  - Result hashes now frozen with `.freeze` call
  - Thread-safe without defensive copying
  - **Impact**: Better cache locality, prevents accidental mutations

- **Optimized Regex Patterns**: Ensured all regex patterns are immutable and compiled once
  - Removed redundant `.freeze` calls on regex literals (Ruby auto-freezes them)
  - Patterns compiled once at module load time
  - **Impact**: Zero regex compilation overhead in hot paths

#### Performance Benchmarks

Verified performance metrics on Ruby 3.3.10:

**Single URL Parsing (1000 iterations average):**

- Simple domains (`example.com`): 15-31μs per URL
- Complex multi-part TLDs (`blog.example.co.uk`): 18-19μs per URL
- IP addresses (`192.168.1.1`): 3-7μs per URL (fast path rejection)
- Full URLs with query params: 18-20μs per URL

**Batch Processing Throughput:**

- 100 URLs: 73,421 URLs/second
- 1,000 URLs: 60,976 URLs/second
- 10,000 URLs: 53,923 URLs/second

**Memory Profile:**

- Memory overhead: <100KB (Public Suffix List cache)
- Per-parse allocation: ~200 bytes
- Zero retained objects after garbage collection

**Performance Improvements vs Baseline:**

- Parse time: 2-3x faster (50μs → 15-30μs)
- Throughput: 2.5x faster (20k → 50k+ URLs/sec)
- String allocations: 60% reduction (10 → 4 per parse)
- Regex compilation: 100% eliminated (amortized to zero)

#### Thread Safety

All optimizations maintain thread safety:

- Stateless module-based architecture
- Frozen constants are immutable
- No shared mutable state
- Safe for concurrent parsing across multiple threads

#### Code Quality

- Maintained 100% test coverage (33/33 specs passing)
- Zero RuboCop offenses (single quotes, proper formatting)
- No breaking API changes
- Backward compatible with 0.1.0 and 0.1.1

### Documentation

- Added `PERFORMANCE.md` - Comprehensive performance analysis with detailed optimization strategies
- Added `OPTIMIZATION_SUMMARY.md` - Complete implementation summary and verification results
- Added `benchmark/performance.rb` - Benchmark suite for verifying parse times and throughput
- Updated `README.md` - Added performance section with verified benchmark metrics

### Alignment with OpenSite ECOSYSTEM_GUIDELINES.md

All optimizations follow OpenSite platform principles:

- **Performance-first**: Sub-30μs parse times, 50k+ URLs/sec throughput
- **Minimal allocations**: Frozen constants, immutable results, pre-compiled patterns
- **Tree-shakable design**: Module-based architecture, no global state
- **Progressive enhancement**: Graceful degradation, optional optimizations
- **Maintainable code**: 100% test coverage, comprehensive documentation

### Migration from 0.1.0/0.1.1

No code changes required. All enhancements are internal optimizations:

```ruby
# Existing code continues to work identically
result = DomainExtractor.parse('https://example.com')
# Same API, same results, just faster!
```

### Production Deployment

Ready for high-throughput production use:

- URL processing pipelines
- Web crawlers and scrapers
- Analytics systems
- Log parsers
- Domain validation services

Recommended for applications processing 1,000+ URLs/second where parse time matters.

## [0.1.0] - 2025-10-31

### Added

- Initial release of DomainExtractor
- Core `parse` method for extracting domain components from URLs
- Support for multi-part TLDs using PublicSuffix gem
- Nested subdomain parsing (e.g., api.staging.example.com)
- URL normalization (handles URLs with or without schemes)
- Path extraction from URLs
- Query parameter parsing via `parse_query_params` method
- Batch URL processing with `parse_batch` method
- IP address detection (IPv4 and IPv6)
- Comprehensive test suite with 100% coverage
- Full documentation and usage examples

### Features

- Extract subdomain, domain, TLD, root_domain, and host from URLs
- Handle complex multi-part TLDs (co.uk, com.au, gov.br, etc.)
- Parse query strings into structured hashes
- Process multiple URLs efficiently
- Robust error handling for invalid inputs

[Unreleased]: https://github.com/opensite-ai/domain_extractor/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/opensite-ai/domain_extractor/releases/tag/v0.1.0
