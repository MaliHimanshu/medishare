const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const email = 'deliverypartner@medishare.com';
  
  // Verify the user exists
  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    console.log(`User ${email} not found.`);
    return;
  }

  console.log(`Updating role for ${email}...`);
  const updatedUser = await prisma.user.update({
    where: { email },
    data: { role: 'DELIVERY_PARTNER' },
  });

  console.log(`Successfully updated ${email} to role: ${updatedUser.role}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
