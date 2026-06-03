# 🐧 Arch Linux — Guía de Instalación con Btrfs + Hyprland

Guía paso a paso para instalar Arch Linux con particionado **Btrfs**, subvolúmenes, **GRUB** en UEFI y **Hyprland** como entorno de escritorio.

---

## 📋 Índice

1. [Live environment](#1-live-environment)
2. [Particionar](#2-particionar-)
3. [Formatear y subvolúmenes](#3-formatear--subvolúmenes)
4. [Montar particiones](#4-montar-particiones)
5. [Instalar base (pacstrap)](#5-instalar-base-pacstrap)
6. [Generar fstab](#6-generar-fstab)
7. [Configurar en chroot](#7-configurar-en-chroot)
8. [GRUB](#8-grub)
9. [Servicios y reinicio](#9-servicios-y-reinicio)
10. [Post-instalación](#10-post-instalación)

---

## 1. Live environment

### Verificar modo UEFI

Si el comando lista archivos, estás en modo UEFI ✓. Si dice `No such file`, hay un problema con el arranque.

```bash
ls /sys/firmware/efi
```

### Conectar a internet

**Ethernet:** ya estás conectado automáticamente.

**WiFi:** ejecuta `iwctl` y luego los siguientes comandos dentro de él:

```bash
iwctl
station wlan0 connect TU-WIFI
exit
```

Verifica la conexión:

```bash
ping -c 3 archlinux.org
```

### Sincronizar reloj y confirmar disco

> [!NOTE]
> Confirma que `nvme0n1` es tu SSD. `sda` es la USB — **no la toques**.

```bash
timedatectl set-ntp true
lsblk
```

---

## 2. Particionar ⚠️

> [!WARNING]
> Este paso **borra datos**. Asegúrate de estar editando el disco correcto.

### Abrir cfdisk

Borra las 3 particiones existentes: selecciona cada una y pulsa **Delete**.

```bash
cfdisk /dev/nvme0n1
```

### Crear partición EFI (dentro de cfdisk)

```
Free space → New → 1G → Enter → Type → EFI System → Enter
```

### Crear partición principal y guardar

```
Free space → New → Enter (todo el espacio restante) → Linux filesystem
→ Write → yes → Quit
```

Verifica el resultado:

```bash
lsblk
```

---

## 3. Formatear + Subvolúmenes

### Formatear EFI como FAT32

```bash
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
```

### Formatear partición principal como Btrfs

```bash
mkfs.btrfs -f -L Arch /dev/nvme0n1p2
```

### Montar y crear los 3 subvolúmenes

| Subvolumen | Uso |
|---|---|
| `@` | Raíz del sistema |
| `@home` | Archivos personales |
| `@snapshots` | Respaldos automáticos con snapper |

```bash
mount /dev/nvme0n1p2 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots

btrfs subvolume list /mnt

umount /mnt
```

---

## 4. Montar particiones

### Montar `@` como raíz

```bash
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@ \
  /dev/nvme0n1p2 /mnt
```

### Crear puntos de montaje

```bash
mkdir -p /mnt/{boot,home,.snapshots}
```

### Montar EFI, `@home` y `@snapshots`

```bash
mount /dev/nvme0n1p1 /mnt/boot

mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home \
  /dev/nvme0n1p2 /mnt/home

mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@snapshots \
  /dev/nvme0n1p2 /mnt/.snapshots
```

### Verificar montajes

Debes ver `nvme0n1p1` en `/boot` y `nvme0n1p2` montado **3 veces**: en `/`, `/home` y `/.snapshots`.

```bash
lsblk -f
```

---

## 5. Instalar base (pacstrap)

### Verificar CPU para microcódigo

```bash
grep 'model name' /proc/cpuinfo | head -1
```

> [!TIP]
> **AMD** → usa `amd-ucode` · **Intel** → usa `intel-ucode`

### Instalar sistema base

> [!NOTE]
> Esto tarda varios minutos. Reemplaza `amd-ucode` por `intel-ucode` si tu CPU es Intel.

```bash
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware \
  btrfs-progs grub efibootmgr networkmanager sudo neovim git amd-ucode
```

---

## 6. Generar fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Verifica que el fstab es correcto. Deben aparecer **4 entradas**:
- `/` → `subvol=@`
- `/home` → `subvol=@home`
- `/.snapshots` → `subvol=@snapshots`
- `/boot` → FAT32

```bash
cat /mnt/etc/fstab
```

---

## 7. Configurar en chroot

> [!IMPORTANT]
> A partir de aquí estás **dentro** de Arch en tu disco.

```bash
arch-chroot /mnt
```

### Zona horaria

```bash
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
```

### Locale

```bash
sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

### Hostname

> [!TIP]
> Cambia `arch` por el nombre que quieras darle a tu PC.

```bash
echo 'arch' > /etc/hostname
```

### Agregar Btrfs a mkinitcpio y regenerar

Necesario para que el kernel pueda arrancar desde Btrfs.

```bash
sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P
```

### Contraseña de root

> [!CAUTION]
> No la olvides — es para emergencias.

```bash
passwd
```

### Crear tu usuario

> [!TIP]
> Reemplaza `usoj` con tu nombre de usuario.

```bash
useradd -m -G wheel -s /bin/bash usoj
passwd usoj
```

### Habilitar sudo para el grupo wheel

```bash
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
```

---

## 8. GRUB

### Instalar GRUB en la partición EFI

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
```

### Generar configuración de GRUB

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 9. Servicios y reinicio

### Habilitar NetworkManager

```bash
systemctl enable NetworkManager
```

### Salir del chroot y desmontar todo

```bash
exit
umount -R /mnt
```

### Reiniciar

> [!WARNING]
> Saca la USB cuando empiece a reiniciar.

```bash
reboot
```

---

## 10. Post-instalación

### Iniciar sesión

Inicia sesión con el **usuario que creaste** (no con root).

### Conectar a internet

```bash
nmtui
```

Navega a `Activate a connection` → selecciona tu WiFi → ingresa la contraseña.

### Habilitar repositorio multilib

```bash
sudo nvim /etc/pacman.conf
```

Busca y descomenta estas dos líneas (quita el `#`):

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Guarda y sal (`:wq`), luego sincroniza:

```bash
sudo pacman -Sy
```

### Instalar entorno completo (Hyprland, SDDM, dotfiles...)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/diazhdez/arch-hyprland-setup/main/hyprland.sh)
```

---
