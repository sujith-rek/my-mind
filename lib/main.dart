import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'restart.dart';

void main() {
  runApp(const RestartWidget(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Mind',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _input = 0;
  String _password = '';
  bool _isPasswordSetVariable = false;

  final TextEditingController _controller = TextEditingController();
  final storage = const FlutterSecureStorage();

  late Future<bool> _fetchInitialDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchInitialDataFuture = _fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchInitialDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Column(
              children: <Widget>[
                TextField(
                  controller: _controller,
                ),
                ElevatedButton(
                  onPressed: () {
                    _input = int.parse(_controller.text);
                    _isPasswordSetVariable
                        ? _isPasswordCorrect()
                        : _setPassword();
                  },
                  child: Text(_isPasswordSetVariable
                      ? 'Check password'
                      : 'Set password'),
                ),
                if (_isPasswordSetVariable)
                  ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Reset password'),
                  ),
              ],
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  void _setPassword() async {
    final bytes = utf8.encode(_input.toString());
    final digest = sha256.convert(bytes);
    await storage.write(key: 'password', value: digest.toString());

    await _showDialog('Password Set', 'Your password has been set.');
    _restartApp();
  }

  void _resetPassword() async {
    await storage.delete(key: 'password');
    await _showDialog('Password Reset', 'Your password has been reset.');
    _restartApp();
  }

  void _isPasswordCorrect() {
    final bytes = utf8.encode(_input.toString());
    final digest = sha256.convert(bytes);
    bool isCorrect = digest.toString() == _password;

    _showDialog('Password Check',
        isCorrect ? 'The password is correct.' : 'The password is incorrect.');
  }

  void _restartApp() {
    RestartWidget.restartApp(context);
  }

  Future<bool> _fetchInitialData() async {
    final password = await storage.read(key: 'password');
    if (password != null) {
      _password = password;
      _isPasswordSetVariable = true;
    } else {
      _isPasswordSetVariable = false;
    }
    return true;
  }

  Future<void> _showDialog(String title, String content) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
