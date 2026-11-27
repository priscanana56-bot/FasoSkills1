import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';

/// Colours of the FasoSkills blue redesign, shared by the client and artisan spaces.
class Palette {
  Palette._();
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E3A8A);
  static const primarySoft = Color(0xFFEFF6FF);
  static const ink = Color(0xFF0F172A);
  static const text = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const background = Color(0xFFF8FAFC);
  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const star = Color(0xFFF59E0B);

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Maps the icon names stored on categories (Material names) to icons.
IconData categoryIcon(String? name) => switch (name) {
      'plumbing' => Icons.plumbing_rounded,
      'electrical_services' || 'bolt' => Icons.electrical_services_rounded,
      'carpenter' => Icons.carpenter_rounded,
      'foundation' => Icons.foundation_rounded,
      'format_paint' => Icons.format_paint_rounded,
      'ac_unit' => Icons.ac_unit_rounded,
      'lock' || 'lock_open' => Icons.lock_open_rounded,
      'build' => Icons.build_rounded,
      'construction' => Icons.construction_rounded,
      'cleaning_services' => Icons.cleaning_services_rounded,
      'solar_power' => Icons.solar_power_rounded,
      _ => Icons.handyman_rounded,
    };

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool verified;
  final String? imageUrl;
  final String? defaultAsset;

  const Avatar({
    super.key,
    required this.name,
    this.size = 48,
    this.verified = false,
    this.imageUrl,
    this.defaultAsset,
  });

  static const _gradients = [
    [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    [Color(0xFF0F766E), Color(0xFF14B8A6)],
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFFB45309), Color(0xFFF59E0B)],
    [Color(0xFFBE123C), Color(0xFFFB7185)],
    [Color(0xFF334155), Color(0xFF64748B)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[name.hashCode.abs() % _gradients.length];

    Widget imageContent;
    final url = imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        // Base64 data URL
        try {
          final comma = url.indexOf(',');
          final b64 = comma != -1 ? url.substring(comma + 1) : url;
          final bytes = base64Decode(b64);
          imageContent = Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _fallback(colors),
          );
        } catch (_) {
          imageContent = _fallback(colors);
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        imageContent = Image.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _fallback(colors),
        );
      } else if (url.startsWith('/')) {
        imageContent = Image.file(
          File(url),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _fallback(colors),
        );
      } else {
        imageContent = _fallback(colors);
      }
    } else if (defaultAsset != null && defaultAsset!.isNotEmpty) {
      imageContent = Image.asset(
        defaultAsset!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallback(colors),
      );
    } else {
      imageContent = _fallback(colors);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: size > 50 ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(child: imageContent),
          ),
          if (verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.verified_rounded,
                    color: Palette.primary, size: size * 0.32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(List<Color> colors) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(
        Fmt.initials(name),
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const Pill(
      {super.key,
      required this.label,
      required this.color,
      required this.background,
      this.icon});

  factory Pill.requestStatus(String status) {
    final (Color c, Color bg, IconData i) = switch (status) {
      'pending' => (
          Palette.warning,
          Palette.warningSoft,
          Icons.hourglass_top_rounded
        ),
      'accepted' || 'in_progress' => (
          Palette.primary,
          Palette.primarySoft,
          Icons.construction_rounded
        ),
      'completed' => (
          Palette.success,
          Palette.successSoft,
          Icons.check_circle_rounded
        ),
      _ => (Palette.muted, const Color(0xFFF1F5F9), Icons.block_rounded),
    };
    return Pill(
        label: Fmt.requestStatus(status), color: c, background: bg, icon: i);
  }

  factory Pill.quoteStatus(String status) {
    final (Color c, Color bg) = switch (status) {
      'accepted' => (Palette.success, Palette.successSoft),
      'rejected' => (Palette.muted, const Color(0xFFF1F5F9)),
      _ => (Palette.warning, Palette.warningSoft),
    };
    return Pill(label: Fmt.quoteStatus(status), color: c, background: bg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(20)),
      child: Text.rich(
        TextSpan(children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(icon, size: 13, color: color)),
            ),
          TextSpan(text: label),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AppCard(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16),
      this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
                letterSpacing: -0.3),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                foregroundColor: Palette.primary, padding: EdgeInsets.zero),
            child: Text(actionLabel!,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Palette.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: Palette.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: Palette.muted, height: 1.4)),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: Palette.primary),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Impossible de charger',
      message: message,
      actionLabel: 'Réessayer',
      onAction: onRetry,
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Palette.primary)));
}

/// Small red counter on top of an icon (unread messages, notifications).
class CountBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const CountBadge({super.key, required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: Palette.danger,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;

  const StarRating(
      {super.key, required this.rating, this.count, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: Palette.star),
        const SizedBox(width: 2),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'Nouveau',
          style: TextStyle(
              fontSize: size - 1,
              fontWeight: FontWeight.w800,
              color: Palette.ink),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 3),
          Text('($count)',
              style: TextStyle(fontSize: size - 2, color: Palette.muted)),
        ],
      ],
    );
  }
}

/// Standard page app bar (white, bold title, back button when possible).
PreferredSizeWidget pageAppBar(BuildContext context, String title,
    {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: false,
    title: Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: Palette.ink)),
    actions: actions,
  );
}

void showFeedback(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Palette.danger : Palette.ink,
      behavior: SnackBarBehavior.floating,
    ));
}
