# frozen_string_literal: true

require 'bundler/setup'
require 'domain_extractor'

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed
end
