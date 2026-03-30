import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../data/services/firebase_service.dart';
import '../widgets/create_group_sheet.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseServiceProvider).ensureCollaborationBackfill();
    });
  }

  Future<void> _openCreateGroupModal(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const CreateGroupSheet(),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo criado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grupos')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum grupo ainda.\nCrie seu primeiro Grupo de Elite!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final g = groups[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: CircleAvatar(
                  backgroundColor: _hexToColor(g.color).withValues(alpha: 0.12),
                  child: Icon(
                    Icons.groups_rounded,
                    color: _hexToColor(g.color),
                  ),
                ),
                title: Text(
                  g.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${g.members.length} membro(s)'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  if (g.id.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Grupo inválido. Atualize e tente novamente.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: g),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGroupModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Grupo'),
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final raw = hex.trim();
  final sanitized = raw.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
  if (sanitized.isEmpty) return const Color(0xFF0052FF);

  final normalized = sanitized.length > 8
      ? sanitized.substring(sanitized.length - 8)
      : sanitized;

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return const Color(0xFF0052FF);

  if (normalized.length <= 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value & 0xFFFFFFFF);
}
