# frozen_string_literal: true

module EresStats
  class Warn773EstablishedColl
    def process(results)
      results.each do |result|
        established = established_773s(result)
        next if established.empty?

        established.each { |coll| result.review("Dupe: #{coll}") }
      end
    end

    def established_773s(result)
      result.coll_titles.select { |coll| coll =~ /\(online collection\)/ }
    end
  end
end
