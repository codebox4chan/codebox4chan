#!/bin/bash

# Default encryption key
DEFAULT_KEY="your_default_key"

# XOR encryption function
xor_encrypt() {
    plaintext="$1"
    key="$2"
    encrypted=""

    for ((i = 0; i < ${#plaintext}; i++)); do
        char="${plaintext:$i:1}"
        keychar="${key:$(($i % ${#key})):1}"
        encrypted+=`printf "%x" $((0x$char ^ 0x$keychar))`
    done

    echo "$encrypted"
}

# Encrypt script using AES-256-CBC and then base64 encode
encrypt_script() {
    input_file="$1"
    key="$2"
    iterations="$3"

    script_content=$(<"$input_file")

    for ((i = 0; i < iterations; i++)); do
        script_content=$(echo -n "$script_content" | base64)
    done

    aes_encrypted_content=$(echo -n "$script_content" | openssl enc -aes-256-cbc -a -k "$key")
    base64_encoded_content=$(echo -n "$aes_encrypted_content" | base64)

    echo "$base64_encoded_content"
}

# Decrypt and execute the script
decrypt_and_execute() {
    encoded_content="$1"
    key="$2"
    iterations="$3"

    base64_decoded_content=$(echo -n "$encoded_content" | base64 -d)

    for ((i = 0; i < iterations; i++)); do
        base64_decoded_content=$(echo -n "$base64_decoded_content" | base64 -d)
    done

    aes_decrypted_content=$(echo -n "$base64_decoded_content" | openssl enc -aes-256-cbc -a -d -k "$key")
    decrypted_content=$(xor_encrypt "$aes_decrypted_content" "$key")

    echo "$decrypted_content" | bash
}

# Usage information
usage() {
    echo "Usage: $0 -f <input_file> [-k <encryption_key>] [-n <iterations>]"
    echo "Options:"
    echo "  -f <input_file>       Input Bash script file to obfuscate"
    echo "  -k <encryption_key>   Optional, encryption key (default is '$DEFAULT_KEY')"
    echo "  -n <iterations>       Optional, num of times for base64 encoding (default is 1)"
    exit 1
}

# Default values
key="$DEFAULT_KEY"
iterations=1

# Main execution
while getopts ":f:k:n:" opt; do
    case $opt in
        f)
            input_file="$OPTARG"
            ;;
        k)
            key="$OPTARG"
            ;;
        n)
            iterations="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

if [ -z "$input_file" ]; then
    echo "Input file not specified."
    usage
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    encrypted_script=$(encrypt_script "$input_file" "$key" "$iterations")
    decrypt_and_execute "$encrypted_script" "$key" "$iterations"
fi
