namespace localconv

--****
-- ==  Locale Names
--
-- <<LEVELTOC level=2 depth=4>>



--****
-- === Constants
-- //Windows// locale names~:
--
-- | af-ZA|  sq-AL|  gsw-FR|  am-ET|  ar-DZ|  ar-BH|  ar-EG|  ar-IQ| 
-- | ar-JO|  ar-KW|  ar-LB|  ar-LY|  ar-MA|  ar-OM|  ar-QA|  ar-SA| 
-- | ar-SY|  ar-TN|  ar-AE|  ar-YE|  hy-AM|  as-IN|  az-Cyrl-AZ|  az-Latn-AZ| 
-- | ba-RU|  eu-ES|  be-BY|  bn-IN|  bs-Cyrl-BA|  bs-Latn-BA|  br-FR|  bg-BG| 
-- | ca-ES|  zh-HK|  zh-MO|  zh-CN|  zh-SG|  zh-TW|  co-FR|  hr-BA| 
-- | hr-HR|  cs-CZ|  da-DK|  prs-AF|  dv-MV|  nl-BE|  nl-NL|  en-AU| 
-- | en-BZ|  en-CA|  en-029|  en-IN|  en-IE|  en-JM|  en-MY|  en-NZ| 
-- | en-PH|  en-SG|  en-ZA|  en-TT|  en-GB|  en-US|  en-ZW|  et-EE| 
-- | fo-FO|  fil-PH|  fi-FI|  fr-BE|  fr-CA|  fr-FR|  fr-LU|  fr-MC| 
-- | fr-CH|  fy-NL|  gl-ES|  ka-GE|  de-AT|  de-DE|  de-LI|  de-LU| 
-- | de-CH|  el-GR|  kl-GL|  gu-IN|  ha-Latn-NG|  he-IL| hi-IN|  hu-HU| 
-- | is-IS|  ig-NG|  id-ID|  iu-Latn-CA| iu-Cans-CA| ga-IE|  it-IT|  it-CH| 
-- | ja-JP|  kn-IN|  kk-KZ|  kh-KH|  qut-GT| rw-RW|  kok-IN|  ko-KR|  
-- | ky-KG|  lo-LA|  lv-LV|  lt-LT|  dsb-DE| lb-LU|  mk-MK|  ms-BN| 
-- | ms-MY|  ml-IN|  mt-MT|  mi-NZ|  arn-CL| mr-IN|  moh-CA|  mn-Cyrl-MN| 
-- | mn-Mong-CN| ne-IN| ne-NP|  nb-NO|  nn-NO|  oc-FR|  or-IN|  ps-AF| 
-- | fa-IR|  pl-PL|  pt-BR|  pt-PT|  pa-IN|  quz-BO|  quz-EC|  quz-PE| 
-- | ro-RO|  rm-CH|  ru-RU|  smn-FI|  smj-NO|  smj-SE|  se-FI|  se-NO| 
-- | se-SE|  sms-FI|  sma-NO|  sma-SE|  sa-IN|  sr-Cyrl-BA|  sr-Latn-BA|  sr-Cyrl-CS| 
-- | sr-Latn-CS| ns-ZA| tn-ZA|  si-LK|  sk-SK|  sl-SI|  es-AR|  es-BO| 
-- | es-CL|  es-CO| es-CR|  es-DO|  es-EC|  es-SV|  es-GT|  es-HN| 
-- | es-MX|  es-NI|  es-PA|  es-PY|  es-PE|  es-PR|  es-ES|  es-ES_tradnl| 
-- | es-US|  es-UY|  es-VE|  sw-KE|  sv-FI|  sv-SE|  syr-SY|  tg-Cyrl-TJ|  
-- | tmz-Latn-DZ| ta-IN| tt-RU|  te-IN|  th-TH|  bo-BT|  bo-CN|  tr-TR| 
-- | tk-TM|  ug-CN|  uk-UA|  wen-DE|  tr-IN|  ur-PK|  uz-Cyrl-UZ|  uz-Latn-UZ| 
-- | vi-VN|  cy-GB|  wo-SN|  xh-ZA|  sah-RU|  ii-CN|  yo-NG|  zu-ZA| 

