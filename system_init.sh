# Run this script AFTER `make run` to set up the system contract fully.
# NOTE: REPLACE URL WITH CHAIN API URL
#!/bin/bash
set -e;
# Create system token.
cleos -u https://66ee-172-109-209-165.ngrok-free.app push action eosio.token create \
  '[ "eosio", "1000000000.0000 EOS"]' \
  -p eosio.token@active ;

# Issue initial supply to eosio.
cleos -u https://66ee-172-109-209-165.ngrok-free.app push action eosio.token issue \
  '[ "eosio", "100000000.0000 EOS", "initial issuance" ]' \
  -p eosio@active ;

# Deploy system contract eosio.system.
set +e;  # Don't exit on command errors

while true; do
    # Fetch initial hash from the abihash table
    echo "Fetching initial hash from abihash table..."
    initial_hash=$(cleos -u https://66ee-172-109-209-165.ngrok-free.app get table eosio eosio abihash | jq -r '.rows[0].hash')
    echo "Initial hash: $initial_hash"

    # Loop until the contract is successfully deployed
    while true; do
        echo "Deploying eosio.system contract...";
        if cleos -u https://66ee-172-109-209-165.ngrok-free.app set contract eosio ~/contracts/eosio.contracts/build/contracts/eosio.system -x 3600; then
            echo "Contract deployed successfully."
            break
        else
            echo "Failed to deploy, retrying..."
            # Optional: Add a sleep here if you want to wait before retrying
            # sleep 5
        fi
    done

    # Fetch new hash from the abihash table
    echo "Fetching new hash from abihash table..."
    new_hash=$(cleos -u https://66ee-172-109-209-165.ngrok-free.app get table eosio eosio abihash | jq -r '.rows[0].hash')
    echo "New hash: $new_hash"

    # Check if hash has changed
    if [ "$initial_hash" != "$new_hash" ]; then
        echo "Hash value has changed. Exiting loop."
        break
    else
        echo "Hash value has not changed. Redeploying..."
        # Optional: Add a sleep here if you want to wait before redeploying
        # sleep 5
    fi
done

set -e;  # Exit on command errors from here on

# Init system contract.
cleos -u https://66ee-172-109-209-165.ngrok-free.app push action eosio init \
  '["0", "4,EOS"]' \
  -p eosio@active ;

# buyram for eosio
cleos -u https://66ee-172-109-209-165.ngrok-free.app push transaction '{"delay_sec":0,"actions":[{"account":"eosio","name":"buyram","data":{"payer":"eosio","receiver":"eosio","quant":"5.0000 EOS"},"authorization":[{"actor":"eosio","permission":"active"}]}]}' ;

# delegatebw for eosio
cleos -u https://66ee-172-109-209-165.ngrok-free.app push transaction '{"delay_sec":0,"actions":[{"account":"eosio","name":"delegatebw","data":{"from":"eosio","receiver":"eosio","stake_net_quantity":"10.0000 EOS","stake_cpu_quantity":"5.0000 EOS","transfer":false},"authorization":[{"actor":"eosio","permission":"active"}]}]}' ;

# Activate Sig EM Key Type "feature_digest": "03d8a26c72bd89ce9c2217c4d6eebe893100f9bc6b8baf14b577137785894e10"
cleos -u https://66ee-172-109-209-165.ngrok-free.app push action eosio activate '["03d8a26c72bd89ce9c2217c4d6eebe893100f9bc6b8baf14b577137785894e10"]' -p eosio