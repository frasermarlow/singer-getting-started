# Setting up Ubuntu for Singer.io taps and targets
# updated 2020-11-30  |  fraser marlow

sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y
sudo apt install git -y
sudo apt-get install cron -y
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl
sudo apt-get install -y python3-dev libssl-dev
pip install --upgrade pip
sudo apt install -y pylint
python3 --version
# returns 'Python 3.6.9'

curl https://pyenv.run | bash

echo '' >> ~/.bashrc
echo 'export PATH="/home/ubuntu/.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
exec "$SHELL"

pyenv install --list | grep " 3\.[5]"
pyenv install 3.5.3
pyenv versions

python3 -m pip install pipx 
pipx ensurepath
# pipx install tap-autopilot (or whatever tap or target you like)
