import 'package:get/get.dart';

import 'translations_es_pt.dart';
import 'translations_fr_de.dart';
import 'translations_id_hi.dart';
import 'translations_ko_ja.dart';
import 'translations_vi_en.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
    'vi': viTranslations,
    'en': enTranslations,
    'es': esTranslations,
    'pt': ptTranslations,
    'fr': frTranslations,
    'de': deTranslations,
    'id': idTranslations,
    'hi': hiTranslations,
    'ko': koTranslations,
    'ja': jaTranslations,
  };
}

const supportedAppLocales = <String>[
  'vi',
  'en',
  'es',
  'pt',
  'fr',
  'de',
  'id',
  'hi',
  'ko',
  'ja',
];
