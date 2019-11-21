# frozen_string_literal: true

module EresStats
  class EjournalOCA < Query
    SQL = <<~SQL
      select distinct b.id
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
      inner join sierra_view.varfield v on v.record_id = bl.item_record_id
        and v.varfield_type_code = 'j' and v.field_content ilike '%OCA electronic journal%'
      where b.bcode3 NOT IN ('d', 'n', 'c')
    SQL

    OUTFILE = 'ejournal_oca.txt'
    EXCLUDED_FIELDS = %w[m001 corp_auth edition expansive_edition
                         extent other_title m919].freeze

    def processors
      [
        DupeChecker.new(include_main_entry: true),
        Warn856uBlank.new,
        Bad856x.new,
        WarnNoAALLocs.new,
        WarnNoArchiveURL.new,
        ForbidAnyLocation.new(['eb']),
        Warn773NotBlank.new
      ]
    end
  end
end
