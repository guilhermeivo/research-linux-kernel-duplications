int sum_vector(int *d, int l)
{
    int total = 0;

    for (int j = 0; j < l; j++)
        total += d[j];

    return total;
}
