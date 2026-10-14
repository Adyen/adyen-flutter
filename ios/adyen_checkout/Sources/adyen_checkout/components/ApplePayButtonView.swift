import PassKit
import UIKit

@MainActor
final class ApplePayButtonView: UIView {
    let height: CGFloat
    private let button: PKPaymentButton
    private let onTap: () -> Void

    var isEnabled: Bool {
        get { button.isEnabled }
        set { button.isEnabled = newValue }
    }

    init(
        style: ApplePayButtonStyleDTO?,
        width: Double?,
        height: Double?,
        onTap: @escaping () -> Void
    ) {
        let buttonType = Self.mapApplePayButtonType(style?.type)
        let minimumWidth = buttonType == .plain ? 100.0 : 140.0
        let buttonWidth = max(width ?? minimumWidth, minimumWidth)
        let buttonHeight = max(height ?? 30.0, 30.0)
        self.height = buttonHeight
        self.button = PKPaymentButton(
            paymentButtonType: buttonType,
            paymentButtonStyle: Self.mapApplePayButtonStyle(style?.theme)
        )
        self.onTap = onTap
        super.init(frame: .zero)

        if let cornerRadius = style?.cornerRadius {
            button.cornerRadius = cornerRadius
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(
            self,
            action: #selector(handleTap),
            for: .touchUpInside
        )

        addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: buttonWidth),
            button.heightAnchor.constraint(equalToConstant: buttonHeight),
            heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap()
    }

    private static func mapApplePayButtonStyle(_ theme: ApplePayButtonThemeDTO?) -> PKPaymentButtonStyle {
        switch theme {
        case .white: return .white
        case .whiteWithLine: return .whiteOutline
        case .automatic: return .automatic
        case .black, nil: return .black
        }
    }

    private static func mapApplePayButtonType(_ type: ApplePayButtonTypeDTO?) -> PKPaymentButtonType {
        guard let type else { return .plain }
        return applePayButtonTypes[type] ?? .plain
    }

    private static let applePayButtonTypes: [ApplePayButtonTypeDTO: PKPaymentButtonType] = [
        .plain: .plain,
        .buy: .buy,
        .setUp: .setUp,
        .inStore: .inStore,
        .donate: .donate,
        .checkout: .checkout,
        .book: .book,
        .subscribe: .subscribe,
        .reload: .reload,
        .addMoney: .addMoney,
        .topUp: .topUp,
        .order: .order,
        .rent: .rent,
        .support: .support,
        .contribute: .contribute,
        .tip: .tip
    ]
}
