# Создание нового юзера

## 1. User
```bash
sudo adduser [user_name]
sudo gpasswd -d [user_name] sudo  # ensure no sudo
```

## 2. Team group & dirs
```bash
sudo usermod -aG [group_name] [user_name]
```

———————

## *3 Стажерский аккаунт
Теперь у стажеров будет root-less docker. Как его поставить:
1) Зайти к стажеру в акк по ssh (это важно)
2) Ввести это в bashrc:
```bash
echo 'export PATH=/usr/bin:$PATH' >> ~/.bashrc
echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock' >> ~/.bashrc
source ~/.bashrc
```
3) Поставить докер (там будет ошибка, надо внимательно прочитать и запустить команду под рутом):
```bash
curl -fsSL https://get.docker.com/rootless | sh
```
4) Запустить демона (про эту команду стоить рассказать стажеру)
```bash
~/bin/dockerd-rootless.sh &
```
5) Проверить, что докер работает:
```bash
docker run --rm hello-world
```
6) Ещё есть команда, чтобы демон докера автозапускался:
```bash
sudo loginctl enable-linger имя_пользователя
```

7) Если нужен доступ из докера для общих папок:
Сначала попробуйте указать следующее в `docker-compose.yaml` или при запуске контейнер:
```yaml
group_add:
   - GID # надо заменить GID под вашу группу
```

Если не заработало, то надо сделать следующее:
```bash
sudo setfacl -R -m u:имя_пользователя:rX путь_до_папки
sudo setfacl -R -d -m u:имя_пользователя:rX путь_до_папки
```

8) Если нужна nvidia, то вот [инструкция](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html). Так следующее:
```bash
nvidia-ctk runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json
systemctl --user restart docker
sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
```