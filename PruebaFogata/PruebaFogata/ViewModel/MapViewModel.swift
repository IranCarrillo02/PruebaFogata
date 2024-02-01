//
//  MapViewModel.swift
//  PruebaFogata
//
//  Created by Iran Carrillo Guzman on 31/01/24.
//

import MapKit
import CoreLocation
import CoreData

// Define your Core Data entity name
let PinEntityName = "PinsLocations"

protocol MapViewModelDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocationCoordinate2D)
    func didSelectAnnotation(_ annotation: CustomAnnotation)
}

class MapViewModel: NSObject, CLLocationManagerDelegate {

    weak var delegate: MapViewModelDelegate?
    private var locationManager = CLLocationManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LocationModel")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    func setupMapView(_ mapView: MKMapView) {
        mapView.delegate = self
        mapView.showsUserLocation = true

        // Fetch and add saved pins
        fetchPins()
    }

    func requestLocationAuthorization() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first?.coordinate {
            delegate?.didUpdateLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle the case where the user's location authorization status changes
        // You might want to update the UI or take specific actions based on the status
    }

    // MARK: - Core Data Methods

    func savePin(coordinate: CLLocationCoordinate2D, name: String) {
        let context = persistentContainer.viewContext

        guard let entityDescription = NSEntityDescription.entity(forEntityName: PinEntityName, in: context) else {
            return
        }

        let pin = NSManagedObject(entity: entityDescription, insertInto: context)

        // Convert the coordinates to strings before saving
        pin.setValue(String(coordinate.latitude), forKey: "latitude")
        pin.setValue(String(coordinate.longitude), forKey: "longitude")
        pin.setValue(name, forKey: "name")

        do {
            try context.save()
        } catch {
            print("Failed to save pin: \(error)")
        }
    }

    func fetchPins() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: PinEntityName)

        do {
            if let pins = try context.fetch(fetchRequest) as? [NSManagedObject] {
                for pin in pins {
                    if let latitude = pin.value(forKey: "latitude") as? CLLocationDegrees,
                       let longitude = pin.value(forKey: "longitude") as? CLLocationDegrees,
                       let name = pin.value(forKey: "name") as? String {
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let customAnnotation = CustomAnnotation(coordinate: coordinate, title: name)
                        delegate?.didUpdateLocation(coordinate)
                        delegate?.didSelectAnnotation(customAnnotation)
                    }
                }
            }
        } catch {
            print("Failed to fetch pins: \(error)")
        }
    }
}

extension MapViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomAnnotation else {
            return nil
        }

        let identifier = "pinAnnotation"
        var annotationView: MKPinAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            annotationView = dequeuedView
        } else {
            annotationView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if let customAnnotation = view.annotation as? CustomAnnotation {
                delegate?.didSelectAnnotation(customAnnotation)
            }
        }
    }
}
