import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../data/models/group_invite_model.dart';
import '../../data/services/firebase_service.dart';
import 'group_invite_decision_sheet.dart';

/// Prioridade: deep link pendente → depois convites do stream (e-mail / UID).
class PendingInviteCoordinator extends ConsumerStatefulWidget {
  const PendingInviteCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PendingInviteCoordinator> createState() =>
      _PendingInviteCoordinatorState();
}

class _PendingInviteCoordinatorState extends ConsumerState<PendingInviteCoordinator>
    with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  final Set<String> _dismissedIds = {};
  String? _pendingShareToken;
  bool _showingSheet = false;
  List<GroupInviteModel> _lastInvites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    // ref.listen no build registava listeners em cada rebuild e pode corromper
    // a árvore; listenManual após o 1.º frame mantém uma única subscrição.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual(
        pendingInvitesStreamProvider,
        (previous, next) {
          next.whenData((invites) {
            _lastInvites = invites;
            SchedulerBinding.instance
                .addPostFrameCallback((_) => _tryShowNext(invites));
          });
        },
        fireImmediately: true,
      );
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleIncomingUri(initial);
      }
    } catch (_) {}
    _linkSub = _appLinks.uriLinkStream.listen(_handleIncomingUri);
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme != 'exmtodo' || uri.host != 'invite') return;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return;
    setState(() => _pendingShareToken = token);
    SchedulerBinding.instance.addPostFrameCallback((_) => _tryShowNext(_lastInvites));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _tryShowNext(_lastInvites));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _tryShowNext(List<GroupInviteModel> streamInvites) async {
    if (!mounted || _showingSheet) return;

    final fs = ref.read(firebaseServiceProvider);
    final candidates = <GroupInviteModel>[];

    if (_pendingShareToken != null) {
      try {
        final byLink =
            await fs.getPendingInviteByShareToken(_pendingShareToken!);
        if (byLink == null) {
          setState(() => _pendingShareToken = null);
        } else if (!_dismissedIds.contains(byLink.id)) {
          candidates.add(byLink);
        }
      } catch (_) {
        setState(() => _pendingShareToken = null);
      }
    }

    for (final inv in streamInvites) {
      if (!_dismissedIds.contains(inv.id) &&
          !candidates.any((c) => c.id == inv.id)) {
        candidates.add(inv);
      }
    }

    candidates.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (candidates.isEmpty) {
      return;
    }

    final invite = candidates.first;
    if (!mounted) return;
    _showingSheet = true;

    final result = await showGroupInviteDecisionSheet(
      context: context,
      invite: invite,
    );

    _showingSheet = false;
    if (!mounted) return;

    if (result == null) {
      _dismissedIds.add(invite.id);
    } else if (result) {
      _pendingShareToken = null;
      try {
        await fs.acceptInviteByDocId(invite.id);
        _dismissedIds.add(invite.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrou no grupo.')),
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
      }
    } else {
      _pendingShareToken = null;
      try {
        await fs.declineInviteByDocId(invite.id);
        _dismissedIds.add(invite.id);
      } catch (_) {}
    }

    SchedulerBinding.instance
        .addPostFrameCallback((_) => _tryShowNext(_lastInvites));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
