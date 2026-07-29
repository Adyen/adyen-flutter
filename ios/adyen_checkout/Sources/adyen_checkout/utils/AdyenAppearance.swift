// TODO: v6 migration - FormComponentStyle (and DropInComponent.Style) are now package-access.
// Per-component styling has moved to a checkout-wide CheckoutTheme (colors + corner radius only,
// via CheckoutConfiguration.theme(_:)), which is not a drop-in replacement for the granular
// per-field styling this type used to expose. Needs a real design follow-up once fine-grained
// theming lands in the public v6 API on iOS.
public enum AdyenAppearance {}
