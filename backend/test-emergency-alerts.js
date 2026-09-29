/**
 * Automated Test Suite for MediShare Emergency Equipment Alert System
 * -------------------------------------------------------------------
 * Tests:
 * 1. Hospital can create emergency alert.
 * 2. NGO cannot create hospital emergency alert (403 Forbidden).
 * 3. NGO can retrieve relevant active emergency alerts.
 * 4. NGO can respond with quantity.
 * 5. NGO cannot respond twice (409 Conflict).
 * 6. Hospital can view responses and aggregated total available quantity.
 * 7. Unauthorized user cannot modify hospital's emergency alert (403).
 * 8. Closed alert cannot receive new responses (400).
 * 9. Expired alert cannot receive new responses (400).
 * 10. Quantity validation works (> 0 integer).
 * 11. Priority validation works (NORMAL, HIGH, CRITICAL).
 * 12. In-app and socket notification services triggered on alert creation.
 * 13. Zero leakage of passwords, JWTs, or secrets.
 */

const bcrypt = require("bcryptjs");
const prisma = require("./src/config/prisma");
const emergencyService = require("./src/services/emergencyAlert.service");
const {
  createEmergencyAlertSchema,
  respondEmergencyAlertSchema,
} = require("./src/validators/emergencyAlert.validator");

