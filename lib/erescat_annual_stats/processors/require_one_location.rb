module EresStats
  # warn if a record has none of the permitted locations; >=1 req loc is okay
  class RequireOneLocation
    attr_reader :locs

    def initialize(required = [])
      @locs = required
    end

    def process(results)
      results.each do |result|
        next if any_required_loc?(result)

        result.review(
          "#{result.bib_locs.join(', ')} contains 0 required locations"
        )
      end
    end

    def any_required_loc?(result)
      result.bib_locs.any? { |bib_loc| locs.include?(bib_loc) }
    end
  end
end
