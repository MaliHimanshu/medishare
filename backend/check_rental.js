const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasources: { db: { url: process.env.DATABASE_URL } } });

async function main() {
  try {
    const rental = await prisma.rental.findUnique({
      where: { id: 'cmuu5fcgg0001sz80z9plvwdt' },
    });
    console.log('Rental exists:', !!rental);
    if (rental) {
      console.log(rental);
    }
  } catch (error) {
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}
main();
