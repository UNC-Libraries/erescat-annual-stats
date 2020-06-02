# frozen_string_literal: true

module EresStats
  class Query
    # These take the query-specific SQL that identifies records
    # relevant to the query and wrap it as a CTE, then extract all of the
    # data that any query would need from the records identified by the CTE.
    SQL_PRE = "WITH\nresult_bibs AS( "
    SQL_POST = <<~SQL
      ),
      pubdate AS (
      SELECT c.p07 || c.p08 || c.p09 || c.p10 AS pubdate,
            c.record_id
      FROM sierra_view.control_field c
      INNER JOIN result_bibs
      ON c.record_id = result_bibs.id
      WHERE c.control_num = 8
      )

      select 'b' || rm.record_num || 'a' as bnum,
              to_char(rm.creation_date_gmt, 'YYYY-MM-DD') as creation_date,
              result_bibs.id,
              bp.best_title,
              bp.best_title_norm,
              pubdate.pubdate,
              v.field_content as m001,
      (
              SELECT STRING_AGG(field_content, ';;;')
              FROM sierra_view.varfield v
              WHERE v.record_id = result_bibs.id
              AND v.marc_tag in ('100', '110', '111', '130')
              GROUP BY v.record_id
          ) AS main_entry,
      (
              SELECT STRING_AGG(content, ';;;')
              FROM sierra_view.subfield sf
              WHERE sf.record_id = result_bibs.id
              AND sf.marc_tag = '245'
              AND sf.tag = 'c'
              GROUP BY sf.record_id
          ) AS state_resp,

      (
              SELECT STRING_AGG(content, ';;;')
              FROM sierra_view.subfield sf
              WHERE sf.record_id = result_bibs.id
              AND sf.marc_tag = '856'
              AND sf.tag = 'u'
              GROUP BY sf.record_id
          ) AS url,
            (
              SELECT STRING_AGG(urlx.content, ';;;')
              FROM sierra_view.subfield urlx
              WHERE urlx.record_id = result_bibs.id
              AND urlx.marc_tag = '856'
              AND urlx.tag = 'x'
            ) AS m856x,
            (
              SELECT STRING_AGG(
                regexp_replace(sst.field_content, '^[|]t', ''),
                                ';;;')
              FROM sierra_view.varfield sst
              WHERE sst.record_id = result_bibs.id
              AND sst.marc_tag = '773'
              ) AS coll_titles,
              bp.material_code AS mat_type,
            (
              SELECT STRING_AGG(brl.location_code, ', ')
              FROM sierra_view.bib_record_location brl
              WHERE brl.bib_record_id = result_bibs.id
              AND brl.location_code != 'multi'
              ) AS bib_locs,
      (
              SELECT STRING_AGG(field_content, ';;;')
              FROM sierra_view.varfield v
              WHERE v.record_id = result_bibs.id
              AND v.marc_tag = '919'
              GROUP BY v.record_id
          ) AS m919,
      (
              SELECT STRING_AGG(field_content, ';;;')
              FROM sierra_view.varfield v
              WHERE v.record_id = result_bibs.id
              AND v.marc_tag = '250'
              GROUP BY v.record_id
          ) AS edition,
      (
              SELECT STRING_AGG(field_content, ';;;')
              FROM sierra_view.varfield v
              WHERE v.record_id = result_bibs.id
              AND v.marc_tag in ('250', '251', '254', '255', '256', '257', '258')
              GROUP BY v.record_id
          ) AS expansive_edition,
      (
              SELECT STRING_AGG(content, ';;;')
              FROM sierra_view.subfield sf
              WHERE sf.record_id = result_bibs.id
              AND sf.marc_tag = '300'
              AND sf.tag = 'a'
              GROUP BY sf.record_id
          ) AS extent,
      (
              SELECT STRING_AGG(field_content, ';;;')
              FROM sierra_view.varfield v
              WHERE v.record_id = result_bibs.id
              AND v.marc_tag = '110'
              GROUP BY v.record_id
          ) AS corp_auth
      from result_bibs
      inner join pubdate on pubdate.record_id = result_bibs.id
      inner join sierra_view.bib_record_property bp on bp.bib_record_id = result_bibs.id
      inner join sierra_view.record_metadata rm on rm.id = result_bibs.id
      inner join sierra_view.varfield v on v.record_id = result_bibs.id
        and marc_tag = '001'
    SQL

    # Combines
    #   - SQL that identifies the records relevant to the query
    #   - SQL to retrieve information about those records
    def full_query
      SQL_PRE + sql + SQL_POST
    end

    # SQL that identifies the records relevant to the query.
    def sql
      self.class::SQL
    end

    def db_data
      Sierra::DB.query(full_query).all
    end

    def results
      return @results if @results

      results = db_data.map { |r| EresStats::Result.new(r) }
      process(results)
      @results = results
    end

    # Runs Processors that add flags, warnings, etc to records
    def process(unprocessed_results)
      processors.each { |p| p.process(unprocessed_results) }
    end

    def processors
      []
    end

    def write_results
      CSV.open(outfile, 'w', col_sep: "\t") do |csv|
        csv << fields
        results.each { |result| csv << result.output(fields) }
      end
    end

    # Default fields that get output are ALL_FIELDS - EXCLUDED_FIELDS
    #
    # Subclasses can modify the fields that are output by
    # - setting FIELDS with a list of the fields to export,
    # - or, setting their own EXCLUDED_FIELDS to exclude a different set of
    #     fields from ALL_FIELDS

    # array of fields to export for a query
    def fields
      return self.class::FIELDS if defined?(self.class::FIELDS)

      self.class::ALL_FIELDS - self.class::EXCLUDED_FIELDS
    end

    # set of fields available for output
    ALL_FIELDS = %w[bnum m001 best_title pubdate
                    main_entry corp_auth resp_stmt edition expansive_edition
                    extent other_title
                    url m856x coll_titles m919
                    mat_type bib_locs our_norm_title TitleMatch PossibleDupe
                    creation_date review remove].freeze

    # default set of fields to exclude from the output
    EXCLUDED_FIELDS = %w[m001 main_entry corp_auth resp_stmt edition
                         expansive_edition extent other_title].freeze

    # filename to write to
    def outfile
      self.class::OUTFILE
    end

    Dir[File.join(__dir__, 'queries', '*.rb')].each { |file| require file }
  end
end
