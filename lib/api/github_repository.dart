import '../models/contribution_data.dart';
import '../models/graphql_response.dart';
import '../utils/date_utils.dart';
import 'github_api.dart';

class GitHubRepository {
  final GitHubAPI api;

  GitHubRepository({required this.api});

  // Fetch and process contribution data
  Future<CachedContributionData> getContributions(String username) async {
    // Fetch from API
    final jsonData = await api.fetchContributions(username);

    // Parse GraphQL response
    final response = GitHubGraphQLResponse.fromJson(jsonData);
    final calendar = response.contributionCalendar;

    // Convert to our model
    final weeks = calendar.weeks.map((week) {
      return Week(
        contributionDays: week.contributionDays.map((day) {
          return ContributionDay(
            date: day.date,
            contributionCount: day.contributionCount,
            contributionLevel: day.contributionLevel,
          );
        }).toList(),
      );
    }).toList();

    // Filter to current month only
    final currentMonthWeeks = _filterToCurrentMonth(weeks);

    // Calculate stats
    final stats = _calculateStats(currentMonthWeeks);

    return CachedContributionData(
      username: username,
      totalContributions: stats['totalContributions'] as int,
      weeks: currentMonthWeeks,
      currentStreak: stats['currentStreak'] as int,
      longestStreak: stats['longestStreak'] as int,
      todayCommits: stats['todayCommits'] as int,
      lastUpdated: DateTime.now(),
    );
  }

  // Filter weeks to only include current month days
  List<Week> _filterToCurrentMonth(List<Week> allWeeks) {
    return allWeeks
        .map((week) {
          final filteredDays = week.contributionDays
              .where((day) => AppDateUtils.isInCurrentMonth(day.date))
              .toList();

          return Week(contributionDays: filteredDays);
        })
        .where((week) => week.contributionDays.isNotEmpty)
        .toList();
  }

  // Calculate contribution stats
  Map<String, int> _calculateStats(List<Week> weeks) {
    int totalContributions = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;
    int tempStreak = 0;

    // Flatten all days
    final allDays = <ContributionDay>[];
    for (var week in weeks) {
      allDays.addAll(week.contributionDays);
    }

    // Sort by date
    allDays.sort((a, b) => a.date.compareTo(b.date));

    // Calculate totals and streaks
    for (var day in allDays) {
      totalContributions += day.contributionCount;

      // Check if today
      if (day.isToday()) {
        todayCommits = day.contributionCount;
      }

      // Calculate streaks
      if (day.contributionCount > 0) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // Current streak is the temp streak if it includes today
    if (allDays.isNotEmpty &&
        allDays.last.isToday() &&
        allDays.last.contributionCount > 0) {
      currentStreak = tempStreak;
    }

    return {
      'totalContributions': totalContributions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
    };
  }
}
