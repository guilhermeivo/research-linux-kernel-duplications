void init_v12(kgd_dev *adev)
{
    WREG32(mmIH_CNTL, 0);
    WREG32(mmIH_RB_CNTL, 1);

    WREG32(mmIH_SIZE, 4096);

    WREG32(mmIH_DOORBELL, 0);

    enable_interrupts(adev);
}
