//
//  ListingDetailResponseMapper.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

extension ListingDetailResponseDTO {
    func toEntity() throws -> ListingDetail {
        guard let listingId else { throw DataError.decodingFailed }

        let conditionCodes = conditions ?? []

        return ListingDetail(
            listingID: listingId,
            title: title ?? "",
            type: type ?? "",
            status: status ?? "",
            rentalType: rentalType ?? "",
            refundPolicy: refundPolicy?.toDetailEntity(),
            contract: contract?.toDetailEntity(),
            genderPolicy: genderPolicy,
            coordinate: location?.toDetailCoordinate(),
            address: address?.toDetailEntity(),
            nearestTransit: nearestTransit?.toDetailEntity(),
            nearbyUniversityCodes: nearbyUniversityCodes ?? [],
            building: building?.toDetailEntity(),
            propertyPolicies: propertyPolicies?.toDetailEntity(),
            facilities: facilities?.toDetailEntity(),
            conditionCodes: conditionCodes,
            conditions: conditionCodes.compactMap(RoomCondition.init(conditionCode:)),
            roomOffers: (roomOffers ?? []).compactMap { $0.toDetailEntity() },
            descriptions: descriptions?.toDetailEntity(),
            imageURLs: imageUrls ?? [],
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
            type: type,
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
            type: type,
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
            studySuitable: studySuitable,
            mealsProvided: mealsProvided,
            englishAvailable: englishAvailable
        )
    }
}

private extension ListingFacilitiesResponseDTO {
    func toDetailEntity() -> ListingDetailFacilities {
        ListingDetailFacilities(
            heatingSystem: heatingSystem ?? [],
            kitchen: kitchen ?? [],
            laundry: laundry ?? [],
            livingAmenities: livingAmenities ?? [],
            securityFeatures: securityFeatures ?? [],
            commonSpaces: (commonSpaces ?? []).compactMap { $0.toDetailEntity() },
            providedSupplies: providedSupplies ?? []
        )
    }
}

private extension ListingCommonSpaceResponseDTO {
    func toDetailEntity() -> ListingDetailCommonSpace? {
        guard let type else { return nil }

        return ListingDetailCommonSpace(
            type: type,
            count: count
        )
    }
}

private extension ListingRoomOfferResponseDTO {
    func toDetailEntity() -> ListingDetailRoomOffer? {
        guard let roomOfferId else { return nil }

        let filterTagCodes = filterTags ?? []

        return ListingDetailRoomOffer(
            id: roomOfferId,
            name: name ?? "",
            status: status,
            pricing: pricing?.toDetailEntity(),
            inventory: inventory?.toDetailEntity(),
            filterTagCodes: filterTagCodes,
            filterTags: filterTagCodes.compactMap(RoomCondition.init(conditionCode:)),
            roomImageURLs: roomImageUrls ?? []
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
