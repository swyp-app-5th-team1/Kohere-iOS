//
//  LocationClient.swift
//  Kohere
//
//  Created by Codex on 6/23/26.
//

import ComposableArchitecture
import CoreLocation

struct LocationClient {
    var requestAuthorization: () async -> MapLocationAuthorization
    var locationUpdates: () async -> AsyncStream<MapCoordinate>
}

extension LocationClient: DependencyKey {
    static let liveValue: LocationClient = {
        let service = LiveLocationService()

        return LocationClient(
            requestAuthorization: {
                await service.requestAuthorization()
            },
            locationUpdates: {
                service.locationUpdates()
            }
        )
    }()
}

extension DependencyValues {
    var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}

@MainActor
private final class LiveLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<MapLocationAuthorization, Never>?
    private var locationContinuations: [UUID: AsyncStream<MapCoordinate>.Continuation] = [:]

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorization() async -> MapLocationAuthorization {
        let authorization = makeMapLocationAuthorization(from: manager.authorizationStatus)

        guard authorization == .notDetermined else {
            return authorization
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationUpdates() -> AsyncStream<MapCoordinate> {
        AsyncStream { continuation in
            let id = UUID()
            locationContinuations[id] = continuation

            if locationContinuations.count == 1 {
                manager.startUpdatingLocation()
            }

            continuation.onTermination = { _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    locationContinuations[id] = nil

                    if locationContinuations.isEmpty {
                        manager.stopUpdatingLocation()
                    }
                }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorization = makeMapLocationAuthorization(from: manager.authorizationStatus)

        guard authorization != .notDetermined else { return }
        authorizationContinuation?.resume(returning: authorization)
        authorizationContinuation = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        let coordinate = makeMapCoordinate(from: location.coordinate)
        for continuation in locationContinuations.values {
            continuation.yield(coordinate)
        }
    }
}

private func makeMapCoordinate(from coordinate: CLLocationCoordinate2D) -> MapCoordinate {
    MapCoordinate(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude
    )
}

private func makeMapLocationAuthorization(from status: CLAuthorizationStatus) -> MapLocationAuthorization {
    switch status {
    case .notDetermined:
        .notDetermined

    case .authorizedAlways, .authorizedWhenInUse:
        .authorized

    case .denied:
        .denied

    case .restricted:
        .restricted

    @unknown default:
        .restricted
    }
}
