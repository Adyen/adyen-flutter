![Flutter](https://github.com/Adyen/adyen-flutter/assets/13377878/66a9fab8-dba0-426f-acd4-ab0bfd469d20)

# Adyen Flutter

The Adyen Flutter package provides you with the building blocks to create a checkout experience for your shoppers, allowing them to pay using the payment method of their choice.

You can integrate with the following:

* **Drop-in**: an out-of-the-box Flutter wrapper for native iOS and Android Drop-in that includes all available payment methods for your shoppers to choose.
* **Components**: Flutter widgets for native iOS and Android Adyen Components. You use one Component for each payment method. We currently offer the following Components:
    - Card Component: allows shoppers to pay with card. Stored cards are also supported.
    - Google Pay Component: renders a Google Pay button.
    - Apple Pay Component: renders an Apple Pay button.
    - Instant Component: supports payment methods that do not require additional input fields, like PayPal, Klarna and many more.

|                                                             iOS                                                              |                                                                Android                                                                |
|:--------------------------------------------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------------------------:|
| <img align="top" src="https://github.com/Adyen/adyen-flutter/assets/13377878/03169e08-665d-4afa-96a4-19cb4594421a" height="400" /> | <img align="top" src="https://github.com/Adyen/adyen-flutter/assets/13377878/f8c1de69-862d-420b-a7dd-76eb04284685" height="400" /> |


## Contributing

Follow our [guidelines](https://github.com/Adyen/.github/blob/main/CONTRIBUTING.md) to provide feedback and contribute the following to this repository:
* New features and functionality
* Bug fixes and resolved issues
* General improvements

We merge each pull request into the `main` branch. We aim to keep it in good shape so that we can release a new version when we need to.

## Before you begin

1. [Get an Adyen test account](https://www.adyen.com/signup).
2. [Get your Client key](https://docs.adyen.com/development-resources/client-side-authentication#get-your-client-key). Your client app does not communicate with the Adyen API directly.
3. [Get your API key](https://docs.adyen.com/development-resources/how-to-get-the-api-key). You need the API key to make requests from your server .
4. [Set up your webhooks](https://docs.adyen.com/development-resources/webhooks/) to get the payment outcome.

Required versions:
* [Checkout API v71](https://docs.adyen.com/api-explorer/Checkout/71/overview) or later.
* [iOS 12](https://support.apple.com/en-us/118387) or later.
* [Android 5.0](https://www.android.com/versions/lollipop-5-0/) or later.


## Integration

Depending on the [server-side flow](https://docs.adyen.com/online-payments/build-your-integration/) you use, follow corresponding the integration guide in our documentation.

### Sessions flow
* [Drop-in integration guide with Sessions flow](https://docs.adyen.com/online-payments/build-your-integration/sessions-flow/?platform=Flutter&integration=Drop-in)
* [Components integration guide with Sessions flow](https://docs.adyen.com/online-payments/build-your-integration/sessions-flow/?platform=Flutter&integration=Components)

### Advanced flow
* [Drop-in integration guide with Advanced flow](https://docs.adyen.com/online-payments/build-your-integration/advanced-flow/?platform=Flutter&integration=Drop-in)
* [Components integration guide with Advanced flow](https://docs.adyen.com/online-payments/build-your-integration/advanced-flow/?platform=Flutter&integration=Components)

## Customization

You can customize the styling of the user interface. Follow the guides for each platform:
* [UI customization](/docs/CUSTOMIZATION.md)

## Support

If you have a feature request, or spotted a bug or a technical problem, create a GitHub issue. For other questions, contact our Support Team via [Customer Area](https://ca-live.adyen.com/ca/ca/contactUs/support.shtml) or via email: support@adyen.com

## See also
* [Adyen Checkout API](https://docs.adyen.com/api-explorer/Checkout/latest/overview)
* [Adyen online payments documentation](https://docs.adyen.com/online-payments/)

## License

MIT license. For more information, see the LICENSE file.

