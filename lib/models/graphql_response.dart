class GitHubGraphQLResponse {
  final ContributionCalendar contributionCalendar;

  GitHubGraphQLResponse({required this.contributionCalendar});

  factory GitHubGraphQLResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data']['user']['contributionsCollection'];
    return GitHubGraphQLResponse(
      contributionCalendar: ContributionCalendar.fromJson(
        data['contributionCalendar'],
      ),
    );
  }
}

class ContributionCalendar {
  final int totalContributions;
  final List<CalendarWeek> weeks;

  ContributionCalendar({required this.totalContributions, required this.weeks});

  factory ContributionCalendar.fromJson(Map<String, dynamic> json) {
    return ContributionCalendar(
      totalContributions: json['totalContributions'] as int,
      weeks: (json['weeks'] as List)
          .map((week) => CalendarWeek.fromJson(week))
          .toList(),
    );
  }
}

class CalendarWeek {
  final List<CalendarDay> contributionDays;

  CalendarWeek({required this.contributionDays});

  factory CalendarWeek.fromJson(Map<String, dynamic> json) {
    return CalendarWeek(
      contributionDays: (json['contributionDays'] as List)
          .map((day) => CalendarDay.fromJson(day))
          .toList(),
    );
  }
}

class CalendarDay {
  final String date;
  final int contributionCount;
  final String contributionLevel;

  CalendarDay({
    required this.date,
    required this.contributionCount,
    required this.contributionLevel,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] as String,
      contributionCount: json['contributionCount'] as int,
      contributionLevel: json['contributionLevel'] as String,
    );
  }
}
