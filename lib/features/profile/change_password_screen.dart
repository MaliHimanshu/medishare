import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final currentPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: const Icon(Icons.lock),

        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: toggle,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const Icon(
              Icons.lock_reset,
              size: 90,
              color: Colors.blue,
            ),

            const SizedBox(height: 30),

            passwordField(
              label: "Current Password",
              controller: currentPasswordController,
              obscure: hideCurrent,
              toggle: () {
                setState(() {
                  hideCurrent = !hideCurrent;
                });
              },
            ),

            const SizedBox(height: 20),

            passwordField(
              label: "New Password",
              controller: newPasswordController,
              obscure: hideNew,
              toggle: () {
                setState(() {
                  hideNew = !hideNew;
                });
              },
            ),

            const SizedBox(height: 20),

            passwordField(
              label: "Confirm Password",
              controller: confirmPasswordController,
              obscure: hideConfirm,
              toggle: () {
                setState(() {
                  hideConfirm = !hideConfirm;
                });
              },
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text(
                  "Update Password",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Password Updated Successfully",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}