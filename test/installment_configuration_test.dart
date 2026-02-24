import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultInstallmentOptionsMapper', () {
    test('maps DefaultInstallmentOptions to DTO', () {
      final options = DefaultInstallmentOptions(
        values: [2, 3, 6, 12],
        includesRevolving: true,
      );

      final dto = options.toDTO();

      expect(dto.values, [2, 3, 6, 12]);
      expect(dto.includesRevolving, true);
    });

    test('maps with includesRevolving false', () {
      final options = DefaultInstallmentOptions(
        values: [2, 3],
        includesRevolving: false,
      );

      final dto = options.toDTO();

      expect(dto.includesRevolving, false);
    });

    test('preserves all values in DTO', () {
      final options = DefaultInstallmentOptions(
        values: [2, 3, 6, 9, 12, 18, 24],
      );

      final dto = options.toDTO();

      expect(dto.values, [2, 3, 6, 9, 12, 18, 24]);
    });
  });

  group('CardBasedInstallmentOptionsMapper', () {
    test('maps CardBasedInstallmentOptions to DTO', () {
      final options = CardBasedInstallmentOptions(
        cardBrand: 'visa',
        values: [2, 3, 6, 12],
        includesRevolving: true,
      );

      final dto = options.toDTO();

      expect(dto.cardBrand, 'visa');
      expect(dto.values, [2, 3, 6, 12]);
      expect(dto.includesRevolving, true);
    });

    test('maps different card brands', () {
      final brands = ['visa', 'mc', 'amex'];

      for (final brand in brands) {
        final options = CardBasedInstallmentOptions(
          cardBrand: brand,
          values: [2, 3],
        );

        final dto = options.toDTO();

        expect(dto.cardBrand, brand);
      }
    });

    test('preserves all values in DTO', () {
      final options = CardBasedInstallmentOptions(
        cardBrand: 'mc',
        values: [2, 3, 6],
        includesRevolving: false,
      );

      final dto = options.toDTO();

      expect(dto.values, [2, 3, 6]);
      expect(dto.includesRevolving, false);
    });
  });

  group('InstallmentConfigurationMapper', () {
    test('maps InstallmentConfiguration with all fields to DTO', () {
      final defaultOptions = DefaultInstallmentOptions(
        values: [2, 3, 6],
        includesRevolving: true,
      );

      final cardBasedOptions = [
        CardBasedInstallmentOptions(
          cardBrand: 'visa',
          values: [2, 3, 6, 12],
          includesRevolving: true,
        ),
        CardBasedInstallmentOptions(
          cardBrand: 'mc',
          values: [2, 3, 6],
          includesRevolving: false,
        ),
      ];

      final config = InstallmentConfiguration(
        defaultOptions: defaultOptions,
        cardBasedOptions: cardBasedOptions,
        showInstallmentAmount: true,
      );

      final dto = config.toDTO();

      expect(dto.defaultOptions?.values, [2, 3, 6]);
      expect(dto.defaultOptions?.includesRevolving, true);
      expect(dto.cardBasedOptions?.length, 2);
      expect(dto.cardBasedOptions?[0]?.cardBrand, 'visa');
      expect(dto.cardBasedOptions?[1]?.cardBrand, 'mc');
      expect(dto.showInstallmentAmount, true);
    });

    test('maps with only defaultOptions', () {
      final defaultOptions = DefaultInstallmentOptions(
        values: [2, 3],
      );

      final config = InstallmentConfiguration(
        defaultOptions: defaultOptions,
      );

      final dto = config.toDTO();

      expect(dto.defaultOptions?.values, [2, 3]);
      expect(dto.cardBasedOptions, null);
      expect(dto.showInstallmentAmount, false);
    });

    test('maps with only cardBasedOptions', () {
      final cardBasedOptions = [
        CardBasedInstallmentOptions(
          cardBrand: 'visa',
          values: [2, 3, 6, 12],
        ),
      ];

      final config = InstallmentConfiguration(
        cardBasedOptions: cardBasedOptions,
      );

      final dto = config.toDTO();

      expect(dto.defaultOptions, null);
      expect(dto.cardBasedOptions?.length, 1);
      expect(dto.cardBasedOptions?[0]?.cardBrand, 'visa');
    });

    test('maps with no options', () {
      const config = InstallmentConfiguration();

      final dto = config.toDTO();

      expect(dto.defaultOptions, null);
      expect(dto.cardBasedOptions, null);
      expect(dto.showInstallmentAmount, false);
    });

    test('maps multiple card-based options correctly', () {
      final cardBasedOptions = [
        CardBasedInstallmentOptions(
          cardBrand: 'visa',
          values: [2, 3, 6, 12],
        ),
        CardBasedInstallmentOptions(
          cardBrand: 'mc',
          values: [2, 3, 6],
        ),
        CardBasedInstallmentOptions(
          cardBrand: 'amex',
          values: [3, 6],
        ),
      ];

      final config = InstallmentConfiguration(
        cardBasedOptions: cardBasedOptions,
      );

      final dto = config.toDTO();

      expect(dto.cardBasedOptions?.length, 3);
      expect(dto.cardBasedOptions?[0]?.cardBrand, 'visa');
      expect(dto.cardBasedOptions?[1]?.cardBrand, 'mc');
      expect(dto.cardBasedOptions?[2]?.cardBrand, 'amex');
    });
  });

  group('CardConfigurationMapper with installments', () {
    test('maps CardConfiguration with installmentConfiguration to DTO', () {
      final installmentConfig = InstallmentConfiguration(
        defaultOptions: DefaultInstallmentOptions(
          values: [2, 3, 6],
          includesRevolving: true,
        ),
        showInstallmentAmount: true,
      );

      final cardConfig = CardConfiguration(
        holderNameRequired: true,
        addressMode: AddressMode.full,
        installmentConfiguration: installmentConfig,
      );

      final dto = cardConfig.toDTO();

      expect(dto.holderNameRequired, true);
      expect(dto.addressMode, AddressMode.full);
      expect(dto.installmentConfiguration?.defaultOptions?.values, [2, 3, 6]);
      expect(dto.installmentConfiguration?.showInstallmentAmount, true);
    });

    test('maps CardConfiguration without installmentConfiguration', () {
      const cardConfig = CardConfiguration(
        holderNameRequired: false,
      );

      final dto = cardConfig.toDTO();

      expect(dto.holderNameRequired, false);
      expect(dto.installmentConfiguration, null);
    });

    test('preserves all CardConfiguration fields with installments', () {
      final installmentConfig = InstallmentConfiguration(
        defaultOptions: DefaultInstallmentOptions(values: [2, 3]),
      );

      final cardConfig = CardConfiguration(
        holderNameRequired: true,
        addressMode: AddressMode.full,
        showStorePaymentField: true,
        showCvcForStoredCard: true,
        showCvc: true,
        supportedCardTypes: ['visa', 'mc'],
        installmentConfiguration: installmentConfig,
      );

      final dto = cardConfig.toDTO();

      expect(dto.holderNameRequired, true);
      expect(dto.addressMode, AddressMode.full);
      expect(dto.showStorePaymentField, true);
      expect(dto.showCvcForStoredCard, true);
      expect(dto.showCvc, true);
      expect(dto.supportedCardTypes, ['visa', 'mc']);
      expect(dto.installmentConfiguration, isNotNull);
    });
  });

  group('Integration tests', () {
    test('full flow: create config with installments and map to DTO', () {
      final defaultOptions = DefaultInstallmentOptions(
        values: [6, 12],
        includesRevolving: true,
      );

      final cardBasedOptions = [
        CardBasedInstallmentOptions(
          cardBrand: 'visa',
          values: [9, 12],
          includesRevolving: true,
        ),
        CardBasedInstallmentOptions(
          cardBrand: 'mc',
          values: [2, 3, 6],
          includesRevolving: false,
        ),
      ];

      final installmentConfig = InstallmentConfiguration(
        defaultOptions: defaultOptions,
        cardBasedOptions: cardBasedOptions,
        showInstallmentAmount: true,
      );

      final cardConfig = CardConfiguration(
        holderNameRequired: true,
        addressMode: AddressMode.full,
        installmentConfiguration: installmentConfig,
      );

      final dto = cardConfig.toDTO();

      expect(dto.installmentConfiguration?.defaultOptions?.values, [6, 12]);
      expect(dto.installmentConfiguration?.defaultOptions?.includesRevolving,
          true);
      expect(dto.installmentConfiguration?.cardBasedOptions?.length, 2);
      expect(dto.installmentConfiguration?.cardBasedOptions?[0]?.cardBrand,
          'visa');
      expect(
          dto.installmentConfiguration?.cardBasedOptions?[0]?.values, [9, 12]);
      expect(
          dto.installmentConfiguration?.cardBasedOptions?[1]?.cardBrand, 'mc');
      expect(dto.installmentConfiguration?.cardBasedOptions?[1]?.values,
          [2, 3, 6]);
      expect(dto.installmentConfiguration?.showInstallmentAmount, true);
    });

    test('example from drop_in_screen.dart maps correctly', () {
      final installmentConfig = InstallmentConfiguration(
        defaultOptions: DefaultInstallmentOptions(
          values: [6, 12],
          includesRevolving: true,
        ),
        cardBasedOptions: [
          CardBasedInstallmentOptions(
            cardBrand: 'visa',
            values: [9, 12],
            includesRevolving: true,
          ),
          CardBasedInstallmentOptions(
            cardBrand: 'mc',
            values: [2, 3, 6],
            includesRevolving: false,
          ),
        ],
        showInstallmentAmount: true,
      );

      final dto = installmentConfig.toDTO();

      expect(dto.defaultOptions?.values, [6, 12]);
      expect(dto.cardBasedOptions?.length, 2);
      expect(dto.showInstallmentAmount, true);
    });

    test('example from card_advanced_component_screen.dart maps correctly', () {
      final installmentConfig = InstallmentConfiguration(
        defaultOptions: DefaultInstallmentOptions(
          values: [2, 3, 6, 12],
          includesRevolving: true,
        ),
        showInstallmentAmount: true,
      );

      final dto = installmentConfig.toDTO();

      expect(dto.defaultOptions?.values, [2, 3, 6, 12]);
      expect(dto.defaultOptions?.includesRevolving, true);
      expect(dto.cardBasedOptions, null);
      expect(dto.showInstallmentAmount, true);
    });
  });
}
