# frozen_string_literal: true

module EresStats
  class ForbidAnyLocation
    attr_reader :locs

    def initialize(forbidden = [])
      @locs = forbidden
    end

    def process(results)
      results.each do |result|
        forbidden = forbidden_locs(result)
        next if forbidden.empty?

        forbidden.each { |loc| result.review("#{loc} location") }
      end
    end

    def forbidden_locs(result)
      result.bib_locs.select { |bib_loc| locs.include?(bib_loc) }
    end
  end
end
