import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'admin_form_screen.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = context.read<AuthProvider>().getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      appBar: AppBar(
        title: const Text('Gerenciar Administradores'),
        backgroundColor: const Color(AppConstants.primaryGreen),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(AppConstants.primaryGreen),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(AppConstants.deleteRed),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar usuários: ${snapshot.error}',
                    style: const TextStyle(color: Color(AppConstants.textGray)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppConstants.primaryGreen),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum usuário encontrado',
                style: TextStyle(color: Color(AppConstants.textGray)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadUsers();
            },
            color: const Color(AppConstants.primaryGreen),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelf =
                    user.id == context.read<AuthProvider>().currentUser?.id;

                return Card(
                  color: const Color(AppConstants.cardDark),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(AppConstants.cardMedium),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(AppConstants.primaryGreen),
                      child: Text(
                        user.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Color(AppConstants.textGray),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              AppConstants.primaryGreen,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.roleDisplayName,
                            style: const TextStyle(
                              color: Color(AppConstants.primaryGreen),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelf
                        ? const Chip(
                            label: Text(
                              'Você',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: Color(AppConstants.textGray),
                            padding: EdgeInsets.zero, // reduce padding
                            visualDensity: VisualDensity.compact, // reduce size
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(AppConstants.textGray),
                            ),
                            onPressed: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminFormScreen(user: user),
                                ),
                              );

                              if (updated == true && mounted) {
                                _loadUsers();
                              }
                            },
                          ),
                    onLongPress: isSelf
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(
                                  AppConstants.cardDark,
                                ),
                                title: const Text(
                                  'Excluir Usuário',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Text(
                                  'Tem certeza que deseja excluir ${user.fullName}?',
                                  style: const TextStyle(
                                    color: Color(AppConstants.textGray),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(
                                        AppConstants.deleteRed,
                                      ),
                                    ),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              if (!context.mounted) return;
                              final authProvider = context.read<AuthProvider>();
                              final success = await authProvider.deleteUser(
                                user.id,
                              );

                              if (!context.mounted) return;
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Usuário excluído com sucesso',
                                    ),
                                    backgroundColor: Color(
                                      AppConstants.primaryGreen,
                                    ),
                                  ),
                                );
                                _loadUsers();
                              }
                            }
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AdminFormScreen()),
          );

          if (created == true && mounted) {
            _loadUsers();
          }
        },
        backgroundColor: const Color(AppConstants.primaryGreen),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
