
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <pause_system_dem>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
  16:	8a2a                	mv	s4,a0
  18:	8b2e                	mv	s6,a1
  1a:	8932                	mv	s2,a2
    int pid = getpid();
  1c:	00000097          	auipc	ra,0x0
  20:	4bc080e7          	jalr	1212(ra) # 4d8 <getpid>
    for (int i = 0; i < loop_size; i++) {
  24:	05205b63          	blez	s2,7a <pause_system_dem+0x7a>
  28:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  2a:	01f9599b          	srliw	s3,s2,0x1f
  2e:	012989bb          	addw	s3,s3,s2
  32:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  36:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
  38:	00001b97          	auipc	s7,0x1
  3c:	950b8b93          	addi	s7,s7,-1712 # 988 <malloc+0xea>
  40:	a031                	j	4c <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
  42:	02998663          	beq	s3,s1,6e <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
  46:	2485                	addiw	s1,s1,1
  48:	02990963          	beq	s2,s1,7a <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
  4c:	0344e7bb          	remw	a5,s1,s4
  50:	fbed                	bnez	a5,42 <pause_system_dem+0x42>
  52:	00000097          	auipc	ra,0x0
  56:	486080e7          	jalr	1158(ra) # 4d8 <getpid>
  5a:	ff5514e3          	bne	a0,s5,42 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
  5e:	864a                	mv	a2,s2
  60:	85a6                	mv	a1,s1
  62:	855e                	mv	a0,s7
  64:	00000097          	auipc	ra,0x0
  68:	77c080e7          	jalr	1916(ra) # 7e0 <printf>
  6c:	bfd9                	j	42 <pause_system_dem+0x42>
            pause_system(pause_seconds);
  6e:	855a                	mv	a0,s6
  70:	00000097          	auipc	ra,0x0
  74:	490080e7          	jalr	1168(ra) # 500 <pause_system>
  78:	b7f9                	j	46 <pause_system_dem+0x46>
        }
    }
    printf("\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	92e50513          	addi	a0,a0,-1746 # 9a8 <malloc+0x10a>
  82:	00000097          	auipc	ra,0x0
  86:	75e080e7          	jalr	1886(ra) # 7e0 <printf>
}
  8a:	60a6                	ld	ra,72(sp)
  8c:	6406                	ld	s0,64(sp)
  8e:	74e2                	ld	s1,56(sp)
  90:	7942                	ld	s2,48(sp)
  92:	79a2                	ld	s3,40(sp)
  94:	7a02                	ld	s4,32(sp)
  96:	6ae2                	ld	s5,24(sp)
  98:	6b42                	ld	s6,16(sp)
  9a:	6ba2                	ld	s7,8(sp)
  9c:	6161                	addi	sp,sp,80
  9e:	8082                	ret

00000000000000a0 <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  a0:	7139                	addi	sp,sp,-64
  a2:	fc06                	sd	ra,56(sp)
  a4:	f822                	sd	s0,48(sp)
  a6:	f426                	sd	s1,40(sp)
  a8:	f04a                	sd	s2,32(sp)
  aa:	ec4e                	sd	s3,24(sp)
  ac:	e852                	sd	s4,16(sp)
  ae:	e456                	sd	s5,8(sp)
  b0:	e05a                	sd	s6,0(sp)
  b2:	0080                	addi	s0,sp,64
  b4:	8a2a                	mv	s4,a0
  b6:	892e                	mv	s2,a1
    int pid = getpid();
  b8:	00000097          	auipc	ra,0x0
  bc:	420080e7          	jalr	1056(ra) # 4d8 <getpid>
    for (int i = 0; i < loop_size; i++) {
  c0:	05205a63          	blez	s2,114 <kill_system_dem+0x74>
  c4:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  c6:	01f9599b          	srliw	s3,s2,0x1f
  ca:	012989bb          	addw	s3,s3,s2
  ce:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  d2:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  d4:	00001b17          	auipc	s6,0x1
  d8:	8dcb0b13          	addi	s6,s6,-1828 # 9b0 <malloc+0x112>
  dc:	a031                	j	e8 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  de:	02998663          	beq	s3,s1,10a <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  e2:	2485                	addiw	s1,s1,1
  e4:	02990863          	beq	s2,s1,114 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  e8:	0344e7bb          	remw	a5,s1,s4
  ec:	fbed                	bnez	a5,de <kill_system_dem+0x3e>
  ee:	00000097          	auipc	ra,0x0
  f2:	3ea080e7          	jalr	1002(ra) # 4d8 <getpid>
  f6:	ff5514e3          	bne	a0,s5,de <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  fa:	864a                	mv	a2,s2
  fc:	85a6                	mv	a1,s1
  fe:	855a                	mv	a0,s6
 100:	00000097          	auipc	ra,0x0
 104:	6e0080e7          	jalr	1760(ra) # 7e0 <printf>
 108:	bfd9                	j	de <kill_system_dem+0x3e>
            kill_system();
 10a:	00000097          	auipc	ra,0x0
 10e:	3ee080e7          	jalr	1006(ra) # 4f8 <kill_system>
 112:	bfc1                	j	e2 <kill_system_dem+0x42>
        }
    }
    printf("\n");
 114:	00001517          	auipc	a0,0x1
 118:	89450513          	addi	a0,a0,-1900 # 9a8 <malloc+0x10a>
 11c:	00000097          	auipc	ra,0x0
 120:	6c4080e7          	jalr	1732(ra) # 7e0 <printf>
}
 124:	70e2                	ld	ra,56(sp)
 126:	7442                	ld	s0,48(sp)
 128:	74a2                	ld	s1,40(sp)
 12a:	7902                	ld	s2,32(sp)
 12c:	69e2                	ld	s3,24(sp)
 12e:	6a42                	ld	s4,16(sp)
 130:	6aa2                	ld	s5,8(sp)
 132:	6b02                	ld	s6,0(sp)
 134:	6121                	addi	sp,sp,64
 136:	8082                	ret

0000000000000138 <set_economic_mode_dem>:


