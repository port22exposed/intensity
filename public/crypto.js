import kemBuilder from "./lib/pqc-kem-kyber1024-90s"

export const kem = await kemBuilder()

export const { publicKey, privateKey } = await kem.keypair()
