//
//  TableViewCell.swift
//  imageDemo
//
//  Created by  明智 on 2020/12/19.
//  Copyright © 2020 ming. All rights reserved.
//

import UIKit

protocol ClickTableViewCellDelegate {
    func clickTableViewCellDidTap(_ sender: ImgurTVCell, data: UIImage)
}

struct PicModel: Codable {
    var pics: [PicItemModel]
}

struct PicItemModel: Codable {
    var name: String
    var url: String
}

class ImgurTVCell: UITableViewCell {
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var imgImgur: UIImageView!
    @IBOutlet weak var labImgur: UILabel!
    
    var imageUrl: URL? = nil
    var delegate: ClickTableViewCellDelegate?
    var data: PicItemModel? = nil {
        didSet {
            loading.startAnimating()
            if let urlStr = data?.url, let url = URL(string: urlStr) {
                labImgur.text = data?.name
                imgImgur.image = nil    //下載前先清空目前顯示的圖
                imageUrl = url
                let load = ImageLoader.shared
                print("要下載的圖片網址: \(url)  self=\(self)")
                load.loadImage(url: url) { (image, imageUrl, userData) in
                    print("下載完成 圖片網址: imageUrl=\(imageUrl) self.imageUrl=\(self.imageUrl) url=\(url) self=\(self)")

                    //檢查讀到的圖跟目前cell有沒有同一個
                    if imageUrl == self.imageUrl {
                        print("下載回來的網址與要顯示的網址一樣")
                        DispatchQueue.main.async {
                            self.loading.stopAnimating()
                            self.imgImgur.image = image
                        }
                        
                    } else {
                        print("----下載回來的網址與要顯示的網址不相符 imageUrl=\(imageUrl) self.imageUrl=\(String(describing: self.imageUrl)) self=\(self)")
                    }
                }
            }
        }
    }
    
    @IBAction func clickButton(_ sender: Any) {
        print("clickButton")
        if let image = self.imgImgur.image {
            delegate?.clickTableViewCellDidTap(self, data: image)
        }
        
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
