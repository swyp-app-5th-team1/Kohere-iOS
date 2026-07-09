import Foundation

extension ListingDetailModel {
    enum ServerCodeNamespace: String {
        case listingType = "listing.type"
        case listingStatus = "listing.status"
        case listingRentalType = "listing.rentalType"
        case listingGenderPolicy = "listing.genderPolicy"
        case addressCity = "address.city"
        case addressDistrict = "address.district"
        case addressFullAddressTerms = "address.fullAddressTerms"
        case buildingType = "building.type"
        case facilitiesLaundry = "facilities.laundry"
        case facilitiesKitchen = "facilities.kitchen"
        case facilitiesLivingAmenities = "facilities.livingAmenities"
        case facilitiesSecurityFeatures = "facilities.securityFeatures"
        case facilitiesCommonSpaces = "facilities.commonSpaces"
        case facilitiesProvidedSupplies = "facilities.providedSupplies"
        case facilitiesHeatingSystem = "facilities.heatingSystem"
        case nearbyUniversityCodes
        case nearestTransitType = "nearestTransit.type"
        case nearestTransitName = "nearestTransit.name"
        case roomOfferStatus = "roomOffer.status"
        case roomOfferCurrency = "roomOffer.currency"
        case roomOfferFilterTags = "roomOffer.filterTags"
        case refundPolicyCode = "refundPolicy.code"
        case propertyPolicies
    }

    private struct ServerCodeLocalization {
        let key: String
        let fallback: String
    }

    private struct AddressTermLocalization {
        let source: String
        let key: String
        let fallback: String
    }

    static func refundPolicyTitle(_ refundPolicy: ListingDetailRefundPolicy) -> String {
        if let description = refundPolicy.description,
           let localizedDescription = localizedServerCode(description, namespace: .refundPolicyCode) {
            return localizedDescription
        }

        if let codeTitle = localizedServerCode(refundPolicy.code, namespace: .refundPolicyCode) {
            return codeTitle
        }

        if let description = refundPolicy.description, !description.isEmpty {
            return description
        }

        return refundPolicy.code
    }

    static func localizedPropertyPolicyTitle(_ code: String) -> String {
        localizedServerCode(code, namespace: .propertyPolicies) ?? code
    }

    static func typeTitle(_ type: String) -> String {
        localizedServerCode(type, namespace: .listingType) ?? (type.isEmpty ? "매물" : type)
    }

    static func rentalTypeTitle(_ rentalType: String) -> String {
        localizedServerCode(rentalType, namespace: .listingRentalType)
            ?? (rentalType.isEmpty ? "임대 유형 정보 없음" : rentalType)
    }

    static func transitTitle(_ transit: ListingDetailNearestTransit?) -> String {
        guard let transit else { return "교통 정보 없음" }
        return transitTitle(transit)
    }

    static func transitTitle(_ transit: ListingDetailNearestTransit) -> String {
        let name = localizedServerCode(transit.name, namespace: .nearestTransitName) ?? transit.name

        if let walkMinutes = transit.walkMinutes {
            return "\(name) 도보 \(walkMinutes)분"
        }

        return name
    }

    static func commonSpaceTitles(_ commonSpaces: [ListingDetailCommonSpace]) -> [String] {
        commonSpaces.map { commonSpace in
            let typeTitle = localizedServerCode(commonSpace.type, namespace: .facilitiesCommonSpaces)
                ?? commonSpace.type

            if let count = commonSpace.count {
                return "\(typeTitle) \(count)개"
            }

            return typeTitle
        }
    }

