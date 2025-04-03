import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mercadinho/models/app_user_info.dart'; // Update import
import 'package:mercadinho/screens/stock_screen.dart'; // Import the correct StockScreen

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible =
      false; // Add a variable to track password visibility

  Future<void> _signUpWithEmail() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        _showErrorToast('Por favor, preencha todos os campos.');
        return;
      }
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
        AppUserInfo.updateFromFirebaseUser(user); // Update global user info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => StockScreen(
                  title: "Estoque de ${AppUserInfo.name}",
                ), // Use global user info
          ),
        );
      }
    } catch (e) {
      _showErrorToast('Erro ao criar conta: ${e.toString()}');
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text('Cadastrar-se')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nome',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType:
                  TextInputType.emailAddress, // Specify email input type
              autofillHints: const [
                AutofillHints.email,
              ], // Enable autofill for email
              decoration: InputDecoration(
                hintText: 'E-mail',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, // Toggle password visibility
              autofillHints: const [
                AutofillHints.newPassword,
              ], // Enable autofill for new password
              decoration: InputDecoration(
                hintText: 'Senha',
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _signUpWithEmail, // Call the sign-up method
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text('Criar Conta', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
