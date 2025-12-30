#!/bin/bash
# Uso: ./encrypt_and_mac.sh directorio ruta_usb

DIR="$1"
USB_DIR="$2"

if [ ! -d "$USB_DIR" ]; then
  echo "No se encontró el almacenamiento de claves en $USB_DIR"
  exit 1
fi

mkdir -p "out" "out/encrypted" "out/mac"

# Generar nuevas claves siempre
if [ -f "$USB_DIR/key_enc.bin" ]; then

  chmod 600 "$USB_DIR/key_enc.bin"

fi
openssl rand -out "$USB_DIR/key_enc.bin" 32
echo "Nueva clave de cifrado generada y guardada en USB."
chmod 400 "$USB_DIR/key_hmac.bin"
if [ -f "$USB_DIR/key_hmac.bin" ]; then

  chmod 600 "$USB_DIR/key_hmac.bin"

fi

openssl rand -out "$USB_DIR/key_hmac.bin" 32
chmod 400 "$USB_DIR/key_hmac.bin"
echo "Nueva clave de HMAC generada y guardada en USB."

KEY_ENC="$USB_DIR/key_enc.bin"
KEY_HMAC="$USB_DIR/key_hmac.bin"
KEY_HMAC_HEX=$(xxd -p "$KEY_HMAC" | tr -d '\n')

find "$DIR" -type f ! -path "$DIR/encrypted/*" ! -path "$DIR/mac/*" | while read FILE; do
  FILE_ABS=$(realpath "$FILE")
  REL_PATH=$(realpath --relative-to="$DIR" "$FILE_ABS")
  ENC_PATH="out/encrypted/$REL_PATH.enc"
  MAC_PATH="out/mac/$REL_PATH.mac"

  # Crear directorios destino si no existen
  mkdir -p "$(dirname "$ENC_PATH")" "$(dirname "$MAC_PATH")"
  # Cifrar archivo
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$FILE" -out "$ENC_PATH" -pass file:"$KEY_ENC"

  # Generar MAC
  openssl dgst -sha256 -mac HMAC -macopt hexkey:"$KEY_HMAC_HEX" "$FILE" >"$MAC_PATH"
done

echo "Cifrado y MAC completados."
