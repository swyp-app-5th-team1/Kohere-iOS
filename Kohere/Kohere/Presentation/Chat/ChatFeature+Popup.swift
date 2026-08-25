//
//  ChatFeature+Popup.swift
//  Kohere
//
//  Created by soomin on 8/9/26.
//

extension ChatFeature {
    static func popup(for action: SwipeAction, roomID: Int, language: AppLanguage) -> AppPopup {
        let content: (messageKey: String, primaryTitleKey: String)
        let route: AppPopup.Route

        switch action {
        case .report:
            content = ("chat.popup.report.message", "chat.popup.report.primary")
            route = .reportBooking(roomID)
        case .block:
            content = ("chat.popup.block.message", "chat.popup.block.primary")
            route = .blockBooking(roomID)
        case .delete:
            content = ("chat.popup.delete.message", "chat.popup.delete.primary")
            route = .deleteBooking(roomID)
        }

        return .action(
            AppPopup.Action(message: language.localizedString(forKey: content.messageKey),
                            primaryTitle: language.localizedString(forKey: content.primaryTitleKey),
                            secondaryTitle: language.localized(.commonCancel), primaryRoute: route)
        )
    }

    static func resultPopup(for action: SwipeAction, succeeded: Bool, language: AppLanguage) -> AppPopup {
        let messageKey: String

        if succeeded {
            switch action {
            case .report:
                messageKey = "chat.popup.report.success"
            case .block:
                messageKey = "chat.popup.block.success"
            case .delete:
                messageKey = "chat.popup.delete.success"
            }
        } else {
            messageKey = "chat.popup.action.failure"
        }

        return .notice(
            AppPopup.Notice(message: language.localizedString(forKey: messageKey), confirmTitle: language.localized(.commonConfirm))
        )
    }
}
