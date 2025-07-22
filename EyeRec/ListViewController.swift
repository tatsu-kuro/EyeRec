//
//  ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/21.


import UIKit
import Photos
import AssetsLibrary
import CoreMotion

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    let someFunctions = MyFunctions()
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let albumName:String = "iCapNYS"
    var videoCurrentCount:Int = 0
//    var videoDate = Array<String>()
//    var videoPHAsset = Array<PHAsset>()

 //   @IBOutlet weak var how2Button: UIButton!
    
//    @IBOutlet weak var rehaButton: UIButton!
//    @IBOutlet weak var gyroButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    private var videoCnt: [Int] = [] {
        didSet {
            tableView?.reloadData()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    @IBOutlet weak var returnButton: UIButton!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("viewDidLoad*******")
        UserDefaults.standard.set(UIScreen.main.brightness, forKey: "brightness")
        setButtons()
//        someFunctions.getAlbumAssets()//完了したら戻ってくるようにしたつもり
//        someFunctions.videoDate=videoDate
//        someFunctions.videoPHAsset=videoPHAsset
//      for i in 0..<videoDate.count {
//            someFunctions.videoDate.append(videoDate[i])
//            someFunctions.videoPHAsset.append(videoPHAsset[i])
//        }
  

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(foreground(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil
        )
     }
    @objc func foreground(notification: Notification) {
//        print("フォアグラウンド")
    }
    override func viewDidAppear(_ animated: Bool) {
//        print("viewDidAppear*********")
        tableView.reloadData()
        let contentOffsetY = CGFloat(someFunctions.getUserDefaultFloat(str:"contentOffsetY",ret:0))
        DispatchQueue.main.async { [self] in
            self.tableView.contentOffset.y=contentOffsetY
        }
    }
 
    func setButtons(){
        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))/2
        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding
        let sp=ww/120//間隙
        let x0but=view.bounds.width-rightPadding-wh*3/4
        let x1but=x0but+wh/2-wh/40
        let bw=view.bounds.width-x1but-rightPadding-2*sp
        let bh=bw*170/440
        let by=wh-bh-sp
        let by0=topPadding+sp
        someFunctions.setButtonProperty(returnButton, x:x1but, y: by, w: bw, h: bh, UIColor.darkGray,0)

        //以下2行ではRightに設定。leftに変更するときは、infoにもlandscape(left home button)を設定
        let landscapeSide=0//0:right 1:left
        UserDefaults.standard.set(landscapeSide,forKey: "landscapeSide")
        tableView.frame = CGRect(x:leftPadding,y:topPadding+sp,width: x1but-leftPadding-sp*2,height: wh-sp*2)
    }
 
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    
        let contentOffsetY = tableView.contentOffset.y
