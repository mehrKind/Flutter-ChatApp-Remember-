import 'package:flutter/material.dart';
import 'package:remember/services/config.dart';
import 'package:remember/services/routes.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  final String name = "Ali Mehr"; // Replace with dynamic values if needed
  final String phoneNumber = "+98 9224850196";

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: getColorByName("mainBg"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image, name, phone
          DrawerHeader(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/drawer.jpg',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      Text(phoneNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          buildDrawerItem(Icons.person, "Profile", AppRoutes.profilePage, context),
          buildDrawerItem(Icons.group, "New Group", AppRoutes.newGroupPage, context),
          buildDrawerItem(Icons.call, "Calls", AppRoutes.callsPage, context),
          buildDrawerItem(Icons.settings, "Settings", AppRoutes.settingsPage, context),
          buildDrawerItem(Icons.bookmark, "Saved Messages", AppRoutes.savedPage, context),
          buildDrawerItem(Icons.contacts, "Contacts", AppRoutes.contactsPage, context),
          buildDrawerItem(Icons.help_outline, "Help", AppRoutes.helpPage, context),
          buildDrawerItem(Icons.code, "Developer", AppRoutes.developerPage, context),

        ],
      ),
    );
  }

  Widget buildDrawerItem(IconData icon, String title, String routeName, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          Navigator.pop(context); // Close the drawer
          Navigator.pushNamed(context, routeName); // Navigate to target page
        },
      ),
    );
  }
}
