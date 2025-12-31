#!/bin/bash

DIR="$1"
ST_DIR="$2"

if [ ! -d "$ST_DIR" ]; then
  echo "No se encontró el almacenamiento de claves en $ST_DIR"
  exit 1
fi

mkdir -p "out" "out/encrypted" "out/mac"

# Generar nuevas claves siempre
if [ -f "$ST_DIR/key_enc.bin" ]; then

  chmod 600 "$ST_DIR/key_enc.bin"

fi
openssl rand -out "$ST_DIR/key_enc.bin" 32

echo "Nueva clave de cifrado generada y guardada en almacenamiento."
chmod 400 "$ST_DIR/key_hmac.bin"
if [ -f "$ST_DIR/key_hmac.bin" ]; then

  chmod 600 "$ST_DIR/key_hmac.bin"

fi

openssl rand -out "$ST_DIR/key_hmac.bin" 32
chmod 400 "$ST_DIR/key_hmac.bin"
echo "Nueva clave de HMAC generada y guardada en almacenamiento."

KEY_ENC="$ST_DIR/key_enc.bin"
KEY_HMAC="$ST_DIR/key_hmac.bin"
KEY_HMAC_HEX=$(xxd -p "$KEY_HMAC" | tr -d '\n')

find "$DIR" -type f ! -path "$DIR/encrypted/*" ! -path "$DIR/mac/*" | while read FILE; do
  FILE_ABS=$(realpath "$FILE")
  REL_PATH=$(realpath --relative-to="$DIR" "$FILE_ABS")
  ENC_PATH="out/encrypted/$REL_PATH.enc"
  MAC_PATH="out/mac/$REL_PATH.mac"

  # Crear directorios
  mkdir -p "$(dirname "$ENC_PATH")" "$(dirname "$MAC_PATH")"
  # Cifrar
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$FILE" -out "$ENC_PATH" -pass file:"$KEY_ENC"
  chmod 400 "$ENC_PATH"

  # MAC
  openssl dgst -sha256 -mac HMAC -macopt hexkey:"$KEY_HMAC_HEX" "$ENC_PATH" >"$MAC_PATH"
  chmod 400 "$MAC_PATH"
done

echo "FIN"
