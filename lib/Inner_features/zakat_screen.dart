import 'package:flutter/material.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  @override
  _ZakatCalculatorScreenState createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _goldController = TextEditingController();
  final TextEditingController _silverController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _businessController = TextEditingController();
  final TextEditingController _anyotherController = TextEditingController();
  double _zakatAmount = 0;
  double _totalAssets = 0;
  double _nisabValue = 55000.00;
  bool _showNoZakat = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zakat Calculator'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputCard(
                  icon: Icons.monetization_on,
                  title: "Gold Value",
                  controller: _goldController,
                ),
                _buildInputCard(
                  icon: Icons.assignment,
                  title: "Silver Value",
                  controller: _silverController,
                ),
                _buildInputCard(
                  icon: Icons.attach_money,
                  title: "Cash Savings",
                  controller: _cashController,
                ),
                _buildInputCard(
                  icon: Icons.business_center_outlined,
                  title: "Business Assets",
                  controller: _businessController,
                ),
                _buildInputCard(
                  icon: Icons.business,
                  title: "Any other Assets",
                  controller: _anyotherController,
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: Icon(Icons.calculate, size: 24),
                  label: Text(
                    "Calculate Zakat",
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color.fromARGB(255, 96, 49, 171),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: const Color.fromARGB(255, 59, 159, 147),
                  ),
                  onPressed: _calculateZakat,
                ),
                SizedBox(height: 30),
                _buildTotalAssetsCard(),
                SizedBox(height: 20),
                _showNoZakat ? _buildNoZakatCard() : _buildZakatResultCard(),
                _buildNisabIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal.shade700),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.teal),
                ),
                filled: true,
                fillColor: Colors.teal.shade50,
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter amount';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAssetsCard() {
    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Assets',
              style: TextStyle(
                fontSize: 18,
                color: Colors.teal.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '₹${_totalAssets.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZakatResultCard() {
    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Zakat Payable',
              style: TextStyle(
                fontSize: 18,
                color: Colors.teal.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '₹${_zakatAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoZakatCard() {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 40),
            SizedBox(height: 10),
            Text(
              'No Zakat Applicable',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your assets are below nisab value',
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNisabIndicator() {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, color: Colors.teal.shade700),
          SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.teal.shade800),
              children: [
                TextSpan(text: 'Current Nisab: '),
                TextSpan(
                  text: '₹${_nisabValue.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculateZakat() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _totalAssets =
            _parseInput(_goldController) +
            _parseInput(_silverController) +
            _parseInput(_cashController) +
            _parseInput(_businessController) +
            _parseInput(_anyotherController);

        _showNoZakat = _totalAssets < _nisabValue;
        _zakatAmount = _showNoZakat ? 0 : _totalAssets * 0.025;
      });
    }
  }

  double _parseInput(TextEditingController controller) {
    return double.tryParse(controller.text) ?? 0;
  }

  @override
  void dispose() {
    _goldController.dispose();
    _silverController.dispose();
    _cashController.dispose();
    _businessController.dispose();
    _anyotherController.dispose();
    super.dispose();
  }
}
