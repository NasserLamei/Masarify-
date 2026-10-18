import SwiftUI
import UIKit

/// Single visible amount field (system digits — Cairo/SwiftUI TextField hid typed numbers).
struct MasarifyAmountField: View {
    var placeholder: String
    @Binding var text: String
    var fontSize: CGFloat = 22

    var body: some View {
        MasarifyAmountUITextField(text: $text, placeholder: placeholder, fontSize: fontSize)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(BrandTheme.deepTeal.opacity(0.5), lineWidth: 1.5)
            )
    }
}

private struct MasarifyAmountUITextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = VisibleAmountTextField()
        field.delegate = context.coordinator
        field.keyboardType = .decimalPad
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.accessibilityIdentifier = "masarify.amount.field"
        field.semanticContentAttribute = .forceLeftToRight
        field.textAlignment = .left
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 16
        // Keep number input LTR with Latin digits regardless of app Arabic locale.
        field.textContentType = nil
        applyVisibleTypingStyle(field, fontSize: fontSize)
        field.attributedPlaceholder = placeholderAttributes(placeholder, fontSize: fontSize)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        field.text = WesternDigits.normalize(text)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.text = $text
        applyVisibleTypingStyle(field, fontSize: fontSize)
        let normalized = WesternDigits.normalize(text)
        if field.text != normalized {
            field.text = normalized
        }
        field.attributedPlaceholder = placeholderAttributes(placeholder, fontSize: fontSize)
    }

    private func applyVisibleTypingStyle(_ field: UITextField, fontSize: CGFloat) {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        field.font = font
        field.textColor = .black
        field.tintColor = UIColor(BrandTheme.deepTeal)
        field.defaultTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: font
        ]
        field.typingAttributes = [
            .foregroundColor: UIColor.black,
            .font: font
        ]
    }

    private func placeholderAttributes(_ placeholder: String, fontSize: CGFloat) -> NSAttributedString {
        AppFont.placeholderAttributed(placeholder, size: max(15, fontSize - 4), weight: .medium)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func editingChanged(_ field: UITextField) {
            let raw = field.text ?? ""
            let value = WesternDigits.normalize(raw)
            if field.text != value {
                field.text = value
            }
            if text.wrappedValue != value {
                text.wrappedValue = value
            }
            let font = field.font ?? .systemFont(ofSize: 22, weight: .bold)
            field.textColor = .black
            field.typingAttributes = [
                .foregroundColor: UIColor.black,
                .font: font
            ]
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            textField.textColor = .black
        }
    }
}

final class VisibleAmountTextField: UITextField {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        textColor = .black
        tintColor = UIColor(BrandTheme.deepTeal)
    }

    override var textColor: UIColor? {
        get { super.textColor }
        set { super.textColor = .black }
    }
}