void set_economic_mode_dem(int interval, int loop_size) {
 138:	7139                	addi	sp,sp,-64
 13a:	fc06                	sd	ra,56(sp)
 13c:	f822                	sd	s0,48(sp)
 13e:	f426                	sd	s1,40(sp)
 140:	f04a                	sd	s2,32(sp)
 142:	ec4e                	sd	s3,24(sp)
 144:	e852                	sd	s4,16(sp)
 146:	e456                	sd	s5,8(sp)
 148:	0080                	addi	s0,sp,64
 14a:	89aa                	mv	s3,a0
 14c:	892e                	mv	s2,a1
    int pid = getpid();
 14e:	00000097          	auipc	ra,0x0
 152:	38a080e7          	jalr	906(ra) # 4d8 <getpid>
    // set_economic_mode(1);
    for (int i = 0; i < loop_size; i++) {
 156:	03205d63          	blez	s2,190 <set_economic_mode_dem+0x58>
 15a:	8a2a                	mv	s4,a0
 15c:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("set economic mode %d/%d completed.\n", i, loop_size);
 15e:	00001a97          	auipc	s5,0x1
 162:	872a8a93          	addi	s5,s5,-1934 # 9d0 <malloc+0x132>
 166:	a021                	j	16e <set_economic_mode_dem+0x36>
    for (int i = 0; i < loop_size; i++) {
 168:	2485                	addiw	s1,s1,1
 16a:	02990363          	beq	s2,s1,190 <set_economic_mode_dem+0x58>
        if (i % interval == 0 && pid == getpid()) {
 16e:	0334e7bb          	remw	a5,s1,s3
 172:	fbfd                	bnez	a5,168 <set_economic_mode_dem+0x30>
 174:	00000097          	auipc	ra,0x0
 178:	364080e7          	jalr	868(ra) # 4d8 <getpid>
 17c:	ff4516e3          	bne	a0,s4,168 <set_economic_mode_dem+0x30>
            printf("set economic mode %d/%d completed.\n", i, loop_size);
 180:	864a                	mv	a2,s2
 182:	85a6                	mv	a1,s1
 184:	8556                	mv	a0,s5
 186:	00000097          	auipc	ra,0x0
 18a:	65a080e7          	jalr	1626(ra) # 7e0 <printf>
 18e:	bfe9                	j	168 <set_economic_mode_dem+0x30>
        }
        if (i == loop_size / 2) {
            // set_economic_mode(0);
        }
    }
    printf("\n");
 190:	00001517          	auipc	a0,0x1
 194:	81850513          	addi	a0,a0,-2024 # 9a8 <malloc+0x10a>
 198:	00000097          	auipc	ra,0x0
 19c:	648080e7          	jalr	1608(ra) # 7e0 <printf>
}
 1a0:	70e2                	ld	ra,56(sp)
 1a2:	7442                	ld	s0,48(sp)
 1a4:	74a2                	ld	s1,40(sp)
 1a6:	7902                	ld	s2,32(sp)
 1a8:	69e2                	ld	s3,24(sp)
 1aa:	6a42                	ld	s4,16(sp)
 1ac:	6aa2                	ld	s5,8(sp)
 1ae:	6121                	addi	sp,sp,64
 1b0:	8082                	ret

00000000000001b2 <main>:

int
main(int argc, char *argv[])
{
 1b2:	1141                	addi	sp,sp,-16
 1b4:	e406                	sd	ra,8(sp)
 1b6:	e022                	sd	s0,0(sp)
 1b8:	0800                	addi	s0,sp,16
   // set_economic_mode_dem(10, 100);
    pause_system_dem(10, 10, 100);
 1ba:	06400613          	li	a2,100
 1be:	45a9                	li	a1,10
 1c0:	4529                	li	a0,10
 1c2:	00000097          	auipc	ra,0x0
 1c6:	e3e080e7          	jalr	-450(ra) # 0 <pause_system_dem>
    kill_system_dem(10, 100);
 1ca:	06400593          	li	a1,100
 1ce:	4529                	li	a0,10
 1d0:	00000097          	auipc	ra,0x0
 1d4:	ed0080e7          	jalr	-304(ra) # a0 <kill_system_dem>
    exit(0);
 1d8:	4501                	li	a0,0
 1da:	00000097          	auipc	ra,0x0
 1de:	27e080e7          	jalr	638(ra) # 458 <exit>

00000000000001e2 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1e2:	1141                	addi	sp,sp,-16
 1e4:	e422                	sd	s0,8(sp)
 1e6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1e8:	87aa                	mv	a5,a0
 1ea:	0585                	addi	a1,a1,1
 1ec:	0785                	addi	a5,a5,1
 1ee:	fff5c703          	lbu	a4,-1(a1)
 1f2:	fee78fa3          	sb	a4,-1(a5)
 1f6:	fb75                	bnez	a4,1ea <strcpy+0x8>
    ;
  return os;
}
 1f8:	6422                	ld	s0,8(sp)
 1fa:	0141                	addi	sp,sp,16
 1fc:	8082                	ret

00000000000001fe <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1fe:	1141                	addi	sp,sp,-16
 200:	e422                	sd	s0,8(sp)
 202:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 204:	00054783          	lbu	a5,0(a0)
 208:	cb91                	beqz	a5,21c <strcmp+0x1e>
 20a:	0005c703          	lbu	a4,0(a1)
 20e:	00f71763          	bne	a4,a5,21c <strcmp+0x1e>
    p++, q++;
 212:	0505                	addi	a0,a0,1
 214:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 216:	00054783          	lbu	a5,0(a0)
 21a:	fbe5                	bnez	a5,20a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 21c:	0005c503          	lbu	a0,0(a1)
}
 220:	40a7853b          	subw	a0,a5,a0
 224:	6422                	ld	s0,8(sp)
 226:	0141                	addi	sp,sp,16
 228:	8082                	ret

000000000000022a <strlen>:

