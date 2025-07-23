//
//  MainViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/22.
//

import UIKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
import VideoToolbox
import CoreML
import AssetsLibrary

extension UIColor {
    func image(size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill() // 色を指定
            rendererContext.fill(.init(origin: .zero, size: size)) // 塗りつぶす
        }
    }
}

class MainViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVAudioPlayerDelegate  {
    let camera = MyFunctions()
    var cameraType:Int = 0
 //   var cropType:Int = 0
    @IBOutlet weak var explanationLabel: UILabel!
    var tempURL:String=""

    @IBOutlet weak var zoomBack: UILabel!
    @IBOutlet weak var exposeBack: UILabel!
    @IBOutlet weak var focusBack: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    func requestAVAssetAsync(asset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        guard asset.mediaType == .video else {
            completion(nil)
            return
        }
        
        let phVideoOptions = PHVideoRequestOptions()
        phVideoOptions.version = .original
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: phVideoOptions) { (asset, _, _) in
            completion(asset)
        }
    }
    
    func requestPhotoLibraryPermissionAndLoadVideos() {
        // iOS 14 以降：ユーザーのアクセス状態を確認
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch currentStatus {
        case .authorized, .limited:
            // ✅ アクセスが許可されている → ビデオ読み込み
            loadVideosFromICapAlbum()
            
        case .notDetermined:
            // 🟡 初回起動：アクセス許可をリクエスト
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    self.loadVideosFromICapAlbum()
                } else {
                    self.showPermissionAlert()
                }
            }
            
        default:
            // ❌ 拒否されている
            showPermissionAlert()
        }
    }
    
    func loadVideosFromICapAlbum() {
        VideoManager.shared.loadVideosFromAlbum(albumName: "iCapNYS") {
            DispatchQueue.main.async {
                //                    print("ビデオ配列ロード完了：", VideoManager.shared.videoDate)
                self.setPlayButtonImage()
                // 必要なら次の画面へ遷移や tableView.reloadData() など
            }
        }
    }
    
    func showPermissionAlert() {
        DispatchQueue.main.async {
            let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false
            let title = isJapanese ? "写真へのアクセスが必要です" : "Photo Access Needed"
            let message = isJapanese
            ? "このアプリは写真ライブラリにアクセスしてビデオを管理します。設定からアクセスを許可してください。"
            : "This app needs access to your photo library to manage videos. Please allow access in Settings."
            
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: isJapanese ? "設定を開く" : "Open Settings", style: .default, handler: { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }))
            
            alert.addAction(UIAlertAction(title: isJapanese ? "キャンセル" : "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    
    
    func thumnailImageForAvasset(asset:AVAsset) -> UIImage?{
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let thumnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1,timescale: 60), actualTime: nil)
            //            print("サムネイルの切り取り成功！")
            return UIImage(cgImage: thumnailCGImage, scale: 0, orientation: .up)
        }catch let err{
            //            print("エラー\(err)")
        }
        return nil
    }
    
    func setPlayButtonImage() {
        guard !VideoManager.shared.videoPHAsset.isEmpty else { return }
        
        let phasset = VideoManager.shared.videoPHAsset[0]
        requestAVAssetAsync(asset: phasset) { avasset in
            guard let avasset = avasset else { return }
            if let image = self.thumnailImageForAvasset(asset: avasset) {
                DispatchQueue.main.async {
                    self.playButton.setImage(image, for: .normal)
                }
            }
        }
    }
    
    @IBAction func onPlayButton(_ sender: UIButton) {
        guard !VideoManager.shared.videoPHAsset.isEmpty else { return }
        
        let phasset = VideoManager.shared.videoPHAsset[0]
        requestAVAssetAsync(asset: phasset) { avasset in
            guard let avasset = avasset else { return }
            
            DispatchQueue.main.async {
                let storyboard: UIStoryboard = self.storyboard!
                let nextView = storyboard.instantiateViewController(withIdentifier: "playView") as! PlayViewController
                nextView.phasset = phasset
                nextView.avasset = avasset
                nextView.calcDate = VideoManager.shared.videoDate[0]
                self.stopMotionUpdates()
                self.present(nextView, animated: true, completion: nil)
            }
        }
    }
    let albumName:String = "iCapNYS"
    var recordingFlag:Bool = false
    var saved2album:Bool = false
    var setteiMode:Int = 0//0:camera, 1:setteimanual, 2:setteiauto
    var autoRecordMode:Bool = false
    let motionManager = CMMotionManager()
    //  var explanationLabeltextColor:UIColor=UIColor.systemGreen
    
    @IBOutlet weak var previewSwitch: UISwitch!
    
    @IBAction func onPreviewSwitch(_ sender: Any) {
        if previewSwitch.isOn==true{
            UserDefaults.standard.set(1, forKey: "previewOn")
        }else{
            UserDefaults.standard.set(0, forKey: "previewOn")
        }
        setButtonsDisplay()
    }
    
    @IBOutlet weak var previewLabel: UILabel!
    //for video input
    var captureSession: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    
    //for video output
    var fileWriter: AVAssetWriter!
    var fileWriterInput: AVAssetWriterInput!
    var fileWriterAdapter: AVAssetWriterInputPixelBufferAdaptor!
    var startTimeStamp:Int64 = 0
    
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    var newFilePath: String = ""
    var iCapNYSWidth: Int32 = 0
    var iCapNYSHeight: Int32 = 0
    var iCapNYSWidthF: CGFloat = 0
    var iCapNYSHeightF: CGFloat = 0
    var iCapNYSWidthF120: CGFloat = 0
    var iCapNYSHeightF5: CGFloat = 0
    var iCapNYSFPS: Float64 = 0
    //for gyro and face drawing
    var gyro = Array<Double>()
    let someFunctions = MyFunctions()
    override var shouldAutorotate: Bool {
        return false
    }
    func stopMotionUpdates() {
#if DEBUG
        print("🛑 motionManager を停止")
#endif
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        if motionManager.isGyroAvailable {
            motionManager.stopGyroUpdates()
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.stopMagnetometerUpdates()
        }
        
        timer?.invalidate()
        timer = nil
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //        if segue.identifier == "showDetail" {
        //            let destinationVC = segue.destination as! DetailViewController
        //            destinationVC.message = "こんにちは、ViewController!"
        //        }
        //        print("prepared",segue)
        stopMotionUpdates()
        //        motionManager.stopDeviceMotionUpdates()
#if DEBUG
        print("prepared",segue)
#endif
    }
    @IBAction func unwindAction(segue: UIStoryboardSegue) {
 
        if segue.source is ListViewController{
            startMotionUpdates()
            setPlayButtonImage()
        }
        UIScreen.main.brightness = CGFloat(UserDefaults.standard.double(forKey: "brightness"))
        UIApplication.shared.isIdleTimerDisabled = false//スリープする.監視する
        recordingFlag=false
        setButtonsDisplay()
        onCameraChange(0,focusChange: false)
        helpButton.isHidden=false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            return UIInterfaceOrientationMask.landscapeRight
        }else{
            return UIInterfaceOrientationMask.landscapeLeft
        }
    }
    var quater0:Double=0
    var quater1:Double=0
    var quater2:Double=0
    var quater3:Double=0
    //    var readingFlag = false
    var timer:Timer?
    var tapFlag:Bool=false//??
    var flashFlag=false

    
    @IBOutlet weak var listButton: UIButton!
