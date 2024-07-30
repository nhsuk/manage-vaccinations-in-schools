// This converts a buffer to a base64 string using the FileReader API.
// This appears to be the fastest method.
// See https://stackoverflow.com/a/9458996/2490003
const bufferToBase64 = (buffer: ArrayBuffer): Promise<string> => {
  const blob = new Blob([buffer], { type: "application/octet-binary" });
  const reader = new FileReader();

  return new Promise((resolve, reject) => {
    reader.onloadend = () => {
      resolve((reader.result as string).split(",")[1]);
    };
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
};

const base64ToBuffer = (base64: string): Uint8Array => {
  const binaryString = self.atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
};

/**
 * This is an encryption class that uses the Web Crypto API to encrypt and decrypt a string using a passphrase and a salt.
 *
 * Usage:
 *     const secret = new SimpleCrypto("my-passphrase", "my-salt");
 *     await secret.init();
 *     const encrypted = await secret.encrypt("hello world");
 *     const decrypted = await secret.decrypt(encrypted);
 */
export class SimpleCrypto {
  private passphrase: string;
  private salt: string;
  private key?: CryptoKey;

  /**
   * @param passphrase The passphrase to use. This can be provided by the user and should be stored securely.
   * @param salt A preferably random string that is used to salt the passphrase, to ensure that ciphertexts of the same data with the same passphrase are different.
   * @returns A new SimpleCrypto instance.
   */
  constructor(passphrase: string, salt: string) {
    this.passphrase = passphrase;
    this.salt = salt;
  }

  /**
   * Parses the passphrase and salt into a determinstic CryptoKey that can be used for encryption and decryption.
   *
   * @returns A Promise that resolves when the key is ready.
   * */
  public async init(): Promise<void> {
    const encoder = new TextEncoder();

    // First, import an initial key from the passphrase. On its own, this key
    // is not secure, as it could be brute forced, so we can't directly use it
    // to encrypt and decrypt data.
    const initialKey = await crypto.subtle.importKey(
      "raw",
      encoder.encode(this.passphrase),
      { name: "PBKDF2" },
      false,
      ["deriveBits", "deriveKey"],
    );

    // Derive a new key from the initial key. Using salt makes it unique per
    // user, and using lots of iterations makes it computationally expensive to
    // brute force.
    this.key = await crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: encoder.encode(this.salt),
        iterations: 100000,
        hash: "SHA-256",
      },
      initialKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["encrypt", "decrypt"],
    );
  }

  /**
   * Encrypts the provided plaintext string.
   *
   * @param plaintext The plaintext string to encrypt.
   * @returns A base64-encoded string containing the initialization vector and the ciphertext.
   */
  public async encrypt(plaintext: string): Promise<string> {
    const encoder = new TextEncoder();

    // Each AES-GCM encryption requires a unique initialization vector, or
    // iv. The iv should be 12 bytes long and is safe to store in plaintext
    // alongside the ciphertext.
    const iv = crypto.getRandomValues(new Uint8Array(12));

    const ciphertext: ArrayBuffer = await crypto.subtle.encrypt(
      {
        name: "AES-GCM",
        iv,
      },
      this.key,
      encoder.encode(plaintext),
    );

    // Prepend the iv to the ciphertext, so that it can be retrieved later,
    // then base64-encode the result.
    return await bufferToBase64(
      new Uint8Array([...iv, ...new Uint8Array(ciphertext)]),
    );
  }

  /**
   * Decrypts the provided ciphertext string.
   *
   * @param ciphertextBase64 A base64-encoded string containing the initialization vector and the ciphertext.
   * @returns The decrypted plaintext string.
   */
  public async decrypt(ciphertextBase64: string): Promise<string> {
    const decoder = new TextDecoder();

    const ciphertextBuffer = base64ToBuffer(ciphertextBase64);
    const iv = ciphertextBuffer.slice(0, 12);
    const ciphertext = ciphertextBuffer.slice(12);

    const plaintext: Uint8Array = await crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv,
      },
      this.key,
      ciphertext,
    );

    return decoder.decode(plaintext);
  }
}
