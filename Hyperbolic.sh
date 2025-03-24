#!/bin/bash

# Warna teks baru
ORANGE='\033[0;38;5;208m'  # Oranye terang
LIME='\033[0;38;5;154m'    # Hijau limau
TEAL='\033[0;38;5;37m'     # Biru kehijauan
MAGENTA='\033[0;95m'       # Magenta terang
GRAY='\033[0;90m'          # Abu-abu
WHITE='\033[0;97m'         # Putih cerah
NC='\033[0m'               # Reset warna

# Pengecekan dan instalasi curl
echo -e "${TEAL}>>> Memeriksa dependensi awal...${NC}"
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${ORANGE}>>> Curl tidak ditemukan, memasang...${NC}"
    sudo apt update
    sudo apt install -y curl
fi

# Menampilkan logo
echo -e "${TEAL}>>> Menampilkan logo...${NC}"
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash || {
    echo -e "${ORANGE}>>> Gagal memuat logo, tetap lanjut...${NC}"
}
sleep 5

# Pilihan mode
echo -e "${MAGENTA}=== Pilih mode instalasi Hyperbolic Bot ===${NC}"
echo -e "${TEAL}1) Mode Python${NC}"
echo -e "${TEAL}2) Mode JavaScript${NC}"
echo -e "${WHITE}>>> Masukkan pilihan (1 atau 2):${NC}"
read -r MODE

if [ "$MODE" != "1" ] && [ "$MODE" != "2" ]; then
    echo -e "${ORANGE}>>> Pilihan tidak valid, harus 1 atau 2${NC}"
    exit 1
fi

# Instalasi bot
echo -e "${MAGENTA}=== Memulai instalasi Hyperbolic Bot ===${NC}"

# 1. Pembaruan sistem dan instalasi paket
echo -e "${LIME}>>> Memperbarui sistem dan memasang paket...${NC}"
sudo apt update && sudo apt upgrade -y
if [ "$MODE" == "1" ]; then
    sudo apt install -y python3 python3-venv python3-pip curl
elif [ "$MODE" == "2" ]; then
    sudo apt install -y nodejs npm curl
fi

# 2. Membuat direktori proyek
PROJECT_DIR="$HOME/hyperbolic"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${ORANGE}>>> Direktori $PROJECT_DIR sudah ada, dibersihkan...${NC}"
    rm -rf "$PROJECT_DIR"
fi
mkdir -p "$PROJECT_DIR" || {
    echo -e "${ORANGE}>>> Gagal membuat direktori $PROJECT_DIR${NC}"
    exit 1
}
cd "$PROJECT_DIR" || {
    echo -e "${ORANGE}>>> Gagal masuk ke $PROJECT_DIR${NC}"
    exit 1
}

# 3. Mengatur lingkungan berdasarkan mode
if [ "$MODE" == "1" ]; then
    echo -e "${LIME}>>> Membuat lingkungan virtual Python...${NC}"
    python3 -m venv venv || {
        echo -e "${ORANGE}>>> Gagal membuat lingkungan virtual${NC}"
        exit 1
    }
    source venv/bin/activate
    pip install --upgrade pip
    pip install requests
    deactivate
elif [ "$MODE" == "2" ]; then
    echo -e "${LIME}>>> Memastikan Node.js siap...${NC}"
    npm init -y >/dev/null 2>&1
    npm install axios >/dev/null 2>&1 || {
        echo -e "${ORANGE}>>> Gagal memasang dependensi Node.js${NC}"
        exit 1
    }
fi

# 4. Mengunduh file bot berdasarkan mode
if [ "$MODE" == "1" ]; then
    BOT_URL="https://raw.githubusercontent.com/choir94/Hyperbolic/refs/heads/main/hyper_bot.py"
    echo -e "${LIME}>>> Mengunduh hyper_bot.py...${NC}"
    curl -fsSL -o hyper_bot.py "$BOT_URL" || {
        echo -e "${ORANGE}>>> Gagal mengunduh hyper_bot.py${NC}"
        exit 1
    }