uint
strlen(const char *s)
{
 22a:	1141                	addi	sp,sp,-16
 22c:	e422                	sd	s0,8(sp)
 22e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 230:	00054783          	lbu	a5,0(a0)
 234:	cf91                	beqz	a5,250 <strlen+0x26>
 236:	0505                	addi	a0,a0,1
 238:	87aa                	mv	a5,a0
 23a:	4685                	li	a3,1
 23c:	9e89                	subw	a3,a3,a0
 23e:	00f6853b          	addw	a0,a3,a5
 242:	0785                	addi	a5,a5,1
 244:	fff7c703          	lbu	a4,-1(a5)
 248:	fb7d                	bnez	a4,23e <strlen+0x14>
    ;
  return n;
}
 24a:	6422                	ld	s0,8(sp)
 24c:	0141                	addi	sp,sp,16
 24e:	8082                	ret
  for(n = 0; s[n]; n++)
 250:	4501                	li	a0,0
 252:	bfe5                	j	24a <strlen+0x20>

0000000000000254 <memset>:

void*
memset(void *dst, int c, uint n)
{
 254:	1141                	addi	sp,sp,-16
 256:	e422                	sd	s0,8(sp)
 258:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 25a:	ce09                	beqz	a2,274 <memset+0x20>
 25c:	87aa                	mv	a5,a0
 25e:	fff6071b          	addiw	a4,a2,-1
 262:	1702                	slli	a4,a4,0x20
 264:	9301                	srli	a4,a4,0x20
 266:	0705                	addi	a4,a4,1
 268:	972a                	add	a4,a4,a0
    cdst[i] = c;
 26a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 26e:	0785                	addi	a5,a5,1
 270:	fee79de3          	bne	a5,a4,26a <memset+0x16>
  }
  return dst;
}
 274:	6422                	ld	s0,8(sp)
 276:	0141                	addi	sp,sp,16
 278:	8082                	ret

000000000000027a <strchr>:

char*
strchr(const char *s, char c)
{
 27a:	1141                	addi	sp,sp,-16
 27c:	e422                	sd	s0,8(sp)
 27e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 280:	00054783          	lbu	a5,0(a0)
 284:	cb99                	beqz	a5,29a <strchr+0x20>
    if(*s == c)
 286:	00f58763          	beq	a1,a5,294 <strchr+0x1a>
  for(; *s; s++)
 28a:	0505                	addi	a0,a0,1
 28c:	00054783          	lbu	a5,0(a0)
 290:	fbfd                	bnez	a5,286 <strchr+0xc>
      return (char*)s;
  return 0;
 292:	4501                	li	a0,0
}
 294:	6422                	ld	s0,8(sp)
 296:	0141                	addi	sp,sp,16
 298:	8082                	ret
  return 0;
 29a:	4501                	li	a0,0
 29c:	bfe5                	j	294 <strchr+0x1a>

000000000000029e <gets>:

