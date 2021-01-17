import UIKit


class ImageEnlargeVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageEnlargeView: UIImageView!
    var largeImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageEnlargeView.image = largeImage
        
        // Do any additional setup after loading the view.
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageEnlargeView
        }
    
    @IBAction func share(_ sender: Any) {
        if let image = imageEnlargeView.image {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            // 顯示出我們的 activityVC。
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}
