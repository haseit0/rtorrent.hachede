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
  "+HacheDe" (Version 1.0):
  
  Este Script ha sido realizado para la autoinstalacion de rtorrent + rutorrent
  en distribuciones Debian. Se ha desarrollado unicamente para ser usado por
  usuarios de HacheDe.me si estas interesado en usarlo en otro sitio ponte en
  contacto conmigo <EMAIL>.
  
  Script desarrollado y probado en Debian 7 OS.
  
    * Haseito
  ----------------------------------------------------------------------------"
echo
echo
echo "Estas usando una distribucion Debian? Si no es asi cancela el proceso o continua bajo tu propio riesgo."
echo 
echo
read -p "Presiona [Enter] para continuar..." -n 1
echo
echo

#[PASO1] Menu Instalacion

cont = 0
while [$cont -eq 0]
	echo
	echo "Selecciona una de las dos opciones siguientes:"
	echo 
	echo "[1] - Crear un nuevo usuario en el sistema (ejemplo: seed)"
	echo "[2] - Usar un usuario ya existente (no es valido usar root como usuario)"
	echo
	echo -n "Introduce tu opcion: "
	echo
	read -e opcion

	if [$opcion -eq 1]; then
		echo -n "Introduce un nombre de usuario: "
		read -e user
		echo -n "Introduce una contraseña para $user: "
		read -e password
		
		useradd "$user"
		passwd "$password"
		
		cont = 1

	elif [$opcion -eq 2]; then
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

			elif [ $user == root ]; then
				echo
				echo "No puedes usar 'root' como usuario!"
			else
				const=1
				cont=1
			fi
		done

	else
		echo "No has seleccionado una opcion correcta"
		cont = 0
	fi
		
done