char*
gets(char *buf, int max)
{
 29e:	711d                	addi	sp,sp,-96
 2a0:	ec86                	sd	ra,88(sp)
 2a2:	e8a2                	sd	s0,80(sp)
 2a4:	e4a6                	sd	s1,72(sp)
 2a6:	e0ca                	sd	s2,64(sp)
 2a8:	fc4e                	sd	s3,56(sp)
 2aa:	f852                	sd	s4,48(sp)
 2ac:	f456                	sd	s5,40(sp)
 2ae:	f05a                	sd	s6,32(sp)
 2b0:	ec5e                	sd	s7,24(sp)
 2b2:	1080                	addi	s0,sp,96
 2b4:	8baa                	mv	s7,a0
 2b6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2b8:	892a                	mv	s2,a0
 2ba:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2bc:	4aa9                	li	s5,10
 2be:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2c0:	89a6                	mv	s3,s1
 2c2:	2485                	addiw	s1,s1,1
 2c4:	0344d863          	bge	s1,s4,2f4 <gets+0x56>
    cc = read(0, &c, 1);
 2c8:	4605                	li	a2,1
 2ca:	faf40593          	addi	a1,s0,-81
 2ce:	4501                	li	a0,0
 2d0:	00000097          	auipc	ra,0x0
 2d4:	1a0080e7          	jalr	416(ra) # 470 <read>
    if(cc < 1)
 2d8:	00a05e63          	blez	a0,2f4 <gets+0x56>
    buf[i++] = c;
 2dc:	faf44783          	lbu	a5,-81(s0)
 2e0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2e4:	01578763          	beq	a5,s5,2f2 <gets+0x54>
 2e8:	0905                	addi	s2,s2,1
 2ea:	fd679be3          	bne	a5,s6,2c0 <gets+0x22>
  for(i=0; i+1 < max; ){
 2ee:	89a6                	mv	s3,s1
 2f0:	a011                	j	2f4 <gets+0x56>
 2f2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2f4:	99de                	add	s3,s3,s7
 2f6:	00098023          	sb	zero,0(s3)
  return buf;
}
 2fa:	855e                	mv	a0,s7
 2fc:	60e6                	ld	ra,88(sp)
 2fe:	6446                	ld	s0,80(sp)
 300:	64a6                	ld	s1,72(sp)
 302:	6906                	ld	s2,64(sp)
 304:	79e2                	ld	s3,56(sp)
 306:	7a42                	ld	s4,48(sp)
 308:	7aa2                	ld	s5,40(sp)
 30a:	7b02                	ld	s6,32(sp)
 30c:	6be2                	ld	s7,24(sp)
 30e:	6125                	addi	sp,sp,96
 310:	8082                	ret

0000000000000312 <stat>:

int
stat(const char *n, struct stat *st)
{
 312:	1101                	addi	sp,sp,-32
 314:	ec06                	sd	ra,24(sp)
 316:	e822                	sd	s0,16(sp)
 318:	e426                	sd	s1,8(sp)
 31a:	e04a                	sd	s2,0(sp)
 31c:	1000                	addi	s0,sp,32
 31e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 320:	4581                	li	a1,0
 322:	00000097          	auipc	ra,0x0
 326:	176080e7          	jalr	374(ra) # 498 <open>
  if(fd < 0)
 32a:	02054563          	bltz	a0,354 <stat+0x42>
 32e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 330:	85ca                	mv	a1,s2
 332:	00000097          	auipc	ra,0x0
 336:	17e080e7          	jalr	382(ra) # 4b0 <fstat>
 33a:	892a                	mv	s2,a0
  close(fd);
 33c:	8526                	mv	a0,s1
 33e:	00000097          	auipc	ra,0x0
 342:	142080e7          	jalr	322(ra) # 480 <close>
  return r;
}
 346:	854a                	mv	a0,s2
 348:	60e2                	ld	ra,24(sp)
 34a:	6442                	ld	s0,16(sp)
 34c:	64a2                	ld	s1,8(sp)
 34e:	6902                	ld	s2,0(sp)
 350:	6105                	addi	sp,sp,32
 352:	8082                	ret
    return -1;
 354:	597d                	li	s2,-1
 356:	bfc5                	j	346 <stat+0x34>

0000000000000358 <atoi>:

int
atoi(const char *s)
{
 358:	1141                	addi	sp,sp,-16
 35a:	e422                	sd	s0,8(sp)
 35c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 35e:	00054603          	lbu	a2,0(a0)
 362:	fd06079b          	addiw	a5,a2,-48
 366:	0ff7f793          	andi	a5,a5,255
 36a:	4725                	li	a4,9
 36c:	02f76963          	bltu	a4,a5,39e <atoi+0x46>
 370:	86aa                	mv	a3,a0
  n = 0;
 372:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 374:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 376:	0685                	addi	a3,a3,1
 378:	0025179b          	slliw	a5,a0,0x2
 37c:	9fa9                	addw	a5,a5,a0
 37e:	0017979b          	slliw	a5,a5,0x1
 382:	9fb1                	addw	a5,a5,a2
 384:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 388:	0006c603          	lbu	a2,0(a3)
 38c:	fd06071b          	addiw	a4,a2,-48
 390:	0ff77713          	andi	a4,a4,255
 394:	fee5f1e3          	bgeu	a1,a4,376 <atoi+0x1e>
  return n;
}
 398:	6422                	ld	s0,8(sp)
 39a:	0141                	addi	sp,sp,16
 39c:	8082                	ret
  n = 0;
 39e:	4501                	li	a0,0
 3a0:	bfe5                	j	398 <atoi+0x40>

00000000000003a2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3a2:	1141                	addi	sp,sp,-16
 3a4:	e422                	sd	s0,8(sp)
 3a6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3a8:	02b57663          	bgeu	a0,a1,3d4 <memmove+0x32>
    while(n-- > 0)
 3ac:	02c05163          	blez	a2,3ce <memmove+0x2c>
 3b0:	fff6079b          	addiw	a5,a2,-1
 3b4:	1782                	slli	a5,a5,0x20
 3b6:	9381                	srli	a5,a5,0x20
 3b8:	0785                	addi	a5,a5,1
 3ba:	97aa                	add	a5,a5,a0
  dst = vdst;
 3bc:	872a                	mv	a4,a0
      *dst++ = *src++;
 3be:	0585                	addi	a1,a1,1
 3c0:	0705                	addi	a4,a4,1
 3c2:	fff5c683          	lbu	a3,-1(a1)
 3c6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3ca:	fee79ae3          	bne	a5,a4,3be <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3ce:	6422                	ld	s0,8(sp)
 3d0:	0141                	addi	sp,sp,16
 3d2:	8082                	ret
    dst += n;
 3d4:	00c50733          	add	a4,a0,a2
    src += n;
 3d8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3da:	fec05ae3          	blez	a2,3ce <memmove+0x2c>
 3de:	fff6079b          	addiw	a5,a2,-1
 3e2:	1782                	slli	a5,a5,0x20
 3e4:	9381                	srli	a5,a5,0x20
 3e6:	fff7c793          	not	a5,a5
 3ea:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3ec:	15fd                	addi	a1,a1,-1
 3ee:	177d                	addi	a4,a4,-1
 3f0:	0005c683          	lbu	a3,0(a1)
 3f4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3f8:	fee79ae3          	bne	a5,a4,3ec <memmove+0x4a>
 3fc:	bfc9                	j	3ce <memmove+0x2c>

00000000000003fe <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3fe:	1141                	addi	sp,sp,-16
 400:	e422                	sd	s0,8(sp)
 402:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 404:	ca05                	beqz	a2,434 <memcmp+0x36>
 406:	fff6069b          	addiw	a3,a2,-1
 40a:	1682                	slli	a3,a3,0x20
 40c:	9281                	srli	a3,a3,0x20
 40e:	0685                	addi	a3,a3,1
 410:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 412:	00054783          	lbu	a5,0(a0)
 416:	0005c703          	lbu	a4,0(a1)
 41a:	00e79863          	bne	a5,a4,42a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 41e:	0505                	addi	a0,a0,1
    p2++;
 420:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 422:	fed518e3          	bne	a0,a3,412 <memcmp+0x14>
  }
  return 0;
 426:	4501                	li	a0,0
 428:	a019                	j	42e <memcmp+0x30>
      return *p1 - *p2;
 42a:	40e7853b          	subw	a0,a5,a4
}
 42e:	6422                	ld	s0,8(sp)
 430:	0141                	addi	sp,sp,16
 432:	8082                	ret
  return 0;
 434:	4501                	li	a0,0
 436:	bfe5                	j	42e <memcmp+0x30>

0000000000000438 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 438:	1141                	addi	sp,sp,-16
 43a:	e406                	sd	ra,8(sp)
 43c:	e022                	sd	s0,0(sp)
 43e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 440:	00000097          	auipc	ra,0x0
 444:	f62080e7          	jalr	-158(ra) # 3a2 <memmove>
}
 448:	60a2                	ld	ra,8(sp)
 44a:	6402                	ld	s0,0(sp)
 44c:	0141                	addi	sp,sp,16
 44e:	8082                	ret