//    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var focusLabel: UILabel!
    @IBOutlet weak var focusBar: UISlider!
    @IBOutlet weak var focusValueLabel: UILabel!
    
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var zoomValueLabel: UILabel!
    @IBOutlet weak var zoomBar: UISlider!
    
    @IBOutlet weak var exposeValueLabel: UILabel!
    @IBOutlet weak var exposeLabel: UILabel!
    @IBOutlet weak var exposeBar: UISlider!

    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var currentTime: UILabel!
//    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var quaternionView: UIImageView!
    @IBOutlet weak var cameraView:UIImageView!
//    @IBOutlet weak var cameraTypeLabel: UILabel!
    @IBOutlet weak var whiteView: UIImageView!
    
//    @IBOutlet weak var cameraChangeButton: UIButton!
    
    func setZoom(level:Float){//0.0-0.1
        zoomBar.value=level
#if DEBUG
        print("setZoom*****:",level)
#endif
        if let device = videoDevice {
            zoomValueLabel.text=(Int(level*1000)).description
            
            do {
                try device.lockForConfiguration()
                device.ramp(
                    toVideoZoomFactor: (device.minAvailableVideoZoomFactor) + CGFloat(level) * ((device.maxAvailableVideoZoomFactor) - (device.minAvailableVideoZoomFactor)),
                    withRate: 30.0)
                device.unlockForConfiguration()
            } catch {
#if DEBUG
                print("Failed to change zoom.")
#endif
            }
        }
    }
    var focusChangeable:Bool=true
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
        focusChangeable=false
        if let device = videoDevice{
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                //                print("focus_supported")
                focusValueLabel.text=(Int(focus*100)).description
                
                do {
                    try device.lockForConfiguration()
                    device.focusMode = .locked
                    device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            device.unlockForConfiguration()
                        })
                    })
                    device.unlockForConfiguration()
                    focusChangeable=true
                }
                catch {
                    // just ignore
                    //                    print("focuserror")
                }
            }else{
                //                print("focus_not_supported")
            }
        }
    }
 
    
    func killTimer(){
        if timer?.isValid == true {
            timer!.invalidate()
        }
    }
    
    
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    var leftPadding:CGFloat=0
    var rightPadding:CGFloat=0
    var topPadding:CGFloat=0
    var bottomPadding:CGFloat=0
    var realWinWidth:CGFloat=0
    var realWinHeight:CGFloat=0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
#if DEBUG
        print("viewDidLayoutSubviews*******")
#endif
        //        if #available(iOS 11.0, *) {iPhone6以前は無視する。
        // viewDidLayoutSubviewsではSafeAreaの取得ができている
        let topPadding = self.view.safeAreaInsets.top
        let bottomPadding = self.view.safeAreaInsets.bottom
        let leftPadding = self.view.safeAreaInsets.left
        let rightPadding = self.view.safeAreaInsets.right
        UserDefaults.standard.set(topPadding,forKey: "topPadding")
        UserDefaults.standard.set(bottomPadding,forKey: "bottomPadding")
        UserDefaults.standard.set(leftPadding,forKey: "leftPadding")
        UserDefaults.standard.set(rightPadding,forKey: "rightPadding")
    }
    func getPaddings(){
        leftPadding = camera.getUserDefaultCGFloat(str: "leftPadding", ret: 0)
        rightPadding = camera.getUserDefaultCGFloat(str: "rightPadding", ret: 0)
        topPadding = camera.getUserDefaultCGFloat(str: "topPadding", ret: 0)
        bottomPadding = camera.getUserDefaultCGFloat(str: "bottomPadding", ret: 0)
        realWinWidth=view.bounds.width-leftPadding-rightPadding
        realWinHeight=view.bounds.height-topPadding-bottomPadding/2
    }
 
    @IBAction func onFocusBarTouchUpInside(_ sender: Any) {
        if cameraType==0 || cameraType==4{
            explanationLabel.isHidden=false
            setZoom(level: Float(zoomValue))
            onCameraChange(0,focusChange: false)
              if cameraType==0{
                previewLabel.isHidden=false
                previewSwitch.isHidden=false
                startStopButton.alpha=1.0
            }
        }
    }
    @IBAction func onFocusBarTouchDown(_ sender: Any) {
        if cameraType==0{
            onCameraChange(0,focusChange: true)
            //        initSession(fps: 60,focusChange:true)
            previewLabel.isHidden=true
            previewSwitch.isHidden=true
            explanationLabel.isHidden=true
            startStopButton.alpha=0
        }
    }
    func resetTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
#if DEBUG
            print("⚠️ トーチのリセットに失敗しました")
#endif
        }
    }

    @IBAction func onFocusBarChanged(_ sender: UISlider) {
        setFocus(focus:focusBar.value)
        UserDefaults.standard.set(focusBar.value, forKey: "focusValue_front")
    }

    var screenUpDown:Bool=false
    var screenUpDownLatest:Bool=false
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 100.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            let quat = motion.attitude.quaternion
            
            if !self.didCreateAlbumAfterAuthorization,
               PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized {
                MyFunctions().ensureAlbumExists { success in
                    if success {
                        print("✅ Album confirmed or created.")
                    } else {
                        print("❌ Failed to create album.")
                    }
                }
                self.didCreateAlbumAfterAuthorization = true
                self.setButtonsDisplay()
            }
            
            let landscapeSide = someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
            if landscapeSide == 0 {
                self.quater0 = quat.w
                self.quater1 = -quat.y
                self.quater2 = -quat.z
                self.quater3 = quat.x
            } else {
                self.quater0 = quat.w
                self.quater1 = quat.y
                self.quater2 = -quat.z
                self.quater3 = -quat.x
            }
