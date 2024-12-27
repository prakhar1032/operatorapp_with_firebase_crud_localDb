import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:operatorapp/colors.dart';
import 'package:operatorapp/db_helper.dart';
import 'AddPlayerForm.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  String _searchQuery = ''; // Holds the search query

  @override
  void initState() {
    super.initState();
    _syncOfflineScores(); // Call it on screen load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'OPERATOR APP',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            width: MediaQuery.sizeOf(context).width * 0.3,
            height: 45,
            decoration: BoxDecoration(
                color: Color(0xff26278D),
                borderRadius: BorderRadius.circular(20)),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddPlayerForm()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                shape: StadiumBorder(),
                backgroundColor: Colors.transparent,
                disabledForegroundColor: Colors.transparent.withOpacity(0.38),
                disabledBackgroundColor: Colors.transparent.withOpacity(0.12),
                shadowColor: Colors.transparent,
                //make color or elevated button transparent
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search players...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Color(0xff26278D)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('players').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No players found.'));
                }

                // Filter players based on search query
                final players = snapshot.data!.docs.where((player) {
                  final playerName = player['name'].toLowerCase();
                  return playerName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final imageBase64 = player['image_base64'];
                    return Card(
                      elevation: 2,
                      color: AppColors.cardBaground,
                      child: ListTile(
                        leading: imageBase64 != null && imageBase64.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.memory(
                                  base64Decode(imageBase64),
                                  height: 50,
                                  width: 50,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  color: Colors.white,
                                  height: 50,
                                  width: 50,
                                  child: Icon(
                                    Icons.person,
                                  ),
                                ),
                              ),
                        title: Text(player['name'],
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w300),
                            'Age: ${player['age']}, Score: ${player['total_score']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddPlayerForm(playerId: player.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, player.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String playerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff26278D),
        title: const Text(
          'Delete Player',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this player?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              _deletePlayer(playerId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlayer(String playerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete player.')),
      );
    }
  }

  Future<void> _syncOfflineScores() async {
    final isOnline = await NetworkService.isOnline();

    // Show SnackBar for online or offline status
    if (isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are online. Syncing scores...')),
      );

      final unsyncedScores = await DatabaseHelper.instance.getUnsyncedScores();
      for (var score in unsyncedScores) {
        // Sync each score to Firebase
        await FirebaseFirestore.instance.collection('match_scores').add(score);
        // Update sync status in local DB
        await DatabaseHelper.instance.updateSyncStatus(score['id']);
      }

      // Show success message after syncing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores synced successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You are offline. Unable to sync scores.')),
      );
    }
  }
}

class NetworkService {
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
