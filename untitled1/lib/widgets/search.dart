import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart';

class DataSearch extends SearchDelegate<List<dynamic>> {
  final List<List<dynamic>> data;

  DataSearch(this.data);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, []);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = data.where((entry) {
      return entry.any((element) => element.toString().toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final productName = result[0];
        final expiryDate = result[1];
        final imageUrl = result[2];
        final daysRemaining = _calculateRemainingDays(expiryDate);
        final progressColor = _getProgressColor(daysRemaining);

        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Image.network(imageUrl, width: 100, height: 100),
            title: Text(productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('유통기한: $expiryDate'),
                LinearProgressIndicator(
                  value: _calculateProgress(daysRemaining),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  backgroundColor: Colors.grey[300],
                ),
                Text(daysRemaining < 0 ? '${daysRemaining.abs()}일 지났습니다' : '${daysRemaining.abs()}일 남음'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = data.where((entry) {
      return entry.any((element) => element.toString().toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        final productName = suggestion[0];
        final expiryDate = suggestion[1];
        final imageUrl = suggestion[2];
        final daysRemaining = _calculateRemainingDays(expiryDate);
        final progressColor = _getProgressColor(daysRemaining);

        return ListTile(
          leading: Image.network(imageUrl, width: 100, height: 100),
          title: Text(productName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('유통기한: $expiryDate'),
              LinearProgressIndicator(
                value: _calculateProgress(daysRemaining),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                backgroundColor: Colors.grey[300],
              ),
              Text(daysRemaining < 0 ? '${daysRemaining.abs()}일 지났습니다' : '${daysRemaining.abs()}일 남음'),
            ],
          ),
          onTap: () {
            query = productName;
            showResults(context);
          },
        );
      },
    );
  }

  int _calculateRemainingDays(String expiryDate) {
    try {
      DateTime endDate;
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 2) {
          final formattedExpiryDate =
              '${DateTime.now().year}/${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}';
          endDate = DateFormat('yyyy/MM/dd').parseStrict(formattedExpiryDate);
        } else if (parts.length == 3) {
          if (parts[0].length == 2) { // yy/MM/dd 형식일 경우
            endDate = DateFormat('yy/MM/dd').parseStrict(expiryDate);
          } else { // yyyy/MM/dd 형식일 경우
            endDate = DateFormat('yyyy/MM/dd').parseStrict(expiryDate);
          }
        } else {
          throw FormatException("Invalid date format");
        }
      } else {
        throw FormatException("Date does not contain expected delimiter");
      }

      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day);
      return endDate.difference(currentDate).inDays;
    } catch (e) {
      print('날짜 포맷 오류: $e');
      return 0;
    }
  }

  double _calculateProgress(int daysRemaining) {
    if (daysRemaining < 0) {
      return 1.0;
    }
    int maxDays = 365;
    return 1.0 - (daysRemaining / maxDays).clamp(0.0, 1.0);
  }

  Color _getProgressColor(int daysRemaining) {
    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining <= 14) {
      return Colors.redAccent[100]!;
    } else {
      double colorIntensity = math.max(0.0, 1.0 - daysRemaining / 30.0);
      return Color.lerp(Colors.green, Colors.red, colorIntensity)!;
    }
  }
}
