import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FinanceHomePage(),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  @override
  _FinanceHomePageState createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  final List<Map<String, dynamic>> _transactions = [];
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // Save transactions to shared_preferences
  Future<void> _saveTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String transactionsJson = jsonEncode(_transactions);
    await prefs.setString('transactions', transactionsJson);
    await prefs.setDouble('totalBalance', _totalBalance);
  }

  // Load transactions from shared_preferences
  Future<void> _loadTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? transactionsJson = prefs.getString('transactions');
    double? savedBalance = prefs.getDouble('totalBalance');

    if (transactionsJson != null) {
      List<dynamic> loadedTransactions = jsonDecode(transactionsJson);
      setState(() {
        _transactions.addAll(
          loadedTransactions
              .map((item) => {
                    'amount': item['amount'],
                    'description': item['description'],
                  })
              .toList(),
        );
        _totalBalance = savedBalance ?? 0.0;
      });
    }
  }

  void _addTransaction() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);
      final String description = _descriptionController.text;

      setState(() {
        _transactions.add({'amount': amount, 'description': description});
        _totalBalance += amount;
      });

      _amountController.clear();
      _descriptionController.clear();

      _saveTransactions(); // Save transactions when a new one is added
    }
  }

  // Delete transaction from list and update storage
  void _deleteTransaction(int index) {
    setState(() {
      _totalBalance -= _transactions[index]['amount'];
      _transactions.removeAt(index);
    });
    _saveTransactions(); // Save the updated list after deletion
  }

  // Show confirmation dialog
  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog and do nothing
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                _deleteTransaction(index); // Delete the transaction
                Navigator.of(context).pop(); // Close the dialog after deleting
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total Balance: \$${_totalBalance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTransaction,
                    child: Text('Add Transaction'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_transactions[index]['description']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${_transactions[index]['amount'].toStringAsFixed(2)}',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
