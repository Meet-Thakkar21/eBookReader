import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/userProfilePage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../components/book_cover.dart';
import '../components/recent_read_item.dart';
import '../components/search_delegate.dart';
import '../Services/auth_service.dart';
import '../managers/favourites_manager.dart';
import 'favorites_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? book1ImageUrl; // Variable to store the URL of book1 image
  String book1Title = "Loading..."; // Default title until data is fetched
  String book1Author = "Loading...";
  String book1Desc = "Loading...";
  String? book1PdfUrl;

  String book2Title = "Loading..."; // Default title until data is fetched
  String book2Author = "Loading...";
  String book2Desc = "Loading...";
  String? book2ImageUrl; // Variable to store the URL of book2 image
  String? book2PdfUrl;

  String book3Title = "Loading..."; // Default title until data is fetched
  String book3Author = "Loading...";
  String book3Desc = "Loading...";
  String? book3ImageUrl; // Variable to store the URL of book3 image
  String? book3PdfUrl; // Variable to store the URL of book1 PDF
  List<RecentReadItem> recentBooks = [];
  @override
  void initState() {
    super.initState();
    fetchBookAssets();
    FavoritesManager().loadFavorites();
  }

  // Method to fetch all book images and PDFs from Firebase Storage
  // Method to fetch all book images and PDFs from Firebase Storage
  Future<List<Map<String, dynamic>>> fetchBookAssets() async {
    try {
      List<Map<String, dynamic>> bookData = [];

      // Fetching book1 details
      DocumentSnapshot doc1 = await FirebaseFirestore.instance.collection('books').doc('book1').get();
      if (doc1.exists && doc1.data() != null) {
        Map<String, dynamic> book1Data = doc1.data() as Map<String, dynamic>;

        DocumentSnapshot authorDoc1 = await FirebaseFirestore.instance.collection('books').doc('book1').collection('Author').doc('author1').get();
        if (authorDoc1.exists && authorDoc1.data() != null) {
          book1Data['authorDetails'] = authorDoc1.data();
        }

        bookData.add(book1Data);
      }

      // Fetching book2 details
      DocumentSnapshot doc2 = await FirebaseFirestore.instance.collection('books').doc('book2').get();
      if (doc2.exists && doc2.data() != null) {
        Map<String, dynamic> book2Data = doc2.data() as Map<String, dynamic>;

        DocumentSnapshot authorDoc2 = await FirebaseFirestore.instance.collection('books').doc('book2').collection('Author').doc('author2').get();
        if (authorDoc2.exists && authorDoc2.data() != null) {
          book2Data['authorDetails'] = authorDoc2.data();
        }

        bookData.add(book2Data);
      }

      // Fetching book3 details
      DocumentSnapshot doc3 = await FirebaseFirestore.instance.collection('books').doc('book3').get();
      if (doc3.exists && doc3.data() != null) {
        Map<String, dynamic> book3Data = doc3.data() as Map<String, dynamic>;

        DocumentSnapshot authorDoc3 = await FirebaseFirestore.instance.collection('books').doc('book3').collection('Author').doc('author3').get();
        if (authorDoc3.exists && authorDoc3.data() != null) {
          book3Data['authorDetails'] = authorDoc3.data();
        }

        bookData.add(book3Data);
      }

      return bookData;
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  void logout(BuildContext context) async {
    final auth = AuthService();
    auth.signOut();

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.account_circle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserProfilePage(), // Navigate to UserProfilePage
              ),
            );
          },
        ),
        title: Text('eBookReader',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[600],
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: Icon(Icons.logout),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              if (recentBooks.isNotEmpty) {
                // Show search only when recentBooks has data
                showSearch(
                  context: context,
                  delegate: BookSearchDelegate(recentBooks),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No books available for search')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchBookAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No books found.'));
          }

          // Successfully fetched data
          List<Map<String, dynamic>> bookData = snapshot.data!;

          // Map book data to RecentReadItem widgets
          recentBooks = bookData.map((book) {
            var authorDetails = book['authorDetails'] ?? {}; // Handle null safely
            return RecentReadItem(
              title: book['title'] ?? 'Untitled',
              author: authorDetails['name'] ?? 'Unknown Author', // Check author safely
              description: book['description'] ?? 'No description available.',
              pdfUrl: book['pdfUrl'] ?? '',
              authorDescription: authorDetails['description'] ?? 'David Goggins is a famous book writer his best selling books is cant hurt me',
              authorImageUrl: authorDetails['imgUrl'] ?? 'assets/sub_assets/placeholder.jpg',
            );
          }).toList();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to eBookReader',
                      style: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.0),

                    // Book Covers Section
                    Text(
                      'Popular Books',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    SizedBox(height: 8.0),

                    // Display book covers
                    Container(
                      height: 200.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: bookData.length,
                        itemBuilder: (context, index) {
                          var book = bookData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0),
                            child: BookCover(
                              imagePath: book['imgUrl'] ??
                                  'assets/sub_assets/placeholder.jpg',
                              pdfUrl: book['pdfUrl'] ?? '',
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.0),

                    // Recent Reads Section
                    Text(
                      'Recent Reads',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    SizedBox(height: 8.0),

                    // Display book recent reads
                    Expanded(
                      child: ListView.builder(
                        itemCount: bookData.length,
                        itemBuilder: (context, index) {
                          var book = bookData[index];
                          var authorDetails = book['authorDetails'] ?? {};
                          // print("Book ${index + 1} author description: ${authorDetails['description']}");

                          return RecentReadItem(
                            title: book['title'] ?? 'Untitled',
                            author: book['author'] ?? 'Unknown Author',
                            description: book['description'] ??
                                'No description available.',
                            pdfUrl: book['pdfUrl'],
                            authorDescription: authorDetails['description'] ?? 'David Goggins is a former Navy SEAL, endurance athlete, and motivational speaker known for his incredible mental toughness and resilience. His bestselling memoir Cant Hurt Me chronicles his journey from hardship to becoming one of the worlds fittest men',
                            authorImageUrl: authorDetails['imgUrl'] ?? 'assets/sub_assets/placeholder.jpg',

                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: FavoritesManager().favoritesNotifier,
                    builder: (context, favorites, child) {
                      final isFavorite = favorites.contains(
                          'Book Title 1'); // Adjust the title or logic as needed
                      return FloatingActionButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoritesPage(),
                            ),
                          );
                        },
                        child: Icon(Icons.favorite),
                        backgroundColor: Colors.blueGrey[600],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
