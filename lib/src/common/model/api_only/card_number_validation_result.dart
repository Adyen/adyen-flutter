sealed class CardNumberValidationResult {}

class ValidCardNumber extends CardNumberValidationResult {}

// We do not use a sealed class in order to prevent breaking changes in the future when adding more invalid reasons.
abstract class InvalidCardNumber extends CardNumberValidationResult {}

final class InvalidCardNumberOtherReason extends InvalidCardNumber {}