0000000000000450 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 450:	4885                	li	a7,1
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <exit>:
.global exit
exit:
 li a7, SYS_exit
 458:	4889                	li	a7,2
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <wait>:
.global wait
wait:
 li a7, SYS_wait
 460:	488d                	li	a7,3
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 468:	4891                	li	a7,4
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <read>:
.global read
read:
 li a7, SYS_read
 470:	4895                	li	a7,5
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <write>:
.global write
write:
 li a7, SYS_write
 478:	48c1                	li	a7,16
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <close>:
.global close
close:
 li a7, SYS_close
 480:	48d5                	li	a7,21
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <kill>:
.global kill
kill:
 li a7, SYS_kill
 488:	4899                	li	a7,6
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <exec>:
.global exec
exec:
 li a7, SYS_exec
 490:	489d                	li	a7,7
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <open>:
.global open
open:
 li a7, SYS_open
 498:	48bd                	li	a7,15
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4a0:	48c5                	li	a7,17
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4a8:	48c9                	li	a7,18
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4b0:	48a1                	li	a7,8
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <link>:
.global link
link:
 li a7, SYS_link
 4b8:	48cd                	li	a7,19
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4c0:	48d1                	li	a7,20
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4c8:	48a5                	li	a7,9
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4d0:	48a9                	li	a7,10
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4d8:	48ad                	li	a7,11
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4e0:	48b1                	li	a7,12
 ecall
 4e2:	00000073          	ecall
 ret
 4e6:	8082                	ret

00000000000004e8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4e8:	48b5                	li	a7,13
 ecall
 4ea:	00000073          	ecall
 ret
 4ee:	8082                	ret

00000000000004f0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4f0:	48b9                	li	a7,14
 ecall
 4f2:	00000073          	ecall
 ret
 4f6:	8082                	ret

00000000000004f8 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 4f8:	48d9                	li	a7,22
 ecall
 4fa:	00000073          	ecall
 ret
 4fe:	8082                	ret

0000000000000500 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 500:	48dd                	li	a7,23
 ecall
 502:	00000073          	ecall
 ret
 506:	8082                	ret

0000000000000508 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 508:	1101                	addi	sp,sp,-32
 50a:	ec06                	sd	ra,24(sp)
 50c:	e822                	sd	s0,16(sp)
 50e:	1000                	addi	s0,sp,32
 510:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 514:	4605                	li	a2,1
 516:	fef40593          	addi	a1,s0,-17
 51a:	00000097          	auipc	ra,0x0
 51e:	f5e080e7          	jalr	-162(ra) # 478 <write>
}
 522:	60e2                	ld	ra,24(sp)
 524:	6442                	ld	s0,16(sp)
 526:	6105                	addi	sp,sp,32
 528:	8082                	ret

000000000000052a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 52a:	7139                	addi	sp,sp,-64
 52c:	fc06                	sd	ra,56(sp)
 52e:	f822                	sd	s0,48(sp)
 530:	f426                	sd	s1,40(sp)
 532:	f04a                	sd	s2,32(sp)
 534:	ec4e                	sd	s3,24(sp)
 536:	0080                	addi	s0,sp,64
 538:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 53a:	c299                	beqz	a3,540 <printint+0x16>
 53c:	0805c863          	bltz	a1,5cc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 540:	2581                	sext.w	a1,a1
  neg = 0;
 542:	4881                	li	a7,0
 544:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 548:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 54a:	2601                	sext.w	a2,a2
 54c:	00000517          	auipc	a0,0x0
 550:	4b450513          	addi	a0,a0,1204 # a00 <digits>
 554:	883a                	mv	a6,a4
 556:	2705                	addiw	a4,a4,1
 558:	02c5f7bb          	remuw	a5,a1,a2
 55c:	1782                	slli	a5,a5,0x20
 55e:	9381                	srli	a5,a5,0x20
 560:	97aa                	add	a5,a5,a0
 562:	0007c783          	lbu	a5,0(a5)
 566:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 56a:	0005879b          	sext.w	a5,a1
 56e:	02c5d5bb          	divuw	a1,a1,a2
 572:	0685                	addi	a3,a3,1
 574:	fec7f0e3          	bgeu	a5,a2,554 <printint+0x2a>
  if(neg)
 578:	00088b63          	beqz	a7,58e <printint+0x64>
    buf[i++] = '-';
 57c:	fd040793          	addi	a5,s0,-48
 580:	973e                	add	a4,a4,a5
 582:	02d00793          	li	a5,45
 586:	fef70823          	sb	a5,-16(a4)
 58a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 58e:	02e05863          	blez	a4,5be <printint+0x94>
 592:	fc040793          	addi	a5,s0,-64
 596:	00e78933          	add	s2,a5,a4
 59a:	fff78993          	addi	s3,a5,-1
 59e:	99ba                	add	s3,s3,a4
 5a0:	377d                	addiw	a4,a4,-1
 5a2:	1702                	slli	a4,a4,0x20
 5a4:	9301                	srli	a4,a4,0x20
 5a6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5aa:	fff94583          	lbu	a1,-1(s2)
 5ae:	8526                	mv	a0,s1
 5b0:	00000097          	auipc	ra,0x0
 5b4:	f58080e7          	jalr	-168(ra) # 508 <putc>
  while(--i >= 0)
 5b8:	197d                	addi	s2,s2,-1
 5ba:	ff3918e3          	bne	s2,s3,5aa <printint+0x80>
}
 5be:	70e2                	ld	ra,56(sp)
 5c0:	7442                	ld	s0,48(sp)
 5c2:	74a2                	ld	s1,40(sp)
 5c4:	7902                	ld	s2,32(sp)
 5c6:	69e2                	ld	s3,24(sp)
 5c8:	6121                	addi	sp,sp,64
 5ca:	8082                	ret
    x = -xx;
 5cc:	40b005bb          	negw	a1,a1
    neg = 1;
 5d0:	4885                	li	a7,1
    x = -xx;
 5d2:	bf8d                	j	544 <printint+0x1a>

