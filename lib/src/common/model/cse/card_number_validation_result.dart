sealed class CardNumberValidationResult {}

final class Valid extends CardNumberValidationResult {}

// We do not use a sealed class in order to prevent breaking changes in the future when adding more invalid reasons.
abstract class Invalid extends CardNumberValidationResult {}

final class InvalidOtherReason extends Invalid {}
