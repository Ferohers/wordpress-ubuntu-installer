#!/bin/bash

# Admin miyiz ?
if [[ $EUID -ne 0 ]]; then
    echo "sudo yazmayi mi unuttun admin gibi gorunmuyorsun"
    exit 1
fi

# Variables configurables
read -p "Veritabani ismi ne olayacak: " DB_NAME
read -p "E kullanici ismi ne olacak: " DB_USER
read -sp "Olusturdugun veritabani sifresi ne olsun " DB_PASSWORD
echo
read -p "hangi domaine kuruyon: " SITE_DOMAIN

# Update olmadan kurulum sakincali
echo "Sistem paketleri guncelleniyor..."
apt update && apt upgrade -y

# Apache yuklemesi
echo "Apache yukleniyor..."
apt install apache2 -y
systemctl start apache2
systemctl enable apache2

# PHP ve ilgili moduller
echo "PHP ve modulleri yukleniyor..."
apt install php php-mysql php-xml php-curl php-mbstring php-zip php-gd libapache2-mod-php -y

# MySQL Yuklemesi
echo "MySQL yukleniyor..."
apt install mysql-server -y

# MySQL Duzenlemesi
echo "Database ayarlamalari yapiliyor..."
mysql -u root <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "Veritabani surada hazir: $DB_NAME"
echo "Kullanici: $DB_USER"

# Wordpress once yuklet sonra gumlet
echo "WordPress Yukleniyor..."
wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xvzf /tmp/latest.tar.gz -C /tmp
mv /tmp/wordpress /var/www/html/

# Wordpress icin izinler ve ayarlamalar
echo "izinler duzenleniyor..."
chown -R www-data:www-data /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# Apache ayarları
echo "Apache duzenleniyor..."
cat <<EOL > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerAdmin admin@$SITE_DOMAIN
    DocumentRoot /var/www/html/wordpress
    ServerName $SITE_DOMAIN
    <Directory /var/www/html/wordpress>
        AllowOverride All
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

a2ensite wordpress
a2enmod rewrite
systemctl restart apache2

# SSL ayarlari (isteniyor ise lutfen tirnak isaretlerini kaldirin)
#read -p "Do you want to install SSL for your domain? (Y/N): " SSL_CHOICE
#if [[ "$SSL_CHOICE" == "y" ]]; then
#    apt install certbot python3-certbot-apache -y
#    certbot --apache -d $SITE_DOMAIN
#fi

# Olan bitenin raporu
echo "Yukleme bitti. Site http://$SITE_DOMAIN WordPress ile hizmete hazir."
echo "veritabani bilgileri:"
echo "  Veritabani ismi: $DB_NAME"
echo "  Kullanici: $DB_USER"
echo "  Sifre: $DB_PASSWORD"
