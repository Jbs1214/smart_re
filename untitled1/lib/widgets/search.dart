import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/widgets/progress_bar.dart';


String _calculateExpiryPeriod(String expiryDate) {
  final dateFormat = DateFormat('yyyy.MM.dd');
  DateTime endDate;
  try {
    endDate = dateFormat.parse(expiryDate);
  } on FormatException {
    return '(yyyy.MM.dd) 형태로 입력해주세요.';
  }

  final now = DateTime.now();
  final remainingDays = endDate.difference(now).inDays;

  if (remainingDays < 0) {
    return '유통기한이 지났습니다.(${-remainingDays}일 지남)';
  } else if (remainingDays == 0) {
    return 'D-Day';
  } else {
    return 'D-${-remainingDays}일';
  }
}


class DataSearch extends SearchDelegate<String> {
  final List<List<dynamic>> allData;

  DataSearch(this.allData);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, "");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<List<dynamic>> results = allData
        .where((list) => list.isNotEmpty && list.length > 1)
        .where((item) => item[0].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {

        final item = results[index];
        final String foodName = item[0];
        final String expiryDate = item[1];
        final String remainingDays = _calculateExpiryPeriod(expiryDate);

        return Column(
          children: <Widget>[
            ListTile(
              title: Text(foodName,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ExpiryProgressBar(expiryDate: expiryDate),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '$remainingDays',
                style: TextStyle(
                    color: Color(0x9B050505),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<List<dynamic>> suggestions = query.isEmpty
        ? []
        : allData
        .where((list) => list.isNotEmpty)
        .where((item) => item[0].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index][0]),
          // 다른 필드가 있다면 여기에 추가
        );
      },
    );
  }
}
