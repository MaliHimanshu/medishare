import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.privacy_tip,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                "Privacy Policy",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),
                        //=================================
            // INFORMATION WE COLLECT
            //=================================

            const Text(
              "1. Information We Collect",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "• Name\n"
              "• Email Address\n"
              "• Phone Number\n"
              "• Profile Information\n"
              "• Equipment Details\n"
              "• Location (Optional)",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // HOW WE USE YOUR INFORMATION
            //=================================

            const Text(
              "2. How We Use Your Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "• Manage your account\n"
              "• Process equipment donations\n"
              "• Process equipment requests\n"
              "• Improve user experience\n"
              "• Provide customer support\n"
              "• Send important notifications",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // DATA SECURITY
            //=================================

            const Text(
              "3. Data Security",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "We use industry-standard security measures to protect your personal information from unauthorized access, modification, disclosure, or destruction.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // THIRD-PARTY SERVICES
            //=================================

            const Text(
              "4. Third-Party Services",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "MediShare may use trusted third-party services for authentication, notifications, analytics, and maps. These services follow their own privacy policies.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // CONTACT
            //=================================

            const Text(
              "5. Contact Us",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [

                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text("Email"),
                      subtitle: Text("support@medishare.com"),
                    ),

                    Divider(),

                    ListTile(
                      leading: Icon(Icons.phone),
                      title: Text("Phone"),
                      subtitle: Text("+91 9876543210"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            //=================================
            // BACK BUTTON
            //=================================

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