00000000000005d4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5d4:	7119                	addi	sp,sp,-128
 5d6:	fc86                	sd	ra,120(sp)
 5d8:	f8a2                	sd	s0,112(sp)
 5da:	f4a6                	sd	s1,104(sp)
 5dc:	f0ca                	sd	s2,96(sp)
 5de:	ecce                	sd	s3,88(sp)
 5e0:	e8d2                	sd	s4,80(sp)
 5e2:	e4d6                	sd	s5,72(sp)
 5e4:	e0da                	sd	s6,64(sp)
 5e6:	fc5e                	sd	s7,56(sp)
 5e8:	f862                	sd	s8,48(sp)
 5ea:	f466                	sd	s9,40(sp)
 5ec:	f06a                	sd	s10,32(sp)
 5ee:	ec6e                	sd	s11,24(sp)
 5f0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5f2:	0005c903          	lbu	s2,0(a1)
 5f6:	18090f63          	beqz	s2,794 <vprintf+0x1c0>
 5fa:	8aaa                	mv	s5,a0
 5fc:	8b32                	mv	s6,a2
 5fe:	00158493          	addi	s1,a1,1
  state = 0;
 602:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 604:	02500a13          	li	s4,37
      if(c == 'd'){
 608:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 60c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 610:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 614:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 618:	00000b97          	auipc	s7,0x0
 61c:	3e8b8b93          	addi	s7,s7,1000 # a00 <digits>
 620:	a839                	j	63e <vprintf+0x6a>
        putc(fd, c);
 622:	85ca                	mv	a1,s2
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	ee2080e7          	jalr	-286(ra) # 508 <putc>
 62e:	a019                	j	634 <vprintf+0x60>
    } else if(state == '%'){
 630:	01498f63          	beq	s3,s4,64e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 634:	0485                	addi	s1,s1,1
 636:	fff4c903          	lbu	s2,-1(s1)
 63a:	14090d63          	beqz	s2,794 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 63e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 642:	fe0997e3          	bnez	s3,630 <vprintf+0x5c>
      if(c == '%'){
 646:	fd479ee3          	bne	a5,s4,622 <vprintf+0x4e>
        state = '%';
 64a:	89be                	mv	s3,a5
 64c:	b7e5                	j	634 <vprintf+0x60>
      if(c == 'd'){
 64e:	05878063          	beq	a5,s8,68e <vprintf+0xba>
      } else if(c == 'l') {
 652:	05978c63          	beq	a5,s9,6aa <vprintf+0xd6>
      } else if(c == 'x') {
 656:	07a78863          	beq	a5,s10,6c6 <vprintf+0xf2>
      } else if(c == 'p') {
 65a:	09b78463          	beq	a5,s11,6e2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 65e:	07300713          	li	a4,115
 662:	0ce78663          	beq	a5,a4,72e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 666:	06300713          	li	a4,99
 66a:	0ee78e63          	beq	a5,a4,766 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 66e:	11478863          	beq	a5,s4,77e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 672:	85d2                	mv	a1,s4
 674:	8556                	mv	a0,s5
 676:	00000097          	auipc	ra,0x0
 67a:	e92080e7          	jalr	-366(ra) # 508 <putc>
        putc(fd, c);
 67e:	85ca                	mv	a1,s2
 680:	8556                	mv	a0,s5
 682:	00000097          	auipc	ra,0x0
 686:	e86080e7          	jalr	-378(ra) # 508 <putc>
      }
      state = 0;
 68a:	4981                	li	s3,0
 68c:	b765                	j	634 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 68e:	008b0913          	addi	s2,s6,8
 692:	4685                	li	a3,1
 694:	4629                	li	a2,10
 696:	000b2583          	lw	a1,0(s6)
 69a:	8556                	mv	a0,s5
 69c:	00000097          	auipc	ra,0x0
 6a0:	e8e080e7          	jalr	-370(ra) # 52a <printint>
 6a4:	8b4a                	mv	s6,s2
      state = 0;
 6a6:	4981                	li	s3,0
 6a8:	b771                	j	634 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6aa:	008b0913          	addi	s2,s6,8
 6ae:	4681                	li	a3,0
 6b0:	4629                	li	a2,10
 6b2:	000b2583          	lw	a1,0(s6)
 6b6:	8556                	mv	a0,s5
 6b8:	00000097          	auipc	ra,0x0
 6bc:	e72080e7          	jalr	-398(ra) # 52a <printint>
 6c0:	8b4a                	mv	s6,s2
      state = 0;
 6c2:	4981                	li	s3,0
 6c4:	bf85                	j	634 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6c6:	008b0913          	addi	s2,s6,8
 6ca:	4681                	li	a3,0
 6cc:	4641                	li	a2,16
 6ce:	000b2583          	lw	a1,0(s6)
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e56080e7          	jalr	-426(ra) # 52a <printint>
 6dc:	8b4a                	mv	s6,s2
      state = 0;
 6de:	4981                	li	s3,0
 6e0:	bf91                	j	634 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6e2:	008b0793          	addi	a5,s6,8
 6e6:	f8f43423          	sd	a5,-120(s0)
 6ea:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6ee:	03000593          	li	a1,48
 6f2:	8556                	mv	a0,s5
 6f4:	00000097          	auipc	ra,0x0
 6f8:	e14080e7          	jalr	-492(ra) # 508 <putc>
  putc(fd, 'x');
 6fc:	85ea                	mv	a1,s10
 6fe:	8556                	mv	a0,s5
 700:	00000097          	auipc	ra,0x0
 704:	e08080e7          	jalr	-504(ra) # 508 <putc>
 708:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 70a:	03c9d793          	srli	a5,s3,0x3c
 70e:	97de                	add	a5,a5,s7
 710:	0007c583          	lbu	a1,0(a5)
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	df2080e7          	jalr	-526(ra) # 508 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 71e:	0992                	slli	s3,s3,0x4
 720:	397d                	addiw	s2,s2,-1
 722:	fe0914e3          	bnez	s2,70a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 726:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 72a:	4981                	li	s3,0
 72c:	b721                	j	634 <vprintf+0x60>
        s = va_arg(ap, char*);
 72e:	008b0993          	addi	s3,s6,8
 732:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 736:	02090163          	beqz	s2,758 <vprintf+0x184>
        while(*s != 0){
 73a:	00094583          	lbu	a1,0(s2)
 73e:	c9a1                	beqz	a1,78e <vprintf+0x1ba>
          putc(fd, *s);
 740:	8556                	mv	a0,s5
 742:	00000097          	auipc	ra,0x0
 746:	dc6080e7          	jalr	-570(ra) # 508 <putc>
          s++;
 74a:	0905                	addi	s2,s2,1
        while(*s != 0){
 74c:	00094583          	lbu	a1,0(s2)
 750:	f9e5                	bnez	a1,740 <vprintf+0x16c>
        s = va_arg(ap, char*);
 752:	8b4e                	mv	s6,s3
      state = 0;
 754:	4981                	li	s3,0
 756:	bdf9                	j	634 <vprintf+0x60>
          s = "(null)";
 758:	00000917          	auipc	s2,0x0
 75c:	2a090913          	addi	s2,s2,672 # 9f8 <malloc+0x15a>
        while(*s != 0){
 760:	02800593          	li	a1,40
 764:	bff1                	j	740 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 766:	008b0913          	addi	s2,s6,8
 76a:	000b4583          	lbu	a1,0(s6)
 76e:	8556                	mv	a0,s5
 770:	00000097          	auipc	ra,0x0
 774:	d98080e7          	jalr	-616(ra) # 508 <putc>
 778:	8b4a                	mv	s6,s2
      state = 0;
 77a:	4981                	li	s3,0
 77c:	bd65                	j	634 <vprintf+0x60>
        putc(fd, c);
 77e:	85d2                	mv	a1,s4
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	d86080e7          	jalr	-634(ra) # 508 <putc>
      state = 0;
 78a:	4981                	li	s3,0
 78c:	b565                	j	634 <vprintf+0x60>
        s = va_arg(ap, char*);
 78e:	8b4e                	mv	s6,s3
      state = 0;
 790:	4981                	li	s3,0
 792:	b54d                	j	634 <vprintf+0x60>
    }
  }
}
 794:	70e6                	ld	ra,120(sp)
 796:	7446                	ld	s0,112(sp)
 798:	74a6                	ld	s1,104(sp)
 79a:	7906                	ld	s2,96(sp)
 79c:	69e6                	ld	s3,88(sp)
 79e:	6a46                	ld	s4,80(sp)
 7a0:	6aa6                	ld	s5,72(sp)
 7a2:	6b06                	ld	s6,64(sp)
 7a4:	7be2                	ld	s7,56(sp)
 7a6:	7c42                	ld	s8,48(sp)
 7a8:	7ca2                	ld	s9,40(sp)
 7aa:	7d02                	ld	s10,32(sp)
 7ac:	6de2                	ld	s11,24(sp)
 7ae:	6109                	addi	sp,sp,128
 7b0:	8082                	ret

00000000000007b2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7b2:	715d                	addi	sp,sp,-80
 7b4:	ec06                	sd	ra,24(sp)
 7b6:	e822                	sd	s0,16(sp)
 7b8:	1000                	addi	s0,sp,32
 7ba:	e010                	sd	a2,0(s0)
 7bc:	e414                	sd	a3,8(s0)
 7be:	e818                	sd	a4,16(s0)
 7c0:	ec1c                	sd	a5,24(s0)
 7c2:	03043023          	sd	a6,32(s0)
 7c6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7ca:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7ce:	8622                	mv	a2,s0
 7d0:	00000097          	auipc	ra,0x0
 7d4:	e04080e7          	jalr	-508(ra) # 5d4 <vprintf>
}
 7d8:	60e2                	ld	ra,24(sp)
 7da:	6442                	ld	s0,16(sp)
 7dc:	6161                	addi	sp,sp,80
 7de:	8082                	ret

00000000000007e0 <printf>:

void
printf(const char *fmt, ...)
{
 7e0:	711d                	addi	sp,sp,-96
 7e2:	ec06                	sd	ra,24(sp)
 7e4:	e822                	sd	s0,16(sp)
 7e6:	1000                	addi	s0,sp,32
 7e8:	e40c                	sd	a1,8(s0)
 7ea:	e810                	sd	a2,16(s0)
 7ec:	ec14                	sd	a3,24(s0)
 7ee:	f018                	sd	a4,32(s0)
 7f0:	f41c                	sd	a5,40(s0)
 7f2:	03043823          	sd	a6,48(s0)
 7f6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7fa:	00840613          	addi	a2,s0,8
 7fe:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 802:	85aa                	mv	a1,a0
 804:	4505                	li	a0,1
 806:	00000097          	auipc	ra,0x0
 80a:	dce080e7          	jalr	-562(ra) # 5d4 <vprintf>
}
 80e:	60e2                	ld	ra,24(sp)
 810:	6442                	ld	s0,16(sp)
 812:	6125                	addi	sp,sp,96
 814:	8082                	ret

0000000000000816 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 816:	1141                	addi	sp,sp,-16
 818:	e422                	sd	s0,8(sp)
 81a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 81c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 820:	00000797          	auipc	a5,0x0
 824:	1f87b783          	ld	a5,504(a5) # a18 <freep>
 828:	a805                	j	858 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 82a:	4618                	lw	a4,8(a2)
 82c:	9db9                	addw	a1,a1,a4
 82e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 832:	6398                	ld	a4,0(a5)
 834:	6318                	ld	a4,0(a4)
 836:	fee53823          	sd	a4,-16(a0)
 83a:	a091                	j	87e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 83c:	ff852703          	lw	a4,-8(a0)
 840:	9e39                	addw	a2,a2,a4
 842:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 844:	ff053703          	ld	a4,-16(a0)
 848:	e398                	sd	a4,0(a5)
 84a:	a099                	j	890 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 84c:	6398                	ld	a4,0(a5)
 84e:	00e7e463          	bltu	a5,a4,856 <free+0x40>
 852:	00e6ea63          	bltu	a3,a4,866 <free+0x50>
{
 856:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 858:	fed7fae3          	bgeu	a5,a3,84c <free+0x36>
 85c:	6398                	ld	a4,0(a5)
 85e:	00e6e463          	bltu	a3,a4,866 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 862:	fee7eae3          	bltu	a5,a4,856 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 866:	ff852583          	lw	a1,-8(a0)
 86a:	6390                	ld	a2,0(a5)
 86c:	02059713          	slli	a4,a1,0x20
 870:	9301                	srli	a4,a4,0x20
 872:	0712                	slli	a4,a4,0x4
 874:	9736                	add	a4,a4,a3
 876:	fae60ae3          	beq	a2,a4,82a <free+0x14>
    bp->s.ptr = p->s.ptr;
 87a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 87e:	4790                	lw	a2,8(a5)
 880:	02061713          	slli	a4,a2,0x20
 884:	9301                	srli	a4,a4,0x20
 886:	0712                	slli	a4,a4,0x4
 888:	973e                	add	a4,a4,a5
 88a:	fae689e3          	beq	a3,a4,83c <free+0x26>
  } else
    p->s.ptr = bp;
 88e:	e394                	sd	a3,0(a5)
  freep = p;
 890:	00000717          	auipc	a4,0x0
 894:	18f73423          	sd	a5,392(a4) # a18 <freep>
}
 898:	6422                	ld	s0,8(sp)
 89a:	0141                	addi	sp,sp,16
 89c:	8082                	ret

