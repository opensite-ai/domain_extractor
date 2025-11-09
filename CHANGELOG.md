# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
