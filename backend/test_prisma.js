const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Connecting to database...");
  await prisma.$connect();
  console.log("DATABASE CONNECTED");

  console.log("Querying first user...");
  const firstUser = await prisma.user.findFirst({
    select: { id: true, email: true, role: true }
  });
  console.log("First User:", firstUser);

  console.log("Querying deliverypartner@medishare.com...");
  const dpUser = await prisma.user.findUnique({
    where: { email: 'deliverypartner@medishare.com' },
    select: { id: true, email: true, role: true }
  });
  console.log("Delivery Partner:", dpUser);
}

main()
  .catch((e) => {
    console.error("Diagnostic Error:", e);
  })
  .finally(async () => {
    await prisma.$disconnect();
    console.log("Disconnected.");
  });
