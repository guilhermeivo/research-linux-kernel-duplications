int sum_array(int *v, int s)
{
    int sum = 0;

    for (int i = 0; i < s; i++)
        sum += v[i];

    return sum;
}
