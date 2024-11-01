import officeCrypto from "officecrypto-tool";
import { promises as fs } from "fs";
import path from "path";

async function encryptExcelFile(filePath, password) {
  try {
    // Check if file exists
    await fs.access(filePath);

    // Read the input file
    const input = await fs.readFile(filePath);

    // Check if already encrypted
    if (officeCrypto.isEncrypted(input)) {
      console.error("File is already encrypted!");
      process.exit(1);
    }

    // Encrypt the file
    const output = officeCrypto.encrypt(input, { password });

    // Generate output filename
    const dir = path.dirname(filePath);
    const ext = path.extname(filePath);
    const basename = path.basename(filePath, ext);
    const outputPath = path.join(dir, `${basename}-encrypted${ext}`);

    // Write the encrypted file
    await fs.writeFile(outputPath, output);

    console.log(`Successfully encrypted: ${outputPath}`);
    console.log(`Password: ${password}`);
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

// Get command line arguments
const args = process.argv.slice(2);

if (args.length === 0) {
  console.error("Usage: node script/encrypt_excel.mjs <path-to-xlsx-file>");
  process.exit(1);
}

const filePath = args[0];
const password = process.env.EXPORT_PASSWORD || "default_password";

encryptExcelFile(filePath, password);