//        print("offset:",contentOffsetY)
        UserDefaults.standard.set(contentOffsetY,forKey: "contentOffsetY")
    }
    //nuber of cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
        if topEndBlank==0{
            return VideoManager.shared.videoDate.count
        }else{
            return VideoManager.shared.videoDate.count+2
        }
    }
    
    //set data on cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let topEndBlank = 0 // UserDefaults.standard.integer(forKey:"topEndBlank")

        var cellText: String = ""
        let totalCount = VideoManager.shared.videoDate.count

        if topEndBlank == 0 {
            // 行頭番号だけを古い順に昇順でつける
            let number = (totalCount - indexPath.row).description + ")"
            let dateString = VideoManager.shared.videoDate[indexPath.row]
            let duration = Int(VideoManager.shared.videoPHAsset[indexPath.row].duration)
            cellText = number + dateString + " (\(duration)s)"
        } else {
            let number = (totalCount - indexPath.row + 1).description + ")"
            if indexPath.row == 0 || indexPath.row == totalCount + 1 {
                cellText = " "
            } else if indexPath.row - 1 < totalCount {
                let dateString = VideoManager.shared.videoDate[indexPath.row - 1]
                let duration = Int(VideoManager.shared.videoPHAsset[indexPath.row - 1].duration)
                let num = (totalCount - (indexPath.row - 1)).description + ")"
                cellText = num + dateString + " (\(duration)s)"
            } else {
                cellText = " "
            }
        }

        cell.textLabel?.font = UIFont(name: "Courier", size: 24)
        let attributedString = NSMutableAttributedString(string: cellText)
        attributedString.addAttribute(.kern, value: 0, range: NSRange(location: 0, length: attributedString.length))
        cell.textLabel?.attributedText = attributedString
        return cell
    }
    func tableView_old(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell{
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:"cell",for :indexPath)
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
     
        var cellText:String=""
        if topEndBlank == 0 {
            let number = (indexPath.row + 1).description + ")"
            let dateString = VideoManager.shared.videoDate[indexPath.row]
            let duration = Int(VideoManager.shared.videoPHAsset[indexPath.row].duration)
            cellText = number + dateString + "(\(duration)s)"
        } else {
            let number = indexPath.row.description + ")"
            if indexPath.row == 0 || indexPath.row == VideoManager.shared.videoDate.count + 1 {
                cellText = " "
            } else if indexPath.row - 1 < VideoManager.shared.videoDate.count {
                let dateString = VideoManager.shared.videoDate[indexPath.row - 1]
                let duration = Int(VideoManager.shared.videoPHAsset[indexPath.row - 1].duration)
                cellText = number + dateString + "(\(duration)s)"
            } else {
                cellText = " "
            }
        }
        cell.textLabel?.font=UIFont(name:"Courier",size: 24)
        let attributedString = NSMutableAttributedString(string: cellText)
        attributedString.addAttribute(.kern, value: 0, range: NSRange(location: 0, length: attributedString.length)) // 文字間隔を1.5に設定
        cell.textLabel?.attributedText = attributedString
        return cell
    }
    func requestAVAsset(asset: PHAsset)-> AVAsset? {
        guard asset.mediaType == .video else { return nil }
        let phVideoOptions = PHVideoRequestOptions()
        phVideoOptions.version = .original
        let group = DispatchGroup()
        let imageManager = PHImageManager.default()
        var avAsset: AVAsset?
        group.enter()
        imageManager.requestAVAsset(forVideo: asset, options: phVideoOptions) { (asset, _, _) in
            avAsset = asset
            group.leave()
            
        }
        group.wait()
        
        return avAsset
    }
    //play item
//    var contentOffsetY:CGFloat=0
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topEndBlank=0//UserDefaults.standard.integer(forKey:"topEndBlank")
        var indexPathRow = indexPath.row
        if topEndBlank==1{
            if indexPath.row==0 || indexPath.row==VideoManager.shared.videoDate.count+1{
                return
            }else{
             indexPathRow -= 1
            }
        }

        videoCurrentCount=indexPathRow// indexPath.row
//        print("video:",videoCurrentCount)
        let contentOffsetY = tableView.contentOffset.y
//        print("offset:",contentOffsetY)
        UserDefaults.standard.set(contentOffsetY,forKey: "contentOffsetY")
        let phasset = VideoManager.shared.videoPHAsset[indexPathRow]//indexPath.row]
        let avasset = requestAVAsset(asset: phasset)
        if avasset == nil {//なぜ？icloudから落ちてきていないのか？
            return
        }
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
      
        nextView.phasset = VideoManager.shared.videoPHAsset[indexPathRow]// indexPath.row]
        nextView.avasset = avasset
        nextView.calcDate = VideoManager.shared.videoDate[indexPathRow]
        
        self.present(nextView, animated: true, completion: nil)
        
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        print("set canMoveRowAt")
        return false
    }
    //セルの削除ボタンが押された時の処理
 
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row

            VideoManager.shared.deleteAssetFromPhotoLibrary(at: index) { success in
                DispatchQueue.main.async {
                    if success {
                        tableView.reloadData()
                    } else {
                        // デバイスの言語によって表示を切り替え
                        let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false
                        let title = isJapanese ? "削除失敗" : "Delete Failed"
                        let message = isJapanese ? "ビデオの削除に失敗しました。" : "Failed to delete the video."
                        let okTitle = isJapanese ? "OK" : "OK"
                        
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: okTitle, style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
}