    static func localizedAddressText(_ address: ListingDetailAddress?) -> String {
        guard let address else { return "주소 정보 없음" }

        let fullAddress = localizedFullAddress(address.fullAddress)
        let detail = address.detail?.trimmingCharacters(in: .whitespacesAndNewlines)

        let addressParts = [fullAddress, detail]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        if !addressParts.isEmpty {
            return addressParts.joined(separator: " ")
        }

        let locationParts = [
            localizedServerCode(address.city, namespace: .addressCity),
            localizedServerCode(address.district, namespace: .addressDistrict),
            detail
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        return locationParts.isEmpty ? "주소 정보 없음" : locationParts.joined(separator: " ")
    }

    static func localizedFullAddress(_ fullAddress: String?) -> String? {
        guard let fullAddress = fullAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
              !fullAddress.isEmpty else {
            return nil
        }

        return addressTermLocalizations.reduce(fullAddress) { localizedAddress, localization in
            localizedAddress.replacingOccurrences(
                of: localization.source,
                with: localized(localization.key, fallback: localization.fallback)
            )
        }
    }

    static func localizedServerCodes(
        _ codes: [String],
        namespace: ServerCodeNamespace
    ) -> [String] {
        codes.map { localizedServerCode($0, namespace: namespace) ?? $0 }
    }

    static func localizedServerCode(
        _ code: String?,
        namespace: ServerCodeNamespace
    ) -> String? {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines),
              !code.isEmpty else {
            return nil
        }

        let lookupKey = serverCodeLookupKey(code, namespace: namespace)
        guard let localization = serverCodeLocalizations[lookupKey] else {
            return nil
        }

        return localized(localization.key, fallback: localization.fallback)
    }

    static func localized(_ key: String, fallback: String) -> String {
        let value = Bundle.main.localizedString(forKey: key, value: fallback, table: nil)
        return value == key ? fallback : value
    }

    static func serverCodeLookupKey(
        _ code: String,
        namespace: ServerCodeNamespace
    ) -> String {
        switch namespace {
        case .addressFullAddressTerms, .nearestTransitName:
            return "\(namespace.rawValue).\(code)"
        case .propertyPolicies:
            return "\(namespace.rawValue).\(code)"
        default:
            return "\(namespace.rawValue).\(canonicalServerCode(code, namespace: namespace))"
        }
    }

    static func canonicalServerCode(
        _ code: String,
        namespace: ServerCodeNamespace
    ) -> String {
        let normalizedCode = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch namespace {
        case .listingType:
            switch normalizedCode {
            case "GOSHIWON":
                return "GOSIWON"
            case "COLIVING":
                return "CO_LIVING"
            case "SHAREHOUSE":
                return "SHARE_HOUSE"
            default:
                return normalizedCode
            }
        default:
            return normalizedCode
        }
    }

    private static let addressTermLocalizations: [AddressTermLocalization] = [
        .init(source: "Dongdaemun-gu", key: "address.fullAddressTerms.Dongdaemun-gu", fallback: "동대문구"),
        .init(source: "Gwangjin-gu", key: "address.fullAddressTerms.Gwangjin-gu", fallback: "광진구"),
        .init(source: "Hoegi-dong", key: "address.fullAddressTerms.Hoegi-dong", fallback: "회기동"),
        .init(source: "Hwayang-dong", key: "address.fullAddressTerms.Hwayang-dong", fallback: "화양동"),
        .init(source: "Hyehwa-dong", key: "address.fullAddressTerms.Hyehwa-dong", fallback: "혜화동"),
        .init(source: "Jongno-gu", key: "address.fullAddressTerms.Jongno-gu", fallback: "종로구"),
        .init(source: "Gwanak-gu", key: "address.fullAddressTerms.Gwanak-gu", fallback: "관악구"),
        .init(source: "Sillim-dong", key: "address.fullAddressTerms.Sillim-dong", fallback: "신림동")
    ]

