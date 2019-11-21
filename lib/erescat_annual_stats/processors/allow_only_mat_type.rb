# frozen_string_literal: true

module EresStats
  class AllowOnlyMatType
    attr_reader :types

    def initialize(allowed = [])
      @types = allowed
    end

    def process(results)
      results.each do |result|
        result.review('Check material type') unless allowed_mat_type?(result)
      end
    end

    def allowed_mat_type?(result)
      return true if types.include?(result.mat_type)

      false
    end
  end
end
