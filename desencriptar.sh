#!/bin/bash

DIR="$1"
ST_DIR="$2"

KEY_ENC="$ST_DIR/key_enc.bin"
KEY_HMAC="$ST_DIR/key_hmac.bin"
KEY_HMAC_HEX=$(xxd -p "$KEY_HMAC" | tr -d '\n')

# Comprobar que existen las claves
if [ ! -f "$KEY_ENC" ] || [ ! -f "$KEY_HMAC" ]; then
  echo "Claves no encontradas en el USB."
  exit 1
fi
echo "$DIR/decrypted"
mkdir -p "$DIR/decrypted"

find "$DIR/encrypted" -type f -name "*.enc" | while read ENC_FILE; do
  REL_PATH=$(realpath --relative-to="$DIR/encrypted" "$ENC_FILE")
  BASENAME="${REL_PATH%.enc}"
  BASENAME="${REL_PATH%.enc}"
  DEC_PATH="$DIR/decrypted/$BASENAME"
  MAC_FILE="$DIR/mac/$BASENAME.mac"

  mkdir -p "$(dirname "$DEC_PATH")"

  # Leer cola MAC
  ORIG_MAC=$(cut -d ' ' -f2 "$MAC_FILE")

  # Descifrar
  openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$ENC_FILE" -out "$DEC_PATH.tmp" -pass file:"$KEY_ENC"

  # Calcular MAC
  CALC_MAC=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:"$KEY_HMAC_HEX" "$DEC_PATH.tmp" | cut -d ' ' -f2)

  # Verificar MAC antes de mover
  if [ "$ORIG_MAC" == "$CALC_MAC" ]; then
    mv "$DEC_PATH.tmp" "$DEC_PATH"
    echo "$BASENAME verificado y descifrado."
  else
    rm "$DEC_PATH.tmp"
    echo "$BASENAME: MAC no coincide, posible manipulación."
  fi
done
