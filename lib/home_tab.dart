import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('news').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading news.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final newsDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: newsDocs.length,
            itemBuilder: (context, index) {
              // Get the document data as a map
              final newsData = newsDocs[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: newsData['image'] != null
                    ? Image.network(
                  newsData['image'],
                  width: 100,
                  fit: BoxFit.cover,
                )
                    : null,
                title: Text(newsData['title'] ?? 'No Title'),
                subtitle: Text(
                  "Confidence rating: ${newsData['confidence'] != null ? (newsData['confidence'] as double).toStringAsFixed(2) : 'N/A'}",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(newsData['Title'] ?? 'News Detail'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (newsData['image'] != null)
                Image.network(newsData['image']),
              SizedBox(height: 10),
              Text(
                newsData['title'] ?? 'No Title',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                newsData['article'] ?? 'No article content available.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
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
                  'Source: ${newsData['source'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,  // Make it look like a link
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: 10),
              // Optionally display other fields such as confidence or tags
              if (newsData['confidence'] != null)
                Text(
                  'Confidence: ${(newsData['confidence'] as double).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14),
                ),
              if (newsData['tags'] != null)
                Wrap(
                  spacing: 6.0,
                  children: List<Widget>.from(
                    (newsData['tags'] as List<dynamic>).map(
                          (tag) => Chip(label: Text(tag.toString())),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
