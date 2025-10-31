# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
