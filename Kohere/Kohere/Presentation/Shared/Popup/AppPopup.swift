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
        let route: Route
    }

    enum Route: Equatable {
        case logout
        case deleteAccount
    }
}
