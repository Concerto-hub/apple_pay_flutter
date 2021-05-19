import Flutter
import UIKit
import Foundation
import PassKit

typealias AuthorizationCompletion = (_ payment: Any) -> Void
typealias AuthorizationViewControllerDidFinish = (_ error : NSDictionary) -> Void

public class SwiftApplePayFlutterPlugin: NSObject, FlutterPlugin, PKPaymentAuthorizationViewControllerDelegate {
    var authorizationCompletion : AuthorizationCompletion!
    var authorizationViewControllerDidFinish : AuthorizationViewControllerDidFinish!
    var pkrequest = PKPaymentRequest()
    var flutterResult: FlutterResult!;
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "apple_pay_flutter", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SwiftApplePayFlutterPlugin(), channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result;
        let parameters = NSMutableDictionary()
        var payments: [PKPaymentNetwork] = []
        var items = [PKPaymentSummaryItem]()
        var totalPrice:Double = 0.0
        let arguments = call.arguments as! NSDictionary
        
        guard let paymentNeworks = arguments["paymentNetworks"] as? [String] else {return}
        guard let countryCode = arguments["countryCode"] as? String else {return}
        guard let currencyCode = arguments["currencyCode"] as? String else {return}
        guard let companyName = arguments["companyName"] as? String else {return}
        guard let paymentItems = arguments["paymentItems"] as? [NSDictionary] else {return}
        guard let merchantIdentifier = arguments["merchantIdentifier"] as? String else {return}
        guard let shippingCharges = arguments["shippingCharges"] as? Double else {return}

        for dictionary in paymentItems {
            guard let label = dictionary["label"] as? String else {return}
            guard let price = dictionary["amount"] as? Double else {return}
            let type = PKPaymentSummaryItemType.final

            totalPrice = price+shippingCharges
            items.append(PKPaymentSummaryItem(label: "SubTotal", amount: NSDecimalNumber(floatLiteral: price), type: type))
            items.append(PKPaymentSummaryItem(label: "SHIPPING", amount: NSDecimalNumber(floatLiteral: shippingCharges), type: type))
        }

        let total = PKPaymentSummaryItem(label: companyName , amount: NSDecimalNumber(floatLiteral:totalPrice), type: .final)
        items.append(total)

        paymentNeworks.forEach {

            guard let paymentType = PaymentSystem(rawValue: $0) else
            {
                assertionFailure("No payment type found")
                return
            }
            payments.append(paymentType.paymentNetwork)
        }

        parameters["paymentNetworks"] = payments
        parameters["requiredShippingContactFields"] = [PKContactField.name, PKContactField.postalAddress] as Set
        parameters["merchantCapabilities"] = PKMerchantCapability.capability3DS // optional

        parameters["merchantIdentifier"] = merchantIdentifier
        parameters["countryCode"] = countryCode
        parameters["currencyCode"] = currencyCode

        parameters["paymentSummaryItems"] = items

