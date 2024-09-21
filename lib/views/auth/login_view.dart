import 'package:famlicious_app/faculty_home_view.dart';
import 'package:famlicious_app/managers/auth_manager.dart';
import 'package:famlicious_app/views/auth/create_account_view.dart';
import 'package:famlicious_app/views/auth/forgot_password_view.dart';
import 'package:famlicious_app/views/home/home_view.dart';
import 'package:famlicious_app/faculty_home_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final RegExp emailRegexp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  bool isLoading = false;
  final AuthManager _authManager = AuthManager();
  final CollectionReference _facultyCollection = FirebaseFirestore.instance.collection('faculty');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Image.asset('assets/logo_header.png', width: 130, height: 130),
              const SizedBox(height: 35),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(label: Text('Email')),
                validator: (value) {
                  if (value!.isEmpty) return 'Email is required!';
                  if (!emailRegexp.hasMatch(value)) return 'Email is invalid';
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(label: Text('Password')),
                validator: (value) {
                  if (value!.isEmpty) return 'Password is required!';
                  if (value.length < 8) return 'Password should be 8 characters or more';
                },
              ),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ForgotPasswordView())),
                  child: const Text('Forgot password? Reset here!', style: TextStyle(color: Colors.grey)),
                ),
              ),
              isLoading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() { isLoading = true; });

                      bool isSuccessful = await _authManager.loginUser(
                          email: _emailController.text,
                          password: _passwordController.text);

                      if (isSuccessful) {
                        // Check if email belongs to a faculty member
                        QuerySnapshot facultySnapshot = await _facultyCollection.where('email', isEqualTo: _emailController.text).get();
                        setState(() { isLoading = false; });

                        if (facultySnapshot.docs.isNotEmpty) {
                          // Redirect to FacultyView
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => FacultyHomeView()),
                                (route) => false,
                          );
                        } else {
                          // Not a faculty email, redirect to HomeView
                          Fluttertoast.showToast(
                            msg: "Welcome back to UniGram!",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => HomeView()),
                                (route) => false,
                          );
                        }
                      } else {
                        // Error in login
                        setState(() { isLoading = false; });
                        Fluttertoast.showToast(
                          msg: _authManager.message,
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    } else {
                      // Validation error
                      Fluttertoast.showToast(
                        msg: 'Email and Password are required!',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).buttonTheme.colorScheme!.background),
                  child: Text('Login', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).buttonTheme.colorScheme!.primary))
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateAccountView())),
                  child: const Text('No account? Create one here!', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
