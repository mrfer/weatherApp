//
//  DrawerPreviewContentViewController.swift
//  weatherApp
//
//  Created by Artur on 25.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import UIKit
import Pulley
import MapKit
import RxCocoa
import RxSwift
import RxDataSources
import NSObject_Rx

class ListWeathersViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: ShakingSearchBar!
    @IBOutlet var gripperView: UIView!
    
    @IBOutlet var seperatorHeightConstraint: NSLayoutConstraint!
    
    var mapView: MKMapView?
    
    weak var handleMapSearchDelegate: HandleMapSearch?
    
    let dataSource = RxTableViewSectionedReloadDataSource<WeatherSection>()
    var shownPlacesSection: WeatherSection!
    var allPlaces = [WeatherItem]()
    var sections = PublishSubject<[WeatherSection]>()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gripperView.layer.cornerRadius = 2.5
        seperatorHeightConstraint.constant = 1.0 / UIScreen.main.scale
        
        NotificationCenter.default.addObserver(self, selector: #selector(obtainPlacesDataStorage), name: .weatherAppWillUpateListWeatherNotification, object: nil)
        
        setupCellConfiguration()
        setupCellTapHandling()
        setupSearhBar()
    }
}

extension ListWeathersViewController: PulleyDrawerViewControllerDelegate {
    
    func collapsedDrawerHeight() -> CGFloat
    {
        return 68.0
    }
    
    func partialRevealDrawerHeight() -> CGFloat
    {
        return 264.0
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all // You can specify the drawer positions you support. This is the same as: [.open, .partiallyRevealed, .collapsed, .closed]
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController)
    {
        //tableView.isScrollEnabled = drawer.drawerPosition == .open
        
        if drawer.drawerPosition != .open {
            view.endEditing(true)
            self.searchBar.setShowsCancelButton(false, animated: false)
        } else {
            
        }
    }
}

// MARK: - Setup Rx

extension ListWeathersViewController {
    
    func setupSearhBar() {
        
        searchBar.returnKeyType = .done
        
        searchBar
            .rx.textDidBeginEditing
            .subscribe(onNext: { _ in
                if let drawerVC = self.parent as? PulleyViewController
                {
                    drawerVC.setDrawerPosition(position: .open, animated: true)
                    self.searchBar.shake()
                    self.searchBar.setShowsCancelButton(true, animated: true)
                }
            })
            .addDisposableTo(disposeBag)
        
        searchBar
            .rx.text
            .orEmpty // Make it non-optional
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] query in
                
                if query.characters.count == 0 {
                   
                    self.obtainPlacesDataStorage()

                } else {
                    self.obtainPlacesMap(text: query)
                }
            })
            .addDisposableTo(disposeBag)
        
        searchBar
            .rx
            .cancelButtonClicked
            .subscribe(onNext: { [unowned self] in
                self.searchBar.setShowsCancelButton(false, animated: false)
                self.view.endEditing(true)
                if let drawerVC = self.parent as? PulleyViewController
                {
                    drawerVC.setDrawerPosition(position: .collapsed, animated: true)
                }

            
            }).addDisposableTo(disposeBag)
        
        searchBar
            .rx
            .searchButtonClicked
            .subscribe(onNext: { [unowned self] in
                self.view.endEditing(true)
            }).addDisposableTo(disposeBag)
        
    }
    
    func setupCellConfiguration(){
        
        shownPlacesSection = WeatherSection(header: "Places", items: allPlaces)
        sections.onNext([shownPlacesSection])
        dataSource.configureCell = { (_, tableView, indexPath, index) in
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
            cell.configureWithWeather(weatherItem: self.shownPlacesSection.items[indexPath.row])
            return cell
        }
        
        sections
            .asObservable()
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(rx_disposeBag) // Instead of creating the bag again and again, use the extension NSObject_rx
    }
    
    func setupCellTapHandling() {
        
        tableView
            .rx
            .modelSelected(WeatherItem.self)
            .subscribe(onNext: {
                weatherItem in
                
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                    
                    if weatherItem.temp == nil {
                        let selectedItem = weatherItem.placemapk
                        self.handleMapSearchDelegate?.dropPinZoomIn(selectedItem!)
                        self.view.endEditing(true)
                        if let drawerVC = self.parent as? PulleyViewController
                        {
                            drawerVC.setDrawerPosition(position: .collapsed, animated: true)
                        }
                    }
                }
            })
            .addDisposableTo(rx_disposeBag)
    }
    
    fileprivate func obtainPlacesMap(text: String) {
        
        guard let mapView = self.mapView else { return }
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            
            let matchingItems = response.mapItems
            
            self.allPlaces.removeAll()
            self.allPlaces = matchingItems.map({ item in
                WeatherItem(namePlacemark: item.placemark.name!, addressPlacemark: self.parseAddress(item.placemark), temp: nil, date: nil, time: nil, placemapk: item.placemark)
            })
            
            self.shownPlacesSection = WeatherSection(
                original: self.shownPlacesSection,
                items: self.allPlaces
            )
            
            self.sections.onNext([self.shownPlacesSection])
        }
    }

    @objc fileprivate func obtainPlacesDataStorage() {
        
        self.allPlaces.removeAll()
        if let weathersOld = DataStorage.defaultLocalDB.obtainArrayWeathers(){
            self.allPlaces = weathersOld
            
            self.shownPlacesSection = WeatherSection(
                original: self.shownPlacesSection,
                items: self.allPlaces
            )
            
            self.sections.onNext([self.shownPlacesSection])
        }
    }
}


extension ListWeathersViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

// Mark: HelpersFunctions

extension ListWeathersViewController {
    
   fileprivate func parseAddress(_ selectedItem:MKPlacemark) -> String {
        
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil &&
            selectedItem.thoroughfare != nil) ? " " : ""
        
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) &&
            (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil &&
            selectedItem.administrativeArea != nil) ? " " : ""
        
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        
        return addressLine
    }
}
