import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final nik = _nikController.text.trim();
    final password = _passwordController.text.trim();

    if (nik.isEmpty || password.isEmpty) {
      AppToast.error(context, 'Harap isi NIK dan Password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService().login(nik, password);
      if (mounted) {
        if (result['success'] == true) {
          final user = result['data']['user'];
          final role = user['role']?.toString().toLowerCase();

          if (role == 'admin' || role == 'kader') {
            ApiService().clearSession();
            AppToast.error(context, 'Akses ditolak. Admin dan Kader hanya dapat login melalui Web.');
            setState(() => _isLoading = false);
            return;
          }

          AppToast.success(context, 'Login Berhasil!');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          throw result['message'] ?? 'Login gagal';
        }
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, '$error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primary.withOpacity(0.08),
                        Colors.white,
                        AppTheme.primarySoft.withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          SizedBox(height: Responsive.h(60)),
                          _buildHeader(),
                          SizedBox(height: Responsive.h(36)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.pad(30)),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _nikController,
                                  label: 'NIK',
                                  icon: Icons.badge_outlined,
                                  hint: 'Masukkan NIK Anda',
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: Responsive.h(20)),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  hint: 'Masukkan password',
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onToggleVisibility: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                SizedBox(height: Responsive.h(36)),
                                _buildLoginButton(),
                                SizedBox(height: Responsive.h(30)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(bottom: Responsive.h(32)),
                            child: Text(
                              'TaniSehat v1.0',
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: Responsive.sp(12),
                                letterSpacing: 0.5,
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
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.pad(18)),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: Responsive.w(56),
              height: Responsive.w(56),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: Responsive.h(20)),
        Text(
          'TaniSehat',
          style: TextStyle(
            fontSize: Responsive.sp(30),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.primary,
          ),
        ),
        SizedBox(height: Responsive.h(8)),
        Text(
          'Solusi Kesehatan Petani Indonesia',
          style: TextStyle(
            fontSize: Responsive.sp(14),
            color: AppTheme.textMedium.withOpacity(0.7),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.sp(13),
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: Responsive.h(8)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.radius(14)),
            boxShadow: AppTheme.shadowSm,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: Responsive.sp(15), color: AppTheme.textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: Responsive.sp(14)),
              prefixIcon: Icon(icon, color: AppTheme.primarySoft, size: Responsive.icon(22)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.grey.shade400,
                        size: Responsive.icon(22),
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(14)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: Responsive.h(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: Responsive.h(52),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        gradient: _isLoading ? null : AppTheme.primaryGradient,
        color: _isLoading ? Colors.grey.shade300 : null,
        boxShadow: _isLoading ? [] : AppTheme.shadowLg,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
        ),
        child: _isLoading
            ? SizedBox(
                width: Responsive.w(24),
                height: Responsive.w(24),
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                'MASUK',
                style: TextStyle(
                  fontSize: Responsive.sp(17),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
