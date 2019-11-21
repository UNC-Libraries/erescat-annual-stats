# frozen_string_literal: true

module EresStats
  class Result
    private

    attr_reader :data

    public

    attr_reader :m919, :bib_locs, :url, :m856x, :coll_titles,
                :mat_type, :titlematch

    def initialize(data = {})
      @data = data.to_hash
      @m919 = data[:m919] || ''
      @url = data[:url] || ''
      @mat_type = data[:mat_type] || ''
      @bib_locs = data[:bib_locs]&.split(', ') || []
      @m856x = data[:m856x]&.split(';;;') || []
      @coll_titles = data[:coll_titles]&.split(';;;') || []
      @review = []
      @remove = []
    end

    # If passed a review note appends it to the array; otherwise, returns the
    # array
    def review(message = nil)
      return @review unless message

      @review << message
    end

    # If passed a remove note appends it to the array; otherwise, returns the
    # array
    def remove(message = nil)
      return @remove unless message

      @remove << message
    end

    # Transforms given array of fields into values for those fields.
    def output(fields)
      fields.map do |heading|
        case heading
        when 'remove'
          remove.join('; ')
        when 'review'
          review.join('; ')
        else
          @data[heading.to_sym].to_s
        end
      end
    end

    # Sets dupe status, so that a set of duplicate records is only counted once.
    # Values are:
    #   'Dupe0' for the first dupe in a set
    #   'DupeX' for remaining dupes in a set of dupes
    #   and nothing is set for non-dupes
    def dupe_status(value)
      data[:PossibleDupe] = value
    end

    # Sets title used to detect duplicate records
    def set_titlematch(include_main_entry: false)
      titlematch = "#{data[:best_title_norm]} #{data[:pubdate]}"
      titlematch += data[:main_entry].to_s if include_main_entry
      @titlematch = data[:TitleMatch] = titlematch.strip
    end
  end
end