//下記５行、これは何かわからないので削除、大丈夫かな。20250606
//            if self.degreeAtResetHead == -1 {
//                self.degreeAtResetHead = (self.cameraType != 0 && self.cameraType != 4)
//                ? (motion.gravity.z > 0 ? 1 : 0)
//                : (motion.gravity.z > 0 ? 0 : 1)
//            }
//
            screenUpDown=motion.gravity.z<0 ? true : false
            let elapsed = CFAbsoluteTimeGetCurrent() - self.timerCntTime
            let currentInt = Int(elapsed)
            if currentInt != self.lastTimeInt {
                self.currentTime.text = String(format: "%01d:%02d", currentInt / 60, currentInt % 60)
                self.lastTimeInt = currentInt
            }
            //              self.updateHeadFrom(quat: quat)
        }
       //ここでscreenが上か下かチェックしてdrawHead()で頭を回転させる。
         screenUpDownLatest=screenUpDown
    }

    override func viewDidLoad() {
        super.viewDidLoad()
 
        getPaddings()
        setteiMode=1
        autoRecordMode=false
        
        requestPhotoLibraryPermissionAndLoadVideos()
//        frontCameraMode=someFunctions.getUserDefaultInt(str: "frontCameraMode", ret: 0)
//        getCameras()
//        cameraType = camera.getUserDefaultInt(str: "cameraType", ret: 0)
        cameraType = 0
        if getUserDefault(str: "previewOn", ret: 0) == 0{
            previewSwitch.isOn=false
        }else{
            previewSwitch.isOn=true
        }
        setPreviewLabel()
        
        set_rpk_ppk()
        startMotionUpdates()
        initSession(fps: 60,focusChange: false)//遅ければ30fpsにせざるを得ないかも、30fpsだ！
        //露出はオートの方が良さそう
//        LEDBar.minimumValue = 0
//        LEDBar.maximumValue = 1
//        LEDBar.addTarget(self, action: #selector(onLEDValueChange), for: UIControl.Event.valueChanged)
//        LEDBar.value=UserDefaults.standard.float(forKey: "")
//        if cameraType != 0 && cameraType != 4{
//            LEDBar.value=UserDefaults.standard.float(forKey: "ledValue")
//        }
        focusBar.minimumValue = 0
        focusBar.maximumValue = 1.0
        focusBar.value=camera.getUserDefaultFloat(str: "focusValue_front", ret: 0)
        setFocus(focus:focusBar.value)

        exposeValue=exposeValue//getDefaultしてその値をsetする。setでsetExposeしそこでexposeValue表示
        currentTime.isHidden=true
          setButtonsLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            setZoom(level: camera.getUserDefaultFloat(str: "zoomValue_front", ret: 0.0))
            exposeValue=exposeValue//.getでgetDefaultしてその値を.setする。.setでsetExposeしそこでexposeValue表示
        }
        zoomBar.minimumValue = 0
        zoomBar.maximumValue = 0.02
        zoomBar.addTarget(self, action: #selector(onZoomValueChange), for: UIControl.Event.valueChanged)
        setZoom(level: camera.getUserDefaultFloat(str: "zoomValue_front", ret: 0.0))
        
        exposeBar.minimumValue = Float(videoDevice!.minExposureTargetBias)/2.0
        exposeBar.maximumValue = Float(videoDevice!.maxExposureTargetBias)
        exposeBar.addTarget(self, action: #selector(onExposeValueChange), for: UIControl.Event.valueChanged)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startMotionUpdates()
        }
    }
    
    @objc func onExposeValueChange(){//setteiMode==0 record, 1:manual 2:auto
        exposeValue=CGFloat(exposeBar.value)
    }
    
    var zoomValue: CGFloat = 0.0 // 初期値（0.0 ~ 1.0 の間）

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        UIApplication.shared.isIdleTimerDisabled = false  // この行
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = false//スリープする.監視する
        startMotionUpdates()
        setFocus(focus:focusBar.value)

        // 👇 これを追加！
        setButtonsDisplay()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    @objc func onZoomValueChange(){
        UserDefaults.standard.set(zoomBar.value, forKey: "zoomValue_front")
     
        setZoom(level: zoomBar.value)
    }
    
    var timerCnt:Int=0
    var lastTimeInt:Int=0
    // 旧：var autholizedFlag:Bool=false
    private var didCreateAlbumAfterAuthorization = false
    
    var rpk1 = Array(repeating: CGFloat(0), count:500)
    var ppk1 = Array(repeating: CGFloat(0), count:500)//144*3
    
    let facePoints: [Int] = {
        let horizon = stride(from: 0, through: 360, by: 15).flatMap { [Int($0), 0, 0] } + [360, 0, 1]
        let vertical = stride(from: 0, through: 360, by: 15).flatMap { [0, Int($0), 0] } + [0, 360, 1]
        let coronal = stride(from: 0, through: 360, by: 15).flatMap { [Int($0), 90, 0] } + [360, 90, 1]
        let hairRight = stride(from: -90, through: -180, by: -15).flatMap { [20, $0, 0] } + [20, -180, 1]
        let hairLeft  = stride(from: -90, through: -180, by: -15).flatMap { [-20, $0, 0] } + [-20, -180, 1]
        let hairFarRight = stride(from: -90, through: -180, by: -15).flatMap { [40, $0, 0] } + [40, -180, 1]
        let hairFarLeft  = stride(from: -90, through: -180, by: -15).flatMap { [-40, $0, 0] } + [-40, -180, 1]
        
        let rightEye = [23,-9,0, 31,-12,0, 38,-20,0, 40,-31,0, 38,-41,0, 31,-46,0, 23,-45,0, 15,-39,0, 10,-32,0, 8,-23,0, 10,-16,0, 15,-10,0, 23,-9,1]
        let leftEye  = [-23,-9,0, -31,-12,0, -38,-20,0, -40,-31,0, -38,-41,0, -31,-46,0, -23,-45,0, -15,-39,0, -10,-32,0, -8,-23,0, -10,-16,0, -15,-10,0, -23,-9,1]
        let rightEyeDots = [22,-26,0, 23,-25,0, 24,-24,1]
        let leftEyeDots  = [-22,-26,0, -23,-25,0, -24,-24,1]
        let mouth = [-19,32,0, -14,31,0, -9,31,0, -4,31,0, 0,30,0, 4,31,0, 9,31,0, 14,31,0, 19,32,1]
        
        return horizon + vertical + coronal + hairRight + hairLeft + hairFarRight + hairFarLeft + rightEye + leftEye + rightEyeDots + leftEyeDots + mouth
    }()
    func set_rpk_ppk() {
        let faceRadius: CGFloat = 40
        let frontBackOffset = 180
        let count = facePoints.count / 3
        
        for i in 0..<count {
            let angleX = CGFloat(facePoints[i * 3])
            let angleY = CGFloat(facePoints[i * 3 + 1] + frontBackOffset)
            
            let radX = angleX * .pi / 180
            let radY = angleY * .pi / 180
            
            rpk1[i * 2] = radX
            rpk1[i * 2 + 1] = radY
            
            // Set initial point (0, faceRadius, 0)
            ppk1[i * 3] = 0
            ppk1[i * 3 + 1] = faceRadius
            ppk1[i * 3 + 2] = 0
        }
        
        for i in 0..<count {
            // Rotation around X axis
            let sinX = sin(rpk1[i * 2]), cosX = cos(rpk1[i * 2])
            let dy1 = ppk1[i * 3 + 1] * cosX - ppk1[i * 3 + 2] * sinX
            let dz1 = ppk1[i * 3 + 1] * sinX + ppk1[i * 3 + 2] * cosX
            ppk1[i * 3 + 1] = dy1
            ppk1[i * 3 + 2] = dz1
            
            // Rotation around Z axis
            let sinZ = sin(rpk1[i * 2 + 1]), cosZ = cos(rpk1[i * 2 + 1])
            let dx2 = ppk1[i * 3] * cosZ - ppk1[i * 3 + 1] * sinZ
            let dy2 = ppk1[i * 3] * sinZ + ppk1[i * 3 + 1] * cosZ
            ppk1[i * 3] = dx2
            ppk1[i * 3 + 1] = dy2
            
            // Rotation around Y axis (90 deg)
            let sinY: CGFloat = 1.0, cosY: CGFloat = 0.0
            let dx3 = ppk1[i * 3] * cosY + ppk1[i * 3 + 2] * sinY
            let dz3 = -ppk1[i * 3] * sinY + ppk1[i * 3 + 2] * cosY
            ppk1[i * 3] = dx3
            ppk1[i * 3 + 2] = dz3
        }
    }
    
    //モーションセンサーをリセットするときに-1とする。リセット時に-1なら,角度から０か１をセット
