import SQLite3
import AVFoundation

class SQLiteConnect {
    static let shared = SQLiteConnect(path: sqliteURL.path)
    static let sqliteURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("cachedb.sqlite")
        } catch {
            fatalError("Error getting file URL from document directory.")
        }
    }()
    static let dbQueue = DispatchQueue(label: "db")
    
    var db :OpaquePointer? = nil
    var sqlitePath :String
    
    init?(path :String) {
            sqlitePath = path
            db = openDatabase(sqlitePath)
            print("ccc")
            if db == nil {
                return nil
            }
            
            if db != nil {
                //create
                let _ = createTable("cache", columnsInfo: [
                                        "key text primary key",
                                        "image blob",
                                        "usedTime integer"])
                
            }
    }
    
    // 連結資料庫 connect database
    func openDatabase(_ path :String) -> OpaquePointer? {
        
        var connectdb: OpaquePointer? = nil
        if db != nil {
            print("aaa")
            return db
        }
        sqlite3_shutdown()
        sqlite3_initialize();
        if sqlite3_open_v2(path, &connectdb, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            print("Successfully opened database \(path)")
            return connectdb!
        } else {
            //            print("Unable to open database.")
            return nil
        }
    }
    
    func closeDatabase() {
        if db != nil {
            SQLiteConnect.dbQueue.sync {
                sqlite3_close(db!)
                db = nil
            }
        }
    }
    
    // 建立資料表 create table
    func createTable(_ tableName :String, columnsInfo :[String]) -> Bool {
        
        let sql = "create table if not exists \(tableName) "
            + "(\(columnsInfo.joined(separator: ",")))"
        
        if sqlite3_exec(
            self.db, sql.cString(using: String.Encoding.utf8), nil, nil, nil)
            == SQLITE_OK {
            print("createTable1")
            
            return true
        }
        
        return false
    }
    
    // 新增資料
    func insert(_ tableName :String, rowInfo :[String:String], _ data: Data) -> Bool {
        var statement :OpaquePointer? = nil
        
        let sql = "insert into \(tableName) "
            + "(\(rowInfo.keys.joined(separator: ",")),image) "
            + "values (\(rowInfo.values.joined(separator: ",")),?)"
        
        let imageData = NSData(data: data)
        
        if sqlite3_prepare_v2(
            self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
            == SQLITE_OK {
            
            if sqlite3_bind_blob(statement, 1, imageData.bytes, Int32(imageData.count), nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(statement))
                print("error is \(errmsg)")
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
            sqlite3_finalize(statement)
        }

        return false
    }
    
    // 讀取資料
    func fetch(
        _ tableName :String, cond :String?, order :String?)
    -> OpaquePointer? {
        var statement :OpaquePointer? = nil
        var sql = "select * from \(tableName)"
        if let condition = cond {
            sql += " where \(condition)"
        }
        
        if let orderBy = order {
            sql += " order by \(orderBy)"
        }
        
        sqlite3_prepare_v2(
            self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
        
        return statement
    }
    
    // 更新資料
    func update(
        _ tableName :String, cond :String?, rowInfo :[String:String]) -> Bool {
        var statement :OpaquePointer? = nil
        var sql = "update \(tableName) set "
        
        // row info
        var info :[String] = []
        for (k, v) in rowInfo {
            info.append("\(k) = \(v)")
        }
        
        sql += info.joined(separator: ",")
        
        // condition
        if let condition = cond {
            sql += " where \(condition)"
        }
        
        if sqlite3_prepare_v2(
            self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
            == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
            sqlite3_finalize(statement)
        }
        
        return false
        
    }
    
    // 刪除資料
    func delete(_ tableName :String, cond :String?) -> Bool {
        var statement :OpaquePointer? = nil
        var sql = "delete from \(tableName)"
        
        // condition
        if let condition = cond {
            sql += " where \(condition)"
        }
        
        if sqlite3_prepare_v2(
            self.db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
            == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
            sqlite3_finalize(statement)
        }
        
        return false
    }
    
}
