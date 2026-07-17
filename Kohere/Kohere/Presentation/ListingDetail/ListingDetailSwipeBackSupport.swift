//
//  ListingDetailSwipeBackSupport.swift
//  Kohere
//
//  Created by Codex on 7/17/26.
//

import SwiftUI
import UIKit

struct ListingDetailSwipeBackEnabler: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> NavigationControllerResolverView {
        let view = NavigationControllerResolverView()
        view.onResolve = { [weak coordinator = context.coordinator] navigationController in
            coordinator?.enableSwipeBack(in: navigationController)
        }
        view.onRemoval = { [weak coordinator = context.coordinator] in
            coordinator?.restoreSwipeBack()
        }
        return view
    }

    func updateUIView(_ uiView: NavigationControllerResolverView, context: Context) {}

    static func dismantleUIView(
        _ uiView: NavigationControllerResolverView,
        coordinator: Coordinator
    ) {
        coordinator.restoreSwipeBack()
    }

    final class Coordinator: NSObject {
        private weak var navigationController: UINavigationController?
        private weak var popGestureRecognizer: UIGestureRecognizer?
        private weak var previousDelegate: UIGestureRecognizerDelegate?
        private var previousIsEnabled = false

        func enableSwipeBack(in navigationController: UINavigationController) {
            guard self.navigationController !== navigationController,
                  let popGestureRecognizer = navigationController.interactivePopGestureRecognizer else {
                return
            }

            restoreSwipeBack()

            self.navigationController = navigationController
            self.popGestureRecognizer = popGestureRecognizer
            previousDelegate = popGestureRecognizer.delegate
            previousIsEnabled = popGestureRecognizer.isEnabled

            popGestureRecognizer.delegate = nil
            popGestureRecognizer.isEnabled = navigationController.viewControllers.count > 1
        }

        func restoreSwipeBack() {
            guard let popGestureRecognizer else {
                return
            }

            if popGestureRecognizer.delegate == nil {
                popGestureRecognizer.delegate = previousDelegate
                popGestureRecognizer.isEnabled = previousIsEnabled
            }

            navigationController = nil
            self.popGestureRecognizer = nil
            previousDelegate = nil
        }
    }

    final class NavigationControllerResolverView: UIView {
        var onResolve: ((UINavigationController) -> Void)?
        var onRemoval: (() -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard window != nil else {
                onRemoval?()
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self,
                      window != nil else {
                    return
                }

                guard let navigationController else { return }

                onResolve?(navigationController)
            }
        }

        private var navigationController: UINavigationController? {
            var responder: UIResponder? = self

            while let currentResponder = responder {
                if let navigationController = currentResponder as? UINavigationController {
                    return navigationController
                }

                if let viewController = currentResponder as? UIViewController,
                   let navigationController = viewController.navigationController {
                    return navigationController
                }

                responder = currentResponder.next
            }

            return nil
        }
    }
}