//    var degreeAtResetHead:Int=0//0:-90<&&<90 1:<-90||>90 -1:flag for get degree
    
    func drawHead(width: CGFloat, height: CGFloat, radius: CGFloat, qOld0: CGFloat, qOld1: CGFloat, qOld2: CGFloat, qOld3: CGFloat) -> UIImage {
        let faceCenter = CGPoint(x: width / 2, y: height / 2)
        let defaultRadius: CGFloat = 40.0
        let contextSize = CGSize(width: width, height: height)
        var rotatedPoints = Array(repeating: CGFloat(0), count: facePoints.count)
        
        for i in 0..<(facePoints.count / 3) {
            let x0 = ppk1[i * 3]
            let y0 = ppk1[i * 3 + 1]
            let z0 = -ppk1[i * 3 + 2]
            
            var q0 = qOld0, q1 = qOld1, q2 = qOld2, q3 = qOld3
            let mag = sqrt(q0*q0 + q1*q1 + q2*q2 + q3*q3)
            if mag > CGFloat(Float.ulpOfOne) {
                let norm = 1 / mag
                q0 *= norm; q1 *= norm; q2 *= norm; q3 *= norm
            }
            
            let rx = x0 * (q0*q0 + q1*q1 - q2*q2 - q3*q3) + y0 * (2 * (q1*q2 - q0*q3)) + z0 * (2 * (q1*q3 + q0*q2))
            let ry = x0 * (2 * (q1*q2 + q0*q3)) + y0 * (q0*q0 - q1*q1 + q2*q2 - q3*q3) + z0 * (2 * (q2*q3 - q0*q1))
            let rz = x0 * (2 * (q1*q3 - q0*q2)) + y0 * (2 * (q2*q3 + q0*q1)) + z0 * (q0*q0 - q1*q1 - q2*q2 + q3*q3)
            
            rotatedPoints[i * 3] = rx
            rotatedPoints[i * 3 + 1] = ry
            rotatedPoints[i * 3 + 2] = rz
        }
        
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 1.0)
        
        let path = UIBezierPath(arcCenter: faceCenter, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        UIColor.white.setFill()
        path.fill()
        
        let backThreshold = radius / defaultRadius
        var moveToNext = true
        
        for i in 0..<(facePoints.count / 3 - 1) {
            let x = rotatedPoints[i * 3] * radius / defaultRadius
            let y = rotatedPoints[i * 3 + 2] * radius / defaultRadius
            let behind = rotatedPoints[i * 3 + 1] < backThreshold

            let xSign: CGFloat = screenUpDownLatest ? 1 : -1
            let ySign: CGFloat = screenUpDownLatest ? -1 : 1
            let point = CGPoint(x: faceCenter.x + x * xSign, y: faceCenter.y + y * ySign)
            if moveToNext || behind {
                path.move(to: point)
                moveToNext = false
            } else {
                path.addLine(to: point)
            }
            
            if facePoints[i * 3 + 2] == 1 {
                moveToNext = true
            }
        }
        
        UIColor.black.setStroke()
        path.lineWidth = 2.0
        path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    // captureOutput(_:didOutput:from:) の中で以下のように呼び出す
    
    func setVideoFormat(desiredFps: Double)->Bool {
        var retF:Bool=false
        //desiredFps 60
        // 取得したフォーマットを格納する変数
        var selectedFormat: AVCaptureDevice.Format! = nil
        // そのフレームレートの中で一番大きい解像度を取得する
        // フォーマットを探る
        for format in videoDevice!.formats {
            // フォーマット内の情報を抜き出す (for in と書いているが1つの format につき1つの range しかない)
            for _: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                let width = dimensions.width
                //                print(dimensions.width,dimensions.height)
                //                if range.maxFrameRate == desiredFps && width == 1280{
                if  width == 1280{
                    selectedFormat = format//最後のformat:一番高品質
                    //                    print(range.maxFrameRate,dimensions.width,dimensions.height)
                }
            }
        }
        //ipod touch 1280x720 1440*1080
        //SE 960x540 1280x720 1920x1080
        //11 192x144 352x288 480x360 640x480 1024x768 1280x720 1440x1080 1920x1080 3840x2160
        //1280に設定すると上手く行く。合成のところには1920x1080で飛んでくるようだ。？
        // フォーマットが取得できていれば設定する
        if selectedFormat != nil {
            //            print(selectedFormat.description)
            do {
                try videoDevice!.lockForConfiguration()
                videoDevice!.activeFormat = selectedFormat
                //                videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.unlockForConfiguration()
                
                let description = selectedFormat.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                iCapNYSWidth = dimensions.width
                iCapNYSHeight = dimensions.height
              //  if cameraType == 0{//訳がわからないがこれで上手くいく、反則行為
                    iCapNYSHeight=720
            //    }
                iCapNYSFPS = desiredFps
#if DEBUG
                print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(iCapNYSWidth) px x \(iCapNYSHeight) px")
#endif
                iCapNYSWidthF=CGFloat(iCapNYSWidth)
                iCapNYSHeightF=CGFloat(iCapNYSHeight)
                iCapNYSWidthF120=iCapNYSWidthF/120//quaterの表示開始位置
                iCapNYSHeightF5=iCapNYSHeightF/5//quaterの表示サイズ
                retF=true
            }
            catch {
                //                print("フォーマット・フレームレートが指定できなかった")
                retF=false
            }
        }
        else {
#if DEBUG
            print("指定のフォーマットが取得できなかった")
#endif
            retF=false
        }
        return retF
    }

    let camerasIsUltraWide : Array<Int> = [0,4,1,3,0,4,1]//without wifi
    let camerasNoUltraWide : Array<Int> = [0,4,1,0,4,1,0]//without wifi
    //    let camerasIsUltraWide : Array<Int> = [0,4,1,3,5,0,4,1]
    //    let camerasNoUltraWide : Array<Int> = [0,4,1,5,0,4,1,5]
    func cameraChange(_ cameraType:Int,incDec: Int)->Int{
        var type = cameraType
        //WiFiCamera使用しないときは上のcamerasIs?????:Arrayを変更し、下記３行を追加、
      
  
            return 0
      
    }
    //"frontCam:","wideAngleCam:","telePhotoCam","ultraWideCam:","frontCamWithVideo","wifiCam"
//    let cameraTypeStrings : Array<String> = ["フロント\nカメラ\n\n","背面\nカメラ1\n\n","teleP","背面\nカメラ2\n\n","解説付\n自動90秒\n\n","WiFi\nカメラ\n\n"]
//    let cameraTypeStringsE : Array<String> = ["Front\nCamera\n\n","Back\nCamera1\n\n","teleP","Back\nCamera2\n\n","with Video\nAuto90s\n\n","WiFi\nCamera\n\n"]
    
