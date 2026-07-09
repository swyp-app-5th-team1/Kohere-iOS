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
                
                if !item.pricePerMonth.isEmpty {
                    Text(item.pricePerMonth)
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
                infoRow(label: "Applicant", value: item.applicantName)
                infoRow(label: "Move-in Date", value: item.moveInDate)
                infoRow(label: "Lease Term", value: item.leaseTerm)
                infoRow(label: "Deposit", value: item.deposit)
                infoRow(label: "Total Cost", value: item.totalCost)
            }
            
        case .landlord:
            VStack(spacing: 4) {
                infoRow(label: "이름", value: item.applicantName)
                infoRow(label: "성별", value: item.applicantGender)
                infoRow(label: "국적", value: item.applicantNationality)
                emailRow
                infoRow(label: "객실 타입", value: item.roomType)
                infoRow(label: "입주희망일", value: item.moveInDate)
                infoRow(label: "희망입주기간", value: item.leaseTerm)
                infoRow(label: "보증금", value: item.deposit)
                infoRow(label: "총 초기비용", value: item.totalCost)
            }
        }
    }
    
    private var emailRow: some View {
        HStack {
            Text("이메일")
                .kohereTextStyle(.caption1Regular)
                .foregroundColor(.neutral50)
            
            Spacer()
            
            Button {
                copyApplicantEmail()
            } label: {
                HStack(spacing: 4) {
                    Text(item.applicantEmail)
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
            .accessibilityLabel(isEmailCopied ? "이메일 복사됨" : "이메일 복사")
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
