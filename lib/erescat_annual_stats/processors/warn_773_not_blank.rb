# frozen_string_literal: true

module EresStats
  class Warn773NotBlank
    attr_reader :allowed

    def initialize(allowed = [])
      @allowed = allowed
    end

    def process(results)
      results.each do |result|
        result.review('773 not blank') if disallowed_773?(result)
      end
    end

    def disallowed_773?(result)
      (result.coll_titles - allowed).any?
    end
  end
end
