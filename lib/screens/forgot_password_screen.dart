import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // Current Step
  // 0 = Email
  // 1 = OTP
  // 2 = New Password
  int _currentStep = 0;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------- Snackbar helper ----------
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ---------- Continue Button ----------
  Future<void> _continue() async {
    final email = _emailController.text.trim();

    // ================= STEP 0: Send OTP =================
    if (_currentStep == 0) {
      if (email.isEmpty) {
        _showSnack('Please enter your email', Colors.orange);
        return;
      }

      final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        _showSnack('Please enter a valid email address', Colors.orange);
        return;
      }

      setState(() => _isLoading = true);
      try {
        await ApiService.sendResetOtp(email: email);
        if (!mounted) return;
        _showSnack('OTP sent to $email', Colors.green);
        setState(() => _currentStep = 1);
      } catch (e) {
        if (!mounted) return;
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          Colors.red,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // ================= STEP 1: Verify OTP (local) =================
    // NOTE: backend has no verify-otp endpoint.
    // The OTP is validated server-side when reset-password is called.
    if (_currentStep == 1) {
      final otp = _otpController.text.trim();
      if (otp.length != 6) {
        _showSnack('Please enter the 6-digit OTP', Colors.orange);
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    // ================= STEP 2: Reset Password =================
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in both password fields', Colors.orange);
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters', Colors.orange);
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: password,
      );
      if (!mounted) return;
      _showSuccessMessage();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- Success Dialog ----------
  void _showSuccessMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: const [
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF16A34A),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Password Reset Successful',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your password has been updated successfully. '
                'You can now login with your new password.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop dialog, then pop this screen back to Login
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Go to Login',
                style: TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- Page Title ----------
  String get _title {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password?';
      case 1:
        return 'Verify OTP';
      default:
        return 'Create New Password';
    }
  }

  // ---------- Page Description ----------
  String get _description {
    switch (_currentStep) {
      case 0:
        return 'Enter your email address and we will send you a verification code.';
      case 1:
        return 'Enter the verification code sent to your email address.';
      default:
        return 'Create a new password for your account.';
    }
  }

  // ---------- Button Text ----------
  String get _buttonText {
    switch (_currentStep) {
      case 0:
        return 'Send OTP';
      case 1:
        return 'Verify OTP';
      default:
        return 'Reset Password';
    }
  }

  // ---------- Go Back ----------
  void _goBack() {
    if (_isLoading) return; // prevent back while loading
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),

                // Back Button
                IconButton(
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1E3A8A),
                    size: 22,
                  ),
                ),

                const SizedBox(height: 20),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Center(
                  child: Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Center(
                  child: Text(
                    _description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Progress Indicator
                _buildProgressIndicator(),

                const SizedBox(height: 35),

                // Step Content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentStep(),
                ),

                const SizedBox(height: 30),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      _buttonText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Current Step Widget ----------
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      default:
        return _buildNewPasswordStep();
    }
  }

  // ---------- Email Step ----------
  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('emailStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: _inputDecoration(
            hintText: 'Enter your email',
            icon: Icons.email_outlined,
          ),
        ),
      ],
    );
  }

  // ---------- OTP Step ----------
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otpStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          enabled: !_isLoading,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
          decoration: _inputDecoration(
            hintText: 'Enter 6-digit OTP',
            icon: Icons.lock_clock_outlined,
          ).copyWith(
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'OTP sent to ${_emailController.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _resendOtp,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Resend OTP ----------
  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Email is missing, please go back', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.sendResetOtp(email: email);
      if (!mounted) return;
      _showSnack('OTP resent to $email', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- New Password Step ----------
  Widget _buildNewPasswordStep() {
    return Column(
      key: const ValueKey('passwordStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Password',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          decoration: _inputDecoration(
            hintText: 'Enter new password',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          enabled: !_isLoading,
          decoration: _inputDecoration(
            hintText: 'Confirm new password',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Input Decoration ----------
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF1E3A8A),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFF59E0B),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF1E3A8A),
          width: 2,
        ),
      ),
    );
  }

  // ---------- Progress Indicator ----------
  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _stepIndicator(0),
        _stepLine(0),
        _stepIndicator(1),
        _stepLine(1),
        _stepIndicator(2),
      ],
    );
  }

  // ---------- Step Circle ----------
  Widget _stepIndicator(int step) {
    final bool isActive = _currentStep >= step;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ---------- Step Line ----------
  Widget _stepLine(int step) {
    final bool isActive = _currentStep > step;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
      ),
    );
  }
}