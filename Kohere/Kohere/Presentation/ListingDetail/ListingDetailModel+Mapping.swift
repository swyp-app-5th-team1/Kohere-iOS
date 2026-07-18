import Foundation

extension ListingDetailModel {
    init(
        listingDetail: ListingDetail,
        exchangeRate: KRWToUSDExchangeRate?,
        convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase,
        language: AppLanguage
    ) {
        let roomPricings = listingDetail.roomOffers.compactMap(\.pricing)
        let monthlyRents = roomPricings.compactMap(\.monthlyRent)
        let deposits = roomPricings.compactMap(\.deposit)
        let maintenanceFees = roomPricings.compactMap(\.maintenanceFee)
        let convertedMonthlyRents = exchangeRate.map { exchangeRate in
            monthlyRents.map {
                convertMonthlyRentCurrencyUseCase.execute($0, exchangeRate)
            }
        } ?? []

        id = listingDetail.listingID
        overview = ListingDetailOverviewModel(
            id: listingDetail.listingID,
            title: listingDetail.title,
            typeTag: Self.localizedServerCode(
                listingDetail.type,
                namespace: .listingType,
                language: language
            )
                ?? listingDetail.type,
            imageURLs: listingDetail.imageURLs,
            monthlyRentText: ListingDetailValueFormatter.monthlyRentTitle(
                min: monthlyRents.min(),
                max: monthlyRents.max(),
                language: language
            ),
            convertedMonthlyRentText: MonthlyRentPriceFormatter.usdTitle(
                min: convertedMonthlyRents.min(),
                max: convertedMonthlyRents.max()
            ),
            depositText: ListingDetailValueFormatter.overviewDepositTitle(
                min: deposits.min(),
                max: deposits.max(),
                language: language
            ),
            maintenanceFeeText: ListingDetailValueFormatter.overviewMaintenanceFeeTitle(
                min: maintenanceFees.min(),
                max: maintenanceFees.max(),
                language: language
            ),
            transitText: ListingDetailValueFormatter.transitTitle(
                listingDetail.nearestTransit,
                language: language
            ),
            imageCountText: Self.imageCountTitle(listingDetail.imageURLs.count),
            reviewCount: 0,
            isLiked: listingDetail.isFavorited,
            favoriteCount: listingDetail.favoriteCount
        )
        tabs = Self.tabs(language: language)
        roomOffers = listingDetail.roomOffers.map { Self.roomOfferModel($0, language: language) }
        priceInfo = Self.priceRows(
            listingDetail: listingDetail,
            monthlyRents: monthlyRents,
            deposits: deposits,
            maintenanceFees: maintenanceFees,
            language: language
        )
        propertyInfo = Self.propertyRows(listingDetail, language: language)
        propertyFeatures = Self.propertyFeatures(listingDetail.conditions, language: language)
        buildingInfo = Self.buildingRows(listingDetail.building, language: language)
        facilityInfo = Self.facilityRows(listingDetail.facilities, language: language)
        locationInfo = Self.locationInfo(listingDetail, language: language)
    }

    private static func roomOfferModel(
        _ offer: ListingDetailRoomOffer,
        language: AppLanguage
    ) -> ListingRoomOfferModel {
        ListingRoomOfferModel(
            id: offer.id,
            name: offer.name,
            imageURLs: offer.roomImageURLs,
            pricingText: ListingDetailValueFormatter.roomOfferPricingTitle(
                offer.pricing,
                language: language
            ),
            tags: roomOfferTags(offer, language: language)
        )
    }

    private static func roomOfferTags(
        _ offer: ListingDetailRoomOffer,
        language: AppLanguage
    ) -> [String] {
        localizedServerCodes(
            offer.filterTags,
            namespace: .roomOfferFilterTags,
            language: language
        )
    }

