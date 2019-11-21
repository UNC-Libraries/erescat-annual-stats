# frozen_string_literal: true

module EresStats
  class GovdocNonDWSMonograph < Query
    SQL = <<~SQL
      select distinct b.id
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
      inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
        and vi.varfield_type_code = 'j' and vi.field_content ~* 'Online Gov Doc.*Monograph'
      where b.bcode3 NOT IN ('d', 'n', 'c')
        and not exists (select *
                        from sierra_view.varfield vb
                        where vb.record_id = b.id
                        and vb.marc_tag = '919'
                        and vb.field_content ilike '%dwsgpo%')
    SQL

    OUTFILE = 'govdoc_nondws_monograph.txt'
    EXCLUDED_FIELDS = %w[m001 main_entry corp_auth
                         expansive_edition other_title m919].freeze

    def processors
      [
        DupeChecker.new,
        Warn856uBlank.new,
        Bad856x.new,
        WarnNoAALLocs.new,
        Warn773NotBlank.new(
          [
            'North Carolina general statutes. 2009 ed.',
            'State of North Carolina administrative code',
            'Wilde-Ramsing, Mark. Steady as she goes ... (OCoLC)318361864'
          ]
        ),
        AllowOnlyMatType.new(['z', 'a'])
      ]
    end
  end
end