public constant w32_names = {
	"af-ZA",
	"sq-AL",
	"gsw-FR",
	"am-ET",
	"ar-DZ",
	"ar-BH",
	"ar-EG",
	"ar-IQ",
	"ar-JO",
	"ar-KW",
	"ar-LB",
	"ar-LY",
	"ar-MA",
	"ar-OM",
	"ar-QA",
	"ar-SA",
	"ar-SY",
	"ar-TN",
	"ar-AE",
	"ar-YE",
	"hy-AM",
	"as-IN",
	"az-Cyrl-AZ",
	"az-Latn-AZ",
	"ba-RU",
	"eu-ES",
	"be-BY",
	"bn-IN",
	"bs-Cyrl-BA",
	"bs-Latn-BA",
	"br-FR",
	"bg-BG",
	"ca-ES",
	"zh-HK",
	"zh-MO",
	"zh-CN",
	"zh-SG",
	"zh-TW",
	"co-FR",
	"hr-BA",
	"hr-HR",
	"cs-CZ",
	"da-DK",
	"prs-AF",
	"dv-MV",
	"nl-BE",
	"nl-NL",
	"en-AU",
	"en-BZ",
	"en-CA",
	"en-029",
	"en-IN",
	"en-IE",
	"en-JM",
	"en-MY",
	"en-NZ",
	"en-PH",
	"en-SG",
	"en-ZA",
	"en-TT",
	"en-GB",
	"en-US",
	"en-ZW",
	"et-EE",
	"fo-FO",
	"fil-PH",
	"fi-FI",
	"fr-BE",
	"fr-CA",
	"fr-FR",
	"fr-LU",
	"fr-MC",
	"fr-CH",
	"fy-NL",
	"gl-ES",
	"ka-GE",
	"de-AT",
	"de-DE",
	"de-LI",
	"de-LU",
	"de-CH",
	"el-GR",
	"kl-GL",
	"gu-IN",
	"ha-Latn-NG",
	"he-IL",
	"hi-IN",
	"hu-HU",
	"is-IS",
	"ig-NG",
	"id-ID",
	"iu-Latn-CA",
	"iu-Cans-CA",
	"ga-IE",
	"it-IT",
	"it-CH",
	"ja-JP",
	"kn-IN",
	"kk-KZ",
	"kh-KH",
	"qut-GT",
	"rw-RW",
	"kok-IN",
	"ko-KR",
	"ky-KG",
	"lo-LA",
	"lv-LV",
	"lt-LT",
	"dsb-DE",
	"lb-LU",
	"mk-MK",
	"ms-BN",
	"ms-MY",
	"ml-IN",
	"mt-MT",
	"mi-NZ",
	"arn-CL",
	"mr-IN",
	"moh-CA",
	"mn-Cyrl-MN",
	"mn-Mong-CN",
	"ne-IN",
	"ne-NP",
	"nb-NO",
	"nn-NO",
	"oc-FR",
	"or-IN",
	"ps-AF",
	"fa-IR",
	"pl-PL",
	"pt-BR",
	"pt-PT",
	"pa-IN",
	"quz-BO",
	"quz-EC",
	"quz-PE",
	"ro-RO",
	"rm-CH",
	"ru-RU",
	"smn-FI",
	"smj-NO",
	"smj-SE",
	"se-FI",
	"se-NO",
	"se-SE",
	"sms-FI",
	"sma-NO",
	"sma-SE",
	"sa-IN",
	"sr-Cyrl-BA",
	"sr-Latn-BA",
	"sr-Cyrl-CS",
	"sr-Latn-CS",
	"ns-ZA",
	"tn-ZA",
	"si-LK",
	"sk-SK",
	"sl-SI",
	"es-AR",
	"es-BO",
	"es-CL",
	"es-CO",
	"es-CR",
	"es-DO",
	"es-EC",
	"es-SV",
	"es-GT",
	"es-HN",
	"es-MX",
	"es-NI",
	"es-PA",
	"es-PY",
	"es-PE",
	"es-PR",
	"es-ES",
	"es-ES_tradnl",
	"es-US",
	"es-UY",
	"es-VE",
	"sw-KE",
	"sv-FI",
	"sv-SE",
	"syr-SY",
	"tg-Cyrl-TJ",
	"tmz-Latn-DZ",
	"ta-IN",
	"tt-RU",
	"te-IN",
	"th-TH",
	"bo-BT",
	"bo-CN",
	"tr-TR",
	"tk-TM",
	"ug-CN",
	"uk-UA",
	"wen-DE",
	"tr-IN",
	"ur-PK",
	"uz-Cyrl-UZ",
	"uz-Latn-UZ",
	"vi-VN",
	"cy-GB",
	"wo-SN",
	"xh-ZA",
	"sah-RU",
	"ii-CN",
	"yo-NG",
	"zu-ZA"
	}
	
