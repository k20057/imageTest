//
//  ImgurVC.swift
//  imageDemo
//
//  Created by  明智 on 2020/12/20.
//  Copyright © 2020 ming. All rights reserved.
//

import UIKit
import SQLite3

private let reuseIdentifier = "dataCell"
private let reuseImage = "imagelarge"

class ImgurVC: UIViewController, ClickTableViewCellDelegate {
 
    
    @IBOutlet weak var tableView: UITableView!
    var pics: [PicItemModel]? = nil
    
    let picJsonStr = """
    {"pics":
        [
        {"name":"pic1", "url": "https://i.imgur.com/oSVsPL7.jpg"},
        {"name":"pic2", "url": "https://i.imgur.com/kg0Drit.jpg"},
        {"name":"pic3", "url": "https://i.imgur.com/bWV8uTx.jpg"},
        {"name":"pic4", "url": "https://i.imgur.com/l4YlDtp.jpg"},
        {"name":"pic5", "url": "https://i.imgur.com/C05G66k.jpg"},
        {"name":"pic6", "url": "https://i.imgur.com/hzcaxR0.jpg"},
        {"name":"pic7", "url": "https://i.imgur.com/4HEbvp3.jpg"},
        {"name":"pic8", "url": "https://i.imgur.com/D0skKBt.jpg"},
        {"name":"pic9", "url": "https://i.imgur.com/N40YxkB.jpg"},
        {"name":"pic10","url": "https://i.imgur.com/oCR1OXT.jpg"},
        {"name":"pic11","url": "https://i.imgur.com/P9w28UA.jpg"},
        {"name":"pic12","url": "https://i.imgur.com/brrqBQs.jpg"},
        {"name":"pic13","url": "https://i.imgur.com/hZQ09sg.jpg"},
        {"name":"pic14","url": "https://i.imgur.com/zq4Camx.jpg"},
        {"name":"pic15","url": "https://i.imgur.com/sjVoNAS.jpg"},
        {"name":"pic16","url": "https://i.imgur.com/0qbV0eF.jpg"},
        {"name":"pic17","url": "https://i.imgur.com/s9SawhH.jpg"},
        {"name":"pic18","url": "https://i.imgur.com/grhf3K2.jpg"},
        {"name":"pic19","url": "https://i.imgur.com/Zz28mtL.jpg"},
        {"name":"pic20","url": "https://i.imgur.com/fXH6QHf.jpg"},
        {"name":"pic21","url": "https://i.imgur.com/uNhh96M.jpg"},
        {"name":"pic22","url": "https://i.imgur.com/4Ps2dVm.jpg"},
        {"name":"pic23","url": "https://i.imgur.com/aVW7062.jpg"},
        {"name":"pic24","url": "https://i.imgur.com/9b6zpba.jpg"},
        {"name":"pic25","url": "https://i.imgur.com/zzv0qOp.jpg"},
        {"name":"pic26","url": "https://i.imgur.com/syTr0VP.jpg"},
        {"name":"pic27","url": "https://i.imgur.com/gld5mkP.jpg"},
        {"name":"pic28","url": "https://i.imgur.com/ava0OHv.jpg"},
        {"name":"pic29","url": "https://i.imgur.com/GbqXo0v.jpg"},
        {"name":"pic30","url": "https://i.imgur.com/kGTwUfe.jpg"}
        ]
    }
    """
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = UIScreen.main.bounds.width * 3 / 4
        print("self.tableView.estimatedRowHeight=\(self.tableView.estimatedRowHeight)")
        
        ImageLoader.maxWidth = self.view.frame.width * UIScreen.main.scale

        if let jsonData = picJsonStr.data(using: .utf8) {
            if let photoData = try? JSONDecoder().decode(PicModel.self, from: jsonData) {
                
                self.pics = photoData.pics
                self.tableView.reloadData()
            }
        }
    }

    func clickTableViewCellDidTap(_ sender: ImgurTVCell, data: UIImage) {
        print("clickTableViewCellDidTap data=\(data)")
        let imageLargeVC = self.storyboard?.instantiateViewController(identifier: reuseImage) as! ImageEnlargeVC
         
        imageLargeVC.largeImage = data
        self.navigationController?.pushViewController(imageLargeVC, animated: true)
        
    }
    
    @IBAction func deleteCache(_ sender: Any) {
        let cache = ImageLoader()
        cache.cacheLists.removeAll()
        
        var db: SQLiteConnect? = nil
        
        let sqliteURL: URL = {
            do {
                return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("cachedb.sqlite")
            } catch {
                fatalError("Error getting file URL from document directory.")
            }
        }()
        
        let sqlitePath = sqliteURL.path
        db = SQLiteConnect(path: sqlitePath)
        
        if let mydb = db {
        
            let _ = mydb.delete("cache", cond: "1 == 1")
            
        }
    }
    
}

extension ImgurVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return pics?.count ?? 0
    }
    //設delegate把cell的圖傳到controller再把圖傳到下一頁
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ImgurTVCell
        
        let pic = pics![indexPath.row]
        cell.data = PicItemModel(name: pic.name, url: pic.url)
        cell.delegate = self
        print(" cellForRowAt indexPath:\(indexPath) cell.data=\(String(describing: cell.data))")
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

