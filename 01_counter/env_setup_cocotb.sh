env_setup_cocotb() {
    python3 -m venv ~/.venv
    ~/.venv/bin/pip install cocotb cocotb-tools pyyaml
    source ~/.venv/bin/activate
    echo "Done — venv is now active."
}

env_setup_cocotb
