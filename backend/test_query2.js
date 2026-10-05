const { PrismaClient } = require('@prisma/client'); 
const prisma = new PrismaClient(); 
prisma.rental.findUnique({where: {id: 'cmuu5fcgg0001sz80z9plvwdt'}})
.then(console.log)
.catch(console.error)
.finally(()=>prisma.$disconnect());
