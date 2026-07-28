/// The shopper's name.
///
/// Field names match the Adyen Checkout API's `shopperName` schema. [infix]
/// and [gender] are not yet populated when coming from iOS, pending a native
/// SDK change to expose them there.
class ShopperName {
  final String? firstName;
  final String? lastName;
  final String? infix;
  final String? gender;

  const ShopperName({
    this.firstName,
    this.lastName,
    this.infix,
    this.gender,
  });

  @override
  String toString() {
    return 'ShopperName('
        'firstName: $firstName, '
        'lastName: $lastName, '
        'infix: $infix, '
        'gender: $gender)';
  }
}
