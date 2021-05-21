# apple_pay_flutter
Accept Payments with Apple Pay.

## Usage
```dart
  import 'package:apple_pay_flutter/apple_pay_flutter.dart';

  Future<void> makePayment() async {

    // To store apple payment data
    dynamic applePaymentData;

    // List of items with label & price
    List<PaymentItem> paymentItems = [
      PaymentItem(label: 'Label', amount: 1.00)
    ];

    try {
        // initiate payment
        applePaymentData = await ApplePayFlutter.makePayment(
            countryCode: "US",
            currencyCode: "SAR",
            paymentNetworks: [
                PaymentNetwork.visa,
                PaymentNetwork.mastercard,
                PaymentNetwork.amex,
                PaymentNetwork.mada
            ],
            merchantIdentifier: "merchant.demo.tech.demoApplePayId",
            paymentItems: paymentItems,
            customerEmail: "demo.user@business.com",
            customerName: "Demo User",
            companyName: "Demo Company",
            shippingCharges: 2.00,
        );

        // This logs the Apple Pay response data
        print(applePaymentData.toString());

        } on PlatformException {
            print('Failed payment');
        }
     }

```
