//
//  MoveInApplicationCardView.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import SwiftUI
import UIKit

enum MoveInApplicationCardMode {
    case tenant
    case landlord
}

struct MoveInApplicationCardView: View {
    
    // MARK: - Properties
    
    let item: ChatRoomModel
    var mode: MoveInApplicationCardMode = .tenant

    @Environment(\.locale)
    private var locale
    @State private var isEmailCopied = false
    @State private var emailCopyResetTask: Task<Void, Never>?
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailImage
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.listingName)
                    .kohereTextStyle(.label2Medium)
                    .foregroundColor(.neutral80)
                    .padding(.bottom, 4)
                
                Text(item.location)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.labelAlternative)
                
                if !cardFormatter.pricePerMonth.isEmpty {
                    Text(cardFormatter.pricePerMonth)
                        .kohereTextStyle(.caption1Regular)
                        .foregroundColor(.labelAlternative)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.coolNeutral7)
            
            cardInfo
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .frame(width: 255)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.coolNeutral8, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
        .onDisappear {
            cancelEmailCopyFeedback()
        }
    }
    
    // MARK: - SubView
    
    private var thumbnailImage: some View {
        KohereRemoteImageView(urlString: item.thumbnailURL) {
            placeholderImage
        }
        .frame(width: 255, height: 173)
        .clipped()
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: 20,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 20
                )
            )
        )
    }
    
    private var placeholderImage: some View {
        Image(.roomPlaceholder)
            .resizable()
            .scaledToFill()
    }
    
    @ViewBuilder private var cardInfo: some View {
        switch mode {
        case .tenant:
            VStack(spacing: 4) {
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.applicant"),
                    value: cardFormatter.applicantName
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.moveInDate"),
                    value: cardFormatter.moveInDate
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.leaseTerm"),
                    value: cardFormatter.leaseTerm
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.deposit"),
                    value: cardFormatter.deposit
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.totalCost"),
                    value: cardFormatter.totalCost
                )
            }
            
        case .landlord:
            VStack(spacing: 4) {
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.applicant"),
                    value: cardFormatter.applicantName
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.gender"),
                    value: cardFormatter.applicantGender
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.nationality"),
                    value: cardFormatter.applicantNationality
                )
                emailRow
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.roomType"),
                    value: cardFormatter.roomType
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.moveInDate"),
                    value: cardFormatter.moveInDate
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.leaseTerm"),
                    value: cardFormatter.leaseTerm
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.deposit"),
                    value: cardFormatter.deposit
                )
                infoRow(
                    label: cardFormatter.localized("chat.applicationCard.field.totalCost"),
                    value: cardFormatter.totalCost
                )
            }
        }
    }
    
    private var emailRow: some View {
        HStack {
            Text(cardFormatter.localized("chat.applicationCard.field.email"))
                .kohereTextStyle(.caption1Regular)
                .foregroundColor(.neutral50)
            
            Spacer()
            
            Button {
                copyApplicantEmail()
            } label: {
                HStack(spacing: 4) {
                    Text(cardFormatter.applicantEmail)
                        .kohereTextStyle(.label3Medium)
                        .foregroundColor(.statusInfo)

                    Image(isEmailCopied ? .check24 : .copy24)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.statusInfo)
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                cardFormatter.localized(
                    isEmailCopied
                        ? "chat.applicationCard.accessibility.emailCopied"
                        : "chat.applicationCard.accessibility.copyEmail"
                )
            )
            .accessibilityValue(item.applicantEmail)
        }
        .frame(height: 24)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .kohereTextStyle(.caption1Regular)
                .foregroundColor(.neutral50)
            
            Spacer()
            
            Text(value)
                .kohereTextStyle(.label3Medium)
                .foregroundColor(.neutral70)
        }
        .frame(height: 24)
    }

    private var cardFormatter: ChatApplicationCardFormatter {
        ChatApplicationCardFormatter(
            item: item,
            language: cardLanguage
        )
    }

    private var cardLanguage: AppLanguage {
        switch mode {
        case .landlord:
            return .korean
        case .tenant:
            return locale.language.languageCode?.identifier == AppLanguage.korean.rawValue
                ? .korean
                : .english
        }
    }

    private func copyApplicantEmail() {
        let email = item.applicantEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, email != "N/A" else { return }

        UIPasteboard.general.string = email
        showEmailCopyFeedback()
    }

    private func showEmailCopyFeedback() {
        isEmailCopied = true
        emailCopyResetTask?.cancel()
        emailCopyResetTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                isEmailCopied = false
                emailCopyResetTask = nil
            }
        }
    }

    private func cancelEmailCopyFeedback() {
        emailCopyResetTask?.cancel()
        emailCopyResetTask = nil
    }
}