        makePaymentRequest(parameters: parameters,  authCompletion: authorizationCompletion, authControllerCompletion: authorizationViewControllerDidFinish)
    }

    func authorizationCompletion(_ payment: Any) {
        // success
        flutterResult(payment)
    }

    func authorizationViewControllerDidFinish(_ error : NSDictionary) {
        //error
        flutterResult(error)
    }

    enum PaymentSystem: String {
        case visa
        case mastercard
        case amex
        case mada
        case quicPay
        case chinaUnionPay
        case discover
        case interac
        case privateLabel

        var paymentNetwork: PKPaymentNetwork {

            switch self {
                case .mastercard: return PKPaymentNetwork.masterCard
                case .visa: return PKPaymentNetwork.visa
                case .amex: return PKPaymentNetwork.amex
                case .mada: if #available(iOS 12.1.1, *) {
                    return PKPaymentNetwork.mada
                }else{
                    return PKPaymentNetwork.amex
                }
                case .quicPay: return PKPaymentNetwork.quicPay
                case .chinaUnionPay: return PKPaymentNetwork.chinaUnionPay
                case .discover: return PKPaymentNetwork.discover
                case .interac: return PKPaymentNetwork.interac
                case .privateLabel: return PKPaymentNetwork.privateLabel
            }
        }
    }

    func makePaymentRequest(parameters: NSDictionary, authCompletion: @escaping AuthorizationCompletion, authControllerCompletion: @escaping AuthorizationViewControllerDidFinish) {
        guard let paymentNetworks               = parameters["paymentNetworks"]                 as? [PKPaymentNetwork] else {return}
        guard let requiredShippingContactFields = parameters["requiredShippingContactFields"]   as? Set<PKContactField> else {return}
        let merchantCapabilities : PKMerchantCapability = parameters["merchantCapabilities"]    as? PKMerchantCapability ?? .capability3DS

        guard let merchantIdentifier            = parameters["merchantIdentifier"]              as? String else {return}
        guard let countryCode                   = parameters["countryCode"]                     as? String else {return}
        guard let currencyCode                  = parameters["currencyCode"]                    as? String else {return}

        guard let paymentSummaryItems           = parameters["paymentSummaryItems"]             as? [PKPaymentSummaryItem] else {return}

        authorizationCompletion = authCompletion
        authorizationViewControllerDidFinish = authControllerCompletion

        // Cards that should be accepted
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {

            pkrequest.merchantIdentifier = merchantIdentifier
            pkrequest.countryCode = countryCode
            pkrequest.currencyCode = currencyCode
            pkrequest.supportedNetworks = paymentNetworks
            pkrequest.requiredShippingContactFields = requiredShippingContactFields
            pkrequest.merchantCapabilities = merchantCapabilities

            pkrequest.paymentSummaryItems = paymentSummaryItems

            let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: pkrequest)

            if let viewController = authorizationViewController {
                    viewController.delegate = self
                guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
                    return
                }
                currentViewController.present(viewController, animated: true)
            }
        } else {
            let error: NSDictionary = ["message": "No payment method found", "code": "404", "ok": false]
            authControllerCompletion(error)
         }

        return
    }

     /*
     * This is the first method to be called once the encrypted blob is received from the apple server.
     * Our implementation of the call back function below is calling payment service to decrypt the encrypted blob.
     * It then proceeds to call processPayment method to send this data down to payment service for authorization.
    */
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        var paymentType = "";

        switch payment.token.paymentMethod.type {
            case .debit:
                paymentType = "debit"
            case .credit:
                paymentType = "credit"
            case .store:
                paymentType = "store"
            case .prepaid:
                paymentType = "prepaid"
            default:
                paymentType = "unknown"
            }

        var paymentMethodDictionary: [AnyHashable: Any] = ["network": payment.token.paymentMethod.network ?? "", "type": paymentType, "displayName": payment.token.paymentMethod.displayName ?? ""]

        let encryptedPaymentData = payment.token.paymentData
        let decryptedPaymentData:NSString! = NSString(data: encryptedPaymentData, encoding: String.Encoding.utf8.rawValue)

        let PaymentData: NSDictionary = [
            "ok": true,
            "paymentMethod": paymentMethodDictionary,
            "paymentType": paymentType,
            "paymentData": decryptedPaymentData,
            // "shippingContact": payment.shippingContact ?? <#default value#>,
            // "billingContact": payment.billingContact ?? <#default value#>,
            "transactionIdentifier": payment.token.transactionIdentifier,
        ]

        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        authorizationCompletion(PaymentData)
    }


    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // Dismiss the Apple Pay UI
        guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
            return
        }
        currentViewController.dismiss(animated: true, completion: nil)
        let error: NSDictionary = ["message": "User closed apple pay", "code": "400", "ok": false]
        authorizationViewControllerDidFinish(error)
    }

    func makePaymentSummaryItems(itemsParameters: Array<Dictionary <String, Any>>) -> [PKPaymentSummaryItem]? {
        var items = [PKPaymentSummaryItem]()
        var totalPrice:Decimal = 0.0

        for dictionary in itemsParameters {

            guard let label = dictionary["label"] as? String else {return nil}
            guard let amount = dictionary["amount"] as? NSDecimalNumber else {return nil}
            guard let type = dictionary["type"] as? PKPaymentSummaryItemType else {return nil}

            totalPrice += amount.decimalValue

            items.append(PKPaymentSummaryItem(label: "SHIPPING", amount: amount, type: type))
        }

        let total = PKPaymentSummaryItem(label: "LLC.", amount: NSDecimalNumber(decimal:totalPrice), type: .final)
        items.append(total)
        print(items)
        return items
    }
    
}

extension UIWindow {
    func topMostViewController() -> UIViewController? {
        guard let rootViewController = self.rootViewController else {
            return nil
        }
        return topViewController(for: rootViewController)
    }
    
    func topViewController(for rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        guard let presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }
        switch presentedViewController {
        case is UINavigationController:
            let navigationController = presentedViewController as! UINavigationController
            return topViewController(for: navigationController.viewControllers.last)
        case is UITabBarController:
            let tabBarController = presentedViewController as! UITabBarController
            return topViewController(for: tabBarController.selectedViewController)
        default:
            return topViewController(for: presentedViewController)
        }
    }
}
