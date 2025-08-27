# ============ ШАГ 1: СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ ============

# Настройки пользователя
username = "user"
password = "root"

print("Creating User and Setting it up...")

# Создаём пользователя
!sudo useradd -m $username &> /dev/null

# Добавляем пользователя в группу sudo
!sudo adduser $username sudo &> /dev/null

# Устанавливаем пароль
!echo '$username:$password' | sudo chpasswd

# Меняем оболочку на bash
!sed -i 's|/bin/sh|/bin/bash|g' /etc/passwd

print("User Created and Configured Successfully!\n")

# ============ ШАГ 2: УСТАНОВКА CHROME REMOTE DESKTOP ============

import os
import subprocess

# === ПОЛЬЗОВАТЕЛЬСКИЕ НАСТРОЙКИ ===
print("Now, configure your RDP settings below:")
CRP = "DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0AVMBsJjUi-tdzPjnrXqOAyUsMovf1kGfz0-P_fFyjqBuzJGQCm72gnntQlDi8LqHsiZJxw" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)"  # ← ВСТАВЬТЕ ССЫЛКУ ИЗ remotedesktop.google.com/headless
Pin = 123456  # ← УКАЖИТЕ ПИН (не менее 6 цифр)
Autostart = False  # ← True, если нужно автозапускать Colab

class CRD:
    @staticmethod
    def installCRD():
        print("📥 Installing Chrome Remote Desktop...")
        subprocess.run(['wget', 'https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb'], stdout=subprocess.PIPE)
        subprocess.run(['dpkg', '--install', 'chrome-remote-desktop_current_amd64.deb'], stdout=subprocess.PIPE)
        subprocess.run(['apt', 'install', '--assume-yes', '--fix-broken'], stdout=subprocess.PIPE)

    @staticmethod
    def installDesktopEnvironment():
        print("🎨 Installing Desktop Environment (XFCE)...")
        os.system("export DEBIAN_FRONTEND=noninteractive")
        os.system("apt install --assume-yes xfce4 desktop-base xfce4-terminal")
        os.system("bash -c 'echo \"exec /etc/X11/Xsession /usr/bin/xfce4-session\" > /etc/chrome-remote-desktop-session'")
        os.system("apt remove --assume-yes gnome-terminal")
        os.system("apt install --assume-yes xscreensaver")
        os.system("systemctl disable lightdm.service")

    @staticmethod
    def installGoogleChrome():
        print("📦 Installing Google Chrome...")
        subprocess.run(["wget", "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"], stdout=subprocess.PIPE)
        subprocess.run(["dpkg", "--install", "google-chrome-stable_current_amd64.deb"], stdout=subprocess.PIPE)
        subprocess.run(['apt', 'install', '--assume-yes', '--fix-broken'], stdout=subprocess.PIPE)

    @staticmethod
    def finish(user):
        print("🔧 Finalizing setup...")
        
        # Добавляем пользователя в группу chrome-remote-desktop
        os.system(f"adduser {user} chrome-remote-desktop")

        # Автозапуск Colab (опционально)
        if Autostart:
            os.makedirs(f"/home/{user}/.config/autostart", exist_ok=True)
            link = "https://colab.research.google.com/github/PradyumnaKrishna/Colab-Hacks/blob/master/Colab%20RDP/Colab%20RDP.ipynb"
            colab_autostart = f"""[Desktop Entry]
Type=Application
Name=Colab
Exec=sh -c "sensible-browser {link}"
Icon=
Comment=Open a predefined notebook at session signin.
X-GNOME-Autostart-enabled=true"""
            with open(f"/home/{user}/.config/autostart/colab.desktop", "w") as f:
                f.write(colab_autostart)
            os.system(f"chmod +x /home/{user}/.config/autostart/colab.desktop")
            os.system(f"chown {user}:{user} /home/{user}/.config")

        # Запуск команды RDP
        command = f"{CRP} --pin={Pin}"
        os.system(f"su - {user} -c '{command}'")
        os.system("service chrome-remote-desktop start")
        print("\n✅ RDP Setup Complete!")
        print("🟢 Now go to: https://remotedesktop.google.com/access")

# === ЗАПУСК УСТАНОВКИ ===
try:
    if CRP == "":
        print("❌ Error: Please enter the CRP command from https://remotedesktop.google.com/headless")
    elif len(str(Pin)) < 6:
        print("❌ Error: PIN must be at least 6 digits")
    else:
        CRD.installCRD()
        CRD.installDesktopEnvironment()
        CRD.installGoogleChrome()
        CRD.finish(username)
except Exception as e:
    print(f"❌ Setup failed: {e}")