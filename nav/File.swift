import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var userLocationAnnotation: MKPointAnnotation!

    // Hedef konumlar ve renkler
    let targetLocations = [
        (location: CLLocation(latitude: 40.904255, longitude: 31.175961), color: UIColor.red, icon: "redIcon"),
        (location: CLLocation(latitude: 40.7924144, longitude: 30.7381734), color: UIColor.yellow, icon: "yellowIcon"),
        (location: CLLocation(latitude: 40.6710622, longitude: 30.5837081), color: UIColor.green, icon: "greenIcon")
    ]

    private var iconImageCache = [String: UIImage]()

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
        locationManager.startUpdatingLocation()

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

        // Yakınlaştırma ve uzaklaştırma butonlarını ekle
        setupZoomButtons()
    }

    // Konum güncellemeleri
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

        mapView.setRegion(region, animated: true)

        // Kullanıcı konumu işaretleyicisini güncelle
        userLocationAnnotation.coordinate = center

        // Hedef konumlara olan mesafeyi kontrol et
        for target in targetLocations {
            let distance = location.distance(from: target.location)
            if distance < 100 { // 100 metre içinde
                showAlert(for: target)
            }
        }
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
        // Görsel uyarı
        let alert = UIAlertController(title: "Uyarı", message: "Hedef konuma yaklaştınız!", preferredStyle: .alert)
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

    // Yakınlaştırma ve uzaklaştırma butonlarını ekle
    func setupZoomButtons() {
        let zoomInButton = UIButton(frame: CGRect(x: view.bounds.width - 60, y: view.bounds.height - 120, width: 50, height: 50))
        zoomInButton.setTitle("+", for: .normal)
        zoomInButton.setTitleColor(UIColor.black, for: .normal)
        zoomInButton.backgroundColor = UIColor.white
        zoomInButton.layer.cornerRadius = 25
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        view.addSubview(zoomInButton)

        let zoomOutButton = UIButton(frame: CGRect(x: view.bounds.width - 60, y: view.bounds.height - 60, width: 50, height: 50))
        zoomOutButton.setTitle("-", for: .normal)
        zoomOutButton.setTitleColor(UIColor.black, for: .normal)
        zoomOutButton.backgroundColor = UIColor.white
        zoomOutButton.layer.cornerRadius = 25
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
}