    private static func priceRows(
        listingDetail: ListingDetail,
        monthlyRents: [Int],
        deposits: [Int],
        maintenanceFees: [Int],
        language: AppLanguage
    ) -> [ListingDetailInfoRowModel] {
        var rows: [ListingDetailInfoRowModel] = [
            ListingDetailInfoRowModel(
                id: "rental-type",
                title: language.localized("listingDetail.field.rentType"),
                value: localizedServerCode(
                    listingDetail.rentalType,
                    namespace: .listingRentalType,
                    language: language
                ) ?? language.localized("listingDetail.value.noRentalTypeInfo")
            ),
            ListingDetailInfoRowModel(
                id: "deposit",
                title: language.localized("listingDetail.field.deposit"),
                value: ListingDetailValueFormatter.priceRowValue(
                    min: deposits.min(),
                    max: deposits.max(),
                    language: language
                )
            ),
            ListingDetailInfoRowModel(
                id: "monthly-rent",
                title: language.localized("listingDetail.field.monthlyRent"),
                value: ListingDetailValueFormatter.priceRowValue(
                    min: monthlyRents.min(),
                    max: monthlyRents.max(),
                    language: language
                )
            ),
            ListingDetailInfoRowModel(
                id: "maintenance-fee",
                title: language.localized("listingDetail.field.maintenanceFee"),
                value: ListingDetailValueFormatter.maintenanceFeeRowValue(
                    min: maintenanceFees.min(),
                    max: maintenanceFees.max(),
                    language: language
                )
            )
        ]

        if let refundPolicy = listingDetail.refundPolicy {
            rows.append(
                ListingDetailInfoRowModel(
                    id: "refund-policy",
                    title: language.localized("listingDetail.field.refundPolicy"),
                    value: refundPolicyTitle(refundPolicy, language: language)
                )
            )
        }

        return rows
    }

    private static func propertyRows(
        _ listingDetail: ListingDetail,
        language: AppLanguage
    ) -> [ListingDetailInfoRowModel] {
        var rows: [ListingDetailInfoRowModel] = []

        if let contractTitle = ListingDetailValueFormatter.stayTitle(
            listingDetail.contract,
            language: language
        ) {
            rows.append(
                ListingDetailInfoRowModel(
                    id: "stay",
                    title: language.localized("listingDetail.field.usagePeriod"),
                    value: contractTitle
                )
            )
        }

        if let genderPolicy = localizedServerCode(
            listingDetail.genderPolicy,
            namespace: .listingGenderPolicy,
            language: language
        ) {
            rows.append(
                ListingDetailInfoRowModel(
                    id: "gender",
                    title: language.localized("listingDetail.field.genderPolicy"),
                    value: genderPolicy
                )
            )
        }

        return rows
    }

    private static func propertyFeatures(
        _ conditionCodes: [String],
        language: AppLanguage
    ) -> [String] {
        localizedServerCodes(
            conditionCodes,
            namespace: .roomOfferFilterTags,
            language: language
        )
    }

    private static func buildingRows(
        _ building: ListingDetailBuilding?,
        language: AppLanguage
    ) -> [ListingDetailInfoRowModel] {
        guard let building else { return [] }

        return [
            optionalRow(
                id: "building-type",
                title: language.localized("listingDetail.field.buildingType"),
                value: localizedServerCode(
                    building.type,
                    namespace: .buildingType,
                    language: language
                )
            ),
            optionalRow(
                id: "floor",
                title: language.localized("listingDetail.field.floor"),
                value: ListingDetailValueFormatter.floorTitle(building, language: language)
            ),
            optionalRow(
                id: "parking",
                title: language.localized("listingDetail.field.parking"),
                value: ListingDetailValueFormatter.availabilityTitle(
                    building.parkingAvailable,
                    availableKey: "listingDetail.value.parkingAvailable",
                    unavailableKey: "listingDetail.value.noParking",
                    language: language
                )
            ),
            optionalRow(
                id: "elevator",
                title: language.localized("listingDetail.field.elevator"),
                value: ListingDetailValueFormatter.availabilityTitle(
                    building.elevatorAvailable,
                    availableKey: "listingDetail.value.elevatorAvailable",
                    unavailableKey: "listingDetail.value.noElevator",
                    language: language
                )
            )
        ]
        .compactMap { $0 }
    }

