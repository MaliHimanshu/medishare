import 'package:flutter/material.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Request Details"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            //==================================
            // ICON
            //==================================

            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.orange.shade100,

                child: const Icon(
                  Icons.assignment,
                  size: 60,
                  color: Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Wheelchair Request",

              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
                        //==================================
            // REQUEST INFORMATION
            //==================================

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [

                    ListTile(
                      leading: const Icon(
                        Icons.medical_services,
                        color: Colors.blue,
                      ),
                      title: const Text("Equipment"),
                      subtitle: const Text("Wheelchair"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.inventory,
                        color: Colors.orange,
                      ),
                      title: const Text("Quantity"),
                      subtitle: const Text("2"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.local_hospital,
                        color: Colors.red,
                      ),
                      title: const Text("Hospital"),
                      subtitle: const Text("Civil Hospital"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Colors.green,
                      ),
                      title: const Text("Requested By"),
                      subtitle: const Text("Rahul Sharma"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Colors.deepPurple,
                      ),
                      title: const Text("Request Date"),
                      subtitle: const Text("20 July 2026"),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                      ),
                      title: const Text("Location"),
                      subtitle: const Text(
                        "Ahmedabad, Gujarat",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.info,
                        color: Colors.teal,
                      ),
                      title: const Text("Status"),

                      subtitle: Chip(
                        backgroundColor:
                            Colors.orange.shade100,
                        label: const Text(
                          "Pending",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
                        //==================================
            // REQUEST DESCRIPTION
            //==================================

            const Text(
              "Request Description",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  "The patient requires a wheelchair for post-surgery mobility. "
                  "The request is urgent and has been submitted by the hospital for immediate assistance.",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            //==================================
            // CONTACT INFORMATION
            //==================================

            const Text(
              "Contact Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 3,
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
                    subtitle: Text("hospital@medishare.com"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                    title: Text("Address"),
                    subtitle: Text(
                      "Civil Hospital, Ahmedabad, Gujarat",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            //==================================
            // ACTION BUTTONS
            //==================================

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Request Approved Successfully",
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Request Rejected",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //==================================
            // BACK BUTTON
            //==================================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
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