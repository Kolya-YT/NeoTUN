#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>

uint32_t lwip_port_rand(void) {
    uint32_t r = 0;
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        read(fd, &r, sizeof(r));
        close(fd);
    }
    return r;
}
