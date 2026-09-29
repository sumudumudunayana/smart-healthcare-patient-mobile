import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

import '../navigation/patient_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _showPassword = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage);

    _authService = AuthService(apiClient, secureStorage);
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ---------------------------------------------------------
    // VALIDATION
    // ---------------------------------------------------------

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ---------------------------------------------------------
    // LOGIN
    // ---------------------------------------------------------

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Patient app only accepts Patient accounts.
      if (response.role != 'Patient') {
        await _authService.logout();

        if (!mounted) return;

        _showError('This account is not registered as a patient account.');

        return;
      }

      // -------------------------------------------------------
      // SUCCESS
      // -------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${response.fullName}!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PatientNavigation()),
        (route) => false,
      );

      // Patient dashboard will be connected here next.
      //
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (_) => const PatientDashboardScreen(),
      //   ),
      // );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // ERROR
  // =========================================================

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  // =========================================================
  // NAVIGATE TO REGISTER
  // =========================================================

  void _openRegister() {
    if (_isLoading) return;

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            if (isDesktop) {
              return _buildDesktopLayout();
            }

            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // =========================================================
  // DESKTOP LAYOUT
  // =========================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 58, child: _buildBrandPanel()),
        Expanded(
          flex: 42,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FFFB),
                  Color(0xFFF4FAF7),
                  Color(0xFFEEF8F3),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45,
                  vertical: 45,
                ),
                child: _buildLoginCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MOBILE LAYOUT
  // =========================================================

  Widget _buildMobileLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFF5FAF7), Color(0xFFF0FDF4)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
          child: _buildLoginCard(mobile: true),
        ),
      ),
    );
  }

  // =========================================================
  // BRAND PANEL
  // =========================================================

  Widget _buildBrandPanel() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF047857),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
          stops: [0.0, 0.42, 0.72, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrand(light: true),

            const Spacer(),

            _buildBrandContent(),

            const Spacer(),

            _buildFeatures(),

            const Spacer(),

            _buildBrandFooter(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BRAND
  // =========================================================

  Widget _buildBrand({required bool light}) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: light
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFF059669),
            border: light
                ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartHealthcare',
              style: TextStyle(
                color: light ? Colors.white : const Color(0xFF064E3B),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Healthcare Management System',
              style: TextStyle(
                color: light
                    ? Colors.white.withValues(alpha: 0.65)
                    : const Color(0xFF64748B),
                fontSize: 10,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // BRAND CONTENT
  // =========================================================

  Widget _buildBrandContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Text(
            'SMART HEALTHCARE',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Smarter Healthcare.\nBetter Care.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 52,
            height: 1.02,
            fontWeight: FontWeight.w700,
            letterSpacing: -2.5,
          ),
        ),

        const SizedBox(height: 20),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Text(
            'A unified platform designed to help healthcare teams '
            'manage appointments, medical records, billing, '
            'notifications, and healthcare operations efficiently.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FEATURES
  // =========================================================

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeature(
          title: 'Secure Access',
          description: 'Role-based authentication',
        ),
        const SizedBox(height: 17),
        _buildFeature(
          title: 'Connected Care',
          description: 'Healthcare information in one place',
        ),
        const SizedBox(height: 17),
        _buildFeature(
          title: 'AI-Assisted',
          description: 'Intelligent healthcare assistance',
        ),
      ],
    );
  }

  Widget _buildFeature({required String title, required String description}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Center(
            child: Text(
              '✓',
              style: TextStyle(
                color: Color(0xFFA7F3D0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // BRAND FOOTER
  // =========================================================

  Widget _buildBrandFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '© 2026 SmartHealthcare',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 9,
          ),
        ),
        Text(
          'Secure Healthcare Platform',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LOGIN CARD
  // =========================================================

  Widget _buildLoginCard({bool mobile = false}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 470),
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 25 : 46,
        vertical: mobile ? 32 : 46,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(mobile ? 18 : 22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.10),
            blurRadius: 70,
            offset: const Offset(0, 25),
          ),
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[_buildMobileBrand(), const SizedBox(height: 32)],

          _buildLoginHeader(),

          const SizedBox(height: 30),

          _buildLoginForm(),

          const SizedBox(height: 25),

          _buildRegisterLink(),

          const SizedBox(height: 26),

          _buildSecurityBox(),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE BRAND
  // =========================================================

  Widget _buildMobileBrand() {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF047857), Color(0xFF10B981)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartHealthcare',
              style: TextStyle(
                color: Color(0xFF064E3B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Healthcare Management System',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildLoginHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME BACK',
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'Sign in to your account',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'Enter your credentials to access the healthcare management system.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.7),
        ),
      ],
    );
  }

  // =========================================================
  // LOGIN FORM
  // =========================================================

  Widget _buildLoginForm() {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          _buildErrorBox(),
          const SizedBox(height: 20),
        ],

        _buildEmailField(),

        const SizedBox(height: 21),

        _buildPasswordField(),

        const SizedBox(height: 21),

        _buildLoginButton(),
      ],
    );
  }

  // =========================================================
  // EMAIL FIELD
  // =========================================================

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 49,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FCFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7E7DF)),
          ),
          child: TextField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: Color(0xFF064E3B), fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Color(0xFFA3B5AD), fontSize: 12),
              prefixIcon: SizedBox(
                width: 43,
                child: Center(
                  child: Text(
                    '@',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PASSWORD FIELD
  // =========================================================

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Secure login',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          height: 49,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FCFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7E7DF)),
          ),
          child: TextField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) {
                _login();
              }
            },
            style: const TextStyle(color: Color(0xFF064E3B), fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(
                color: Color(0xFFA3B5AD),
                fontSize: 12,
              ),
              prefixIcon: const SizedBox(
                width: 43,
                child: Center(
                  child: Text(
                    '*',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              suffixIcon: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  foregroundColor: const Color(0xFF059669),
                  disabledForegroundColor: const Color(0xFF059669)
                      .withValues(alpha: 0.5),
                ),
                child: Text(
                  _showPassword ? 'Hide' : 'Show',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LOGIN BUTTON
  // =========================================================

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          disabledBackgroundColor: const Color(0xFF059669)
              .withValues(alpha: 0.65),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'Signing in...',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 9),
                  Text(
                    '→',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
      ),
    );
  }

  // =========================================================
  // ERROR BOX
  // =========================================================

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REGISTER LINK
  // =========================================================

  Widget _buildRegisterLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          GestureDetector(
            onTap: _isLoading ? null : _openRegister,
            child: const Text(
              'Create an account',
              style: TextStyle(
                color: Color(0xFF059669),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY BOX
  // =========================================================

  Widget _buildSecurityBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text('🔒', style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & Protected',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your account information is protected using secure authentication.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
