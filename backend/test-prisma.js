const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

async function main() {
  await prisma.$connect();
  console.log("✅ Prisma Connected Successfully");

  const users = await prisma.user.findMany({
    take: 1,
  });

  console.log(users);

  await prisma.$disconnect();
}

main().catch(async (error) => {
  console.error(error);
  await prisma.$disconnect();
});