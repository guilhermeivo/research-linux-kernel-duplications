ARG DISTRO=ubuntu
ARG TAG=22.04
ARG REPO_URL=https://github.com/arkanjo-tool/arkanjo.git
ARG KERNEL_REPO_URL=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
ARG BRANCH=main
ARG KERNEL_BRANCH=master

FROM ${DISTRO}:${TAG} AS builder
ARG DISTRO
ARG TAG
ARG REPO_URL
ARG KERNEL_REPO_URL
ARG BRANCH
ARG KERNEL_BRANCH

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN set -eux; \
    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then \
        apt-get update && \
        apt-get install -y build-essential make g++ git python3 python3-venv python3-pip python3-dev && \
        rm -rf /var/lib/apt/lists/*; \
    fi

RUN set -eux; \
    if [ "$DISTRO" = "fedora" ]; then \
        dnf install -y gcc-c++ make git python3 python3-virtualenv python3-pip python3-devel && \
        dnf clean all; \
    fi

RUN set -eux; \
    if [ "$DISTRO" = "archlinux" ]; then \
        pacman -Syu --noconfirm && \
        pacman -S --noconfirm base-devel git python python-pip python-virtualenv pyenv && \
        export PYENV_ROOT="$HOME/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && \
        pyenv install 3.11.6; \
        pyenv global 3.11.6; \
        ln -sf $PYENV_ROOT/versions/3.11.6/bin/python /usr/bin/python3; \
    fi

RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir nltk gensim astor && \
    python -m nltk.downloader punkt && \
    python -c "import nltk; nltk.download('punkt_tab')"

ENV PATH="/opt/venv/bin:$PATH"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

ARG CACHEBUST=1
RUN git clone --branch $BRANCH --depth 1 $REPO_URL .
RUN make -j$(nproc) install
RUN rm -rf /app/*

CMD ["bash"]