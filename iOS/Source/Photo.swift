import UIKit
import Photos

class Photo {
    static let NumberOfSections = 500

    let thumbnailURL: String
    var image: UIImage?

    init(thumbnailURL: String) {
        self.thumbnailURL = thumbnailURL
    }

    static func constructRemoteElements() -> [[Photo]] {
        var sections = [[Photo]]()

        for section in 1..<Photo.NumberOfSections {
            var elements = [Photo]()
            for row in 1..<10 {
                let photo = Photo(thumbnailURL: "/300x300&text=image\(section * 10 + row)")
                elements.append(photo)
            }
            sections.append(elements)
        }

        return sections
    }
}
