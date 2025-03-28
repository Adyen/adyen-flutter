import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state_notifier.dart';
import 'package:adyen_checkout_example/screens/api_only/input_formatters/month_year_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_formatters/card_number_input_formatter.dart';

class CardWidget extends StatefulWidget {
  const CardWidget({super.key, required this.cardModelNotifier});

  final CardStateNotifier cardModelNotifier;

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  final _cardNumberController = TextEditingController();
  final _securityCodeController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final lightGrey = const Color(0xFFf7f7f8);
  final darkerGrey = const Color(0xFFc9cdd3);
  final lighterDark = const Color(0xff1b1919);
  final borderRadius = BorderRadius.circular(8);

  @override
  void dispose() {
    _cardNumberController.dispose();
    _securityCodeController.dispose();
    _expiryDateController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cardModelNotifier.reset();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardModel = widget.cardModelNotifier.value;

    return Container(
      decoration: BoxDecoration(
        color: lightGrey,
        border: Border.all(color: darkerGrey),
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.cardModelNotifier.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardFormHeader(),
            const SizedBox(height: 16),
            _inputFieldTitle("Card number"),
            const SizedBox(height: 4),
            TextFormField(
              controller: _cardNumberController,
              decoration: createInputDecoration("assets/nocard.svg"),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                CardNumberInputFormatter(),
              ],
              onChanged: (value) {
                widget.cardModelNotifier.updateCardNumber(value);
              },
              validator: (value) {
                if (cardModel.cardNumberValidationResult
                    is InvalidCardNumber?) {
                  return 'Enter a valid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _buildBrandLogoRow(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      _inputFieldTitle("Expiry date"),
                      TextFormField(
                        controller: _expiryDateController,
                        decoration: createInputDecoration(
                            "assets/expiry_date_hint.svg"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          MonthYearInputFormatter(),
                        ],
                        onChanged: (value) {
                          widget.cardModelNotifier.updateExpiryDate(value);
                        },
                        validator: (value) {
                          if (cardModel.cardExpiryDateValidationResult
                              is InvalidCardExpiryDate?) {
                            return 'Invalid expiry date';
                          }
                          return null;
                        },
                      ),
                      _inputFieldSubText("Front of card in MM/YY format"),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      _inputFieldTitle("Security code"),
                      TextFormField(
                        controller: _securityCodeController,
                        decoration:
                            createInputDecoration("assets/cvc_hint.svg"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: (value) {
                          widget.cardModelNotifier.updateSecurityCode(value);
                        },
                        validator: (value) {
                          if (cardModel.cardSecurityCodeValidationResult
                              is InvalidCardSecurityCode?) {
                            return 'Invalid security code';
                          }
                          return null;
                        },
                      ),
                      _inputFieldSubText("3 digits on back of card"),
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
                  backgroundColor: const Color(0xFF00112c),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18, // Adjust as needed
                    fontWeight: FontWeight.w600, // Semi-bold font weight
                  ),
                ),
                onPressed: cardModel.loading == true
                    ? null
                    : () => _makePayment(context),
                child: cardModel.loading == true
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("PAY"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePayment(BuildContext context) async {
    final paymentResultCode = await widget.cardModelNotifier.pay();
    if (paymentResultCode != null) {
      showPaymentResultCodeDialog(paymentResultCode);
    }
  }

  Widget _buildCardFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            SvgPicture.asset(
              "assets/card.svg",
              fit: BoxFit.scaleDown,
              height: 26,
            ),
            const Text(
              "Cards",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Text("All fields are required unless marked otherwise.")
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

  Row _buildBrandLogoRow() {
    return Row(
      spacing: 4,
      children: [
        SvgPicture.asset(
          "assets/visa.svg",
          fit: BoxFit.scaleDown,
          height: 16,
        ),
        SvgPicture.asset(
          "assets/mc.svg",
          fit: BoxFit.scaleDown,
          height: 16,
        ),
        SvgPicture.asset(
          "assets/amex.svg",
          fit: BoxFit.scaleDown,
          height: 16,
        ),
        SvgPicture.asset(
          "assets/cup.svg",
          fit: BoxFit.scaleDown,
          height: 16,
        ),
      ],
    );
  }

  InputDecoration createInputDecoration(String? iconAssetPath) {
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
      suffixIcon: iconAssetPath == null
          ? null
          : SvgPicture.asset(
              iconAssetPath,
              fit: BoxFit.scaleDown,
            ),
    );
  }

  void showPaymentResultCodeDialog(
    ResultCode resultCode,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Result:"),
          content: Text(resultCode.toString()),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Close'),
              onPressed: () {
                //Close dialog
                Navigator.of(context).pop();
                //Close page
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
