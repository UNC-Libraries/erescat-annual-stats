# frozen_string_literal: true

module EresStats
  class RequireAllLocations
    attr_reader :locs

    def initialize(locs = [])
      @locs = locs
    end

    def process(results)
      results.each do |result|
        lacking = locations_lacking(result)
        next if lacking.empty?

        lacking.each { |loc| result.review("Missing #{loc} location") }
      end
    end

    def locations_lacking(result)
      locs - result.bib_locs
    end
  end
end
