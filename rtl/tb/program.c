
void main(void)
{
    unsigned int counter = 0;
    for (;;) {
        *((volatile unsigned int *)(4*1024)) = counter >> 20;
        counter++;
    }
}
