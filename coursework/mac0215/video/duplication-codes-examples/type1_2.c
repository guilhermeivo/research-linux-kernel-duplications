void reset_device(void) {
    write_reg(CTRL, 0);
    enable_device();
}
