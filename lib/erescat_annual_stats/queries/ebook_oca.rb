# frozen_string_literal: true

module EresStats
  class EbookOCA < Query
    SQL = <<~SQL
      select distinct b.id
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
      inner join sierra_view.varfield v on v.record_id = bl.item_record_id
        and v.varfield_type_code = 'j' and v.field_content ilike '%OCA electronic book%'
      where b.bcode3 NOT IN ('d', 'n', 'c')
    SQL

    OUTFILE = 'ebook_oca.txt'

    def processors
      [
        DupeChecker.new,
        Warn856uBlank.new,
        WarnNoAALLocs.new,
        RequireAllLocations.new(['eb', 'er'])
      ]
    end
  end
end
