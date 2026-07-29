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

        return ListingDetail(
            listingID: listingId,
            title: title ?? "",
            type: type?.label ?? "",
            status: status ?? "",
            rentalType: rentalType?.label ?? "",
            refundPolicy: refundPolicy?.toDetailEntity(),
            contract: contract?.toDetailEntity(),
            genderPolicy: genderPolicy?.label,
            coordinate: location?.toDetailCoordinate(),
            address: address?.toDetailEntity(),
            nearestTransit: nearestTransit?.toDetailEntity(),
            nearbyUniversityCodes: nearbyUniversityCodes ?? [],
            building: building?.toDetailEntity(),
            propertyPolicies: propertyPolicies?.toDetailEntity(),
            facilities: facilities?.toDetailEntity(),
            conditions: (conditions ?? []).map(\.label),
            roomOffers: (roomOffers ?? []).compactMap { $0.toDetailEntity() },
            descriptions: descriptions?.toDetailEntity(),
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

private extension ListingAddressResponseDTO {
    func toDetailEntity() -> ListingDetailAddress? {
        guard city != nil || district != nil || fullAddress != nil || detail != nil else {
            return nil
        }

        return ListingDetailAddress(
            city: city,
            district: district,
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

private extension ListingPropertyPoliciesResponseDTO {
    func toDetailEntity() -> ListingDetailPropertyPolicies {
        ListingDetailPropertyPolicies(
            arcRequired: arcRequired,
            residentRegistrationAvailable: residentRegistrationAvailable,
            mealsProvided: mealsProvided,
            englishAvailable: englishAvailable
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
            commonSpaces: (commonSpaces ?? []).compactMap { $0.toDetailEntity() },
            providedSupplies: (providedSupplies ?? []).map(\.label)
        )
    }
}

private extension ListingCommonSpaceResponseDTO {
    func toDetailEntity() -> ListingDetailCommonSpace? {
        guard let type = type?.label else { return nil }

        return ListingDetailCommonSpace(
            type: type,
            count: count
        )
    }
}

private extension ListingRoomOfferResponseDTO {
    func toDetailEntity() -> ListingDetailRoomOffer? {
        guard let roomOfferId else { return nil }

        let imageURLs = nonEmptyImageURLs(roomImageUrls)

        return ListingDetailRoomOffer(
            id: roomOfferId,
            name: name ?? "",
            status: status,
            pricing: pricing?.toDetailEntity(),
            inventory: inventory?.toDetailEntity(),
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

private extension ListingRoomInventoryResponseDTO {
    func toDetailEntity() -> ListingDetailRoomInventory {
        ListingDetailRoomInventory(
            totalCount: totalCount,
            availableCount: availableCount,
            nextAvailableFrom: nextAvailableFrom
        )
    }
}

private extension ListingDescriptionsResponseDTO {
    func toDetailEntity() -> ListingDetailDescriptions {
        ListingDetailDescriptions(
            korean: ko,
            english: en,
            extraNotes: extraNotes
        )
    }
}
