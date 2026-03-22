#include <stdint.h>
#include <sys/random.h>

uint32_t lwip_port_rand(void) {
    uint32_t r;
    getrandom(&r, sizeof(r), 0);
    return r;
}
