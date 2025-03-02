# SageMath script to decrypt ISTS flag
from sage.all import *
from Crypto.Hash import SHA256
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

# Given parameters
p = 419  # Public prime
ls = [3, 5, 7]  # Prime factors used in isogenies

# Given elliptic curves (Alice's and Bob's public keys)
E_A = EllipticCurve(GF(p), [0, 286, 0, 1, 191])
E_B = EllipticCurve(GF(p), [0, 56, 0, 1, 342])

# Alice's private key (exponents for isogenies)
alice_private_key = {3: 65, 5: -405, 7: 147}

# Function to apply isogenies based on a private key
def apply_isogenies(private_key, E):
    for l, exp in private_key.items():
        for _ in range(abs(exp)):
            if exp > 0:
                E = E.isogeny(E.lift_x(l)).codomain()
            else:
                E = E.isogeny(E.lift_x(l)).codomain()
    return E

# Compute shared secret using Alice's private key and Bob's public key
shared_secret = apply_isogenies(alice_private_key, E_B)
j_inv = shared_secret.j_invariant()

# Derive AES key
aes_key = SHA256.new(data=bytes(j_inv)).digest()

# Encrypted ciphertext from output.txt
ciphertext_hex = "07a3cd1c73b10d16446dae811757c907e960b504f2611a4345689cb76e2637c2"
ciphertext = bytes.fromhex(ciphertext_hex)

# Decrypt the flag
cipher = AES.new(aes_key, AES.MODE_ECB)
decrypted_flag = unpad(cipher.decrypt(ciphertext), 16)

print("Decrypted Flag:", decrypted_flag.decode())
