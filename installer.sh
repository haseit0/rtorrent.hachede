#--------------------------------------------------------
#libtorrent version
libtorrent_url="http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.4.tar.gz"
libtorrent_file="libtorrent-0.13.4.tar.gz"
libtorrent_folder="libtorrent-0.13.4"
#rtorrent version
rtorrent_url="http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.4.tar.gz"
rtorrent_file="rtorrent-0.9.4.tar.gz"
rtorrent_folder="rtorrent-0.9.4"
#rutorrent version
rutorrent_url="https://bintray.com/artifact/download/novik65/generic/rutorrent-3.6.tar.gz"
rutorrent_file="rutorrent-3.6.tar.gz"
#rutorrent plugins version
plugins_url="http://dl.bintray.com/novik65/generic/plugins-3.6.tar.gz"
plugins_file="plugins-3.6.tar.gz"

#!/bin/bash
clear

#Comprobacion que el usuario es root

if [ "$(id -u)" != "0" ]; then
	echo
	echo "Este Script ha de ser ejecutado como root." 1>&2
	echo
	exit 1
fi

# Intro

echo "  ----------------------------------------------------------------------------
  "+*****" (Version 1.0):
  
  Este Script ha sido realizado para la autoinstalacion de rtorrent + rutorrent
  en distribuciones Debian. Se ha desarrollado unicamente para ser usado por
  usuarios de *****.me si estas interesado en usarlo en otro sitio ponte en
  contacto conmigo <EMAIL>.
  
  Script desarrollado y probado en Debian 7 OS.
  
    * ******
  ----------------------------------------------------------------------------"
echo
echo
echo "Estas usando una distribucion Debian? Si no es asi cancela el proceso o continua bajo tu propio riesgo."
echo 
echo
read -p "Presiona [Enter] para continuar..." -n 1
echo
echo

clear

#[PASO1] Menu Instalacion, creacion de usuario y directorio principal

con=0
while [ $con -eq 0 ]; do
	echo
	echo "Selecciona una de las dos opciones siguientes:"
	echo 
	echo "[1] - Crear un nuevo usuario en el sistema (ejemplo: seed)"
	echo "[2] - Usar un usuario ya existente (no es valido usar root como usuario)"
	echo
	echo -n "Introduce tu opcion: "
	read -e opcion

	if [ $opcion -eq 1 ]; then
		echo -n "Introduce un nombre de usuario: "
		read -e user
		useradd "$user"
		echo -n "Introduce una contraseña para $user -> "
		passwd "$user"
		
		con=1

	elif [ $opcion -eq 2 ]; then
		const=0
		while [ $const -eq 0 ]; do
			echo -n "Introduce un nombre de usuario valido: "
			read -e user
			uid=$(cat /etc/passwd | grep "$user": | cut -d: -f3)

			if [ -z $(cat /etc/passwd | grep "$user":) ]; then
				echo
				echo "El usuario no existe"

			elif [ $uid -lt 999 ]; then
				echo
				echo "El usuario tiene un identificador (UID) demasiado corto "

			elif [ $user == nobody ]; then
				echo
				echo "No puedes usar 'nobody' como usuario!"
			else
				const=1
				con=1
			fi
		done

	else
		clear
		echo "No has seleccionado una opcion correcta"
		con=0
		
	fi
		
done

homedir=$(cat /etc/passwd | grep "$user": | cut -d: -f6)


#[PASO2] Actualizando e instalando dependencias

apt-get update
apt-get install openssl git subversion apache2 apache2-utils build-essential libsigc++-2.0-dev libcurl4-openssl-dev automake libtool libcppunit-dev libncurses5-dev libapache2-mod-scgi php5 php5-curl php5-cli libapache2-mod-php5 screen unrar-free unzip


#[PASO3] Instalando XMLRPC

svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c
cd xmlrpc-c
./configure --disable-cplusplus
make
make install
cd ..
rm -rv xmlrpc-c

mkdir rtorrent
cd rtorrent


#[PASO4] Instalando libtorrent http://libtorrent.rakshasa.no/

wget "$libtorrent_url"
tar -zxvf "$libtorrent_file"
cd "$libtorrent_folder"
./autogen.sh
./configure
make
make install
cd ..

#[PASO5] Instalando rtorrent http://libtorrent.rakshasa.no/

wget "$rtorrent_url"
tar -zxvf "$rtorrent_file"
cd "$rtorrent_folder"
./autogen.sh
./configure --with-xmlrpc-c
make
make install
cd ../..
rm -rv rtorrent

