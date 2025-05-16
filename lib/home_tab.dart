import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DateTime? selectedDate; // holds the user-selected date filter
  String _searchQuery = ''; // holds search query string

  // Helper method to get the Firestore query based on date filter
  Query getNewsQuery() {
    Query query = FirebaseFirestore.instance.collection('news');
    if (selectedDate != null) {
      // Define the start and end of the day based on the selected date
      DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime endOfDay = startOfDay.add(Duration(hours: 23, minutes: 59, seconds: 59));
      query = query
          .where('publish_date', isGreaterThanOrEqualTo: startOfDay)
          .where('publish_date', isLessThanOrEqualTo: endOfDay);
    }
    return query;
  }

  // Show a dialog with a TextField to allow search input.
  Future<void> _showSearchDialog() async {
    String tempSearch = _searchQuery;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Search by Title"),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: "Enter search term"),
            onChanged: (value) {
              tempSearch = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear the search query
                setState(() {
                  _searchQuery = '';
                });
                Navigator.pop(context);
              },
              child: Text("Clear"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempSearch;
                });
                Navigator.pop(context);
              },
              child: Text("Search"),
            ),
          ],
        );
      },
    );
  }

  // Clear the date filter
  void _clearFilter() {
    setState(() {
      selectedDate = null;
    });
  }

  // Function to show the date picker for filtering
  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog, // Show search dialog when tapped.
          ),
          // Filter button: opens a DatePicker so the user can select a date to filter news
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _pickDate,
          ),
          // Optionally add a clear filter button if a date is already selected.
          if (selectedDate != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearFilter,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getNewsQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading news.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Get the list of documents from Firestore
          List<DocumentSnapshot> newsDocs = snapshot.data!.docs;

          // If a search query is provided, filter newsDocs on client-side based on the title.
          if (_searchQuery.isNotEmpty) {
            newsDocs = newsDocs.where((doc) {
              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();
              return title.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          if (newsDocs.isEmpty) {
            return Center(child: Text('No articles found.'));
          }

          return ListView.builder(
            itemCount: newsDocs.length,
            itemBuilder: (context, index) {
              // Get the document data as a map
              final newsData = newsDocs[index].data() as Map<String, dynamic>;

              // Process published_date: Handle both Firestore Timestamp and DateTime, if needed.
              DateTime? publishedDate;
              if (newsData['publish_date'] != null) {
                final pd = newsData['publish_date'];
                if (pd is Timestamp) {
                  publishedDate = pd.toDate();
                } else if (pd is DateTime) {
                  publishedDate = pd;
                }
              }

              return ListTile(
                leading: newsData['image'] != null
                    ? Image.network(
                  newsData['image'],
                  width: 100,
                  fit: BoxFit.cover,
                )
                    : null,
                title: Text(newsData['title'] ?? 'No Title'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (publishedDate != null)
                      Text(
                        'Published: ${DateFormat('yyyy-MM-dd').format(publishedDate)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    Text(
                      "Confidence rating: ${newsData['confidence'] != null ? (newsData['confidence'] as double).toStringAsFixed(2) : 'N/A'}",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to the detail screen with the news data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(newsData: newsData),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsData;

  const NewsDetailScreen({Key? key, required this.newsData}) : super(key: key);

  String getFormattedDate(dynamic publishedDateValue) {
    DateTime? date;
    if (publishedDateValue != null) {
      if (publishedDateValue is Timestamp) {
        date = publishedDateValue.toDate();
      } else if (publishedDateValue is DateTime) {
        date = publishedDateValue;
      }
    }
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : 'Unknown';
  }

  String getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return 'Invalid URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<String?> feedback = ValueNotifier(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(newsData['title'] ?? 'News Detail'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (newsData['image'] != null) ...[
                Image.network(newsData['image']),
                SizedBox(height: 10),
              ],
              Text(
                newsData['title'] ?? 'No Title',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (newsData['published_date'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Published: ${getFormattedDate(newsData['published_date'])}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              SizedBox(height: 12),
              Text(
                newsData['article'] ?? 'No article content available.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              if (newsData['source'] != null)
                GestureDetector(
                  onTap: () async {
                    final url = newsData['source'];
                    if (url != null && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not open the source link.")),
                      );
                    }
                  },
                  child: Text(
                    'Source: ${getDomain(newsData['source'])}',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              SizedBox(height: 10),
              if (newsData['confidence'] != null)
                Text(
                  'Confidence: ${(newsData['confidence'] as double).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14),
                ),
              if (newsData['tags'] != null && (newsData['tags'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 6.0,
                    children: List<Widget>.from(
                      (newsData['tags'] as List<dynamic>).map(
                            (tag) => Chip(label: Text(tag.toString())),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Divider(),
              ValueListenableBuilder<String?>(
                valueListenable: feedback,
                builder: (context, value, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          value == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: value == 'like' ? Colors.green : null,
                        ),
                        onPressed: () {
                          feedback.value = value == 'like' ? null : 'like';
                        },
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          value == 'dislike' ? Icons.thumb_down : Icons.thumb_down_outlined,
                          color: value == 'dislike' ? Colors.red : null,
                        ),
                        onPressed: () {
                          feedback.value = value == 'dislike' ? null : 'dislike';
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
