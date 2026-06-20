import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../business_logic/providers/group_provider.dart';
import '../business_logic/voice_shopping_list_context.dart';
import '../data/models/group_type.dart';
import '../data/services/auth_service.dart';
import '../data/services/firebase_service.dart';

const kGroupTypeMigrationSuggestPrefsKey = 'group_type_migration_suggest_v1';

/// Sugere conversão para lista contínua (uma vez) em grupos cujo nome bate com o regex legado.
Future<void> maybeSuggestContinuousGroupConversion(
  BuildContext context,
  WidgetRef ref,
) async {
  final uid = ref.read(authStateProvider).value?.uid;
  if (uid == null) return;

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(kGroupTypeMigrationSuggestPrefsKey) == true) return;

  final groups = ref.read(groupsStreamProvider).value ?? const [];
  final candidates = groups.where((g) {
    if (g.type != GroupType.tasks) return false;
    if (!g.isAdmin(uid)) return false;
    return VoiceShoppingListContext.isShoppingListGroupName(g.name);
  }).toList();

  await prefs.setBool(kGroupTypeMigrationSuggestPrefsKey, true);
  if (!context.mounted || candidates.isEmpty) return;

  final g = candidates.first;
  final convert = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Converter "${g.name}"?'),
      content: const Text(
        'Este grupo parece uma lista de compras. Quer convertê-lo para '
        'Lista contínua? Itens comprados poderão voltar com um toque e '
        'não aparecerão nas contagens da home.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Manter como tarefas'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Converter'),
        ),
      ],
    ),
  );

  if (convert == true) {
    try {
      await ref.read(firebaseServiceProvider).updateGroupType(
            g.id,
            GroupType.continuous,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${g.name} agora é uma lista contínua.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao converter: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
