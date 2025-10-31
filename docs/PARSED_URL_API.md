# ParsedURL API Documentation

The `ParsedURL` class provides an intuitive, flexible API for accessing parsed URL components with declarative method names that make your intent clear.

## Overview

When you call `DomainExtractor.parse(url)`, it returns a `ParsedURL` object that supports three accessor styles:

1. **Default methods** - Return the value or `nil` (fail silently)
2. **Bang methods (`!`)** - Return the value or raise an exception
3. **Question methods (`?`)** - Return a boolean (true/false)

This design allows you to be explicit about how you want to handle missing or invalid data, making your code more predictable and easier to reason about.

## Method Accessor Styles

### Default Methods (Silent Nil)

Default method calls return the value if it exists, or `nil` if it doesn't. This is the safest option for exploratory code or when you're handling invalid data gracefully.

```ruby
# With subdomain
result = DomainExtractor.parse('https://api.example.com')
result.subdomain    # => 'api'
result.domain       # => 'example'
result.tld          # => 'com'
result.root_domain  # => 'example.com'
result.host         # => 'api.example.com'
result.path         # => ''
result.query_params # => {}

# Without subdomain
result = DomainExtractor.parse('https://example.com')
result.subdomain    # => nil
result.domain       # => 'example'
result.host         # => 'example.com'

# Invalid URL (when constructed directly, parse() would raise)
parsed = DomainExtractor::ParsedURL.new(nil)
parsed.subdomain    # => nil
parsed.domain       # => nil
parsed.host         # => nil
```

**When to use:**
- Exploratory code or REPL sessions
- When you have fallback logic for missing values
- Processing analytics data where some URLs might be malformed
- Chain-safe operations where nil propagation is desired

### Bang Methods (!) - Explicit Errors

Bang methods return the value if it exists, or raise `DomainExtractor::InvalidURLError` if it doesn't. This is ideal for production code where missing data indicates a problem that should be caught early.

```ruby
# Valid URL with all components
result = DomainExtractor.parse('https://api.example.com')
result.subdomain!   # => 'api'
result.domain!      # => 'example'
result.host!        # => 'api.example.com'

# Valid URL without subdomain
result = DomainExtractor.parse('https://example.com')
result.domain!      # => 'example'
result.subdomain!   # raises DomainExtractor::InvalidURLError: "subdomain not found or invalid"

# Usage with rescue
begin
  subdomain = parsed_url.subdomain!
  # Process subdomain-specific logic
rescue DomainExtractor::InvalidURLError
  # Handle missing subdomain
end
```

**When to use:**
- Production code where missing values are exceptional
- Validating required fields
- Early failure when data doesn't meet expectations
- Making dependencies explicit in your code

### Question Methods (?) - Boolean Checks

Question methods always return a boolean (`true` or `false`) and never raise exceptions. They're perfect for conditional logic and validation checks.

```ruby
# With subdomain
result = DomainExtractor.parse('https://api.example.com')
result.subdomain?    # => true
result.domain?       # => true
result.host?         # => true

# Without subdomain
result = DomainExtractor.parse('https://example.com')
result.subdomain?    # => false
result.domain?       # => true
result.host?         # => true

# Invalid URL
parsed = DomainExtractor::ParsedURL.new(nil)
parsed.subdomain?    # => false
parsed.domain?       # => false
parsed.host?         # => false

# Conditional logic
if parsed_url.subdomain?
  puts "Processing subdomain: #{parsed_url.subdomain}"
else
  puts "No subdomain present"
end
```

**When to use:**
- Conditional logic and control flow
- Validation without exception handling
- Guard clauses and early returns
- Boolean flags in templates or views

## Available Accessor Methods

All three styles (default, `!`, `?`) work with these component methods:

| Method | Description | Example Value |
|--------|-------------|---------------|
| `subdomain` | The subdomain portion | `'api'`, `'www'`, `'api.staging'` |
| `domain` | The second-level domain | `'example'`, `'google'` |
| `tld` | The top-level domain | `'com'`, `'co.uk'`, `'com.au'` |
| `root_domain` | Domain + TLD | `'example.com'`, `'example.co.uk'` |
| `host` | Full hostname | `'api.example.com'` |
| `path` | URL path | `'/api/v1/users'` |
| `query_params` | Parsed query parameters | `{'key' => 'value'}` |

## Special Helper Methods

### `www_subdomain?`

Check if the subdomain is specifically `'www'`:

```ruby
DomainExtractor.parse('https://www.dashtrack.com').www_subdomain?
# => true

DomainExtractor.parse('https://api.dashtrack.com').www_subdomain?
# => false

DomainExtractor.parse('https://dashtrack.com').www_subdomain?
# => false
```

### `valid?`

Check if the parsed result contains valid data:

```ruby
result = DomainExtractor.parse('https://example.com')
result.valid?  # => true

invalid = DomainExtractor::ParsedURL.new(nil)
invalid.valid?  # => false
```

## Backward Compatibility

`ParsedURL` maintains full backward compatibility with hash-style access using `[]`:

```ruby
result = DomainExtractor.parse('https://www.example.co.uk/path?query=value')

# Hash-style access (original API)
result[:subdomain]    # => 'www'
result[:domain]       # => 'example'
result[:tld]          # => 'co.uk'
result[:root_domain]  # => 'example.co.uk'
result[:host]         # => 'www.example.co.uk'

# Method-style access (new API)
result.subdomain      # => 'www'
result.domain         # => 'example'
result.tld            # => 'co.uk'
result.root_domain    # => 'example.co.uk'
result.host           # => 'www.example.co.uk'
```

