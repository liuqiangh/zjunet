# ZJU Network Scripts
## Reference and Original Project
Gist from DreaminginCodeZH: [ZJU Network Configuration from Zhang Hai](https://gist.github.com/DreaminginCodeZH/59c3a9a8d781639472e3ad6998b903c4)  
Scripts from DreaminginCodeZH [zju-net-utils](https://github.com/DreaminginCodeZH/zju-net-utils)

## VPN
You could use the following command to install zjuvpn.
```shell
cd vpn
bash setup.sh
```
After successful installed, you could just connent to zjuvpn with
```shell
zjuvpn
```
Note that the setup script will install *xl2tpd* and it will change or create the configuration files in the following:
```
1. /etc/ppp/chap-secrets
2. /etc/ppp/peers/zjuvpn.l2tpd
3. /etc/xl2tpd/xl2tpd.conf
```
If you have same files, please backup them or modified those files manually.

## IN DEVELOPING
// This repository could not be used yet
VPN in testing.
WLAN in developing(could not be used yet)
