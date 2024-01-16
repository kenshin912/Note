# Install Powerline and Configure it for Bash and VIM on Ubuntu 22.04

## Step 1 , Install Powerline on Ubuntu 22.04

```bash
sudo apt update -y

sudo add-apt-repository universe

sudo apt install powerline -y

```

## Step 2 , Configure Powerline for Bash Shell

At this point , to configure Powerline for the Bash shell , you need to edit the `bashrc` file.

```bash
sudo vim ~/.bashrc
```

Add the following code to the file

```bash
# Powerline configuration
if [ -f /usr/share/powerline/bindings/bash/powerline.sh ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  source /usr/share/powerline/bindings/bash/powerline.sh
fi

```

when you are done. save and close the file.

To apply the changes , run the following command.

```bash
sudo source ~/.bashrc
```

## Step 3. Configure Powerline for VIM

Open your vimrc file via vim

```bash
sudo vim ~/.vimrc
```

Add the following code to your file.

```vim
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

set laststatus=2
```

save and quit the file. then you are done.
