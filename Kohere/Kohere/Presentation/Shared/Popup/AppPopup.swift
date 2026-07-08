//
//  AppPopup.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

enum AppPopup: Equatable {
    case notice(Notice)
    case action(Action)

    struct Notice: Equatable {
        let message: String
        var confirmTitle = "확인"
    }

    struct Action: Equatable {
        let message: String
        let primaryTitle: String
        var secondaryTitle = "취소"
        var primaryRoute: Route?
        var secondaryRoute: Route?

        init(
            message: String,
            primaryTitle: String,
            secondaryTitle: String = "취소",
            primaryRoute: Route? = nil,
            secondaryRoute: Route? = nil
        ) {
            self.message = message
            self.primaryTitle = primaryTitle
            self.secondaryTitle = secondaryTitle
            self.primaryRoute = primaryRoute
            self.secondaryRoute = secondaryRoute
        }

        init(
            message: String,
            primaryTitle: String,
            secondaryTitle: String = "취소",
            route: Route
        ) {
            self.init(
                message: message,
                primaryTitle: primaryTitle,
                secondaryTitle: secondaryTitle,
                primaryRoute: route
            )
        }
    }

    enum Route: Equatable {
        case logout
        case deleteAccount
    }
}
