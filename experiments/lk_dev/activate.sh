#!/usr/bin/env bash
set -euo pipefail

# colors
GREEN="\e[32m"
PINK="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

export KERNEL_TAG="${BOLD}[KERNEL]${RESET}"
export ERROR_TAG="${BOLD}[ERROR]${RESET}"
export IGT_TAG="${BOLD}[IGT GPU TOOLS]${RESET}"

trap 'echo -e "${ERROR_TAG} failed at line $LINENO" >&2' ERR

VERSION=1.0.0

# environment variables
export LK_DEV_DIR="/home/lk_dev" # path to testing environment directory

## Linux kernel tree build variables
export ARCH="arm64" # variable defining target architecture
export CROSS_COMPILE="aarch64-linux-gnu-"

export CCACHE_DIR="${LK_DEV_DIR}/.cache/cache"
mkdir -p "${CCACHE_DIR}"

export IGT_ROOT="${LK_DEV_DIR}/igt-gpu-tools"
export IGT_DRIVERS=amdgpu

export LOGS_DIR="${LK_DEV_DIR}/.logs"
mkdir -p "${LOGS_DIR}"

export SASHIKO_DIR="${LK_DEV_DIR}/sashiko"
export PATH="${SASHIKO_DIR}/target/release:$PATH"

export BUILD_DIR="build_dir"

deps=(kw cargo make python3 ccache clang systemctl)

for d in "${deps[@]}"; do
    command -v "$d" >/dev/null 2>&1 || {
        echo -e "${ERROR_TAG} missing dependency: $d"
        exit 1
    }
done

function enable-gui() {
    echo "Starting GDM and unmasking sleep/hibernate targets..."
    sudo systemctl start gdm
    sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
}
export -f enable-gui

function disable-sleep() {
    sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    setterm -blank 0
    setterm -powerdown 0
}
export -f disable-sleep

## worflow

function make-kernel() {
    SECONDS=0
    M=""

    if [ -z "$M" ]; then
        echo -e "${KERNEL_TAG} Starting to compile the Linux kernel"
    else
        echo -e "${KERNEL_TAG} Starting to compile the Linux kernel in ${M}"
    fi
    sleep 1

    [ ! -f Makefile ] && {
        echo -e "${KERNEL_TAG} Run this inside the Linux kernel tree"
        return 1
    }

    [ ! -f .kw ] && {
        echo -e "${KERNEL_TAG} kw ..."
        kw init

        kw config build.arch "${ARCH}"
        kw config build.cross_compile "${CROSS_COMPILE}"
        kw config build.kernel_img_name "Image.gz"
    }

    if [ -z "$M" ]; then
        # gerar o arquivo .config
        echo -e "${KERNEL_TAG} make olddefconfig ..."
        KBUILD_BUILD_TIMESTAMP='' make \
            W=1 LLVM=1 O="${BUILD_DIR}" ARCH="${ARCH}" CC="ccache clang" \
            olddefconfig > "${LOGS_DIR}/make__olddefconfig"
    else
        echo -e "${KERNEL_TAG} make scripts ..."
        KBUILD_BUILD_TIMESTAMP='' make \
            W=1 LLVM=1 O="${BUILD_DIR}" ARCH="${ARCH}" CC="ccache clang" \
            scripts > "${LOGS_DIR}/make__scripts"
    fi

    echo -e "${KERNEL_TAG} make ..."
    KBUILD_BUILD_TIMESTAMP='' make \
        M="${M}" \
        W=1 LLVM=1 O="${BUILD_DIR}" ARCH="${ARCH}" CC="ccache clang" \
        -j$(nproc) KCFLAGS="-Winvalid-pch" > "${LOGS_DIR}/make__j"

    if [ -z "$M" ]; then
        echo -e "${KERNEL_TAG} python3 gen_compile_commands.py"
        python3 scripts/clang-tools/gen_compile_commands.py \
            -d "${BUILD_DIR}" > "${LOGS_DIR}/gen_compile_commands"
    fi

    cd "${SASHIKO_DIR}" || return 1
    cargo build --release --bin sashiko-cli || return 1
    cargo build --release --bin sashiko || return 1
    cd "${LK_DEV_DIR}"

    # sashiko \
        # > "${LOGS_DIR}/daemon.log" 2>&1 &

    # PID=$!
    # echo "${PID}" > "${LOGS_DIR}/daemon.pid"

    echo -e "${KERNEL_TAG} Change informations in: sashiko/Settings.toml"
    echo -e "${KERNEL_TAG} Use the command: export LLM_API_KEY={LLM_API_KEY}"
    echo -e "${KERNEL_TAG} and use the command: sashiko-cli submit HEAD~{n}..HEAD"

    echo -e "${KERNEL_TAG} Execution time: $SECONDS seconds"

    return 0
}
export -f make-kernel

## ----------------------------------

# prompt preamble
prompt_preamble='(LK-DEV)'

function title() {
    local c="\e[32m"
    local r="\e[0m"
    # Text Font: ANSI Shadow (modify)
    echo -e "
┌──                                               ──┐
│                                                   │
    Welcome to
    $c██$r┐     $c██$r┐  $c██$r┐     $c██████$r┐ $c███████$r┐$c██$r┐   $c██$r┐
    $c██$r│     $c██$r│ $c██$r┌┘     $c██$r┌──$c██$r┐$c██$r┌────┘$c██$r│   $c██$r│
    $c██$r│     $c█████$r┌┘$c█████$r┐$c██$r│  $c██$r│$c█████$r┐  $c██$r│   $c██$r│
    $c██$r│     $c██$r┌─$c██$r┐└────┘$c██$r│  $c██$r│$c██$r┌──┘  └$c██$r┐ $c██$r┌┘
    $c███████$r┐$c██$r│  $c██$r┐     $c██████$r┌┘$c███████$r┐ └$c████$r┌┘ 
    └──────┘└─┘  └─┘     └─────┘ └──────┘  └───┘  
│                       $CROSS_COMPILE$ARCH     │
└──                                               ──┘
    " 
}

title
echo -e "${GREEN}Entering shell session for Linux Kernel Dev${RESET}"

if systemctl -q is-active gdm; then
    echo -e "${IGT_TAG} ${PINK}Warning${RESET}
It is necessary to stop the GNOME Display Manager (GDM):
\tsudo systemctl stop gdm"
    echo -e "Press Ctrl+Alt+F3 to access TTY3 and continue.\n"
else
    echo -e "${IGT_TAG} You are now in safe TTY. To run all tests, use:\n"
    echo -e "\tsudo ./scripts/run_tests.sh\n"
fi

echo -e "${GREEN}To exit, type 'exit' or press Ctrl+D.${RESET}"
exec bash --rcfile <(cat <<EOF
source ~/.bashrc
disable-sleep
PS1="\[${BOLD}\]\[${PINK}\]${prompt_preamble}\[${RESET}\] \$PS1"
EOF
)

# scripts/config --enable DRM
# scripts/config --enable DRM_AMDGPU
# scripts/config --enable DEBUG_KERNEL
# scripts/config --enable KUNIT