--**
-- Canonical locale names for //Windows//:
-- 
-- | Afrikaans_South Africa|  Afrikaans_South Africa| Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Afrikaans_South Africa|  Afrikaans_South Africa|  Afrikaans_South Africa| 
-- | Basque_Spain|  Basque_Spain|  Belarusian_Belarus| 
-- | Belarusian_Belarus|  Belarusian_Belarus|  Belarusian_Belarus| 
-- | Belarusian_Belarus|  Belarusian_Belarus|  Catalan_Spain| 
-- | Catalan_Spain|  Catalan_Spain|  Catalan_Spain| 
-- | Catalan_Spain|  Catalan_Spain|  Catalan_Spain| 
-- | Catalan_Spain| Catalan_Spain|  Catalan_Spain| 
-- | Danish_Denmark| Danish_Denmark|  Danish_Denmark|   
-- | Danish_Denmark|  Danish_Denmark|  English_Australia| 
-- | English_United States|  English_United States|  English_United States| 
-- | English_United States|  English_United States|  English_United States| 
-- | English_United States|  English_United States|  English_United States| 
-- | English_United States|  English_United States|  English_United States| 
-- | English_United States|  English_United States|  English_United States| 
-- | English_United States|  English_United States|  English_United States| 
-- | Finnish_Finland|  French_France|  French_France| 
-- | French_France|  French_France|  French_France| 
-- | French_France|  French_France|  French_France| 
-- | French_France|  French_France|  French_France| 
-- | French_France|  French_France|  French_France| 
-- | French_France|  French_France|  French_France| 
-- | French_France|  French_France|  French_France| 
-- | Hungarian_Hungary|  Hungarian_Hungary|  Hungarian_Hungary| 
-- | Hungarian_Hungary|  Hungarian_Hungary|  Hungarian_Hungary| 
-- | Hungarian_Hungary|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy|  
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy|  
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy|  
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy|  
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Italian_Italy|  Italian_Italy| 
-- | Italian_Italy|  Romanian_Romania|  Romanian_Romania| 
-- | Russian_Russia|  Russian_Russia|  Russian_Russia| 
-- | Russian_Russia|  Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| 
-- | Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| 
-- | Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| 
-- | Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| 
-- | Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| Serbian (Cyrillic)_Serbia| 
-- | Serbian (Cyrillic)_Serbia| Slovak_Slovakia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Estonian_Estonia| 
-- | Estonian_Estonia|  Estonian_Estonia|  Swedish_Sweden| 
-- | Swedish_Sweden|  Swedish_Sweden|  Swedish_Sweden| 
-- | Swedish_Sweden|  Swedish_Sweden|  Swedish_Sweden| 
-- | Swedish_Sweden|  Swedish_Sweden|  Swedish_Sweden| 
-- | Swedish_Sweden|  Swedish_Sweden|  Swedish_Sweden| 
-- | Swedish_Sweden|  Swedish_Sweden|  Ukrainian_Ukraine| 
-- | Ukrainian_Ukraine|  Ukrainian_Ukraine|  Ukrainian_Ukraine| 
-- | Ukrainian_Ukraine|  Ukrainian_Ukraine|  Ukrainian_Ukraine| 
-- | Ukrainian_Ukraine|  Ukrainian_Ukraine|  Ukrainian_Ukraine| 
-- | Ukrainian_Ukraine|  Ukrainian_Ukraine|  Ukrainian_Ukraine| 
-- | Ukrainian_Ukraine|                            |                     |

