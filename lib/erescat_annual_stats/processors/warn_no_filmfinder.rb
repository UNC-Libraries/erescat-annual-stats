# frozen_string_literal: true

module EresStats
  class WarnNoFilmfinder
    def process(results)
      results.each do |result|
        result.review('No filmfinder scope') unless filmfinder?(result)
      end
    end

    def filmfinder?(result)
      return true if result.m919 =~ /filmfinder/i || result.bib_locs.grep(/^ul/).any?

      false
    end
  end
end
