import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.purple, // Make the primary color purple
        scaffoldBackgroundColor: Colors.purple[50], // Light purple background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple, // Purple AppBar
          titleTextStyle: TextStyle(
            color: Colors.white, // White text on AppBar
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              color: Colors.white), // Updated for newer Flutter versions
          bodyMedium: TextStyle(
              color: Colors.white), // Updated for newer Flutter versions
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, // Updated: Purple button background
            foregroundColor: Colors.white, // Updated: White button text
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.purple), // Purple label text
          border: OutlineInputBorder(),
        ),
      ),
      home: const FinanceHomePage(),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({Key? key}) : super(key: key);

  @override
  FinanceHomePageState createState() => FinanceHomePageState();
}

class FinanceHomePageState extends State<FinanceHomePage> {
  final List<Map<String, dynamic>> _transactions = [];
  final List<Map<String, dynamic>> _incomes = [];
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Save transactions and incomes to shared_preferences
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String transactionsJson = jsonEncode(_transactions);
    String incomesJson = jsonEncode(_incomes);
    await prefs.setString('transactions', transactionsJson);
    await prefs.setString('incomes', incomesJson);
    await prefs.setDouble('totalBalance', _totalBalance);
  }

  // Load transactions and incomes from shared_preferences
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? transactionsJson = prefs.getString('transactions');
    String? incomesJson = prefs.getString('incomes');
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
      });
    }

    if (incomesJson != null) {
      List<dynamic> loadedIncomes = jsonDecode(incomesJson);
      setState(() {
        _incomes.addAll(
          loadedIncomes
              .map((item) => {
                    'amount': item['amount'],
                    'description': item['description'],
                  })
              .toList(),
        );
      });
    }

    setState(() {
      _totalBalance = savedBalance ?? 0.0;
    });
  }

  void _addTransaction() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);
      final String description = _descriptionController.text;

      setState(() {
        _transactions.add({'amount': amount, 'description': description});
        _totalBalance -= amount; // Subtract transaction from balance
      });

      _amountController.clear();
      _descriptionController.clear();

      _saveData(); // Save transactions and incomes after adding
    }
  }

  void _addIncome() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);
      final String description = _descriptionController.text;

      setState(() {
        _incomes.add({'amount': amount, 'description': description});
        _totalBalance += amount; // Add income to balance
      });

      _amountController.clear();
      _descriptionController.clear();

      _saveData(); // Save transactions and incomes after adding
    }
  }

  // Delete transaction from list and update storage
  void _deleteTransaction(int index) {
    setState(() {
      _totalBalance += _transactions[index]['amount']; // Revert transaction
      _transactions.removeAt(index);
    });
    _saveData(); // Save the updated list after deletion
  }

  // Delete income from list and update storage
  void _deleteIncome(int index) {
    setState(() {
      _totalBalance -= _incomes[index]['amount']; // Revert income
      _incomes.removeAt(index);
    });
    _saveData(); // Save the updated list after deletion
  }

  // Show confirmation dialog for transactions
  Future<void> _showDeleteTransactionDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _deleteTransaction(index); // Delete the transaction
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for incomes
  Future<void> _showDeleteIncomeDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Income'),
          content: const Text('Are you sure you want to delete this income?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _deleteIncome(index); // Delete the income
                Navigator.of(context).pop();
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
        title: const Text('Finance Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total Balance: \$${_totalBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _addIncome,
                        child: const Text('Add Income'),
                      ),
                      ElevatedButton(
                        onPressed: _addTransaction,
                        child: const Text('Add Transaction'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    'Transactions:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  ..._transactions.map((transaction) {
                    int index = _transactions.indexOf(transaction);
                    return ListTile(
                      title: Text(transaction['description'],
                          style: const TextStyle(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '-\$${transaction['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteTransactionDialog(index);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text(
                    'Incomes:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  ..._incomes.map((income) {
                    int index = _incomes.indexOf(income);
                    return ListTile(
                      title: Text(income['description'],
                          style: const TextStyle(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+\$${income['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteIncomeDialog(index);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