public constant w32_name_canonical = {
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Afrikaans_South Africa",
	"Basque_Spain",
	"Basque_Spain",
	"Belarusian_Belarus",
	"Belarusian_Belarus",
	"Belarusian_Belarus",
	"Belarusian_Belarus",
	"Belarusian_Belarus",
	"Belarusian_Belarus",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Catalan_Spain",
	"Danish_Denmark",
	"Danish_Denmark",
	"Danish_Denmark",
	"Danish_Denmark",
	"Danish_Denmark",
	"English_Australia",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"English_United States",
	"Estonian_Estonia",
	"English_United States",
	"English_United States",
	"Finnish_Finland",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"French_France",
	"Hungarian_Hungary",
	"Hungarian_Hungary",
	"Hungarian_Hungary",
	"Hungarian_Hungary",
	"Hungarian_Hungary",
	"Hungarian_Hungary",
	"Hungarian_Hungary",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Italian_Italy",
	"Romanian_Romania",
	"Romanian_Romania",
	"Russian_Russia",
	"Russian_Russia",
	"Russian_Russia",
	"Russian_Russia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Serbian (Cyrillic)_Serbia",
	"Slovak_Slovakia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Spanish_Spain",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Estonian_Estonia",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Swedish_Sweden",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine",
	"Ukrainian_Ukraine"
}

--**
-- POSIX locale names~:
--
-- | af_ZA|  sq_AL|  gsw_FR|   am_ET|  ar_DZ      | ar_BH      | ar_EG      | ar_IQ| 
-- | ar_JO|  ar_KW|  ar_LB| ar_LY|  ar_MA|  ar_OM|  ar_QA|  ar_SA| 
-- | ar_SY|  ar_TN|  ar_AE| ar_YE|  hy_AM|  as_IN|  az_Cyrl_AZ|  az_Latn_AZ| 
-- | ba_RU|  eu_ES|  be_BY|  bn_IN|  bs_Cyrl_BA|  bs_Latn_BA|  br_FR|  bg_BG| 
-- | ca_ES|  zh_HK|  zh_MO|  zh_CN|  zh_SG|  zh_TW|  co_FR|  hr_BA| 
-- | hr_HR|  cs_CZ|  da_DK|  prs_AF|  dv_MV|  nl_BE|  nl_NL|  en_AU| 
-- | en_BZ|  en_CA|  en_029|  en_IN|  en_IE|  en_JM|  en_MY|  en_NZ| 
-- | en_PH|  en_SG|  en_ZA|  en_TT|  en_GB|  en_US|  en_ZW|  et_EE| 
-- | fo_FO|  fil_PH|  fi_FI|  fr_BE|  fr_CA|  fr_FR|  fr_LU|  fr_MC| 
-- | fr_CH|  fy_NL|  gl_ES|  ka_GE|  de_AT|  de_DE|  de_LI|  de_LU| 
-- | de_CH|  el_GR|  kl_GL|  gu_IN|  ha_Latn_NG|  he_IL|  hi_IN|  hu_HU| 
-- | is_IS|  ig_NG|  id_ID|  iu_Latn_CA| iu_Cans_CA|  ga_IE|  it_IT|  it_CH| 
-- | ja_JP|  kn_IN|  kk_KZ|  kh_KH|  qut_GT|  rw_RW|  kok_IN|  ko_KR| 
-- | ky_KG|  lo_LA|  lv_LV|  lt_LT|  dsb_DE|  lb_LU|  mk_MK|  ms_BN| 
-- | ms_MY|  ml_IN|  mt_MT|  mi_NZ|  arn_CL|  mr_IN|  moh_CA|  mn_Cyrl_MN| 
-- | mn_Mong_CN| ne_IN| ne_NP|  nb_NO|  nn_NO|  oc_FR|  or_IN|  ps_AF| 
-- | fa_IR|  pl_PL|  pt_BR|  pt_PT|  pa_IN|  quz_BO|  quz_EC|  quz_PE| 
-- | ro_RO|  rm_CH|  ru_RU|  smn_FI|  smj_NO|  smj_SE|  se_FI|  se_NO| 
-- | se_SE|  sms_FI|  sma_NO|  sma_SE|  sa_IN|  sr_Cyrl_BA|  sr_Latn_BA|  sr_Cyrl_CS| 
-- | sr_Latn_CS| ns_ZA| tn_ZA|  si_LK|  sk_SK|  sl_SI|  es_AR|  es_BO| 
-- | es_CL|  es_CO|  es_CR|  es_DO|  es_EC|  es_SV|  es_GT|  es_HN| 
-- | es_MX|  es_NI|  es_PA|  es_PY|  es_PE|  es_PR|  es_ES|  es_ES_tradnl| 
-- | es_US|  es_UY|  es_VE|  sw_KE|  sv_FI|  sv_SE|  syr_SY|  tg_Cyrl_TJ| 
-- | tmz_Latn_DZ| ta_IN| tt_RU|  te_IN|  th_TH|  bo_BT|  bo_CN|  tr_TR| 
-- | tk_TM|  ug_CN|  uk_UA|  wen_DE|  tr_IN|  ur_PK|  uz_Cyrl_UZ|  uz_Latn_UZ| 
-- | vi_VN|  cy_GB|  wo_SN|  xh_ZA|  sah_RU|  ii_CN|  yo_NG      | zu_ZA| 

