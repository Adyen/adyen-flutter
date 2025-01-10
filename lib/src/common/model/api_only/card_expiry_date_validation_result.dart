sealed class CardExpiryDateValidationResult {}

class ValidCardExpiryDate extends CardExpiryDateValidationResult {}

// We do not use a sealed class in order to prevent breaking changes in the future when adding more invalid reasons.
abstract class InvalidCardExpiryDate extends CardExpiryDateValidationResult {}

final class InvalidCardExpiryDateOtherReason extends InvalidCardExpiryDate {}
