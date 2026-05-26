import '../models/news_model.dart';

final List<NewsModel> dummyNews = [

  const NewsModel(
    id: '1',
    title: 'Canada announces new immigration update',
    category: 'General',
    date: 'May 20, 2026',
    summary:
    'This is a simple AI-generated summary of the latest Canada immigration update.',
    sourceUrl: 'https://www.canada.ca',
  ),

  const NewsModel(
    id: '2',
    title: 'Express Entry draw update released',
    category: 'Express Entry',
    date: 'May 20, 2026',
    summary:
    'Important points about the latest Express Entry update will appear here.',
    sourceUrl: 'https://www.canada.ca',
  ),

  const NewsModel(
    id: '3',
    title: 'Study permit rule changes explained',
    category: 'Study Permit',
    date: 'May 20, 2026',
    summary:
    'Students can read a short and easy explanation of the latest rule changes.',
    sourceUrl: 'https://www.canada.ca',
  ),

];