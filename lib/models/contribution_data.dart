import '../core/date_utils.dart';

class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String? contributionLevel; // Optional: NONE, FIRST_QUARTILE, SECOND_QUARTILE, THIRD_QUARTILE, FOURTH_QUARTILE

  ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    return ContributionDay(
      date: DateTime.parse(json['date']),
      contributionCount: json['contributionCount'] as int,
      contributionLevel: json['contributionLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'contributionCount': contributionCount,
      if (contributionLevel != null) 'contributionLevel': contributionLevel,
    };
  }

  bool isToday() => AppDateUtils.isToday(date);
}

class CachedContributionData {
  final String username;
  final int totalContributions;
  final int currentStreak;
  final int longestStreak;
  final int todayCommits;
  final List<ContributionDay> days;
  final Map<int, int> dailyContributions;
  final DateTime? lastUpdated;

  CachedContributionData({
    required this.username,
    required this.totalContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayCommits,
    required this.days,
    required this.dailyContributions,
    this.lastUpdated,
  });

  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    final daysList = (json['days'] as List)
        .map((day) => ContributionDay.fromJson(day))
        .toList();

    // Convert string keys back to int keys
    final dailyContribsJson = json['dailyContributions'] as Map<String, dynamic>? ?? {};
    final dailyMap = <int, int>{};
    dailyContribsJson.forEach((key, value) {
      dailyMap[int.parse(key)] = value as int;
    });

    return CachedContributionData(
      username: json['username'],
      totalContributions: json['totalContributions'],
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      todayCommits: json['todayCommits'],
      days: daysList,
      dailyContributions: dailyMap,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert int keys to string keys for JSON compatibility
    final dailyContributionsJson = dailyContributions.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return {
      'username': username,
      'totalContributions': totalContributions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
      'days': days.map((day) => day.toJson()).toList(),
      'dailyContributions': dailyContributionsJson,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }
}
