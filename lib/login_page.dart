import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

import 'settings_provider.dart';
import 'main_navigation_screen.dart';
import 'update_notifier.dart';
import 'auto_translator.dart';

class LoginPage extends StatefulWidget {
  final bool initialIsLogin;

  const LoginPage({super.key, this.initialIsLogin = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for email and password text fields, and FirebaseAuth instance.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  
  // Tracks whether the form is in Login or Sign-Up mode, loading state, and error display.
  late bool _isLogin = widget.initialIsLogin;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  final Color _primaryIndigo = const Color(0xFF5442F5);

  // Loads saved 'Remember Me' state and pre-fills the email input if enabled.
  @override
  void initState() {
    super.initState();
    // Pre-fill remember me state if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _rememberMe = settings.rememberMe;
        if (_rememberMe) {
          _emailController.text = settings.rememberedEmail;
        }
      });
      UpdateNotifier.checkAndShowWhatsNew(context);
    });
  }

  // Disposes email and password controllers when leaving the login screen.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handles Login and Sign-Up form submission via FirebaseAuth, links credentials
  // if upgrading a Guest user, saves 'Remember Me' preferences, and navigates into the app.
  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);

      if (_isLogin) {
        await _auth
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
            .timeout(const Duration(seconds: 15));
        settings.setGuestUser(false);
      } else {
        if (settings.isGuestUser && _auth.currentUser != null) {
          final credential = EmailAuthProvider.credential(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          try {
            await _auth.currentUser!
                .linkWithCredential(credential)
                .timeout(const Duration(seconds: 15));
          } on FirebaseAuthException catch (e) {
            if (e.code == 'provider-already-linked') {
              await _auth
                  .createUserWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                  )
                  .timeout(const Duration(seconds: 15));
            } else {
              rethrow;
            }
          }
          settings.setGuestUser(false);
        } else {
          await _auth
              .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              )
              .timeout(const Duration(seconds: 15));
          settings.setGuestUser(false);
        }
      }

      // Save remember me choice
      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        settings.updateRememberMe(_rememberMe);
        if (_rememberMe) {
          settings.updateRememberedEmail(_emailController.text.trim());
        } else {
          settings.updateRememberedEmail('');
        }
        // If LoginPage was pushed on top of MainNavigationScreen (e.g., Guest clicking Login),
        // pop back to the root route so MainNavigationScreen is visible.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyAuthError(e.code, e.message);
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyAuthError(e.code, e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Maps Firebase / Platform auth error codes to clear, user-friendly messages.
  String _friendlyAuthError(String code, String? rawMessage) {
    final normalized = code.toLowerCase();
    if (normalized.contains('invalid-credential') ||
        normalized.contains('invalid_credential') ||
        normalized.contains('wrong-password') ||
        normalized.contains('user-not-found')) {
      return tr(
        context,
        'Incorrect email or password. If you do not have an account yet, please tap Sign Up below.',
        'メールアドレスまたはパスワードが正しくありません。アカウントをお持ちでない場合は下のサインアップをタップしてください。',
        'အီးမေးလ် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည်။ အကောင့်မရှိသေးပါက အောက်ပါ အကောင့်ဖွင့်ရန် ကို နှိပ်ပါ။',
      );
    }
    if (normalized.contains('email-already-in-use')) {
      return tr(
        context,
        'This email is already registered. Please switch to Login.',
        'このメールアドレスは既に登録されています。ログインに切り替えてください。',
        'ဤအီးမေးလ်သည် မှတ်ပုံတင်ပြီးသား ဖြစ်ပါသည်။ အကောင့်ဝင်ရန်သို့ ပြောင်းပါ။',
      );
    }
    if (normalized.contains('weak-password')) {
      return tr(
        context,
        'Password should be at least 6 characters.',
        'パスワードは6文字以上で入力してください。',
        'စကားဝှက်သည် အနည်းဆုံး စာလုံးရေ ၆ လုံး ရှိရပါမည်။',
      );
    }
    if (normalized.contains('invalid-email')) {
      return tr(
        context,
        'Please enter a valid email address.',
        '有効なメールアドレスを入力してください。',
        'ကျေးဇူးပြု၍ မှန်ကန်သော အီးမေးလ်လိပ်စာကို ထည့်သွင်းပါ။',
      );
    }
    return rawMessage ?? AppLocalizations.of(context)!.authFailed;
  }

  // Sends a Firebase password reset email to the address entered in _emailController.
  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = l10n.enterEmailReset;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetEmailSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? l10n.failedResetEmail;
      });
    } catch (e) {
      setState(() {
        _errorMessage = l10n.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Builds the authentication UI with email/password inputs, Remember Me checkbox,
  // Forgot Password action, Login/Sign-Up toggle, and Continue as Guest option.
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isActiveGuest = settings.isGuestUser && _auth.currentUser != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isActiveGuest
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(),
                            ),
                          );
                        }
                      },
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 80,
                        color: _primaryIndigo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? AppLocalizations.of(context)!.welcomeBack : AppLocalizations.of(context)!.createAccount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),
                
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    prefixIcon: Icon(Icons.email_outlined, color: _primaryIndigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryIndigo, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    prefixIcon: Icon(Icons.lock_outline, color: _primaryIndigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryIndigo, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: _primaryIndigo,
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.rememberMe,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (_isLogin)
                      TextButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: TextStyle(
                            color: _primaryIndigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.signUp,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? AppLocalizations.of(context)!.dontHaveAccount
                        : AppLocalizations.of(context)!.alreadyHaveAccount,
                    style: TextStyle(color: _primaryIndigo),
                  ),
                ),
                if (_isLogin && !isActiveGuest)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            try {
                              final randomNum = DateTime.now().millisecondsSinceEpoch.toString();
                              final fakeEmail = 'guest_$randomNum@easybudget.local';
                              final fakePassword = 'guest_$randomNum';
                              
                              await _auth
                                  .createUserWithEmailAndPassword(
                                    email: fakeEmail,
                                    password: fakePassword,
                                  )
                                  .timeout(const Duration(seconds: 15));

                              if (mounted) {
                                final settings = Provider.of<SettingsProvider>(context, listen: false);
                                settings.setGuestUser(true);
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              setState(() {
                                _errorMessage = "Guest Login Error: ${e.code} - ${e.message}";
                              });
                            } catch (e) {
                              setState(() {
                                _errorMessage = "Could not sign in as guest: $e";
                              });
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                    child: Text(
                      AppLocalizations.of(context)!.continueAsGuest,
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
