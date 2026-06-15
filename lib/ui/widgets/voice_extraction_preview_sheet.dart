import 'package:flutter/material.dart';

import '../../business_logic/voice_extraction_plan.dart';
import '../../data/models/extracted_voice_task_dto.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_type.dart';
import '../../data/models/tag_model.dart';
import '../../business_logic/voice_task_group_resolver.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'eximium/eximium.dart';
import 'group_tag_name_color_dialog.dart';

/// Resultado do bottom sheet de confirmação do ditado.
class VoiceExtractionPreviewResult {
  final VoiceExtractionPlan plan;

  const VoiceExtractionPreviewResult({required this.plan});
}

/// Mostra resumo editável antes de gravar tarefas e etiquetas do ditado.
Future<VoiceExtractionPreviewResult?> showVoiceExtractionPreviewSheet({
  required BuildContext context,
  required VoiceExtractionPlan initialPlan,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required Map<String, List<TagModel>> tagsByGroupId,
  String? transcript,
}) {
  return showModalBottomSheet<VoiceExtractionPreviewResult?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.ex.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ExRadius.xl)),
    ),
    builder: (ctx) => _VoiceExtractionPreviewBody(
      initialPlan: initialPlan,
      groups: groups,
      forcedGroupId: forcedGroupId,
      tagsByGroupId: tagsByGroupId,
      transcript: transcript,
    ),
  );
}

class _VoiceExtractionPreviewBody extends StatefulWidget {
  const _VoiceExtractionPreviewBody({
    required this.initialPlan,
    required this.groups,
    required this.forcedGroupId,
    required this.tagsByGroupId,
    this.transcript,
  });

  final VoiceExtractionPlan initialPlan;
  final List<GroupModel> groups;
  final String? forcedGroupId;
  final Map<String, List<TagModel>> tagsByGroupId;
  final String? transcript;

  @override
  State<_VoiceExtractionPreviewBody> createState() =>
      _VoiceExtractionPreviewBodyState();
}

