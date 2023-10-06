enum TemporaryAlertHelper {
    static func buildPaymentMethodDeletionErrorAlert() -> UIAlertController {
        // TODO: - this should be part of the native SDK and be translated there
        let alertController = UIAlertController(title: "Error", message: "Removal of the stored payment method failed. Please try again later.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        return alertController
    }
}
