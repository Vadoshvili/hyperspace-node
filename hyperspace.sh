channel_logo() { 
  echo -e "\n\nПодпишись https://t.me/teapot_crypto"
}

download_node() {
  echo 'Начинаю установку...'

  read -p "Введите ваш приватный ключ: " PRIVATE_KEY
  echo "$PRIVATE_KEY" > $HOME/my.pem

  session="hyperspacenode"

  cd $HOME

  sudo apt-get update -y && sudo apt-get upgrade -y
  sudo apt-get install wget make tar screen nano build-essential unzip lz4 gcc git jq -y

  if [ -d "$HOME/.aios" ]; then
    sudo rm -rf "$HOME/.aios"
    aios-cli kill
  fi
  
  if screen -list | grep -q "\.${session}\b"; then
    screen -S hyperspacenode -X quit
  else
    echo "Сессия ${session} не найдена."
  fi

  while true; do
    curl -s https://download.hyper.space/api/install | bash | tee $HOME/hyperspacenode_install.log

    if ! grep -q "Failed to parse version from release data." $HOME/hyperspacenode_install.log; then
        echo "Клиент-скрипт был установлен."
        break
    else
        echo "Сервер установки клиента недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacenode_install.log

  export PATH=$PATH:$HOME/.aios
  source ~/.bashrc

  eval "$(cat ~/.bashrc | tail -n +10)"

  screen -dmS hyperspacenode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"
    aios-cli start
    exec bash
  '

  while true; do
    aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee $HOME/hyperspacemodel_download.log

    if grep -q "Download complete" $HOME/hyperspacemodel_download.log; then
        echo "Модель была установлена."
        break
    else
        echo "Сервер установки модели недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacemodel_download.log

  aios-cli hive import-keys $HOME/my.pem
  aios-cli hive login
  aios-cli hive connect
}
