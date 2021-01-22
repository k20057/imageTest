# ImageTest
## 主旨
從網路上下載圖片需要許多時間，每次重新執行都要重新下載，所以如果能夠把圖片儲存在快取，之後就不必重新下載，直接從快取讀取圖片，節省許多時間。
### 流程
整個流程是會先從記憶體快取讀取資料，沒有資料就從資料庫快取讀取資料，如果還是沒有資料就會從網路下載。下載完圖片會儲存到記憶體快取與資料庫快取。儲存到資料庫時會先將圖片等比例壓縮再儲存。
### 快取
快取分成記憶體快取與資料庫快取。記憶體快取有設儲存上限，超過會刪除最先儲存的快取。記憶體快取部分是自行建立，資料庫快取是使用SQLite。
### 下載
下載分成正在下載佇列與未下載佇列。正在下載佇列有設上限，超過會儲存到未下載佇列，當正在下載完成時會移除下載好的url，再把圖片存到快取，並且檢查記憶體快取有沒有超過上限，有的話移除最早儲存的快取，之後將未下載的url存到正在下載的佇列，並且刪除未下載的url，接著重複一樣的動作，直到正在下載與未下載的數量為0，代表下載完成。
### 其它
讀取快取與下載圖片是在serial佇列執行。
下載完的圖片能夠刪除所有的快取，還有進到下一頁放大圖片與分享圖片。

## 過程
### 起因
做這個最主要的原因是想要有個作品，因此決定做非同步讀圖。並且不使用第三方套件，這非常有挑戰性。

### 規劃
#### 1 下載圖片
從最基本的做起，先照json結構建立model，之後把json轉成model object，解json得到下載的圖片的url，下載圖片放到cell之後，上下滑動會讀到舊的圖片，無法讀到所有的圖片，這是因為cell的reuse機制造成的，
舊的圖還沒讀完滑動後，cell已經換了，但讀圖的沒有取消，等圖讀完去設定就錯了。
#### 2 下載與未下載

#### 3 記憶體快取與資料庫快取，縮小圖片

#### 4 用delegate傳圖到下一頁，scrollview放大圖片，分享圖片與刪除快取

#### 5 多執行緒與資料庫執行緒

#### 6 checkNextDownload
