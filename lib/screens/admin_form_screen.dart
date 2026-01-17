import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';

class AdminFormScreen extends StatefulWidget {
  final UserModel? user; // Null for create, non-null for edit

  const AdminFormScreen({super.key, this.user});

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.viewer;
  bool _isLoading = false;
  bool _changePassword = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _usernameController.text = widget.user!.username;
      _fullNameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _selectedRole = widget.user!.role;
    } else {
      _changePassword = true; // Always require password for new users
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final uuid = const Uuid();
      final currentUser = context.read<AuthProvider>().currentUser;

      String passwordHash;
      if (isEditing && !_changePassword) {
        passwordHash = widget.user!.passwordHash;
      } else {
        passwordHash = UserModel.hashPassword(_passwordController.text);
      }

      final user = UserModel(
        id: isEditing ? widget.user!.id : uuid.v4(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        passwordHash: passwordHash,
        role: _selectedRole,
        isActive: isEditing ? widget.user!.isActive : true,
        mustChangePassword: isEditing ? widget.user!.mustChangePassword : true,
        createdAt: isEditing ? widget.user!.createdAt : now,
        createdBy: isEditing ? widget.user!.createdBy : currentUser?.username,
        updatedAt: now,
        updatedBy: currentUser?.username,
        lastLoginAt: isEditing ? widget.user!.lastLoginAt : null,
      );

      final provider = context.read<AuthProvider>();
      final success = isEditing
          ? await provider.updateUser(user)
          : await provider.createUser(user);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Usuário atualizado com sucesso'
                    : 'Usuário criado com sucesso',
              ),
              backgroundColor: const Color(AppConstants.primaryGreen),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro ao salvar usuário. Verifique se o nome de usuário ou email já existem.',
              ),
              backgroundColor: Color(AppConstants.deleteRed),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: const Color(AppConstants.deleteRed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Usuário' : 'Novo Usuário'),
        backgroundColor: const Color(AppConstants.primaryGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Info Section
              const Text(
                'Informações Pessoais',
                style: TextStyle(
                  color: Color(AppConstants.primaryGreen),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                validator: Validators.validateFullName,
                decoration: _buildInputDecoration(
                  'Nome Completo *',
                  Icons.person,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Account Info Section
              const Text(
                'Informações da Conta',
                style: TextStyle(
                  color: Color(AppConstants.primaryGreen),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                validator: Validators.validateUsername,
                decoration: _buildInputDecoration(
                  'Nome de Usuário *',
                  Icons.alternate_email,
                ),
                style: const TextStyle(color: Colors.white),
                enabled: !isEditing, // Username cannot be changed
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                validator: Validators.validateEmail,
                decoration: _buildInputDecoration('Email *', Icons.email),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              InputDecorator(
                decoration: _buildInputDecoration(
                  'Função / Permissão *',
                  Icons.security,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _selectedRole,
                    isDense: true,
                    dropdownColor: const Color(AppConstants.cardDark),
                    style: const TextStyle(color: Colors.white),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password Section
              if (isEditing)
                CheckboxListTile(
                  title: const Text(
                    'Alterar Senha',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _changePassword,
                  onChanged: (value) {
                    setState(() {
                      _changePassword = value ?? false;
                    });
                  },
                  activeColor: const Color(AppConstants.primaryGreen),
                  contentPadding: EdgeInsets.zero,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                ),

              if (_changePassword) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  validator: (value) {
                    if (!_changePassword) return null;
                    return Validators.validatePassword(value);
                  },
                  obscureText: true,
                  decoration: _buildInputDecoration(
                    isEditing ? 'Nova Senha *' : 'Senha *',
                    Icons.lock,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'A senha deve ter pelo menos 8 caracteres, maiúscula, minúscula e número.',
                  style: TextStyle(
                    color: const Color(
                      AppConstants.textGray,
                    ).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: isEditing ? 'Salvar Alterações' : 'Criar Usuário',
                onPressed: _handleSave,
                isLoading: _isLoading,
                icon: isEditing ? Icons.save : Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(AppConstants.textGray)),
      prefixIcon: Icon(icon, color: const Color(AppConstants.textGray)),
      filled: true,
      fillColor: const Color(AppConstants.cardDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(AppConstants.primaryGreen),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(AppConstants.deleteRed),
          width: 1,
        ),
      ),
    );
  }
}
