void reset_device(void)
{

    /* Reset hardware */
    write_reg(CTRL, 0);

    enable_device();
}
