#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"


void pause_system_dem(int interval, int pause_seconds, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            pause_system(pause_seconds);
        }
    }
    printf("\n");
}

void kill_system_dem(int interval, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            kill_system();
        }
    }
    printf("\n");
}

void env_large(){

    int pid;
    int status;

    for (int i=0; i<4; i++) {
        if ((pid = fork()) == 0) {
            for (int i = 0; i <= 10000000; i++){
                if (i % 10000 == 0){
                    printf("%d", i);
                }
            }
            exit(0);
        }
    }

    while (wait(&status) > 0);
}   


int
main(int argc, char *argv[])
{ 
    env_large();
    print_stats();
    pause_system_dem(10, 10, 100);
    kill_system_dem(10, 100);
    exit(0);
}
