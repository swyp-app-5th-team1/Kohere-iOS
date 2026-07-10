extension ListingDetailModel {
    init(listingDetail: ListingDetail) {
        let roomPricings = listingDetail.roomOffers.compactMap(\.pricing)
        let monthlyRents = roomPricings.compactMap(\.monthlyRent)
        let deposits = roomPricings.compactMap(\.deposit)
        let maintenanceFees = roomPricings.compactMap(\.maintenanceFee)

        id = listingDetail.listingID
        overview = ListingDetailOverviewModel(
            id: listingDetail.listingID,
            title: listingDetail.title,
            typeTag: Self.typeTitle(listingDetail.type),
            imageURLs: listingDetail.imageURLs,
            monthlyRentText: MonthlyRentPriceFormatter.wonTitle(
                min: monthlyRents.min(),
                max: monthlyRents.max()
            ),
            convertedMonthlyRentText: "",
            depositText: Self.rangeTitle(
                prefix: "보증금",
                min: deposits.min(),
                max: deposits.max(),
                fallback: "보증금 정보 없음"
            ),
            maintenanceFeeText: Self.maintenanceFeeTitle(
                min: maintenanceFees.min(),
                max: maintenanceFees.max(),
                conditions: listingDetail.conditions
            ),
            transitText: Self.transitTitle(listingDetail.nearestTransit),
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
        buildingInfo = Self.buildingRows(listingDetail.building)
        facilityInfo = Self.facilityRows(listingDetail.facilities)
        locationInfo = Self.locationInfo(listingDetail)
    }

    private static func roomOfferModel(_ offer: ListingDetailRoomOffer) -> ListingRoomOfferModel {
        ListingRoomOfferModel(
            id: offer.id,
            name: offer.name,
            imageURLs: offer.roomImageURLs,
            pricingText: roomOfferPricingTitle(offer.pricing),
            tags: roomOfferTags(offer)
        )
    }

    private static func roomOfferPricingTitle(_ pricing: ListingDetailRoomPricing?) -> String {
        guard let pricing else { return "가격 정보 없음" }

        let monthlyRentTitle = rangeTitle(
            prefix: "월세",
            min: pricing.monthlyRent,
            max: pricing.monthlyRent,
            fallback: ""
        )
        let depositTitle = rangeTitle(
            prefix: "보증금",
            min: pricing.deposit,
            max: pricing.deposit,
            fallback: ""
        )

        let titles = [monthlyRentTitle, depositTitle].filter { !$0.isEmpty }
        return titles.isEmpty ? "가격 정보 없음" : titles.joined(separator: " · ")
    }

    private static func roomOfferTags(_ offer: ListingDetailRoomOffer) -> [String] {
        let mappedTags = offer.filterTagCodes.compactMap {
            localizedServerCode($0, namespace: .roomOfferFilterTags)
        }
        guard mappedTags.isEmpty else { return mappedTags }

        let conditionTitles = offer.filterTags.map(\.displayTitle)
        guard conditionTitles.isEmpty else { return conditionTitles }

        return offer.filterTagCodes
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
                title: "임대 유형",
                value: rentalTypeTitle(listingDetail.rentalType)
            ),
            ListingDetailInfoRowModel(
                id: "deposit",
                title: "보증금",
                value: rangeValue(min: deposits.min(), max: deposits.max())
            ),
            ListingDetailInfoRowModel(
                id: "monthly-rent",
                title: "월세",
                value: rangeValue(min: monthlyRents.min(), max: monthlyRents.max())
            ),
            ListingDetailInfoRowModel(
                id: "maintenance-fee",
                title: "관리비",
                value: maintenanceFeeValue(
                    min: maintenanceFees.min(),
                    max: maintenanceFees.max(),
                    conditions: listingDetail.conditions
                )
            )
        ]

        if let refundPolicy = listingDetail.refundPolicy {
            rows.append(
                ListingDetailInfoRowModel(
                    id: "refund-policy",
                    title: "환불 규정",
                    value: refundPolicyTitle(refundPolicy)
                )
            )
        }

        return rows
    }

    private static func propertyRows(_ listingDetail: ListingDetail) -> [ListingDetailInfoRowModel] {
        var rows: [ListingDetailInfoRowModel] = []

        if let contractTitle = contractTitle(listingDetail.contract) {
            rows.append(ListingDetailInfoRowModel(id: "stay", title: "이용 기간", value: contractTitle))
        }

        if let genderPolicy = localizedServerCode(listingDetail.genderPolicy, namespace: .listingGenderPolicy) {
            rows.append(ListingDetailInfoRowModel(id: "gender", title: "남녀구분", value: genderPolicy))
        }

        let conditionTitles = listingDetail.conditionCodes.compactMap {
            localizedServerCode($0, namespace: .roomOfferFilterTags)
        }
        if !conditionTitles.isEmpty {
            rows.append(
                ListingDetailInfoRowModel(
                    id: "features",
                    title: "기타사항",
                    value: conditionTitles.joined(separator: ", ")
                )
            )
        }

        if let policies = listingDetail.propertyPolicies {
            rows.append(contentsOf: propertyPolicyRows(policies))
        }

        return rows
    }

    private static func propertyPolicyRows(
        _ policies: ListingDetailPropertyPolicies
    ) -> [ListingDetailInfoRowModel] {
        [
            booleanRow(
                id: "arc-required",
                title: localizedPropertyPolicyTitle("arcRequired"),
                value: policies.arcRequired
            ),
            booleanRow(
                id: "resident-registration",
                title: localizedPropertyPolicyTitle("residentRegistrationAvailable"),
                value: policies.residentRegistrationAvailable
            ),
            booleanRow(
                id: "study-suitable",
                title: localizedPropertyPolicyTitle("studySuitable"),
                value: policies.studySuitable
            ),
            booleanRow(
                id: "meals-provided",
                title: localizedPropertyPolicyTitle("mealsProvided"),
                value: policies.mealsProvided
            ),
            booleanRow(
                id: "english-available",
                title: localizedPropertyPolicyTitle("englishAvailable"),
                value: policies.englishAvailable
            )
        ]
        .compactMap { $0 }
    }

    private static func buildingRows(_ building: ListingDetailBuilding?) -> [ListingDetailInfoRowModel] {
        guard let building else { return [] }

        return [
            optionalRow(
                id: "building-type",
                title: "건물 형태",
                value: localizedServerCode(building.type, namespace: .buildingType)
            ),
            optionalRow(id: "floor", title: "층수", value: floorTitle(building)),
            booleanRow(id: "parking", title: "주차", value: building.parkingAvailable),
            booleanRow(id: "elevator", title: "엘리베이터", value: building.elevatorAvailable)
        ]
        .compactMap { $0 }
    }

    private static func facilityRows(_ facilities: ListingDetailFacilities?) -> [ListingDetailInfoRowModel] {
        guard let facilities else { return [] }

        return [
            listRow(
                id: "heating",
                title: "난방시설",
                values: localizedServerCodes(facilities.heatingSystem, namespace: .facilitiesHeatingSystem)
            ),
            listRow(
                id: "laundry",
                title: "세탁시설",
                values: localizedServerCodes(facilities.laundry, namespace: .facilitiesLaundry)
            ),
            listRow(
                id: "kitchen",
                title: "주방시설",
                values: localizedServerCodes(facilities.kitchen, namespace: .facilitiesKitchen)
            ),
            listRow(
                id: "amenities",
                title: "생활시설",
                values: localizedServerCodes(facilities.livingAmenities, namespace: .facilitiesLivingAmenities)
            ),
            listRow(
                id: "security",
                title: "안전시설",
                values: localizedServerCodes(facilities.securityFeatures, namespace: .facilitiesSecurityFeatures)
            ),
            listRow(
                id: "common-areas",
                title: "공간시설",
                values: commonSpaceTitles(facilities.commonSpaces)
            ),
            listRow(
                id: "supplies",
                title: "제공비품",
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
                    description: transitTitle(transit)
                )
            ]
        } ?? []

        return ListingLocationInfoModel(
            sectionTitle: "위치 및 주변시설",
            addressText: localizedAddressText(listingDetail.address),
            transits: transits,
            coordinate: listingDetail.coordinate,
            nearbyPlacesTitle: "주변 편의시설",
            nearbyPlacesText: listingDetail.nearestTransit?.nearbyPlacesDescription
                ?? "주변 편의시설 정보 없음"
        )
    }

    private static func rangeTitle(prefix: String, min: Int?, max: Int?, fallback: String) -> String {
        let title = MonthlyRentPriceFormatter.rangeTitle(prefix: prefix, min: min, max: max)
        return title.isEmpty ? fallback : title
    }

    private static func rangeValue(min: Int?, max: Int?) -> String {
        MonthlyRentPriceFormatter.wonRangeTitle(min: min, max: max) ?? "정보 없음"
    }

    private static func maintenanceFeeTitle(
        min: Int?,
        max: Int?,
        conditions: [RoomCondition]
    ) -> String {
        "관리비 \(maintenanceFeeValue(min: min, max: max, conditions: conditions))"
    }

    private static func maintenanceFeeValue(
        min: Int?,
        max: Int?,
        conditions: [RoomCondition]
    ) -> String {
        if min == nil, max == nil, conditions.contains(.noMaintenanceFee) {
            return "없음"
        }

        return MonthlyRentPriceFormatter.wonRangeTitle(min: min, max: max) ?? "정보 없음"
    }

    private static func contractTitle(_ contract: ListingDetailContract?) -> String? {
        guard let contract else { return nil }

        switch (contract.minStayMonths, contract.maxStayMonths) {
        case let (min?, max?) where min == max:
            return "\(min)개월"
        case let (min?, max?):
            return "최소 \(min)개월~최대 \(max)개월"
        case let (min?, nil):
            return "최소 \(min)개월"
        case let (nil, max?):
            return "최대 \(max)개월"
        case (nil, nil):
            return nil
        }
    }

    private static func floorTitle(_ building: ListingDetailBuilding) -> String? {
        let usedFloorTitle: String?
        switch (building.usedFloorMin, building.usedFloorMax) {
        case let (min?, max?) where min == max:
            usedFloorTitle = "\(min)층"
        case let (min?, max?):
            usedFloorTitle = "\(min)층~\(max)층"
        case let (min?, nil):
            usedFloorTitle = "\(min)층 이상"
        case let (nil, max?):
            usedFloorTitle = "\(max)층 이하"
        case (nil, nil):
            usedFloorTitle = nil
        }

        guard let usedFloorTitle else {
            return building.totalFloors.map { "전체 \($0)층" }
        }

        if let totalFloors = building.totalFloors {
            return "\(usedFloorTitle) / 전체 \(totalFloors)층"
        }

        return usedFloorTitle
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

    private static func booleanRow(
        id: String,
        title: String,
        value: Bool?
    ) -> ListingDetailInfoRowModel? {
        guard let value else { return nil }
        return ListingDetailInfoRowModel(id: id, title: title, value: value ? "가능" : "불가능")
    }

}
