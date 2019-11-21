# frozen_string_literal: true

module EresStats
  class Bad856x
    def process(results)
      results.each do |result|
        result.review('856x') if bad_856x?(result)
      end
    end

    def bad_856x?(result)
      result.m856x.each do |m856x|
        return true unless m856x.empty? ||
                           m856x =~ /http:|chk ci|chk kms|ci$|kms$|ocalink/i
      end
      false
    end
  end
end
