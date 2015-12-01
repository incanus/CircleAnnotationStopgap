import UIKit
import Mapbox

class ViewController: UIViewController, MGLMapViewDelegate {

    typealias JSON = Dictionary<String, AnyObject>

    var map: MGLMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        map = MGLMapView(frame: view.bounds)
        map.delegate = self
        view.addSubview(map)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let pointsURL = NSURL(string: "https://git.io/vB57T") {
            NSURLSession.sharedSession().dataTaskWithURL(pointsURL, completionHandler: {
                [unowned self] maybeFeaturesData, response, maybeFeaturesError in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    [unowned self] in
                    if let featuresData = maybeFeaturesData,
                      let featuresJSON = try? NSJSONSerialization.JSONObjectWithData(featuresData, options: []) as? JSON,
                      let features = featuresJSON?["features"] as? [JSON] {
                        var annotations = [MGLAnnotation]()
                        for i in 0..<50 {
                            let feature = features[i]
                            if let geometry = feature["geometry"] as? JSON,
                              let coordinates = geometry["coordinates"] as? [Double] {
                              let lon = coordinates[0]
                              let lat = coordinates[1]
                              let point = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                let circle = MGLPointAnnotation()
                                circle.coordinate = point
                                annotations.append(circle)
                            }
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            self.map.addAnnotations(annotations)
                            if let annotations = self.map.annotations {
                                self.map.showAnnotations(annotations, animated: false)
                            }
                        }
                    }
                }
            }).resume()
        }
    }

    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        let radius = Int(arc4random_uniform(20)) + 10
        let colorIndex = Int(arc4random_uniform(6))
        let color = [
            UIColor.redColor(),
            UIColor.blueColor(),
            UIColor.greenColor(),
            UIColor.purpleColor(),
            UIColor.magentaColor(),
            UIColor.yellowColor()
        ][colorIndex]
        let identifier = "circle-\(radius)-\(color.description)"
        if let image = mapView.dequeueReusableAnnotationImageWithIdentifier(identifier) {
            return image
        } else {
            let image = circleImageWithRadius(radius, color: color)
            return MGLAnnotationImage(image: image, reuseIdentifier: identifier)
        }
    }

    func circleImageWithRadius(radius: Int, color: UIColor) -> UIImage {
        let buffer = 2
        let rect = CGRect(x: 0, y: 0, width: radius * 2 + buffer, height: radius * 2 + buffer)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.colorWithAlphaComponent(0.25).CGColor)
        CGContextSetStrokeColorWithColor(context, color.colorWithAlphaComponent(0.75).CGColor)
        CGContextSetLineWidth(context, 1)
        CGContextFillEllipseInRect(context, CGRectInset(rect, CGFloat(buffer * 2), CGFloat(buffer * 2)))
        CGContextStrokeEllipseInRect(context, CGRectInset(rect, CGFloat(buffer * 2), CGFloat(buffer * 2)))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
