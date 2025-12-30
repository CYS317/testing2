import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'admin_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool _dbReady = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  String? selectedQuestion;

  String? usernameError;
  String? passwordError;
  String? answerError;

  Database? _database;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));
    _initDb();
  }

  Future<void> _initDb() async {
    String path = join(await getDatabasesPath(), 'users.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            createdAt TEXT,
            lastLogin TEXT,
            securityQuestion TEXT,
            securityAnswer TEXT
          )
        ''');

        await db.insert('users', {
          'username': 'admin',
          'password': 'adminPassword',
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': DateTime.now().toIso8601String(),
          'securityQuestion': null,
          'securityAnswer': null,
        });
      },
    );
    setState(() => _dbReady = true);
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    final upperCase = RegExp(r'[A-Z]');
    final lowerCase = RegExp(r'[a-z]');
    final digit = RegExp(r'\d');
    final specialChar = RegExp(r'[^A-Za-z0-9]');
    if (!upperCase.hasMatch(password)) return false;
    if (!lowerCase.hasMatch(password)) return false;
    if (!digit.hasMatch(password)) return false;
    if (!specialChar.hasMatch(password)) return false;
    return true;
  }

  Future<void> _register(BuildContext context) async {
    if (!_dbReady) return;
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final answer = answerController.text;

    setState(() {
      usernameError = username.isEmpty ? "Please enter username" : null;
      answerError = (selectedQuestion == null || answer.isEmpty)
          ? "Please select a question and provide answer"
          : null;

      if (password.isEmpty) {
        passwordError = "Please enter password";
      } else if (!_validatePassword(password)) {
        passwordError =
            "Password must be at least 8 characters, include uppercase, lowercase, number, and special character";
      } else {
        passwordError = null;
      }
    });

    if (usernameError != null || passwordError != null || answerError != null) return;

    final existingUser = await _database!.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (existingUser.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This username already exists")),
      );
      return;
    }

    await _database!.insert('users', {
      'username': username,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': DateTime.now().toIso8601String(),
      'securityQuestion': selectedQuestion ?? '',
      'securityAnswer': answer,
    });

    setState(() {
      usernameError = null;
      passwordError = null;
      answerError = null;
      isLogin = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registered successfully. Please login.")),
    );
  }

  Future<void> _login(BuildContext context) async {
    if (!_dbReady) return;
    final username = usernameController.text.trim();
    final password = passwordController.text;

    setState(() {
      usernameError = username.isEmpty ? "Please enter username" : null;
      passwordError = password.isEmpty ? "Please enter password" : null;
    });

    if (usernameError != null || passwordError != null) return;

    final result = await _database!.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      await _database!.update(
        'users',
        {'lastLogin': DateTime.now().toIso8601String()},
        where: 'username = ?',
        whereArgs: [username],
      );

      if (username == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(currentUser: username)),
        );
      }
    } else {
      setState(() {
        passwordError = "Invalid username or password";
      });
    }
  }

  void _goToForgetPassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ForgetPasswordPage(database: _database!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/authentication_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "AI-Based Focus Monitoring For Exercise",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.exo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: usernameController,
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: GoogleFonts.roboto(
                            color: Colors.black54,
                          ),
                          errorText: usernameError,
                          errorStyle: const TextStyle(color: Colors.red),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: GoogleFonts.roboto(
                            color: Colors.black54,
                          ),
                          errorText: passwordError,
                          errorStyle: const TextStyle(color: Colors.red),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedQuestion,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'What is your favorite color?',
                              child: Text('What is your favorite color?', maxLines: 2),
                            ),
                            DropdownMenuItem(
                              value: 'What is your favorite sport?',
                              child: Text('What is your favorite sport?', maxLines: 2),
                            ),
                            DropdownMenuItem(
                              value: 'What is your favorite sport equipment?',
                              child: Text('What is your favorite sport equipment?', maxLines: 2),
                            ),
                          ],
                          onChanged: (v) => setState(() => selectedQuestion = v ?? ''),
                          decoration: InputDecoration(
                            labelText: "Security Question",
                            errorText: answerError,
                            labelStyle: GoogleFonts.roboto(color: Colors.black54),
                            errorStyle: const TextStyle(color: Colors.red),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: answerController,
                          style: GoogleFonts.roboto(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: "Answer",
                            errorText: answerError,
                            errorStyle: const TextStyle(color: Colors.red),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _dbReady ? () => isLogin ? _login(context) : _register(context) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isLogin ? "Login" : "Sign Up",
                          style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => setState(() {
                          isLogin = !isLogin;
                          usernameError = null;
                          passwordError = null;
                          answerError = null;
                        }),
                        child: Text(
                          isLogin ? "Create account" : "Back to login",
                          style: GoogleFonts.roboto(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isLogin)
                        TextButton(
                          onPressed: () => _goToForgetPassword(context),
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgetPasswordPage extends StatefulWidget {
  final Database database;
  const ForgetPasswordPage({super.key, required this.database});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  String question = '';
  String password = '';
  String usernameError = '';
  Color passwordColor = Colors.black87;

  void _checkQuestion() async {
    final user = await widget.database.query(
      'users',
      where: 'username = ?',
      whereArgs: [usernameController.text.trim()],
    );

    if (user.isEmpty) {
      setState(() {
        usernameError = 'Username does not exist';
        question = '';
        password = '';
      });
      return;
    }

    setState(() {
      question = user.first['securityQuestion']?.toString() ?? '';
      password = '';
      usernameError = '';
    });
  }

  void _submitAnswer() async {
    final user = await widget.database.query(
      'users',
      where: 'username = ? AND securityAnswer = ?',
      whereArgs: [usernameController.text.trim(), answerController.text],
    );

    if (user.isNotEmpty) {
      setState(() {
        password = 'Your password is: ${user.first['password']?.toString() ?? ''}';
        passwordColor = Colors.teal;
      });
    } else {
      setState(() {
        password = 'Your answer is wrong answer';
        passwordColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/authentication_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: usernameController,
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: GoogleFonts.roboto(
                            color: Colors.black54,
                          ),
                          errorText: usernameError.isEmpty ? null : usernameError,
                          errorStyle: const TextStyle(color: Colors.red),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (question.isEmpty)
                        ElevatedButton(
                          onPressed: _checkQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "Next",
                            style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      if (question.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Question: $question",
                            style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: answerController,
                          style: GoogleFonts.roboto(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: "Answer",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "Submit",
                            style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (password.isNotEmpty)
                          Text(
                            password,
                            style: TextStyle(
                              fontSize: 16,
                              color: passwordColor,
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Back to login",
                          style: GoogleFonts.roboto(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}