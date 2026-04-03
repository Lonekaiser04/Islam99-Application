import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Our Work'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 30),
            _buildPaymentMethodCard(
              icon: Icons.payment,
              title: "UPI & Mobile Payments",
              color: Colors.purple,
              children: [
                _buildPaymentTile(
                  context,
                  "Google Pay",
                  "lonekaiser04@oksbi",
                  Icons.account_balance_wallet,
                  _launchGooglePay,
                ),
                _buildPaymentTile(
                  context,
                  "Other UPI Applications",
                  "lonekaiser04@oksbi",
                  Icons.payment,
                  _launchGenericUpi,
                ),
                _buildQrCodeSection(context),
              ],
            ),
            _buildPaymentMethodCard(
              icon: Icons.currency_exchange,
              title: "International Payments",
              color: Colors.orange,
              children: [
                _buildPaymentTile(
                  context,
                  "PayPal",
                  "lonekaiser04@oksbi",
                  Icons.paypal,
                  _launchPayPal,
                ),
                _buildPaymentTile(
                  context,
                  "Wise",
                  "lonekaiser04@oksbi",
                  Icons.account_balance,
                  _launchWise,
                ),
                _buildPaymentTile(
                  context,
                  "Stripe",
                  "lonekaiser04@oksbi",
                  Icons.credit_card,
                  _launchStripe,
                ),
              ],
            ),
            _buildSecurityNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Function() onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 83, 88, 91),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.copy, size: 20),
            onPressed: () {
              FlutterClipboard.copy(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$label copied to clipboard"),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
          ),
          SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color.fromARGB(255, 214, 210, 91),
            ),
            onPressed: onTap,
            child: Text("Pay Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGooglePay() async {
    const url =
        "upi://pay?pa=lonekaiser04@oksbi&pn=Mulsimpro's developer&mc=0000&mode=02&purpose=00";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _launchFallback("https://pay.google.com");
    }
  }

  Future<void> _launchGenericUpi() async {
    const url =
        "upi://pay?pa=lonekaiser04@oksbi&pn=Islam99's developer&tn=Support Payment for Islam99&cu=INR";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _launchFallback("https://pay.google.com"); // Fallback if no UPI app found
    }
  }

  Future<void> _launchPayPal() async {
    const url = 'https://www.paypal.com/paypalme/support@techdev.com';
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchWise() async {
    const url = 'https://wise.com/pay/techdev-support@wise.com';
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchStripe() async {
    const url = 'https://pay.techdev.com';
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchFallback(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.volunteer_activism, size: 60, color: Colors.blue),
        SizedBox(height: 20),
        Text(
          "Support Our Development",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Your support helps us maintain and improve our services. Choose your preferred payment method:",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                "Scan QR Code",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/icon/qr_code.jpg',
                    ), // Add your QR image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Scan using any payment app",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Text(
          "Security Alert: Always verify payment details through our official channels. "
          "We will never ask for payments through unofficial platforms or direct messages.",
          style: TextStyle(
            color: const Color.fromARGB(255, 173, 75, 75),
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
