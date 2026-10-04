import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/streak/models/daily_record.dart';
import '../../widgets/pressable_scale.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.record, required this.onTap});

  final DailyRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (record.kind) {
      DayKind.completed => AppColors.amber,
      DayKind.sundayProtected || DayKind.streakSaved => AppColors.protected,
      DayKind.missed => AppColors.textMuted,
      DayKind.none => AppColors.textMuted,
    };
    final title = switch (record.kind) {
      DayKind.completed => 'STRYK ${record.streakAtPoint ?? ''}',
      DayKind.sundayProtected => 'Sunday Safe',
      DayKind.streakSaved => 'Streak Saved',
      DayKind.missed => 'Missed',
      DayKind.none => 'No activity',
    };
    final end = record.endTime ??
        (record.arrivalTime != null && record.duration != null
            ? record.arrivalTime!.add(record.duration!)
            : null);
    final photo = record.optionalPhotoPath;
    final hasPhoto = photo != null && File(photo).existsSync();

    return PressableScale(
      onPressed: onTap,
      child: Semantics(
        button: true,
        label: '$title, ${Dates.short.format(record.calendarDate)}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photo),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(Icons.local_fire_department, color: accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.subheading.copyWith(color: accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.gymName ??
                            (record.kind == DayKind.completed
                                ? 'Gym'
                                : record.kind == DayKind.sundayProtected
                                    ? 'Rest day protected'
                                    : record.kind == DayKind.streakSaved
                                        ? 'One banked save used'
                                        : 'No gym visit'),
                        style: AppTypography.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (record.arrivalTime != null && end != null)
                        Text(
                          Dates.timeRange(record.arrivalTime!, end),
                          style: AppTypography.label,
                        ),
                      if (record.duration != null)
                        Text(
                          Dates.friendlyDuration(record.duration!),
                          style: AppTypography.label.copyWith(color: accent),
                        ),
                    ],
                  ),
                ),
                Text(
                  Dates.upperDay(record.calendarDate),
                  style: AppTypography.label.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
