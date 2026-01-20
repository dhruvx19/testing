import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:flutter/material.dart';

class FileOptionsBottomSheet extends StatelessWidget {
  final HealthFile file;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const FileOptionsBottomSheet({
    super.key,
    required this.file,
    this.onOpen,
    this.onShare,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.open_in_new,
              color: Color(0xFF2B7FFF),
            ),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(context);
              onOpen?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Color(0xFF2B7FFF)),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              onShare?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Color(0xFF2B7FFF)),
            title: const Text('Download'),
            onTap: () {
              Navigator.pop(context);
              onDownload?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }
}