class _VoiceExtractionPreviewBodyState
    extends State<_VoiceExtractionPreviewBody> {
  late List<ExtractedVoiceTaskDto> _tasks;
  late List<VoiceTagToCreate> _tagsToCreate;
  bool _transcriptExpanded = false;

  @override
  void initState() {
    super.initState();
    _tasks = List<ExtractedVoiceTaskDto>.from(widget.initialPlan.tasks);
    _tagsToCreate =
        List<VoiceTagToCreate>.from(widget.initialPlan.tagsToCreate);
  }

  void _updateTask(int index, ExtractedVoiceTaskDto dto) {
    setState(() => _tasks[index] = dto);
  }

  void _removeTask(int index) {
    setState(() => _tasks.removeAt(index));
  }

  void _updateTag(int index, VoiceTagToCreate tag) {
    setState(() => _tagsToCreate[index] = tag);
  }

  void _removeTag(int index) {
    setState(() => _tagsToCreate.removeAt(index));
  }

  bool _isShoppingItem(ExtractedVoiceTaskDto dto) {
    final gid = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: widget.groups,
      forcedGroupId: widget.forcedGroupId,
    );
    if (gid == null) return false;
    for (final g in widget.groups) {
      if (g.id == gid) return g.type == GroupType.continuous;
    }
    return false;
  }

  bool get _allShoppingItems =>
      _tasks.isNotEmpty && _tasks.every(_isShoppingItem);

  void _confirm() {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma tarefa.')),
      );
      return;
    }
    final rebuilt = buildVoiceExtractionPlan(
      tasks: _tasks,
      groups: widget.groups,
      forcedGroupId: widget.forcedGroupId,
      tagsByGroupId: widget.tagsByGroupId,
    );
    final colorByKey = {
      for (final t in _tagsToCreate) t.dedupeKey: t.color,
    };
    final nameByKey = {
      for (final t in _tagsToCreate) t.dedupeKey: t.name,
    };
    final mergedTags = rebuilt.tagsToCreate.map((t) {
      final color = colorByKey[t.dedupeKey];
      final name = nameByKey[t.dedupeKey];
      return t.copyWith(
        color: color ?? t.color,
        name: name ?? t.name,
      );
    }).toList();

    Navigator.of(context).pop(
      VoiceExtractionPreviewResult(
        plan: VoiceExtractionPlan(
          tasks: _tasks,
          tagsToCreate: mergedTags,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(ExRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: ExSpace.s4),
            Text(
              'Confirmar ditado',
              textAlign: TextAlign.center,
              style: ExText.h2(c.textPrimary),
            ),
            const SizedBox(height: ExSpace.s2),
            Text(
              'Revise o que será criado. Pode editar ou remover itens.',
              textAlign: TextAlign.center,
              style: ExText.body(c.textSecondary),
            ),
            const SizedBox(height: ExSpace.s4),
            Expanded(
              child: ListView(
                children: [
                  if (widget.transcript != null &&
                      widget.transcript!.trim().isNotEmpty) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(
                        () => _transcriptExpanded = !_transcriptExpanded,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              _transcriptExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 20,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Transcrição',
                              style: ExText.body(c.textSecondary)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_transcriptExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          widget.transcript!.trim(),
                          style: ExText.body(c.textSecondary)
                              .copyWith(fontSize: 12, height: 1.35),
                        ),
                      ),
                  ],
                  if (_tagsToCreate.isNotEmpty) ...[
                    _sectionTitle('Categorias a criar'),
                    const SizedBox(height: 8),
                    ...List.generate(_tagsToCreate.length, (i) {
                      final tag = _tagsToCreate[i];
                      return _TagCreateCard(
                        tag: tag,
                        onChanged: (t) => _updateTag(i, t),
                        onRemove: () => _removeTag(i),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                  _sectionTitle(
                    _allShoppingItems ? 'Itens da lista' : 'Tarefas a criar',
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_tasks.length, (i) {
                    final dto = _tasks[i];
                    if (_isShoppingItem(dto)) {
                      return _ShoppingItemPreviewCard(
                        dto: dto,
                        onChanged: (d) => _updateTask(i, d),
                        onRemove: _tasks.length > 1
                            ? () => _removeTask(i)
                            : null,
                      );
                    }
                    return _TaskPreviewCard(
                      dto: dto,
                      groups: widget.groups,
                      tagsByGroupId: widget.tagsByGroupId,
                      onChanged: (d) => _updateTask(i, d),
                      onRemove: _tasks.length > 1
                          ? () => _removeTask(i)
                          : null,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: ExSpace.s3),
            Row(
              children: [
                Expanded(
                  child: ExButton(
                    label: 'Cancelar',
                    variant: ExButtonVariant.secondary,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
                const SizedBox(width: ExSpace.s3),
                Expanded(
                  flex: 2,
                  child: ExButton(
                    label: 'Confirmar',
                    variant: ExButtonVariant.primary,
                    expand: true,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Builder(
      builder: (context) => Text(text, style: ExText.h3(context.ex.textPrimary)),
    );
  }
}

class _TagCreateCard extends StatelessWidget {
  const _TagCreateCard({
    required this.tag,
    required this.onChanged,
    required this.onRemove,
  });

  final VoiceTagToCreate tag;
  final ValueChanged<VoiceTagToCreate> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(tag.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tag.groupName.isNotEmpty ? tag.groupName : 'Grupo',
                    style: ExText.body(context.ex.textSecondary)
                        .copyWith(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                  tooltip: 'Não criar esta categoria',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tag.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final edited = await showDialog<VoiceTagToCreate>(
                  context: context,
                  builder: (ctx) => _TagEditDialog(initial: tag),
                );
                if (edited != null) onChanged(edited);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar nome e cor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagEditDialog extends StatefulWidget {
  const _TagEditDialog({required this.initial});

  final VoiceTagToCreate initial;

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _nameCtrl;
  late int _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _color = widget.initial.color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar categoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Nome da categoria'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kGroupTagPresetColors.map((c) {
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.black87, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              widget.initial.copyWith(name: name, color: _color),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ShoppingItemPreviewCard extends StatefulWidget {
  const _ShoppingItemPreviewCard({
    required this.dto,
    required this.onChanged,
    this.onRemove,
  });

  final ExtractedVoiceTaskDto dto;
  final ValueChanged<ExtractedVoiceTaskDto> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_ShoppingItemPreviewCard> createState() =>
      _ShoppingItemPreviewCardState();
}

class _ShoppingItemPreviewCardState extends State<_ShoppingItemPreviewCard> {
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.dto.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: TextField(
          controller: _titleCtrl,
          onChanged: (_) => widget.onChanged(
            widget.dto.copyWith(title: _titleCtrl.text.trim()),
          ),
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: 'Item',
            isDense: true,
            border: InputBorder.none,
          ),
        ),
        trailing: widget.onRemove != null
            ? IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onRemove,
                tooltip: 'Remover item',
              )
            : null,
      ),
    );
  }
}

class _TaskPreviewCard extends StatefulWidget {
  const _TaskPreviewCard({
    required this.dto,
    required this.groups,
    required this.tagsByGroupId,
    required this.onChanged,
    this.onRemove,
  });

  final ExtractedVoiceTaskDto dto;
  final List<GroupModel> groups;
  final Map<String, List<TagModel>> tagsByGroupId;
  final ValueChanged<ExtractedVoiceTaskDto> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_TaskPreviewCard> createState() => _TaskPreviewCardState();
}

class _TaskPreviewCardState extends State<_TaskPreviewCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _tagCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.dto.title);
    _descCtrl = TextEditingController(text: widget.dto.description);
    _tagCtrl = TextEditingController(text: widget.dto.tagName ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final tag = _tagCtrl.text.trim();
    widget.onChanged(
      widget.dto.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        tagName: tag.isEmpty ? null : tag,
        tagExplicit: tag.isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupLabel = widget.dto.groupName?.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (groupLabel != null && groupLabel.isNotEmpty)
                  Expanded(
                    child: Text(
                      groupLabel,
                      style: ExText.body(context.ex.textSecondary)
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onRemove,
                    tooltip: 'Remover tarefa',
                  ),
              ],
            ),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => _emit(),
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Título',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              onChanged: (_) => _emit(),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagCtrl,
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(
                labelText: 'Categoria / etiqueta',
                isDense: true,
                hintText: 'Opcional',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
