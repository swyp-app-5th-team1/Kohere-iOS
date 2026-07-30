//
//  ListingDetailContentSections.swift
//  Kohere
//

import SwiftUI

struct ListingDetailContentSections: View {
    let detail: ListingDetailModel
    let appLanguage: AppLanguage
    let title: (ListingDetailSection) -> String
    let onMapPreviewTapped: () -> Void
    let sectionWrapper: (ListingDetailSection, AnyView) -> AnyView

    var body: some View {
        Group {
            sectionWrapper(.price, AnyView(
                ListingDetailInfoSection(title: title(.price), rows: detail.priceInfo)
            ))
            sectionWrapper(.property, AnyView(
                ListingDetailPropertySection(
                    title: title(.property),
                    rows: detail.propertyInfo,
                    featuresTitle: appLanguage.localized("listingDetail.field.otherDetails"),
                    features: detail.propertyFeatures
                )
            ))
            sectionWrapper(.building, AnyView(
                ListingDetailInfoSection(title: title(.building), rows: detail.buildingInfo)
            ))
            sectionWrapper(.facility, AnyView(
                ListingDetailInfoSection(title: title(.facility), rows: detail.facilityInfo)
            ))
            sectionWrapper(.location, AnyView(
                ListingDetailLocationSection(
                    locationInfo: detail.locationInfo,
                    onMapPreviewTapped: onMapPreviewTapped
                )
            ))
            sectionWrapper(.review, AnyView(
                ListingDetailReviewSection(
                    title: title(.review),
                    reviewCount: detail.overview.reviewCount,
                    emptyMessage: appLanguage.localized("listingDetail.review.empty"),
                    promptMessage: appLanguage.localized("listingDetail.review.prompt")
                )
            ))
        }
    }
}
