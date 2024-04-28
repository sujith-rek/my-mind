import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = FlutterSecureStorage();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _input = 0;
  String _password = '';
  bool _isPasswordSetVariable = false;

  final TextEditingController _controller = TextEditingController();
  final storage = FlutterSecureStorage();

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
          return const CircularProgressIndicator(); // Show a loading spinner while waiting for _fetchInitialData to complete
        }
      },
    );
  }

  void _setPassword() async {
    final bytes = utf8.encode(_input.toString());
    final digest = sha256.convert(bytes);
    await storage.write(key: 'password', value: digest.toString());

    _showDialog('Password Set', 'Your password has been set.');
  }

  void _showDialog(String title, String content) {
    showDialog(
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

  void _resetPassword() async {
    await storage.delete(key: 'password');
    _showDialog('Password Reset', 'Your password has been reset.');
  }

  void _isPasswordCorrect() {
    final bytes = utf8.encode(_input.toString());
    final digest = sha256.convert(bytes);
    bool isCorrect = digest.toString() == _password;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isCorrect ? 'Correct Password' : 'Incorrect Password'),
          content: Text(isCorrect
              ? 'You have entered the correct password.'
              : 'The password you entered is incorrect.'),
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
}
