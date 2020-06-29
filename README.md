# Mullvad server connection Randomizer

This is a tiny shell script that arbitrarily picks a Wireguard interface to connect to, drops the existing connection and connects to a new one.

## Why?
Though primarily written for Mullvad, should work with almost all wireguard interfaces with minor configurations. Mullvad offers around 176 servers via Wireguard and as a practice, I like to continuously rotate my connected servers every morning. The procedure doesn't take much time but automating via a crontab is a bliss.

## The Script
Mullvad wireguard configuration script saves the different Wireguard interfaces in `/etc/wireguard` with the nomenclature `mullvad-<server-name>.conf`.

The script picks the scripts that start with `mullvad-` and picks a random one to connect to. A complete guide on how to use it [located on my Blog](https://archern9.github.io/articles/2020/06/29/randomize-mullvad-interface-with-cron.html)

### MIT License