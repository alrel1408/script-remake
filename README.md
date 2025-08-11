# 🚀 AlrelShop VPN Script Remake with API Integration

<p align="center">
<img src="https://readme-typing-svg.herokuapp.com?color=%2336BCF7&center=true&vCenter=true&lines=ALRELSHOP+VPN+SCRIPT+REMAKE;WITH+API+INTEGRATION;AUTO+VPN+MANAGEMENT" />
</p>

## 📋 Deskripsi

Ini adalah remake dari script VPN AlrelShop yang sudah diintegrasikan dengan API server untuk memudahkan pengelolaan akun VPN melalui panel web. Sekarang Anda tidak perlu lagi login ke VPS untuk membuat, memperpanjang, atau menghapus akun VPN!

## ✨ Fitur Utama

### 🔥 Fitur Baru (Remake)
- **API Server Terintegrasi** - Kelola akun VPN melalui REST API
- **Web Panel Modern** - Interface web yang cantik dan responsif
- **Auto Account Management** - Buat, perpanjang, dan hapus akun otomatis
- **Real-time Status** - Monitor status server secara real-time
- **Easy Integration** - Mudah diintegrasikan dengan panel hosting/web

### 📡 Protokol VPN yang Didukung
- **SSH/OpenVPN** ✅
- **Trojan-WS** ✅  
- **V2Ray/VMess** ✅
- **VLESS** ✅
- **Shadowsocks** ✅

### 🛠 Fitur Teknis
- Quota Management (per akun)
- IP Limit Control
- Auto Delete Expired
- Account Backup & Restore
- Bot Telegram Integration
- Bandwidth Monitoring

## 🚀 Quick Install

### Install Script VPN + API
```bash
apt update -y && apt upgrade -y && wget -q https://raw.githubusercontent.com/alrel1408/script-remake/main/install/install.sh && chmod +x install.sh && ./install.sh
```

### Setelah Instalasi
1. **Upload Web Panel** - Upload file `web/index.html` ke hosting Anda
2. **Get API Info** - Jalankan command `requestapi` di VPS untuk mendapatkan API Key
3. **Konfigurasi Panel** - Masukkan API URL dan Key di web panel
4. **Mulai Kelola VPN** - Sekarang Anda bisa membuat akun dari web!

## 🌐 Web Panel Setup

### 1. Upload File Web
Upload file `web/index.html` ke hosting/panel web Anda

### 2. Konfigurasi API
Setelah install, jalankan di VPS:
```bash
requestapi
```

Salin API Key dan URL yang ditampilkan

### 3. Akses Web Panel
Buka web panel dan masukkan:
- **Server URL**: `http://IP-VPS:5000`
- **API Key**: Key yang didapat dari command `requestapi`

## 📱 API Endpoints

### SSH Management
```bash
# Membuat akun SSH
POST /api/ssh/create
{
    "username": "testuser",
    "duration": 30,
    "quota": 9999,
    "ip_limit": 2
}

# Perpanjang akun SSH  
POST /api/ssh/renew
{
    "username": "testuser",
    "duration": 30
}

# Hapus akun SSH
POST /api/ssh/delete
{
    "username": "testuser"
}

# List akun SSH
GET /api/ssh/list
```

### Trojan Management
```bash
# Membuat akun Trojan
POST /api/trojan/create
{
    "username": "testuser",
    "duration": 30,
    "quota": 9999,
    "ip_limit": 2
}
```

## 🔧 Command Line Usage

### Membuat Akun (Terminal)
```bash
# SSH
addssh

# Trojan  
addtr

# Perpanjang SSH
renewssh
```

### Management Commands
```bash
# Lihat info API
requestapi

# Restart API server
systemctl restart vpn-api

# Cek status API
systemctl status vpn-api
```

## 📊 Monitoring & Logs

### Cek Status Services
```bash
# Status API Server
systemctl status vpn-api

# Log API Server
tail -f /var/log/vpn-api.log

# Test API Connection
curl -H "X-API-Key: YOUR_API_KEY" http://localhost:5000
```

## 🔒 Security Features

- **API Key Authentication** - Semua request butuh API key yang valid
- **Rate Limiting** - Mencegah spam request
- **Input Validation** - Validasi semua input user
- **Secure Headers** - CORS dan security headers
- **Encrypted Storage** - Data akun disimpan dengan aman

## 🌍 Supported OS

### ✅ Ubuntu
- Ubuntu 18.04 LTS
- Ubuntu 20.04 LTS  
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

### ✅ Debian
- Debian 9 (Stretch)
- Debian 10 (Buster)
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

## 📋 Port Information
```
- SSH WS/TLS         : 443
- SSH Non-TLS        : 8880, 80
- SSH UDP            : 1-65535
- Trojan WS          : 443
- Trojan GRPC        : 443
- V2Ray WS           : 443
- V2Ray GRPC         : 443
- VLESS WS           : 443
- VLESS GRPC         : 443
- Shadowsocks WS     : 443
- OpenVPN SSL/TCP    : 1194
- Squid Proxy        : 3128
- API Server         : 5000
```

## 🔧 Troubleshooting

### API Server Tidak Jalan
```bash
# Restart service
systemctl restart vpn-api

# Cek error log
journalctl -u vpn-api -f

# Manual start untuk debug
cd /opt/vpn-api
source venv/bin/activate
python app.py
```

### Web Panel Tidak Konek
1. Pastikan port 5000 terbuka di firewall
2. Cek API key sudah benar
3. Pastikan format URL benar: `http://IP:5000`

### Command Tidak Ditemukan
```bash
# Re-create symlinks
ln -sf /usr/local/bin/addssh /usr/bin/addssh
ln -sf /usr/local/bin/requestapi /usr/bin/requestapi
```

## 🆕 Update Script

### Auto Update
```bash
# Download update script
wget -q https://raw.githubusercontent.com/alrel1408/script-remake/main/update.sh && chmod +x update.sh && ./update.sh
```

### Manual Update API
```bash
cd /opt/vpn-api
git pull origin main
systemctl restart vpn-api
```

## 🤝 Contributing

Kami menerima kontribusi! Silakan:

1. Fork repository ini
2. Buat branch feature (`git checkout -b feature/amazing-feature`)  
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push ke branch (`git push origin feature/amazing-feature`)
5. Buat Pull Request

## 📞 Support & Contact

### 🆘 Need Help?
- **Telegram**: [@alrelshop](https://t.me/alrelshop)
- **GitHub Issues**: [Create Issue](https://github.com/alrel1408/script-remake/issues)
- **Email**: support@alrelshop.com

### 💬 Community
- **Telegram Group**: [AlrelShop Community](https://t.me/alrelshop_community)
- **Discord**: [Join Discord](https://discord.gg/alrelshop)

## 📜 License

Script ini dibuat oleh **AlrelShop** dan dilindungi hak cipta. 

⚠️ **DILARANG KERAS**:
- Menjual script ini
- Mengklaim sebagai karya sendiri  
- Menghapus credit/watermark
- Modifikasi untuk tujuan komersial tanpa izin

✅ **DIPERBOLEHKAN**:
- Penggunaan pribadi
- Modifikasi untuk kebutuhan sendiri
- Kontribusi improvement
- Sharing dengan tetap mencantumkan credit

## 🏆 Credits

**Developer**: AlrelShop࿐®  
**Version**: 2.0 (API Remake Edition)  
**Year**: 2024  

---

<p align="center">
<b>⭐ Jangan lupa berikan star jika script ini membantu! ⭐</b>
</p>

<p align="center">
Made with ❤️ by <a href="https://github.com/alrel1408">AlrelShop</a>
</p>

# script-remake