//    let explanationStrings : Array<String> = ["\n画面中央のボタンでも\n録画開始・録画終了できます\n\n録画中、録画終了ボタンは薄く表示されます","","telePhoto","","\n画面中央のボタンでも\n録画開始・解説スキップ・録画終了できます\n\n録画は約90秒後に自動的に終了します","\niPhone-WiFiのネットワークに\n\nユニメックWiFiカメラのSSIDを設定すると\n\nそのWiFiカメラの映像を記録できます\n\nカメラの上にiPhoneを載せて記録します"]
//    let explanationStringsE : Array<String> = ["\nThe screen-center button\nalso starts/stops recording.\n\nThe stop button dims during recording.","","telePhoto","","\nThe center button also starts recording,\nskips the explanation and stops recording.\n\nRecording automatically stops after 90s.","Set the Unimec WiFi Camera SSID\n\nin the iPhone-WiFi setting\n\nto record the video from the Camera."]
//    
    func setButtonsDisplay(){
        getPaddings()
        setButtonsLocation()
        
//        setButtonsFrontCameraMode()
        setPreviewLabel()
        zoomParts(hide: false)
        exposeParts(hide: false)
        cameraView.isHidden=false
        quaternionView.isHidden=false
        if cameraType == 5{//cameraType:5
//            cameraChangeButton.isHidden=false
            currentTime.isHidden=true
            cameraView.isHidden=true
            quaternionView.isHidden=true
            focusParts(hide: true)
 //           LEDParts(hide: true)
        }
        if recordingFlag==true {
            hideButtonsSlides()
            explanationLabel.isHidden=true
//            cameraTypeLabel.isHidden=true
 //           stopButton.isHidden=false
   //         startButton.isHidden=true
            currentTime.isHidden=false
            previewLabel.isHidden=true
            previewSwitch.isHidden=true
            playButton.isHidden=true
            listButton.isHidden=true
            helpButton.isHidden=true
            if cameraType == 0{
                startStopButton.alpha=0.015
                quaternionView.alpha=0.0
                cameraView.alpha=0.3
                currentTime.alpha=0.001//0.1
  //              stopButton.alpha=0.03
            }else{
                if cameraType==4{
                    startStopButton.alpha=0.015
                }else{
                    startStopButton.alpha=0.0
                }
                currentTime.alpha=1
                cameraView.alpha=1
                quaternionView.alpha=1
//                stopButton.alpha=1.0
            }
        }else{//not recording
            explanationLabel.isHidden=true//false
//            stopButton.isHidden=true
 ///           startButton.isHidden=false
            currentTime.isHidden=true
            playButton.isHidden=false
            listButton.isHidden=false
            currentTime.alpha=1
            cameraView.alpha=1
            quaternionView.alpha=1
            zoomParts(hide: false)
            exposeParts(hide: true)//false)
            focusParts(hide: false)
            helpButton.isHidden=false
            if focusChangeable==false{
                setFocusParts(type: 0)
            }else{
                setFocusParts(type:1)
            }
            if(cameraType==5){//wifi
                focusParts(hide: true)
                zoomParts(hide: true)
                exposeParts(hide: true)
            }else if cameraType==0||cameraType==4{//front camera
                startStopButton.alpha=1.0
            }else{//back camera
                startStopButton.alpha=0
            }
        }
//        if someFunctions.firstLang().contains("ja"){
//            explanationLabel.text = explanationStrings[cameraType]
//        }else{
//            explanationLabel.text = explanationStringsE[cameraType]
//        }
        //.isHidden=true
 //       stopButton.isHidden=true
    }
    func setFocusParts(type:Int){
        if type==2 {//auto
            focusBar.isHidden=true
            focusValueLabel.isHidden=true
            focusLabel.isHidden=true
            focusBack.text=""//!=someFunctions.firstLang().contains("ja") ? "自動焦点":"Autofocus"
//            LEDBar.isHidden=false
//            LEDValueLabel.isHidden=false
//            LEDLabel.isHidden=false
        }else if type==1{//manual
            focusBar.isHidden=false
            focusValueLabel.isHidden=false
            focusLabel.isHidden=false
            focusBack.text!=""
         //   LEDBar.isHidden=true
         //   LEDValueLabel.isHidden=true
         //   LEDLabel.isHidden=true
        }else{//fixed focus
            focusBar.isHidden=true
            focusValueLabel.isHidden=true
            focusBack.text!=someFunctions.firstLang().contains("ja") ? "固定焦点":"Fixed focus"
         //   LEDBar.isHidden=true
         //   LEDValueLabel.isHidden=true
         //   LEDLabel.isHidden=true
        }
    }
    var videoPlayer: AVPlayer!
    var soundPlayer: AVAudioPlayer?
    
    func sound(snd: String, fwd: Double) {
        if let sound = NSDataAsset(name: snd) {
            soundPlayer = try? AVAudioPlayer(data: sound.data)
            soundPlayer?.delegate = self  // デリゲートを設定
            soundPlayer?.currentTime = fwd
            soundPlayer?.play()
        }
    }
    
    func playMoviePath(_ urlorig: String) {
        guard let url = Bundle.main.url(forResource: urlorig, withExtension: "mp4") else {
            return
        }
        let playerItem = AVPlayerItem(url: url)
        // 通知登録（再生終了を監視）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspect
        layer.player = videoPlayer
        layer.frame = CGRect(x: -40, y: -10, width: view.bounds.width + 80, height: view.bounds.height + 20)
        
        cameraView.layer.addSublayer(layer)
        videoPlayer.play()
    }
    func stopAndDisposePlayer() {
        if let player = videoPlayer {
            if player.timeControlStatus == .playing {
                player.pause()
            }
            player.replaceCurrentItem(with: nil)
            videoPlayer = nil
        }
        // AVPlayerLayer を取り除く
        whiteView.layer.sublayers?.removeAll(where: { $0 is AVPlayerLayer })
        // 通知解除
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func onCameraChange(_ incDec:Int,focusChange:Bool){
//        cameraType = camera.getUserDefaultInt(str: "cameraType", ret: 0)
//        
//        cameraType = cameraChange(cameraType,incDec: incDec)
        cameraType = 0
//        UserDefaults.standard.set(cameraType, forKey: "cameraType")
        
        captureSession.stopRunning()
        set_rpk_ppk()
        initSession(fps: 60,focusChange: focusChange)
  
        focusBar.value=UserDefaults.standard.float(forKey: "focusValue_front")

        setFocus(focus: focusBar.value)
        setButtonsDisplay()
        exposeValue=exposeValue//getDefaultしてその値をsetする。setでsetExposeしそこでexposeValue表示
        setZoom(level: camera.getUserDefaultFloat(str: "zoomValue_front", ret: 0))
    }
    
    func initSession(fps:Double,focusChange:Bool) {
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

        
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        
        if setVideoFormat(desiredFps: fps)==false{
            //            print("error******")
        }else{
            //            print("no error****")
        }
        // AVCaptureSession生成
        captureSession = AVCaptureSession()
        captureSession.addInput(videoInput)
        
        // プレビュー出力設定
        whiteView.layer.frame=CGRect(x:0,y:0,width:view.bounds.width,height:view.bounds.height)
        cameraView.layer.frame=CGRect(x:0,y:0,width:view.bounds.width,height:view.bounds.height)
        cameraView.layer.addSublayer(   whiteView.layer)
        let leftPadding=CGFloat( UserDefaults.standard.integer(forKey:"leftPadding"))
        let width=view.bounds.width
        let height=view.bounds.height
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if !focusChange && (cameraType == 0 || cameraType == 4){//拡大した部分は隠す
            videoLayer.frame = CGRect(x:leftPadding+10,y:height*2.5/6,width:height*(16/9)/6,height:height/6)
        }else{//backCamera　拡大した部分は表示されない
                videoLayer.frame=self.view.bounds
        }
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        //info right home button
        let landscapeSide=someFunctions.getUserDefaultInt(str: "landscapeSide", ret: 0)
        if landscapeSide==0{
            videoLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        }else{
            videoLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        }
        cameraView.layer.addSublayer(videoLayer)
        
        // VideoDataOutputを作成、startRunningするとそれ以降delegateが呼ばれるようになる。
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
        //         videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        //         videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoDataOutput)
        //        configureAutoFocus()
        captureSession.startRunning()
        
        // ファイル出力設定
        startTimeStamp = 0
        //一時ファイルはこの時点で必ず消去
        let fileURL = NSURL(fileURLWithPath: TempFilePath)
        startMotionUpdates()//作動中ならそのまま戻る
        fileWriter = try? AVAssetWriter(outputURL: fileURL as URL, fileType: AVFileType.mov)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: iCapNYSWidth as AnyObject,
            AVVideoHeightKey: iCapNYSHeight as AnyObject
        ]
        fileWriterInput = AVAssetWriterInput(mediaType:AVMediaType.video, outputSettings: videoOutputSettings)
        fileWriterInput.expectsMediaDataInRealTime = true
        fileWriter.add(fileWriterInput)
        
        fileWriterAdapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: fileWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String:Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferHeightKey as String: iCapNYSWidth,
                kCVPixelBufferWidthKey as String: iCapNYSHeight,
            ]
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //        startTimer()
    }
    func setProperty(label:UILabel,radius:CGFloat){
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.cornerRadius = radius
    }
    var exposeValue: CGFloat {
        get {
            CGFloat(camera.getUserDefaultFloat(str: "exposeValue", ret: 0))
        }
        set {
            let minBias = Double(videoDevice!.minExposureTargetBias)//-8
            let maxBias = Double(videoDevice!.maxExposureTargetBias)//8
            let clampedValue = min(max(newValue, minBias/2), maxBias)
            UserDefaults.standard.set(Double(clampedValue), forKey: "exposeValue")
            setExpose(expose: Float(clampedValue))
        }
    }
    
    func setPreviewLabel(){
        if cameraType == 0 && setteiMode != 2{
            previewLabel.isHidden=false
            previewSwitch.isHidden=false
            if previewSwitch.isOn{
                if someFunctions.firstLang().contains("ja"){
                    previewLabel.text="ビュー"
                }else{
                    previewLabel.text="View"
                }
            }else{
                if someFunctions.firstLang().contains("ja"){
                    previewLabel.text="ビュー"
                }else{
                    previewLabel.text="View"
                }
            }
        }else{
            previewLabel.isHidden=true
            previewSwitch.isHidden=true
        }
    }
    
 /*   func configureAutoFocus() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try device.lockForConfiguration()
            
            // continuousAutoFocus に設定（録画中もオートフォーカスを維持）
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            //            if device.isExposurePointOfInterestSupported {
            //                device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)  // 画面中心
            //                device.exposureMode = .continuousAutoExposure
            //            }
            
            device.unlockForConfiguration()
            
        } catch {
            //            print("❌ カメラ設定のロックに失敗: \(error)")
        }
    }*/
    
 /*   func focusAtCenter() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)  // 画面中心
                device.focusMode = .continuousAutoFocus
            }
            
            device.unlockForConfiguration()
            
        } catch {
            //            print("❌ カメラ設定のロックに失敗: \(error)")
        }
    }*/
    func setButtonsLocation(){
        //        let height=CGFloat(camera.getUserDefaultFloat(str: "buttonsHeight", ret: 0))
        //pangestureによるボタンの高さ調整は不能とした。
        let sp=realWinWidth/120//間隙
        let bw=(realWinWidth-sp*10)/7//ボタン幅
        let bh=bw*170/440
        let by1 = realWinHeight - bh - sp// - bh*2/3//-height
        let by = realWinHeight - (bh+sp)*2// - bh*2/3//-height
        let x0=leftPadding+sp*2
        
        previewSwitch.frame = CGRect(x:leftPadding+10,y:view.bounds.height*3.5/6+sp,width: bw,height: bh)
        let y1=previewSwitch.frame.minY+(previewSwitch.frame.height-bh)/2
        previewLabel.frame=CGRect(x:previewSwitch.frame.maxX+sp/2,y:y1,width: bw*5,height: bh)
        explanationLabel.frame=CGRect(x:x0,y:sp,width:realWinWidth-sp*4,height: zoomLabel.frame.minY-sp)
        focusBar.frame = CGRect(x:x0+bw*4+sp*4, y: by1, width:bw*2+sp, height: bh)
  //      LEDBar.frame = CGRect(x:x0+bw*4+sp*4, y: by-sp-bh, width:bw*2+sp, height: bh)
        camera.setLabelProperty(focusBack,x:x0+bw*4+sp*4,y:by1,w:bw*2+sp,h:bh,UIColor.systemGray6,1)
        camera.setLabelProperty(focusLabel,x:x0+bw*3+sp*3,y:by1,w:bw,h:bh,UIColor.white)
        camera.setLabelProperty(focusValueLabel, x: x0+bw*7/2+sp*3, y: by1, w: bw/2-2, h: bh/2, UIColor.white,0)
//        camera.setLabelProperty(LEDLabel,x:x0+bw*3+sp*3,y:by-sp-bh,w:bw,h:bh,UIColor.white)
//        camera.setLabelProperty(LEDValueLabel, x: x0+bw*7/2+sp*3, y: by-sp-bh, w: bw/2-2, h: bh/2, UIColor.white,0)
//        camera.setLabelProperty(LEDBack,x:x0+bw*4+sp*4,y:by-sp-bh,w:bw*2+sp,h:bh,UIColor.systemGray6,1)
        exposeBar.frame = CGRect(x:x0+bw*4+sp*4, y: by1, width:bw*2+sp, height: bh)
        camera.setLabelProperty(exposeBack,x:x0+bw*4+sp*4,y:by1,w:bw*2+sp,h:bh,UIColor.systemGray6,1)
        camera.setLabelProperty(exposeLabel, x: x0+bw*3+sp*3, y: by1, w: bw, h: bh, UIColor.white,1)
        camera.setLabelProperty(exposeValueLabel,x:x0+bw*7/2+sp*3, y:by1, w: bw/2-2, h: bh/2, UIColor.white,0)
        zoomBar.frame = CGRect(x:x0+bw+sp, y: by1, width:bw*2+sp, height: bh)
        camera.setLabelProperty(zoomBack,x:x0+bw+sp,y:by1,w:bw*2+sp,h:bh,UIColor.systemGray6,1)
        camera.setLabelProperty(zoomLabel,x:x0,y:by1,w:bw,h:bh,UIColor.white)
        camera.setLabelProperty(zoomValueLabel, x: x0+bw/2, y: by1, w: bw/2-2, h: bh/2, UIColor.white,0)
        zoomBack.backgroundColor = UIColor.systemGray5
        focusBack.backgroundColor = UIColor.systemGray5
        exposeBack.backgroundColor = UIColor.systemGray5
        //
        camera.setButtonProperty(helpButton,x:x0+bw*6+sp*6,y:by1/*by-bh-sp*/,w:bw,h:bh,UIColor.darkGray,0)
        
        camera.setButtonProperty(playButton,x:x0+bw*6+sp*6,y:topPadding+sp,w:bw,h:bw*realWinHeight/realWinWidth,UIColor.darkGray,0)
        camera.setButtonProperty(listButton,x:x0+bw*6+sp*6,y:playButton.frame.maxY+sp,w:bw,h:bh,UIColor.darkGray,0)
        
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: view.bounds.width/30, weight: .medium)
        currentTime.frame = CGRect(x:x0+sp*6+bw*6, y: topPadding+sp, width: bw, height: bw*240/440)
        //        currentTime.alpha=0.5
        quaternionView.frame=CGRect(x:leftPadding+sp,y:sp,width:realWinHeight/5,height:realWinHeight/5)
        startStopButton.frame=CGRect(x:leftPadding+realWinWidth/2-realWinHeight*4/10,y:realWinHeight/10+topPadding,width: realWinHeight*4/5,height: realWinHeight*4/5)
         
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        // アプリがバックグラウンドに移行する直前に呼ばれる
        UIScreen.main.brightness = CGFloat(UserDefaults.standard.double(forKey: "brightness"))
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        UIScreen.main.brightness = CGFloat(UserDefaults.standard.double(forKey: "brightness"))
        // 完全に復帰したとき（ユーザーが操作可能になった）
    }
    func onClickStopButton() {
        guard canStopRecording else {
            //               print("⚠️ 録画開始後1秒以内。録画停止ブロック中。")
            return
        }

        recordingFlag = false
        helpButton.isHidden = false
        setButtonsDisplay()
        UIScreen.main.brightness = CGFloat(UserDefaults.standard.double(forKey: "brightness"))
        
        if fileWriter!.status == .writing {
            fileWriter!.finishWriting {
                DispatchQueue.main.async {
                    MyFunctions().makeSound()
                    self.saveVideoToAlbum() // ✅ 書き込み完了後に保存
                    self.canStartRecording = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.canStartRecording = true
                        //                        print("✅ 1秒経過：録画再開可能に")
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                MyFunctions().makeSound()
                self.saveVideoToAlbum()
            }
        }
    }
    
    func saveVideoToAlbum() {
        DispatchQueue.global(qos: .utility).async { [self] in
            let fileURL = URL(fileURLWithPath: TempFilePath)
            
            guard FileManager.default.fileExists(atPath: TempFilePath) else {
                return
            }
            
            PHPhotoLibrary.shared().performChanges({ [self] in
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: camera.getPHAssetcollection())
                let placeHolder = assetRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        VideoManager.shared.loadVideosFromAlbum(albumName: "iCapNYS") {
                            DispatchQueue.main.async {
                                self.setPlayButtonImage()
                                self.setButtonsDisplay()
                                self.onCameraChange(0, focusChange: false)
                            }
                        }
                    }
                }
            }
        }
    }
    func zoomParts(hide:Bool){
        zoomBar.isHidden=hide
        zoomLabel.isHidden=hide
        zoomValueLabel.isHidden=hide
        zoomBack.isHidden=hide
    }
    func exposeParts(hide:Bool){
        exposeBar.isHidden=hide
        exposeLabel.isHidden=hide
        exposeValueLabel.isHidden=hide
        exposeBack.isHidden=hide
    }
    func focusParts(hide:Bool){
        focusLabel.isHidden=hide
        focusValueLabel.isHidden=hide
        focusBar.isHidden=hide
        focusBack.isHidden=hide
    }

    func hideButtonsSlides() {
        zoomParts(hide:true)
        exposeParts(hide:true)
        focusParts(hide:true)
        currentTime.isHidden=false
    }
    var timerCntTime = CFAbsoluteTimeGetCurrent()
    
 
    var canStartRecording:Bool=true
    var canStopRecording:Bool=true
    func startRecording(option: String) {
        guard canStartRecording else {
            //               print("⚠️ 録画停止後1秒以内。録画開始ブロック中。")
            return
        }
        canStopRecording = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.canStopRecording = true
            //            print("✅ 1秒経過：録画停止可能に")
        }
        UserDefaults.standard.set(UIScreen.main.brightness, forKey: "brightness")
        if cameraType == 0 || cameraType == 4{
            UIScreen.main.brightness = CGFloat(1.0)
            explanationLabel.isHidden=true
        }
        timerCnt=0
        timerCntTime=CFAbsoluteTimeGetCurrent()
        currentTime.text="0:00"
        recordingFlag=true
        helpButton.isHidden=true
        setButtonsDisplay()
        recordingFlag=false
        UIApplication.shared.isIdleTimerDisabled = true  //スリープさせない
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {//executeAfter5Minutes()
            UIApplication.shared.isIdleTimerDisabled = false//スリープさせる
        }

        MyFunctions().makeSound()
        
        listButton.isHidden=true
        if (cameraType == 0 && previewSwitch.isOn==false) || cameraType == 4{
            quaternionView.isHidden=true
            cameraView.isHidden=true
            currentTime.alpha=0.001//0.1
        }
        
        try? FileManager.default.removeItem(atPath: TempFilePath)

        recordingFlag=true
        
        fileWriter!.startWriting()
        fileWriter!.startSession(atSourceTime: CMTime.zero)
        startMotionUpdates()
        timerCnt=0
    }
    @IBAction func onClickedStartStopButton(_ sender: Any) {
        if cameraType==0{
            if recordingFlag==true{
                onClickStopButton()
            }else{
                startRecording(option: "default") // デフォルト引数で呼ぶ
            }
        }
    }
    
    @IBAction func tapGest(_ sender: UITapGestureRecognizer) {
        startMotionUpdates()
    }
    var isManuallySoundStopped = false
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        //        print("🎵 再生が終了しました")
        if isManuallySoundStopped {
            //            print("⏹ 手動停止による終了 → 処理をスキップ")
            isManuallySoundStopped = false // 忘れずリセット
            return
        }
        onClickStopButton()
    }
    @objc func playerDidFinishPlaying(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == videoPlayer?.currentItem else {
            // 現在の再生アイテムではない（手動でnilにしたなど）
            return
        }
        //        print("🎬 動画の再生が終了しました")
        // 再生停止（念のため）
        videoPlayer?.pause()
        // プレイヤーアイテムを解放
        videoPlayer?.replaceCurrentItem(with: nil)
        // AVPlayer のインスタンスを破棄
        videoPlayer = nil
        // AVPlayerLayer を削除（whiteViewのサブレイヤーから）
        whiteView.layer.sublayers?.removeAll(where: { $0 is AVPlayerLayer })
        // 通知の解除（登録していた場合）
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: notification.object)
    }
  
    func setExpose(expose:Float) {
        if let currentDevice=videoDevice{
            exposeValueLabel.text=Int(expose*1000/80).description
            do {
                try currentDevice.lockForConfiguration()
                defer { currentDevice.unlockForConfiguration() }
                // 露出を設定
                //                       currentDevice.exposureMode = .autoExpose
                currentDevice.setExposureTargetBias(expose, completionHandler: nil)
                
            } catch {
                //                print("\(error.localizedDescription)")
            }
        }
    }
    
    private let quaternionQueue = DispatchQueue(label: "quaternion.sync.queue")
    
    //    var filterType:Int = 0//0:nonfilter 1:monochromeFilter 2:sepiaFilter
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if fileWriter.status == .writing && startTimeStamp == 0 {
            startTimeStamp = sampleBuffer.outputPresentationTimeStamp.value
        }
        //        print("recording")
        //全部UIImageで処理してるが、これでは遅いので全てCIImageで処理するように書き換えたほうがよさそう
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            //フレームが取得できなかった場合にすぐ返る
            //            print("unable to get image from sample buffer")
            return
        }
        //backCamera->.right  frontCamera->.left
        let frameCIImage = cameraType == 0 || cameraType == 4 ? CIImage(cvImageBuffer: frame).oriented(CGImagePropertyOrientation.right):CIImage(cvImageBuffer: frame).oriented(CGImagePropertyOrientation.left)
        let matrix1 = CGAffineTransform(rotationAngle: -1*CGFloat.pi/2)
        //width:1280と設定しているが？
        //width:1920で飛んで来ている
        let matrix2 = CGAffineTransform(translationX: 0, y: CGFloat(1080))
        var quaterImage:UIImage?
        if cameraType==0 {//}|| cameraType==4 || cropType==0 || cropType==1{//cameraType==0の時はcropType:0とする
            var rotatedCIImage:CIImage
            //2つのアフィンを組み合わせ
            let matrix = matrix1.concatenating(matrix2)
            //            if filterType==0{
            rotatedCIImage = frameCIImage.transformed(by: matrix)
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                // 同期的に読み取る（読み取り時に他スレッドと衝突しないように）
                var qCG0: CGFloat = 0
                var qCG1: CGFloat = 0
                var qCG2: CGFloat = 0
                var qCG3: CGFloat = 0
                
                quaternionQueue.sync {
                    qCG0 = CGFloat(quater0)
                    qCG1 = CGFloat(quater1)
                    qCG2 = CGFloat(quater2)
                    qCG3 = CGFloat(quater3)
                }
                
                quaterImage = drawHead(
                    width: realWinHeight / 2.5,
                    height: realWinHeight / 2.5,
                    radius: realWinHeight / 5 - 1,
                    qOld0: qCG0, qOld1: qCG1, qOld2: qCG2, qOld3: qCG3
                )
                
                DispatchQueue.main.async {
                    self.quaternionView.image = quaterImage
                    self.quaternionView.setNeedsLayout()
                }
            }
            
            //frameの時間計算, sampleBufferの時刻から算出
            let frameTime:CMTime = CMTimeMake(value: sampleBuffer.outputPresentationTimeStamp.value - startTimeStamp, timescale: sampleBuffer.outputPresentationTimeStamp.timescale)
            //3/2倍はこれで良い
            let x0:CGFloat=0
            let y0:CGFloat=120
          
            let frameUIImage = UIImage(ciImage:rotatedCIImage)
            UIGraphicsBeginImageContext(CGSize(width: iCapNYSWidthF, height: iCapNYSHeightF))
            frameUIImage.draw(in: CGRect(x:0, y:0, width:iCapNYSWidthF, height: iCapNYSHeightF))
            quaterImage!.draw(in: CGRect(x:iCapNYSWidthF120, y:iCapNYSWidthF120, width:iCapNYSHeightF5,height: iCapNYSHeightF5))
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // 1. 再利用バッファを定義（クラスのプロパティなどで）
            var reusablePixelBuffer: CVPixelBuffer?
            
            // 2. 使用するタイミングで呼び出す（ここが変更ポイント）
            if let renderedImage = renderedImage {
                let renderedBuffer = renderedImage.toCVPixelBuffer(reuse: &reusablePixelBuffer, width: Int(iCapNYSWidthF), height: Int(iCapNYSHeightF))
                
                if recordingFlag, startTimeStamp != 0, fileWriter.status == .writing {
                    if fileWriterInput?.isReadyForMoreMediaData == true, let buffer = renderedBuffer {
                        fileWriterAdapter.append(buffer, withPresentationTime: frameTime)
                    }
                }
            }
        }else{//cropType 2
            var scaX:CGFloat=0
            scaX=4/3
            let scaling = CGAffineTransform(scaleX:scaX,y:scaX)
            //            let scaling = CGAffineTransform(scaleX:1.5,y:1.5)
            let matrix = matrix1.concatenating(matrix2).concatenating(scaling) //3つのアフィンを組み合わせ
            
            //            let rotatedCIImage = monoChromeFilter(frameCIImage.transformed(by: matrix),intensity: 0.9)
            let rotatedCIImage = frameCIImage.transformed(by: matrix)
#if DEBUG
            //            print(" ")
            //            print("cropType2:frame/width,height:\(frameCIImage.extent.width),\(frameCIImage.extent.height)")
            //1080*1920
            //            print("cropType2:rotate/width,height:\(rotatedCIImage!.extent.width),\(rotatedCIImage!.extent.height)")
            //cropTpe0:1920*1080
            //cropTpe1:2343*1318 cropType2:2560*1440  original:1280*720
#endif
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                // 同期的に読み取る（読み取り時に他スレッドと衝突しないように）
                var qCG0: CGFloat = 0
                var qCG1: CGFloat = 0
                var qCG2: CGFloat = 0
                var qCG3: CGFloat = 0
                
                quaternionQueue.sync {
                    qCG0 = CGFloat(quater0)
                    qCG1 = CGFloat(quater1)
                    qCG2 = CGFloat(quater2)
                    qCG3 = CGFloat(quater3)
                }
                
                quaterImage = drawHead(
                    width: realWinHeight / 2.5,
                    height: realWinHeight / 2.5,
                    radius: realWinHeight / 5 - 1,
                    qOld0: qCG0, qOld1: qCG1, qOld2: qCG2, qOld3: qCG3
                )
                
                DispatchQueue.main.async {
                    self.quaternionView.image = quaterImage
                    self.quaternionView.setNeedsLayout()
                }
            }
            
            //frameの時間計算, sampleBufferの時刻から算出
            let frameTime:CMTime = CMTimeMake(value: sampleBuffer.outputPresentationTimeStamp.value - startTimeStamp, timescale: sampleBuffer.outputPresentationTimeStamp.timescale)
           
            let x0=1280//ok
            let y0=0//ok
        
            //cropTpe1:2343*1318 cropType2:2560*1440
            let frameUIImage = UIImage(ciImage: rotatedCIImage.cropped(to: CGRect(x:x0,y:y0,width:1280,height: 720)))
