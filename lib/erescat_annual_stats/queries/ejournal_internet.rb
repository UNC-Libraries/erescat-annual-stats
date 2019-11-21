# frozen_string_literal: true

module EresStats
  class EjournalInternet < Query
    SQL = <<~SQL
      with exclude_bibs AS
        (select bil.bib_record_id
        from sierra_view.item_record i
        inner join sierra_view.varfield v on v.record_id = i.id
        inner join sierra_view.bib_record_item_record_link bil on bil.item_record_id = i.id
        where
            (v.varfield_type_code = 'j'
              and (v.field_content ilike '%oca%'
                    or v.field_content ilike '%online gov doc%'
                    or v.field_content ilike '%online database%'
                    or v.field_content ilike '%web site%'))
            or
            (v.varfield_type_code = 'c' and v.field_content ilike '%online db%')
        ),
        holdings_bibs AS
      (select b.id
        from sierra_view.bib_record b
        inner join sierra_view.leader_field ldr on ldr.record_id = b.id
        and ldr.bib_level_code = 's'
        where b.bcode3 NOT IN ('d', 'n', 'c')
        --and not exists
        --(select *
      -- from exclude_bibs
        --where exclude_bibs.bib_record_id = b.id)
        and not exists
        (select *
        from sierra_view.phrase_entry ph
        where ph.record_id = b.id and ph.index_tag = 'o' and ph.index_entry ~ '^ss(ib|j)')
        except select * from exclude_bibs) ,
      item_bibs AS
      (select holdings_bibs.id
        from holdings_bibs
        where NOT EXISTS
        (select * from sierra_view.varfield v
        where v.record_id = holdings_bibs.id
        and (
            (v.marc_tag = '773' and v.field_content ilike '%(online collection)%')
              or
            (v.marc_tag = '040' and v.field_content ilike '%gpo%')
        ))
        )

      select holdings_bibs.id
      --select 'b' || rm.record_num || 'a'
      from holdings_bibs
      inner join sierra_view.bib_record_holding_record_link bhl on bhl.bib_record_id = holdings_bibs.id
      inner join sierra_view.holding_record_item_record_link hil on hil.holding_record_id = bhl.holding_record_id
      inner join sierra_view.holding_record_location h on h.holding_record_id = bhl.holding_record_id
        and h.location_code in ('erri', 'wbcc')
      inner join sierra_view.record_metadata rm on rm.id = holdings_bibs.id
      UNION
      select item_bibs.id
      --select 'b' || rm.record_num || 'a'
      from item_bibs
      inner join sierra_view.bib_record_item_record_link bil on bil.bib_record_id = item_bibs.id
      inner join sierra_view.item_record i on i.id = bil.item_record_id
        and i.location_code in ('erri', 'wbcc')
      inner join sierra_view.record_metadata rm on rm.id = item_bibs.id
    SQL

    OUTFILE = 'ejournal_internet.txt'
    EXCLUDED_FIELDS = %w[m001 corp_auth edition expansive_edition
                         extent other_title m919].freeze

    def processors
      [
        DupeChecker.new(title_format: 'apn'),
        Warn856uBlank.new,
        Bad856x.new,
        WarnNoAALLocs.new,
        ForbidAnyLocation.new(['eb']),
        Warn773NotBlank.new
      ]
    end
  end
end
