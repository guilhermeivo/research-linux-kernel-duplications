void init_device(void)
{
  const int v[] = {1, 2, 3};

  for (int i = 0; i < 3; i++)
    write_reg(REG_A + i, v[i]);
}
