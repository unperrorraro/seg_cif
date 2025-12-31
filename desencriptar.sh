#!/bin/bash

DIR="$1"
ST_DIR="$2"

echo "USAGE: ./desencriptar.sh directorio_encriptado almacenamiento_claves"
echo ""
echo "Los archivos se guardan en ./directoio_encriptado/decrypted"
echo ""
KEY_ENC="$ST_DIR/key_enc.bin"
KEY_MAC="$ST_DIR/key_hmac.bin"
KEY_MAC_HEX=$(xxd -p "$KEY_MAC" | tr -d '\n')

# Comprobar que existen las claves
if [ ! -f "$KEY_ENC" ] || [ ! -f "$KEY_MAC" ]; then
  echo "Claves no encontradas en el USB."
  exit 1
fi
mkdir -p "$DIR/decrypted"

find "$DIR/encrypted" -type f -name "*.enc" | while read ENC_FILE; do
  REL_PATH=$(realpath --relative-to="$DIR/encrypted" "$ENC_FILE")
  BASENAME="${REL_PATH%.enc}"
  DEC_PATH="$DIR/decrypted/$BASENAME"
  MAC_FILE="$DIR/mac/$BASENAME.mac"
  MAC_TMP="$DIR/mac/$BASENAME.tmp"

  mkdir -p "$(dirname "$DEC_PATH")"

  # Leer cola MAC
  ORIG_MAC=$(cut -d ' ' -f2 "$MAC_FILE")

  # Calcular MAC
  (openssl dgst -sha256 -mac HMAC -macopt hexkey:"$KEY_MAC_HEX" "$ENC_FILE" | cut -d ' ' -f2) >"$MAC_TMP"

  MAC_TMP_VAR=$(cat "$MAC_TMP")
  # Verificar MAC

  if [ "$ORIG_MAC" == "$MAC_TMP_VAR" ]; then

    rm $MAC_TMP
    openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$ENC_FILE" -out "$DEC_PATH" -pass file:"$KEY_ENC"

    echo "$BASENAME  descifrado."
  else
    rm "$MAC_TMP"
    echo "$BASENAME: MAC no coincide."
  fi
done
