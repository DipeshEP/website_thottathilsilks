


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/colour_constants.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Check if Firebase is initialized
        if (FirebaseAuth.instance.app == null) {
          throw Exception('Firebase is not initialized');
        }

        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Login success → navigate
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Login successful!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Login failed';
        
        // Provide user-friendly error messages
        switch (e.code) {
          case 'configuration-not-found':
            errorMessage = 'Firebase Authentication is not configured. Please enable it in Firebase Console.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed attempts. Please try again later.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your internet connection.';
            break;
          default:
            errorMessage = e.message ?? 'Login failed. Please try again.';
        }

        print('Firebase Auth Error: ${e.code} - ${e.message}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        print('Login Error: $e');
        
        String errorMessage = 'Something went wrong';
        if (e.toString().contains('Firebase')) {
          errorMessage = 'Firebase error. Please check your configuration.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WebColours.gradientStart,
              WebColours.gradientEnd,
              WebColours.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20.0 : 40.0,
                  vertical: 32.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left side - Logo (hidden on mobile)
                    if (!isMobile) ...[
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo Image - Replace with your actual image path
                              Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/IMG_3859-removebg-preview.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.white,
                                            size: 100,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                'Thottathil Silks',
                                style: TextStyle(
                                  fontSize: isTablet ? 36 : 42,
                                  fontWeight: FontWeight.w300,
                                  color: WebColours.primaryColor,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],

                    // Right side - Login Form
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 480,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 28.0 : 48.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo Image for Mobile
                                if (isMobile) ...[
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        'https://via.placeholder.com/200x200/000000/FFFFFF?text=Thottathil+Silks',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.black,
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                color: Colors.white,
                                                size: 80,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Thottathil Silks',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w300,
                                      color: WebColours.primaryColor,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],

                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: isMobile ? 32 : 36,
                                    fontWeight: FontWeight.bold,
                                    color: WebColours.primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Email Field (changed from Username)
                                _buildTextField(
                                  controller: _usernameController,
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  icon: Icons.email_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    // Basic email validation
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Password reset link sent!'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: WebColours.gradientStart,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Login Button with gradient
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        WebColours.gradientStart,
                                        WebColours.gradientEnd,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: WebColours.gradientStart.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                        : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider
                                // Row(
                                //   children: [
                                //     Expanded(child: Divider(color: WebColours.grayColour300)),
                                //     Padding(
                                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                                //       child: Text(
                                //         'OR',
                                //         style: TextStyle(
                                //           color: WebColours.grayColour600,
                                //           fontWeight: FontWeight.w500,
                                //         ),
                                //       ),
                                //     ),
                                //     Expanded(child: Divider(color: WebColours.grayColour300)),
                                //   ],
                                // ),
                                // const SizedBox(height: 24),

                                // Social Login Buttons
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: _buildSocialButton(
                                //         icon: Icons.g_mobiledata,
                                //         label: 'Google',
                                //       ),
                                //     ),
                                //     const SizedBox(width: 16),
                                //     Expanded(
                                //       child: _buildSocialButton(
                                //         icon: Icons.apple,
                                //         label: 'Apple',
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(height: 32),

                                // Sign Up Link
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.center,
                                //   children: [
                                //     Text(
                                //       "Don't have an account? ",
                                //       style: TextStyle(
                                //         color: WebColours.grayColour600,
                                //         fontSize: 15,
                                //       ),
                                //     ),
                                //     TextButton(
                                //       onPressed: () {
                                //         ScaffoldMessenger.of(context).showSnackBar(
                                //           SnackBar(
                                //             content: const Text('Navigate to sign up'),
                                //             behavior: SnackBarBehavior.floating,
                                //             shape: RoundedRectangleBorder(
                                //               borderRadius: BorderRadius.circular(10),
                                //             ),
                                //           ),
                                //         );
                                //       },
                                //       style: TextButton.styleFrom(
                                //         padding: EdgeInsets.zero,
                                //       ),
                                //       child: const Text(
                                //         'Sign Up',
                                //         style: TextStyle(
                                //           color: WebColours.gradientStart,
                                //           fontSize: 15,
                                //           fontWeight: FontWeight.bold,
                                //         ),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebColours.grayColour700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: WebColours.grayColour400),
            prefixIcon: Icon(icon, color: WebColours.grayColour600, size: 22),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: WebColours.grayColour600,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
                : null,
            filled: true,
            fillColor: WebColours.grayColour100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: WebColours.gradientStart,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

}