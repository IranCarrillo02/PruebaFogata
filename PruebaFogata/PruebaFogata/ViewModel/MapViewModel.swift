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
    func setAnotations(_ annotation: CustomAnnotation)
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

        // Create a new UUID for each pin
        let newUUID = UUID()

        // Convert the coordinates to strings before saving
        pin.setValue(newUUID, forKey: "id")
        pin.setValue(coordinate.latitude, forKey: "latitude")
        pin.setValue(coordinate.longitude, forKey: "longitude")
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
                    if let latitude = pin.value(forKey: "latitude"), let longitude = pin.value(forKey: "longitude"), let name = pin.value(forKey: "name"), let id = pin.value(forKey: "id") {
                        let coordinate = CLLocationCoordinate2D(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees)
                        let customAnnotation = CustomAnnotation(coordinate: coordinate, title: name as? String, id: id as! UUID)
                        delegate?.setAnotations(customAnnotation)
                    }
                }
            }
        } catch {
            print("Failed to fetch pins: \(error)")
        }
    }
    
    func deleteRecord(_ withUUID: UUID, completition: @escaping (Bool) -> ()) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: PinEntityName)

        do {
            if let records = try context.fetch(fetchRequest) as? [NSManagedObject] {
                for record in records {
                    if let recordUUID = record.value(forKey: "id") as? UUID, recordUUID == withUUID {
                        context.delete(record)
                    }
                }
                try context.save()
                completition(true)
            }
        } catch {
            print("Error deleting record: \(error.localizedDescription)")
            completition(false)
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
