import 'package:flutter/material.dart';
import '../managers/favourites_manager.dart';
import '../screens/pdf_viewer_page.dart';
import 'home_screen.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        backgroundColor: Colors.blueGrey[600],
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: FavoritesManager().favoritesNotifier,
        builder: (context, favorites, _) {
          return favorites.isEmpty
              ? Center(
            child: Text(
              'No favorites yet.',
              style: TextStyle(fontSize: 18.0, color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final book = favorites[index];
              return ListTile(
                leading: Icon(Icons.book, color: Colors.blueGrey[600]),
                title: Text(
                  book['title'] ?? 'Unknown Title',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          // Remove the book from favorites in Firestore
                          FavoritesManager().removeFavorite(book['title']!);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.blueGrey),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PDFViewerPage(pdfPath: book['pdfUrl']!),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
