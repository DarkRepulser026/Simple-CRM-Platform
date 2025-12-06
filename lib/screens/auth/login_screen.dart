import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/auth/auth_service.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_config.dart';
// Giả định bạn đã có widget này, nếu chưa hãy dùng code cũ hoặc placeholder
import '../../widgets/web_google_sign_in_button.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;
  String _version = '';
  
  // Màu chủ đạo cho CRM (Navy Blue & Slate)
  final Color _primaryColor = const Color(0xFF0F172A); 
  final Color _accentColor = const Color(0xFF3B82F6);
  final Color _surfaceColor = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _authService = locator<AuthService>();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    _handleSignIn(() => _authService.signInWithGoogle());
  }

  Future<void> _signInWithGoogleIdToken(String idToken) async {
    _handleSignIn(() => _authService.signInWithGoogleIdToken(idToken));
  }

  Future<void> _handleSignIn(Future<bool> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await signInMethod();
      if (success && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else if (mounted) {
        setState(() => _errorMessage = 'Authentication failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _quickLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Direct authentication with email/password (assuming auth service supports this)
      // This would typically call an email/password authentication method
      final success = await _authService.signInWithEmailPassword(email, password);
      if (success && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else if (mounted) {
        setState(() => _errorMessage = 'Quick login failed. Please ensure the account exists.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildQuickLoginButton(String label, String email, Color color) {
    return FilledButton.tonal(
      onPressed: _isLoading ? null : () => _quickLogin(email, 'test123'),
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng LayoutBuilder để responsive
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // === DESKTOP / TABLET LAYOUT (Split Screen) ===
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side: Hero Section (Branding)
        Expanded(
          flex: 5,
          child: Container(
            color: _primaryColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Abstract decorative circles
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentColor.withOpacity(0.1),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(isLight: true),
                      const SizedBox(height: 32),
                      Text(
                        'Manage Your\nCustomer Relationships\nLike a Pro.',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'The all-in-one platform to track leads, manage pipelines, and grow your business efficiency.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey[100],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Feature Pills
                      Row(
                        children: [
                          _buildFeaturePill(Icons.analytics_outlined, 'Analytics'),
                          const SizedBox(width: 12),
                          _buildFeaturePill(Icons.people_outline, 'Contacts'),
                          const SizedBox(width: 12),
                          _buildFeaturePill(Icons.sync, 'Real-time'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side: Login Form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: _buildLoginFormContent(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // === MOBILE LAYOUT ===
  Widget _buildMobileLayout() {
    return Container(
      color: _surfaceColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(isLight: false),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildLoginFormContent(),
                ),
                const SizedBox(height: 24),
                if (_version.isNotEmpty)
                  Text(
                    'Version $_version',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === SHARED WIDGETS ===

  Widget _buildLogo({required bool isLight}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isLight ? Colors.white : _primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
               if (!isLight) BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 10, offset: Offset(0,4))
            ]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Fallback icon nếu asset lỗi
            child: Image.asset(
              'assets/icon/icon.png',
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Icon(Icons.business, color: isLight ? _primaryColor : Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRM PROJECT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isLight ? Colors.white : _primaryColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ENTERPRISE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isLight ? _accentColor : _primaryColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access your dashboard',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        // Google Button Wrapper
        if (kIsWeb)
          WebGoogleSignInButton(
            clientId: ApiConfig.googleClientId,
            onSuccess: (idToken) => _signInWithGoogleIdToken(idToken),
            onError: (error) {
               setState(() {
                 _errorMessage = 'Sign-in error: $error';
                 _isLoading = false;
               });
            },
          )
        else
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isLoading 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : FaIcon(FontAwesomeIcons.google, color: Colors.red[600], size: 20),
              label: Text(
                _isLoading ? 'Signing in...' : 'Sign in with Google',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Debug Quick Login (only in development)
        if (kDebugMode)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🔧 Debug: Quick Login',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickLoginButton('Admin', 'admin@example.com', Colors.red),
                  _buildQuickLoginButton('Manager', 'manager@example.com', Colors.orange),
                  _buildQuickLoginButton('Agent', 'agent@example.com', Colors.blue),
                  _buildQuickLoginButton('Viewer', 'user@example.com', Colors.green),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),

        // Footer / Terms
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Secured by Enterprise SSO',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                Text('By continuing, you agree to our', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                InkWell(
                  onTap: () {}, // Add logic
                  child: Text('Terms', style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Text('&', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                InkWell(
                  onTap: () {}, // Add logic
                  child: Text('Privacy Policy', style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}