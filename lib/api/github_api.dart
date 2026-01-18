import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class GitHubAPI {
  final String token;

  GitHubAPI({required this.token});

  // GraphQL query for contributions
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

  // Fetch contributions from GitHub
  Future<Map<String, dynamic>> fetchContributions(String username) async {
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

        // Check for GraphQL errors
        if (data['errors'] != null) {
          throw GitHubAPIException(
            'GraphQL Error: ${data['errors'][0]['message']}',
          );
        }

        // Check if user exists
        if (data['data']['user'] == null) {
          throw GitHubAPIException('User not found: $username');
        }

        return data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw GitHubAPIException(
          'Invalid GitHub token. Please check your Personal Access Token.',
        );
      } else if (response.statusCode == 403) {
        throw GitHubAPIException(
          'Rate limit exceeded. Please try again later.',
        );
      } else {
        throw GitHubAPIException('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is GitHubAPIException) {
        rethrow;
      }
      throw GitHubAPIException('Network error: ${e.toString()}');
    }
  }
}

class GitHubAPIException implements Exception {
  final String message;

  GitHubAPIException(this.message);

  @override
  String toString() => message;
}
