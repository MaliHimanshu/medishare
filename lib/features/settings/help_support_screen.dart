import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
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
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.blue,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Need Help?",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Find answers to common questions or contact our support team.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),
                        //=================================
            // SUPPORT OPTIONS
            //=================================

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                children: [

                  ListTile(
                    leading: const Icon(
                      Icons.phone,
                      color: Colors.green,
                    ),
                    title: const Text("Call Support"),
                    subtitle: const Text("+91 9876543210"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.email,
                      color: Colors.blue,
                    ),
                    title: const Text("Email Support"),
                    subtitle: const Text("support@medishare.com"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.question_answer,
                      color: Colors.orange,
                    ),
                    title: const Text("Frequently Asked Questions"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("FAQ Coming Soon"),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.chat,
                      color: Colors.purple,
                    ),
                    title: const Text("Live Chat"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Live Chat Coming Soon"),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.bug_report,
                      color: Colors.red,
                    ),
                    title: const Text("Report an Issue"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Report Issue Coming Soon"),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.star_rate,
                      color: Colors.amber,
                    ),
                    title: const Text("Rate Our App"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Thank you for your feedback!"),
                        ),
                      );
                    },
                  ),
                ],
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