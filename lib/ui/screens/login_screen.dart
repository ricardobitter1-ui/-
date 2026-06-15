import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../widgets/eximium/eximium.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_isSignUp) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro Google: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;

    return Scaffold(
      body: ExAppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ExSpace.s8,
                ExSpace.s8,
                ExSpace.s8,
                ExSpace.s12,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo tile com gradiente + glow.
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: ExColors.gradientBrand,
                        borderRadius: BorderRadius.circular(ExRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: ExColors.brandGreen.withValues(alpha: 0.35),
                            blurRadius: 32,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: ExSpace.s6),
                    Text(
                      _isSignUp ? 'Criar conta' : 'Bem-vindo de volta',
                      style: ExText.display(c.textPrimary),
                    ),
                    const SizedBox(height: ExSpace.s2),
                    Text(
                      _isSignUp
                          ? 'Cadastre-se para acessar suas tarefas, grupos e lembretes.'
                          : 'Entre para acessar suas tarefas, grupos e lembretes.',
                      style: ExText.bodyLg(c.textSecondary),
                    ),
                    const SizedBox(height: ExSpace.s8),
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ExLoginField(
                            label: 'E-mail',
                            icon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                v!.isEmpty ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: ExSpace.s5),
                          _ExLoginField(
                            label: 'Senha',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleAuth(),
                            validator: (v) =>
                                v!.length < 6 ? 'Mínimo 6 chars' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ExSpace.s6),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: ExSpace.s2),
                          child: CircularProgressIndicator(
                            color: ExColors.brandGreen,
                          ),
                        ),
                      )
                    else
                      ExButton(
                        label: _isSignUp ? 'Cadastrar' : 'Entrar',
                        onPressed: _handleAuth,
                        expand: true,
                        size: ExButtonSize.lg,
                      ),
                    const SizedBox(height: ExSpace.s5),
                    _buildDivider(c),
                    const SizedBox(height: ExSpace.s5),
                    _buildGoogleButton(c),
                    const SizedBox(height: ExSpace.s6),
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text.rich(
                          TextSpan(
                            style: ExText.body(c.textSecondary),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Já tem uma conta? '
                                    : 'Não tem conta? ',
                              ),
                              TextSpan(
                                text: _isSignUp ? 'Entre' : 'Cadastre-se',
                                style: ExText.body(c.textAccent).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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

  Widget _buildDivider(ExColors c) {
    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ExSpace.s4),
          child: Text('OU', style: ExText.label(c.textMuted)),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }

  Widget _buildGoogleButton(ExColors c) {
    return Opacity(
      opacity: _isLoading ? 0.5 : 1,
      child: Material(
        color: c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExRadius.pill),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(ExRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ExSpace.s4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  height: 20,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 24,
                  ),
                ),
                const SizedBox(width: ExSpace.s3),
                Text(
                  'Continuar com Google',
                  style: ExText.h3(c.textPrimary).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de input do login: label UPPERCASE, ícone à esquerda (verde no foco),
/// borda verde + focusRing quando focado.
class _ExLoginField extends StatefulWidget {
  const _ExLoginField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<_ExLoginField> createState() => _ExLoginFieldState();
}

class _ExLoginFieldState extends State<_ExLoginField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final Color labelColor = _focused ? c.textAccent : c.textSecondary;
    final Color iconColor = _focused ? ExColors.brandGreen : c.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(widget.label.toUpperCase(), style: ExText.label(labelColor)),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ExRadius.md),
            boxShadow: _focused ? ExEffects.focusRing : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            style: ExText.bodyLg(c.textPrimary).copyWith(fontSize: 14),
            cursorColor: ExColors.brandGreen,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: c.surface2,
              prefixIcon: Icon(widget.icon, size: 18, color: iconColor),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ExRadius.md),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ExRadius.md),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ExRadius.md),
                borderSide: const BorderSide(
                  color: ExColors.brandGreen,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ExRadius.md),
                borderSide: BorderSide(color: c.errorText),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ExRadius.md),
                borderSide: BorderSide(color: c.errorText, width: 1.5),
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}
