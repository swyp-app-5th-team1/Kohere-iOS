//
//  ListingDetailModel.swift
//  Kohere
//
//  Created by Codex on 6/27/26.
//

import Foundation

struct ListingDetailModel: Equatable, Identifiable {
    let id: String
    var overview: ListingDetailOverviewModel
    let tabs: [String]
    let roomOffers: [ListingRoomOfferModel]
    let priceInfo: [ListingDetailInfoRowModel]
    let propertyInfo: [ListingDetailInfoRowModel]
    let buildingInfo: [ListingDetailInfoRowModel]
    let facilityInfo: [ListingDetailInfoRowModel]
    let locationInfo: ListingLocationInfoModel
}

struct ListingDetailOverviewModel: Equatable, Identifiable {
    let id: String
    let title: String
    let typeTag: String
    let imageURLs: [String]
    let monthlyRentText: String
    let convertedMonthlyRentText: String
    let depositText: String
    let maintenanceFeeText: String
    let transitText: String
    let imageCountText: String
    let reviewCount: Int
    var isLiked: Bool
    var favoriteCount: Int?

    init(
        id: String,
        title: String,
        typeTag: String,
        imageURLs: [String] = [],
        monthlyRentText: String,
        convertedMonthlyRentText: String,
        depositText: String,
        maintenanceFeeText: String,
        transitText: String,
        imageCountText: String,
        reviewCount: Int,
        isLiked: Bool,
        favoriteCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.typeTag = typeTag
        self.imageURLs = imageURLs
        self.monthlyRentText = monthlyRentText
        self.convertedMonthlyRentText = convertedMonthlyRentText
        self.depositText = depositText
        self.maintenanceFeeText = maintenanceFeeText
        self.transitText = transitText
        self.imageCountText = imageCountText
        self.reviewCount = reviewCount
        self.isLiked = isLiked
        self.favoriteCount = favoriteCount
    }
}

struct ListingRoomOfferModel: Equatable, Identifiable {
    let id: String
    let name: String
    let imageURLs: [String]
    let pricingText: String
    let tags: [String]

    init(
        id: String,
        name: String,
        imageURLs: [String] = [],
        pricingText: String,
        tags: [String]
    ) {
        self.id = id
        self.name = name
        self.imageURLs = imageURLs
        self.pricingText = pricingText
        self.tags = tags
    }
}

struct ListingDetailInfoRowModel: Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
}

struct ListingLocationInfoModel: Equatable {
    let sectionTitle: String
    let addressText: String
    let transits: [ListingTransitInfoModel]
    let coordinate: MapCoordinate?
    let nearbyPlacesTitle: String
    let nearbyPlacesText: String
}

struct ListingTransitInfoModel: Equatable, Identifiable {
    let id: String
    let lineText: String
    let lineColorName: String
    let description: String
}

extension ListingDetailModel {
    static let tabs = ["각 방 정보", "가격 정보", "매물 정보", "건물 정보", "공용 시설", "위치", "리뷰"]

