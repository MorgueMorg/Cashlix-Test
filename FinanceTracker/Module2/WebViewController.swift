import UIKit
import WebKit

final class WebViewController: UIViewController {

    // MARK: - Properties

    private var webView: WKWebView!
    private var refreshControl: UIRefreshControl!
    private var progressBar: UIProgressView!
    private var progressObservation: NSKeyValueObservation?

    private var redirectRecoveryWorkItem: DispatchWorkItem?
    private var redirectRecoveryAttempts = 0
    private let maxRedirectRecoveryAttempts = 2

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupWebView()
        setupProgressBar()
        loadInitialURL()
    }

    deinit {
        progressObservation?.invalidate()
        redirectRecoveryWorkItem?.cancel()
    }

    // MARK: - Setup

    private func setupWebView() {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.bounces = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        self.webView = webView

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        self.refreshControl = refreshControl
    }

    private func setupProgressBar() {
        let progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor = .systemBlue
        progressBar.trackTintColor = .clear
        progressBar.progress = 0
        progressBar.isHidden = true
        self.progressBar = progressBar

        view.addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2)
        ])

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            guard let self else { return }

            DispatchQueue.main.async {
                let progress = Float(webView.estimatedProgress)
                self.progressBar.isHidden = progress >= 1.0
                self.progressBar.setProgress(progress, animated: true)
            }
        }
    }

    // MARK: - Loading

    private func loadInitialURL() {
        guard
            let urlString = AppState.shared.lastWebURL ?? AppState.shared.savedWebURL,
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            return
        }

        load(url: url)
    }

    private func load(url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .useProtocolCachePolicy
        webView.load(request)
    }

    @objc
    private func handlePullToRefresh() {
        redirectRecoveryWorkItem?.cancel()

        if webView.url != nil {
            webView.reload()
        } else {
            loadInitialURL()
        }
    }

    private func scheduleRedirectRecovery() {
        guard redirectRecoveryAttempts < maxRedirectRecoveryAttempts else {
            finishLoadingUI()
            return
        }

        redirectRecoveryAttempts += 1
        redirectRecoveryWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.webView.reload()
        }

        redirectRecoveryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    private func persistLastLoadedURL() {
        guard
            let urlString = webView.url?.absoluteString,
            !urlString.isEmpty,
            urlString != "about:blank"
        else {
            return
        }

        AppState.shared.lastWebURL = urlString
    }

    private func finishLoadingUI() {
        refreshControl.endRefreshing()
        progressBar.isHidden = true
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        redirectRecoveryAttempts = 0
        redirectRecoveryWorkItem?.cancel()
        finishLoadingUI()
        persistLastLoadedURL()
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        handleWebError(error)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        handleWebError(error)
    }

    private func handleWebError(_ error: Error) {
        let nsError = error as NSError
        finishLoadingUI()

        if nsError.code == NSURLErrorCancelled {
            return
        }

        if nsError.code == NSURLErrorHTTPTooManyRedirects {
            scheduleRedirectRecovery()
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = (url.scheme ?? "").lowercased()

        if ["tel", "mailto", "sms", "facetime", "itms-apps"].contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
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

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
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
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
}
