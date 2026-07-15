import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.green.shade100,
                child: const Icon(
                  Icons.contact_phone,
                  size: 60,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                "Contact MediShare",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "We're here to help you.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 30),
                        //=================================
            // CONTACT INFORMATION
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
                      Icons.phone,
                      color: Colors.green,
                    ),
                    title: Text("Phone"),
                    subtitle: Text("+91 9876543210"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.email,
                      color: Colors.blue,
                    ),
                    title: Text("Email"),
                    subtitle: Text("support@medishare.com"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Colors.deepPurple,
                    ),
                    title: Text("Website"),
                    subtitle: Text("www.medishare.com"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                    title: Text("Address"),
                    subtitle: Text(
                      "Ahmedabad, Gujarat, India",
                    ),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: Colors.orange,
                    ),
                    title: Text("Office Hours"),
                    subtitle: Text(
                      "Mon - Sat : 9:00 AM - 6:00 PM",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            //=================================
            // SEND MESSAGE BUTTON
            //=================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.message),

                label: const Text(
                  "Send Message",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Message feature coming soon.",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            //=================================
            // BACK BUTTON
            //=================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),

                label: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 18,
                  ),
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