#!/bin/bash

VERSION=$(grep "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
SOURCES_LIST="/etc/apt/sources.list"

# Ubuntu sürümüne göre kaynak listelerini ekle
if [ "$VERSION" == "20.04" ]; then
    echo "Ubuntu 20.04 (Focal Fossa) tespit edildi. sources.list güncelleniyor."
    cat <<EOF > $SOURCES_LIST
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu focal-security main restricted universe multiverse
EOF
elif [ "$VERSION" == "22.04" ]; then
    echo "Ubuntu 22.04 (Jammy Jellyfish) tespit edildi. sources.list güncelleniyor."
    cat <<EOF > $SOURCES_LIST
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF
else
    echo "Desteklenmeyen Ubuntu sürümü: $VERSION"
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
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker deposunu ekle
echo "Docker deposu sources.list.d dizinine ekleniyor..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
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