import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../main.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;

  const NewsCard({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: savedNewsIds,
      builder: (context, savedIds, child) {
        final isSaved = savedIds.contains(news.id);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(news.category)),

                    if (news.isImportant)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Important',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        final updatedList = List<String>.from(savedIds);

                        if (isSaved) {
                          updatedList.remove(news.id);
                        } else {
                          updatedList.add(news.id);
                        }

                        savedNewsIds.value = updatedList;
                        saveNewsIds(updatedList);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  news.date,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  news.summary,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailsScreen(
                            title: news.title,
                            category: news.category,
                            date: news.date,
                            summary: news.summary,
                            sourceUrl: news.sourceUrl,
                          ),
                        ),
                      );
                    },
                    child: const Text('Read More'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}