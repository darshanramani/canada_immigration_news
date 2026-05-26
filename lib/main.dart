import 'package:flutter/material.dart';
import 'data/dummy_news.dart';
import 'widgets/news_card.dart';
import 'models/news_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
final ValueNotifier<List<String>> savedNewsIds = ValueNotifier<List<String>>([]);

Stream<List<NewsModel>> streamNewsFromFirestore() {
  return FirebaseFirestore.instance
      .collection('news')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return NewsModel.fromMap(data);
    }).toList();
  });
}

Future<void> loadSavedNews() async {
  final prefs = await SharedPreferences.getInstance();
  final savedIds = prefs.getStringList('savedNewsIds') ?? [];
  savedNewsIds.value = savedIds;
}

Future<void> saveNewsIds(List<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('savedNewsIds', ids);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await loadSavedNews();

  runApp(const CanadaImmigrationApp());
}

class CanadaImmigrationApp extends StatelessWidget {
  const CanadaImmigrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canada Immigration Daily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    CategoriesScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = '';
  String selectedCategory = 'All';

  final List<String> homeCategories = const [
    'All',
    'General',
    'Study Permit',
    'Work Permit',
    'Express Entry',
    'PNP',
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: Text(
                'Canada Immigration Daily',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Updated 🇨🇦',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Daily Canada immigration news, explained in simple words.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search immigration updates...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: homeCategories.length,
                itemBuilder: (context, index) {
                  final category = homeCategories[index];
                  final isSelected = selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Colors.red,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            StreamBuilder<List<NewsModel>>(
              stream: streamNewsFromFirestore(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final allNews = snapshot.data ?? [];

                final filteredNews = allNews.where((news) {
                  final title = news.title.toLowerCase();
                  final category = news.category.toLowerCase();
                  final search = searchText.toLowerCase();

                  final matchesSearch =
                      title.contains(search) || category.contains(search);
                  final matchesCategory =
                      selectedCategory == 'All' ||
                          news.category == selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredNews.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('No immigration updates found.'),
                    ),
                  );
                }

                return Column(
                  children: filteredNews.map((news) {
                    return NewsCard(news: news);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NewsDetailsScreen extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final String summary;
  final String sourceUrl;

  const NewsDetailsScreen({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.summary,
    required this.sourceUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(category)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(date, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Text(summary, style: const TextStyle(fontSize: 18, height: 1.6)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final Uri url = Uri.parse(sourceUrl);

                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Official Source'),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<String> categories = const [
    'Study Permit',
    'Work Permit',
    'Express Entry',
    'Permanent Residence',
    'PNP',
    'Visitor Visa',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.flag_circle_outlined),
              title: Text(categories[index]),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryNewsScreen(
                      category: categories[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved News'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: savedNewsIds,
        builder: (context, savedIds, child) {
          return StreamBuilder<List<NewsModel>>(
            stream: streamNewsFromFirestore(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }

              final allNews = snapshot.data ?? [];

              final savedNews = allNews.where((news) {
                return savedIds.contains(news.id);
              }).toList();

              if (savedNews.isEmpty) {
                return const Center(
                  child: Text('No saved updates yet.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: savedNews.length,
                itemBuilder: (context, index) {
                  final news = savedNews[index];
                  return NewsCard(news: news);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About App'),
              subtitle: Text('Canada immigration updates explained simply.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber_outlined),
              title: Text('Disclaimer'),
              subtitle: Text(
                'This app is for information only and does not provide legal or immigration advice.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy Policy'),
              subtitle: Text('Privacy policy link will be added before Play Store release.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('Contact Support'),
              subtitle: Text('support@canadaimmigrationdaily.com'),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryNewsScreen extends StatelessWidget {
  final String category;

  const CategoryNewsScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        centerTitle: true,
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: streamNewsFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final allNews = snapshot.data ?? [];

          final categoryNews = allNews.where((news) {
            return news.category == category;
          }).toList();

          if (categoryNews.isEmpty) {
            return const Center(
              child: Text('No updates available in this category yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryNews.length,
            itemBuilder: (context, index) {
              final news = categoryNews[index];
              return NewsCard(news: news);
            },
          );
        },
      ),
    );
  }
}