    private static let serverCodeLocalizations: [String: ServerCodeLocalization] = [
        "listing.type.GOSIWON": .init(key: "listing.type.GOSIWON", fallback: "고시원"),
        "listing.type.CO_LIVING": .init(key: "listing.type.CO_LIVING", fallback: "코리빙"),
        "listing.type.SHARE_HOUSE": .init(key: "listing.type.SHARE_HOUSE", fallback: "쉐어하우스"),
        "listing.status.PUBLISHED": .init(key: "listing.status.PUBLISHED", fallback: "공개 중"),
        "listing.rentalType.MONTHLY_RENT": .init(key: "listing.rentalType.MONTHLY_RENT", fallback: "월세"),
        "listing.genderPolicy.ANY": .init(key: "listing.genderPolicy.ANY", fallback: "혼성"),
        "listing.genderPolicy.FEMALE_ONLY": .init(key: "listing.genderPolicy.FEMALE_ONLY", fallback: "여성 전용"),
        "listing.genderPolicy.MALE_ONLY": .init(key: "listing.genderPolicy.MALE_ONLY", fallback: "남성 전용"),
        "listing.genderPolicy.GENDER_SEPARATED": .init(key: "listing.genderPolicy.GENDER_SEPARATED", fallback: "남녀분리"),
        "address.city.SEOUL": .init(key: "address.city.SEOUL", fallback: "서울"),
        "address.district.DONGDAEMUN_GU": .init(key: "address.district.DONGDAEMUN_GU", fallback: "동대문구"),
        "address.district.GWANAK_GU": .init(key: "address.district.GWANAK_GU", fallback: "관악구"),
        "address.district.GWANGJIN_GU": .init(key: "address.district.GWANGJIN_GU", fallback: "광진구"),
        "address.district.JONGNO_GU": .init(key: "address.district.JONGNO_GU", fallback: "종로구"),
        "building.type.OFFICETEL": .init(key: "building.type.OFFICETEL", fallback: "오피스텔"),
        "building.type.VILLA": .init(key: "building.type.VILLA", fallback: "빌라"),
        "building.type.OTHER": .init(key: "building.type.OTHER", fallback: "상가주택"),
        "facilities.laundry.COIN_LAUNDRY": .init(key: "facilities.laundry.COIN_LAUNDRY", fallback: "코인세탁"),
        "facilities.laundry.DRYER": .init(key: "facilities.laundry.DRYER", fallback: "건조기"),
        "facilities.laundry.PRIVATE_WASHER": .init(key: "facilities.laundry.PRIVATE_WASHER", fallback: "개인세탁기 구비"),
        "facilities.laundry.SHARED_WASHER": .init(key: "facilities.laundry.SHARED_WASHER", fallback: "공용세탁기"),
        "facilities.kitchen.GAS_STOVE": .init(key: "facilities.kitchen.GAS_STOVE", fallback: "가스레인지"),
        "facilities.kitchen.MICROWAVE": .init(key: "facilities.kitchen.MICROWAVE", fallback: "전자레인지"),
        "facilities.kitchen.SHARED_KITCHEN_FULL_OPTION": .init(key: "facilities.kitchen.SHARED_KITCHEN_FULL_OPTION", fallback: "공용주방 풀옵션"),
        "facilities.kitchen.SHARED_REFRIGERATOR": .init(key: "facilities.kitchen.SHARED_REFRIGERATOR", fallback: "공용냉장고"),
        "facilities.livingAmenities.AIR_CONDITIONER": .init(key: "facilities.livingAmenities.AIR_CONDITIONER", fallback: "에어컨"),
        "facilities.livingAmenities.GAS_STOVE": .init(key: "facilities.livingAmenities.GAS_STOVE", fallback: "가스레인지"),
        "facilities.livingAmenities.MICROWAVE": .init(key: "facilities.livingAmenities.MICROWAVE", fallback: "전자레인지"),
        "facilities.livingAmenities.SHARED_KITCHEN_FULL_OPTION": .init(key: "facilities.livingAmenities.SHARED_KITCHEN_FULL_OPTION", fallback: "공용주방 풀옵션"),
        "facilities.livingAmenities.SHARED_PC": .init(key: "facilities.livingAmenities.SHARED_PC", fallback: "공용PC"),
        "facilities.livingAmenities.SHARED_REFRIGERATOR": .init(key: "facilities.livingAmenities.SHARED_REFRIGERATOR", fallback: "공용냉장고"),
        "facilities.livingAmenities.SOFA": .init(key: "facilities.livingAmenities.SOFA", fallback: "소파"),
        "facilities.livingAmenities.TV": .init(key: "facilities.livingAmenities.TV", fallback: "TV"),
        "facilities.livingAmenities.WIFI": .init(key: "facilities.livingAmenities.WIFI", fallback: "WIFI"),
        "facilities.securityFeatures.CCTV": .init(key: "facilities.securityFeatures.CCTV", fallback: "CCTV"),
        "facilities.securityFeatures.DOOR_LOCK": .init(key: "facilities.securityFeatures.DOOR_LOCK", fallback: "도어락"),
        "facilities.securityFeatures.ENTRANCE_DOOR_LOCK": .init(key: "facilities.securityFeatures.ENTRANCE_DOOR_LOCK", fallback: "공동현관 도어락"),
        "facilities.securityFeatures.FIRE_ALARM": .init(key: "facilities.securityFeatures.FIRE_ALARM", fallback: "화재경보기"),
        "facilities.securityFeatures.FIRE_EXTINGUISHER": .init(key: "facilities.securityFeatures.FIRE_EXTINGUISHER", fallback: "소화기"),
        "facilities.securityFeatures.SECURITY_GUARD": .init(key: "facilities.securityFeatures.SECURITY_GUARD", fallback: "경비원"),
        "facilities.commonSpaces.LOUNGE": .init(key: "facilities.commonSpaces.LOUNGE", fallback: "휴게실"),
        "facilities.commonSpaces.SHARED_BATH": .init(key: "facilities.commonSpaces.SHARED_BATH", fallback: "샤워장"),
        "facilities.commonSpaces.SHARED_KITCHEN": .init(key: "facilities.commonSpaces.SHARED_KITCHEN", fallback: "공용주방"),
        "facilities.commonSpaces.SHARED_TOILET": .init(key: "facilities.commonSpaces.SHARED_TOILET", fallback: "공용화장실"),
        "facilities.commonSpaces.STUDY_ROOM": .init(key: "facilities.commonSpaces.STUDY_ROOM", fallback: "독서실"),
        "facilities.providedSupplies.BEDDING": .init(key: "facilities.providedSupplies.BEDDING", fallback: "침구류"),
        "facilities.providedSupplies.LAUNDRY_DETERGENT": .init(key: "facilities.providedSupplies.LAUNDRY_DETERGENT", fallback: "세탁세제"),
        "facilities.providedSupplies.SEASONING": .init(key: "facilities.providedSupplies.SEASONING", fallback: "조미료"),
        "facilities.providedSupplies.SLIPPERS": .init(key: "facilities.providedSupplies.SLIPPERS", fallback: "실내화"),
        "facilities.providedSupplies.TISSUE": .init(key: "facilities.providedSupplies.TISSUE", fallback: "휴지"),
        "facilities.providedSupplies.TOWEL": .init(key: "facilities.providedSupplies.TOWEL", fallback: "수건"),
        "facilities.heatingSystem.CENTRAL": .init(key: "facilities.heatingSystem.CENTRAL", fallback: "중앙난방"),
        "facilities.heatingSystem.DISTRICT": .init(key: "facilities.heatingSystem.DISTRICT", fallback: "지역난방"),
        "facilities.heatingSystem.INDIVIDUAL": .init(key: "facilities.heatingSystem.INDIVIDUAL", fallback: "개별난방"),
        "facilities.heatingSystem.OTHER": .init(key: "facilities.heatingSystem.OTHER", fallback: "전기난방"),
        "nearbyUniversityCodes.CAU": .init(key: "nearbyUniversityCodes.CAU", fallback: "중앙대학교"),
        "nearbyUniversityCodes.HUFS": .init(key: "nearbyUniversityCodes.HUFS", fallback: "한국외국어대학교"),
        "nearbyUniversityCodes.HYU": .init(key: "nearbyUniversityCodes.HYU", fallback: "한양대학교"),
        "nearbyUniversityCodes.KHU": .init(key: "nearbyUniversityCodes.KHU", fallback: "경희대학교"),
        "nearbyUniversityCodes.KONKUK": .init(key: "nearbyUniversityCodes.KONKUK", fallback: "건국대학교"),
        "nearbyUniversityCodes.KOREA": .init(key: "nearbyUniversityCodes.KOREA", fallback: "고려대학교"),
        "nearbyUniversityCodes.SEJONG": .init(key: "nearbyUniversityCodes.SEJONG", fallback: "세종대학교"),
        "nearbyUniversityCodes.SKKU": .init(key: "nearbyUniversityCodes.SKKU", fallback: "성균관대학교"),
        "nearbyUniversityCodes.SNU": .init(key: "nearbyUniversityCodes.SNU", fallback: "서울대학교"),
        "nearbyUniversityCodes.SOONGSIL": .init(key: "nearbyUniversityCodes.SOONGSIL", fallback: "숭실대학교"),
        "nearbyUniversityCodes.SUNGSHIN": .init(key: "nearbyUniversityCodes.SUNGSHIN", fallback: "성신여자대학교"),
        "nearestTransit.type.SUBWAY": .init(key: "nearestTransit.type.SUBWAY", fallback: "지하철"),
        "nearestTransit.name.Anguk": .init(key: "nearestTransit.name.Anguk", fallback: "안국역"),
        "nearestTransit.name.Bongcheon": .init(key: "nearestTransit.name.Bongcheon", fallback: "봉천역"),
        "nearestTransit.name.Cheongnyangni": .init(key: "nearestTransit.name.Cheongnyangni", fallback: "청량리역"),
        "nearestTransit.name.Guui": .init(key: "nearestTransit.name.Guui", fallback: "구의역"),
        "nearestTransit.name.Hyehwa": .init(key: "nearestTransit.name.Hyehwa", fallback: "혜화역"),
        "nearestTransit.name.Jayang": .init(key: "nearestTransit.name.Jayang", fallback: "자양역"),
        "nearestTransit.name.Jegi-dong": .init(key: "nearestTransit.name.Jegi-dong", fallback: "제기동역"),
        "nearestTransit.name.Jongno 3-ga": .init(key: "nearestTransit.name.Jongno 3-ga", fallback: "종로3가역"),
        "nearestTransit.name.Konkuk Univ.": .init(key: "nearestTransit.name.Konkuk Univ.", fallback: "건대입구역"),
        "nearestTransit.name.Nakseongdae": .init(key: "nearestTransit.name.Nakseongdae", fallback: "낙성대역"),
        "nearestTransit.name.Seoul Nat'l Univ.": .init(key: "nearestTransit.name.Seoul Nat'l Univ.", fallback: "서울대입구역"),
        "nearestTransit.name.Sillim": .init(key: "nearestTransit.name.Sillim", fallback: "신림역"),
        "roomOffer.status.ACTIVE": .init(key: "roomOffer.status.ACTIVE", fallback: "운영 중"),
        "roomOffer.currency.KRW": .init(key: "roomOffer.currency.KRW", fallback: "원"),
        "roomOffer.filterTags.ADDRESS_REGISTRATION": .init(key: "roomOffer.filterTags.ADDRESS_REGISTRATION", fallback: "전입신고 가능"),
        "roomOffer.filterTags.DOUBLE_ROOM": .init(key: "roomOffer.filterTags.DOUBLE_ROOM", fallback: "2인실 가능"),
        "roomOffer.filterTags.ENGLISH_OK": .init(key: "roomOffer.filterTags.ENGLISH_OK", fallback: "영어 소통 가능"),
        "roomOffer.filterTags.FEMALE_ONLY": .init(key: "roomOffer.filterTags.FEMALE_ONLY", fallback: "여성 전용"),
        "roomOffer.filterTags.MEALS_INCLUDED": .init(key: "roomOffer.filterTags.MEALS_INCLUDED", fallback: "식사 제공"),
        "roomOffer.filterTags.MOVE_IN_NOW": .init(key: "roomOffer.filterTags.MOVE_IN_NOW", fallback: "즉시 입주"),
        "roomOffer.filterTags.NO_MAINT_FEE": .init(key: "roomOffer.filterTags.NO_MAINT_FEE", fallback: "관리비 없음"),
        "roomOffer.filterTags.PRIVATE_BATH": .init(key: "roomOffer.filterTags.PRIVATE_BATH", fallback: "개인 욕실 · 화장실"),
        "refundPolicy.code.FULL_REFUND_BEFORE_7_DAYS": .init(key: "refundPolicy.code.FULL_REFUND_BEFORE_7_DAYS", fallback: "입주 7일 전 취소 시 전액 환불"),
        "refundPolicy.code.NON_REFUNDABLE": .init(key: "refundPolicy.code.NON_REFUNDABLE", fallback: "입주 당일 취소 시 환불 불가"),
        "refundPolicy.code.PARTIAL_REFUND": .init(key: "refundPolicy.code.PARTIAL_REFUND", fallback: "부분 환불"),
        "propertyPolicies.arcRequired": .init(key: "propertyPolicies.arcRequired", fallback: "ARC 필요"),
        "propertyPolicies.residentRegistrationAvailable": .init(key: "propertyPolicies.residentRegistrationAvailable", fallback: "전입신고 가능"),
        "propertyPolicies.studySuitable": .init(key: "propertyPolicies.studySuitable", fallback: "학습 적합"),
        "propertyPolicies.mealsProvided": .init(key: "propertyPolicies.mealsProvided", fallback: "식사 제공"),
        "propertyPolicies.englishAvailable": .init(key: "propertyPolicies.englishAvailable", fallback: "영어 소통 가능")
    ]
}
