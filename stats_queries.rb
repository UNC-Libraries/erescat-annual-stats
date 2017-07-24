load '../postgres_connect/connect.rb'
load 'StatsResults.rb'
c = Connect.new

full = ['bnum', 'best_title', 'pubdate', 'main_entry', 'corp_auth', 'resp_stmt', 'edition', 'extent',
          'other_title', 'url', 'm856x', 'coll_titles', 'm919', 'mat_type', 'bib_locs',
          'our_norm_title', 'TitleMatch', 'PossibleDupe', 'review', 'remove']
# 'expansive_edition' (25? fields) is not listed in full; used only in dataset_online
# 'm001' is not listed in full; used only in sersol_ejournals
standard = full - ['main_entry', 'corp_auth', 'resp_stmt', 'edition', 'extent', 'other_title']
#standard =  bnum, title, pubdate, url, 856x, 773, 919, mat_type, bib_locs


data_grab_pre = "WITH\nresult_bibs AS( "
# begin data_grab_post
data_grab_post = <<-EOT
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
        result_bibs.id,
				bp.best_title,
				bp.best_title_norm,
        (select string_agg(content, ' ' ORDER BY display_order ASC)
          from sierra_view.subfield_view sf
          where sf.record_id = result_bibs.id
            and marc_tag = '245'
            and tag in ('a', 'b', 'p', 'n')
        ) as title_abpn,
        (select string_agg(content, ' ' ORDER BY display_order ASC)
          from sierra_view.subfield_view sf
          where sf.record_id = result_bibs.id
            and marc_tag = '245'
            and tag in ('a', 'p', 'n')
        ) as title_apn,
				pubdate.pubdate,
        v.field_content as m001,
