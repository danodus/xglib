
#define DISPLAY         0x00001000
#define UART_DATA       0x00002000
#define UART_STATUS     0x00002004

#define REG_WRITE(_reg_, _value_) (*((volatile unsigned int *)(_reg_)) = _value_)
#define REG_READ(_reg_)           (*((volatile unsigned int *)(_reg_)))

void main(void)
{
    unsigned int counter = 0;

    for (;;) {
        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'H');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'e');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'l');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'l');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'o');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, ',');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, ' ');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'w');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'o');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'r');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'l');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, 'd');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, '!');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, '\r');

        while(REG_READ(UART_STATUS) & 1);
        REG_WRITE(UART_DATA, '\n');

        REG_WRITE(DISPLAY, counter);
        counter++;
    }
}
