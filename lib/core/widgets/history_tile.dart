import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/streak/models/daily_record.dart';
import '../../widgets/pressable_scale.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

/// Strava-style activity row for gym sessions.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.record, required this.onTap});

  final DailyRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final end = record.endTime ??
        (record.arrivalTime != null && record.duration != null
            ? record.arrivalTime!.add(record.duration!)
            : null);
    final photo = record.optionalPhotoPath;
    final hasPhoto = photo != null && File(photo).existsSync();
    final dateLabel = DateFormat('EEE, d MMM').format(record.calendarDate);
    final durationLabel = record.duration != null
        ? Dates.friendlyDuration(record.duration!)
        : '—';
    final status = record.isCompleted
        ? 'StryK ${record.streakAtPoint ?? ''}'.trim()
        : record.kind == DayKind.sundayProtected
            ? 'Protected'
            : record.kind == DayKind.streakSaved
                ? 'Saved'
                : record.kind == DayKind.missed
                    ? 'Missed'
                    : '—';

    return PressableScale(
      scale: 0.985,
      onPressed: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              if (hasPhoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(photo),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    record.isCompleted
                        ? Icons.fitness_center_rounded
                        : Icons.event_busy_rounded,
                    color: record.isCompleted
                        ? AppColors.amber
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.arrivalTime != null && end != null
                          ? Dates.timeRange(record.arrivalTime!, end)
                          : status,
                      style: AppTypography.body.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    durationLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.amber,
                      fontSize: 15,
                      fontVariations: const [FontVariation('wght', 700)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.toUpperCase(),
                    style: AppTypography.label.copyWith(fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
