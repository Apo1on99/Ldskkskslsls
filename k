#!/bin/bash
# Скрипт установки Hikka для локального запуска и деплоя на Heroku
# Поддерживает установку нескольких юзер-ботов с разными именами.
# Использование:
#   ./install.sh <имя_бота>
# Если имя не указано, используется "ubalala" по умолчанию

# Имя юзер-бота (например, для тестового — ubalala)
USERBOT_NAME=${1:-ubalala}

# Получаем текущую рабочую директорию (абсолютный путь)
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

printf "\n\e[1;35;47m                   \e[0m\n"
printf "\e[1;35;47m █ █ █ █▄▀ █▄▀ ▄▀█ \e[0m\n"
printf "\e[1;35;47m █▀█ █ █ █ █ █ █▀█ \e[0m\n"
printf "\e[1;35;47m                   \e[0m\n"
printf "\n\e[3;34;40m Installing...\e[0m\n\n"

##############################################################################
printf "\r\033[0;34mPreparing for installation...\e[0m"

# Если скрипт уже запускался ранее (файл .setup_complete существует)
if [ -f ".setup_complete" ]; then
    PYVER="3"
    printf "\rExisting installation detected. Hikka is already installed.\n"
fi

echo "Preparing installation for userbot: ${USERBOT_NAME}" >"${WORKING_DIR}/hikka-install.log"

PYVER="3"  # Используем python3

##############################################################################
printf "\r\033[K\033[0;32mPreparation complete!\e[0m"
printf "\n\r\033[0;34mCloning repo...\e[0m"

# Клонируем репозиторий в отдельную папку для данного бота
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
printf "\n\r\033[0;34mCreating config.json...\e[0m"

# Создаём файл config.json в папке с ботом
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
# Не создаём systemd unit-файл – запуск будем осуществлять вручную.
printf "\n\033[0;32mHikka installation complete for userbot '${USERBOT_NAME}'!\e[0m"
printf "\nTo start the bot, execute the following commands:\n"
printf "cd %s/Heroku_%s\n" "$WORKING_DIR" "$USERBOT_NAME"
printf "python%s -m hikka\n\n" "$PYVER"
