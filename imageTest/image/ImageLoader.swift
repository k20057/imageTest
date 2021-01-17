//
//  ImageLoader.swift
//  imageDemo
//
//  Created by  明智 on 2020/12/21.
//  Copyright © 2020 ming. All rights reserved.
//

import UIKit
import SQLite3
import CommonCrypto
import Foundation

//定義一組下載用的資料模型
struct ImageLoaderModel {
    var url: URL
    var userData: Any? = nil
    var image: UIImage? = nil
}
//定義快取
struct ImageCacheModel {
    var key: String
    var imageData: Data
    var lastTimeUsed: Date
}

class ImageLoader: NSObject {
    var db: SQLiteConnect? = nil
    
    let sqliteURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("cachedb.sqlite")
        } catch {
            fatalError("Error getting file URL from document directory.")
        }
    }()
    
    static let shared = ImageLoader()
    static var maxWidth: CGFloat? = nil
    let maxDownloadNumber = 4 //定義最大同時下載數
    let maxMemoryCache = 8 //定義記憶體快取最多存幾張
    var downloadLists = [ImageLoaderModel]()
    var queueLists =    [ImageLoaderModel]()
    var cacheLists =    [ImageCacheModel]()
   
    
    let dbQueue = DispatchQueue(label: "db")
    func loadImage(url: URL,
                   userData: Any? = nil,
                   completed: @escaping (_ image: UIImage?, _ url: URL, _ userData: Any?) -> Void) {
        //cacheList有圖所以直接取快取裡的圖片，最多8張，超過8張丟棄最久沒讀的那張
        dbQueue.async {
            let reqKey = url.absoluteString.md5
            
            /*
            if !self.cacheLists.isEmpty {
                for data in self.cacheLists {
                    if data.key == reqKey {
                        //data.imageData是Data，轉成UIImage
                        if let image = UIImage(data: data.imageData) {
                            completed(image, url, userData)
                            return
                        }
                    }
                }
            }
            */
            
            //檢查是否有記憶體快取
            if let img = self.checkMemoryCache(key: reqKey){
                completed(img, url, userData)
                return
            }
            
            
            //檢查有沒有資料庫快取
            self.loadImageFromDb(reqKey, url) { [weak self] (image, url, userData) in
                guard let self = self else { return }
                if let image = image {
                    completed(image, url, userData)
                } else {
                    //沒有資料庫快取， 進行網路下載
                    self.downloadImage(url, completed)
                }
            }
        }
    }
    
    func checkMemoryCache(key: String) -> UIImage? {
        if !self.cacheLists.isEmpty {
            for data in self.cacheLists {
                if data.key == key {
                    //data.imageData是Data，轉成UIImage
                    if let image = UIImage(data: data.imageData) {
                        return image
                    }
                }
            }
        }
        return nil
    }
    
    func loadImageFromDb(_ reqKey: String, _ url: URL,userData: Any? = nil, _ completed: @escaping (_ image: UIImage?, _ url: URL, _ userData: Any?) -> Void) {
        let sqlitePath = sqliteURL.path
        db = SQLiteConnect(path: sqlitePath)
        
        //快取沒有圖就從資料庫裡抓 資料庫沒有再下載
        if let mydb = db {
            
            //create
            let _ = mydb.createTable("cache", columnsInfo: [
                                        "key text primary key",
                                        "image blob",
                                        "usedTime integer"])
            
            //load
            let statement = mydb.fetch("cache", cond: "1 == 1", order: nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let loadkey = sqlite3_column_text(statement, 0)
                if loadkey != nil{
                    if String(cString: loadkey!) == reqKey {
                        let length = sqlite3_column_bytes(statement, 1)
                        let bytes = sqlite3_column_blob(statement, 1)
                        let imageData = NSData(bytes: bytes, length: Int(length))
                        
                        let lastTime = Date()
                        let _ = mydb.update("cache", cond: "key = '\(reqKey)'", rowInfo: ["usedTime":"\(Int(lastTime.timeIntervalSince1970))"])
                        
                        sqlite3_finalize(statement)
                        //有讀到圖
                        completed(UIImage(data: imageData as Data)!, url, userData)
                        return
                    }
                }
            }
            sqlite3_finalize(statement)
            
        }
        //沒有讀到圖
        completed(nil, url, userData)
    }
    
    func downloadImage(_ url: URL,userData: Any? = nil, _ completed: @escaping (_ image: UIImage?, _ url: URL, _ userData: Any?) -> Void) {
        //將url和userData包裝成 imageLoaderModel物件
        //downloadImage的count小於4會把url加到downloadImage
        //如果大於等於4就會將url存到queueImage
        let downloadData = ImageLoaderModel(url: url, userData: userData)
        //檢查下載執行緒是否超過限制
        if downloadLists.count < maxDownloadNumber {
            downloadLists.append(downloadData)
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                self.completedImage(downloadData,data, response, completed)
            }
            task.resume()
        } else {
            queueLists.append(downloadData)
        }
    }
    
    func completedImage(_ imageData: ImageLoaderModel, _ data: Data?, _ response: URLResponse?, _ completed: @escaping (_ image: UIImage?, _ url: URL, _ userData: Any?) -> Void) {
        if var data = data, var image = UIImage(data: data) {
            //回傳結果
            let lastTime = Date()
            
            // 如果回傳圖片太大, 先進行縮小
            if let maxWidth = ImageLoader.maxWidth, image.size.width > maxWidth / 2{
                if let newImg = image.resize(CGSize(width: maxWidth, height: maxWidth)) {
                    image = newImg
                }
            }
            
            data = image.jpegData(compressionQuality: 0.8)!
            
            //加到快取
            addToCache(imageData, data, lastTime)
            removeOldCache(image, imageData, response, completed)
            
            //回傳圖片
            completed(image, imageData.url, imageData.userData)

            //下載完了就移除已經下載好的url
            self.downloadLists.removeAll { (imageData) -> Bool in
                return imageData.url == response?.url
            }

            checkNextDownload(completed)
        }
    }
    
    func addToCache(_ imageData: ImageLoaderModel, _ data: Data, _ lastTime: Date){
        let cacheData = ImageCacheModel(key: imageData.url.absoluteString.md5, imageData: data, lastTimeUsed: lastTime)
        self.cacheLists.append(cacheData)
    
        self.saveImageToDb(cacheData.key, cacheData.imageData, Int(cacheData.lastTimeUsed.timeIntervalSince1970))
    }
    
    func saveImageToDb(_ key: String, _ image: Data, _ usedTime: Int) {
        let sqlitePath = sqliteURL.path
        db = SQLiteConnect(path: sqlitePath)
//        print(sqlitePath)
        if let mydb = db {
            
            let _ = mydb.insert("cache",
                                rowInfo: ["key":"'\(key)'", "usedTime":"\(usedTime)"], image)
        }
    }
    
    func removeOldCache(_ image: UIImage, _ imageData: ImageLoaderModel,_ response: URLResponse?,_ completed: @escaping (_ image: UIImage?, _ url: URL, _ userData: Any?) -> Void) {
        if self.cacheLists.count > 8 {
            var minTime = Date().timeIntervalSince1970
            var minCache: ImageCacheModel? = nil
            for cache in self.cacheLists {
                if cache.lastTimeUsed.timeIntervalSince1970 < minTime {
                    minTime = cache.lastTimeUsed.timeIntervalSince1970
                    minCache = cache
                }
            }
            
            self.cacheLists.removeAll { (removeCache) -> Bool in
                return removeCache.key == minCache!.key
            }
        }
    }
    
    func checkNextDownload(_ completed: @escaping (_ image: UIImage?, _ url: URL, _ userData: Any?) -> Void) {
        //檢查是否還有未下載的網址
        //如果queueImage沒有值就中止 代表全都下載完了
        if !self.queueLists.isEmpty {
            //有未下載的，將它移出queue，並呼叫loadImage下載它
            if let qimg = self.queueLists.first {
                //移除queue第一個網址
                self.queueLists.removeFirst()
                //呼叫loadImage去下載第一個網址
                self.loadImage(url: qimg.url, userData: qimg.userData, completed: completed)
            }
            
        } else {
            return
        }
    }
    
    
}


