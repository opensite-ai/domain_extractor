# frozen_string_literal: true

require 'bundler/setup'
require 'domain_extractor'

require 'simplecov'
require 'simplecov_json_formatter'
SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::JSONFormatter,
                                                       SimpleCov::Formatter::HTMLFormatter
                                                     ])
  add_filter '/spec/'
end

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed
end
