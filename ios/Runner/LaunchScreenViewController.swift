// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var splashWindow: UIWindow?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Create the main Flutter window first
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        GeneratedPluginRegistrant.register(with: self)

        // Create and show animated splash overlay
        showAnimatedSplash()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func showAnimatedSplash() {
        // Create splash window that overlays everything
        splashWindow = UIWindow(frame: UIScreen.main.bounds)
        splashWindow?.windowLevel = UIWindow.Level.alert + 1
        splashWindow?.isHidden = false

        // Create splash view controller
        let splashVC = createSplashViewController()
        splashWindow?.rootViewController = splashVC
        splashWindow?.makeKeyAndVisible()

        // Start animations and remove after delay
        startSplashAnimations(in: splashVC.view)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.removeSplashWithAnimation()
        }
    }

    private func createSplashViewController() -> UIViewController {
        let splashVC = UIViewController()

        // Create gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0).cgColor,
            UIColor(red: 0.09, green: 0.13, blue: 0.24, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.20, blue: 0.38, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = UIScreen.main.bounds
        splashVC.view.layer.addSublayer(gradientLayer)

        // Create logo
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(systemName: "bolt.fill")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = .white
        logoImageView.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        logoImageView.center = CGPoint(x: UIScreen.main.bounds.width / 2,
                                      y: UIScreen.main.bounds.height / 2 - 60)
        logoImageView.tag = 100 // Tag for animation reference

        // Add glow effect
        logoImageView.layer.shadowColor = UIColor.cyan.cgColor
        logoImageView.layer.shadowRadius = 20
        logoImageView.layer.shadowOpacity = 0.8
        logoImageView.layer.shadowOffset = CGSize.zero

        splashVC.view.addSubview(logoImageView)

        // Create app name label
        let appNameLabel = UILabel()
        appNameLabel.text = "AWESOME APP"
        appNameLabel.textColor = .white
        appNameLabel.font = UIFont.boldSystemFont(ofSize: 28)
        appNameLabel.textAlignment = .center
        appNameLabel.frame = CGRect(x: 20, y: logoImageView.frame.maxY + 40,
                                   width: UIScreen.main.bounds.width - 40, height: 40)
        appNameLabel.tag = 101
        splashVC.view.addSubview(appNameLabel)

        // Create tagline label
        let taglineLabel = UILabel()
        taglineLabel.text = "Experience the magic"
        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        taglineLabel.font = UIFont.systemFont(ofSize: 16)
        taglineLabel.textAlignment = .center
        taglineLabel.frame = CGRect(x: 20, y: appNameLabel.frame.maxY + 12,
                                   width: UIScreen.main.bounds.width - 40, height: 20)
        taglineLabel.tag = 102
        splashVC.view.addSubview(taglineLabel)

        // Create progress view
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = UIColor.cyan
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.frame = CGRect(x: (UIScreen.main.bounds.width - 200) / 2,
                                   y: taglineLabel.frame.maxY + 60, width: 200, height: 4)
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.tag = 103
        splashVC.view.addSubview(progressView)

        return splashVC
    }

    private func startSplashAnimations(in view: UIView) {
        guard let logoImageView = view.viewWithTag(100),
              let appNameLabel = view.viewWithTag(101),
              let taglineLabel = view.viewWithTag(102),
              let progressView = view.viewWithTag(103) as? UIProgressView else { return }

        // Set initial states
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        appNameLabel.alpha = 0
        appNameLabel.transform = CGAffineTransform(translationX: 0, y: 50)

        taglineLabel.alpha = 0
        taglineLabel.transform = CGAffineTransform(translationX: 0, y: 40)

        progressView.alpha = 0
        progressView.progress = 0

        // Logo animation with bounce
        UIView.animate(withDuration: 1.2, delay: 0.2, usingSpringWithDamping: 0.6,
                      initialSpringVelocity: 0.8, options: .curveEaseInOut) {
            logoImageView.alpha = 1.0
            logoImageView.transform = CGAffineTransform.identity
        }

        // Logo rotation (continuous)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.toValue = NSNumber(value: Double.pi * 2)
            rotation.duration = 3.0
            rotation.repeatCount = Float.infinity
            logoImageView.layer.add(rotation, forKey: "rotationAnimation")
        }

        // App name slide up
        UIView.animate(withDuration: 0.8, delay: 0.8, usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            appNameLabel.alpha = 1.0
            appNameLabel.transform = CGAffineTransform.identity
        }

        // Tagline slide up
        UIView.animate(withDuration: 0.6, delay: 1.2, usingSpringWithDamping: 0.8,
                      initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            taglineLabel.alpha = 1.0
            taglineLabel.transform = CGAffineTransform.identity
        }

        // Progress view fade in
        UIView.animate(withDuration: 0.4, delay: 1.6) {
            progressView.alpha = 1.0
        }

        // Progress animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UIView.animate(withDuration: 1.5, delay: 0, options: .curveEaseInOut) {
                progressView.setProgress(1.0, animated: true)
            }
        }
    }

    private func removeSplashWithAnimation() {
        guard let splashWindow = self.splashWindow else { return }

        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
            splashWindow.alpha = 0
            splashWindow.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            splashWindow.isHidden = true
            self.splashWindow = nil

            // Make main window key
            self.window?.makeKeyAndVisible()
        }
    }
}