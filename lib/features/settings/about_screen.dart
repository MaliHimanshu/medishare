import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("About MediShare"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.center,

          children: [

            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.blue,

              child: Icon(
                Icons.local_hospital,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "MediShare",

              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Smart Medical Equipment Sharing Platform",

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),
                        //=================================
            // APP INFORMATION
            //=================================

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: const Column(
                children: [

                  ListTile(
                    leading: Icon(
                      Icons.verified,
                      color: Colors.blue,
                    ),
                    title: Text("Version"),
                    subtitle: Text("1.0.0"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.code,
                      color: Colors.green,
                    ),
                    title: Text("Developer"),
                    subtitle: Text("MediShare Development Team"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.school,
                      color: Colors.orange,
                    ),
                    title: Text("Project"),
                    subtitle: Text(
                      "Smart Medical Equipment Network",
                    ),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.copyright,
                      color: Colors.red,
                    ),
                    title: Text("Copyright"),
                    subtitle: Text("© 2026 MediShare"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // FEATURES
            //=================================

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Key Features",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(15),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text("✅ Medical Equipment Sharing"),
                    SizedBox(height: 10),

                    Text("✅ Equipment Donation"),
                    SizedBox(height: 10),

                    Text("✅ Equipment Requests"),
                    SizedBox(height: 10),

                    Text("✅ Nearby Hospitals"),
                    SizedBox(height: 10),

                    Text("✅ AI Chatbot Assistance"),
                    SizedBox(height: 10),

                    Text("✅ User Profile Management"),
                    SizedBox(height: 10),

                    Text("✅ Notifications"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // ABOUT
            //=================================

            const Text(
              "MediShare is designed to help hospitals, NGOs, "
              "and individuals donate and request medical equipment "
              "efficiently. The goal is to reduce medical equipment "
              "wastage and make healthcare resources more accessible "
              "to everyone.",

              textAlign: TextAlign.justify,

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            //=================================
            // THANK YOU
            //=================================

            const Text(
              "❤️ Thank you for using MediShare ❤️",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),

                label: const Text(
                  "Back",
                  style: TextStyle(fontSize: 18),
                ),

                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}