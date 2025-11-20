import './seed-setup.js';

/* The `seed-setup.js` module calls the helpers and handles running seeding logic. */
console.log('Seeds completed.');
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