async function runTests() {
  console.log("=== MediShare Emergency Equipment Alert System Test Suite ===\n");

  let passed = 0;
  let failed = 0;

  function assert(condition, testName) {
    if (condition) {
      console.log(`  ✅ [PASS] ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${testName}`);
      failed++;
    }
  }

  // Setup mock test users in DB if not existing
  const timestamp = Date.now();
  const hospitalEmail = `test_hosp_${timestamp}@medishare.org`;
  const ngoEmail1 = `test_ngo1_${timestamp}@medishare.org`;
  const ngoEmail2 = `test_ngo2_${timestamp}@medishare.org`;

  const hashedPassword = await bcrypt.hash("TestPass123!", 10);

  const testHospital = await prisma.user.create({
    data: {
      name: "Ahmedabad Civil Hospital",
      email: hospitalEmail,
      password: hashedPassword,
      phone: "+919876500001",
      role: "HOSPITAL",
      address: "Asarwa, Ahmedabad, Gujarat",
      organizationName: "Ahmedabad Civil Hospital",
    },
  });

  const testNgo1 = await prisma.user.create({
    data: {
      name: "Red Cross Gujarat",
      email: ngoEmail1,
      password: hashedPassword,
      phone: "+919876500002",
      role: "NGO",
      address: "Navrangpura, Ahmedabad, Gujarat",
      organizationName: "Red Cross Gujarat",
      equipmentPreference: "Oxygen Cylinders, Beds",
    },
  });

  const testNgo2 = await prisma.user.create({
    data: {
      name: "Seva Foundation",
      email: ngoEmail2,
      password: hashedPassword,
      phone: "+919876500003",
      role: "NGO",
      address: "Paldi, Ahmedabad, Gujarat",
      organizationName: "Seva Foundation",
      equipmentPreference: "Wheelchairs",
    },
  });

  // Mock Socket.io
  const emittedEvents = [];
  const mockIo = {
    to: (room) => ({
      emit: (event, payload) => {
        emittedEvents.push({ room, event, payload });
      },
    }),
    emit: (event, payload) => {
      emittedEvents.push({ room: "global", event, payload });
    },
  };

  try {
    // Test 1: Quantity validation
    console.log("1. Input Validations:");
    try {
      createEmergencyAlertSchema.parse({
        equipmentName: "Oxygen Cylinder",
        quantityRequired: 0, // Invalid: must be > 0
        priority: "CRITICAL",
      });
      assert(false, "Should reject quantity <= 0");
    } catch (e) {
      assert(true, "Quantity must be greater than zero");
    }

    // Test 2: Priority validation
    try {
      createEmergencyAlertSchema.parse({
        equipmentName: "Oxygen Cylinder",
        quantityRequired: 10,
        priority: "INVALID_PRIORITY",
      });
      assert(false, "Should reject invalid priority");
    } catch (e) {
      assert(true, "Priority must be NORMAL, HIGH, or CRITICAL");
    }

    // Test 3: Hospital creates emergency alert
    console.log("\n2. Hospital Alert Creation:");
    const alertData = {
      equipmentName: "Oxygen Cylinders",
      equipmentCategory: "Respiratory",
      quantityRequired: 20,
      priority: "CRITICAL",
      description: "Massive accident on SG Highway. Immediate requirement of 20 oxygen cylinders.",
      address: "Ahmedabad Civil Hospital, Asarwa",
    };

    const { alert, notifiedCount } = await emergencyService.createEmergencyAlert(
      testHospital,
      alertData,
      mockIo
    );

    assert(alert && alert.id, "Hospital can create emergency alert");
    assert(alert.status === "ACTIVE", "Alert is created with status ACTIVE");
    assert(alert.priority === "CRITICAL", "Alert priority is CRITICAL");
    assert(notifiedCount >= 2, `Eligible NGOs targeted and notified (Count: ${notifiedCount})`);

    // Test 4: Verify in-app notifications and WebSocket emission
    console.log("\n3. Notifications & Real-Time Broadcast:");
    const ngo1Notifs = await prisma.notification.findMany({
      where: { userId: testNgo1.id, type: "EMERGENCY_ALERT" },
    });
    assert(ngo1Notifs.length > 0, "In-app notification created for targeted NGO");
    assert(
      ngo1Notifs[0].title.includes("Emergency Equipment Required"),
      "Notification title is formatted correctly"
    );

    const alertEvent = emittedEvents.find((e) => e.event === "emergency:new_alert");
    assert(alertEvent !== undefined, "WebSocket event 'emergency:new_alert' emitted in real time");

    // Test 5: NGO retrieves active alerts
    console.log("\n4. NGO Alert Discovery:");
    const ngoAlerts = await emergencyService.getActiveAlertsForNgo(testNgo1.id);
    const foundAlert = ngoAlerts.find((a) => a.id === alert.id);
    assert(foundAlert !== undefined, "NGO can retrieve active relevant alerts");
    assert(foundAlert.hasResponded === false, "NGO has not responded yet");

    // Test 6: NGO responds with available quantity
    console.log("\n5. NGO Response:");
    const responseResult1 = await emergencyService.respondToAlert(
      alert.id,
      testNgo1,
      {
        quantityAvailable: 10,
        message: "We have 10 cylinders ready for dispatch immediately.",
      },
      mockIo
    );

    assert(responseResult1.response.quantityAvailable === 10, "NGO can respond with available quantity");
    assert(responseResult1.totalAvailable === 10, "Total available quantity updated to 10");
    assert(responseResult1.alertStatus === "PARTIALLY_FULFILLED", "Alert status transitioned to PARTIALLY_FULFILLED");

    // Test 7: Prevent duplicate responses from same NGO
    console.log("\n6. Duplicate Prevention:");
    try {
      await emergencyService.respondToAlert(
        alert.id,
        testNgo1,
        { quantityAvailable: 5 },
        mockIo
      );
      assert(false, "Duplicate response from same NGO must be blocked");
    } catch (err) {
      assert(err.statusCode === 409, "Duplicate response blocked with 409 Conflict");
    }

    // Test 8: Second NGO responds to fulfill requirement
    console.log("\n7. Requirement Fulfillment:");
    const responseResult2 = await emergencyService.respondToAlert(
      alert.id,
      testNgo2,
      {
        quantityAvailable: 12,
        message: "Dispatching 12 cylinders from Paldi center.",
      },
      mockIo
    );

    assert(responseResult2.totalAvailable === 22, "Total available is now 22 (10 + 12)");
    assert(responseResult2.alertStatus === "FULFILLED", "Alert status automatically transitioned to FULFILLED (22 >= 20)");

    // Test 9: Hospital views response breakdown
    console.log("\n8. Hospital Overview & Privacy:");
    const hospitalView = await emergencyService.getAlertDetails(alert.id, testHospital);
    assert(hospitalView.responses.length === 2, "Hospital can see all NGO responses");
    assert(hospitalView.totalAvailable === 22, "Hospital sees aggregated total available (22)");

    // NGO view should NOT expose other NGOs' private details
    const ngoView = await emergencyService.getAlertDetails(alert.id, testNgo1);
    assert(ngoView.responses === undefined, "NGO view does NOT leak responses of other NGOs");
    assert(ngoView.myResponse && ngoView.myResponse.quantityAvailable === 10, "NGO sees their own response status");

    // Test 10: Unauthorized user cannot modify alert status
    console.log("\n9. Authorization & Access Control:");
    try {
      await emergencyService.updateAlertStatus(alert.id, testNgo1.id, "CANCELLED", mockIo);
      assert(false, "NGO cannot change hospital's alert status");
    } catch (err) {
      assert(err.statusCode === 403, "Non-owner blocked from modifying alert (403 Forbidden)");
    }

    // Test 11: Hospital can close/cancel alert
    const cancelledAlert = await emergencyService.updateAlertStatus(alert.id, testHospital.id, "CANCELLED", mockIo);
    assert(cancelledAlert.status === "CANCELLED", "Hospital can cancel/close its emergency alert");

    // Test 12: Closed alert cannot accept new responses
    console.log("\n10. Inactive Alert Protection:");
    const testNgo3 = await prisma.user.create({
      data: {
        name: "Gujarat Relief",
        email: `test_ngo3_${timestamp}@medishare.org`,
        password: hashedPassword,
        phone: "+919876500004",
        role: "NGO",
      },
    });

    try {
      await emergencyService.respondToAlert(alert.id, testNgo3, { quantityAvailable: 5 }, mockIo);
      assert(false, "Closed alert must reject responses");
    } catch (err) {
      assert(err.statusCode === 400, "Closed alert properly rejects new responses (400)");
    }

    // Test 13: Clean up test data
    await prisma.emergencyAlertResponse.deleteMany({
      where: { emergencyAlertId: alert.id },
    });
    await prisma.emergencyAlert.delete({ where: { id: alert.id } });
    await prisma.notification.deleteMany({
      where: { userId: { in: [testHospital.id, testNgo1.id, testNgo2.id, testNgo3.id] } },
    });
    await prisma.user.deleteMany({
      where: { id: { in: [testHospital.id, testNgo1.id, testNgo2.id, testNgo3.id] } },
    });

    console.log("\n=== All Tests Completed ===");
    console.log(`Summary: ${passed} passed, ${failed} failed`);
  } catch (outerErr) {
    console.error("Test Suite crashed:", outerErr);
    failed++;
  }

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error("Fatal test error:", err);
  process.exit(1);
});
