import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when map DropInConfiguration then should map to DropInConfigurationDTO',
      () {
    const demoClientKey = "1234567890";
    const countryCode = "US";
    const currency = "USD";
    const amountValue = 1286;
    final dropInConfiguration = DropInConfiguration(
      environment: Environment.test,
      clientKey: demoClientKey,
      countryCode: countryCode,
      amount: Amount(value: amountValue, currency: currency),
    );
    final dropInConfigurationDto = dropInConfiguration.toDTO("0.0.1");

    expect(dropInConfigurationDto.environment, Environment.test);
    expect(dropInConfigurationDto.clientKey, demoClientKey);
    expect(dropInConfigurationDto.countryCode, countryCode);
    expect(dropInConfigurationDto.amount.value, amountValue);
    expect(dropInConfigurationDto.amount.currency, currency);
    expect(dropInConfigurationDto.amount.runtimeType == AmountDTO, true);
    expect(dropInConfigurationDto.shopperLocale, null);
    expect(dropInConfigurationDto.cardConfigurationDTO, null);
    expect(dropInConfigurationDto.applePayConfigurationDTO, null);
    expect(dropInConfigurationDto.googlePayConfigurationDTO, null);
    expect(dropInConfigurationDto.cashAppPayConfigurationDTO, null);
    expect(dropInConfigurationDto.analyticsOptionsDTO.enabled, true);
    expect(dropInConfigurationDto.isRemoveStoredPaymentMethodEnabled, false);
    expect(dropInConfigurationDto.skipListWhenSinglePaymentMethod, false);
  });
}
