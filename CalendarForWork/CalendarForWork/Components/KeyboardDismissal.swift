import UIKit

extension UIViewController {
    func enableKeyboardDismissOnTap(cancelsTouchesInView: Bool = false) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditingFromTap))
        tapGesture.cancelsTouchesInView = cancelsTouchesInView
        view.addGestureRecognizer(tapGesture)
    }

    func observeKeyboardForScrollView(_ scrollView: UIScrollView) {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak scrollView] notification in
            guard let self = self,
                  let scrollView = scrollView,
                  let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }

            let convertedFrame = self.view.convert(keyboardFrame, from: nil)
            let overlap = max(self.view.bounds.maxY - convertedFrame.minY, 0)
            scrollView.contentInset.bottom = overlap + AppTheme.Spacing.md
            scrollView.verticalScrollIndicatorInsets.bottom = overlap + AppTheme.Spacing.md
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak scrollView] _ in
            scrollView?.contentInset.bottom = 0
            scrollView?.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    func doneToolbar(selector: Selector = #selector(endEditingFromTap)) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Xong", style: .done, target: self, action: selector)
        ]
        return toolbar
    }

    @objc private func endEditingFromTap() {
        view.endEditing(true)
    }
}

extension UIViewController: @retroactive UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
