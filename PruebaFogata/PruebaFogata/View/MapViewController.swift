//
//  MapViewController.swift
//  PruebaFogata
//
//  Created by Iran Carrillo Guzman on 31/01/24.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    private var pinIsColocated = false
    private var viewModel: MapViewModel!

    private let mapView: MKMapView = {
        let mapView = MKMapView(frame: .zero)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        checkLocationAuthorization()
        setupLongPressGesture()
    }

    internal func initUI() {
        initViews()
        initConstraints()
        initListeners()
    }

    internal func initViews() {
        view.backgroundColor = .white
        view.addSubview(mapView)
    }

    internal func initConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    internal func initListeners() {
        // You can add any additional map-related setup or event handling here
    }

    private func checkLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            viewModel = MapViewModel()
            viewModel.delegate = self
            viewModel.setupMapView(mapView)
            viewModel.requestLocationAuthorization()
        } else {
            // Handle the case where location services are not enabled
            print("Location services are not enabled")
        }
    }

    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

            // Ask the user for a name for the new pin
            showNameInputAlert { name in
                // Add a new pin at the long-press location with the user-provided name
                let customAnnotation = CustomAnnotation(coordinate: coordinate, title: name)
                self.mapView.addAnnotation(customAnnotation)

                // Save the pin to Core Data
                self.viewModel.savePin(coordinate: coordinate, name: name)
            }
        }
    }
    
    private func showNameInputAlert(completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: "Add a Name", message: "Enter a name for the new pin", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Pin Name"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            if let name = alertController.textFields?.first?.text, !name.isEmpty {
                completion(name)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(addAction)

        present(alertController, animated: true, completion: nil)
    }
}

extension MapViewController: MapViewModelDelegate {
    func didUpdateLocation(_ location: CLLocationCoordinate2D) {
        if !pinIsColocated {
            mapView.setCenter(location, animated: true)
            mapView.addAnnotation(CustomAnnotation(coordinate: location, title: "My Location"))

            // Zoom to the region around the pin
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            pinIsColocated = true
        }
    }

    func didSelectAnnotation(_ annotation: CustomAnnotation) {
        guard annotation.title != "My Location" else {
            let alertController = UIAlertController(title: "Pin Details", message: "Coordinates: \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)\nTitle: \(annotation.title ?? "")", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)

            alertController.addAction(okAction)
            
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "Pin Details", message: "Coordinates: \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)\nTitle: \(annotation.title ?? "")", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.mapView.removeAnnotation(annotation)
        }

        alertController.addAction(okAction)
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
}
