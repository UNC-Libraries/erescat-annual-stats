# frozen_string_literal: true

module EresStats
  class GovdocDWS < Query
    SQL = <<~SQL
      select distinct 'b' || rm.record_num || 'a' as bnum,
      (
        SELECT STRING_AGG(sf.content, ';;;')
        FROM sierra_view.varfield vs
        INNER JOIN sierra_view.subfield sf on sf.varfield_id = vs.id
        WHERE vs.record_id = b.id
        AND vs.marc_tag = '856'
        AND sf.tag = 'u'
        GROUP BY vs.record_id
      ) AS url
      from sierra_view.bib_record b
      inner join sierra_view.record_metadata rm on rm.id = b.id
      inner join sierra_view.varfield v on v.record_id = b.id
      and v.marc_tag = '919' and v.field_content ilike '%dwsgpo%'
      where b.bcode3 NOT IN ('d', 'n', 'c')
    SQL

    OUTFILE = 'govdoc_dws.txt'
    FIELDS = %w[bnum url remove].freeze

    def processors
      [
        Warn856uBlank.new
      ]
    end

    # this doesn't use the pre- and post- data grab query form; too many results
    # and practically none of the grabbed fields get used
    def full_query
      SQL
    end
  end
end
