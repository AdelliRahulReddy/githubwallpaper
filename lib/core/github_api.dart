import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'date_utils.dart';
import '../models/contribution_data.dart';

class GitHubAPI {
  final String token;

  GitHubAPI({required this.token});

  String _buildQuery(String username) {
    final from = AppDateUtils.getYearStart().toUtc().toIso8601String();
    final to = AppDateUtils.getYearEnd().toUtc().toIso8601String();

    return '''
    query {
      user(login: "$username") {
        contributionsCollection(from: "$from", to: "$to") {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                date
                contributionCount
                contributionLevel
              }
            }
          }
        }
      }
    }
    ''';
  }

  Future<CachedContributionData> fetchContributions(String username) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.githubApiUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'query': _buildQuery(username)}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['errors'] != null) {
          throw GitHubAPIException(
            'GraphQL Error: ${data['errors'][0]['message']}',
          );
        }

        if (data['data']['user'] == null) {
          throw GitHubAPIException('User not found: $username');
        }

        return _parseResponse(data, username);
      } else if (response.statusCode == 401) {
        throw GitHubAPIException('Invalid GitHub token');
      } else if (response.statusCode == 403) {
        throw GitHubAPIException('Rate limit exceeded');
      } else {
        throw GitHubAPIException('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is GitHubAPIException) rethrow;
      throw GitHubAPIException('Network error: ${e.toString()}');
    }
  }

  CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    final calendar =
        json['data']['user']['contributionsCollection']['contributionCalendar'];
    final weeksJson = calendar['weeks'] as List;

    // Flatten all days from all weeks
    final allDays = <ContributionDay>[];
    for (var week in weeksJson) {
      final daysJson = week['contributionDays'] as List;
      for (var day in daysJson) {
        allDays.add(ContributionDay(
          date: DateTime.parse(day['date']),
          contributionCount: day['contributionCount'] as int,
          contributionLevel: day['contributionLevel'] as String?,
        ));
      }
    }

    // Filter to current month
    final currentMonthDays = _filterToCurrentMonth(allDays);
    final stats = _calculateStats(currentMonthDays);

    // Build daily contributions map
    final dailyContributions = <int, int>{};
    for (var day in currentMonthDays) {
      dailyContributions[day.date.day] = day.contributionCount;
    }

    return CachedContributionData(
      username: username,
      totalContributions: stats['totalContributions']!,
      currentStreak: stats['currentStreak']!,
      longestStreak: stats['longestStreak']!,
      todayCommits: stats['todayCommits']!,
      days: currentMonthDays,
      dailyContributions: dailyContributions,
      lastUpdated: DateTime.now(),
    );
  }

  List<ContributionDay> _filterToCurrentMonth(List<ContributionDay> allDays) {
    return allDays
        .where((day) => AppDateUtils.isInCurrentMonth(day.date))
        .toList();
  }

  Map<String, int> _calculateStats(List<ContributionDay> days) {
    int totalContributions = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;
    int tempStreak = 0;

    // Sort days by date
    final sortedDays = List<ContributionDay>.from(days);
    sortedDays.sort((a, b) => a.date.compareTo(b.date));

    for (var day in sortedDays) {
      totalContributions += day.contributionCount;

      if (day.isToday()) {
        todayCommits = day.contributionCount;
      }

      if (day.contributionCount > 0) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    if (sortedDays.isNotEmpty &&
        sortedDays.last.isToday() &&
        sortedDays.last.contributionCount > 0) {
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

class GitHubAPIException implements Exception {
  final String message;
  GitHubAPIException(this.message);

  @override
  String toString() => message;
}
