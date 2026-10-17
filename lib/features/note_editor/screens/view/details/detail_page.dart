import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../home/core/providers.dart';
import '../../../../home/view/desktop/content_panel/core/navigator.dart';
import '../../../../../shared/app_scaffold.dart';

class NoteDetailsPage extends ConsumerWidget {
  const NoteDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(activeNoteProvider)!;

    return SelectionArea(
      child: AppScaffold.rightPanel(
        option: RightPanelPageOptions.noteDetails,
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSection(
              context,
              title: 'Primary Keys & Core Data',
              icon: Icons.vpn_key_outlined,
              children: [
                _MetadataItem(label: 'UUID', value: note.uuid),
                _MetadataItem(label: 'Title', value: note.title),
                _MetadataItem(label: 'Content Length', value: '${note.content.length} characters'),
                _MetadataItem(label: 'Content', value: note.content, isMultiline: true),
              ],
            ),
            _buildSection(
              context,
              title: 'UI & UX Features',
              icon: Icons.design_services_outlined,
              children: [
                _MetadataItem(label: 'Color (Hex)', value: '0x${note.color.toRadixString(16).toUpperCase()}'),
                _MetadataItem(label: 'Pinned At', value: note.pinnedAt?.toIso8601String() ?? 'null'),
                _MetadataItem(label: 'Archived At', value: note.archivedAt?.toIso8601String() ?? 'null'),
                _MetadataItem(label: 'Locked At', value: note.lockedAt?.toIso8601String() ?? 'null'),
                _MetadataItem(label: 'Tags', value: note.tags ?? 'null'),
                _MetadataItem(label: 'Reminder At', value: note.reminderAt?.toIso8601String() ?? 'null'),
              ],
            ),
            _buildSection(
              context,
              title: 'Attachments & Media',
              icon: Icons.attachment_outlined,
              children: [
                _MetadataItem(label: 'Local Path', value: note.localAttachmentPath ?? 'null', isMultiline: true),
                _MetadataItem(label: 'Cloud URL', value: note.cloudAttachmentUrl ?? 'null', isMultiline: true),
              ],
            ),
            _buildSection(
              context,
              title: 'Versioning & Schema',
              icon: Icons.schema_outlined, // If not available, use Icons.layers_outlined
              children: [
                _MetadataItem(label: 'Schema Version', value: note.schemaVersion.toString()),
                _MetadataItem(label: 'Content Version', value: note.contentVersion.toString()),
              ],
            ),
            _buildSection(
              context,
              title: 'Relational Data & Security',
              icon: Icons.security_outlined,
              children: [
                _MetadataItem(label: 'Folder ID', value: note.folderId ?? 'null (root)'),
                _MetadataItem(label: 'Owner UID', value: note.ownerUid ?? 'null'),
              ],
            ),
            _buildSection(
              context,
              title: 'Timestamps (LWW Engine)',
              icon: Icons.access_time,
              children: [
                _MetadataItem(label: 'Created At', value: note.createdAt.toIso8601String()),
                _MetadataItem(label: 'Updated At', value: note.updatedAt.toIso8601String()),
                _MetadataItem(label: 'Deleted At', value: note.deletedAt?.toIso8601String() ?? 'null'),
              ],
            ),
            _buildSection(
              context,
              title: 'Sync Engine',
              icon: Icons.sync,
              children: [
                _MetadataItem(label: 'Cloud Sync Status', value: note.cloudSyncStatus.toString()),
                _MetadataItem(label: 'Local Sync Status', value: note.localSyncStatus.toString()),
                _MetadataItem(label: 'Update Counter', value: note.updateCounter.toString()),
              ],
            ),
            _buildSection(
              context,
              title: 'Device & Platform Metadata',
              icon: Icons.devices_outlined,
              children: [
                _MetadataItem(label: 'Creation Platform', value: note.creationPlatform ?? 'null'),
                _MetadataItem(label: 'Creation Device', value: note.creationDevice ?? 'null'),
                _MetadataItem(label: 'Last Edited Platform', value: note.lastEditedPlatform ?? 'null'),
                _MetadataItem(label: 'Last Edited Device', value: note.lastEditedDevice ?? 'null'),
                _MetadataItem(label: 'Deleted Platform', value: note.deletedPlatform ?? 'null'),
                _MetadataItem(label: 'Deleted Device', value: note.deletedDevice ?? 'null'),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => children[index],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const _MetadataItem({required this.label, required this.value, this.isMultiline = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: isMultiline ? null : 2, // Allows UUIDs/Timestamps to wrap nicely on mobile
              overflow: isMultiline ? null : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}