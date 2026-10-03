const Groq = require("groq-sdk");
const prisma = require("../config/prisma");

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

const askAI = async (message, user) => {
  try {
    // Gather system-wide context
    const totalEquip = await prisma.equipment.count();
    const availableEquip = await prisma.equipment.count({ where: { status: "AVAILABLE" } });
    const totalHospitals = await prisma.hospital.count();
    const totalDonations = await prisma.donation.count();

    // Gather user-specific context
    const myItems = await prisma.equipment.findMany({
      where: { ownerId: user.id },
      select: { name: true, status: true, mode: true },
    });
    const myItemsStr = myItems.length > 0 
      ? myItems.map(e => `${e.name} (${e.mode}) - ${e.status}`).join("; ") 
      : "None";

    const myRentalRequests = await prisma.rental.findMany({
      where: { equipment: { ownerId: user.id } },
      include: { equipment: true, renter: true },
    });
    const myRentalRequestsStr = myRentalRequests.length > 0 
      ? myRentalRequests.map(r => `${r.equipment.name} requested by ${r.renter.name} (Status: ${r.status})`).join("; ") 
      : "None";

    const myRentals = await prisma.rental.findMany({
      where: { renterId: user.id },
      include: { equipment: true },
    });
    const myRentalsStr = myRentals.length > 0 
      ? myRentals.map(r => `${r.equipment.name} (Status: ${r.status})`).join("; ") 
      : "None";

    const myRequests = await prisma.request.findMany({
      where: { requesterId: user.id },
      include: { equipment: true },
    });
    const myRequestsStr = myRequests.length > 0 
      ? myRequests.map(r => `${r.equipment.name} (Status: ${r.status})`).join("; ") 
      : "None";

    const systemPrompt = `
You are the MediShare AI Assistant.
MediShare is a Medical Equipment Donation and Redistribution Platform.
The user you are speaking to is named ${user.name || "User"} and their role is ${user.role || "User"}.

Here is the LIVE context from the MediShare Database:
- Total Equipment in system: ${totalEquip}
- Available Equipment: ${availableEquip}
- Total Registered Hospitals: ${totalHospitals}
- Total Donations: ${totalDonations}

User's Personal Data Context:
- User's listed equipment: ${myItemsStr}
- Rental requests for user's equipment: ${myRentalRequestsStr}
- User's active/past rentals: ${myRentalsStr}
- User's equipment requests: ${myRequestsStr}

INSTRUCTIONS:
1. Answer the user's question naturally using this data if it is relevant.
2. If the user greets you, greet them back and ask how you can help.
3. Be professional and concise.
4. DO NOT mention that you have access to a database, backend, or context prompt. Act like you just know this information seamlessly.
`;

    const completion = await groq.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      messages: [
        {
          role: "system",
          content: systemPrompt,
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