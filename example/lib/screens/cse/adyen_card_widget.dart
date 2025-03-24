import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdyenCardWidget extends StatefulWidget {
  const AdyenCardWidget({super.key});

  @override
  State<AdyenCardWidget> createState() => _AdyenCardWidgetState();
}

class _AdyenCardWidgetState extends State<AdyenCardWidget> {
  final _cardNumberController = TextEditingController();
  final _securityCodeController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final lightGrey = const Color(0xFFf7f7f8);
  final darkerGrey = const Color(0xFFc9cdd3);
  final lighterDark = const Color(0xff1b1919);
  final borderRadius = BorderRadius.circular(8);



  @override
  void dispose() {
    _cardNumberController.dispose();
    _securityCodeController.dispose();
    _expiryDateController.dispose();
    _cardHolderNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: lightGrey,
        border: Border.all(color: darkerGrey),
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
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
                LengthLimitingTextInputFormatter(16),
                _CreditCardNumberInputFormatter(),
              ],
              validator: (value) {
                print(value);
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
                        ],
                        validator: (value) {
                          print(value);
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
                        decoration: createInputDecoration(
                            "assets/cvc_hint.svg"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          print(value);
                        },
                      ),
                      _inputFieldSubText("3 digits on back of card"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _inputFieldTitle("Name on card"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cardHolderNameController,
              decoration: createInputDecoration(null),
              validator: (value) {
                print(value);
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00112c),
                  // Dark blue background
                  foregroundColor: Colors.white,
                  // White text color
                  minimumSize: const Size(double.infinity, 56),
                  // Full width, fixed height
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18, // Adjust as needed
                    fontWeight: FontWeight.w600, // Semi-bold font weight
                  ),
                ),
                onPressed: () {},
                child: const Text("PAY"),
              ),
            ),
          ],
        ),
      ),
    );
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
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkerGrey),
        borderRadius: borderRadius,
      ),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: lighterDark, width: 1),
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
}

class _CreditCardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
