#!/usr/bin/env bash
cd /data/data/com.termux/files/home/dynu-environment
echo '[*] Packaging cluster state directly...'
tar -czf protein-engine-full-backup.tar.gz inventory/ workers/ termux/
echo '[*] Syncing directly via Termux network...'
rclone copy protein-engine-full-backup.tar.gz aws:nutgit-vault-178870258461-ap-southeast-7/protein-engine-cluster/ --progress
echo '[✓] Sync completed instantly!'
