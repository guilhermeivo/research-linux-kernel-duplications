void init_v11(kgd_dev *kgd)
{
    WREG32(mmIH_CNTL, 0);
    WREG32(mmIH_RB_CNTL, 1);
    WREG32(mmIH_DOORBELL, 0);

    enable_interrupts(kgd);
}
