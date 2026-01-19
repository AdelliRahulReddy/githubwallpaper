import '../core/date_utils.dart';

class ContributionDay {
  final String date;
  final int contributionCount;
  final String contributionLevel;

  ContributionDay({
    required this.date,
    required this.contributionCount,
    required this.contributionLevel,
  });

  bool isToday() => AppDateUtils.isToday(date);

  int getLevelInt() {
    switch (contributionLevel) {
      case 'NONE':
        return 0;
      case 'FIRST_QUARTILE':
        return 1;
      case 'SECOND_QUARTILE':
        return 2;
      case 'THIRD_QUARTILE':
        return 3;
      case 'FOURTH_QUARTILE':
        return 4;
      default:
        return 0;
    }
  }

  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    return ContributionDay(
      date: json['date'] as String,
      contributionCount: json['contributionCount'] as int,
      contributionLevel: json['contributionLevel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'contributionCount': contributionCount,
      'contributionLevel': contributionLevel,
    };
  }
}

class Week {
  final List<ContributionDay> contributionDays;

  Week({required this.contributionDays});

  factory Week.fromJson(Map<String, dynamic> json) {
    return Week(
      contributionDays: (json['contributionDays'] as List)
          .map((day) => ContributionDay.fromJson(day))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contributionDays': contributionDays.map((day) => day.toJson()).toList(),
    };
  }
}

class CachedContributionData {
  final String username;
  final int totalContributions;
  final List<Week> weeks;
  final int currentStreak;
  final int longestStreak;
  final int todayCommits;
  final DateTime lastUpdated;

  CachedContributionData({
    required this.username,
    required this.totalContributions,
    required this.weeks,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayCommits,
    required this.lastUpdated,
  });

  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    return CachedContributionData(
      username: json['username'] as String,
      totalContributions: json['totalContributions'] as int,
      weeks: (json['weeks'] as List)
          .map((week) => Week.fromJson(week))
          .toList(),
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      todayCommits: json['todayCommits'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'totalContributions': totalContributions,
      'weeks': weeks.map((week) => week.toJson()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
