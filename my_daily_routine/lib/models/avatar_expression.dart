/// Gameplay reaction derived from progress; never stored as appearance.
enum AvatarExpression {
  tired('Cansado', -1),
  bored('Aburrido', -0.45),
  neutral('Tranquilo', 0),
  happy('Alegre', 1);

  final String label;
  final double intensity;
  const AvatarExpression(this.label, this.intensity);

  static AvatarExpression fromProgress(
    double progress, {
    bool hasActiveStats = true,
  }) {
    if (!hasActiveStats || !progress.isFinite) return neutral;
    if (progress < 25) return tired;
    if (progress < 50) return bored;
    if (progress < 75) return neutral;
    return happy;
  }
}
