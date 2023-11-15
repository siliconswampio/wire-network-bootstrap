echo "Fetching rows from abihash table..."
abihash_data=$(cleos -u https://f0a4-172-109-209-165.ngrok-free.app/ get table eosio eosio abihash | jq -r '.rows[0].hash')

# Assuming you have a local ABI file to compare with
abi_file="~/contracts/eosio.contracts/build/contracts/eosio.system/eosio.system.abi"

echo $abihash_data

# Calculate checksum of the ABI file
echo "Calculating checksum of the ABI file..."
# calculated_checksum=$(sha256sum "$abi_file" | awk '{ print $1 }')
calculated_checksum=$(openssl dgst -sha256 -binary "$abi_file" | openssl enc -base64)

# Extract the relevant checksum from the fetched data
# Note: Adjust the following command according to the actual structure of your abihash_data
extracted_checksum=$(echo "$abihash_data" | grep -Po '"checksum": "\K[^"]+')

# Compare checksums
if [ "$calculated_checksum" == "$extracted_checksum" ]; then
    echo "Checksums match."
else
    echo "Checksums do not match."
fi