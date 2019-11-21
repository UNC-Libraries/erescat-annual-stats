# frozen_string_literal: true

module EresStats
  class Warn856uBlank
    def process(results)
      results.each do |result|
        next if m856u?(result)

        result.review('No URL')
        result.remove('No URL')
      end
    end

    def m856u?(result)
      !result.url.empty?
    end
  end
end
