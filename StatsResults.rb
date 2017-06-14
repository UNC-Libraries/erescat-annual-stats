class StatsResults
  attr_accessor :results

  def initialize(arry)
    @results = arry
    @results.each do |result|
      result['review'] = ''
      result['remove'] = ''
    end
  end

  def misc_checks
    warn_856u_blank
    warn_856x_not_blank
    warn_no_AAL_locs
  end

  def dupe_check(title_format: 'abpn', oca_ej: false)
    normalize_title(title_format, oca_ej)
    mark_dupes
  end

  def cleared
    return @results.select{ |x| x['review'].empty? && x['remove'].empty? }
  end

  def warned
    return @results.select{ |x| !x['review'].empty? || !x['remove'].empty? }
  end

  def warn_773_not_blank(allowed_array: '')
    checked = []
    @results.each do |result|
      allowed = true
      blank = false
      if result['coll_titles']
        result['coll_titles'].split(";;;").each do |coll|
          if !allowed_array.include?(coll)
            allowed = false
          end
        end
      else
        blank = true
      end
      if !blank && !allowed
        result['review'] += '773 not blank;'
      end
      checked << result
    end
    @results = checked
  end

  def warn_773_has_established_coll
    checked = []
    @results.each do |result|
      if result['coll_titles']
          result['coll_titles'].split(";;;").each do |coll|
            if coll.match(/\(online collection\)/)
              result['review'] += "dupe: #{coll};"
            end
          end
      end
      checked << result
    end
    @results = checked
  end

  def warn_856u_blank
    checked = []
    @results.each do |result|
      unless result['url']
        result['review'] += 'No URL;'
        result['remove'] += 'No URL;'
      end
      checked << result
    end
    @results = checked
  end

  def warn_856x_not_blank
    checked = []
    @results.each do |result|
      allowed = true
      if result['m856x']
        result['m856x'].split(";;;").each do |note|
          allowed = false if note !~ /http:|chk ci|chk kms|ci$|kms$/i
        end
      end
      if !allowed && result['remove'].empty?
        result['review'] += '856x;'
      end
      checked << result
    end
    @results = checked
  end

  def warn_no_AAL_locs
    checked = []
    @results.each do |result|
      if result['bib_locs'].gsub(/,| |noh|k/, "").empty?
        result['review'] += 'Check location;'
        result['remove'] += 'No AAL location;'
      end
      checked << result
    end
    @results = checked
  end

  def warn_no_filmfinder
    checked = []
    @results.each do |result|
      unless result['m919'].to_s.match(/filmfinder/i) || result['bib_locs'].match(/ul/)
        result['review'] += 'no filmfinder scope;'
      end
      checked << result
    end
    @results = checked
  end

  def allow_only_mat_type(allowed_array)
    checked = []
    @results.each do |result|
      unless allowed_array.include?(result['mat_type'])
        result['review'] += 'Check Material Type;'
      end
      checked << result
    end
    @results = checked
  end

  def require_all_location(required_array)
    checked = []
    @results.each do |result|
      required_array.each do |element|
        if !result['bib_locs'].match(/#{element}/)
          result['review'] += "missing #{element} location;"
        end
      end
      checked << result
    end
    @results = checked
  end

  def forbid_any_location(forbidden_array)
    checked = []
    @results.each do |result|
      forbidden_array.each do |element|
        if result['bib_locs'].match(/#{element}/)
          result['review'] += "#{element} location;"
        end
      end
      checked << result
    end
    @results = checked
  end

  def warn_no_archive_url()
    checked = []
    @results.each do |result|
      unless result['url'].match(/archive\.org/i)
        result['review'] += 'no archive.org URL;'
      end
      checked << result
    end
    @results = checked
  end

  def mark_dupes
    checked = []
    @results.group_by { |x| x['TitleMatch'] }.each do |k, grp|
      if grp.length > 1
        puts checked.length
        grp[0]['PossibleDupe'] = 'Dupe0'
        checked << grp[0]
        grp[1..-1].each do |item|
          item['PossibleDupe'] = 'DupeX'
          checked << item
        end
      else
        checked << grp[0]
      end
    end
    @results = checked
  end

  def normalize_title(title_format, oca_ej)
    #for now try with just best_title
    checked = []
    @results.each do |result|
      title = working_title(result, title_format)
      result['our_norm_title'] =
        title.downcase.
          gsub('&', 'and').
          gsub('[electronic resource]', '').
          gsub(/[[:punct:]]/, ' ').
          gsub(/\s\s+/, ' ').strip.tr(
  "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
  "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
  )
      if oca_ej
        result['TitleMatch'] =
          result['our_norm_title'] + " " + result['pubdate'] + result['main_entry'].to_s
      else
        result['TitleMatch'] =
          result['our_norm_title'] + " " + result['pubdate']
      end
      checked << result
    end
    @results = checked
  end

  def working_title(result, format)
    working_title = result["title_#{format}"].to_s
    return working_title
  end

  def write(filename, headers)
    puts "writing: #{filename}"
    CSV.open(filename, 'w', col_sep: "\t") do |csv|
      csv << headers
      @results.each do |result|
        csv << headers.map { |heading| result[heading].to_s }
      end
    end
  end

end