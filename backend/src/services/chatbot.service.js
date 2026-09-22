const Groq = require("groq-sdk");
const prisma = require("../config/prisma");

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

const askAI = async (message, user) => {
  try {
    const question = message.toLowerCase();

    // ==========================
    // DATABASE RESPONSES
    // ==========================

    // Total Equipment
    if (
      question.includes("total equipment") ||
      question.includes("how many equipment")
    ) {
      const total = await prisma.equipment.count();

      return `There are ${total} equipment items registered in MediShare.`;
    }

    // Available Equipment
    if (
      question.includes("available equipment") ||
      question.includes("equipment available")
    ) {
      const total = await prisma.equipment.count({
        where: {
          status: "AVAILABLE",
        },
      });

      return `Currently ${total} equipment items are available.`;
    }

    // Total Hospitals
    if (
      question.includes("hospital") &&
      question.includes("how many")
    ) {
      const total = await prisma.hospital.count();

      return `There are ${total} registered hospitals.`;
    }

    // Total Donations
    if (
      question.includes("donation") &&
      question.includes("how many")
    ) {
      const total = await prisma.donation.count();

      return `There are ${total} donations in the system.`;
    }

    // My Equipment (for Donor / Hospital)
    if (
      question.includes("my equipment") ||
      question.includes("show my equipment")
    ) {
      const items = await prisma.equipment.findMany({
        where: { ownerId: user.id },
        select: { name: true, status: true, mode: true },
      });

      if (items.length === 0) {
        return "You have not listed any equipment yet.";
      }

      return `Your equipment listings (${items.length}):\n` +
        items.map((e) => `• ${e.name} (${e.mode}) - ${e.status}`).join("\n");
    }

    // Rental Requests (for Donor / Hospital)
    if (
      question.includes("rental request") ||
      question.includes("rental requests")
    ) {
      const rentals = await prisma.rental.findMany({
        where: { equipment: { ownerId: user.id } },
        include: { equipment: true, renter: true },
      });

      if (rentals.length === 0) {
        return "You have no rental requests for your equipment.";
      }

      return `Rental requests for your equipment (${rentals.length}):\n` +
        rentals
          .map(
            (r) =>
              `• ${r.equipment.name} requested by ${r.renter.name} - ${r.status}`
          )
          .join("\n");
    }

    // My Rentals (for Recipient / Hospital)
    if (
      question.includes("my rental") ||
      question.includes("my rentals")
    ) {
      const rentals = await prisma.rental.findMany({
        where: { renterId: user.id },
        include: { equipment: true },
      });

      if (rentals.length === 0) {
        return "You have no active or previous rentals.";
      }

      return `Your rentals (${rentals.length}):\n` +
        rentals
          .map((r) => `• ${r.equipment.name} - Status: ${r.status}`)
          .join("\n");
    }

    // My Requests
    if (
      question.includes("my request") ||
      question.includes("show my requests")
    ) {
      const requests = await prisma.request.findMany({
        where: {
          requesterId: user.id,
        },
        include: {
          equipment: true,
        },
      });

      if (requests.length === 0) {
        return "You have no equipment requests.";
      }

      return requests
        .map(
          (r) =>
            `• ${r.equipment.name} - ${r.status}`
        )
        .join("\n");
    }

    // ==========================
    // GROQ FALLBACK
    // ==========================

    const completion = await groq.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      messages: [
        {
          role: "system",
          content: `
You are MediShare AI Assistant.

MediShare is a Medical Equipment Donation and Redistribution Platform.

Answer professionally and clearly.

If the question is not about live MediShare database data,
answer it normally.
          `,
        },
        {
          role: "user",
          content: message,
        },
      ],
      temperature: 0.5,
      max_tokens: 500,
    });

    return completion.choices[0].message.content;
  } catch (error) {
    console.error("Groq Error:", error);
    throw new Error("Unable to generate AI response.");
  }
};

module.exports = {
  askAI,
};