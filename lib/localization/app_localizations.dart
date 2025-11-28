import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Provides internationalization (i18n) support for the application.
///
/// This class handles loading and accessing translated strings from JSON files
/// based on the current locale. It supports parameter substitution in translated strings.
class AppLocalizations {
  /// The current locale for which translations are loaded.
  final Locale locale;

  /// Creates an [AppLocalizations] instance for the specified locale.
  AppLocalizations(this.locale);

  /// Retrieves the [AppLocalizations] instance for the current build context.
  ///
  /// Parameters:
  /// - [context]: The build context used to access the localization
  ///
  /// Returns:
  /// The [AppLocalizations] instance for the current locale, or null if not available
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// The delegate responsible for loading and managing [AppLocalizations] instances.
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  /// Cache of loaded translated strings mapped by their keys.
  Map<String, String>? _localizedStrings;

  /// Loads the translation strings from the JSON file for the current locale.
  ///
  /// The method reads the appropriate JSON file from the assets/translations/
  /// directory based on the locale's language code and caches the translations.
  ///
  /// Returns:
  /// A [Future] that completes with true when the translations are successfully loaded
  Future<bool> load() async {
    String jsonString =
    await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  /// Translates a string key to the current locale's language.
  ///
  /// If the key is not found, returns the key itself as a fallback.
  /// Supports parameter substitution by replacing placeholders like {paramName}
  /// with actual values from the parameters map.
  ///
  /// Parameters:
  /// - [key]: The translation key to look up
  /// - [params]: Optional map of parameters to substitute in the translated string
  ///
  /// Returns:
  /// The translated string with parameters substituted, or the key if not found
  String translate(String key, [Map<String, String>? params]) {
    String? value = _localizedStrings?[key];

    if (value == null) {
      return key; // Fallback to key if translation not found
    }

    if (params != null) {
      // Creates a new variable to avoid null problems
      String result = value;
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
      return result;
    }

    return value;
  }
}

/// The delegate class responsible for creating and loading [AppLocalizations] instances.
///
/// This class implements [LocalizationsDelegate] to manage the lifecycle of
/// [AppLocalizations] objects and determine which locales are supported.
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  /// Creates a new [_AppLocalizationsDelegate] instance.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}