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
        return "You have no requests.";
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