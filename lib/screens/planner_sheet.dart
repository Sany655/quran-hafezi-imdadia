import 'package:flutter/material.dart';
import 'planner_screen.dart';

class PlannerSheet extends StatelessWidget {
  final Function(int pageNumber) onOpenPage;

  const PlannerSheet({
    super.key,
    required this.onOpenPage,
  });

  @override
  Widget build(BuildContext context) {
    return PlannerScreen(onOpenPage: onOpenPage);
  }
}
