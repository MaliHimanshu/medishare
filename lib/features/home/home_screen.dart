import 'package:flutter/material.dart';

import '../equipment/equipment_list_screen.dart';
import '../equipment/add_equipment_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Map<String, dynamic>> dashboardItems = [
    {
      "title": "Medical Equipment",
      "icon": Icons.medical_services,
      "color": Colors.blue,
    },
    {
      "title": "Donate Equipment",
      "icon": Icons.volunteer_activism,
      "color": Colors.green,
    },
    {
      "title": "Request Equipment",
      "icon": Icons.assignment,
      "color": Colors.orange,
    },
    {
      "title": "Nearby Hospitals",
      "icon": Icons.local_hospital,
      "color": Colors.red,
    },
    {
      "title": "My Donations",
      "icon": Icons.favorite,
      "color": Colors.purple,
    },
    {
      "title": "My Requests",
      "icon": Icons.inventory,
      "color": Colors.teal,
    },
  ];

  void navigateToScreen(String title) {
    switch (title) {
      case "Medical Equipment":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EquipmentListScreen(),
          ),
        );
        break;

      case "Donate Equipment":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddEquipmentScreen(),
          ),
        );
        break;

      case "Request Equipment":
      case "Nearby Hospitals":
      case "My Donations":
      case "My Requests":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$title Coming Soon"),
          ),
        );
        break;
    }
  }

  void bottomNavigation(int index) {
    setState(() {
      currentIndex = index;
    });

    switch (index) {
      case 0:
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EquipmentListScreen(),
          ),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddEquipmentScreen(),
          ),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MediShare"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Notifications Coming Soon"),
                ),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "MediShare",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Settings Coming Soon"),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: GridView.builder(
          itemCount: dashboardItems.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = dashboardItems[index];

            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  navigateToScreen(item["title"]);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor:
                          (item["color"] as Color).withOpacity(0.15),
                      child: Icon(
                        item["icon"],
                        color: item["color"],
                        size: 35,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      item["title"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: bottomNavigation,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "Equipment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: "Donate",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}