#if DEBUG
            print("cropType1-2:croppedFrame/width,height:\(frameCIImage.extent.width),\(frameCIImage.extent.height)")
            //1080*1920
            //            print("cropType1-2:crrotate/width,height:",rotatedCIImage?.extent.width as Any,rotatedCIImage?.extent.height as Any)
            //cropTpe0:1920*1080
            //cropTpe1:2343*1318 cropType2:2560*1440
#endif
            UIGraphicsBeginImageContext(CGSize(width: iCapNYSWidthF, height: iCapNYSHeightF))
            frameUIImage.draw(in: CGRect(x:0, y:0, width:iCapNYSWidthF, height: iCapNYSHeightF))
            quaterImage!.draw(in: CGRect(x:iCapNYSWidthF120, y:iCapNYSWidthF120, width:iCapNYSHeightF5,height: iCapNYSHeightF5))
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // 1. 再利用バッファを定義（クラスのプロパティなどで）
            var reusablePixelBuffer: CVPixelBuffer?
            
            // 2. 使用するタイミングで呼び出す（ここが変更ポイント）
            if let renderedImage = renderedImage {
                let renderedBuffer = renderedImage.toCVPixelBuffer(reuse: &reusablePixelBuffer, width: Int(iCapNYSWidthF), height: Int(iCapNYSHeightF))
                
                if recordingFlag, startTimeStamp != 0, fileWriter.status == .writing {
                    if fileWriterInput?.isReadyForMoreMediaData == true, let buffer = renderedBuffer {
                        fileWriterAdapter.append(buffer, withPresentationTime: frameTime)
                    }
                }
            }
        }
    }
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            
            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            
            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            return pixelBuffer
        }
        
        return nil
    }
    
    func toCVPixelBuffer(reuse buffer: inout CVPixelBuffer?, width: Int, height: Int) -> CVPixelBuffer? {
        if buffer == nil {
            // 初回だけ作成
            let attrs = [
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
            ] as CFDictionary
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width, height,
                kCVPixelFormatType_32ARGB,
                attrs,
                &buffer
            )
            if status != kCVReturnSuccess { return nil }
        }
        
        guard let buffer = buffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        if let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) {
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1.0, y: -1.0)
            UIGraphicsPushContext(context)
            self.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            UIGraphicsPopContext()
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
