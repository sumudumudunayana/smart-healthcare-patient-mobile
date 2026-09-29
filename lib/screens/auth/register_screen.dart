import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage);

    _authService = AuthService(
      apiClient,
      secureStorage,
    );
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Required fields
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    // Name validation
    if (fullName.length < 2) {
      _showError('Please enter a valid full name.');
      return;
    }

    // Email validation
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    // Password validation
    if (password.length < 6) {
      _showError('Password must contain at least 6 characters.');
      return;
    }

    // Password confirmation
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone.isEmpty ? null : phone,
        password: password,
      );

      if (!mounted) return;

      // Registration endpoint returns authentication data.
      // We clear it here because this screen follows the web app flow:
      // registration succeeds → user goes to Login.
      final secureStorage = SecureStorageService();
      await secureStorage.clearAuthData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text(
      'Account created successfully. Please sign in.',
    ),
    backgroundColor: Color(0xFF059669),
  ),
);

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

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
  // DESKTOP
  // =========================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 58,
          child: _buildBrandPanel(),
        ),
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
                  vertical: 35,
                ),
                child: _buildRegisterCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BRAND PANEL
  // =========================================================

  Widget _buildBrandPanel() {
    return Container(
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
          stops: [
            0.0,
            0.42,
            0.72,
            1.0,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 70,
          vertical: 55,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrand(
              light: true,
            ),

            const Spacer(),

            _buildBrandContent(),

            const SizedBox(height: 50),

            _buildFeatures(),

            const Spacer(),

            Row(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand({
    required bool light,
  }) {
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
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  )
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
                color: light
                    ? Colors.white
                    : const Color(0xFF064E3B),
                fontSize: 22,
                fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: const Text(
            'JOIN SMART HEALTHCARE',
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
          'Your Healthcare.\nConnected.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 52,
            height: 1.02,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
          ),
        ),

        const SizedBox(height: 20),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 550,
          ),
          child: Text(
            'Create your account and access a secure healthcare '
            'management platform designed to connect healthcare '
            'teams and improve everyday operations.',
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

  Widget _buildFeatures() {
    return Column(
      children: [
        _buildFeature(
          'Secure Account',
          'Your information is protected',
        ),
        const SizedBox(height: 17),
        _buildFeature(
          'Easy Access',
          'Simple and convenient healthcare management',
        ),
        const SizedBox(height: 17),
        _buildFeature(
          'Connected Healthcare',
          'Everything designed around better care',
        ),
      ],
    );
  }

  Widget _buildFeature(
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
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
  // MOBILE
  // =========================================================

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFECFDF5),
            Color(0xFFF5FAF7),
            Color(0xFFF0FDF4),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 25,
          ),
          child: _buildRegisterCard(
            mobile: true,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // REGISTER CARD
  // =========================================================

  Widget _buildRegisterCard({
    bool mobile = false,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 560,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 25 : 45,
        vertical: mobile ? 32 : 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          mobile ? 18 : 22,
        ),
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
          if (mobile) ...[
            _buildMobileBrand(),
            const SizedBox(height: 28),
          ],

          _buildHeader(),

          const SizedBox(height: 25),

          _buildForm(
            mobile: mobile,
          ),

          const SizedBox(height: 21),

          _buildLoginLink(),

          const SizedBox(height: 21),

          _buildSecurityBox(),
        ],
      ),
    );
  }

  Widget _buildMobileBrand() {
    return _buildBrand(
      light: false,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GET STARTED',
          style: TextStyle(
            color: Color(0xFF059669),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Create your account',
          style: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 29,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Register your account to get started with SmartHealthcare.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FORM
  // =========================================================

  Widget _buildForm({
    required bool mobile,
  }) {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          _buildErrorBox(),
          const SizedBox(height: 18),
        ],

        _buildInputField(
          label: 'Full Name',
          controller: _fullNameController,
          hint: 'Enter your full name',
          icon: '👤',
          keyboardType: TextInputType.name,
        ),

        const SizedBox(height: 17),

        if (mobile) ...[
          _buildInputField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'Enter your email',
            icon: '@',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 17),
          _buildInputField(
            label: 'Phone Number',
            optional: true,
            controller: _phoneController,
            hint: 'Phone number',
            icon: '☎',
            keyboardType: TextInputType.phone,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Email Address',
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: '@',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  label: 'Phone Number',
                  optional: true,
                  controller: _phoneController,
                  hint: 'Phone number',
                  icon: '☎',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),

        const SizedBox(height: 17),

        if (mobile) ...[
          _buildPasswordField(
            label: 'Password',
            controller: _passwordController,
            hint: 'Create a password',
            showPassword: _showPassword,
            onToggle: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
          const SizedBox(height: 17),
          _buildPasswordField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Confirm password',
            showPassword: _showConfirmPassword,
            onToggle: () {
              setState(() {
                _showConfirmPassword = !_showConfirmPassword;
              });
            },
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildPasswordField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Create a password',
                  showPassword: _showPassword,
                  onToggle: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPasswordField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  hint: 'Confirm password',
                  showPassword: _showConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 13),

        Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '✓',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Password must contain at least 6 characters.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9,
              ),
            ),
          ],
        ),

        const SizedBox(height: 17),

        SizedBox(
          width: double.infinity,
          height: 49,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              disabledBackgroundColor:
                  const Color(0xFF059669).withValues(alpha: 0.65),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'Creating account...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(
                        '→',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INPUT
  // =========================================================

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String icon,
    required TextInputType keyboardType,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text(
                'Optional',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FCFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFD7E7DF),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !_isLoading,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 11,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA3B5AD),
                fontSize: 11,
              ),
              prefixIcon: SizedBox(
                width: 45,
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PASSWORD FIELD
  // =========================================================

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FCFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFD7E7DF),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !_isLoading,
            obscureText: !showPassword,
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 11,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA3B5AD),
                fontSize: 11,
              ),
              prefixIcon: const SizedBox(
                width: 45,
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
                onPressed: _isLoading ? null : onToggle,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  foregroundColor: const Color(0xFF059669),
                  disabledForegroundColor:
                      const Color(0xFF059669).withValues(alpha: 0.5),
                ),
                child: Text(
                  showPassword ? 'Hide' : 'Show',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
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
  // LOGIN LINK
  // =========================================================

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
            child: const Text(
              'Sign in',
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
  // SECURITY
  // =========================================================

  Widget _buildSecurityBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFDCFCE7),
        ),
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
              child: Text(
                '🔒',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your information is secure',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'We use secure authentication to protect your account information.',
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