import WatchKit
import Combine

class ExtendedSessionManager: NSObject, WKExtendedRuntimeSessionDelegate, ObservableObject {
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) {
    
    }
    
    @Published var isSessionActive = false
    private var session: WKExtendedRuntimeSession?

    func startExtendedSession() {
        guard session == nil || session?.state == .invalid else {
            print("🚨 セッションはすでに開始されています")
            return
        }

        session = WKExtendedRuntimeSession()
        session?.delegate = self

        if session?.state == .scheduled || session?.state == .running {
            print("🚨 既に動作中のセッションがあります")
            return
        }

        print("🟢 セッションを開始します")
        session?.start()
        DispatchQueue.main.async {
            self.isSessionActive = true
        }
    }

    func stopExtendedSession() {
        print("🛑 セッションを停止します")
        session?.invalidate()
        DispatchQueue.main.async {
            self.isSessionActive = false
        }
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("✅ セッションが開始されました")
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ セッションがまもなく終了します")
    }

    func extendedRuntimeSessionDidInvalidate(_ session: WKExtendedRuntimeSession) {
        print("❌ セッションが無効になりました")
        DispatchQueue.main.async {
            self.isSessionActive = false
        }
        self.session = nil
    }
}
