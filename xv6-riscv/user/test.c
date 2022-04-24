// #include "kernel/param.h"
// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "user/user.h"
// #include "kernel/fs.h"
// #include "kernel/fcntl.h"
// #include "kernel/syscall.h"
// #include "kernel/memlayout.h"
// #include "kernel/riscv.h"

// void pause_system_dem(int interval, int pause_seconds, int loop_size) {
//     int pid = getpid();
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("pause system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             pause_system(pause_seconds);
//         }
//     }
//     printf("\n");
// }

// void kill_system_dem(int interval, int loop_size) {
//     int pid = getpid();
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("kill system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             kill_system();
//         }
//     }
//     printf("\n");
// }


// void set_economic_mode_dem(int interval, int loop_size) {
//     int pid = getpid();
//     // set_economic_mode(1);
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("set economic mode %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             // set_economic_mode(0);
//         }
//     }
//     printf("\n");
// }

// int
// main(int argc, char *argv[])
// {
//    // set_economic_mode_dem(10, 100);
//     // pause_system_dem(10, 10, 100);
//     // kill_system_dem(10, 100);
//     print_stats();
//     exit(0);
// }

#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

// void env(int size, int interval, char* env_name) {
//     int pid;
//     int result = 1;
//     int loop_size = (10e6);
//     int n_forks = 2;
//     for (int i = 0; i < n_forks; i++) {
//         pid = fork();
//     }
//     for (int i = 0; i < loop_size; i++) {
//         if (i % (int)(loop_size / 10e0) == 0) {
//             if (pid == 0) {
//                 printf("%s %d/%d completed.\n", env_name, i, loop_size);
//             } else {
//                 printf(" ");
//             }
//         }
//         if (i % interval == 0) {
//             result = result * size;
//         }
//     }
//     printf("\n");
// }

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

// void env_large() {
//     env(10e6, 10e6, "env_large");
// }

// void env_freq() {
//     env(10e1, 10e1, "env_freq");
// }

int
main(int argc, char *argv[])
{
    env_large();
    // env_freq();
    print_stats();
    exit(0);
}
