# frozen_string_literal: true

require_relative 'lib/domain_extractor/version'

Gem::Specification.new do |spec|
  # ========================================================================
  # REQUIRED ATTRIBUTES
  # ========================================================================

  spec.name = 'domain_extractor'
  spec.version = DomainExtractor::VERSION
  spec.authors = ['OpenSite AI']
  spec.summary = 'Extract domain components from URLs with multi-part TLD support'

  # Files to include in the gem
  spec.files = Dir.glob('{lib,spec}/**/*') + %w[
    README.md
    LICENSE.txt
    CHANGELOG.md
    .rubocop.yml
  ]

  spec.description = "DomainExtractor is a lightweight, robust Ruby library for parsing URLs and extracting domain components. It accurately handles complex scenarios including multi-part TLDs (co.uk, com.au), nested subdomains, query parameters, and URL normalization. Built on Ruby's URI library and the public_suffix gem, it provides reliable domain parsing for web scraping, analytics, and URL manipulation tasks."
  spec.email = 'dev@opensite.ai'
  spec.homepage = 'https://github.com/opensite-ai/domain_extractor'
  spec.license = 'MIT'
  spec.metadata = {
    'source_code_uri' => 'https://github.com/opensite-ai/domain_extractor',
    'changelog_uri' => 'https://github.com/opensite-ai/domain_extractor/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://rubydoc.info/gems/domain_extractor',
    'bug_tracker_uri' => 'https://github.com/opensite-ai/domain_extractor/domain_extractor/issues',
    'homepage_uri' => 'https://opensite.ai',
    'wiki_uri' => 'https://docs.devguides.com/domain_extractor',
    'rubygems_mfa_required' => 'true',
    'allowed_push_host' => 'https://rubygems.org'
  }

  spec.add_dependency 'public_suffix', '~> 6.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-performance', '~> 1.18'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'yard', '~> 0.9'

  spec.required_ruby_version = '>= 2.7.0'
  spec.require_paths = ['lib']
  spec.extra_rdoc_files = ['README.md', 'LICENSE.txt', 'CHANGELOG.md']
  spec.rdoc_options = [
    '--main', 'README.md',
    '--title', 'DomainExtractor - URL Domain Component Extractor',
    '--line-numbers',
    '--inline-source'
  ]
end