public constant posix_names = {
	"af_ZA",
	"sq_AL",
	"gsw_FR",
	"am_ET",
	"ar_DZ",
	"ar_BH",
	"ar_EG",
	"ar_IQ",
	"ar_JO",
	"ar_KW",
	"ar_LB",
	"ar_LY",
	"ar_MA",
	"ar_OM",
	"ar_QA",
	"ar_SA",
	"ar_SY",
	"ar_TN",
	"ar_AE",
	"ar_YE",
	"hy_AM",
	"as_IN",
	"az_Cyrl_AZ",
	"az_Latn_AZ",
	"ba_RU",
	"eu_ES",
	"be_BY",
	"bn_IN",
	"bs_Cyrl_BA",
	"bs_Latn_BA",
	"br_FR",
	"bg_BG",
	"ca_ES",
	"zh_HK",
	"zh_MO",
	"zh_CN",
	"zh_SG",
	"zh_TW",
	"co_FR",
	"hr_BA",
	"hr_HR",
	"cs_CZ",
	"da_DK",
	"prs_AF",
	"dv_MV",
	"nl_BE",
	"nl_NL",
	"en_AU",
	"en_BZ",
	"en_CA",
	"en_029",
	"en_IN",
	"en_IE",
	"en_JM",
	"en_MY",
	"en_NZ",
	"en_PH",
	"en_SG",
	"en_ZA",
	"en_TT",
	"en_GB",
	"en_US",
	"en_ZW",
	"et_EE",
	"fo_FO",
	"fil_PH",
	"fi_FI",
	"fr_BE",
	"fr_CA",
	"fr_FR",
	"fr_LU",
	"fr_MC",
	"fr_CH",
	"fy_NL",
	"gl_ES",
	"ka_GE",
	"de_AT",
	"de_DE",
	"de_LI",
	"de_LU",
	"de_CH",
	"el_GR",
	"kl_GL",
	"gu_IN",
	"ha_Latn_NG",
	"he_IL",
	"hi_IN",
	"hu_HU",
	"is_IS",
	"ig_NG",
	"id_ID",
	"iu_Latn_CA",
	"iu_Cans_CA",
	"ga_IE",
	"it_IT",
	"it_CH",
	"ja_JP",
	"kn_IN",
	"kk_KZ",
	"kh_KH",
	"qut_GT",
	"rw_RW",
	"kok_IN",
	"ko_KR",
	"ky_KG",
	"lo_LA",
	"lv_LV",
	"lt_LT",
	"dsb_DE",
	"lb_LU",
	"mk_MK",
	"ms_BN",
	"ms_MY",
	"ml_IN",
	"mt_MT",
	"mi_NZ",
	"arn_CL",
	"mr_IN",
	"moh_CA",
	"mn_Cyrl_MN",
	"mn_Mong_CN",
	"ne_IN",
	"ne_NP",
	"nb_NO",
	"nn_NO",
	"oc_FR",
	"or_IN",
	"ps_AF",
	"fa_IR",
	"pl_PL",
	"pt_BR",
	"pt_PT",
	"pa_IN",
	"quz_BO",
	"quz_EC",
	"quz_PE",
	"ro_RO",
	"rm_CH",
	"ru_RU",
	"smn_FI",
	"smj_NO",
	"smj_SE",
	"se_FI",
	"se_NO",
	"se_SE",
	"sms_FI",
	"sma_NO",
	"sma_SE",
	"sa_IN",
	"sr_Cyrl_BA",
	"sr_Latn_BA",
	"sr_Cyrl_CS",
	"sr_Latn_CS",
	"ns_ZA",
	"tn_ZA",
	"si_LK",
	"sk_SK",
	"sl_SI",
	"es_AR",
	"es_BO",
	"es_CL",
	"es_CO",
	"es_CR",
	"es_DO",
	"es_EC",
	"es_SV",
	"es_GT",
	"es_HN",
	"es_MX",
	"es_NI",
	"es_PA",
	"es_PY",
	"es_PE",
	"es_PR",
	"es_ES",
	"es_ES_tradnl",
	"es_US",
	"es_UY",
	"es_VE",
	"sw_KE",
	"sv_FI",
	"sv_SE",
	"syr_SY",
	"tg_Cyrl_TJ",
	"tmz_Latn_DZ",
	"ta_IN",
	"tt_RU",
	"te_IN",
	"th_TH",
	"bo_BT",
	"bo_CN",
	"tr_TR",
	"tk_TM",
	"ug_CN",
	"uk_UA",
	"wen_DE",
	"tr_IN",
	"ur_PK",
	"uz_Cyrl_UZ",
	"uz_Latn_UZ",
	"vi_VN",
	"cy_GB",
	"wo_SN",
	"xh_ZA",
	"sah_RU",
	"ii_CN",
	"yo_NG",
	"zu_ZA"
}