    static let mockList: [ListingDetailModel] = [
        ListingDetailModel(
            id: "1",
            overview: ListingDetailOverviewModel(
                id: "1",
                title: "Happy Goshiwon",
                typeTag: "Goshiwon",
                monthlyRentText: "₩380~400K/mo",
                convertedMonthlyRentText: "≈$355~398/mo",
                depositText: "Dep. ₩200K",
                maintenanceFeeText: "No Maint. Fee",
                transitText: "8-min walk Hongdae Sta.",
                imageCountText: "1/20",
                reviewCount: 0,
                isLiked: false
            ),
            tabs: tabs,
            roomOffers: [
                ListingRoomOfferModel(
                    id: "green-zone-1",
                    name: "Green Zone 1",
                    pricingText: "₩490K/mo · ₩1M deposit",
                    tags: ["Move-in Now", "Female Only", "Private Bath"]
                ),
                ListingRoomOfferModel(
                    id: "standard-single",
                    name: "Standard Single",
                    pricingText: "₩380K/mo · ₩200K deposit",
                    tags: ["Move-in Now", "Female Only", "No Maint. Fee"]
                ),
                ListingRoomOfferModel(
                    id: "compact-single",
                    name: "Compact Single",
                    pricingText: "₩400K/mo · ₩200K deposit",
                    tags: ["Meals Included", "English OK", "Address Registration"]
                )
            ],
            priceInfo: [
                ListingDetailInfoRowModel(id: "rental-type", title: "Rental Type", value: "Monthly Rent"),
                ListingDetailInfoRowModel(id: "deposit", title: "Deposit", value: "₩600~700K"),
                ListingDetailInfoRowModel(id: "maintenance-fee", title: "Maint. Fee", value: "N/A"),
                ListingDetailInfoRowModel(id: "refund-policy", title: "Refunds", value: "7-day notice required")
            ],
            propertyInfo: [
                ListingDetailInfoRowModel(id: "stay", title: "Stay", value: "1 mo min"),
                ListingDetailInfoRowModel(id: "gender", title: "Gender", value: "Gender-Separated"),
                ListingDetailInfoRowModel(
                    id: "features",
                    title: "Features",
                    value: "Move-in Now, No ARC, No Maint. Fee, Meals Included, Single OK, Double Room, Female Only, Private Bath, Address Registration"
                )
            ],
            buildingInfo: [
                ListingDetailInfoRowModel(id: "building-type", title: "Building Type", value: "Low-rise Apartment"),
                ListingDetailInfoRowModel(id: "floor", title: "Floors", value: "Floors 2-3 of 5"),
                ListingDetailInfoRowModel(id: "parking", title: "Parking", value: "No Parking"),
                ListingDetailInfoRowModel(id: "elevator", title: "Elevator", value: "No Elevator")
            ],
            facilityInfo: [
                ListingDetailInfoRowModel(id: "heating", title: "Heating", value: "Central Heating"),
                ListingDetailInfoRowModel(id: "laundry", title: "Laundry", value: "Washer, Iron"),
                ListingDetailInfoRowModel(id: "kitchen", title: "Kitchen", value: "Shared Refrigerator, Microwave, Electric Kettle, Gas Stove"),
                ListingDetailInfoRowModel(id: "amenities", title: "Amenities", value: "Wi-Fi, TV, Sofa"),
                ListingDetailInfoRowModel(id: "security", title: "Security", value: "Shared Entrance, Digital Door Lock, CCTV, Fire Extinguisher"),
                ListingDetailInfoRowModel(id: "common-areas", title: "Common Areas", value: "Shared Bathrooms, Study Room, Meeting Room, Rooftop, Shower Room"),
                ListingDetailInfoRowModel(id: "supplies", title: "Supplies", value: "Laundry Detergent, Toilet Paper, Slippers")
            ],
            locationInfo: ListingLocationInfoModel(
                sectionTitle: "Location & Nearby",
                addressText: "서울 동대문구 이문동 567-89",
                transits: [
                    ListingTransitInfoModel(id: "line-2", lineText: "2", lineColorName: "green60", description: "3 min walk from HUFS Station")
                ],
                coordinate: MapCoordinate(latitude: 37.5963, longitude: 127.0528),
                nearbyPlacesTitle: "Nearby Amenities",
                nearbyPlacesText: "Convenience Store, Pharmacy, Laundry Service"
            )
        ),
        ListingDetailModel(
            id: "2",
            overview: ListingDetailOverviewModel(
                id: "2",
                title: "스테이폴리오 성수점",
                typeTag: "코리빙",
                monthlyRentText: "월세 75~100만 원",
                convertedMonthlyRentText: "≈$355~398/mo",
                depositText: "보증금 50만 원",
                maintenanceFeeText: "관리비 5만원",
                transitText: "성수역 도보 5분",
                imageCountText: "1/24",
                reviewCount: 2,
                isLiked: false
            ),
            tabs: tabs,
            roomOffers: koreanRoomOffers,
            priceInfo: [
                ListingDetailInfoRowModel(id: "rental-type", title: "임대 유형", value: "월세"),
                ListingDetailInfoRowModel(id: "deposit", title: "보증금", value: "50만 원"),
                ListingDetailInfoRowModel(id: "maintenance-fee", title: "관리비", value: "5만 원"),
                ListingDetailInfoRowModel(id: "refund-policy", title: "환불 규정", value: "퇴실 7일 전 통보")
            ],
            propertyInfo: [
                ListingDetailInfoRowModel(id: "stay", title: "이용 기간", value: "최소 6개월~최대 12개월"),
                ListingDetailInfoRowModel(id: "gender", title: "남녀구분", value: "여성전용"),
                ListingDetailInfoRowModel(id: "features", title: "기타사항", value: "취사 가능, 전입신고 가능, 식사 제공, 개인 욕실·화장실, 영어 소통 가능")
            ],
            buildingInfo: [
                ListingDetailInfoRowModel(id: "building-type", title: "건물 형태", value: "빌라/연립"),
                ListingDetailInfoRowModel(id: "floor", title: "층수", value: "1층~3층 / 전체 4층"),
                ListingDetailInfoRowModel(id: "parking", title: "주차", value: "불가능"),
                ListingDetailInfoRowModel(id: "elevator", title: "엘리베이터", value: "없음")
            ],
            facilityInfo: koreanFacilityRows,
            locationInfo: ListingLocationInfoModel(
                sectionTitle: "위치 및 주변시설",
                addressText: "서울 서대문구 대현동 234-38",
                transits: [
                    ListingTransitInfoModel(id: "sinchon", lineText: "2", lineColorName: "green60", description: "신촌역 도보 3분"),
                    ListingTransitInfoModel(id: "ewha", lineText: "2", lineColorName: "green60", description: "이대역 도보 5분")
                ],
                coordinate: MapCoordinate(latitude: 37.5580, longitude: 126.9458),
                nearbyPlacesTitle: "주변 편의시설",
                nearbyPlacesText: "대형마트, 세탁소"
            )
        ),
        ListingDetailModel(
            id: "3",
            overview: ListingDetailOverviewModel(
                id: "3",
                title: "연남 그린 하우스",
                typeTag: "쉐어하우스",
                monthlyRentText: "월세 49~55만 원",
                convertedMonthlyRentText: "≈$286/mo",
                depositText: "보증금 100만 원",
                maintenanceFeeText: "관리비 1/n",
                transitText: "홍대입구역 도보 8분",
                imageCountText: "1/27",
                reviewCount: 0,
                isLiked: false
            ),
            tabs: tabs,
            roomOffers: koreanRoomOffers,
            priceInfo: [
                ListingDetailInfoRowModel(id: "rental-type", title: "임대 유형", value: "월세"),
                ListingDetailInfoRowModel(id: "deposit", title: "보증금", value: "100만 원"),
                ListingDetailInfoRowModel(id: "maintenance-fee", title: "관리비", value: "1/n"),
                ListingDetailInfoRowModel(id: "refund-policy", title: "환불 규정", value: "퇴실 7일 전 통보")
            ],
            propertyInfo: [
                ListingDetailInfoRowModel(id: "stay", title: "이용 기간", value: "최소 6개월~최대 12개월"),
                ListingDetailInfoRowModel(id: "gender", title: "남녀구분", value: "여성전용"),
                ListingDetailInfoRowModel(id: "features", title: "기타사항", value: "취사 가능, 공용라운지, 식사 제공, 개인 욕실·화장실, ARC 필수")
            ],
            buildingInfo: [
                ListingDetailInfoRowModel(id: "building-type", title: "건물 형태", value: "상가건물"),
                ListingDetailInfoRowModel(id: "floor", title: "층수", value: "사용 3층 / 전체 4층"),
                ListingDetailInfoRowModel(id: "parking", title: "주차", value: "불가능"),
                ListingDetailInfoRowModel(id: "elevator", title: "엘리베이터", value: "없음")
            ],
            facilityInfo: [
                ListingDetailInfoRowModel(id: "heating", title: "난방시설", value: "중앙난방"),
                ListingDetailInfoRowModel(id: "laundry", title: "세탁시설", value: "세탁기, 건조기, 건조대"),
                ListingDetailInfoRowModel(id: "kitchen", title: "주방시설", value: "공용 냉장고, 전자레인지, 전기포트, 가스레인지, 인덕션, 정수기, 조리도구"),
                ListingDetailInfoRowModel(id: "amenities", title: "생활시설", value: "WIFI, 공용에어컨"),
                ListingDetailInfoRowModel(id: "security", title: "안전시설", value: "공동현관, 도어락, CCTV, 소화기"),
                ListingDetailInfoRowModel(id: "common-areas", title: "공간시설", value: "공용 화장실(2개), 샤워장, 휴게실"),
                ListingDetailInfoRowModel(id: "supplies", title: "제공비품", value: "세탁세제, 휴지")
            ],
            locationInfo: ListingLocationInfoModel(
                sectionTitle: "위치 및 주변시설",
                addressText: "서울 마포구 서교동 674-36",
                transits: [
                    ListingTransitInfoModel(id: "mangwon", lineText: "6", lineColorName: "yellow70", description: "망원역 도보 4분"),
                    ListingTransitInfoModel(id: "hapjeong", lineText: "2", lineColorName: "green60", description: "합정역 도보 8분")
                ],
                coordinate: MapCoordinate(latitude: 37.5568, longitude: 126.9140),
                nearbyPlacesTitle: "주변 편의시설",
                nearbyPlacesText: "편의점(도보 3분), 약국(도보 7분), 세탁소(도보 1분)"
            )
        )
    ]

