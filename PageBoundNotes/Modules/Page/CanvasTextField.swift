import SwiftUI
import UIKit

struct CanvasTextField: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var textColor: UIColor
    var shouldBecomeFirstResponder: Bool
    var onEditingEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> FocusableTextView {
        let textView = FocusableTextView()
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.text = text
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
        textView.keyboardDismissMode = .interactive
        textView.onFocusSucceeded = { [weak coordinator = context.coordinator] in
            coordinator?.didBecomeFirstResponder = true
            coordinator?.pendingFocusAttempts = 0
        }
        return textView
    }

    func updateUIView(_ uiView: FocusableTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.font != font {
            uiView.font = font
        }
        if uiView.textColor != textColor {
            uiView.textColor = textColor
        }

        uiView.shouldRequestFocus = shouldBecomeFirstResponder

        if shouldBecomeFirstResponder, !context.coordinator.didBecomeFirstResponder {
            context.coordinator.requestFirstResponder(on: uiView)
        }

        if !shouldBecomeFirstResponder, uiView.isFirstResponder {
            uiView.resignFirstResponder()
            context.coordinator.didBecomeFirstResponder = false
            context.coordinator.pendingFocusAttempts = 0
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CanvasTextField
        var didBecomeFirstResponder = false
        var pendingFocusAttempts = 0
        private let maxFocusAttempts = 8

        init(parent: CanvasTextField) {
            self.parent = parent
        }

        func requestFirstResponder(on textView: FocusableTextView) {
            guard !didBecomeFirstResponder, pendingFocusAttempts < maxFocusAttempts else { return }
            guard textView.window != nil else { return }

            pendingFocusAttempts += 1
            DispatchQueue.main.async { [weak self, weak textView] in
                guard let self, let textView else { return }
                guard textView.window != nil else {
                    self.pendingFocusAttempts = max(0, self.pendingFocusAttempts - 1)
                    return
                }
                if textView.becomeFirstResponder() {
                    self.didBecomeFirstResponder = true
                    self.pendingFocusAttempts = 0
                } else if self.pendingFocusAttempts < self.maxFocusAttempts {
                    self.requestFirstResponder(on: textView)
                }
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            didBecomeFirstResponder = false
            pendingFocusAttempts = 0
            parent.onEditingEnded()
        }
    }
}

final class FocusableTextView: UITextView {
    var shouldRequestFocus = false
    var onFocusSucceeded: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, shouldRequestFocus, !isFirstResponder else { return }
        if becomeFirstResponder() {
            onFocusSucceeded?()
        }
    }
}
