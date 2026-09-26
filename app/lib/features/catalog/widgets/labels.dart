import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

extension CatalogLabels on AppLocalizations {
  String situation(Situation s) => switch (s) {
    Situation.podroz => situationPodroz,
    Situation.przedSnem => situationPrzedSnem,
    Situation.wDomu => situationWDomu,
    Situation.czekanie => situationCzekanie,
  };

  String requirement(Requirement r) => switch (r) {
    Requirement.mikrofon => requirementMikrofon,
    Requirement.miejsceDoRuchu => requirementMiejsceDoRuchu,
    Requirement.kartkaIOlowek => requirementKartkaIOlowek,
    Requirement.wydrukPdf => requirementWydrukPdf,
  };

  String kind(ContentKind k) => switch (k) {
    ContentKind.audioGame => kindAudioGame,
    ContentKind.song => kindSong,
    ContentKind.interactiveGame => kindInteractiveGame,
  };

  String duration(int seconds) => minutes((seconds / 60).round().clamp(1, 999));

  String? playerCount(ContentItem item) {
    final min = item.playersMin;
    if (min == null) return null;
    final max = item.playersMax;
    return max == null || max == min ? players(min) : playersRange(min, max);
  }
}

IconData situationIcon(Situation s) => switch (s) {
  Situation.podroz => Icons.directions_car_rounded,
  Situation.przedSnem => Icons.bedtime_rounded,
  Situation.wDomu => Icons.cottage_rounded,
  Situation.czekanie => Icons.hourglass_bottom_rounded,
};
