import Foundation
import ImageIO
import CoreLocation
import UniformTypeIdentifiers

struct ImageMetadataUtil {
  /** Read metadata from Data object

  ```
  let metadata = ImageMetadataUtil.extractMetadata(from: data)
  ```

  - Parameters:
    - imageData: Data to read metadata from, assumed to be image file data

  - Returns: Dictionary of metadata
  */
  public static func extractMetadata(from imageData: Data) -> [String: Any]? {
    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
      print("Failed to create image source")
      return nil
    }
    
    // Using index 0 needed to get all the properties, docs aren't helpful.
    guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
      print("Failed to extract image properties")
      return nil
    }
    
    return imageProperties
  }
  
  /** Extract GPS coordinates from metadata dict if present

  - Parameters:
    - metaData: Dictionary of metadata

  - Returns: CLLocationCoordinate2D object of GPS coordinates
  */
  public static func gps(from metaData: [String : Any]) -> CLLocationCoordinate2D? {
    if let gpsDictionary = metaData[kCGImagePropertyGPSDictionary as String] as? [String: Any],
       let latitudeRef = gpsDictionary[kCGImagePropertyGPSLatitudeRef as String] as? String,
       let latitude = gpsDictionary[kCGImagePropertyGPSLatitude as String] as? Double,
       let longitudeRef = gpsDictionary[kCGImagePropertyGPSLongitudeRef as String] as? String,
       let longitude = gpsDictionary[kCGImagePropertyGPSLongitude as String] as? Double {
      
      var coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      
      if latitudeRef == "S" {
        coordinate.latitude *= -1
      }
      
      if longitudeRef == "W" {
        coordinate.longitude *= -1
      }
      
      return coordinate
    }
    
    return nil
  }
  
  /** Write metadata to Data object

  ```
  let updatedImage = ImageMetadataUtil.writeMetadataToImageData(sourceData: data, metadata: metadata)
  ```

  - Parameters:
    - sourceData: Data to read metadata from, assumed to be image file data
    - metadata: Dictionary of metadata to write to image
    - type: UTType of image to write

  - Returns: Data object with updated metadata
  */
  public static func writeMetadataToImageData(sourceData: Data, metadata: [String: Any], type: CFString) -> Data {
    let outputData = NSMutableData() // Create source to read from and destination to update
    guard let imageSource = CGImageSourceCreateWithData(sourceData as CFData, nil),
          let imageDestination = CGImageDestinationCreateWithData(outputData, type, 1, nil)
    else {
      print("Failed to create image source or destination")
      return sourceData
    }
    
    let mutableMetadata = NSMutableDictionary(dictionary: metadata)
    
    // Add existing metadata to preserve it
    if let currentMetadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) {
      mutableMetadata.addEntries(from: currentMetadata as! [AnyHashable: Any])
    }
    
    CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, mutableMetadata)
    
    if CGImageDestinationFinalize(imageDestination) {
      return outputData as Data
    } else {
      print("Failed to write metadata to the image")
      return sourceData
    }
  }
}
