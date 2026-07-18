import Foundation

extension ListingDetailModel {
    init(
        listingDetail: ListingDetail,
        exchangeRate: KRWToUSDExchangeRate?,
        convertMonthlyRentCurrencyUseCase: ConvertMonthlyRentCurrencyUseCase
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
            typeTag: Self.localizedServerCode(listingDetail.type, namespace: .listingType)
                ?? listingDetail.type,
            imageURLs: listingDetail.imageURLs,
            monthlyRentText: ListingDetailValueFormatter.monthlyRentTitle(
                min: monthlyRents.min(),
                max: monthlyRents.max()
            ),
            convertedMonthlyRentText: MonthlyRentPriceFormatter.usdTitle(
                min: convertedMonthlyRents.min(),
                max: convertedMonthlyRents.max()
            ),
            depositText: ListingDetailValueFormatter.overviewDepositTitle(
                min: deposits.min(),
                max: deposits.max()
            ),
            maintenanceFeeText: ListingDetailValueFormatter.overviewMaintenanceFeeTitle(
                min: maintenanceFees.min(),
                max: maintenanceFees.max()
            ),
            transitText: ListingDetailValueFormatter.transitTitle(listingDetail.nearestTransit),
            imageCountText: Self.imageCountTitle(listingDetail.imageURLs.count),
            reviewCount: 0,
            isLiked: listingDetail.isFavorited,
            favoriteCount: listingDetail.favoriteCount
        )
        tabs = Self.tabs
        roomOffers = listingDetail.roomOffers.map { Self.roomOfferModel($0) }
        priceInfo = Self.priceRows(
            listingDetail: listingDetail,
            monthlyRents: monthlyRents,
            deposits: deposits,
            maintenanceFees: maintenanceFees
        )
        propertyInfo = Self.propertyRows(listingDetail)
        propertyFeatures = Self.propertyFeatures(listingDetail.conditions)
        buildingInfo = Self.buildingRows(listingDetail.building)
        facilityInfo = Self.facilityRows(listingDetail.facilities)
        locationInfo = Self.locationInfo(listingDetail)
    }

    private static func roomOfferModel(_ offer: ListingDetailRoomOffer) -> ListingRoomOfferModel {
        ListingRoomOfferModel(
            id: offer.id,
            name: offer.name,
            imageURLs: offer.roomImageURLs,
            pricingText: ListingDetailValueFormatter.roomOfferPricingTitle(offer.pricing),
            tags: roomOfferTags(offer)
        )
    }

    private static func roomOfferTags(_ offer: ListingDetailRoomOffer) -> [String] {
        localizedServerCodes(offer.filterTags, namespace: .roomOfferFilterTags)
    }

    private static func priceRows(
        listingDetail: ListingDetail,
        monthlyRents: [Int],
        deposits: [Int],
        maintenanceFees: [Int]
    ) -> [ListingDetailInfoRowModel] {
        var rows: [ListingDetailInfoRowModel] = [
            ListingDetailInfoRowModel(
                id: "rental-type",
                title: String(localized: "listingDetail.field.rentType"),
                value: localizedServerCode(listingDetail.rentalType, namespace: .listingRentalType)
                    ?? String(localized: "listingDetail.value.noRentalTypeInfo")
            ),
            ListingDetailInfoRowModel(
                id: "deposit",
                title: String(localized: "listingDetail.field.deposit"),
                value: ListingDetailValueFormatter.priceRowValue(min: deposits.min(), max: deposits.max())
            ),
            ListingDetailInfoRowModel(
                id: "monthly-rent",
                title: String(localized: "listingDetail.field.monthlyRent"),
                value: ListingDetailValueFormatter.priceRowValue(min: monthlyRents.min(), max: monthlyRents.max())
            ),
            ListingDetailInfoRowModel(
                id: "maintenance-fee",
                title: String(localized: "listingDetail.field.maintenanceFee"),
                value: ListingDetailValueFormatter.maintenanceFeeRowValue(
                    min: maintenanceFees.min(),
                    max: maintenanceFees.max()
                )
            )
        ]

        if let refundPolicy = listingDetail.refundPolicy {
            rows.append(
                ListingDetailInfoRowModel(
                    id: "refund-policy",
                    title: String(localized: "listingDetail.field.refundPolicy"),
                    value: refundPolicyTitle(refundPolicy)
                )
            )
        }

        return rows
    }

    private static func propertyRows(_ listingDetail: ListingDetail) -> [ListingDetailInfoRowModel] {
        var rows: [ListingDetailInfoRowModel] = []

        if let contractTitle = ListingDetailValueFormatter.stayTitle(listingDetail.contract) {
            rows.append(ListingDetailInfoRowModel(id: "stay", title: String(localized: "listingDetail.field.usagePeriod"), value: contractTitle))
        }

        if let genderPolicy = localizedServerCode(
            listingDetail.genderPolicy,
            namespace: .listingGenderPolicy
        ) {
            rows.append(ListingDetailInfoRowModel(id: "gender", title: String(localized: "listingDetail.field.genderPolicy"), value: genderPolicy))
        }

        return rows
    }

    private static func propertyFeatures(_ conditionCodes: [String]) -> [String] {
        localizedServerCodes(conditionCodes, namespace: .roomOfferFilterTags)
    }

    private static func buildingRows(_ building: ListingDetailBuilding?) -> [ListingDetailInfoRowModel] {
        guard let building else { return [] }

        return [
            optionalRow(
                id: "building-type",
                title: String(localized: "listingDetail.field.buildingType"),
                value: localizedServerCode(building.type, namespace: .buildingType)
            ),
            optionalRow(id: "floor", title: String(localized: "listingDetail.field.floor"), value: ListingDetailValueFormatter.floorTitle(building)),
            optionalRow(
                id: "parking",
                title: String(localized: "listingDetail.field.parking"),
                value: ListingDetailValueFormatter.availabilityTitle(
                    building.parkingAvailable,
                    availableKey: "listingDetail.value.parkingAvailable",
                    unavailableKey: "listingDetail.value.noParking"
                )
            ),
            optionalRow(
                id: "elevator",
                title: String(localized: "listingDetail.field.elevator"),
                value: ListingDetailValueFormatter.availabilityTitle(
                    building.elevatorAvailable,
                    availableKey: "listingDetail.value.elevatorAvailable",
                    unavailableKey: "listingDetail.value.noElevator"
                )
            )
        ]
        .compactMap { $0 }
    }

    private static func facilityRows(_ facilities: ListingDetailFacilities?) -> [ListingDetailInfoRowModel] {
        guard let facilities else { return [] }

        return [
            listRow(
                id: "heating",
                title: String(localized: "listingDetail.field.heatingFacility"),
                values: localizedServerCodes(facilities.heatingSystem, namespace: .facilitiesHeatingSystem)
            ),
            listRow(
                id: "laundry",
                title: String(localized: "listingDetail.field.laundryFacility"),
                values: localizedServerCodes(facilities.laundry, namespace: .facilitiesLaundry)
            ),
            listRow(
                id: "kitchen",
                title: String(localized: "listingDetail.field.kitchenFacility"),
                values: localizedServerCodes(facilities.kitchen, namespace: .facilitiesKitchen)
            ),
            listRow(
                id: "amenities",
                title: String(localized: "listingDetail.field.livingFacility"),
                values: localizedServerCodes(facilities.livingAmenities, namespace: .facilitiesLivingAmenities)
            ),
            listRow(
                id: "security",
                title: String(localized: "listingDetail.field.safetyFacility"),
                values: localizedServerCodes(facilities.securityFeatures, namespace: .facilitiesSecurityFeatures)
            ),
            listRow(
                id: "common-areas",
                title: String(localized: "listingDetail.field.spaceFacility"),
                values: commonSpaceTitles(facilities.commonSpaces)
            ),
            listRow(
                id: "supplies",
                title: String(localized: "listingDetail.field.providedSupplies"),
                values: localizedServerCodes(facilities.providedSupplies, namespace: .facilitiesProvidedSupplies)
            )
        ]
        .compactMap { $0 }
    }

    private static func locationInfo(_ listingDetail: ListingDetail) -> ListingLocationInfoModel {
        let transits = listingDetail.nearestTransit.map { transit in
            [
                ListingTransitInfoModel(
                    id: transit.name,
                    lineText: transitLineText(transit),
                    lineColorName: "green60",
                    description: ListingDetailValueFormatter.transitTitle(transit, includesFrom: true)
                )
            ]
        } ?? []

        return ListingLocationInfoModel(
            sectionTitle: String(localized: "listingDetail.section.locationAndNearby"),
            addressText: localizedAddressText(listingDetail.address),
            transits: transits,
            coordinate: listingDetail.coordinate,
            nearbyPlacesTitle: String(localized: "listingDetail.field.nearbyAmenities"),
            nearbyPlacesText: listingDetail.nearestTransit?.nearbyPlacesDescription
                ?? String(localized: "listingDetail.value.noNearbyAmenities")
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
