#!/bin/bash

# Welcome message
echo "Hi User, Thanks for Using This Script!"
echo "(Automated Script By discord @Notlol95)"
echo ""

# Prompt for key
read -p "Please enter a valid key: " key

if [ "$key" != "crashcloud95" ]; then
    echo "Invalid key! Exiting..."
    exit 1
fi

echo "Key verified successfully!"
echo ""

read -p "Enter PASSWORD: " password
echo "PASSWORD: $password"
read -p "Type (y/n) to confirm: " confirm

if [ "$confirm" != "y" ]; then
    echo "Installation aborted!"
    exit 1
fi
