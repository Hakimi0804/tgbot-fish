FROM fedora:latest

# Install packages
RUN dnf install -y python3-devel jq aria2 pv openssl neofetch curl-devel glib-devel openssl-devel python3 curl bash which zip git nano file glib2
RUN dnf install -y make g++ wget asciidoc
RUN dnf install -y coreutils
RUN dnf install -y dnf-plugins-core
RUN dnf -y copr enable ignatenkobrain/fish
RUN dnf install -y fish
RUN dnf install -y gh
RUN dnf install -y netcat
RUN dnf upgrade -y

# Use rpmfusion ffmpeg
RUN dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf clean all

# YTDL
RUN wget -c https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl && \
    chmod +x /usr/local/bin/youtube-dl

# Python
RUN python3 -m ensurepip \
    && pip3 install --upgrade pip setuptools \
    && pip3 install wheel telethon \
    && rm -rf /usr/lib/python*/ensurepip && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -rf /root/.cache

# PIP
RUN pip3 install speedtest-cli pycryptodome docopt
RUN pip3 install git+https://github.com/nlscc/samloader.git
RUN pip3 install --upgrade pycryptodome git+https://github.com/R0rt1z2/realme-ota
WORKDIR /app
RUN chmod 777 /app

# Copy all files to workdir
COPY . .
CMD ["fish","tgbot.fish"]