public constant locale_canonical = posix_names

ifdef UNIX then
	public constant platform_locale = posix_names
elsedef
	public constant platform_locale = w32_name_canonical
end ifdef

--****
-- === Locale Name Translation
--

--**
-- Get canonical name for a locale.
--
-- Parameters:
--			# ##new_locale## : a sequence, the string for the locale.
-- Returns:
--		A **sequence**, either the translated locale on success or ##new_locale## on failure.
--
-- See Also:
-- 		[[:get]], [[:set]], [[:decanonical]]

public function canonical(sequence new_locale)
	integer w, ws, p, n
	ifdef WINDOWS then
		n = find('.', new_locale) 
		if n then
			new_locale = remove(new_locale, n, length(new_locale))
		end if
	end ifdef
	p = find(new_locale, posix_names)
	w = find(new_locale, w32_names)
	ws = find(new_locale, w32_name_canonical)
	if p != 0 then
		n = p
	elsif w != 0 then
		n = w
	elsif ws != 0 then
		n = ws
	else
		--unknown, can not be canonical
		return new_locale
	end if
	new_locale = locale_canonical[n]
	ifdef WINDOWS then
		n = find('.', new_locale) 
		if n then
			new_locale = remove(new_locale, n, length(new_locale))
		end if
	end ifdef
	return new_locale
end function

--**
-- gets the translation of a locale string for current platform.
--
-- Parameters:
--		# ##new_locale##: a sequence, the string for the locale.
--
-- Returns:
--		A **sequence**, either the translated locale on success or ##new_locale## on failure.
--
-- See Also:
-- 		[[:get]], [[:set]], [[:canonical]]

public function decanonical(sequence new_locale)
	integer w, ws, p, n
	ifdef WINDOWS then
		n = find('.', new_locale) 
		if n then
			new_locale = remove(new_locale, n, length(new_locale))
		end if
	end ifdef
	p = find(new_locale, posix_names)
	w = find(new_locale, w32_names)
	ws = find(new_locale, w32_name_canonical)
	if p != 0 then
		n = p
	elsif w != 0 then
		n = w
	elsif ws != 0 then
		n = ws
	else
		--unknown, can not be canonical
		return new_locale
	end if
	new_locale = platform_locale[n]
	ifdef WINDOWS then
		n = find('.', new_locale) 
		if n then
			new_locale = remove(new_locale, n, length(new_locale))
		end if
	end ifdef
	return new_locale
end function

--**
-- gets the translation of a canoncial locale string for the //Windows// platform.
--
-- Parameters:
--		# ##new_locale##: a sequence, the string for the locale.
--
-- Returns:
--		A **sequence**, either the Windows native locale name on success or "C" on failure.
--
-- See Also:
-- 		[[:get]], [[:set]], [[:canonical]], [[:decanonical]]

public function canon2win(sequence new_locale)
	integer w, n

	ifdef WINDOWS then
		n = find('.', new_locale) 
		if n then
			new_locale = remove(new_locale, n, length(new_locale))
		end if
	end ifdef

	w = find(new_locale, posix_names)
	if w = 0 then
		-- unknown
		return "C"
	end if

	new_locale = w32_names[w]

	ifdef WINDOWS then
		n = find('.', new_locale) 
		if n then
			new_locale = remove(new_locale, n, length(new_locale))
		end if
	end ifdef

	return new_locale
end function