    private static func facilityRows(
        _ facilities: ListingDetailFacilities?,
        language: AppLanguage
    ) -> [ListingDetailInfoRowModel] {
        guard let facilities else { return [] }

        return [
            listRow(
                id: "heating",
                title: language.localized("listingDetail.field.heatingFacility"),
                values: localizedServerCodes(
                    facilities.heatingSystem,
                    namespace: .facilitiesHeatingSystem,
                    language: language
                )
            ),
            listRow(
                id: "laundry",
                title: language.localized("listingDetail.field.laundryFacility"),
                values: localizedServerCodes(
                    facilities.laundry,
                    namespace: .facilitiesLaundry,
                    language: language
                )
            ),
            listRow(
                id: "kitchen",
                title: language.localized("listingDetail.field.kitchenFacility"),
                values: localizedServerCodes(
                    facilities.kitchen,
                    namespace: .facilitiesKitchen,
                    language: language
                )
            ),
            listRow(
                id: "amenities",
                title: language.localized("listingDetail.field.livingFacility"),
                values: localizedServerCodes(
                    facilities.livingAmenities,
                    namespace: .facilitiesLivingAmenities,
                    language: language
                )
            ),
            listRow(
                id: "security",
                title: language.localized("listingDetail.field.safetyFacility"),
                values: localizedServerCodes(
                    facilities.securityFeatures,
                    namespace: .facilitiesSecurityFeatures,
                    language: language
                )
            ),
            listRow(
                id: "common-areas",
                title: language.localized("listingDetail.field.spaceFacility"),
                values: commonSpaceTitles(facilities.commonSpaces, language: language)
            ),
            listRow(
                id: "supplies",
                title: language.localized("listingDetail.field.providedSupplies"),
                values: localizedServerCodes(
                    facilities.providedSupplies,
                    namespace: .facilitiesProvidedSupplies,
                    language: language
                )
            )
        ]
        .compactMap { $0 }
    }

    private static func locationInfo(
        _ listingDetail: ListingDetail,
        language: AppLanguage
    ) -> ListingLocationInfoModel {
        let transits = listingDetail.nearestTransit.map { transit in
            [
                ListingTransitInfoModel(
                    id: transit.name,
                    lineText: transitLineText(transit),
                    lineColorName: "green60",
                    description: ListingDetailValueFormatter.transitTitle(
                        transit,
                        includesFrom: true,
                        language: language
                    )
                )
            ]
        } ?? []

        return ListingLocationInfoModel(
            sectionTitle: language.localized("listingDetail.section.locationAndNearby"),
            addressText: localizedAddressText(listingDetail.address, language: language),
            transits: transits,
            coordinate: listingDetail.coordinate,
            nearbyPlacesTitle: language.localized("listingDetail.field.nearbyAmenities"),
            nearbyPlacesText: listingDetail.nearestTransit?.nearbyPlacesDescription
                ?? language.localized("listingDetail.value.noNearbyAmenities")
        )
    }

    private static func transitLineText(_ transit: ListingDetailNearestTransit) -> String {
        guard let type = transit.type, !type.isEmpty else { return "T" }
        return String(type.prefix(1))
    }

    private static func imageCountTitle(_ count: Int) -> String {
        count == 0 ? "0/0" : "1/\(count)"
    }

    private static func optionalRow(
        id: String,
        title: String,
        value: String?
    ) -> ListingDetailInfoRowModel? {
        guard let value, !value.isEmpty else { return nil }
        return ListingDetailInfoRowModel(id: id, title: title, value: value)
    }

    private static func listRow(
        id: String,
        title: String,
        values: [String]
    ) -> ListingDetailInfoRowModel? {
        guard !values.isEmpty else { return nil }
        return ListingDetailInfoRowModel(id: id, title: title, value: values.joined(separator: ", "))
    }

}
