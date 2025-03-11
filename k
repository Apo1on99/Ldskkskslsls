#!/bin/bash
# Скрипт установки Hikka для локального запуска и деплоя на Heroku
# Поддерживает установку нескольких юзер-ботов с разными именами.
# Использование:
#   ./install.sh <имя_бота>
# Если имя не указано, по умолчанию используется "ubalala"

# Получаем имя юзер-бота из аргументов (или по умолчанию)
USERBOT_NAME=${1:-ubalala}

# Получаем текущую рабочую директорию
WORKING_DIR=$(pwd)

# Функции логирования
runin() {
    { "$@" 2>>"${WORKING_DIR}/hikka-install.log" || return $?; } | while read -r line; do
        printf "%s\n" "$line" >>"${WORKING_DIR}/hikka-install.log"
    done
}
runout() {
    { "$@" 2>>"${WORKING_DIR}/hikka-install.log" || return $?; } | while read -r line; do
        printf "%s\n" "$line" >>"${WORKING_DIR}/hikka-install.log"
    done
}
errorin() {
    cat "${WORKING_DIR}/hikka-install.log"
}
errorout() {
    cat "${WORKING_DIR}/hikka-install.log"
}

##############################################################################
clear

printf "\n\e[1;35;47m                   \e[0m"
printf "\n\e[1;35;47m █ █ █ █▄▀ █▄▀ ▄▀█ \e[0m"
printf "\n\e[1;35;47m █▀█ █ █ █ █ █ █▀█ \e[0m"
printf "\n\e[1;35;47m                   \e[0m"
printf "\n\n\e[3;34;40m Installing...\e[0m\n\n"

##############################################################################
printf "\r\033[0;34mPreparing for installation...\e[0m"

# Если скрипт уже запускался ранее
if [ -f ".setup_complete" ]; then
    PYVER="3"
    printf "\rExisting installation detected. Hikka is already installed.\n"
fi

echo "Preparing installation for userbot: ${USERBOT_NAME}" >"${WORKING_DIR}/hikka-install.log"

PYVER="3"  # Используем python3

##############################################################################
printf "\r\033[K\033[0;32mPreparation complete!\e[0m"
printf "\n\r\033[0;34mCloning repo...\e[0m"

# Удаляем старую версию для данного бота, если есть
rm -rf "${WORKING_DIR}/Heroku_${USERBOT_NAME}"
runout git clone https://github.com/coddrago/Heroku "${WORKING_DIR}/Heroku_${USERBOT_NAME}" || {
    errorout "Clone failed."
    exit 3
}

cd "${WORKING_DIR}/Heroku_${USERBOT_NAME}" || {
    printf "\r\033[0;33mPlease install git and restart installer\e[0m"
    exit 7
}

printf "\r\033[K\033[0;32mRepo cloned!\e[0m"

##############################################################################
# Если требуется переключиться на определённую версию или ветку, добавьте здесь нужные команды

##############################################################################
printf "\n\r\033[0;34mCreating config.json...\e[0m"

# Создаем файл config.json внутри папки с ботом
cat > "${WORKING_DIR}/Heroku_${USERBOT_NAME}/config.json" <<EOL
{
    "api_id": 7301124,
    "api_hash": "46eb50618e7a00ca8b165275d9e0fe0b",
    "app_name": "Discipulus Pietas Omnis",
    "userbot_name": "${USERBOT_NAME}"
}
EOL

printf "\r\033[K\033[0;32mconfig.json created!\e[0m"

##############################################################################
printf "\n\r\033[0;34mInstalling python dependencies...\e[0m"
runin python$PYVER -m pip install --upgrade -q --disable-pip-version-check --no-warn-script-location -r requirements.txt
runin python$PYVER -m pip install --upgrade pip setuptools wheel --user
runin python$PYVER -m pip install -r requirements.txt --upgrade --user --no-warn-script-location --disable-pip-version-check || {
    errorin "Requirements failed!"
    exit 4
}
runin python$PYVER -m pip install -U urllib3 requests

rm -f "${WORKING_DIR}/hikka-install.log"
touch "${WORKING_DIR}/.setup_complete"

##############################################################################
printf "\r\033[K\033[0;32mDependencies installed!\e[0m"

##############################################################################
# Создаем systemd unit file для данного юзер-бота с корректной рабочей директорией
SERVICE_FILE="/etc/systemd/system/${USERBOT_NAME}.service"
printf "\n\r\033[0;34mCreating systemd service file ${SERVICE_FILE}...\e[0m"

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Hikka userbot ${USERBOT_NAME}
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=${WORKING_DIR}/Heroku_${USERBOT_NAME}
ExecStart=/usr/bin/python3 -m hikka
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Перезагружаем systemd, включаем и запускаем сервис
systemctl daemon-reload
systemctl enable "${USERBOT_NAME}.service"
systemctl restart "${USERBOT_NAME}.service"

##############################################################################
printf "\r\033[K\033[0;32mService ${USERBOT_NAME} installed and started!\e[0m"
printf "\n\033[0;32mHikka installation complete for userbot '${USERBOT_NAME}'!\e[0m"
printf "\nTo check status: systemctl status ${USERBOT_NAME}.service\n\n"
