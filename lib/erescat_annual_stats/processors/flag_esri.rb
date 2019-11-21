# frozen_string_literal: true

module EresStats
  class FlagESRI
    def process(results)
      results.each do |result|
        if esri?(result)
          result.remove('Do not count in general Online Dataset count. Count for ESRI data sets collection')
        end
      end
    end

    def esri?(result)
      return true if result.m919 =~ /EsriDatasets/i

      false
    end
  end
end
