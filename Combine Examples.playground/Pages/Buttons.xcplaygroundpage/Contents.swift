import UIKit
import Combine

extension UIControl {
    private static var onTapKey = "onTapKey"
    private var _onTap: PassthroughSubject<Void, Never> {
        if let onTap = objc_getAssociatedObject(self, &UIControl.onTapKey) as? PassthroughSubject<Void, Never> {
            return onTap
        } else {
            let onTap = PassthroughSubject<Void, Never>()
            objc_setAssociatedObject(self, &UIControl.onTapKey, onTap, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            addTarget(self, action: #selector(sendTapEvent), for: .touchUpInside)
            return onTap
        }
    }
    public final var onTap: AnyPublisher<Void, Never> { _onTap.eraseToAnyPublisher() }
    @objc private func sendTapEvent() {
        _onTap.send()
    }
}

let button = UIButton()

let cancellable = button.onTap.sink {
    print("button did tap")
}

button.sendActions(for: .touchUpInside)
