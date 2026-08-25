//
//  ListingDetailResponseMapper.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

extension ListingDetailResponseDTO {
    func toEntity() throws -> ListingDetail {
        guard let listingId else { throw DataError.decodingFailed }

        let listingImageURLs = nonEmptyImageURLs(imageUrls)
        let offers = roomOffers ?? []
        let contracts = offers.compactMap(\.contract)
        let aggregateContract = ListingDetailContract(
            minStayMonths: contracts.compactMap(\.minStayMonths).min(),
            maxStayMonths: contracts.compactMap(\.maxStayMonths).max()
        )
        let conditionCodes = Set((conditions ?? []).map { $0.code.uppercased() })

        return ListingDetail(
            listingID: listingId,
            title: title ?? "",
            type: type?.label ?? "",
            status: status ?? "",
            rentalType: rentalType?.label ?? "",
            refundPolicy: refundPolicy.map {
                ListingDetailRefundPolicy(code: "", description: $0)
            },
            contract: contracts.isEmpty ? nil : aggregateContract,
            genderPolicy: genderPolicy?.label,
            coordinate: location?.toDetailCoordinate(),
            address: address?.toDetailEntity(),
            nearestTransit: nearestTransit?.toDetailEntity(),
            nearbyUniversityCodes: nearbyUniversityCodes ?? [],
            building: building?.toDetailEntity(),
            propertyPolicies: ListingDetailPropertyPolicies(
                arcRequired: arcRequired?.code.uppercased().contains("NOT") == false,
                residentRegistrationAvailable: conditionCodes.contains("ADDRESS_REGISTRATION"),
                mealsProvided: conditionCodes.contains("MEALS_INCLUDED"),
                englishAvailable: conditionCodes.contains("ENGLISH_OK")
            ),
            facilities: facilities?.toDetailEntity(),
            conditions: (conditions ?? []).map(\.label),
            roomOffers: offers.compactMap { $0.toDetailEntity() },
            descriptions: ListingDetailDescriptions(
                korean: description,
                english: description,
                extraNotes: extraNotes
            ),
            imageURLs: listingImageURLs,
            isFavorited: favorited ?? false,
            favoriteCount: favoriteCount ?? 0,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension ListingLocationResponseDTO {
    func toDetailCoordinate() -> MapCoordinate? {
        guard let lat, let lng else { return nil }
        return MapCoordinate(latitude: lat, longitude: lng)
    }
}

private extension ListingNearestTransitResponseDTO {
    func toDetailEntity() -> ListingDetailNearestTransit? {
        guard let name else { return nil }

        return ListingDetailNearestTransit(
            type: type?.label,
            name: name,
            walkMinutes: walkMinutes,
            nearbyPlacesDescription: nearbyPlacesDescription
        )
    }
}

private extension ListingRefundPolicyResponseDTO {
    func toDetailEntity() -> ListingDetailRefundPolicy? {
        guard let code else { return nil }

        return ListingDetailRefundPolicy(
            code: code,
            description: description
        )
    }
}

private extension ListingContractResponseDTO {
    func toDetailEntity() -> ListingDetailContract {
        ListingDetailContract(
            minStayMonths: minStayMonths,
            maxStayMonths: maxStayMonths
        )
    }
}

private extension ListingAddressV2ResponseDTO {
    func toDetailEntity() -> ListingDetailAddress? {
        guard city != nil || district != nil || fullAddress != nil || detail != nil else {
            return nil
        }

        return ListingDetailAddress(
            city: city?.label,
            district: district?.label,
            fullAddress: fullAddress,
            detail: detail
        )
    }
}

private extension ListingBuildingResponseDTO {
    func toDetailEntity() -> ListingDetailBuilding {
        ListingDetailBuilding(
            type: type?.label,
            usedFloorMin: usedFloorMin,
            usedFloorMax: usedFloorMax,
            totalFloors: totalFloors,
            parkingAvailable: parkingAvailable,
            elevatorAvailable: elevatorAvailable
        )
    }
}

private extension ListingFacilitiesResponseDTO {
    func toDetailEntity() -> ListingDetailFacilities {
        ListingDetailFacilities(
            heatingSystem: (heatingSystem ?? []).map(\.label),
            kitchen: (kitchen ?? []).map(\.label),
            laundry: (laundry ?? []).map(\.label),
            livingAmenities: (livingAmenities ?? []).map(\.label),
            securityFeatures: (securityFeatures ?? []).map(\.label),
            commonSpaces: (commonSpaces ?? []).map {
                ListingDetailCommonSpace(type: $0.label, count: nil)
            },
            providedSupplies: (providedSupplies ?? []).map(\.label)
        )
    }
}

private extension ListingRoomOfferV2ResponseDTO {
    func toDetailEntity() -> ListingDetailRoomOffer? {
        guard let roomOfferId else { return nil }

        let imageURLs = nonEmptyImageURLs(roomImageUrls)

        return ListingDetailRoomOffer(
            id: roomOfferId,
            name: name ?? "",
            status: status,
            pricing: pricing?.toDetailEntity(),
            inventory: nil,
            filterTags: (filterTags ?? []).map(\.label),
            roomImageURLs: imageURLs
        )
    }
}

private extension ListingRoomPricingResponseDTO {
    func toDetailEntity() -> ListingDetailRoomPricing {
        ListingDetailRoomPricing(
            monthlyRent: monthlyRent,
            deposit: deposit,
            maintenanceFee: maintenanceFee,
            currency: currency
        )
    }
}

private func nonEmptyImageURLs(_ imageURLs: [String]?) -> [String] {
    (imageURLs ?? [])
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}
