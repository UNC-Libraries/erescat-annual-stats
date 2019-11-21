# frozen_string_literal: true

module EresStats
  class EjournalSersol < Query
    SQL = <<~SQL
      select distinct b.id
      from sierra_view.phrase_entry ph
      inner join sierra_view.bib_record b on b.id = ph.record_id
          and b.bcode3 NOT IN ('d', 'n', 'c')
      inner join sierra_view.bib_record_holding_record_link bhl on bhl.bib_record_id = b.id
      inner join sierra_view.holding_record_location hl on hl.holding_record_id = bhl.holding_record_id
          and hl.location_code = 'erri'
      where (ph.index_tag || ph.index_entry) ~ '^oss(ib|j)'
    SQL

    OUTFILE = 'ejournal_sersol.txt'
    EXCLUDED_FIELDS = %w[corp_auth edition expansive_edition
                         extent other_title m919].freeze

    def processors
      [
        DupeChecker.new,
        Warn856uBlank.new,
        WarnNoAALLocs.new
      ]
    end
  end
end
