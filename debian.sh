#!/bin/bash

VERSION=$(grep "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
SOURCES_LIST="/etc/apt/sources.list"

# Debian sürümüne göre kaynak listelerini ekle
if [ "$VERSION" == "11" ]; then
    echo "Debian 11 (Bullseye) tespit edildi. sources.list güncelleniyor."
    cat <<EOF > $SOURCES_LIST
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
EOF
elif [ "$VERSION" == "12" ]; then
    echo "Debian 12 (Bookworm) tespit edildi. sources.list güncelleniyor."
    cat <<EOF > $SOURCES_LIST
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
else
    echo "Desteklenmeyen Debian sürümü: $VERSION"
    exit 1
fi

# Eski Docker paketlerini kaldır
echo "Eski Docker paketleri kaldırılıyor..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove -y $pkg
done

# Sistem güncelleniyor ve gerekli paketler kuruluyor
echo "Sistem güncelleniyor ve gerekli paketler kuruluyor..."
apt-get update
apt-get install -y ca-certificates curl hardening-runtime

# Docker GPG anahtarını indir ve ekle
echo "Docker GPG anahtarı indiriliyor..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker deposunu ekle
echo "Docker deposu sources.list.d dizinine ekleniyor..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Sistem tam olarak yükseltiliyor
echo "Sistem full-upgrade yapılıyor..."
apt-get update
apt-get full-upgrade -y

# Gereksiz paketler kaldırılıyor
echo "Gereksiz paketler kaldırılıyor..."
apt-get autoremove -y

# Docker ve ilgili paketler kuruluyor
echo "Docker kuruluyor..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Fit2Cloud 1Panel kurulumu başlatılıyor
echo "Fit2Cloud 1Panel kurulumu başlatılıyor..."
curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh

echo "Kurulum tamamlandı."