//
//  MoveInApplicationCardView.swift
//  Kohere
//
//  Created by mandoo on 6/29/26.
//

import SwiftUI

struct MoveInApplicationCardView: View {
    
    // MARK: - Properties
    
    let item: ChatRoomModel
    let onViewDetailsTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(.roomPlaceholder)
                .resizable()
                .frame(width: 270, height: 173)
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
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.listingName)
                    .kohereTextStyle(.label2Medium)
                    .foregroundColor(.neutral70)
                    .padding(.bottom, 4)
                
                Text(item.location)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.coolNeutral30)
                
                Text(item.pricePerMonth)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.coolNeutral30)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.coolNeutral7)
            
            VStack(spacing: 4) {
                infoRow(label: "Applicant", value: item.applicantName)
                infoRow(label: "Move-in Date", value: item.moveInDate)
                infoRow(label: "Lease Term", value: item.leaseTerm)
                infoRow(label: "Deposit", value: item.deposit)
                infoRow(label: "Total Cost", value: item.totalCost)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, 8)
            
            VStack {
                Button(action: onViewDetailsTapped) {
                    Text("View Details")
                        .kohereTextStyle(.label1Semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.statusInfo)
                }
            }
            .padding(.vertical, 14)
            .background(Color.statusBlue5)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 0,
                        bottomLeading: 20,
                        bottomTrailing: 20,
                        topTrailing: 0
                    )
                )
            )
        }
        .frame(width: 270)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.coolNeutral8, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
    }
    
    // MARK: - SubView
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .kohereTextStyle(.caption1Regular)
                .foregroundColor(.neutral50)
            
            Spacer()
            
            Text(value)
                .kohereTextStyle(.label3Medium)
                .foregroundColor(.coolNeutral77)
        }
        .frame(height: 24)
    }
}
