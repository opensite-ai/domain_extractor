# Contributing to DomainExtractor

Thank you for your interest in contributing to DomainExtractor! We welcome contributions from the community and appreciate your efforts to improve this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Running Tests](#running-tests)
- [Code Quality](#code-quality)
- [Making Changes](#making-changes)
- [Submitting Pull Requests](#submitting-pull-requests)
- [Release Process](#release-process)
- [Project Structure](#project-structure)
- [Additional Resources](#additional-resources)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please be respectful, inclusive, and constructive in all interactions.

## Getting Started

### Prerequisites

- **Ruby**: 3.2.0 or higher (we test on Ruby 3.2 and 3.3)
- **Bundler**: Latest version recommended
- **Git**: For version control

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/domain_extractor.git
   cd domain_extractor
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/opensite-ai/domain_extractor.git
   ```

## Development Setup

### Install Dependencies

```bash
# Install all gems
bundle install
```

The project uses these development dependencies:
- **rspec** (~> 3.12) - Testing framework
- **rubocop** (~> 1.50) - Ruby linter and formatter
- **rubocop-performance** (~> 1.18) - Performance-focused linting
- **rubocop-rake** (~> 0.7.1) - Rake task linting
- **rubocop-rspec** (~> 2.20) - RSpec-specific linting
- **simplecov** (~> 0.22.0) - Code coverage reporting
- **rake** (~> 13.0) - Task automation

### Verify Setup

Run the default Rake task to ensure everything is working:

```bash
bundle exec rake
```

This runs both RSpec tests and RuboCop linting. All checks should pass.

## Development Workflow

### 1. Create a Feature Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write clean, readable code following the project's style guide
- Add or update tests for your changes
- Update documentation as needed
- Keep commits focused and atomic

### 3. Test Your Changes

```bash
# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Or run both (default task)
bundle exec rake
```

### 4. Commit Your Changes

We use conventional commits for clear, semantic versioning-friendly messages:

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "feat: add support for custom TLD lists"
# or
git commit -m "fix: handle edge case in subdomain parsing"
# or
git commit -m "docs: update README with new examples"
```

**Commit Message Prefixes:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style changes (formatting, no logic change)
- `refactor:` - Code refactoring (no functional change)
- `perf:` - Performance improvements
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks (dependencies, tooling)

### 5. Keep Your Branch Updated

Regularly sync with the upstream repository:

```bash
git fetch upstream
git rebase upstream/master
```

## Running Tests

### Full Test Suite

```bash
bundle exec rspec
```

This runs all tests and generates a coverage report in [coverage/index.html](coverage/index.html).

### Run Specific Tests

```bash
# Run a single test file
bundle exec rspec spec/domain_extractor_spec.rb

# Run a specific test by line number
bundle exec rspec spec/domain_extractor_spec.rb:42

# Run tests matching a pattern
bundle exec rspec spec/domain_extractor_spec.rb -e "multi-part TLD"
```

### View Coverage Report

After running tests, open the HTML coverage report:

```bash
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
start coverage/index.html  # Windows
```

### Coverage Requirements

- **Target**: 100% code coverage
- All new code must include comprehensive tests
- Tests should cover edge cases and error conditions
- SimpleCov generates both HTML and JSON reports

## Code Quality

### RuboCop Linting

Run RuboCop to check code style:

```bash
# Check all files
bundle exec rubocop

# Auto-fix safe violations
bundle exec rubocop -a

# Auto-fix all violations (including unsafe)
bundle exec rubocop -A

# Check specific files
bundle exec rubocop lib/domain_extractor.rb
```

### Code Style Guidelines

The project enforces these style rules (see [.rubocop.yml](.rubocop.yml)):

#### String Literals
```ruby
# Good 
'single quotes for strings'

# Bad L
"double quotes without interpolation"
```

#### Frozen String Literals
All Ruby files must start with:
```ruby
# frozen_string_literal: true
```

#### Line Length
- **Maximum**: 120 characters
- Long comment lines are allowed

#### Method Length
- **Maximum**: 15 lines (not enforced in specs)
- Keep methods focused and single-purpose

#### Module-Based Architecture
```ruby
# Good  - Module with module_function
module MyModule
  module_function

  def parse(input)
    # Implementation
  end
end

# Bad L - Class for stateless operations
class MyClass
  def self.parse(input)
    # Implementation
  end
end
```

### Performance Considerations

This is a performance-critical library. When making changes:

1. **Use frozen constants** for immutable data
2. **Minimize object allocations**
3. **Leverage fast-path detection** for common cases
4. **Benchmark your changes** using [benchmark/performance.rb](benchmark/performance.rb)

Run benchmarks to verify performance:

```bash
./benchmark/performance.rb
```

## Making Changes

### Adding New Features

1. **Discuss first**: For major features, open an issue to discuss the design
2. **Write tests first**: Consider TDD (Test-Driven Development)
3. **Update documentation**:
   - Update [README.md](README.md) with usage examples
   - Update [CHANGELOG.md](CHANGELOG.md) under "Unreleased" section
   - Add inline code comments for complex logic
4. **Maintain backward compatibility**: Avoid breaking existing APIs

### Fixing Bugs

1. **Add a failing test** that demonstrates the bug
2. **Fix the bug** with minimal changes
3. **Verify the test passes**
4. **Update [CHANGELOG.md](CHANGELOG.md)** under "Fixed" section

### Updating Documentation

Documentation improvements are always welcome:
- Fix typos or clarify confusing sections
- Add examples for common use cases
- Improve inline code comments
- Update [README.md](README.md), [CHANGELOG.md](CHANGELOG.md), or docs in [docs/](docs/)

## Submitting Pull Requests

### Before Submitting

Ensure your PR meets these requirements:

-  All tests pass (`bundle exec rspec`)
-  RuboCop checks pass (`bundle exec rubocop`)
-  Code coverage is maintained at 100%
-  Commit messages follow conventional format
-  Documentation is updated
-  [CHANGELOG.md](CHANGELOG.md) is updated (if applicable)
-  Branch is up-to-date with `master`

### Submitting

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Open a Pull Request on GitHub

3. Fill out the PR template with:
   - Clear description of the changes
   - Motivation and context
   - Related issue numbers (if any)
   - Screenshots (if UI-related)

4. Wait for CI checks to complete:
   - Tests run on Ruby 3.2 and 3.3
   - RuboCop linting (Ruby 3.3 only)
   - Coverage uploaded to Codecov and qlty

### After Submitting

- **Respond to feedback** promptly
- **Make requested changes** in new commits (don't force-push)
- **Rebase if needed** to keep history clean
- **Be patient** - maintainers will review when available

## Release Process

The release process is automated for maintainers:

### For Maintainers

1. **Ensure all tests and checks pass**:
   ```bash
   bundle exec rake
   ```

2. **Update [CHANGELOG.md](CHANGELOG.md)**:
   - Move items from "Unreleased" to new version section
   - Follow [Keep a Changelog](https://keepachangelog.com/) format
   - Use semantic versioning (MAJOR.MINOR.PATCH)

3. **Run the release task**:
   ```bash
   bundle exec rake "release:prepare[0.2.4]"
   ```

   This automated task:
   -  Runs RuboCop and RSpec
   -  Updates `lib/domain_extractor/version.rb`
   -  Updates `Gemfile.lock`
   -  Creates a conventional commit using `aicommits`
   -  Pushes to master branch
   -  Creates and pushes a git tag (e.g., `v0.2.4`)

4. **GitHub Actions automatically publishes**:
   - Release workflow triggers on tag push
   - Uses `rubygems/release-gem@v1` action
   - Builds and publishes to [RubyGems.org](https://rubygems.org/gems/domain_extractor)
   - Requires MFA (configured in gemspec)

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.2.0): New features, backward compatible
- **PATCH** (0.2.3): Bug fixes, backward compatible

### Manual Gem Building (Testing)

To test gem building locally:

```bash
# Build the gem
gem build domain_extractor.gemspec

# Install locally
gem install ./domain_extractor-0.2.3.gem

# Test in a Ruby console
irb -r domain_extractor
```

## Project Structure

```
domain_extractor/
   lib/                          # Source code (342 lines)
      domain_extractor.rb       # Main entry point
      domain_extractor/
          version.rb            # Version constant
          errors.rb             # Custom exceptions
          normalizer.rb         # URL normalization
          validators.rb         # IPv4/IPv6 detection
          parser.rb             # Core parsing logic
          result.rb             # Result hash builder
          query_params.rb       # Query string parser
          parsed_url.rb         # ParsedURL API wrapper
   spec/                         # Test suite (797 lines)
      spec_helper.rb            # RSpec + SimpleCov config
      domain_extractor_spec.rb  # Core functionality tests
      parsed_url_spec.rb        # ParsedURL API tests
   docs/                         # Detailed documentation
      PARSED_URL_API.md
      PARSED_URL_QUICK_START.md
      PERFORMANCE.md
      OPTIMIZATION_SUMMARY.md
      RELEASE_0.1.2.md
   benchmark/                    # Performance testing
      performance.rb
   .github/workflows/            # CI/CD automation
      ci.yml                    # Continuous integration
      release.yml               # Automated gem publishing
   README.md                     # Main documentation
   CHANGELOG.md                  # Version history
   CONTRIBUTING.md               # This file
   domain_extractor.gemspec      # Gem specification
```

### Key Components

- **[DomainExtractor](lib/domain_extractor.rb)**: Main API (`.parse`, `.parse_batch`, `.parse_query_params`)
- **[Parser](lib/domain_extractor/parser.rb)**: Orchestrates parsing pipeline
- **[Normalizer](lib/domain_extractor/normalizer.rb)**: URL normalization
- **[Validators](lib/domain_extractor/validators.rb)**: IPv4/IPv6 detection
- **[Result](lib/domain_extractor/result.rb)**: Builds result hashes
- **[QueryParams](lib/domain_extractor/query_params.rb)**: Query string parser
- **[ParsedURL](lib/domain_extractor/parsed_url.rb)**: Object-oriented API wrapper

### Architecture Philosophy

- **Module-based**: All components are stateless modules using `module_function`
- **Fail-safe**: Returns `nil` for invalid input (no exceptions)
- **Performance-first**: Frozen constants, minimal allocations
- **Explicit dependencies**: Clear separation of concerns
- **Standard library first**: Uses Ruby's URI and string methods

## Additional Resources

### Documentation

- **[README.md](README.md)**: Comprehensive usage guide
- **[CHANGELOG.md](CHANGELOG.md)**: Version history and release notes
- **[docs/PARSED_URL_API.md](docs/PARSED_URL_API.md)**: Complete API reference
- **[docs/PERFORMANCE.md](docs/PERFORMANCE.md)**: Performance analysis
- **[CLAUDE.md](CLAUDE.md)**: AI assistant guidance (not distributed)

### External Links

- **Gem**: https://rubygems.org/gems/domain_extractor
- **GitHub**: https://github.com/opensite-ai/domain_extractor
- **Issues**: https://github.com/opensite-ai/domain_extractor/issues
- **CI Status**: https://github.com/opensite-ai/domain_extractor/actions
- **Code Climate**: https://codeclimate.com/github/opensite-ai/domain_extractor
- **RubyDoc**: https://rubydoc.info/gems/domain_extractor

### Getting Help

- **Questions**: Open a [GitHub Discussion](https://github.com/opensite-ai/domain_extractor/discussions)
- **Bugs**: Open a [GitHub Issue](https://github.com/opensite-ai/domain_extractor/issues)
- **Email**: dev@opensite.ai

### Related Resources

- **Public Suffix List**: https://publicsuffix.org/
- **Ruby Style Guide**: https://rubystyle.guide/
- **Semantic Versioning**: https://semver.org/
- **Keep a Changelog**: https://keepachangelog.com/

---

Thank you for contributing to DomainExtractor! Your efforts help make this library better for everyone. <‰
