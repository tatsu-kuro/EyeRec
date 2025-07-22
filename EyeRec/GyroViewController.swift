import UIKit
import CoreMotion
import Network

class GyroViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var ip1: UITextField!
    @IBOutlet weak var ip2: UITextField!
    @IBOutlet weak var ip3: UITextField!
    @IBOutlet weak var ip4: UITextField!
    @IBOutlet weak var portLabel: UILabel!
    @IBOutlet weak var port: UITextField!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var motionSensorLabel: UILabel!
    @IBOutlet weak var explanationLabel: UILabel!

    // MARK: - Properties
    let motionManager = CMMotionManager()
    var IPAddress: String?
    var host: NWEndpoint.Host = "192.168.0.209"
    var port1108: NWEndpoint.Port = 1108
    var connection: NWConnection?
    var UDPf = false

    var quatx: Double = 0.0
    var quaty: Double = 0.0
    var quatz: Double = 0.0
    var quatw: Double = 0.0
    var cnt = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupInitialValues()
        setupUI()
        setupMotionUpdates()

        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if UDPf {
            disconnect(connection: connection!)
        }
        UDPf = false
        stopMotionUpdates()
    }

    // MARK: - Setup Methods
    private func setupInitialValues() {
        IPAddress = MyFunctions().getUserDefaultString(str: "IPAddress", ret: "192.168.1.1")

        if let arr = IPAddress?.components(separatedBy: "."), arr.count == 4 {
            ip1.text = arr[0]
            ip2.text = arr[1]
            ip3.text = arr[2]
            ip4.text = arr[3]
        }

        UserDefaults.standard.set(UIScreen.main.brightness, forKey: "brightness")
    }

    private func setupUI() {
        let top = CGFloat(UserDefaults.standard.float(forKey: "topPadding"))
        let bottom = CGFloat(UserDefaults.standard.float(forKey: "bottomPadding"))
        let left = CGFloat(UserDefaults.standard.float(forKey: "leftPadding"))
        let right = CGFloat(UserDefaults.standard.float(forKey: "rightPadding"))
        let ww = view.bounds.width - (left + right)
        let wh = view.bounds.height - (top + bottom)
        let sp = ww / 120
        var bw = (ww - sp * 9) / 8
        let bh = bw * 170 / 440
        let by = wh - bh - sp
        
        MyFunctions().setButtonProperty(exitButton, x: left + bw * 7 + sp * 8, y: by, w: bw, h: bh, UIColor.darkGray)
        MyFunctions().setButtonProperty(setButton, x: left + bw * 7 + sp * 8, y: top + bh + 4 * sp, w: bw, h: bh, UIColor.darkGray)

        topLabel.frame = CGRect(x: left + sp, y: top + 2 * sp, width: ww, height: bh)
        ipLabel.frame = CGRect(x: left + sp, y: top + bh + 4 * sp, width: bw, height: bh)

        for (i, field) in [ip1, ip2, ip3, ip4, port].enumerated() {
            field?.frame = CGRect(x: left + bw * CGFloat(i + 1) + sp * CGFloat(i + 2), y: top + bh + 4 * sp, width: bw, height: bh)
        }

        portLabel.frame = CGRect(x: left + bw * 5 + sp * 6, y: top + bh + 4 * sp, width: bw, height: bh)
        port.frame=CGRect(x:left+bw*6+sp*7,y:top+bh+4*sp,width: bw,height: bh)

        
        motionSensorLabel.frame = CGRect(x: left + sp, y: top + bh * 2 + 5 * sp, width: bw * 6 + 7 * sp, height: bh)

        explanationLabel.numberOfLines = 0
        explanationLabel.font = UIFont.systemFont(ofSize: 20)
        explanationLabel.frame = CGRect(x: sp, y: 0, width: ww - 2 * sp, height: 0)

        if MyFunctions().firstLang().contains("ja"){
            explanationLabel.text="CapNYS(Windowsソフト)にモーションセンサーデータを送ります。\nCapNYSのメニューからGyro(phone WiFi)を選択すると、IPアドレスが表示されますので、それらを上記枠に入力し、セットします。iPhoneを赤外線カメラの上に置けば、CapNYSで眼振映像に頭位アニメーションを合成し、録画できます。CapNYSメニューからGyroDirectionをiPhoneの置き方に合わせて、7もしくは８に設定して下さい。\nCapNYS(Windowsソフト)は \"https://kuroda33.com/jibika\" からダウンロード出来ます。詳細はCapNYSのHelpをご覧ください。"
        }else{
            explanationLabel.text="From the CapNYS menu select Gyro(phone WiFi), then the IP address will be displayed, so enter this address into the fields above and set it. Once the iPhone is placed over the infrared camera, CapNYS will overlay head position animation onto the nystagmus video and record it. In the CapNYS menu, set GyroDirection to either 7 or 8 depending on the orientation of the iPhone. Please see CapNYS Help for details. \nCapNYS can be downloaded from \"https://kuroda33.com/jibika\"."
        }
        explanationLabel.sizeToFit()

        scrollView.frame = CGRect(x: left, y: top + bh * 3 + 6 * sp, width: ww, height: wh - top - bh * 3 - 6 * sp)
        scrollView.contentSize = CGSize(width: ww, height: explanationLabel.frame.maxY + 20)

        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func setupMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 25.0
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            let quat = motion.attitude.quaternion
            self.quatx = quat.x
            self.quaty = quat.y
            self.quatz = quat.z
            self.quatw = quat.w

            let b0 = UInt8((self.quatz + 1.0) * 128)
            let b1 = UInt8((self.quaty + 1.0) * 128)
            let b2 = UInt8((self.quatx + 1.0) * 128)
            let b3 = UInt8((self.quatw + 1.0) * 128)

            let quatString = String(format: "Q:%03d%03d%03d%03d\n", b0, b1, b2, b3)
            
            let formatted = String(format: "x:%+.3f, y:%+.3f, z:%+.3f, w:%+.3f", quatx, quaty, quatz, quatw)
            self.motionSensorLabel.text = formatted
            self.motionSensorLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
            
//            self.motionSensorLabel.text = String(format: "x:%.3f,y:%.3f,z:%.3f,w:%.3f", self.quatx, self.quaty, self.quatz, self.quatw)
//            self.motionSensorLabel.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
            if let dataUTF8 = quatString.data(using: .utf8), self.UDPf {
                self.send(dataUTF8)
            }
        }
    }

    // MARK: - Motion & Connection Methods
    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    private func disconnect(connection: NWConnection) {
        connection.cancel()
    }

    private func connect(hostname: String) {
        let host = NWEndpoint.Host(hostname)
        connection = NWConnection(host: host, port: port1108, using: .udp)

        connection?.stateUpdateHandler = { _ in }
        connection?.viabilityUpdateHandler = { [weak self] isViable in
            self?.UDPf = isViable
        }
        connection?.betterPathUpdateHandler = { _ in }
        connection?.start(queue: .global())
    }

    private func send(_ payload: Data) {
        connection?.send(content: payload, completion: .contentProcessed { [weak self] error in
            if error == nil {
                self?.cnt += 1
            }
        })
    }

    // MARK: - Actions
    @IBAction func onSetButton(_ sender: Any) {
        [ip1, ip2, ip3, ip4, port].forEach { $0?.resignFirstResponder() }

        let ipComponents = [ip1.text, ip2.text, ip3.text, ip4.text].compactMap { $0 ?? "0" }
        IPAddress = ipComponents.joined(separator: ".")
        UserDefaults.standard.set(IPAddress, forKey: "IPAddress")

        if let ip = IPAddress {
            connect(hostname: ip)
            setupMotionUpdates()
        }
    }
}

