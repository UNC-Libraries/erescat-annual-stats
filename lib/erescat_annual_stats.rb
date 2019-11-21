# frozen_string_literal: true

require 'csv'
require 'sierra_postgres_utilities'

module EresStats
  require_relative 'erescat_annual_stats/query.rb'
  require_relative 'erescat_annual_stats/result.rb'

  Dir[File.join(__dir__, 'erescat_annual_stats/processors', '*.rb')].
    each { |file| require file }
end