elif [ "$MODE" == "2" ]; then
    BOT_URL="https://raw.githubusercontent.com/choir94/Hyperbolic/refs/heads/main/hyper_bot.js"
    echo -e "${LIME}>>> Mengunduh hyper_bot.js...${NC}"
    curl -fsSL -o hyper_bot.js "$BOT_URL" || {
        echo -e "${ORANGE}>>> Gagal mengunduh hyper_bot.js${NC}"
        exit 1
    }
fi

# 5. Meminta dan mengganti API key
echo -e "${WHITE}>>> Masukkan kunci API Hyperbolic Anda:${NC}"
read -r USER_API_KEY
if [ -z "$USER_API_KEY" ]; then
    echo -e "${ORANGE}>>> Kunci API tidak boleh kosong${NC}"
    exit 1
fi
if [ "$MODE" == "1" ]; then
    sed -i "s/HYPERBOLIC_API_KEY = \"\$API_KEY\"/HYPERBOLIC_API_KEY = \"$USER_API_KEY\"/" hyper_bot.py || {
        echo -e "${ORANGE}>>> Gagal mengganti kunci API${NC}"
        exit 1
    }
elif [ "$MODE" == "2" ]; then
    sed -i "s/HYPERBOLIC_API_KEY = \"\$API_KEY\"/HYPERBOLIC_API_KEY = \"$USER_API_KEY\"/" hyper_bot.js || {
        echo -e "${ORANGE}>>> Gagal mengganti kunci API${NC}"
        exit 1
    }
fi

# 6. Mengunduh file questions.txt
QUESTIONS_URL="https://raw.githubusercontent.com/choir94/Hyperbolic/refs/heads/main/question.txt"
echo -e "${LIME}>>> Mengunduh question.txt...${NC}"
curl -fsSL -o questions.txt "$QUESTIONS_URL" || {
    echo -e "${ORANGE}>>> Gagal mengunduh question.txt${NC}"
    exit 1
}

# 7. Membuat layanan systemd berdasarkan mode
USERNAME=$(whoami)
HOME_DIR=$(eval echo ~"$USERNAME")
SERVICE_FILE="/etc/systemd/system/hyper-bot.service"

echo -e "${LIME}>>> Mengatur layanan systemd...${NC}"
if [ "$MODE" == "1" ]; then
    sudo bash -c "cat <<EOT > $SERVICE_FILE
[Unit]
Description=Hyperbolic API Bot Service (Python)
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/hyperbolic
ExecStart=$HOME_DIR/hyperbolic/venv/bin/python $HOME_DIR/hyperbolic/hyper_bot.py
Restart=always
Environment=PATH=$HOME_DIR/hyperbolic/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT" || {
        echo -e "${ORANGE}>>> Gagal membuat layanan systemd${NC}"
        exit 1
    }
elif [ "$MODE" == "2" ]; then
    sudo bash -c "cat <<EOT > $SERVICE_FILE
[Unit]
Description=Hyperbolic API Bot Service (JavaScript)
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/hyperbolic
ExecStart=/usr/bin/node $HOME_DIR/hyperbolic/hyper_bot.js
Restart=always
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT" || {
        echo -e "${ORANGE}>>> Gagal membuat layanan systemd${NC}"
        exit 1
    }
fi

# 8. Mengatur dan menjalankan layanan
echo -e "${LIME}>>> Menjalankan layanan Hyperbolic Bot...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable hyper-bot.service
sudo systemctl start hyper-bot.service || {
    echo -e "${ORANGE}>>> Gagal memulai layanan${NC}"
    exit 1
}

# Pesan penutup
echo -e "${MAGENTA}========================================${NC}"
echo -e "${WHITE}>>> Instalasi selesai!${NC}"
echo -e "${GRAY}>>> Cek log: sudo journalctl -u hyper-bot.service -f${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e "${LIME}>>> Script by Airdrop Node${NC}"
echo -e "${TEAL}>>> Telegram: https://t.me/airdrop_node${NC}"
