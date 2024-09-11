import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var userLocationAnnotation: MKPointAnnotation!
    var isTrackingUserLocation = false
    var regionIconImageView: UIImageView!
    
    // Hedef konumlar ve dereceler
   
           let targetLocations = [
               (location: CLLocation(latitude: 40.8927236, longitude: 31.1680019), color: UIColor.red, icon: "Fazla Riskli"),
               (location: CLLocation(latitude: 40.8664894, longitude: 31.1672618), color: UIColor.yellow, icon: "Orta Riskli"),
               (location: CLLocation(latitude: 40.8767913, longitude: 31.1687546), color: UIColor.blue, icon: "Riskli"),
               (location: CLLocation(latitude: 40.9055567, longitude: 31.154617), color: UIColor.blue, icon: "Riskli"),
               (location: CLLocation(latitude: 40.9005048, longitude: 31.1724293), color: UIColor.yellow, icon: "Orta Riskli"),
               (location: CLLocation(latitude: 40.9050723, longitude: 31.17691), color: UIColor.red, icon: "Fazla Riskli"),

           ]

    
    private var iconImageCache = [String: UIImage]()
    private var shownAlerts = Set<CLLocation>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // MapView oluştur ve görünümü ekle
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        view.addSubview(mapView)

        // Konum yöneticisini oluştur
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        // Kullanıcı konumu işaretleyicisi oluştur
        userLocationAnnotation = MKPointAnnotation()
        mapView.addAnnotation(userLocationAnnotation)

        // Hedef konumlara işaretleyici ekle
        for target in targetLocations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = target.location.coordinate
            annotation.title = target.icon
            mapView.addAnnotation(annotation)
        }

        // Kullanıcı konumunu göster
        mapView.showsUserLocation = true

        // Bölge simgesi görüntüleyici oluştur ve görünümü ekle
        setupRegionIconImageView()

        // Yakınlaştırma, uzaklaştırma ve konuma gitme butonlarını ekle
        setupButtons()
    }

    // Konum güncellemeleri
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Kullanıcı konumu işaretleyicisini güncelle
        userLocationAnnotation.coordinate = location.coordinate

        // Hedef konumlara olan mesafeyi kontrol et
        for target in targetLocations {
            let distance = location.distance(from: target.location)
            if distance < 250, !shownAlerts.contains(target.location) { // 1000 metre içinde ve daha önce gösterilmemişse
                showAlert(for: target)
                shownAlerts.insert(target.location) // Uyarı gösterildikten sonra hedefi kaydet
            }
        }
        
        // Eğer kullanıcı konumunu takip ediyorsak haritayı kullanıcı konumuna merkezle
        if isTrackingUserLocation {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }

        // Bölge simgesini güncelle
        updateRegionIcon(for: location)
    }

    // Konum yetkisi değiştiğinde
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if status == .denied || status == .restricted {
            // Konum izni verilmezse kullanıcıya bildirimde bulunun
            let alert = UIAlertController(title: "Konum İzni Gerekli", message: "Navigasyon için konum iznine ihtiyaç var.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }

    // Görsel uyarı
    func showAlert(for target: (location: CLLocation, color: UIColor, icon: String)) {
        let alert = UIAlertController(title: "Uyarı", message: "Riskli Bölgeye Yaklaştınız!", preferredStyle: .alert)
        alert.view.backgroundColor = target.color
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // İşaretleyiciler için görünümleri ayarlama
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "targetLocation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        if let title = annotation.title, let iconName = title {
            if let cachedImage = iconImageCache[iconName] {
                annotationView?.image = cachedImage
            } else {
                if let iconImage = UIImage(named: iconName) {
                    let size = CGSize(width: 30, height: 30) // İstediğiniz boyutları buraya ayarlayın
                    UIGraphicsBeginImageContext(size)
                    iconImage.draw(in: CGRect(origin: .zero, size: size))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    iconImageCache[iconName] = resizedImage
                    annotationView?.image = resizedImage
                }
            }
        }

        return annotationView
    }

    // Butonları ekle
    func setupButtons() {
        let buttonSize: CGFloat = 50
        let buttonMargin: CGFloat = 10

        let locationButton = UIButton(frame: CGRect(x: view.bounds.width - buttonSize - buttonMargin, y: view.bounds.height - 3 * buttonSize - 4 * buttonMargin, width: buttonSize, height: buttonSize))
        locationButton.setImage(UIImage(named: "locationIcon"), for: .normal)
        locationButton.backgroundColor = UIColor.white
        locationButton.layer.cornerRadius = buttonSize / 2
        locationButton.addTarget(self, action: #selector(goToUserLocation), for: .touchUpInside)
        view.addSubview(locationButton)

        let zoomInButton = UIButton(frame: CGRect(x: view.bounds.width - buttonSize - buttonMargin, y: view.bounds.height - 2 * buttonSize - 3 * buttonMargin, width: buttonSize, height: buttonSize))
        zoomInButton.setTitle("+", for: .normal)
        zoomInButton.setTitleColor(UIColor.black, for: .normal)
        zoomInButton.backgroundColor = UIColor.white
        zoomInButton.layer.cornerRadius = buttonSize / 2
        zoomInButton.layer.borderColor = UIColor.lightGray.cgColor
        zoomInButton.layer.borderWidth = 1
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        view.addSubview(zoomInButton)

        let zoomOutButton = UIButton(frame: CGRect(x: view.bounds.width - buttonSize - buttonMargin, y: view.bounds.height - buttonSize - 2 * buttonMargin, width: buttonSize, height: buttonSize))
        zoomOutButton.setTitle("-", for: .normal) // "+" işareti için düzeltilmiş
        zoomOutButton.setTitleColor(UIColor.black, for: .normal)
        zoomOutButton.backgroundColor = UIColor.white
        zoomOutButton.layer.cornerRadius = buttonSize / 2
        zoomOutButton.layer.borderColor = UIColor.lightGray.cgColor
        zoomOutButton.layer.borderWidth = 1
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        view.addSubview(zoomOutButton)
    }

    @objc func zoomIn() {
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(center: currentRegion.center, span: MKCoordinateSpan(latitudeDelta: currentRegion.span.latitudeDelta * 0.5, longitudeDelta: currentRegion.span.longitudeDelta * 0.5))
        mapView.setRegion(newRegion, animated: true)
    }

    @objc func zoomOut() {
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(center: currentRegion.center, span: MKCoordinateSpan(latitudeDelta: currentRegion.span.latitudeDelta * 2.0, longitudeDelta: currentRegion.span.longitudeDelta * 2.0))
        mapView.setRegion(newRegion, animated: true)
    }

    @objc func goToUserLocation() {
        isTrackingUserLocation = true
        if let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }
        locationManager.startUpdatingLocation()
    }

    // Bölge simgesi görüntüleyiciyi oluştur
    func setupRegionIconImageView() {
        let iconSize: CGFloat = 50
        regionIconImageView = UIImageView(frame: CGRect(x: 20, y: 40, width: iconSize, height: iconSize))
        regionIconImageView.contentMode = .scaleAspectFit
        view.addSubview(regionIconImageView)
    }

    // Bölge simgesini güncelle
    func updateRegionIcon(for location: CLLocation) {
        var isInAnyRegion = false
        for target in targetLocations {
            let distance = location.distance(from: target.location)
            if distance < 250 { // 250 metre içinde
                if let iconImage = UIImage(named: target.icon) {
                    regionIconImageView.image = iconImage
                    isInAnyRegion = true
                    break
                }
            }
        }
        
        // Kullanıcı bölgeden çıkarsa simgeyi kaldır
        if !isInAnyRegion {
            regionIconImageView.image = nil
        }
    }
}
