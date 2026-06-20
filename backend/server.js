require("dotenv").config();

const app = require("./src/app");
const prisma = require("./src/config/prisma");

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    await prisma.$connect();

    console.log("=================================");
    console.log(" PostgreSQL Connected");
    console.log(" Database: thu_vien_ca_nhan");
    console.log("=================================");

    app.listen(PORT, () => {
      console.log(` Server running at http://localhost:${PORT}`);
    });

  } catch (error) {
    console.error(" Database Connection Failed");
    console.error(error);

    process.exit(1);
  }
}

startServer();