enum ResultCode {
  authenticationFinished("AuthenticationFinished"),
  authenticationNotRequired("AuthenticationNotRequired"),
  authorised("Authorised"),
  refused("Refused"),
  pending("Pending"),
  cancelled("Cancelled"),
  error("Error"),
  received("Received"),
  redirectShopper("RedirectShopper"),
  identifyShopper("IdentifyShopper"),
  challengeShopper("ChallengeShopper"),
  presentToShopper("PresentToShopper"),
  partiallyAuthorised("PartiallyAuthorised"),
  unknown("Unknown");

  final String name;

  const ResultCode(this.name);
}
