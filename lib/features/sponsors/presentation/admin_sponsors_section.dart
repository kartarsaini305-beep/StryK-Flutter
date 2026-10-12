import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../features/share/models/monthly_result.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../models/sponsor.dart';
import '../services/sponsor_repository.dart';
import 'sponsor_logo.dart';

class AdminSponsorsSection extends StatefulWidget {
  const AdminSponsorsSection({super.key});

  @override
  State<AdminSponsorsSection> createState() => _AdminSponsorsSectionState();
}

class _AdminSponsorsSectionState extends State<AdminSponsorsSection> {
  final _repo = SponsorRepository();
  List<Sponsor> _sponsors = const [];
  var _loading = true;
  String? _error;
  SponsorPlacement _filter = SponsorPlacement.monthlyCard;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchAll();
      if (!mounted) return;
      setState(() {
        _sponsors = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load sponsors. $e';
      });
    }
  }

  Future<void> _openEditor([Sponsor? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _SponsorEditorSheet(
        existing: existing,
        repo: _repo,
        defaultPlacement: _filter,
      ),
    );
    if (saved == true) await _reload();
  }

  Future<void> _toggle(Sponsor s) async {
    try {
      await _repo.setActive(s.id, !s.active);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Could not update sponsor. $e',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }
  }

  Future<void> _delete(Sponsor s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove sponsor?', style: AppTypography.subheading),
        content: Text(
          'Remove ${s.name} from the monthly shareable card?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTypography.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.delete(s.id);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Could not remove sponsor. $e',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }
  }

  Future<void> _move(Sponsor s, {required bool earlier}) async {
    await _repo.moveSlot(s.id, earlier: earlier);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _sponsors.where((s) => s.placement == _filter).toList();
    final active = filtered.where((s) => s.active).toList();
    final inactive = filtered.where((s) => !s.active).toList();
    final fmt = DateFormat('MMM d');
    final previewSponsors = active
        .where((s) => s.isLiveAt(DateTime.now()))
        .take(5)
        .map(
          (s) => SponsorSnapshot(
            sponsorId: s.id,
            name: s.name,
            logoUrl: s.logoUrl,
            tagline: s.description,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SPONSORS',
                style: AppTypography.label.copyWith(color: AppColors.amber),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(
                Icons.add_rounded,
                color: AppColors.amber,
                size: 18,
              ),
              label: Text(
                'Add Sponsor',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.amber),
              ),
            ),
          ],
        ),
        Text(
          '3 separate pools: App · Daily card · Monthly card. Never mixed.',
          style: AppTypography.body.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final p in SponsorPlacement.values)
              ChoiceChip(
                label: Text(p.label),
                selected: _filter == p,
                selectedColor: AppColors.amber.withValues(alpha: 0.25),
                labelStyle: AppTypography.label.copyWith(
                  color: _filter == p ? AppColors.amber : AppColors.textSecondary,
                  fontSize: 11,
                ),
                onSelected: (_) => setState(() => _filter = p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _CardPreview(
          sponsors: previewSponsors,
          title: '${_filter.label.toUpperCase()} PREVIEW',
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
          )
        else if (_error != null)
          Column(
            children: [
              Text(_error!, style: AppTypography.body),
              const SizedBox(height: 8),
              StrykButton(
                label: 'Retry',
                variant: StrykButtonVariant.secondary,
                onPressed: _reload,
              ),
            ],
          )
        else ...[
          Text('ACTIVE', style: AppTypography.label),
          const SizedBox(height: 8),
          if (active.isEmpty)
            Text(
              'No active sponsors yet. Tap Add Sponsor.',
              style: AppTypography.body,
            )
          else
            for (final s in active)
              _SponsorRow(
                sponsor: s,
                dateLabel: _dates(s, fmt),
                onEdit: () => _openEditor(s),
                onToggle: () => _toggle(s),
                onDelete: () => _delete(s),
                onMoveUp: () => _move(s, earlier: true),
                onMoveDown: () => _move(s, earlier: false),
              ),
          const SizedBox(height: 16),
          Text('DRAFT / INACTIVE', style: AppTypography.label),
          const SizedBox(height: 8),
          if (inactive.isEmpty)
            Text('None.', style: AppTypography.body)
          else
            for (final s in inactive)
              _SponsorRow(
                sponsor: s,
                dateLabel: _dates(s, fmt),
                onEdit: () => _openEditor(s),
                onToggle: () => _toggle(s),
                onDelete: () => _delete(s),
                onMoveUp: () => _move(s, earlier: true),
                onMoveDown: () => _move(s, earlier: false),
              ),
        ],
      ],
    );
  }

  String _dates(Sponsor s, DateFormat fmt) {
    if (s.startAt == null && s.endAt == null) return 'Always';
    final a = s.startAt == null ? '—' : fmt.format(s.startAt!);
    final b = s.endAt == null ? '—' : fmt.format(s.endAt!);
    return '$a → $b';
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.sponsors, this.title = 'PREVIEW'});
  final List<SponsorSnapshot> sponsors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return StrykCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(color: AppColors.amber),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
              color: AppColors.charcoal.withValues(alpha: 0.7),
            ),
            child: Column(
              children: [
                Text(
                  sponsors.length <= 1 ? 'POWERED BY' : 'SPONSORS',
                  style: AppTypography.label.copyWith(
                    color: AppColors.amber,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                if (sponsors.isEmpty)
                  Text(
                    'No sponsors yet — add one above.',
                    style: AppTypography.body.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final s in sponsors)
                        SizedBox(
                          width: sponsors.length == 1 ? 140 : 72,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 28,
                                child: SponsorLogo(
                                  urlOrPath: s.logoUrl,
                                  fallbackIconSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.name,
                                style: AppTypography.label.copyWith(
                                  fontSize: 9,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorRow extends StatelessWidget {
  const _SponsorRow({
    required this.sponsor,
    required this.dateLabel,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final Sponsor sponsor;
  final String dateLabel;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StrykCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: ColoredBox(
                      color: AppColors.charcoal,
                      child: SponsorLogo(
                        urlOrPath: sponsor.logoUrl,
                        fit: BoxFit.cover,
                        fallbackIconSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sponsor.name,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  Text(
                    '${sponsor.placement.label} · ${sponsor.active ? 'Active' : 'Inactive'} · $dateLabel · P${sponsor.slot}',
                    style: AppTypography.label.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                TextButton(
                  onPressed: onMoveUp,
                  child: Text(
                    'Up',
                    style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: onMoveDown,
                  child: Text(
                    'Down',
                    style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text(
                    'Edit',
                    style: AppTypography.label.copyWith(color: AppColors.amber),
                  ),
                ),
                TextButton(
                  onPressed: onToggle,
                  child: Text(
                    sponsor.active ? 'Disable' : 'Enable',
                    style: AppTypography.label.copyWith(
                      color:
                          sponsor.active ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: Text(
                    'Remove',
                    style: AppTypography.label.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorEditorSheet extends StatefulWidget {
  const _SponsorEditorSheet({
    required this.repo,
    this.existing,
    this.defaultPlacement = SponsorPlacement.monthlyCard,
  });

  final SponsorRepository repo;
  final Sponsor? existing;
  final SponsorPlacement defaultPlacement;

  @override
  State<_SponsorEditorSheet> createState() => _SponsorEditorSheetState();
}

class _SponsorEditorSheetState extends State<_SponsorEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _campaign;
  late final TextEditingController _priority;
  late DateTime? _start;
  late DateTime? _end;
  late bool _active;
  late SponsorPlacement _placement;
  String? _logoUrl;
  File? _logoFile;
  var _saving = false;
  double _uploadProgress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _campaign = TextEditingController(text: e?.campaignName ?? '');
    _priority = TextEditingController(text: '${e?.slot ?? 1}');
    _start = e?.startAt;
    _end = e?.endAt;
    _active = e?.active ?? true;
    _placement = e?.placement ?? widget.defaultPlacement;
    _logoUrl = e?.logoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _campaign.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() => _logoFile = File(picked.path));
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? (_start ?? now) : (_end ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Sponsor name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _uploadProgress = 0;
    });
    try {
      final id = widget.existing?.id ?? '';
      var draft = Sponsor(
        id: id,
        name: name,
        logoUrl: _logoUrl ?? '',
        tier: 'Partner',
        active: _active,
        slot: int.tryParse(_priority.text.trim()) ?? 1,
        placement: _placement,
        description: _description.text.trim(),
        campaignName: _campaign.text.trim(),
        startAt: _start,
        endAt: _end,
      );
      draft = await widget.repo.upsert(draft);
      if (_logoFile != null) {
        final url = await widget.repo.uploadLogo(
          sponsorId: draft.id,
          file: _logoFile!,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        draft = draft.copyWith(logoUrl: url);
        await widget.repo.upsert(draft);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Sponsor could not be saved. $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final fmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.charcoalDeep,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null ? 'Add Sponsor' : 'Edit Sponsor',
              style: AppTypography.heading.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickLogo,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoFile != null
                      ? Image.file(_logoFile!, fit: BoxFit.cover)
                      : (_logoUrl != null && _logoUrl!.isNotEmpty)
                          ? SponsorLogo(
                              urlOrPath: _logoUrl!,
                              fit: BoxFit.cover,
                              fallbackIconSize: 28,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.upload_rounded,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload logo',
                                  style: AppTypography.label
                                      .copyWith(fontSize: 9),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            if (_saving && _logoFile != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _uploadProgress.clamp(0.05, 1),
                color: AppColors.amber,
                backgroundColor: AppColors.charcoal,
              ),
            ],
            const SizedBox(height: 16),
            Text('Placement', style: AppTypography.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<SponsorPlacement>(
              initialValue: _placement,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.charcoal,
              ),
              items: [
                for (final p in SponsorPlacement.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _placement = v);
                    },
            ),
            const SizedBox(height: 10),
            StrykTextField(controller: _name, label: 'Sponsor name'),
            const SizedBox(height: 10),
            StrykTextField(controller: _description, label: 'Description'),
            const SizedBox(height: 10),
            StrykTextField(controller: _campaign, label: 'Campaign name'),
            const SizedBox(height: 10),
            StrykTextField(
              controller: _priority,
              label: 'Priority / order (1 = first)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _pickDate(start: true),
                    child: Text(
                      _start == null ? 'Start date' : fmt.format(_start!),
                      style: AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _pickDate(start: false),
                    child: Text(
                      _end == null ? 'End date' : fmt.format(_end!),
                      style: AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Active / publish to card', style: AppTypography.bodyMedium),
              value: _active,
              activeTrackColor: AppColors.amber,
              onChanged: _saving ? null : (v) => setState(() => _active = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: AppTypography.body.copyWith(color: AppColors.error),
                ),
              ),
            StrykButton(
              label: _saving ? 'Saving…' : 'Save / Publish Sponsor',
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
