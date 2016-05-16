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

        if let pointsURL = NSURL(string: "https://raw.githubusercontent.com/mapbox/mapbox-gl-native/1ee14915f8484f22abb59b7ecdb48e197e6dbf38/platform/ios/app/points.geojson") {
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
                                
                             // proportionally sized circles
                            let c = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            let radius:Double = Double(arc4random_uniform(20)) + 100
                            let pt0 = self.polygonCircleForCoordinate(c, withMeterRadius:radius)
                            annotations.append(pt0)
                                
                            // UIImage overlay
                             let pt1 = MGLPointAnnotation()
                              pt1.coordinate = c
                              annotations.append(pt1)
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

    func polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D, withMeterRadius: Double) -> MGLPolygon{
        let degreesBetweenPoints = 8.0
        let numberOfPoints:Int = Int(floor(360.0 / degreesBetweenPoints))
        let distRadians: Double = withMeterRadius / 6371000.0
        let centerLatRadians: Double = coordinate.latitude * M_PI / 180
        let centerLonRadians: Double = coordinate.longitude * M_PI / 180
        var coordinates = [CLLocationCoordinate2D]()
        
        for index in 0..<numberOfPoints {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * M_PI / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / M_PI
            let pointLon: Double = pointLonRadians * 180 / M_PI
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            coordinates.append(point)
        }
 
        
        let polygon = MGLPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
        return polygon
    }
    
    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.5
    }
    
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        // change the colors
        let colorIndex = Int(arc4random_uniform(6))
        let color = [
            UIColor.redColor(),
            UIColor.blueColor(),
            UIColor.greenColor(),
            UIColor.purpleColor(),
            UIColor.magentaColor(),
            UIColor.yellowColor()
            ][colorIndex]
        
        return color
    }
    
    func mapView(mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        //return UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1)
        let colorIndex = Int(arc4random_uniform(6))
        let color = [
            UIColor.redColor(),
            UIColor.blueColor(),
            UIColor.greenColor(),
            UIColor.purpleColor(),
            UIColor.magentaColor(),
            UIColor.yellowColor()
            ][colorIndex]
        
        return color
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
