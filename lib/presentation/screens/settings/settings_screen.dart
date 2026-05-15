import 'package:budget_app/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/category.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Appearance ──────────────────────────────────────
          _SectionHeader(label: AppStrings.settingsAppearance),
          _SettingsCard(
            children: [
              _ThemeTile(current: themeMode),
            ],
          ),
          const Gap(20),

          // ── Categories ──────────────────────────────────────
          _SectionHeader(label: AppStrings.settingsCategories),
          _CategorySection(),
          const Gap(20),

          // ── Data ────────────────────────────────────────────
          _SectionHeader(label: AppStrings.settingsData),
          _SettingsCard(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep_outlined,
                      color: AppColors.expense, size: 20),
                ),
                title: const Text(
                  AppStrings.settingsClearData,
                  style: TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle:
                    const Text('Tar bort alla transaktioner och budgetar'),
                onTap: () => _confirmClearData(context, ref),
              ),
            ],
          ),
          const Gap(20),

          // ── About ────────────────────────────────────────────
          _SectionHeader(label: AppStrings.settingsAbout),
          _SettingsCard(
            children: [
              _VersionTile(),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.currency_exchange,
                      color: AppColors.primary, size: 20),
                ),
                title: const Text(AppStrings.settingsCurrency,
                    style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  AppStrings.settingsCurrencyValue,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Clear all data ────────────────────────────────────────────

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.settingsClearData),
        content: const Text(AppStrings.settingsClearDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.buttonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(transactionNotifierProvider.notifier).clearAll();
      await ref.read(budgetNotifierProvider.notifier).clearAll();

      // Re-seed default categories so the app is still usable
      await ref.read(transactionRepositoryProvider).seedDefaultCategories();
      ref.invalidate(categoryNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.snackDataCleared),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile({required this.current});

  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  current == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : current == ThemeMode.light
                          ? Icons.light_mode_outlined
                          : Icons.brightness_auto_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const Gap(12),
              Text(
                AppStrings.settingsDarkMode,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const Gap(12),
          // Segmented button for System / Light / Dark
          Row(
            children: [
              _ThemeOption(
                label: 'System',
                icon: Icons.brightness_auto_outlined,
                selected: current == ThemeMode.system,
                onTap: () => ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
              const Gap(8),
              _ThemeOption(
                label: 'Ljust',
                icon: Icons.light_mode_outlined,
                selected: current == ThemeMode.light,
                onTap: () => ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              const Gap(8),
              _ThemeOption(
                label: 'Mörkt',
                icon: Icons.dark_mode_outlined,
                selected: current == ThemeMode.dark,
                onTap: () => ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.13)
                : theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withOpacity(0.45),
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryNotifierProvider);
    final expenses = categories.where((c) => c.isExpense).toList();
    final income = categories.where((c) => !c.isExpense).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryGroup(
          title: AppStrings.transactionExpense,
          categories: expenses,
          ref: ref,
        ),
        const Gap(12),
        _CategoryGroup(
          title: AppStrings.transactionIncome,
          categories: income,
          ref: ref,
        ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.title,
    required this.categories,
    required this.ref,
  });

  final String title;
  final List<Category> categories;
  final WidgetRef ref;

  // Default category IDs (seeded in Category.defaults) — cannot be deleted
  static final _defaultIds = Category.defaults.map((c) => c.id).toSet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ),
        _SettingsCard(
          children: [
            for (int i = 0; i < categories.length; i++) ...[
              _buildCategoryTile(context, categories[i]),
              if (i < categories.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    final isDefault = _defaultIds.contains(category.id);

    if (isDefault) {
      // Default categories: shown but cannot be deleted
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, color: category.color, size: 18),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.lock_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
      );
    }

    // Custom categories: swipe to delete
    return Slidable(
      key: ValueKey(category.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _deleteCategory(context, category),
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 20),
                Gap(2),
                Text('Ta bort',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, color: category.color, size: 18),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ta bort kategori?'),
        content: Text(
            '"${category.name}" tas bort. Transaktioner med denna kategori påverkas inte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.buttonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERSION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _VersionTile extends StatefulWidget {
  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String _version = '—';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted)
        setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
      ),
      title: const Text(AppStrings.settingsVersion,
          style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(
        _version,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED LAYOUT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}
