import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApplePayFlutter {
  static const MethodChannel _channel =
  const MethodChannel('apple_pay_flutter');

  static Future<dynamic> makePayment({
    @required String countryCode,
    @required String currencyCode,
    @required List<PaymentNetwork> paymentNetworks,
    @required String merchantIdentifier,
    @required List<PaymentItem> paymentItems,
    @required String customerName,
    @required String customerEmail,
    @required String companyName,
    @required double shippingCharges,
  }) async {
    // Assert checks for validating null references in the parameters
    assert(countryCode != null);
    assert(currencyCode != null);
    assert(paymentItems != null);
    assert(merchantIdentifier != null);
    assert(customerEmail != null);
    assert(customerName != null);
    assert(companyName != null);
    assert(shippingCharges != null);

    // Create a argument json to be send to ApplePlay swift function
    final Map<String, Object> args = <String, dynamic>{
      'paymentNetworks':
      paymentNetworks.map((item) => item.toString().split('.')[1]).toList(),
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'paymentItems':
      paymentItems.map((PaymentItem item) => item._toMap()).toList(),
      'merchantIdentifier': merchantIdentifier,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'companyName':companyName,
      'shippingCharges':shippingCharges,
    };

    // Check if user is having real iOS device
    if (Platform.isIOS) {
      // To call apple pay method channel interface to show payment sheet & initiate payment
      final dynamic data = await _channel.invokeMethod('', args);
      return data;
    } else {
      // Throw error in case of trying to call the method from Andriod device
      throw Exception("Not supported operation system");
    }
  }
}

// Payment Item interface to be sent to apple pay parameters
class PaymentItem {
  final String label;
  final double amount;

  PaymentItem({@required this.label, @required this.amount}) {
    assert(this.label != null);
    assert(this.amount != null);
  }

  Map<String, dynamic> _toMap() {
    Map<String, dynamic> map = new Map();
    map["label"] = this.label;
    map["amount"] = this.amount;
    return map;
  }
}

// Support payment network enum
enum PaymentNetwork {
  visa,
  mastercard,
  amex,
  quicPay,
  chinaUnionPay,
  discover,
  interac,
  privateLabel,
  mada,
}
