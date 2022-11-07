//
//  HomeViewController.swift
//  iOS Example Frame
//
//  Created by Ehab Alsharkawy.
//  Copyright © 2022 Checkout. All rights reserved.
//

import Frames
import PassKit
import UIKit

class HomeViewController: UIViewController {
  // UI elements
  @IBOutlet private weak var scrollView: UIScrollView! {
    didSet {
      scrollView.keyboardDismissMode = .interactive
    }
  }
  @IBOutlet private weak var threeDSURLTextField: UITextField!
  @IBOutlet private weak var defaultButton: UIButton!
  @IBOutlet private weak var theme1Button: UIButton!

  private var notificationCenter: NotificationCenter = .default
  private lazy var checkoutAPIService = Frames.CheckoutAPIService(publicKey: Factory.apiKey, environment: .sandbox)

  override func viewDidLoad() {
    super.viewDidLoad()

    #if UITEST
      defaultButton.accessibilityIdentifier = "UITestDefault"
      theme1Button.accessibilityIdentifier = "UITestTheme1"
    #endif
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    deregisterKeyboardHandlers(notificationCenter: notificationCenter)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
    setUpKeyboard()
  }

  @IBAction private func showDefaultTheme(_ sender: Any) {
    customizeNavigationBarAppearance(backgroundColor: .white, foregroundColor: .black)
    let viewController = Factory.getDefaultPaymentViewController { [weak self] result in
      self?.handleTokenResponse(with: result)
    }
    navigationController?.pushViewController(viewController, animated: true)
  }

  @IBAction private func showMatrixTheme(_ sender: Any) {
    customizeNavigationBarAppearance(backgroundColor: UIColor(red: 23 / 255, green: 32 / 255, blue: 30 / 255, alpha: 1),
                                       foregroundColor: .green)
    let viewController = Factory.getMatrixPaymentViewController { [weak self] result in
      self?.handleTokenResponse(with: result)
    }
    navigationController?.pushViewController(viewController, animated: true)
  }

  @IBAction private func showOtherTheme(_ sender: Any) {
    customizeNavigationBarAppearance(backgroundColor: UIColor(red: 23 / 255, green: 32 / 255, blue: 30 / 255, alpha: 1),
                                       foregroundColor: .green)
    let viewController = Factory.getOtherPaymentViewController { [weak self] result in
      self?.handleTokenResponse(with: result)
    }
    navigationController?.pushViewController(viewController, animated: true)
  }

  @IBAction private func getApplePayData(_ sender: Any) {
      let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]
      let paymentItem = PKPaymentSummaryItem.init(label: "Test item", amount: NSDecimalNumber(value: 12.99))
      if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
          let request = PKPaymentRequest()
              request.currencyCode = "USD" // 1
              request.countryCode = "US" // 2
              request.merchantIdentifier = "merchant.io.michaeltaylor.test"
              request.merchantCapabilities = PKMerchantCapability.capability3DS // 4
              request.supportedNetworks = paymentNetworks // 5
              request.paymentSummaryItems = [paymentItem] // 6
          guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
              displayDefaultAlert(title: "Error", message: "Unable to present Apple Pay authorization.")
              return
          }
              paymentVC.delegate = self
              self.present(paymentVC, animated: true, completion: nil)

      } else {
        displayDefaultAlert(title: "Error", message: "Unable to make Apple Pay transaction.")
      }

  }

  @IBAction private func get3DSToken(_ sender: Any) {
    guard let threeDSURLString = threeDSURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
          let threeDSURL = URL(string: threeDSURLString) else {
        showAlert(with: "3DS URL could not be parsed")
        return
    }

    let webViewController = ThreedsWebViewController(environment: .sandbox,
                                                     successUrl: Factory.successURL,
                                                     failUrl: Factory.failureURL)
    webViewController.delegate = self
    webViewController.authURL = threeDSURL

    present(webViewController, animated: true, completion: nil)
  }

  @objc private func keyboardWillShow(notification: Notification) {
    guard let userInfo = notification.userInfo,
      let keyboardFrameValue = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }
    var keyboardFrame = keyboardFrameValue.cgRectValue
    keyboardFrame = view.convert(keyboardFrame, from: nil)
    var contentInset: UIEdgeInsets = scrollView.contentInset
    contentInset.bottom = keyboardFrame.size.height + 20
    updateScrollViewInset(to: contentInset, from: notification)
  }

  @objc private func keyboardWillHide(notification: Notification) {
    updateScrollViewInset(to: .zero, from: notification)
  }

  private func setUpKeyboard() {
    registerKeyboardHandlers(notificationCenter: notificationCenter,
                             keyboardWillShow: #selector(keyboardWillShow),
                             keyboardWillHide: #selector(keyboardWillHide))
  }

  private func displayDefaultAlert(title: String?, message: String?) {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
      alert.addAction(okAction)
      self.present(alert, animated: true, completion: nil)
  }

  private func updateScrollViewInset(to contentInset: UIEdgeInsets, from notification: Notification) {
    var animationDuration: Double = 0
    if let userInfo = notification.userInfo,
       let notificationAnimationDuration: Double = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
      animationDuration = notificationAnimationDuration
    }
    UIView.animate(withDuration: animationDuration) {
      self.scrollView.contentInset = contentInset
    }
  }

  private func handleTokenResponse(with result: Result<TokenDetails, TokenRequestError>) {
    switch result {
      case .failure(let error):
        showAlert(with: error.localizedDescription)
      case .success(let tokenDetails):
        showAlert(with: tokenDetails.token)
    }
  }

  private func showAlert(with cardToken: String) {
    DispatchQueue.main.async {
      let alert = UIAlertController(title: "Payment",
                                    message: cardToken, preferredStyle: .alert)
      let action = UIAlertAction(title: "OK", style: .default) { _ in
        alert.dismiss(animated: true, completion: nil)
      }
      alert.addAction(action)
      self.present(alert, animated: true, completion: nil)
    }
  }

}

extension HomeViewController: ThreedsWebViewControllerDelegate {
  func threeDSWebViewControllerAuthenticationDidSucceed(_ threeDSWebViewController: ThreedsWebViewController, token: String?) {
      threeDSWebViewController.dismiss(animated: true, completion: nil)
      showAlert(with: "3DS success, token: \(token ?? "nil")")
  }

  func threeDSWebViewControllerAuthenticationDidFail(_ threeDSWebViewController: ThreedsWebViewController) {
      threeDSWebViewController.dismiss(animated: true, completion: nil)
      showAlert(with: "3DS Fail")
  }
}

extension HomeViewController: PKPaymentAuthorizationViewControllerDelegate {

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: nil)
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        dismiss(animated: true, completion: nil)

        // pull test payload from static file
        guard let paymentDataURL = Bundle.main.url( forResource: "example_apple_pay_payment_data", withExtension: "json") else {
              print("Unable to get URL of Apple Pay payment data.")
              return
            }
            let paymentData: Data

            do {
              paymentData = try Data(contentsOf: paymentDataURL)
            } catch {
              print(error.localizedDescription)
              return
            }

            checkoutAPIService.createToken(.applePay(ApplePay(tokenData: paymentData))) { result in
                switch result {
                case .success(let tokenDetails):
                  DispatchQueue.main.async {
                    self.displayDefaultAlert(title: "Success!", message: tokenDetails.token)
                  }

                case .failure(let error):
                  DispatchQueue.main.async {
                    self.displayDefaultAlert(title: "Error!", message: error.localizedDescription)
                  }
                }
            }
    }
}
