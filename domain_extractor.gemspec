# frozen_string_literal: true

require_relative 'lib/domain_extractor/version'

Gem::Specification.new do |spec|
  # ========================================================================
  # REQUIRED ATTRIBUTES
  # ========================================================================

  spec.name = 'domain_extractor'
  spec.version = DomainExtractor::VERSION
  spec.authors = ['OpenSite AI']
  spec.summary = 'High-performance url parser and domain extractor for Ruby'

  # Files to include in the gem
  spec.files = Dir.glob('{lib,spec}/**/*') + %w[
    README.md
    LICENSE.txt
    CHANGELOG.md
    .rubocop.yml
  ]

  spec.description = 'DomainExtractor is a high-performance url parser and domain parser for Ruby. It delivers precise domain extraction, query parameter parsing, url normalization, and multi-part tld parsing via public_suffix for web scraping and analytics workflows.'
  spec.email = 'dev@opensite.ai'
  spec.homepage = 'https://github.com/opensite-ai/domain_extractor'
  spec.license = 'MIT'
  spec.metadata = {
    'source_code_uri' => 'https://github.com/opensite-ai/domain_extractor',
    'changelog_uri' => 'https://github.com/opensite-ai/domain_extractor/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://rubydoc.info/gems/domain_extractor',
    'bug_tracker_uri' => 'https://github.com/opensite-ai/domain_extractor/issues',
    'homepage_uri' => 'https://opensite.ai',
    'wiki_uri' => 'https://docs.devguides.com/domain_extractor',
    'rubygems_mfa_required' => 'true',
    'allowed_push_host' => 'https://rubygems.org'
  }

  spec.add_dependency 'public_suffix', '~> 6.0'

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
