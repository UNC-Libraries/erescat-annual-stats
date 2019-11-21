# frozen_string_literal: true

module EresStats
  class WarnNoAALLocs
    def process(results)
      results.each do |result|
        next if aal_locs?(result)

        result.review('Check location')
        result.remove('No AAL location')
      end
    end

    def aal_locs?(result)
      result.bib_locs.reject { |loc| loc =~ /^noh|^k/ }.any?
    end
  end
end