You can also convert to a plain hash:

```ruby
result = DomainExtractor.parse('https://api.example.com')

hash = result.to_h
# => { subdomain: 'api', domain: 'example', ... }

# Or use to_hash (alias)
hash = result.to_hash
```

## Real-World Usage Examples

### Example 1: Analytics Processing

```ruby
# Process referrer URLs in analytics pipeline
def track_referrer(referrer_url)
  parsed = DomainExtractor::ParsedURL.new(
    DomainExtractor::Parser.call(referrer_url)
  )
  
  return unless parsed.valid?
  
  {
    has_subdomain: parsed.subdomain?,
    is_www: parsed.www_subdomain?,
    domain: parsed.root_domain,
    source: parsed.host
  }
end
```

### Example 2: Subdomain-Based Routing

```ruby
# Route based on subdomain presence
def route_request(url)
  result = DomainExtractor.parse(url)
  
  if result.subdomain? && result.subdomain != 'www'
    route_to_api(result.subdomain)
  else
    route_to_main_app
  end
end
```

### Example 3: URL Validation with Required Components

```ruby
# Validate that URL has required components
def validate_api_url(url)
  result = DomainExtractor.parse(url)
  
  # Use bang methods to ensure all required parts exist
  result.subdomain!  # Must have subdomain
  result.domain!     # Must have domain
  result.path!       # Must have path
  
  true
rescue DomainExtractor::InvalidURLError => e
  puts "Invalid API URL: #{e.message}"
  false
end
```

### Example 4: Conditional Subdomain Processing

```ruby
# Process URLs differently based on subdomain
def process_url(url)
  result = DomainExtractor.parse(url)
  
  case
  when result.www_subdomain?
    redirect_to_apex_domain(result.root_domain)
  when result.subdomain? && result.subdomain.start_with?('api')
    process_api_request(result)
  when result.subdomain?
    process_tenant_subdomain(result.subdomain, result.root_domain)
  else
    process_main_domain(result.root_domain)
  end
end
```

### Example 5: Safe Batch Processing

```ruby
# Process many URLs safely without stopping on errors
urls = load_urls_from_database

results = urls.map do |url|
  parsed = DomainExtractor::ParsedURL.new(
    DomainExtractor::Parser.call(url)
  )
  
  {
    url: url,
    valid: parsed.valid?,
    host: parsed.host,  # nil if invalid
    has_subdomain: parsed.subdomain?
  }
end

# Filter and process valid URLs
valid_results = results.select { |r| r[:valid] }
```

## Edge Cases

### Empty Values

Empty strings and empty hashes are treated as "not present":

```ruby
result = DomainExtractor.parse('https://example.com')

result.path         # => '' (empty string)
result.path?        # => false (empty is not present)
result.query_params # => {} (empty hash)
result.query_params? # => false (empty is not present)
```

### Multi-Part TLDs

Multi-part TLDs are fully supported:

```ruby
result = DomainExtractor.parse('https://shop.example.com.au')

result.tld          # => 'com.au'
result.tld?         # => true
result.root_domain  # => 'example.com.au'
```

### Nested Subdomains

Nested subdomains are preserved:

```ruby
result = DomainExtractor.parse('https://api.staging.example.com')

result.subdomain    # => 'api.staging'
result.subdomain?   # => true
result.subdomain!   # => 'api.staging'
```

## Performance Considerations

`ParsedURL` objects are:
- **Frozen** - Immutable after creation
- **Lightweight** - Minimal memory overhead (~200 bytes)
- **Fast** - Method dispatch via `method_missing` is optimized
- **Thread-safe** - Immutable objects are safe for concurrent use

## Migration Guide

### From Hash Access

If you're currently using hash access:

```ruby
# Before
result = DomainExtractor.parse(url)
if result && result[:subdomain]
  process_subdomain(result[:subdomain])
end

# After (cleaner and more expressive)
result = DomainExtractor.parse(url)
if result.subdomain?
  process_subdomain(result.subdomain)
end
```

### From Manual Validation

If you're manually checking for nil:

```ruby
# Before
result = DomainExtractor.parse(url)
subdomain = result[:subdomain]
raise "Missing subdomain" unless subdomain

# After (more expressive)
result = DomainExtractor.parse(url)
subdomain = result.subdomain!  # Raises if missing
```

## Best Practices

1. **Use question methods for conditionals** - They never raise and clearly indicate boolean logic
2. **Use bang methods when values are required** - Fail fast with clear error messages
3. **Use default methods for exploratory code** - Safe for unknown data quality
4. **Chain safely with default methods** - `parsed.subdomain&.upcase` works naturally
5. **Use `www_subdomain?` instead of** - `parsed.subdomain == 'www'` for clarity

## Error Handling

```ruby
# Option 1: Let errors bubble up
subdomain = parsed_url.subdomain!

# Option 2: Explicit rescue
begin
  subdomain = parsed_url.subdomain!
  process_subdomain(subdomain)
rescue DomainExtractor::InvalidURLError
  handle_missing_subdomain
end

# Option 3: Guard with question method (recommended)
if parsed_url.subdomain?
  process_subdomain(parsed_url.subdomain)
else
  handle_missing_subdomain
end
```

## Summary

The `ParsedURL` API provides three accessor styles to match your intent:

- **Default methods** → "Give me the value or nil" (safe, exploratory)
- **Bang methods** → "Give me the value or fail" (explicit, production)
- **Question methods** → "Does this exist?" (conditional, validation)

Choose the style that best communicates your intent and handles errors appropriately for your use case.