import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_service.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_invite_model.dart';

/// Stream reativo de grupos do usuário logado.
/// Filtra automaticamente por uid via FirebaseService.
/// Retorna lista vazia quando o usuário não está autenticado.
final groupsStreamProvider = StreamProvider<List<GroupModel>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getGroupsStream();
});

/// Convites pendentes onde o utilizador atual é o convidado.
final pendingInvitesStreamProvider =
    StreamProvider<List<GroupInviteModel>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getPendingInvitesForMeStream();
});
