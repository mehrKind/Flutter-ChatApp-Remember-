import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/routes.dart';
import '../../services/storage_service.dart';

class Contact {
  final String name;
  final String? phone;
  final String? photoBase64; // Store photo as base64 string for caching

  Contact({required this.name, this.phone, this.photoBase64});

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'photoBase64': photoBase64,
    };
  }

  // Create from Map for deserialization
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'],
      phone: map['phone'],
      photoBase64: map['photoBase64'],
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPage();
}

class _ContactsPage extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _cachedContacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _showingCachedData = false;
  final String _contactsCacheKey = 'cached_contacts';

  @override
  void initState() {
    super.initState();
    _loadCachedContacts();
    _requestContactsPermission();
  }

  // Load cached contacts from shared preferences
  Future<void> _loadCachedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_contactsCacheKey);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        setState(() {
          _cachedContacts = decoded.map((e) => Contact.fromMap(e)).toList();
          _contacts = List.from(_cachedContacts);
          _showingCachedData = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading cached contacts: $e");
    }
  }

  // Save contacts to shared preferences
  Future<void> _saveContactsToCache(List<Contact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(contacts.map((e) => e.toMap()).toList());
      await prefs.setString(_contactsCacheKey, encoded);
    } catch (e) {
      debugPrint("Error saving contacts to cache: $e");
    }
  }

  Future<void> _requestContactsPermission() async {
    if (await FlutterContacts.requestPermission()) {
      _loadContacts();
    } else {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    try {
      final fetchedContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      // Convert to our Contact model
      final contacts = fetchedContacts.map((c) {
        return Contact(
          name: c.displayName,
          phone: c.phones.isNotEmpty ? c.phones.first.number : null,
          photoBase64: c.photo != null ? base64Encode(c.photo!) : null,
        );
      }).toList();

      // Save to cache
      await _saveContactsToCache(contacts);

      setState(() {
        _cachedContacts = contacts;
        _contacts = List.from(_cachedContacts);
        _isLoading = false;
        _showingCachedData = false;
      });
    } catch (e) {
      debugPrint("Error loading contacts: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshContacts() {
    setState(() {
      _isLoading = true;
    });
    _loadContacts();
  }

  void _showRefreshMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2F3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white),
                title: const Text('Refresh Contacts',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _refreshContacts();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Get avatar image provider from base64 string
  ImageProvider? _getAvatar(Contact contact) {
    if (contact.photoBase64 != null) {
      return MemoryImage(base64Decode(contact.photoBase64!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF121925),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 34),
            // Top Bar
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/images/icons/arrow-left.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_showingCachedData)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.cloud_done, color: Colors.grey, size: 18),
                  ),
                IconButton(
                  onPressed: () => _showRefreshMenu(context),
                  icon: const Icon(Icons.more_vert),
                  color: Colors.white,
                )
              ],
            ),
            const SizedBox(height: 34),
            // Search Box
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F3A),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: const Color(0xFF8B8B8B),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/icons/Search.png',
                    width: 20,
                    height: 20,
                    color: const Color(0xFF9099AE),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        hintText: 'Name, Phone Number',
                        hintStyle: TextStyle(color: Color(0xFF9099AE)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _contacts = List.from(_cachedContacts);
                          });
                        } else {
                          final filtered = _cachedContacts.where((c) =>
                          c.name.toLowerCase().contains(value.toLowerCase()) ||
                              (c.phone?.contains(value) ?? false)).toList();

                          setState(() {
                            _contacts = filtered;
                          });
                        }
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Handle mic icon tap
                    },
                    child: Image.asset(
                      'assets/images/icons/Voice.png',
                      width: 20,
                      height: 20,
                      color: const Color(0xFF9099AE),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _buildContactsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Clear all stored data (token, user ID, etc.)
            await StorageService.clearAll();

            // Navigate to sign up page and remove all previous routes
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signUpPage,
                  (route) => false, // This removes all previous routes
            );
          } catch (e) {
            // Handle any errors that might occur
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error during logout: ${e.toString()}')),
            );
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFCA9FFE), Color(0xFF8259FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/icons/user_add.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    } else {
      final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
      final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
      return '$first$last';
    }
  }

  Widget _buildContactsList() {
    if (_isLoading && _contacts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Contacts permission denied',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestContactsPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // In the ListView.builder's itemBuilder, wrap the contact item with GestureDetector
        ListView.builder(
          itemCount: _contacts.length,
          itemBuilder: (context, index) {
            final contact = _contacts[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.chatPage,
                  arguments: {
                    'contactName': contact.name,
                    'contactPhone': contact.phone ?? '',
                  },
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2F3A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF4A5568),
                      backgroundImage: _getAvatar(contact),
                      child: _getAvatar(contact) == null
                          ? Text(
                        _getInitials(contact.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (contact.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              contact.phone!,
                              style: const TextStyle(
                                color: Color(0xFF9099AE),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_isLoading && _showingCachedData)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Updating contacts...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}