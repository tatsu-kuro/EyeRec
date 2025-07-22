//
//  PlayViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/22.
//

import UIKit
import AVFoundation
import Photos
import AssetsLibrary
import MessageUI
class PlayViewController: UIViewController{
    let camera = MyFunctions()
    var phasset:PHAsset?
    var avasset:AVAsset?
    var videoPlayer: AVPlayer!
    var duration:Float=0
    var currTime:UILabel?
    var calcDate:String?
    lazy var seekBar = UISlider()
    var timer:Timer?
    var url:URL?
    
    @IBAction func onExitButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    //    @IBOutlet weak var mailAddressInputField: UITextField!
    @IBOutlet weak var paperPlaneButton: UIButton!
    @IBAction func onPaperPlaneButton(_ sender: Any) {
//        mailAddressInputField.endEditing(true)
//        UserDefaults.standard.set(mailAddressInputField.text,forKey: "mailAdress")
        let url = (videoPlayer.currentItem?.asset as? AVURLAsset)?.url
        sendMail(subject: "Movie of iCapNYS",url:url!)//,mailAddress:"")//mailAddressInputField.text!)
    }
    @IBOutlet weak var videoPauseButton: UIButton!
    @IBOutlet weak var videoTopButton: UIButton!
    @IBOutlet weak var videoPlayButton: UIButton!
    
    
    @IBOutlet weak var quitButton: UIButton!
    let someFunctions = MyFunctions()
    override var shouldAutorotate: Bool {
        return false
    }
    @IBAction func onVideoPlayButton(_ sender: Any) {
        if seekBar.value>seekBar.maximumValue-0.5{
        seekBar.value=0
        }
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
        videoPlayer.play()
    }
    
    @IBAction func onVideoTopButton(_ sender: Any) {
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
        }
        seekBar.value=0
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    @IBAction func onVideoPauseButton(_ sender: Any) {
        videoPlayer.pause()
    }
  
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            return UIInterfaceOrientationMask.landscapeRight
        }else{
            return UIInterfaceOrientationMask.landscapeLeft
        }
    }
    
    @objc func update(tm: Timer) {
        let min=Int(seekBar.value/60)
        let sec=Int(seekBar.value)%60
        let dura=Int(duration)
        currTime?.text=String(format:"%d:%02d / %d:%02d",min,sec,dura/60,dura%60)//seekBar.value)
    }
   
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func setButtonProperty(button:UIButton,color:UIColor){
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 5.0
        button.backgroundColor = color
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
    override func viewDidLoad() {
        super.viewDidLoad()
        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let rightPadding=CGFloat(UserDefaults.standard.integer(forKey:"rightPadding"))
        let topPadding=CGFloat(UserDefaults.standard.integer(forKey:"topPadding"))
        let bottomPadding=CGFloat(UserDefaults.standard.integer(forKey:"bottomPadding"))/2
        let ww:CGFloat=view.bounds.width-leftPadding-rightPadding
        let wh:CGFloat=view.bounds.height-topPadding-bottomPadding
        let sp=ww/120//間隙
        let bw=(ww-sp*10)/7//ボタン幅
        let bh=bw*170/440
        let by=wh-bh-sp
        let by1=wh-(bh+sp)*2+1.5*sp
        let x0=leftPadding+sp*2
        duration=Float(phasset!.duration)// Float(CMTimeGetSeconds(avAsset.duration))
        
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avasset!)
        // Create AVPlayer
        videoPlayer = AVPlayer(playerItem: playerItem)
        
//        mailAddressInputField.text=myFunctions().getUserDefaultString(str: "mailAdress", ret: "sample@sample.com")

       url = (videoPlayer.currentItem?.asset as? AVURLAsset)?.url
       // print(url)
        
        // Add AVPlayer
        let layer = AVPlayerLayer()
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        layer.player = videoPlayer
//        print(self.view.bounds,":",view.bounds)
        layer.frame = self.view.bounds
        self.view.layer.addSublayer(layer)
        // Create Movie SeekBar
        seekBar.frame = CGRect(x: x0, y: by1, width: ww - 4*sp, height: bh)
        seekBar.minimumValue = 0
        seekBar.maximumValue = duration
        seekBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        view.addSubview(seekBar)
        // Set SeekBar Interval
        let interval : Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
        // ConvertCMTime
        let time : CMTime = CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC))
        // Observer
        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: {time in
            // Change SeekBar Position
            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
            self.seekBar.value = value
        })

        currTime = UILabel(frame:CGRect(x:x0+bw+sp,y:by,width:bw*2+sp,height:bh))
        currTime!.backgroundColor = UIColor.systemGray6
        currTime!.layer.masksToBounds = true
        currTime!.layer.cornerRadius = 5
        currTime!.textColor = UIColor.black
        currTime!.textAlignment = .center
        currTime!.font=UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
      //  currTime!.layer.borderColor = UIColor.systemGray6.cgColor
      //  currTime!.layer.borderWidth = 1.0
        view.addSubview(currTime!)
        videoPlayer.play()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        camera.setButtonProperty(quitButton,x: x0+6*bw+6*sp, y: by, w:bw , h: bh,UIColor.darkGray,0)
        camera.setButtonProperty(videoPlayButton,x:x0+4*bw+4*sp,y:by,w:bw,h: bh,UIColor.orange,0)
        camera.setButtonProperty(videoTopButton,x: x0+3*bw+3*sp, y: by, w: bw, h: bh,UIColor.orange,0)
        camera.setButtonProperty(videoPauseButton,x: x0+5*bw+5*sp,y:by,w:bw,h: bh,UIColor.orange,0)
        camera.setButtonProperty(paperPlaneButton, x: x0, y: by, w: bw, h: bh, UIColor.darkGray,0)
        view.bringSubviewToFront(quitButton)
        view.bringSubviewToFront(videoTopButton)
        view.bringSubviewToFront(videoPlayButton)
        view.bringSubviewToFront(videoPauseButton)
        view.bringSubviewToFront(paperPlaneButton)
    }

    // SeekBar Value Changed
    @objc func onSliderValueChange(){
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), preferredTimescale: Int32(NSEC_PER_SEC)))
        videoPlayer.pause()
    }
   
}
extension PlayViewController: MFMailComposeViewControllerDelegate {
    
    fileprivate func sendMail(subject: String,url: URL){//},mailAddress:String) {
        
//        let toRecipients = ["to@gmail.com"]
//        let ccRecipients = ["cc@gmail.com"]
//        let bccRecipients = ["Bcc1@gamil.com","Bcc2@gmail.com"]
        
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        
 //       mailViewController.setToRecipients([mailAddress])
//        mailViewController.setCcRecipients(ccRecipients)
//        mailViewController.setBccRecipients(bccRecipients)
        
        //件名・本文
        mailViewController.setSubject(subject)
  //      mailViewController.setMessageBody(message, isHTML: false)
        
        //添付ファイル
        
        //Documentフォルダのパス
        if FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last != nil {
//            print(url)
            // ファイルパス ... ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
            let realmFileName = url//"default.realm"
            let targetFilePath = url//documentDirectoryFileURL.appendingPathComponent(realmFileName)
        
            do {
                //realmファイルの送信
                //TODO: mimeTypeの設定 "text/csv" ? (バイナリフィルの指定がわからない...)
                
                let data = try Data(contentsOf: targetFilePath)
                mailViewController.addAttachmentData(data, mimeType: "realm/binary", fileName:realmFileName.lastPathComponent)// absoluteString)
            } catch {
//                print("error ...")
            }
        }
        
        self.present(mailViewController, animated: true, completion: nil)
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case .sent:
            break
        default:
            break
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

