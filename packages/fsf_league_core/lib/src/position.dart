enum Position {
  gk('GK'),
  def('DEF'),
  mid('MID'),
  fwd('FWD');

  const Position(this.code);
  final String code;

  static Position? tryParse(Object? code) {
    for (final p in values) {
      if (p.code == code) return p;
    }
    return null;
  }
}