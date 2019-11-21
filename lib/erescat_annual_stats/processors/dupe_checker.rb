# frozen_string_literal: true

module EresStats
  class DupeChecker
    attr_reader :include_main_entry

    def initialize(include_main_entry: false)
      @include_main_entry = include_main_entry
    end

    def process(results)
      results.each { |r| r.set_titlematch(include_main_entry: include_main_entry) }
      mark_dupes(results)
    end

    def mark_dupes(results)
      results.group_by(&:titlematch).each do |_k, grp|
        next unless grp.length > 1

        first = grp.shift
        first.dupe_status('Dupe0')
        grp.each { |other| other.dupe_status('DupeX') }
      end
      nil
    end
  end
end
