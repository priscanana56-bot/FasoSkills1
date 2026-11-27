import 'package:flutter/material.dart';
import 'ui_kit.dart';

class DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;

  const DockItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      this.badge = 0});
}

/// Floating bottom bar used by both spaces. Items are given by the shell; an
/// optional raised centre button (client "new request") sits in the middle.
class FloatingDockNavBar extends StatelessWidget {
  final List<DockItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onCenterFabTap;

  const FloatingDockNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.onCenterFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (var i = 0; i < items.length; i++)
        Expanded(
            child: _NavItem(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onItemSelected(i))),
    ];
    if (onCenterFabTap != null) {
      children.insert(
          children.length ~/ 2, _CenterButton(onTap: onCenterFabTap!));
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
                color: Palette.ink.withValues(alpha: 0.12),
                blurRadius: 26,
                offset: const Offset(0, 10)),
            BoxShadow(
                color: Palette.primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Palette.border),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, children: children),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DockItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Palette.primary : Palette.faint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? Palette.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CountBadge(
                count: item.badge,
                child: Icon(selected ? item.activeIcon : item.icon,
                    size: 23, color: color),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Palette.primary.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6)),
            ],
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
