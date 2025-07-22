




import SwiftUI
import CoreMotion
import WatchConnectivity

struct ContentView: View {
    @StateObject private var sessionManager = ExtendedSessionManager()

    @State private var quaternionText: String = "Initializing..."
    private let motionManager = CMMotionManager()
    private var session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    var body: some View {
        VStack {
            Text("Quaternion Data")
                .font(.headline)
            Text(quaternionText)
                .font(.system(size: 14))
         //       .padding()
            
            Button(sessionManager.isSessionActive ? "Stop Session" : "Start Session") {
                if sessionManager.isSessionActive {
                    sessionManager.stopExtendedSession()
                } else {
                    sessionManager.startExtendedSession()
                }
            }
            .padding()
            .background(sessionManager.isSessionActive ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            startMotionUpdates()
            setupWatchConnectivity()
        }
    }

    private func setupWatchConnectivity() {
        if let session = session {
            session.delegate = WatchConnectivityHandler.shared
            session.activate()
        }
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            quaternionText = "Device motion unavailable"
            return
        }

        motionManager.deviceMotionUpdateInterval = 2/25  // 更新間隔 
        motionManager.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
            guard let motion = deviceMotion, error == nil else {
                quaternionText = "Error: \(error?.localizedDescription ?? "Unknown")"
                return
            }

            let quaternion = motion.attitude.quaternion
            quaternionText = String(format: "x: %.3f\ny: %.3f\nz: %.3f\nw: %.3f",
                                     quaternion.x, quaternion.y, quaternion.z, quaternion.w)

            // 四元数データをiPhoneに送信
            let quaternionData: [String: Double] = [
                "x": quaternion.x,
                "y": quaternion.y,
                "z": quaternion.z,
                "w": quaternion.w
            ]
            WatchConnectivityHandler.shared.sendQuaternionToiPhone(data: quaternionData)
        }
    }
}

class WatchConnectivityHandler: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityHandler()

    func sendQuaternionToiPhone(data: [String: Double]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: { error in
                print("Failed to send message: \(error.localizedDescription)")
            })
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

/*
 //extendedSessionManager　の使い方
 import SwiftUI
 
 struct ContentView: View {
     @StateObject private var sessionManager = ExtendedSessionManager()

     var body: some View {
         VStack {
             Text("Apple Watch App")
                 .font(.title2)
                 .padding()

             Button(sessionManager.isSessionActive ? "Stop Session" : "Start Session") {
                 if sessionManager.isSessionActive {
                     sessionManager.stopExtendedSession()
                 } else {
                     sessionManager.startExtendedSession()
                 }
             }
             .padding()
             .background(sessionManager.isSessionActive ? Color.red : Color.blue)
             .foregroundColor(.white)
             .cornerRadius(10)
         }
     }
 }
*/
