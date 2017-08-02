//
//  ViewController.swift
//  weatherApp
//
//  Created by Artur on 25.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import UIKit
import MapKit
import Pulley
import Alamofire
import RxCocoa
import RxSwift

protocol HandleMapSearch: class {
    func dropPinZoomIn(_ placemark:MKPlacemark)
}

class MapViewController: UIViewController{
    
    var selectedPin: MKPlacemark?
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var controlsContainer: UIView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet var myLocationButtonBottomConstraint: NSLayoutConstraint!
    
    fileprivate let myLocationButtonBottomDistance: CGFloat = 8.0
    
    var sig:Observable<Int>!
    var bag:DisposeBag!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureObservers()
        configureMapView()
        
        updateLocation()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureHandleMapSearchDelegate()
    }

    func configureObservers(){
        
        sig = Observable<Int>.interval(1.0, scheduler: MainScheduler.instance)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addPulse))
        tapGestureRecognizer.numberOfTapsRequired = 1
        controlsContainer.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func configureHandleMapSearchDelegate(){
       
        if let drawer = self.parent as? PulleyViewController {
            let drawerController = drawer.drawerContentViewController as! ListWeathersViewController
            drawerController.mapView = mapView
            drawerController.handleMapSearchDelegate = self
        }
    }
    
    func configureMapView(){
        mapView.showsCompass = false
    }
    
    func obtainWeather(_ location: CLLocation, currentLocationKey: Bool){
        
        WeatherService.obtainWeatherActiveStatus(with: location){ (temp, errors) in
            if let errors = errors {
                self.showErrors(errors)
                return
            }
            
            if let temp = temp {
                self.temperatureLabel.text = String(temp)
                if currentLocationKey == true {
                    WeatherService.sharedManager.lastTempCurrentLocation = String(temp)
                }
            }
        }
    }
    
    @IBAction func myLocationButtonTap(_ sender: Any) {
        updateLocation()
    }
    
    
    func willEnterForeground(){
        stopAllSessions()
        updateLocation()
    }
    
    func didEnterBackground() {
        DataStorage.defaultLocalDB.saveLastTempCurrentLocation()
        updateLocation()
    }
}

// MARK: - PulleyPrimaryContentControllerDelegate

extension MapViewController: PulleyPrimaryContentControllerDelegate {
    
    func makeUIAdjustmentsForFullscreen(progress: CGFloat)
    {
        controlsContainer.alpha = 1.0 - progress
    }
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat)
    {
        if distance <= 268.0
        {
            myLocationButtonBottomConstraint.constant = distance + myLocationButtonBottomDistance
        }
        else
        {
            myLocationButtonBottomConstraint.constant = 268.0 + myLocationButtonBottomDistance
        }
    }
}

// MARK: - LocationService

extension MapViewController {
    
    func updateLocation(){
        
        startAnimation()
        
        LocationService.startLocation()
        
        LocationService.sharedManager.didUpdateLocation = { [weak self] location in
            
            guard let strongSelf = self else { return }
            strongSelf.obtainWeather(location, currentLocationKey: true)
            strongSelf.mapView.setRegionByLocation(location)
            
        }
    }
}

// MARK: HandleMapSearchDelegate

extension MapViewController: HandleMapSearch {
    
    func dropPinZoomIn(_ placemark: MKPlacemark){
        // cache the pin
        startAnimation()
        
        self.mapView.dropPinZoomIn(with: placemark)
        self.obtainWeather(placemark.location!, currentLocationKey: false)
    }
}

// Mark: AnimationsService

extension MapViewController {
    
    func startAnimation() {
        
        self.bag = DisposeBag()

        sig.subscribe(onNext: { (sec) in
            if sec < 2 {
                self.addPulse()
            } else {
                self.bag = nil
            }
        }).addDisposableTo(bag)
    }
    
    @objc fileprivate func addPulse(){
        let pulse = PulsingAnimation(numberOfPulses: 1, radius: 120, position: controlsContainer.center)
        pulse.animationDuration = 1.5
        pulse.backgroundColor = UIColor(colorLiteralRed: 42.0/255.0, green: 165.0/255.0, blue: 252.0/255, alpha: 1).cgColor
        DispatchQueue.main.async {
            self.view.layer.insertSublayer(pulse, below: self.controlsContainer.layer)
        }
    }
}

// Mark: HelpersFunctions

extension MapViewController {
 
    fileprivate func stopAllSessions() {
        
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { $0.cancel() }
            uploadData.forEach { $0.cancel() }
            downloadData.forEach { $0.cancel() }
        }
    }
    
    fileprivate func showErrors(_ errors: [RequestError]) {
        
        let alertController = UIAlertController(title: "Error", message: errors.map { $0.errorText }.joined(separator: "\n") , preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "ОК", style: .cancel, handler: nil)
        alertController.addAction(OKAction)
        present(alertController, animated: true) {}
    }
}

extension Notification.Name {
    static let weatherAppWillUpateListWeatherNotification = Notification.Name("weatherAppWillUpateListWeatherNotification")
}
