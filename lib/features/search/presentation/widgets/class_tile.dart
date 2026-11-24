import 'package:flutter/material.dart';

import '../../../../core/widgets/info_tag.dart';
import '../../domain/class_result.dart';

class ClassTile extends StatelessWidget {
  const ClassTile(this.c, {super.key});

  final ClassResult c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(c.title, style: theme.textTheme.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${c.placeName}${c.address != null ? ' · ${c.address}' : ''}'),
          if (c.scheduleNote != null && c.scheduleNote!.isNotEmpty)
            Text(c.scheduleNote!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              InfoTag(c.activity),
              InfoTag(levelLabels[c.level] ?? c.level),
              InfoTag(formatLabels[c.format] ?? c.format),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(c.distanceLabel, style: theme.textTheme.labelLarge),
          if (c.pricePln != null)
            Text('${c.pricePln} zł', style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
    );
  }
}
