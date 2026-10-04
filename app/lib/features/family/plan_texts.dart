import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// "Zosia", or "Dziecko 2" when the parent left the name empty.
String childLabel(AppLocalizations l10n, ChildProfile child, int index) =>
    child.name.isEmpty ? l10n.childNumber(index + 1) : child.name;

Color childColor(int index) => const [AkBrand.sun, AkBrand.teal, AkBrand.lavender, AkBrand.orange][index % 4];

String levelName(AppLocalizations l10n, int level) => switch (level) {
  1 => l10n.level1Name,
  2 => l10n.level2Name,
  3 => l10n.level3Name,
  _ => l10n.level4Name,
};

String levelNews(AppLocalizations l10n, int level) => switch (level) {
  1 => l10n.level1News,
  2 => l10n.level2News,
  3 => l10n.level3News,
  _ => l10n.level4News,
};

String tipText(AppLocalizations l10n, PlanTip tip) => switch (tip) {
  PlanTip.phoneDown => l10n.tipPhoneDown,
  PlanTip.kidsMode => l10n.tipKidsMode,
  PlanTip.download => l10n.tipDownload,
  PlanTip.favorites => l10n.tipFavorites,
  PlanTip.microphone => l10n.tipMicrophone,
  PlanTip.sleepTimer => l10n.tipSleepTimer,
  PlanTip.printables => l10n.tipPrintables,
  PlanTip.account => l10n.tipAccount,
};

/// Catalog skills are Polish words already; capitalised for display.
String skillLabel(String skill) => skill.isEmpty ? skill : skill[0].toUpperCase() + skill.substring(1);

String goalName(AppLocalizations l10n, DevGoal goal) => switch (goal) {
  DevGoal.imagination => l10n.goalImagination,
  DevGoal.language => l10n.goalLanguage,
  DevGoal.logic => l10n.goalLogic,
  DevGoal.listening => l10n.goalListening,
  DevGoal.movement => l10n.goalMovement,
  DevGoal.calm => l10n.goalCalm,
};
