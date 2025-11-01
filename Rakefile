# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :release do
  desc 'Run checks, bump version, and publish the gem'
  task :prepare, [:new_version] => %i[rubocop spec] do |_t, args|
    version = args[:new_version] || ENV.fetch('VERSION', nil)
    abort 'Please provide the new version (e.g. rake release:prepare[1.2.3]).' unless version

    version_file = File.join(__dir__, 'lib', 'domain_extractor', 'version.rb')
    contents = File.read(version_file)
    replacement = contents.sub(/VERSION\s*=\s*['"][^'"]+['"]/) { "VERSION = '#{version}'" }

    abort "Could not update #{version_file}, VERSION constant not found." if contents == replacement

    File.write(version_file, replacement)
    puts "Updated #{version_file} to version #{version}"

    sh('bundle install')
    sh('aicommits --type conventional --stage-all')
    sh('git push origin master')

    tag_name = "v#{version}"
    sh(%(git tag -a #{tag_name} -m "Release version #{version}"))
    sh("git push origin #{tag_name}")
  end
end