    static func mock(id: String) -> ListingDetailModel {
        mockList.first { $0.id == id } ?? mockList[0]
    }

    private static let koreanRoomOffers: [ListingRoomOfferModel] = [
        ListingRoomOfferModel(
            id: "green-zone-1",
            name: "그린존1룸",
            pricingText: "월세 49만 원 · 보증금 100만 원",
            tags: ["즉시 입주", "여성 전용", "개인 화장실"]
        ),
        ListingRoomOfferModel(
            id: "green-zone-2",
            name: "그린존2룸",
            pricingText: "월세 55만 원 · 보증금 100만 원",
            tags: ["즉시 입주", "여성 전용", "개인 화장실"]
        ),
        ListingRoomOfferModel(
            id: "green-zone-3",
            name: "그린존3룸",
            pricingText: "월세 49만 원 · 보증금 100만 원",
            tags: ["식사 제공", "전입신고 가능", "ARC 필수"]
        )
    ]

    private static let koreanFacilityRows: [ListingDetailInfoRowModel] = [
        ListingDetailInfoRowModel(id: "heating", title: "난방시설", value: "중앙난방"),
        ListingDetailInfoRowModel(id: "laundry", title: "세탁시설", value: "세탁기, 다리미, 건조기"),
        ListingDetailInfoRowModel(id: "kitchen", title: "주방시설", value: "공용 냉장고, 전자레인지, 전기포트, 가스레인지, 전기밥솥, 커피머신, 식탁"),
        ListingDetailInfoRowModel(id: "amenities", title: "생활시설", value: "WIFI, TV, 소파, 공용에어컨, 공용 PC"),
        ListingDetailInfoRowModel(id: "security", title: "안전시설", value: "공동현관, 도어락, CCTV, 소화기"),
        ListingDetailInfoRowModel(id: "common-areas", title: "공간시설", value: "공용 화장실(14개), 독서실, 회의실, 옥상, 샤워장, 휴게실, 코워킹"),
        ListingDetailInfoRowModel(id: "supplies", title: "제공비품", value: "조미료, 세탁세제, 휴지, 실내화")
    ]
}
