# frozen_string_literal: true

module EresStats
  class DatasetOnline < Query
    SQL = <<~SQL
      select distinct b.id
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
      left outer join sierra_view.varfield vi on vi.record_id = bl.item_record_id
        and vi.varfield_type_code = 'j' and vi.field_content ilike '%Online Dataset%'
      inner join sierra_view.item_record i on i.id = bl.item_record_id
      where b.bcode3 NOT IN ('d', 'n', 'c')
          and ( i.location_code in ('errd', 'errs', 'errw') or vi.record_id = bl.item_record_id)
    SQL

    OUTFILE = 'dataset_online.txt'
    EXCLUDED_FIELDS = %w[m001 main_entry corp_auth edition
                         resp_stmt extent other_title].freeze

    def processors
      [
        DupeChecker.new,
        Warn856uBlank.new,
        Bad856x.new,
        WarnNoAALLocs.new,
        FlagESRI.new,
        ForbidAnyLocation.new(['eb']),
        Warn773NotBlank.new(
          [
            '|7c2es|aEnvironmental Systems Research Institute (Redlands, Calif.).|tESRI data & maps|w(OCoLC)52103844'
          ]
        )
      ]
    end
  end
end
