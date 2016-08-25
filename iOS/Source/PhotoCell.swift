import UIKit
import Networking

class PhotoCell: UICollectionViewCell {
    static let Identifier = "PhotoCellIdentifier"

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        self.backgroundColor = UIColor.blackColor()
        self.addSubview(self.imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func display(photo: Photo) {
        // Using Networking
        /*
        let (baseURL, path) = Networking.splitBaseURLAndRelativePath(photo.thumbnailURL)
        let networking = Networking(baseURL: baseURL)
        networking.downloadImage(path) { image, error in
            self.imageView.image = image
        }
        */

        // Using NSURLSession
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let url = NSURL(string: photo.thumbnailURL)!
        let task = session.dataTaskWithURL(url) { data, response, error in
            let image = UIImage(data: data!)!
            dispatch_async(dispatch_get_main_queue()) {
                self.imageView.image = image
            }
        }
        task.resume()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
}
