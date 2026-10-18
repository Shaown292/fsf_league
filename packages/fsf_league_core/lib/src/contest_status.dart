enum ContestStatus {
  draft('DRAFT', 'Draft'),
  published('PUBLISHED', 'Published'),
  matchFinished('MATCH_FINISHED', 'Match finished'),
  scoring('SCORING', 'Scoring'),
  resultsPublished('RESULTS_PUBLISHED', 'Results published'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  const ContestStatus(this.code, this.label);
  final String code;
  final String label;

  static ContestStatus? tryParse(Object? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }

  // "Open" and "locked" are derived from times, so they are not stored.
  static const _transitions = <ContestStatus, Set<ContestStatus>>{
    draft: {published},
    published: {draft, matchFinished, cancelled},
    matchFinished: {scoring, cancelled},
    scoring: {resultsPublished, matchFinished},
    resultsPublished: {completed, scoring},
    completed: {},
    cancelled: {},
  };

  bool canMoveTo(ContestStatus next) => _transitions[this]!.contains(next);
}