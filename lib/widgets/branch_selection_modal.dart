import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';
import '../data/models/models.dart';

class BranchSelectionModal extends StatefulWidget {
  final List<Cabang> branches;
  final Cabang? selectedBranch;
  final bool canDismiss;
  final String title;
  final String subtitle;

  const BranchSelectionModal({
    super.key,
    required this.branches,
    this.selectedBranch,
    this.canDismiss = false,
    this.title = 'Pilih Cabang',
    this.subtitle = 'Pilih cabang untuk sesi POS',
  });

  /// Show modal and return selected branch
  static Future<Cabang?> show(
    BuildContext context, {
    required List<Cabang> branches,
    Cabang? selectedBranch,
    bool canDismiss = false,
    String title = 'Pilih Cabang',
    String subtitle = 'Pilih cabang untuk sesi POS',
  }) {
    return showModalBottomSheet<Cabang>(
      context: context,
      isDismissible: canDismiss,
      enableDrag: canDismiss,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BranchSelectionModal(
        branches: branches,
        selectedBranch: selectedBranch,
        canDismiss: canDismiss,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<BranchSelectionModal> createState() => _BranchSelectionModalState();
}

class _BranchSelectionModalState extends State<BranchSelectionModal> {
  Cabang? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedBranch;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Branch list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.branches.length,
              itemBuilder: (context, index) {
                final branch = widget.branches[index];
                final isSelected = _selected?.id == branch.id;

                return ListTile(
                  onTap: () {
                    setState(() {
                      _selected = branch;
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.textLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.store,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    branch.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: branch.address != null && branch.address!.isNotEmpty
                      ? Text(
                          branch.address!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: isSelected
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selected != null
                    ? () {
                        Navigator.of(context).pop(_selected);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Konfirmasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
