import 'package:adyen_checkout_example/screens/api_only/card_state.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state_notifier.dart';
import 'package:adyen_checkout_example/screens/api_only/input_formatters/card_number_input_formatter.dart';
import 'package:adyen_checkout_example/screens/api_only/input_formatters/month_year_input_formatter.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardWidget extends StatefulWidget {
  final CardStateNotifier cardStateNotifier;

  const CardWidget({required this.cardStateNotifier, super.key});

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  final _cardNumberController = TextEditingController();
  final _securityCodeController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final lightGrey = const Color(0xFFF7F7F8);
  final darkerGrey = const Color(0xFFC9CDD3);
  final lighterDark = const Color(0xFF1B1919);
  final borderRadius = BorderRadius.circular(8);

  @override
  void dispose() {
    _cardNumberController.dispose();
    _securityCodeController.dispose();
    _expiryDateController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cardStateNotifier.reset();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CardState>(
      valueListenable: widget.cardStateNotifier,
      builder: (context, cardState, _) {
        return Container(
          decoration: BoxDecoration(
            color: lightGrey,
            border: Border.all(color: darkerGrey),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: widget.cardStateNotifier.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardFormHeader(),
                const SizedBox(height: 16),
                _inputFieldTitle('Card number'),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: createInputDecoration(
                    _buildRelatedCardBrandsIcons(cardState),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                    CardNumberInputFormatter(),
                  ],
                  onChanged: (value) =>
                      widget.cardStateNotifier.updateCardNumber(value),
                  validator: (value) => cardState.isCardNumberValid == false
                      ? 'Enter a valid card number'
                      : null,
                ),
                const SizedBox(height: 8),
                _buildBrandLogoRow(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _inputFieldTitle('Expiry date'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _expiryDateController,
                            decoration: createInputDecoration(
                              _buildIcon('assets/expiry_date_hint.svg'),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              MonthYearInputFormatter(),
                            ],
                            onChanged: (value) => widget.cardStateNotifier
                                .updateExpiryDate(value),
                            validator: (value) =>
                                cardState.isExpiryDateValid == false
                                    ? 'Invalid expiry date'
                                    : null,
                          ),
                          const SizedBox(height: 4),
                          _inputFieldSubText('Front of card in MM/YY format'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _inputFieldTitle('Security code'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _securityCodeController,
                            decoration: createInputDecoration(
                              _buildIcon('assets/cvc_hint.svg'),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (value) => widget.cardStateNotifier
                                .updateSecurityCode(value),
                            validator: (value) =>
                                cardState.isSecurityCodeValid == false
                                    ? 'Invalid security code'
                                    : null,
                          ),
                          const SizedBox(height: 4),
                          _inputFieldSubText('3 digits on back of card'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.maxFinite,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00112C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: cardState.loading || !cardState.isInputValid
                        ? null
                        : () => _makePayment(context),
                    child: cardState.loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('PAY'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePayment(BuildContext context) async {
    final resultCode = await widget.cardStateNotifier.pay();
    if (resultCode != null && context.mounted) {
      DialogBuilder.showPaymentResultDialog(
        'Payment Result',
        'Result code: $resultCode',
        context,
      );
    }
  }

  Widget _buildCardFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SvgPicture.asset(
                'assets/card.svg',
                fit: BoxFit.scaleDown,
                height: 26,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Cards',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('All fields are required unless marked otherwise.')
      ],
    );
  }

  Widget _inputFieldTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      );

  Widget _inputFieldSubText(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      );

  Row _buildBrandLogoRow() => Row(
        children: [
          SvgPicture.asset(
            'assets/card_brands/visa.svg',
            fit: BoxFit.scaleDown,
            height: 16,
          ),
          const SizedBox(width: 4),
          SvgPicture.asset(
            'assets/card_brands/mc.svg',
            fit: BoxFit.scaleDown,
            height: 16,
          ),
          const SizedBox(width: 4),
          SvgPicture.asset(
            'assets/card_brands/amex.svg',
            fit: BoxFit.scaleDown,
            height: 16,
          ),
          const SizedBox(width: 4),
          SvgPicture.asset(
            'assets/card_brands/cup.svg',
            fit: BoxFit.scaleDown,
            height: 16,
          ),
        ],
      );

  InputDecoration createInputDecoration(Widget suffixIcon) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkerGrey),
        borderRadius: borderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: lighterDark, width: 1),
        borderRadius: borderRadius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: borderRadius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: borderRadius,
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildRelatedCardBrandsIcons(CardState cardState) {
    final relatedCardBrandIcons = cardState.relatedCardBrands
        ?.map((cardBrand) => SvgPicture.asset(
              width: 30,
              'assets/card_brands/$cardBrand.svg',
              fit: BoxFit.scaleDown,
            ))
        .toList();

    if (relatedCardBrandIcons == null || relatedCardBrandIcons.isEmpty) {
      return _buildIcon('assets/default_card.svg');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: relatedCardBrandIcons,
    );
  }

  Widget _buildIcon(String iconAssetPath) => SvgPicture.asset(
        iconAssetPath,
        fit: BoxFit.scaleDown,
      );
}
