# frozen_string_literal: true

module EresStats
  class DatabaseOnline < Query
    SQL = <<~SQL
      select distinct b.id
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
      inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
        and (
          (vi.varfield_type_code = 'j' and vi.field_content ilike '%Online Database%')
          or
          (vi.varfield_type_code = 'c' and vi.field_content ilike '%ONLINE DB%')
        )
      where b.bcode3 NOT IN ('d', 'n', 'c')
    SQL

    OUTFILE = 'database_online.txt'
    EXCLUDED_FIELDS = %w[m001 corp_auth edition expansive_edition
                         extent other_title m919].freeze

    def processors
      [
        DupeChecker.new,
        Warn856uBlank.new,
        Bad856x.new,
        WarnNoAALLocs.new,
        Warn773NotBlank.new(
          [
            'Ambrose video 2.0.|d[New York] : Ambrose Video Publishing|w(OCoLC)601901399',
            'America\'s historical imprints',
            'America\'s historical newspapers.',
            'Archives direct',
            'BBC Shakespeare plays (online collection)',
            'Black studies center',
            'BrillOnline Primary sources',
            'Division of Social science research network (OCoLC)44325651',
            'Music online: listening (online collection)',
            '|iPart of collection:|tArchives unbound',
            'ProQuest history vault. Southern life and slavery',
            '|aWorld newspaper archive|w(OCoLC)277239916',
            'World newspaper archive.|d[Naples, Fla.] : Readex|w(DLC)  2009252495|w(OCoLC)277239916'
          ]
        )
      ]
    end
  end
end
