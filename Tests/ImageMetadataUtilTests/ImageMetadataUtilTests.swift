import XCTest
@testable import ImageMetadataUtil
import CoreLocation

final class ImageMetadataUtilTests: XCTestCase {

  var metadata: [String: Any]!
    
  override func setUp() {
    super.setUp()
    do {
      let url = URL(fileURLWithPath: FileManager().currentDirectoryPath).appendingPathComponent("test_image.jpg")
      let imageData = try Data(contentsOf: url)
      metadata = ImageMetadataUtil.extractMetadata(from: imageData)!
    } catch {
      XCTFail("Failed to load image")
    }
  }

  func testMetadata() throws {
    XCTAssertEqual((metadata["PixelWidth"] as? Int), 240)
  }

  func testGps() throws {
      let gps = ImageMetadataUtil.gps(from: metadata)
      XCTAssertEqual(gps?.latitude, 53.001144445)
      XCTAssertEqual(gps?.longitude, -6.3499083333333335)
  }
}
