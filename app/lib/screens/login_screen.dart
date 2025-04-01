import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mercadinho/screens/signup_screen.dart'; // Import the signup screen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mercadinho/screens/stock_screen.dart'; // Ensure correct StockScreen import
import 'package:mercadinho/models/app_user_info.dart'; // Update import

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Add password controller
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _showPasswordField = false;
  bool _isPasswordVisible = false; // Add a variable to track password visibility

  Future<void> _signInWithEmail() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showErrorToast('Por favor, preencha todos os campos.');
        return;
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        AppUserInfo.updateFromFirebaseUser(user); // Update global user info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StockScreen(title: "Estoque de ${AppUserInfo.name}"), // Use global user info
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}'); // Print error details
      if (e.code == 'user-not-found') {
        _showErrorToast('Usuário não encontrado.');
      } else if (e.code == 'wrong-password') {
        _showErrorToast('Senha incorreta.');
      } else if (e.code == 'invalid-email') {
        _showErrorToast('O e-mail é inválido.');
      } else {
        _showErrorToast('Erro: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error: $e'); // Print unexpected error details
      _showErrorToast('Erro inesperado: $e');
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        _showPasswordField = _emailController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress, // Specify email input type
                    autofillHints: const [AutofillHints.email], // Enable autofill for email
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    decoration: InputDecoration(
                      hintText: 'E-mail',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8.0),
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Container(
                    height: 1, // Invisible divider to maintain layout consistency
                    color: Colors.grey[800],
                  ),
                  TextField(
                    controller: _passwordController, // Attach password controller
                    focusNode: _passwordFocusNode,
                    obscureText: !_isPasswordVisible, // Toggle password visibility
                    enabled: _showPasswordField,
                    autofillHints: const [AutofillHints.password], // Enable autofill for password
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(8.0),
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signInWithEmail, // Call the sign-in method
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  'Cadastrar-se',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      // Facebook login action
                    },
                    icon: const FaIcon(FontAwesomeIcons.facebook),
                    color: Colors.blue,
                    iconSize: 40,
                  ),
                  IconButton(
                    onPressed: () {
                      // Gmail login action
                    },
                    icon: const FaIcon(FontAwesomeIcons.google),
                    color: Colors.red,
                    iconSize: 40,
                  ),
                  IconButton(
                    onPressed: () {
                      // Apple login action
                    },
                    icon: const FaIcon(FontAwesomeIcons.apple),
                    color: Colors.white,
                    iconSize: 40,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
