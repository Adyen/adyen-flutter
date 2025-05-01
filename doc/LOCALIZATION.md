## Localization

Changing text in the SDK is possible by overriding string resources on the native Android and
iOS layers.

### Android

To override a string resource for Android, you have to specify the string in your own strings.xml
file located in android/app/src/main/res/values/strings.xml. If the file is not present, create an
empty strings.xml file or copy it from
the [example app](https://github.com/Adyen/adyen-flutter/tree/main/example/android/app/src/main/res/values).
In case your app supports multiple languages, please make sure to use the value directories (for
example values-nl-rNL).

You will find the general string resources of the
SDK [here](https://github.com/Adyen/adyen-android/blob/main/ui-core/src/main/res/template/values/strings.xml.tt).
For overriding payment method specific strings,
please [search](https://github.com/search?q=repo%3AAdyen%2Fadyen-android+strings.xml+language%3AXML&type=code&l=XML)
for the associated strings.xml file.

Copy and replace the string you want to override into your own strings.xml file. For adjusting the
names of the payment methods in Drop-In, please use
the [DropInConfiguration](https://github.com/Adyen/adyen-flutter/blob/20895342c83d9888186fedc45d290c9390d58dc3/example/lib/screens/drop_in/drop_in_screen.dart#L142).

You can find more detailed information in the native Android
localization [documentation](https://github.com/Adyen/adyen-android/blob/main/docs/UI_CUSTOMIZATION.md#overriding-string-resources).

### iOS

Overriding strings requires omitting the `shopperLocale` from the configuration on iOS. If a
`shopperLocale` is provided, the SDK uses the default string for that language.

In Xcode, create
a [new](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog#Add-a-string-catalog-to-your-project)
string catalog or use your existing one. Find the key for the string you want to override in
the [list of available strings](https://github.com/Adyen/adyen-ios/blob/develop/Adyen/Assets/Generated/LocalizationKey.swift).

Copy and replace the string you want to override into the string catalog. For adjusting the
names of the payment methods in Drop-In, please use
the [DropInConfiguration](https://github.com/Adyen/adyen-flutter/blob/20895342c83d9888186fedc45d290c9390d58dc3/example/lib/screens/drop_in/drop_in_screen.dart#L142).

You can find more detailed information in the native iOS
localization [documentation](https://adyen.github.io/adyen-ios/5.17.0/documentation/adyen/localization).

### List of currently available locales:

| Language               | Locale code | Fallback |
|------------------------|-------------|:--------:|
| Arabic - International | ar          |          |
| Bulgarian              | bg-BG       |          |
| Catalan                | ca-ES       |          |
| Chinese - Simplified   | zh-CN       |          |
| Chinese - Traditional  | zh-TW       |          |
| Croatian               | hr-HR       |          |
| Czech                  | cs-CZ       |          |
| Danish                 | da-DK       |          |
| Dutch                  | nl-NL       |          |
| English - US           | en-US       |    ✱     |
| Estonian               | et-EE       |          |
| Finnish                | fi-FI       |          |
| French                 | fr-FR       |          |
| German                 | de-DE       |          |
| Greek                  | el-GR       |          |
| Hungarian              | hu-HU       |          |
| Icelandic              | is-IS       |          |
| Italian                | it-IT       |          |
| Japanese               | ja-JP       |          |
| Korean                 | ko-KR       |          |
| Latvian                | lv-LV       |          |
| Lithuanian             | lt-LT       |          |
| Norwegian              | no-NO       |          |
| Polish                 | pl-PL       |          |
| Portuguese - Brazil    | pt-BR       |          |
| Portuguese - Portugal  | pt-PT       |          |
| Romanian               | ro-RO       |          |
| Russian                | ru-RU       |          |
| Slovak                 | sk-SK       |          |
| Slovenian              | sl-SI       |          |
| Spanish                | es-ES       |          |
| Swedish                | sv-SE       |          |