import UIKit
import Photos

struct Photo {
    let thumbnailURL: String
    static let NumberOfSections = 200

    static func constructRemoteElements() -> [[Photo]] {
        var sections = [[Photo]]()

        for section in 1..<Photo.NumberOfSections {
            var elements = [Photo]()
            for row in 1..<10 {
                let photo = Photo(thumbnailURL: "http://placehold.it/300x300&text=image\(section * 10 + row)")
                elements.append(photo)
            }
            sections.append(elements)
        }

        return sections
    }
}
