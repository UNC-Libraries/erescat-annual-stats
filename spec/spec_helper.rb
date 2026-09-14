# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

ENV['SIERRA_DELAY_CONNECT'] = '1'

require 'erescat_annual_stats'

def make_result(data)
  EresStats::Result.new(data)
end
