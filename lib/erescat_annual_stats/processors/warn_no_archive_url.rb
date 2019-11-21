# frozen_string_literal: true

module EresStats
  class WarnNoArchiveURL
    def process(results)
      results.each do |result|
        next if archive_url?(result)

        result.review('no archive.org URL')
      end
    end

    def archive_url?(result)
      return true if result.url =~ /archive\.org/i

      false
    end
  end
end
