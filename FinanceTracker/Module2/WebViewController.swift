import UIKit
import WebKit

final class WebViewController: UIViewController {

    // MARK: - Properties

    private var webView: WKWebView!
    private var refreshControl: UIRefreshControl!
    private var progressBar: UIProgressView!
    private var progressObservation: NSKeyValueObservation?
    private var errorOverlay: UIView?

    // Retry counters for NSURLErrorHTTPTooManyRedirects
    private var redirectErrorRetryCount = 0
    private let maxRedirectErrorRetries = 5

    // MARK: - Rotation (WebView only — portrait + landscape)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupProgressBar()
        loadURL()
    }

    deinit {
        progressObservation?.invalidate()
    }

    // MARK: - Setup

    private func setupWebView() {
        // Accept ALL cookies — required for login / session persistence.
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always

        let config = WKWebViewConfiguration()
        config.websiteDataStore       = .default()   // persistent storage → session survives restart
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []   // slots / video autoplay
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.processPool            = WebViewProcessPool.shared

        // Seed WKHTTPCookieStore with any cookies from the system store
        // so previously saved sessions are visible to the webview immediately.
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                config.websiteDataStore.httpCookieStore.setCookie(cookie) { }
            }
        }

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true   // swipe left/right navigation
        webView.navigationDelegate = self
        webView.uiDelegate         = self
        webView.customUserAgent    =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
            "Version/16.0 Mobile/15E148 Safari/604.1"

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Pull-to-refresh (swipe down)
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        webView.scrollView.bounces = true
    }

    private func setupProgressBar() {
        progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor      = .systemBlue
        progressBar.trackTintColor = .clear
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2)
        ])

        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
            DispatchQueue.main.async {
                let p = Float(wv.estimatedProgress)
                self?.progressBar.setProgress(p, animated: true)
                self?.progressBar.isHidden = p >= 1.0
            }
        }
    }

    // MARK: - Loading

    /// Loads the page. On first launch uses savedWebURL; on subsequent launches
    /// restores the last visited page (lastWebURL) so the user lands where they left off.
    private func loadURL(useBase: Bool = false) {
        let urlString = useBase
            ? (AppState.shared.savedWebURL ?? "")
            : (AppState.shared.lastWebURL ?? AppState.shared.savedWebURL ?? "")
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            showErrorOverlay(message: "No URL configured.")
            return
        }
        webView.load(URLRequest(url: url))
    }

    @objc private func pullToRefresh() {
        hideErrorOverlay()
        if webView.url != nil {
            webView.reload()
        } else {
            loadURL()
        }
    }

    // MARK: - Error Overlay

    private func showErrorOverlay(message: String = "No Internet Connection",
                                  isRedirectError: Bool = false) {
        hideErrorOverlay()

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis      = .vertical
        stack.alignment = .center
        stack.spacing   = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconName = isRedirectError ? "arrow.triangle.2.circlepath" : "wifi.slash"
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor    = .secondaryLabel
        icon.contentMode  = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 56).isActive  = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let title = UILabel()
        title.text          = message
        title.font          = .systemFont(ofSize: 17, weight: .semibold)
        title.textColor     = .label
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text          = isRedirectError
            ? "Pull down or tap Retry to reload"
            : "Pull down or tap Retry to try again"
        subtitle.font          = .systemFont(ofSize: 14)
        subtitle.textColor     = .secondaryLabel
        subtitle.textAlignment = .center

        let retryBtn = UIButton(type: .system)
        retryBtn.setTitle("  Retry  ", for: .normal)
        retryBtn.titleLabel?.font    = .systemFont(ofSize: 16, weight: .medium)
        retryBtn.layer.borderColor   = UIColor.systemBlue.cgColor
        retryBtn.layer.borderWidth   = 1.5
        retryBtn.layer.cornerRadius  = 10
        retryBtn.contentEdgeInsets   = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        retryBtn.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)

        [icon, title, subtitle, retryBtn].forEach { stack.addArrangedSubview($0) }
        stack.setCustomSpacing(6, after: title)

        overlay.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -32)
        ])

        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        errorOverlay = overlay
    }

    private func hideErrorOverlay() {
        errorOverlay?.removeFromSuperview()
        errorOverlay = nil
    }

    @objc private func retryLoad() {
        hideErrorOverlay()
        // On redirect errors reload from the base URL to exit any broken chain.
        loadURL(useBase: true)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
        hideErrorOverlay()
        redirectErrorRetryCount = 0   // successful load — reset retry counter
        // Persist the last successfully loaded URL for session restore.
        if let url = webView.url?.absoluteString, !url.isEmpty, url != "about:blank" {
            AppState.shared.lastWebURL = url
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        let nsErr = error as NSError
        guard nsErr.code != NSURLErrorCancelled else { return }

        if nsErr.code == NSURLErrorHTTPTooManyRedirects {
            // Silently retry — cookies accumulated in the failed chain often shorten
            // the next attempt enough to succeed (e.g. casino OAuth login flows).
            if redirectErrorRetryCount < maxRedirectErrorRetries {
                redirectErrorRetryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self else { return }
                    if let current = webView.url {
                        webView.load(URLRequest(url: current))
                    } else {
                        self.loadURL()
                    }
                }
            } else {
                redirectErrorRetryCount = 0
                showErrorOverlay(message: "Too many redirects", isRedirectError: true)
            }
            return
        }
        showErrorOverlay(message: nsErr.localizedDescription)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        refreshControl.endRefreshing()
        let nsErr = error as NSError
        guard nsErr.code != NSURLErrorCancelled else { return }

        if nsErr.code == NSURLErrorHTTPTooManyRedirects {
            if redirectErrorRetryCount < maxRedirectErrorRetries {
                redirectErrorRetryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self else { return }
                    if let current = webView.url {
                        webView.load(URLRequest(url: current))
                    } else {
                        self.loadURL()
                    }
                }
            } else {
                redirectErrorRetryCount = 0
                showErrorOverlay(message: "Too many redirects", isRedirectError: true)
            }
            return
        }
        let msg = nsErr.code == NSURLErrorNotConnectedToInternet ||
                  nsErr.code == NSURLErrorNetworkConnectionLost
            ? "No Internet Connection"
            : nsErr.localizedDescription
        showErrorOverlay(message: msg)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let scheme = url.scheme?.lowercased() ?? ""
            // Hand special URL schemes off to iOS (phone, mail, SMS, App Store, etc.)
            if ["tel", "mailto", "sms", "facetime", "itms-apps"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate {

    /// Handle target="_blank" and window.open() — load in the same webview.
    /// The load MUST be dispatched asynchronously: calling webView.load() synchronously
    /// inside this callback interrupts WebKit's internal state and causes the page
    /// to appear to "refresh" without actually navigating.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        let request = navigationAction.request
        if request.url != nil {
            DispatchQueue.main.async { [weak webView] in
                webView?.load(request)
            }
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",     style: .default) { _ in completionHandler(true)  })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel)  { _ in completionHandler(false) })
        present(alert, animated: true)
    }
}

// MARK: - Shared Process Pool

enum WebViewProcessPool {
    static let shared = WKProcessPool()
}
