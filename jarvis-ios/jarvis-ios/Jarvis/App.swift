import UIKit
import WebKit

// Adresse par défaut de Jarvis (modifiable dans l'app : appui long à 3 doigts)
let ADRESSE_PAR_DEFAUT = "https://192.168.1.96:3443"

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = JarvisViewController()
        window?.makeKeyAndVisible()
        UIApplication.shared.isIdleTimerDisabled = true // l'écran ne se met pas en veille
        return true
    }
}

class JarvisViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private let messageErreur = UILabel()
    private var timerRelance: Timer?

    private var adresse: String {
        get { UserDefaults.standard.string(forKey: "adresse") ?? ADRESSE_PAR_DEFAUT }
        set { UserDefaults.standard.set(newValue, forKey: "adresse") }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true            // caméra dans la page, pas en plein écran
        config.mediaTypesRequiringUserActionForPlayback = [] // la voix de Jarvis peut parler toute seule
        config.websiteDataStore = .default()               // garde cookies / localStorage (visages enregistrés…)

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)

        messageErreur.textColor = .cyan
        messageErreur.textAlignment = .center
        messageErreur.numberOfLines = 0
        messageErreur.font = .systemFont(ofSize: 18, weight: .medium)
        messageErreur.isHidden = true
        messageErreur.frame = view.bounds.insetBy(dx: 30, dy: 0)
        messageErreur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(messageErreur)

        let appuiLong = UILongPressGestureRecognizer(target: self, action: #selector(changerAdresse(_:)))
        appuiLong.numberOfTouchesRequired = 3
        appuiLong.minimumPressDuration = 1.5
        view.addGestureRecognizer(appuiLong)

        charger()
    }

    private func charger() {
        guard let url = URL(string: adresse) else { return }
        messageErreur.isHidden = true
        webView.load(URLRequest(url: url))
    }

    private func afficherErreur(_ texte: String) {
        messageErreur.text = "J.A.R.V.I.S.\n\nConnexion impossible à\n\(adresse)\n\n\(texte)\n\nNouvel essai dans 5 secondes…"
        messageErreur.isHidden = false
        timerRelance?.invalidate()
        timerRelance = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in self?.charger() }
    }

    @objc private func changerAdresse(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        let alerte = UIAlertController(title: "Adresse de Jarvis", message: nil, preferredStyle: .alert)
        alerte.addTextField { $0.text = self.adresse; $0.keyboardType = .URL; $0.autocapitalizationType = .none }
        alerte.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alerte.addAction(UIAlertAction(title: "Recharger", style: .default) { _ in self.charger() })
        alerte.addAction(UIAlertAction(title: "Enregistrer", style: .default) { _ in
            if let t = alerte.textFields?.first?.text, !t.isEmpty { self.adresse = t }
            self.charger()
        })
        present(alerte, animated: true)
    }

    // Accepte le certificat https "maison" (auto-signé) — uniquement pour le serveur Jarvis
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let hoteJarvis = URL(string: adresse)?.host
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           challenge.protectionSpace.host == hoteJarvis,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // Donne directement l'accès caméra + micro à la page Jarvis (iOS 15+)
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(origin.host == URL(string: adresse)?.host ? .grant : .prompt)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        messageErreur.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        afficherErreur(error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        afficherErreur(error.localizedDescription)
    }

    // Si iOS tue la page en arrière-plan, on la recharge
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        charger()
    }

    // Les alert() JavaScript de la page s'affichent normalement
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: "Jarvis", message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }
}
