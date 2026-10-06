import 'package:flutter/material.dart';
import '../../assets_paths.dart';
import '../../theme.dart';
import 'round_buttons.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String? iconAsset;
  const _NavItem(this.label, this.icon, this.iconAsset);
}

/// Barra de navegación inferior en forma de píldora con degradado
/// (Inicio, Teams, Buscar).
class HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomBar({super.key, this.currentIndex = 0, this.onTap});

  static const _items = [
    _NavItem('Inicio', Icons.home_rounded, AppAssets.iconNavInicio),
    _NavItem('Teams', Icons.groups_rounded, AppAssets.iconNavTeams),
    _NavItem('Buscar', Icons.search_rounded, AppAssets.iconNavBuscar),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        gradient: AppGradients.bottomBar,
        borderRadius: BorderRadius.circular(37),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < _items.length; i++)
            _BarItem(
              item: _items[i],
              selected: i == currentIndex,
              onTap: onTap == null ? null : () => onTap!(i),
            ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback? onTap;

  const _BarItem({required this.item, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: selected ? 0.35 : 0.15),
              ),
              child: Center(
                child: AssetOrIcon(
                  asset: item.iconAsset,
                  icon: item.icon,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