000000000000089e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 89e:	7139                	addi	sp,sp,-64
 8a0:	fc06                	sd	ra,56(sp)
 8a2:	f822                	sd	s0,48(sp)
 8a4:	f426                	sd	s1,40(sp)
 8a6:	f04a                	sd	s2,32(sp)
 8a8:	ec4e                	sd	s3,24(sp)
 8aa:	e852                	sd	s4,16(sp)
 8ac:	e456                	sd	s5,8(sp)
 8ae:	e05a                	sd	s6,0(sp)
 8b0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8b2:	02051493          	slli	s1,a0,0x20
 8b6:	9081                	srli	s1,s1,0x20
 8b8:	04bd                	addi	s1,s1,15
 8ba:	8091                	srli	s1,s1,0x4
 8bc:	0014899b          	addiw	s3,s1,1
 8c0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8c2:	00000517          	auipc	a0,0x0
 8c6:	15653503          	ld	a0,342(a0) # a18 <freep>
 8ca:	c515                	beqz	a0,8f6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8cc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8ce:	4798                	lw	a4,8(a5)
 8d0:	02977f63          	bgeu	a4,s1,90e <malloc+0x70>
 8d4:	8a4e                	mv	s4,s3
 8d6:	0009871b          	sext.w	a4,s3
 8da:	6685                	lui	a3,0x1
 8dc:	00d77363          	bgeu	a4,a3,8e2 <malloc+0x44>
 8e0:	6a05                	lui	s4,0x1
 8e2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8e6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8ea:	00000917          	auipc	s2,0x0
 8ee:	12e90913          	addi	s2,s2,302 # a18 <freep>
  if(p == (char*)-1)
 8f2:	5afd                	li	s5,-1
 8f4:	a88d                	j	966 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8f6:	00000797          	auipc	a5,0x0
 8fa:	12a78793          	addi	a5,a5,298 # a20 <base>
 8fe:	00000717          	auipc	a4,0x0
 902:	10f73d23          	sd	a5,282(a4) # a18 <freep>
 906:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 908:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 90c:	b7e1                	j	8d4 <malloc+0x36>
      if(p->s.size == nunits)
 90e:	02e48b63          	beq	s1,a4,944 <malloc+0xa6>
        p->s.size -= nunits;
 912:	4137073b          	subw	a4,a4,s3
 916:	c798                	sw	a4,8(a5)
        p += p->s.size;
 918:	1702                	slli	a4,a4,0x20
 91a:	9301                	srli	a4,a4,0x20
 91c:	0712                	slli	a4,a4,0x4
 91e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 920:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 924:	00000717          	auipc	a4,0x0
 928:	0ea73a23          	sd	a0,244(a4) # a18 <freep>
      return (void*)(p + 1);
 92c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 930:	70e2                	ld	ra,56(sp)
 932:	7442                	ld	s0,48(sp)
 934:	74a2                	ld	s1,40(sp)
 936:	7902                	ld	s2,32(sp)
 938:	69e2                	ld	s3,24(sp)
 93a:	6a42                	ld	s4,16(sp)
 93c:	6aa2                	ld	s5,8(sp)
 93e:	6b02                	ld	s6,0(sp)
 940:	6121                	addi	sp,sp,64
 942:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 944:	6398                	ld	a4,0(a5)
 946:	e118                	sd	a4,0(a0)
 948:	bff1                	j	924 <malloc+0x86>
  hp->s.size = nu;
 94a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 94e:	0541                	addi	a0,a0,16
 950:	00000097          	auipc	ra,0x0
 954:	ec6080e7          	jalr	-314(ra) # 816 <free>
  return freep;
 958:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 95c:	d971                	beqz	a0,930 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 95e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 960:	4798                	lw	a4,8(a5)
 962:	fa9776e3          	bgeu	a4,s1,90e <malloc+0x70>
    if(p == freep)
 966:	00093703          	ld	a4,0(s2)
 96a:	853e                	mv	a0,a5
 96c:	fef719e3          	bne	a4,a5,95e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 970:	8552                	mv	a0,s4
 972:	00000097          	auipc	ra,0x0
 976:	b6e080e7          	jalr	-1170(ra) # 4e0 <sbrk>
  if(p == (char*)-1)
 97a:	fd5518e3          	bne	a0,s5,94a <malloc+0xac>
        return 0;
 97e:	4501                	li	a0,0
 980:	bf45                	j	930 <malloc+0x92>
