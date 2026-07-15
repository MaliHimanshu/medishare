import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
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
                backgroundColor: Colors.orange.shade100,
                child: const Icon(
                  Icons.description,
                  color: Colors.orange,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                "Terms & Conditions",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),
                        //=================================
            // USER RESPONSIBILITIES
            //=================================

            const Text(
              "1. User Responsibilities",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "• Provide accurate information.\n"
              "• Keep your account credentials secure.\n"
              "• Use the application responsibly.\n"
              "• Do not misuse or abuse the platform.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // DONATION RULES
            //=================================

            const Text(
              "2. Equipment Donation Rules",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "• Donate only functional equipment.\n"
              "• Provide correct equipment details.\n"
              "• Do not upload prohibited items.\n"
              "• Follow all applicable healthcare regulations.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // REQUEST POLICY
            //=================================

            const Text(
              "3. Equipment Request Policy",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Equipment requests are subject to availability. "
              "Hospitals and donors may approve or reject requests "
              "based on inventory and eligibility.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // LIMITATION OF LIABILITY
            //=================================

            const Text(
              "4. Limitation of Liability",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "MediShare acts as a platform connecting donors and recipients. "
              "The application is not responsible for equipment quality, "
              "delivery delays, or disputes between users.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // UPDATES
            //=================================

            const Text(
              "5. Updates to Terms",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "These terms may be updated periodically. "
              "Continued use of the application indicates acceptance "
              "of the latest version.",

              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // ACCEPTANCE
            //=================================

            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "By using MediShare, you acknowledge that you have read, "
                  "understood, and agreed to these Terms & Conditions.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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