import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'date_utils.dart';
import '../models/contribution_data.dart';

class GitHubAPI {
  final String token;

  GitHubAPI({required this.token});

  String _buildQuery(String username) {
    final from = AppDateUtils.getYearStart();
    final to = AppDateUtils.getYearEnd();

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

    final allWeeks = weeksJson.map((week) {
      return Week(
        contributionDays: (week['contributionDays'] as List).map((day) {
          return ContributionDay(
            date: day['date'],
            contributionCount: day['contributionCount'],
            contributionLevel: day['contributionLevel'],
          );
        }).toList(),
      );
    }).toList();

    // Filter to current month
    final currentMonthWeeks = _filterToCurrentMonth(allWeeks);
    final stats = _calculateStats(currentMonthWeeks);

    return CachedContributionData(
      username: username,
      totalContributions: stats['totalContributions']!,
      weeks: currentMonthWeeks,
      currentStreak: stats['currentStreak']!,
      longestStreak: stats['longestStreak']!,
      todayCommits: stats['todayCommits']!,
      lastUpdated: DateTime.now(),
    );
  }

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

  Map<String, int> _calculateStats(List<Week> weeks) {
    int totalContributions = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;
    int tempStreak = 0;

    final allDays = <ContributionDay>[];
    for (var week in weeks) {
      allDays.addAll(week.contributionDays);
    }

    allDays.sort((a, b) => a.date.compareTo(b.date));

    for (var day in allDays) {
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

class GitHubAPIException implements Exception {
  final String message;
  GitHubAPIException(this.message);

  @override
  String toString() => message;
}