(
        SELECT STRING_AGG(field_content, ';;;')
        FROM sierra_view.varfield v
        WHERE v.record_id = result_bibs.id
        AND v.marc_tag like '1%'
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
        AND v.marc_tag like '25_'
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
EOT
# end data_grab_post


# E-Books > General collection ebooks
# ebook_gencoll
#
ebook_gencoll = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and (
     (vi.varfield_type_code = 'j' and vi.field_content ilike '%E-book%')
     or
     (vi.varfield_type_code = 'c' and vi.field_content ~* '^[|]a *INTERNET *$')
   )
where b.bcode3 NOT IN ('d', 'n', 'c')
  and NOT EXISTS(select *
                from sierra_view.varfield vb
                where vb.record_id = b.id
                and vb.marc_tag = '040'
                and vb.field_content ilike '%GPO%')
EOT

c.make_query(data_grab_pre + ebook_gencoll + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.warn_773_has_established_coll
r.dupe_check
r.misc_checks
r.require_all_location(['eb', 'er'])
r.write('ebook_gencoll.txt',
         standard - ['m919'])



# E-Books > OCA e-books
# ebook_oca
#
ebook_oca = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield v on v.record_id = bl.item_record_id
   and v.varfield_type_code = 'j' and v.field_content ilike '%OCA electronic book%'
where b.bcode3 NOT IN ('d', 'n', 'c')
EOT
c.make_query(data_grab_pre + ebook_oca + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks(skip_856x: true)
r.require_all_location(['eb', 'er'])
r.write('ebook_oca.txt',
        standard - ['m856x', 'm919'])

# E-Journals > SerialsSolutions E-journals
# ejournal_sersol
#
ejournal_sersol = <<-EOT
select distinct b.id
from sierra_view.phrase_entry ph
inner join sierra_view.bib_record b on b.id = ph.record_id
		and b.bcode3 NOT IN ('d', 'n', 'c')
inner join sierra_view.bib_record_holding_record_link bhl on bhl.bib_record_id = b.id
inner join sierra_view.holding_record_location hl on hl.holding_record_id = bhl.holding_record_id
    and hl.location_code = 'erri'
where (ph.index_tag || ph.index_entry) ~ '^oss(ib|j)'
EOT
c.make_query(data_grab_pre + ejournal_sersol + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks(skip_856x: true)
r.write('ejournal_sersol.txt',
        (full -
        ['corp_auth', 'edition', 'extent', 'other_title', 'm919']
        ).insert(1, 'm001')
)


# E-Journals > Internet Journals
# ejournal_internet
ejournal_internet = <<-EOT
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
EOT
c.make_query(data_grab_pre + ejournal_internet + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.forbid_any_location(['eb'])
r.warn_773_not_blank
r.write('ejournal_internet.txt',
        full - ['corp_auth', 'edition', 'extent', 'other_title', 'm919'])



# E-Journals > OCA Electronic Journals
# ejournal_oca
#
ejournal_oca = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield v on v.record_id = bl.item_record_id
   and v.varfield_type_code = 'j' and v.field_content ilike '%OCA electronic journal%'
where b.bcode3 NOT IN ('d', 'n', 'c')
EOT
c.make_query(data_grab_pre + ejournal_oca + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check(title_format: 'apn', oca_ej: true)
r.misc_checks
r.warn_no_archive_url
r.forbid_any_location(['eb'])
r.warn_773_not_blank
r.write('ejournal_oca.txt',
        full - ['corp_auth', 'edition', 'extent', 'other_title', 'm919'])

# E-Journals > Internet Journals
#
# NOTE: done manually via Endeca

# Online Databases
# database_online
#
database_online = <<-EOT
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
EOT
c.make_query(data_grab_pre + database_online + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.warn_773_not_blank(allowed_array: [
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
])
r.write('database_online.txt',
        full - ['corp_auth', 'edition', 'extent', 'other_title', 'm919'])



# Online Data Sets
# dataset_online
#
dataset_online = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
left outer join sierra_view.varfield vi on vi.record_id = bl.item_record_id
  and vi.varfield_type_code = 'j' and vi.field_content ilike '%Online Dataset%'
inner join sierra_view.item_record i on i.id = bl.item_record_id
where b.bcode3 NOT IN ('d', 'n', 'c')
    and ( i.location_code in ('errd', 'errs', 'errw') or vi.record_id = bl.item_record_id)
EOT
c.make_query(data_grab_pre + dataset_online + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.flag_esri
r.forbid_any_location(['eb'])
r.warn_773_not_blank(allowed_array: [
  '|7c2es|aEnvironmental Systems Research Institute (Redlands, Calif.).|tESRI data & maps|w(OCoLC)52103844'
])
r.write('dataset_online.txt',
        (full -
        ['main_entry', 'corp_auth', 'resp_stmt', 'extent', 'other_title']
        ).insert(full.find_index('edition'), 'expansive_edition') - ['edition'])

# Gov Docs > DWS
# govdoc_dws
#
# this doesn't use the pre- and post- data grab query form; too many results
# and practically none of the grabbed fields get used
#
govdoc_dws = <<-EOT
select distinct 'b' || rm.record_num || 'a' as bnum,
      (
        SELECT STRING_AGG(content, ';;;')
        FROM sierra_view.subfield sf
        WHERE sf.record_id = b.id
        AND sf.marc_tag = '856'
        AND sf.tag = 'u'
        GROUP BY sf.record_id
      ) AS url
from sierra_view.bib_record b
inner join sierra_view.record_metadata rm on rm.id = b.id
inner join sierra_view.varfield v on v.record_id = b.id
   and v.marc_tag = '919' and v.field_content ilike '%dwsgpo%'
where b.bcode3 NOT IN ('d', 'n', 'c')
EOT
c.make_query(govdoc_dws)
r = StatsResults.new(c.results.to_a)
r.warn_856u_blank
r.write('govdoc_dws.txt',
        ['bnum', 'url', 'remove'])



#  !! historically used to verify subset counts; no longer needed per kms 16/17
#
# Gov Docs > Non-DWS E-Gov Docs
# govdoc_nondws
#
#govdoc_nondws = <<-EOT
#select distinct b.id
#from sierra_view.bib_record b
#inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
#inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
#   and vi.varfield_type_code = 'j' and vi.field_content ilike '%Online Gov Doc%'
#where b.bcode3 NOT IN ('d', 'n', 'c')
#   and not exists (select *
#              from sierra_view.varfield vb
#              where vb.record_id = b.id
#              and vb.marc_tag = '919'
#              and vb.field_content ilike '%dwsgpo%')
#EOT
#c.make_query(data_grab_pre + govdoc_nondws + data_grab_post)
#r = StatsResults.new(c.results.to_a)
#r.write('govdoc_nondws.txt',
#       ['bnum'])


# Gov Docs > Non-DWS E-Gov Docs, journals
# govdoc_nondws_journal
#
govdoc_nondws_journal = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ~* 'Online Gov Doc.*Journal'
where b.bcode3 NOT IN ('d', 'n', 'c')
   and not exists (select *
              from sierra_view.varfield vb
              where vb.record_id = b.id
              and vb.marc_tag = '919'
              and vb.field_content ilike '%dwsgpo%')
EOT
c.make_query(data_grab_pre + govdoc_nondws_journal + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.require_all_location(['er'])
r.forbid_any_location(['eb'])
r.warn_773_not_blank
r.allow_only_mat_type(['s', 'a'])
r.write('govdoc_nondws_journal.txt',
        full - ['main_entry', 'edition', 'extent', 'm919'])

# Gov Docs > Non-DWS E-Gov Docs, monographs
# govdoc_nondws_monograph
#
govdoc_nondws_monograph = <<-EOT
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
EOT
c.make_query(data_grab_pre + govdoc_nondws_monograph + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.warn_773_not_blank(allowed_array: [
  'North Carolina general statutes. 2009 ed.',
  'State of North Carolina administrative code',
  'Wilde-Ramsing, Mark. Steady as she goes ... (OCoLC)318361864'
])
r.allow_only_mat_type(['z', 'a'])
r.write('govdoc_nondws_monograph.txt',
        full - ['main_entry', 'corp_auth', 'other_title', 'm919'])


# Gov Docs > Non-DWS E-Gov Docs, podcasts
# govdoc_nondws_podcast
#
govdoc_nondws_podcast = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ~* 'Online Gov Doc.*Podcast'
where b.bcode3 NOT IN ('d', 'n', 'c')
   and not exists (select *
              from sierra_view.varfield vb
              where vb.record_id = b.id
              and vb.marc_tag = '919'
              and vb.field_content ilike '%dwsgpo%')
EOT
c.make_query(data_grab_pre + govdoc_nondws_podcast + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.warn_773_not_blank
r.write('govdoc_nondws_podcast.txt',
        full - ['main_entry', 'corp_auth', 'extent', 'other_title', 'm919'])

# Gov Docs > Non-DWS E-Gov Docs, maps
# govdoc_nondws_map
#
govdoc_nondws_map = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ~* 'Online Gov Doc.*Map'
where b.bcode3 NOT IN ('d', 'n', 'c')
   and not exists (select *
              from sierra_view.varfield vb
              where vb.record_id = b.id
              and vb.marc_tag = '919'
              and vb.field_content ilike '%dwsgpo%')
EOT
c.make_query(data_grab_pre + govdoc_nondws_map + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.warn_773_not_blank
r.allow_only_mat_type(['w', 'e'])
r.write('govdoc_nondws_map.txt',
        standard - ['m919'])

# Gov Docs > Non-DWS E-Gov Docs, other
# govdoc_nondws_other
#
govdoc_nondws_other = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ~* '^ *Online Gov Doc *$'
where b.bcode3 NOT IN ('d', 'n', 'c')
   and not exists (select *
              from sierra_view.varfield vb
              where vb.record_id = b.id
              and vb.marc_tag = '919'
              and vb.field_content ilike '%dwsgpo%')
EOT
c.make_query(data_grab_pre + govdoc_nondws_other + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.warn_773_not_blank
r.write('govdoc_nondws_other.txt',
        full - ['main_entry', 'corp_auth', 'other_title', 'm919'])

# E-Audiobook (NOT in collections)
# e_audiobook
#
e_audiobook = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ilike '%E-audiobook%'
where b.bcode3 NOT IN ('d', 'n', 'c')
EOT
c.make_query(data_grab_pre + e_audiobook + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check(title_format: 'apn')
r.misc_checks
r.warn_773_not_blank
r.write('e_audiobook.txt',
        standard)

# Streaming media > Streaming audio in collections
#
# caught via collections

# Streaming media > Streaming video in collections
#
# caught via collections

# Streaming media > Streaming audio NOT in collections
# streaming_audio_noncoll
#
streaming_audio_noncoll = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ilike '%Streaming Audio%'
where b.bcode3 NOT IN ('d', 'n', 'c')
EOT
c.make_query(data_grab_pre + streaming_audio_noncoll + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check(title_format: 'apn')
r.misc_checks
r.warn_773_not_blank
r.write('streaming_audio_noncoll.txt',
        standard)

# Streaming media > Streaming video NOT in collections
# streaming_video_noncoll
#
streaming_video_noncoll = <<-EOT
select distinct b.id
from sierra_view.bib_record b
inner join sierra_view.bib_record_item_record_link bl on bl.bib_record_id = b.id
inner join sierra_view.varfield vi on vi.record_id = bl.item_record_id
   and vi.varfield_type_code = 'j' and vi.field_content ilike '%Streaming Video%'
where b.bcode3 NOT IN ('d', 'n', 'c')
EOT
c.make_query(data_grab_pre + streaming_video_noncoll + data_grab_post)
r = StatsResults.new(c.results.to_a)
r.dupe_check
r.misc_checks
r.warn_773_not_blank
r.require_all_location(['er', 'es'])
r.warn_no_filmfinder
r.write('streaming_video_noncoll.txt',
        standard)

# DATA FOR SPECIFIC COLLECTIONS
#
#
coll_data = <<-EOT
SELECT
  v.field_content,
  COUNT(v.record_id)     
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
GROUP BY v.field_content
ORDER BY v.field_content ASC;
EOT
c.make_query(coll_data)
c.write_results('coll_sql_results.txt',
               headers: ['collection', 'count'])


File.open('summary_counts.txt', 'w') do |ofile|
  Dir['*.txt'].each do |filename|
    unless filename == 'summary_counts.txt'
      ofile << "#{filename}\t#{File.foreach(filename).count - 1 }\n"
    end
  end
end

