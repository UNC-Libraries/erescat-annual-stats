# frozen_string_literal: true

module EresStats
  class CollData < Query
    SQL = <<~SQL
      SELECT
        lower(v.field_content) as collection,
        COUNT(v.record_id) as count
      FROM
        sierra_view.varfield v
      INNER JOIN
        sierra_view.bib_record b
        ON v.record_id = b.record_id
        AND b.bcode3 NOT IN ('d', 'n', 'c')
      WHERE
        v.varfield_type_code = 'w'
        AND v.marc_tag = '773'
        AND v.field_content ~* '\(online collection\)|Undergraduate library Kindle ebook collection'
      GROUP BY lower(v.field_content)
      ORDER BY lower(v.field_content) ASC
    SQL

    OUTFILE = 'coll_sql_results.txt'
    FIELDS = %w[collection count].freeze

    # this doesn't use the pre- and post- data grab query form
    def full_query
      SQL
    end
  end
end
