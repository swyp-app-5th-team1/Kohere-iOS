//
//  AppPopup.swift
//  Kohere
//
//  Created by soomin on 7/8/26.
//

enum AppPopup: Equatable {
    case notice(Notice)
    case action(Action)

    struct Notice: Equatable {
        let message: String
        let confirmTitle: String
        var confirmRoute: Route?
    }

    struct Action: Equatable {
        let message: String
        let primaryTitle: String
        let secondaryTitle: String
        var primaryRoute: Route?
        var secondaryRoute: Route?

        init(
            message: String,
            primaryTitle: String,
            secondaryTitle: String,
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
            secondaryTitle: String,
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
        case signIn
        case home
        case logout
        case deleteAccount
        case reportBooking(Int)
        case blockBooking(Int)
        case deleteBooking(Int)
        case dismissListingDetail
        case confirmLanguageChange(AppLanguage)
        case retryNotificationSettings
        case dismissNotificationSettings
        case openNotificationSettings
    }
}
