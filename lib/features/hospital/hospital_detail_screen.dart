import 'package:flutter/material.dart';

class HospitalDetailScreen extends StatelessWidget {
  const HospitalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Details"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            //=================================
            // HOSPITAL LOGO
            //=================================

            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.red.shade100,

                child: const Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Civil Hospital",

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
                        //=================================
            // HOSPITAL INFORMATION
            //=================================

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
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      title: const Text("Address"),
                      subtitle: const Text(
                        "Asarwa, Ahmedabad, Gujarat",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: Colors.green,
                      ),
                      title: const Text("Phone"),
                      subtitle: const Text(
                        "+91 79 2268 1000",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.email,
                        color: Colors.blue,
                      ),
                      title: const Text("Email"),
                      subtitle: const Text(
                        "info@civilhospital.com",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.language,
                        color: Colors.deepPurple,
                      ),
                      title: const Text("Website"),
                      subtitle: const Text(
                        "www.civilhospital.com",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      title: const Text("Rating"),
                      subtitle: const Text(
                        "4.6 / 5.0",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: Colors.teal,
                      ),
                      title: const Text("Working Hours"),
                      subtitle: const Text(
                        "24 Hours (Open Daily)",
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.emergency,
                        color: Colors.redAccent,
                      ),
                      title: const Text("Emergency Service"),
                      subtitle: const Text(
                        "Available 24 × 7",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
                        //=================================
            // ABOUT HOSPITAL
            //=================================

            const Text(
              "About Hospital",
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
                  "Civil Hospital Ahmedabad is one of the largest government hospitals in India. "
                  "It provides quality healthcare services including emergency care, surgery, "
                  "orthopedics, cardiology, ICU, and medical equipment support.",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            //=================================
            // AVAILABLE FACILITIES
            //=================================

            const Text(
              "Available Facilities",
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
                    leading: Icon(Icons.local_hospital),
                    title: Text("Emergency Care"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.medical_services),
                    title: Text("ICU & Ventilator"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.bed),
                    title: Text("Hospital Beds"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.wheelchair_pickup),
                    title: Text("Wheelchair Support"),
                  ),

                  Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.bloodtype),
                    title: Text("Blood Bank"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            //=================================
            // ACTION BUTTONS
            //=================================

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text("Call"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Calling Hospital...",
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("View Map"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Google Maps integration coming soon.",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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