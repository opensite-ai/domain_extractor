# ParsedURL Quick Start Guide

Get up and running with DomainExtractor's intuitive `ParsedURL` API in 5 minutes.

## Installation

```ruby
gem install domain_extractor
```

## The Three Accessor Styles

DomainExtractor gives you three ways to access parsed URL components:

| Style | Returns | Use When |
|-------|---------|----------|
| `result.subdomain` | Value or `nil` | You want safe, silent nil handling |
| `result.subdomain!` | Value or raises error | You require the value (fail fast) |
| `result.subdomain?` | `true` or `false` | You need boolean checks |

## Quick Examples

### 1. Basic Usage

```ruby
require 'domain_extractor'

result = DomainExtractor.parse('https://api.example.com')

# Method access (new API)
result.host           # => 'api.example.com'
result.subdomain      # => 'api'
result.domain         # => 'example'
result.tld            # => 'com'
result.root_domain    # => 'example.com'

# Hash access (still works)
result[:host]         # => 'api.example.com'
result[:subdomain]    # => 'api'
```

### 2. Checking for Subdomains

```ruby
# Question mark methods return booleans
if result.subdomain?
  puts "Has subdomain: #{result.subdomain}"
else
  puts "No subdomain"
end

# Special helper for www
if result.www_subdomain?
  redirect_to_apex_domain
end
```

### 3. Required Values (Bang Methods)

```ruby
# Raises InvalidURLError if missing
begin
  subdomain = result.subdomain!  # Must exist
  api_key = get_api_key_for(subdomain)
rescue DomainExtractor::InvalidURLError
  render_error("Subdomain required")
end
```

### 4. Safe Nil Handling (Default Methods)

```ruby
# Returns nil if not present (no error)
subdomain = result.subdomain  # nil is OK
prefix = subdomain&.upcase || 'DEFAULT'
```

## Common Patterns

### Pattern 1: Conditional Processing

```ruby
url = request.url
parsed = DomainExtractor.parse(url)

case
when parsed.www_subdomain?
  redirect_to(parsed.root_domain)
when parsed.subdomain? && parsed.subdomain.start_with?('api')
  handle_api_request(parsed)
when parsed.subdomain?
  handle_tenant(parsed.subdomain)
else
  handle_main_site
end
```

### Pattern 2: Analytics Tracking

```ruby
def track_referrer(referrer_url)
  parsed = DomainExtractor.parse(referrer_url)
  
  {
    domain: parsed.root_domain,
    has_subdomain: parsed.subdomain?,
    is_www: parsed.www_subdomain?,
    source: parsed.host
  }
rescue DomainExtractor::InvalidURLError
  { domain: 'unknown' }
end
```

### Pattern 3: Validation

```ruby
def validate_tenant_url(url)
  parsed = DomainExtractor.parse(url)
  
  # Ensure required components exist
  parsed.subdomain!  # Raises if missing
  parsed.domain!
  
  # Validate subdomain format
  return false unless parsed.subdomain.match?(/^[a-z0-9-]+$/)
  return false if parsed.www_subdomain?  # www not allowed
  
  true
rescue DomainExtractor::InvalidURLError
  false
end
```

### Pattern 4: Batch Processing

```ruby
urls = User.pluck(:website)

results = urls.map do |url|
  parsed = DomainExtractor.parse(url)
  
  {
    url: url,
    valid: parsed.valid?,
    domain: parsed.root_domain,
    has_subdomain: parsed.subdomain?
  }
rescue DomainExtractor::InvalidURLError
  { url: url, valid: false }
end

valid_domains = results.select { |r| r[:valid] }
```

## Available Methods

All three styles work with these components:

- `subdomain` / `subdomain!` / `subdomain?`
- `domain` / `domain!` / `domain?`
- `tld` / `tld!` / `tld?`
- `root_domain` / `root_domain!` / `root_domain?`
- `host` / `host!` / `host?`
- `path` / `path!` / `path?`
- `query_params` / `query_params!` / `query_params?`

Special helpers:

- `www_subdomain?` - Returns `true` if subdomain is 'www'
- `valid?` - Returns `true` if parse was successful

## Choosing the Right Style

**Use default methods when:**
- Processing untrusted data
- Nil is a valid outcome
- You have fallback logic

**Use bang methods when:**
- Values are required for your logic
- Missing data indicates a problem
- You want explicit error handling

**Use question methods when:**
- Writing conditionals (if/case)
- Guard clauses
- Boolean flags

## Edge Cases

```ruby
# Empty values return false for question methods
parsed.path          # => ''
parsed.path?         # => false

parsed.query_params  # => {}
parsed.query_params? # => false

# Multi-part TLDs work perfectly
result = DomainExtractor.parse('shop.example.co.uk')
result.tld           # => 'co.uk'
result.root_domain   # => 'example.co.uk'

# Nested subdomains are preserved
result = DomainExtractor.parse('api.staging.example.com')
result.subdomain     # => 'api.staging'
```

## Backward Compatibility

Hash-style access still works everywhere:

```ruby
result[:subdomain]    # Same as result.subdomain
result[:host]         # Same as result.host

# Convert to plain hash if needed
hash = result.to_h
```

## Error Handling

```ruby
# parse() raises for invalid URLs
begin
  result = DomainExtractor.parse(url)
rescue DomainExtractor::InvalidURLError
  # Handle invalid URL
end

# Or check validity first
if DomainExtractor.valid?(url)
  result = DomainExtractor.parse(url)
end

# Bang methods raise for missing components
begin
  subdomain = result.subdomain!
rescue DomainExtractor::InvalidURLError => e
  puts e.message  # => "subdomain not found or invalid"
end
```

## Next Steps

- **Read the full API docs:** [PARSED_URL_API.md](PARSED_URL_API.md)
- **Run examples:** `ruby examples/parsed_url_examples.rb`
- **Explore the README:** [README.md](../README.md)

## Quick Reference Card

```ruby
# Access styles
result.subdomain      # => value or nil
result.subdomain!     # => value or raise
result.subdomain?     # => true or false

# Common checks
result.subdomain?         # Has subdomain?
result.www_subdomain?     # Is subdomain 'www'?
result.valid?             # Is parse valid?

# Conversion
result[:key]              # Hash access
result.to_h               # Convert to hash

# All components
host, subdomain, domain, tld, root_domain, path, query_params
```

---

**Pro Tip:** Start with question methods (`?`) for conditionals, use default methods for safe access, and reach for bang methods (`!`) when values are truly required. Your code will be more expressive and maintainable!