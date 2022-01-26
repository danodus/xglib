
void main(void)
{
    for (int i = 0; i < 32; i++)
        *((volatile unsigned int *)1024) = i;
}
