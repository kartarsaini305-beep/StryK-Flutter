import 'package:flutter/material.dart';

import '../../features/gyms/models/gym.dart';
import '../theme/app_theme.dart';

class GymMarker extends StatelessWidget {
  const GymMarker({super.key, required this.gym, this.selected = false});

  final Gym gym;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: gym.name,
      selected: selected,
      child: Container(
        width: selected ? 16 : 12,
        height: selected ? 16 : 12,
        decoration: BoxDecoration(
          color: AppColors.amber,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 2),
        ),
      ),
    );
  }
}