ldconfig


#[PASO6] Creando directorios del rtorrent

if [ ! -d "$homedir"/.rtorrent-session ]; then
	mkdir "$homedir"/.rtorrent-session
	chown "$user"."$user" "$homedir"/.rtorrent-session
else
	chown "$user"."$user" "$homedir"/.rtorrent-session
fi


#[PASO7] Creando la carpeta de descargas

if [ ! -d "$homedir"/Descargas ]; then
	mkdir "$homedir"/Descargas
	chown "$user"."$user" "$homedir"/Descargas
else
	chown "$user"."$user" "$homedir"/Descargas
fi


#[PASO8] Bajando el archivo de configuracion rtorrent.rc

wget -O $homedir/.rtorrent.rc https://raw.githubusercontent.com/haseit0/rtorrent.hachede/master/files/rtorrent.rc

chown "$user"."$user" $homedir/.rtorrent.rc

sed -i "s@HOMEDIRHERE@$homedir@g" $homedir/.rtorrent.rc


#[PASO10] Creamos symlink para scgi.load

if [ ! -h /etc/apache2/mods-enabled/scgi.load ]; then
	ln -s /etc/apache2/mods-available/scgi.load /etc/apache2/mods-enabled/scgi.load
fi


#[PASO11] Instalando rutorrent https://github.com/Novik/ruTorrent

wget "$rutorrent_url"
tar -zxvf "$rutorrent_file"

if [ -d /var/www/rutorrent ]; then
	rm -r /var/www/rutorrent
fi

mv -f rutorrent /var/www/
rm -v "$rutorrent_file"


#[PASO12] Instalando Plugins de rutorrent

wget "$plugins_url"
tar -xvzf "$plugins_file"
cp -R plugins /var/www/rutorrent/
rm -rf /var/www/rutorrent/plugins/darkpal
chown -R www-data:www-data /var/www/rutorrent
chmod -R 775 /var/www/rutorrent
apt-get install mediainfo
apt-get install ffmpeg

#[PASO13] Creando un host virtual de apache

if [ ! -f /etc/apache2/sites-available/rutorrent ]; then

cat > /etc/apache2/sites-available/rutorrent << EOF
<VirtualHost *:80>

	ServerName *
	ServerAlias *

	DocumentRoot /var/www/

	CustomLog /var/log/apache2/rutorrent.log vhost_combined

	ErrorLog /var/log/apache2/rutorrent_error.log

	SCGIMount /RPC2 127.0.0.1:5000

	<location /RPC2>
		AuthName "Seedbox"
		AuthType Basic
		Require Valid-User
		AuthUserFile /var/www/rutorrent/.htpasswd
	</location>
</VirtualHost>
EOF

	a2ensite rutorrent
fi

#[PASO14] Configurando la interfaz web

clear
echo -n "Introduce un nombre de usuario para conectarte a rutorrent (no ha de ser el usuario del sistema): "
read -e htauser

while true; do
	htpasswd -c /var/www/rutorrent/.htpasswd "$htauser"
	if [ $? = 0 ]; then
		break
	fi
done


#[PASO15] Instalando el script de autoarranque de rtorrent

wget -O /etc/init.d/rtorrent-init https://raw.githubusercontent.com/haseit0/rtorrent.hachede/master/files/rtorrent-init

chmod +x /etc/init.d/rtorrent-init

sed -i "s/USERNAMEHERE/$user/g" /etc/init.d/rtorrent-init

update-rc.d rtorrent-init defaults

service apache2 restart

clear
echo -e "Instalacion Completada"
echo

service rtorrent-init start

echo
echo -e "Tus descargas se guardaran en el directorio 'DDescargas', La sesion de los torrents en '.rtorrent-session' y
el archivo de configuracion es '.rtorrent.rc', todo lo puedes encontrar en el directorio /home/$user"
echo
tput sgr0
echo

if [ -z "$(ip addr | grep eth0)" ]; then
	echo "Para entrar en rutorrent a traves del navegador visita el siguiente enlace -> http://IP.ADDRESS/rutorrent"
else
	ip=$(ip addr | grep eth0 | grep inet | awk '{print $2}' | cut -d/ -f1)
	echo "Para entrar en rutorrent a traves del navegador visita el siguiente enlace -> http://$ip/rutorrent"
fi
echo
echo -e "by Haseito [2015]"
