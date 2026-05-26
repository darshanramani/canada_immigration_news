import 'package:cloud_firestore/cloud_firestore.dart';


class NewsModel {
  final String id;
  final String title;
  final String category;
  final String date;
  final String summary;
  final String sourceUrl;
  final bool isSaved;
  final bool isImportant;

  const NewsModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.summary,
    required this.sourceUrl,
    this.isSaved = false,
    this.isImportant = false,
  });

  factory NewsModel.fromMap(Map<String, dynamic> data) {
    String formattedDate = '';


    if (data['date'] is Timestamp) {
      final dateTime = (data['date'] as Timestamp).toDate();
      formattedDate = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else {
      formattedDate = data['date'] ?? '';
    }

    return NewsModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      date: formattedDate,
      summary: data['summary'] ?? '',
      sourceUrl: data['sourceUrl'] ?? '',
      isSaved: data['isSaved'] ?? false,
      isImportant: data['isImportant'] ?? false,
    );
  }
}