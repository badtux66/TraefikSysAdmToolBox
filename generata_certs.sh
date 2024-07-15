#!/bin/bash

# Directory to store certificates
CERT_DIR="$(pwd)/certs"

# List of services
SERVICES=("traefik.local" "zabbix.local" "glpi.local" "portainer.local" "tools.local" "prometheus.local" "grafana.local")

# Create the certificate directory if it doesn't exist
mkdir -p $CERT_DIR

# Root CA variables
ROOT_CA_KEY="$CERT_DIR/rootCA.key"
ROOT_CA_CERT="$CERT_DIR/rootCA.crt"

# Function to create Root CA
generate_root_ca() {
  # Generate Root CA private key
  openssl genrsa -out $ROOT_CA_KEY 2048

  # Generate Root CA certificate
  openssl req -x509 -new -nodes -key $ROOT_CA_KEY -sha256 -days 1024 -out $ROOT_CA_CERT -subj "/CN=MyRootCA"

  echo "Root CA generated:"
  echo "Certificate: $ROOT_CA_CERT"
  echo "Key: $ROOT_CA_KEY"
}

# Function to generate and sign certificates
generate_certificates() {
  local service=$1
  local cert_key="$CERT_DIR/$service.key"
  local cert_csr="$CERT_DIR/$service.csr"
  local cert_crt="$CERT_DIR/$service.crt"
  local cert_ext="$CERT_DIR/$service.ext"

  # Generate a private key
  openssl genrsa -out $cert_key 2048

  # Generate a certificate signing request (CSR)
  openssl req -new -key $cert_key -out $cert_csr -subj "/CN=$service"

  # Create a configuration file for the extensions
  cat > $cert_ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $service
EOF

  # Generate the certificate signed with the root CA
  openssl x509 -req -in $cert_csr -CA $ROOT_CA_CERT -CAkey $ROOT_CA_KEY -CAcreateserial -out $cert_crt -days 500 -sha256 -extfile $cert_ext

  # Remove the CSR and ext file as they are no longer needed
  rm $cert_csr $cert_ext

  echo "Generated certificates for $service:"
  echo "Certificate: $cert_crt"
  echo "Key: $cert_key"
}

# Generate Root CA
generate_root_ca

# Generate and sign certificates for each service
for service in "${SERVICES[@]}"; do
  generate_certificates $service
done

echo "All certificates have been generated and stored in $CERT_DIR."
