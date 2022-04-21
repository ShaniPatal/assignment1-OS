
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <env>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void env(int size, int interval, char* env_name) {
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
  16:	8ab2                	mv	s5,a2
    int pid;
    int result = 1;
    int loop_size = (10e6);
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
  18:	00000097          	auipc	ra,0x0
  1c:	372080e7          	jalr	882(ra) # 38a <fork>
  20:	00000097          	auipc	ra,0x0
  24:	36a080e7          	jalr	874(ra) # 38a <fork>
  28:	8a2a                	mv	s4,a0
    }
    for (int i = 0; i < loop_size; i++) {
  2a:	4481                	li	s1,0
        if (i % (int)(loop_size / 10e0) == 0) {
  2c:	000f49b7          	lui	s3,0xf4
  30:	2409899b          	addiw	s3,s3,576
            if (pid == 0) {
                printf("%s %d/%d completed.\n", env_name, i, loop_size);
            } else {
                printf(" ");
  34:	00001b97          	auipc	s7,0x1
  38:	8acb8b93          	addi	s7,s7,-1876 # 8e0 <malloc+0x100>
                printf("%s %d/%d completed.\n", env_name, i, loop_size);
  3c:	00989937          	lui	s2,0x989
  40:	68090913          	addi	s2,s2,1664 # 989680 <__global_pointer$+0x988557>
  44:	00001b17          	auipc	s6,0x1
  48:	884b0b13          	addi	s6,s6,-1916 # 8c8 <malloc+0xe8>
  4c:	a809                	j	5e <env+0x5e>
                printf(" ");
  4e:	855e                	mv	a0,s7
  50:	00000097          	auipc	ra,0x0
  54:	6d2080e7          	jalr	1746(ra) # 722 <printf>
    for (int i = 0; i < loop_size; i++) {
  58:	2485                	addiw	s1,s1,1
  5a:	03248063          	beq	s1,s2,7a <env+0x7a>
        if (i % (int)(loop_size / 10e0) == 0) {
  5e:	0334e7bb          	remw	a5,s1,s3
  62:	fbfd                	bnez	a5,58 <env+0x58>
            if (pid == 0) {
  64:	fe0a15e3          	bnez	s4,4e <env+0x4e>
                printf("%s %d/%d completed.\n", env_name, i, loop_size);
  68:	86ca                	mv	a3,s2
  6a:	8626                	mv	a2,s1
  6c:	85d6                	mv	a1,s5
  6e:	855a                	mv	a0,s6
  70:	00000097          	auipc	ra,0x0
  74:	6b2080e7          	jalr	1714(ra) # 722 <printf>
  78:	b7c5                	j	58 <env+0x58>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	86e50513          	addi	a0,a0,-1938 # 8e8 <malloc+0x108>
  82:	00000097          	auipc	ra,0x0
  86:	6a0080e7          	jalr	1696(ra) # 722 <printf>
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

00000000000000a0 <env_large>:

void env_large() {
  a0:	1141                	addi	sp,sp,-16
  a2:	e406                	sd	ra,8(sp)
  a4:	e022                	sd	s0,0(sp)
  a6:	0800                	addi	s0,sp,16
    env(10e6, 10e6, "env_large");
  a8:	00001617          	auipc	a2,0x1
  ac:	84860613          	addi	a2,a2,-1976 # 8f0 <malloc+0x110>
  b0:	009895b7          	lui	a1,0x989
  b4:	68058593          	addi	a1,a1,1664 # 989680 <__global_pointer$+0x988557>
  b8:	852e                	mv	a0,a1
  ba:	00000097          	auipc	ra,0x0
  be:	f46080e7          	jalr	-186(ra) # 0 <env>
}
  c2:	60a2                	ld	ra,8(sp)
  c4:	6402                	ld	s0,0(sp)
  c6:	0141                	addi	sp,sp,16
  c8:	8082                	ret

00000000000000ca <env_freq>:

void env_freq() {
  ca:	1141                	addi	sp,sp,-16
  cc:	e406                	sd	ra,8(sp)
  ce:	e022                	sd	s0,0(sp)
  d0:	0800                	addi	s0,sp,16
    env(10e1, 10e1, "env_freq");
  d2:	00001617          	auipc	a2,0x1
  d6:	82e60613          	addi	a2,a2,-2002 # 900 <malloc+0x120>
  da:	06400593          	li	a1,100
  de:	06400513          	li	a0,100
  e2:	00000097          	auipc	ra,0x0
  e6:	f1e080e7          	jalr	-226(ra) # 0 <env>
}
  ea:	60a2                	ld	ra,8(sp)
  ec:	6402                	ld	s0,0(sp)
  ee:	0141                	addi	sp,sp,16
  f0:	8082                	ret

00000000000000f2 <main>:

int
main(int argc, char *argv[])
{
  f2:	1141                	addi	sp,sp,-16
  f4:	e406                	sd	ra,8(sp)
  f6:	e022                	sd	s0,0(sp)
  f8:	0800                	addi	s0,sp,16
    env_large();
  fa:	00000097          	auipc	ra,0x0
  fe:	fa6080e7          	jalr	-90(ra) # a0 <env_large>
    env_freq();
 102:	00000097          	auipc	ra,0x0
 106:	fc8080e7          	jalr	-56(ra) # ca <env_freq>
    print_stats();
 10a:	00000097          	auipc	ra,0x0
 10e:	338080e7          	jalr	824(ra) # 442 <print_stats>
    exit(0);
 112:	4501                	li	a0,0
 114:	00000097          	auipc	ra,0x0
 118:	27e080e7          	jalr	638(ra) # 392 <exit>

000000000000011c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 11c:	1141                	addi	sp,sp,-16
 11e:	e422                	sd	s0,8(sp)
 120:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 122:	87aa                	mv	a5,a0
 124:	0585                	addi	a1,a1,1
 126:	0785                	addi	a5,a5,1
 128:	fff5c703          	lbu	a4,-1(a1)
 12c:	fee78fa3          	sb	a4,-1(a5)
 130:	fb75                	bnez	a4,124 <strcpy+0x8>
    ;
  return os;
}
 132:	6422                	ld	s0,8(sp)
 134:	0141                	addi	sp,sp,16
 136:	8082                	ret

0000000000000138 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 13e:	00054783          	lbu	a5,0(a0)
 142:	cb91                	beqz	a5,156 <strcmp+0x1e>
 144:	0005c703          	lbu	a4,0(a1)
 148:	00f71763          	bne	a4,a5,156 <strcmp+0x1e>
    p++, q++;
 14c:	0505                	addi	a0,a0,1
 14e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 150:	00054783          	lbu	a5,0(a0)
 154:	fbe5                	bnez	a5,144 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 156:	0005c503          	lbu	a0,0(a1)
}
 15a:	40a7853b          	subw	a0,a5,a0
 15e:	6422                	ld	s0,8(sp)
 160:	0141                	addi	sp,sp,16
 162:	8082                	ret

0000000000000164 <strlen>:

uint
strlen(const char *s)
{
 164:	1141                	addi	sp,sp,-16
 166:	e422                	sd	s0,8(sp)
 168:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 16a:	00054783          	lbu	a5,0(a0)
 16e:	cf91                	beqz	a5,18a <strlen+0x26>
 170:	0505                	addi	a0,a0,1
 172:	87aa                	mv	a5,a0
 174:	4685                	li	a3,1
 176:	9e89                	subw	a3,a3,a0
 178:	00f6853b          	addw	a0,a3,a5
 17c:	0785                	addi	a5,a5,1
 17e:	fff7c703          	lbu	a4,-1(a5)
 182:	fb7d                	bnez	a4,178 <strlen+0x14>
    ;
  return n;
}
 184:	6422                	ld	s0,8(sp)
 186:	0141                	addi	sp,sp,16
 188:	8082                	ret
  for(n = 0; s[n]; n++)
 18a:	4501                	li	a0,0
 18c:	bfe5                	j	184 <strlen+0x20>

000000000000018e <memset>:

void*
memset(void *dst, int c, uint n)
{
 18e:	1141                	addi	sp,sp,-16
 190:	e422                	sd	s0,8(sp)
 192:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 194:	ce09                	beqz	a2,1ae <memset+0x20>
 196:	87aa                	mv	a5,a0
 198:	fff6071b          	addiw	a4,a2,-1
 19c:	1702                	slli	a4,a4,0x20
 19e:	9301                	srli	a4,a4,0x20
 1a0:	0705                	addi	a4,a4,1
 1a2:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1a4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1a8:	0785                	addi	a5,a5,1
 1aa:	fee79de3          	bne	a5,a4,1a4 <memset+0x16>
  }
  return dst;
}
 1ae:	6422                	ld	s0,8(sp)
 1b0:	0141                	addi	sp,sp,16
 1b2:	8082                	ret

00000000000001b4 <strchr>:

char*
strchr(const char *s, char c)
{
 1b4:	1141                	addi	sp,sp,-16
 1b6:	e422                	sd	s0,8(sp)
 1b8:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1ba:	00054783          	lbu	a5,0(a0)
 1be:	cb99                	beqz	a5,1d4 <strchr+0x20>
    if(*s == c)
 1c0:	00f58763          	beq	a1,a5,1ce <strchr+0x1a>
  for(; *s; s++)
 1c4:	0505                	addi	a0,a0,1
 1c6:	00054783          	lbu	a5,0(a0)
 1ca:	fbfd                	bnez	a5,1c0 <strchr+0xc>
      return (char*)s;
  return 0;
 1cc:	4501                	li	a0,0
}
 1ce:	6422                	ld	s0,8(sp)
 1d0:	0141                	addi	sp,sp,16
 1d2:	8082                	ret
  return 0;
 1d4:	4501                	li	a0,0
 1d6:	bfe5                	j	1ce <strchr+0x1a>

00000000000001d8 <gets>:

char*
gets(char *buf, int max)
{
 1d8:	711d                	addi	sp,sp,-96
 1da:	ec86                	sd	ra,88(sp)
 1dc:	e8a2                	sd	s0,80(sp)
 1de:	e4a6                	sd	s1,72(sp)
 1e0:	e0ca                	sd	s2,64(sp)
 1e2:	fc4e                	sd	s3,56(sp)
 1e4:	f852                	sd	s4,48(sp)
 1e6:	f456                	sd	s5,40(sp)
 1e8:	f05a                	sd	s6,32(sp)
 1ea:	ec5e                	sd	s7,24(sp)
 1ec:	1080                	addi	s0,sp,96
 1ee:	8baa                	mv	s7,a0
 1f0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1f2:	892a                	mv	s2,a0
 1f4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1f6:	4aa9                	li	s5,10
 1f8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1fa:	89a6                	mv	s3,s1
 1fc:	2485                	addiw	s1,s1,1
 1fe:	0344d863          	bge	s1,s4,22e <gets+0x56>
    cc = read(0, &c, 1);
 202:	4605                	li	a2,1
 204:	faf40593          	addi	a1,s0,-81
 208:	4501                	li	a0,0
 20a:	00000097          	auipc	ra,0x0
 20e:	1a0080e7          	jalr	416(ra) # 3aa <read>
    if(cc < 1)
 212:	00a05e63          	blez	a0,22e <gets+0x56>
    buf[i++] = c;
 216:	faf44783          	lbu	a5,-81(s0)
 21a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 21e:	01578763          	beq	a5,s5,22c <gets+0x54>
 222:	0905                	addi	s2,s2,1
 224:	fd679be3          	bne	a5,s6,1fa <gets+0x22>
  for(i=0; i+1 < max; ){
 228:	89a6                	mv	s3,s1
 22a:	a011                	j	22e <gets+0x56>
 22c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 22e:	99de                	add	s3,s3,s7
 230:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2ed7>
  return buf;
}
 234:	855e                	mv	a0,s7
 236:	60e6                	ld	ra,88(sp)
 238:	6446                	ld	s0,80(sp)
 23a:	64a6                	ld	s1,72(sp)
 23c:	6906                	ld	s2,64(sp)
 23e:	79e2                	ld	s3,56(sp)
 240:	7a42                	ld	s4,48(sp)
 242:	7aa2                	ld	s5,40(sp)
 244:	7b02                	ld	s6,32(sp)
 246:	6be2                	ld	s7,24(sp)
 248:	6125                	addi	sp,sp,96
 24a:	8082                	ret

000000000000024c <stat>:

int
stat(const char *n, struct stat *st)
{
 24c:	1101                	addi	sp,sp,-32
 24e:	ec06                	sd	ra,24(sp)
 250:	e822                	sd	s0,16(sp)
 252:	e426                	sd	s1,8(sp)
 254:	e04a                	sd	s2,0(sp)
 256:	1000                	addi	s0,sp,32
 258:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 25a:	4581                	li	a1,0
 25c:	00000097          	auipc	ra,0x0
 260:	176080e7          	jalr	374(ra) # 3d2 <open>
  if(fd < 0)
 264:	02054563          	bltz	a0,28e <stat+0x42>
 268:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 26a:	85ca                	mv	a1,s2
 26c:	00000097          	auipc	ra,0x0
 270:	17e080e7          	jalr	382(ra) # 3ea <fstat>
 274:	892a                	mv	s2,a0
  close(fd);
 276:	8526                	mv	a0,s1
 278:	00000097          	auipc	ra,0x0
 27c:	142080e7          	jalr	322(ra) # 3ba <close>
  return r;
}
 280:	854a                	mv	a0,s2
 282:	60e2                	ld	ra,24(sp)
 284:	6442                	ld	s0,16(sp)
 286:	64a2                	ld	s1,8(sp)
 288:	6902                	ld	s2,0(sp)
 28a:	6105                	addi	sp,sp,32
 28c:	8082                	ret
    return -1;
 28e:	597d                	li	s2,-1
 290:	bfc5                	j	280 <stat+0x34>

0000000000000292 <atoi>:

int
atoi(const char *s)
{
 292:	1141                	addi	sp,sp,-16
 294:	e422                	sd	s0,8(sp)
 296:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 298:	00054603          	lbu	a2,0(a0)
 29c:	fd06079b          	addiw	a5,a2,-48
 2a0:	0ff7f793          	andi	a5,a5,255
 2a4:	4725                	li	a4,9
 2a6:	02f76963          	bltu	a4,a5,2d8 <atoi+0x46>
 2aa:	86aa                	mv	a3,a0
  n = 0;
 2ac:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2ae:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2b0:	0685                	addi	a3,a3,1
 2b2:	0025179b          	slliw	a5,a0,0x2
 2b6:	9fa9                	addw	a5,a5,a0
 2b8:	0017979b          	slliw	a5,a5,0x1
 2bc:	9fb1                	addw	a5,a5,a2
 2be:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2c2:	0006c603          	lbu	a2,0(a3)
 2c6:	fd06071b          	addiw	a4,a2,-48
 2ca:	0ff77713          	andi	a4,a4,255
 2ce:	fee5f1e3          	bgeu	a1,a4,2b0 <atoi+0x1e>
  return n;
}
 2d2:	6422                	ld	s0,8(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret
  n = 0;
 2d8:	4501                	li	a0,0
 2da:	bfe5                	j	2d2 <atoi+0x40>

00000000000002dc <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2dc:	1141                	addi	sp,sp,-16
 2de:	e422                	sd	s0,8(sp)
 2e0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2e2:	02b57663          	bgeu	a0,a1,30e <memmove+0x32>
    while(n-- > 0)
 2e6:	02c05163          	blez	a2,308 <memmove+0x2c>
 2ea:	fff6079b          	addiw	a5,a2,-1
 2ee:	1782                	slli	a5,a5,0x20
 2f0:	9381                	srli	a5,a5,0x20
 2f2:	0785                	addi	a5,a5,1
 2f4:	97aa                	add	a5,a5,a0
  dst = vdst;
 2f6:	872a                	mv	a4,a0
      *dst++ = *src++;
 2f8:	0585                	addi	a1,a1,1
 2fa:	0705                	addi	a4,a4,1
 2fc:	fff5c683          	lbu	a3,-1(a1)
 300:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 304:	fee79ae3          	bne	a5,a4,2f8 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 308:	6422                	ld	s0,8(sp)
 30a:	0141                	addi	sp,sp,16
 30c:	8082                	ret
    dst += n;
 30e:	00c50733          	add	a4,a0,a2
    src += n;
 312:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 314:	fec05ae3          	blez	a2,308 <memmove+0x2c>
 318:	fff6079b          	addiw	a5,a2,-1
 31c:	1782                	slli	a5,a5,0x20
 31e:	9381                	srli	a5,a5,0x20
 320:	fff7c793          	not	a5,a5
 324:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 326:	15fd                	addi	a1,a1,-1
 328:	177d                	addi	a4,a4,-1
 32a:	0005c683          	lbu	a3,0(a1)
 32e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 332:	fee79ae3          	bne	a5,a4,326 <memmove+0x4a>
 336:	bfc9                	j	308 <memmove+0x2c>

0000000000000338 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 338:	1141                	addi	sp,sp,-16
 33a:	e422                	sd	s0,8(sp)
 33c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 33e:	ca05                	beqz	a2,36e <memcmp+0x36>
 340:	fff6069b          	addiw	a3,a2,-1
 344:	1682                	slli	a3,a3,0x20
 346:	9281                	srli	a3,a3,0x20
 348:	0685                	addi	a3,a3,1
 34a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 34c:	00054783          	lbu	a5,0(a0)
 350:	0005c703          	lbu	a4,0(a1)
 354:	00e79863          	bne	a5,a4,364 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 358:	0505                	addi	a0,a0,1
    p2++;
 35a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 35c:	fed518e3          	bne	a0,a3,34c <memcmp+0x14>
  }
  return 0;
 360:	4501                	li	a0,0
 362:	a019                	j	368 <memcmp+0x30>
      return *p1 - *p2;
 364:	40e7853b          	subw	a0,a5,a4
}
 368:	6422                	ld	s0,8(sp)
 36a:	0141                	addi	sp,sp,16
 36c:	8082                	ret
  return 0;
 36e:	4501                	li	a0,0
 370:	bfe5                	j	368 <memcmp+0x30>

0000000000000372 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 372:	1141                	addi	sp,sp,-16
 374:	e406                	sd	ra,8(sp)
 376:	e022                	sd	s0,0(sp)
 378:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 37a:	00000097          	auipc	ra,0x0
 37e:	f62080e7          	jalr	-158(ra) # 2dc <memmove>
}
 382:	60a2                	ld	ra,8(sp)
 384:	6402                	ld	s0,0(sp)
 386:	0141                	addi	sp,sp,16
 388:	8082                	ret

000000000000038a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 38a:	4885                	li	a7,1
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <exit>:
.global exit
exit:
 li a7, SYS_exit
 392:	4889                	li	a7,2
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <wait>:
.global wait
wait:
 li a7, SYS_wait
 39a:	488d                	li	a7,3
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3a2:	4891                	li	a7,4
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <read>:
.global read
read:
 li a7, SYS_read
 3aa:	4895                	li	a7,5
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <write>:
.global write
write:
 li a7, SYS_write
 3b2:	48c1                	li	a7,16
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <close>:
.global close
close:
 li a7, SYS_close
 3ba:	48d5                	li	a7,21
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3c2:	4899                	li	a7,6
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <exec>:
.global exec
exec:
 li a7, SYS_exec
 3ca:	489d                	li	a7,7
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <open>:
.global open
open:
 li a7, SYS_open
 3d2:	48bd                	li	a7,15
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3da:	48c5                	li	a7,17
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3e2:	48c9                	li	a7,18
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3ea:	48a1                	li	a7,8
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <link>:
.global link
link:
 li a7, SYS_link
 3f2:	48cd                	li	a7,19
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3fa:	48d1                	li	a7,20
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 402:	48a5                	li	a7,9
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <dup>:
.global dup
dup:
 li a7, SYS_dup
 40a:	48a9                	li	a7,10
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 412:	48ad                	li	a7,11
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 41a:	48b1                	li	a7,12
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 422:	48b5                	li	a7,13
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 42a:	48b9                	li	a7,14
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 432:	48d9                	li	a7,22
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 43a:	48dd                	li	a7,23
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 442:	48e1                	li	a7,24
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 44a:	1101                	addi	sp,sp,-32
 44c:	ec06                	sd	ra,24(sp)
 44e:	e822                	sd	s0,16(sp)
 450:	1000                	addi	s0,sp,32
 452:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 456:	4605                	li	a2,1
 458:	fef40593          	addi	a1,s0,-17
 45c:	00000097          	auipc	ra,0x0
 460:	f56080e7          	jalr	-170(ra) # 3b2 <write>
}
 464:	60e2                	ld	ra,24(sp)
 466:	6442                	ld	s0,16(sp)
 468:	6105                	addi	sp,sp,32
 46a:	8082                	ret

000000000000046c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 46c:	7139                	addi	sp,sp,-64
 46e:	fc06                	sd	ra,56(sp)
 470:	f822                	sd	s0,48(sp)
 472:	f426                	sd	s1,40(sp)
 474:	f04a                	sd	s2,32(sp)
 476:	ec4e                	sd	s3,24(sp)
 478:	0080                	addi	s0,sp,64
 47a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 47c:	c299                	beqz	a3,482 <printint+0x16>
 47e:	0805c863          	bltz	a1,50e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 482:	2581                	sext.w	a1,a1
  neg = 0;
 484:	4881                	li	a7,0
 486:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 48a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 48c:	2601                	sext.w	a2,a2
 48e:	00000517          	auipc	a0,0x0
 492:	48a50513          	addi	a0,a0,1162 # 918 <digits>
 496:	883a                	mv	a6,a4
 498:	2705                	addiw	a4,a4,1
 49a:	02c5f7bb          	remuw	a5,a1,a2
 49e:	1782                	slli	a5,a5,0x20
 4a0:	9381                	srli	a5,a5,0x20
 4a2:	97aa                	add	a5,a5,a0
 4a4:	0007c783          	lbu	a5,0(a5)
 4a8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4ac:	0005879b          	sext.w	a5,a1
 4b0:	02c5d5bb          	divuw	a1,a1,a2
 4b4:	0685                	addi	a3,a3,1
 4b6:	fec7f0e3          	bgeu	a5,a2,496 <printint+0x2a>
  if(neg)
 4ba:	00088b63          	beqz	a7,4d0 <printint+0x64>
    buf[i++] = '-';
 4be:	fd040793          	addi	a5,s0,-48
 4c2:	973e                	add	a4,a4,a5
 4c4:	02d00793          	li	a5,45
 4c8:	fef70823          	sb	a5,-16(a4)
 4cc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4d0:	02e05863          	blez	a4,500 <printint+0x94>
 4d4:	fc040793          	addi	a5,s0,-64
 4d8:	00e78933          	add	s2,a5,a4
 4dc:	fff78993          	addi	s3,a5,-1
 4e0:	99ba                	add	s3,s3,a4
 4e2:	377d                	addiw	a4,a4,-1
 4e4:	1702                	slli	a4,a4,0x20
 4e6:	9301                	srli	a4,a4,0x20
 4e8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4ec:	fff94583          	lbu	a1,-1(s2)
 4f0:	8526                	mv	a0,s1
 4f2:	00000097          	auipc	ra,0x0
 4f6:	f58080e7          	jalr	-168(ra) # 44a <putc>
  while(--i >= 0)
 4fa:	197d                	addi	s2,s2,-1
 4fc:	ff3918e3          	bne	s2,s3,4ec <printint+0x80>
}
 500:	70e2                	ld	ra,56(sp)
 502:	7442                	ld	s0,48(sp)
 504:	74a2                	ld	s1,40(sp)
 506:	7902                	ld	s2,32(sp)
 508:	69e2                	ld	s3,24(sp)
 50a:	6121                	addi	sp,sp,64
 50c:	8082                	ret
    x = -xx;
 50e:	40b005bb          	negw	a1,a1
    neg = 1;
 512:	4885                	li	a7,1
    x = -xx;
 514:	bf8d                	j	486 <printint+0x1a>

0000000000000516 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 516:	7119                	addi	sp,sp,-128
 518:	fc86                	sd	ra,120(sp)
 51a:	f8a2                	sd	s0,112(sp)
 51c:	f4a6                	sd	s1,104(sp)
 51e:	f0ca                	sd	s2,96(sp)
 520:	ecce                	sd	s3,88(sp)
 522:	e8d2                	sd	s4,80(sp)
 524:	e4d6                	sd	s5,72(sp)
 526:	e0da                	sd	s6,64(sp)
 528:	fc5e                	sd	s7,56(sp)
 52a:	f862                	sd	s8,48(sp)
 52c:	f466                	sd	s9,40(sp)
 52e:	f06a                	sd	s10,32(sp)
 530:	ec6e                	sd	s11,24(sp)
 532:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 534:	0005c903          	lbu	s2,0(a1)
 538:	18090f63          	beqz	s2,6d6 <vprintf+0x1c0>
 53c:	8aaa                	mv	s5,a0
 53e:	8b32                	mv	s6,a2
 540:	00158493          	addi	s1,a1,1
  state = 0;
 544:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 546:	02500a13          	li	s4,37
      if(c == 'd'){
 54a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 54e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 552:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 556:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 55a:	00000b97          	auipc	s7,0x0
 55e:	3beb8b93          	addi	s7,s7,958 # 918 <digits>
 562:	a839                	j	580 <vprintf+0x6a>
        putc(fd, c);
 564:	85ca                	mv	a1,s2
 566:	8556                	mv	a0,s5
 568:	00000097          	auipc	ra,0x0
 56c:	ee2080e7          	jalr	-286(ra) # 44a <putc>
 570:	a019                	j	576 <vprintf+0x60>
    } else if(state == '%'){
 572:	01498f63          	beq	s3,s4,590 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 576:	0485                	addi	s1,s1,1
 578:	fff4c903          	lbu	s2,-1(s1)
 57c:	14090d63          	beqz	s2,6d6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 580:	0009079b          	sext.w	a5,s2
    if(state == 0){
 584:	fe0997e3          	bnez	s3,572 <vprintf+0x5c>
      if(c == '%'){
 588:	fd479ee3          	bne	a5,s4,564 <vprintf+0x4e>
        state = '%';
 58c:	89be                	mv	s3,a5
 58e:	b7e5                	j	576 <vprintf+0x60>
      if(c == 'd'){
 590:	05878063          	beq	a5,s8,5d0 <vprintf+0xba>
      } else if(c == 'l') {
 594:	05978c63          	beq	a5,s9,5ec <vprintf+0xd6>
      } else if(c == 'x') {
 598:	07a78863          	beq	a5,s10,608 <vprintf+0xf2>
      } else if(c == 'p') {
 59c:	09b78463          	beq	a5,s11,624 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5a0:	07300713          	li	a4,115
 5a4:	0ce78663          	beq	a5,a4,670 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5a8:	06300713          	li	a4,99
 5ac:	0ee78e63          	beq	a5,a4,6a8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5b0:	11478863          	beq	a5,s4,6c0 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5b4:	85d2                	mv	a1,s4
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	e92080e7          	jalr	-366(ra) # 44a <putc>
        putc(fd, c);
 5c0:	85ca                	mv	a1,s2
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	e86080e7          	jalr	-378(ra) # 44a <putc>
      }
      state = 0;
 5cc:	4981                	li	s3,0
 5ce:	b765                	j	576 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5d0:	008b0913          	addi	s2,s6,8
 5d4:	4685                	li	a3,1
 5d6:	4629                	li	a2,10
 5d8:	000b2583          	lw	a1,0(s6)
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	e8e080e7          	jalr	-370(ra) # 46c <printint>
 5e6:	8b4a                	mv	s6,s2
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	b771                	j	576 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5ec:	008b0913          	addi	s2,s6,8
 5f0:	4681                	li	a3,0
 5f2:	4629                	li	a2,10
 5f4:	000b2583          	lw	a1,0(s6)
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	e72080e7          	jalr	-398(ra) # 46c <printint>
 602:	8b4a                	mv	s6,s2
      state = 0;
 604:	4981                	li	s3,0
 606:	bf85                	j	576 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 608:	008b0913          	addi	s2,s6,8
 60c:	4681                	li	a3,0
 60e:	4641                	li	a2,16
 610:	000b2583          	lw	a1,0(s6)
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	e56080e7          	jalr	-426(ra) # 46c <printint>
 61e:	8b4a                	mv	s6,s2
      state = 0;
 620:	4981                	li	s3,0
 622:	bf91                	j	576 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 624:	008b0793          	addi	a5,s6,8
 628:	f8f43423          	sd	a5,-120(s0)
 62c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 630:	03000593          	li	a1,48
 634:	8556                	mv	a0,s5
 636:	00000097          	auipc	ra,0x0
 63a:	e14080e7          	jalr	-492(ra) # 44a <putc>
  putc(fd, 'x');
 63e:	85ea                	mv	a1,s10
 640:	8556                	mv	a0,s5
 642:	00000097          	auipc	ra,0x0
 646:	e08080e7          	jalr	-504(ra) # 44a <putc>
 64a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 64c:	03c9d793          	srli	a5,s3,0x3c
 650:	97de                	add	a5,a5,s7
 652:	0007c583          	lbu	a1,0(a5)
 656:	8556                	mv	a0,s5
 658:	00000097          	auipc	ra,0x0
 65c:	df2080e7          	jalr	-526(ra) # 44a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 660:	0992                	slli	s3,s3,0x4
 662:	397d                	addiw	s2,s2,-1
 664:	fe0914e3          	bnez	s2,64c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 668:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 66c:	4981                	li	s3,0
 66e:	b721                	j	576 <vprintf+0x60>
        s = va_arg(ap, char*);
 670:	008b0993          	addi	s3,s6,8
 674:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 678:	02090163          	beqz	s2,69a <vprintf+0x184>
        while(*s != 0){
 67c:	00094583          	lbu	a1,0(s2)
 680:	c9a1                	beqz	a1,6d0 <vprintf+0x1ba>
          putc(fd, *s);
 682:	8556                	mv	a0,s5
 684:	00000097          	auipc	ra,0x0
 688:	dc6080e7          	jalr	-570(ra) # 44a <putc>
          s++;
 68c:	0905                	addi	s2,s2,1
        while(*s != 0){
 68e:	00094583          	lbu	a1,0(s2)
 692:	f9e5                	bnez	a1,682 <vprintf+0x16c>
        s = va_arg(ap, char*);
 694:	8b4e                	mv	s6,s3
      state = 0;
 696:	4981                	li	s3,0
 698:	bdf9                	j	576 <vprintf+0x60>
          s = "(null)";
 69a:	00000917          	auipc	s2,0x0
 69e:	27690913          	addi	s2,s2,630 # 910 <malloc+0x130>
        while(*s != 0){
 6a2:	02800593          	li	a1,40
 6a6:	bff1                	j	682 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6a8:	008b0913          	addi	s2,s6,8
 6ac:	000b4583          	lbu	a1,0(s6)
 6b0:	8556                	mv	a0,s5
 6b2:	00000097          	auipc	ra,0x0
 6b6:	d98080e7          	jalr	-616(ra) # 44a <putc>
 6ba:	8b4a                	mv	s6,s2
      state = 0;
 6bc:	4981                	li	s3,0
 6be:	bd65                	j	576 <vprintf+0x60>
        putc(fd, c);
 6c0:	85d2                	mv	a1,s4
 6c2:	8556                	mv	a0,s5
 6c4:	00000097          	auipc	ra,0x0
 6c8:	d86080e7          	jalr	-634(ra) # 44a <putc>
      state = 0;
 6cc:	4981                	li	s3,0
 6ce:	b565                	j	576 <vprintf+0x60>
        s = va_arg(ap, char*);
 6d0:	8b4e                	mv	s6,s3
      state = 0;
 6d2:	4981                	li	s3,0
 6d4:	b54d                	j	576 <vprintf+0x60>
    }
  }
}
 6d6:	70e6                	ld	ra,120(sp)
 6d8:	7446                	ld	s0,112(sp)
 6da:	74a6                	ld	s1,104(sp)
 6dc:	7906                	ld	s2,96(sp)
 6de:	69e6                	ld	s3,88(sp)
 6e0:	6a46                	ld	s4,80(sp)
 6e2:	6aa6                	ld	s5,72(sp)
 6e4:	6b06                	ld	s6,64(sp)
 6e6:	7be2                	ld	s7,56(sp)
 6e8:	7c42                	ld	s8,48(sp)
 6ea:	7ca2                	ld	s9,40(sp)
 6ec:	7d02                	ld	s10,32(sp)
 6ee:	6de2                	ld	s11,24(sp)
 6f0:	6109                	addi	sp,sp,128
 6f2:	8082                	ret

00000000000006f4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6f4:	715d                	addi	sp,sp,-80
 6f6:	ec06                	sd	ra,24(sp)
 6f8:	e822                	sd	s0,16(sp)
 6fa:	1000                	addi	s0,sp,32
 6fc:	e010                	sd	a2,0(s0)
 6fe:	e414                	sd	a3,8(s0)
 700:	e818                	sd	a4,16(s0)
 702:	ec1c                	sd	a5,24(s0)
 704:	03043023          	sd	a6,32(s0)
 708:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 70c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 710:	8622                	mv	a2,s0
 712:	00000097          	auipc	ra,0x0
 716:	e04080e7          	jalr	-508(ra) # 516 <vprintf>
}
 71a:	60e2                	ld	ra,24(sp)
 71c:	6442                	ld	s0,16(sp)
 71e:	6161                	addi	sp,sp,80
 720:	8082                	ret

0000000000000722 <printf>:

void
printf(const char *fmt, ...)
{
 722:	711d                	addi	sp,sp,-96
 724:	ec06                	sd	ra,24(sp)
 726:	e822                	sd	s0,16(sp)
 728:	1000                	addi	s0,sp,32
 72a:	e40c                	sd	a1,8(s0)
 72c:	e810                	sd	a2,16(s0)
 72e:	ec14                	sd	a3,24(s0)
 730:	f018                	sd	a4,32(s0)
 732:	f41c                	sd	a5,40(s0)
 734:	03043823          	sd	a6,48(s0)
 738:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 73c:	00840613          	addi	a2,s0,8
 740:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 744:	85aa                	mv	a1,a0
 746:	4505                	li	a0,1
 748:	00000097          	auipc	ra,0x0
 74c:	dce080e7          	jalr	-562(ra) # 516 <vprintf>
}
 750:	60e2                	ld	ra,24(sp)
 752:	6442                	ld	s0,16(sp)
 754:	6125                	addi	sp,sp,96
 756:	8082                	ret

0000000000000758 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 758:	1141                	addi	sp,sp,-16
 75a:	e422                	sd	s0,8(sp)
 75c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 75e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 762:	00000797          	auipc	a5,0x0
 766:	1ce7b783          	ld	a5,462(a5) # 930 <freep>
 76a:	a805                	j	79a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 76c:	4618                	lw	a4,8(a2)
 76e:	9db9                	addw	a1,a1,a4
 770:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 774:	6398                	ld	a4,0(a5)
 776:	6318                	ld	a4,0(a4)
 778:	fee53823          	sd	a4,-16(a0)
 77c:	a091                	j	7c0 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 77e:	ff852703          	lw	a4,-8(a0)
 782:	9e39                	addw	a2,a2,a4
 784:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 786:	ff053703          	ld	a4,-16(a0)
 78a:	e398                	sd	a4,0(a5)
 78c:	a099                	j	7d2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 78e:	6398                	ld	a4,0(a5)
 790:	00e7e463          	bltu	a5,a4,798 <free+0x40>
 794:	00e6ea63          	bltu	a3,a4,7a8 <free+0x50>
{
 798:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 79a:	fed7fae3          	bgeu	a5,a3,78e <free+0x36>
 79e:	6398                	ld	a4,0(a5)
 7a0:	00e6e463          	bltu	a3,a4,7a8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7a4:	fee7eae3          	bltu	a5,a4,798 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7a8:	ff852583          	lw	a1,-8(a0)
 7ac:	6390                	ld	a2,0(a5)
 7ae:	02059713          	slli	a4,a1,0x20
 7b2:	9301                	srli	a4,a4,0x20
 7b4:	0712                	slli	a4,a4,0x4
 7b6:	9736                	add	a4,a4,a3
 7b8:	fae60ae3          	beq	a2,a4,76c <free+0x14>
    bp->s.ptr = p->s.ptr;
 7bc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7c0:	4790                	lw	a2,8(a5)
 7c2:	02061713          	slli	a4,a2,0x20
 7c6:	9301                	srli	a4,a4,0x20
 7c8:	0712                	slli	a4,a4,0x4
 7ca:	973e                	add	a4,a4,a5
 7cc:	fae689e3          	beq	a3,a4,77e <free+0x26>
  } else
    p->s.ptr = bp;
 7d0:	e394                	sd	a3,0(a5)
  freep = p;
 7d2:	00000717          	auipc	a4,0x0
 7d6:	14f73f23          	sd	a5,350(a4) # 930 <freep>
}
 7da:	6422                	ld	s0,8(sp)
 7dc:	0141                	addi	sp,sp,16
 7de:	8082                	ret

00000000000007e0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7e0:	7139                	addi	sp,sp,-64
 7e2:	fc06                	sd	ra,56(sp)
 7e4:	f822                	sd	s0,48(sp)
 7e6:	f426                	sd	s1,40(sp)
 7e8:	f04a                	sd	s2,32(sp)
 7ea:	ec4e                	sd	s3,24(sp)
 7ec:	e852                	sd	s4,16(sp)
 7ee:	e456                	sd	s5,8(sp)
 7f0:	e05a                	sd	s6,0(sp)
 7f2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7f4:	02051493          	slli	s1,a0,0x20
 7f8:	9081                	srli	s1,s1,0x20
 7fa:	04bd                	addi	s1,s1,15
 7fc:	8091                	srli	s1,s1,0x4
 7fe:	0014899b          	addiw	s3,s1,1
 802:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 804:	00000517          	auipc	a0,0x0
 808:	12c53503          	ld	a0,300(a0) # 930 <freep>
 80c:	c515                	beqz	a0,838 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 80e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 810:	4798                	lw	a4,8(a5)
 812:	02977f63          	bgeu	a4,s1,850 <malloc+0x70>
 816:	8a4e                	mv	s4,s3
 818:	0009871b          	sext.w	a4,s3
 81c:	6685                	lui	a3,0x1
 81e:	00d77363          	bgeu	a4,a3,824 <malloc+0x44>
 822:	6a05                	lui	s4,0x1
 824:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 828:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 82c:	00000917          	auipc	s2,0x0
 830:	10490913          	addi	s2,s2,260 # 930 <freep>
  if(p == (char*)-1)
 834:	5afd                	li	s5,-1
 836:	a88d                	j	8a8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 838:	00000797          	auipc	a5,0x0
 83c:	10078793          	addi	a5,a5,256 # 938 <base>
 840:	00000717          	auipc	a4,0x0
 844:	0ef73823          	sd	a5,240(a4) # 930 <freep>
 848:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 84a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 84e:	b7e1                	j	816 <malloc+0x36>
      if(p->s.size == nunits)
 850:	02e48b63          	beq	s1,a4,886 <malloc+0xa6>
        p->s.size -= nunits;
 854:	4137073b          	subw	a4,a4,s3
 858:	c798                	sw	a4,8(a5)
        p += p->s.size;
 85a:	1702                	slli	a4,a4,0x20
 85c:	9301                	srli	a4,a4,0x20
 85e:	0712                	slli	a4,a4,0x4
 860:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 862:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 866:	00000717          	auipc	a4,0x0
 86a:	0ca73523          	sd	a0,202(a4) # 930 <freep>
      return (void*)(p + 1);
 86e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 872:	70e2                	ld	ra,56(sp)
 874:	7442                	ld	s0,48(sp)
 876:	74a2                	ld	s1,40(sp)
 878:	7902                	ld	s2,32(sp)
 87a:	69e2                	ld	s3,24(sp)
 87c:	6a42                	ld	s4,16(sp)
 87e:	6aa2                	ld	s5,8(sp)
 880:	6b02                	ld	s6,0(sp)
 882:	6121                	addi	sp,sp,64
 884:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 886:	6398                	ld	a4,0(a5)
 888:	e118                	sd	a4,0(a0)
 88a:	bff1                	j	866 <malloc+0x86>
  hp->s.size = nu;
 88c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 890:	0541                	addi	a0,a0,16
 892:	00000097          	auipc	ra,0x0
 896:	ec6080e7          	jalr	-314(ra) # 758 <free>
  return freep;
 89a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 89e:	d971                	beqz	a0,872 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8a2:	4798                	lw	a4,8(a5)
 8a4:	fa9776e3          	bgeu	a4,s1,850 <malloc+0x70>
    if(p == freep)
 8a8:	00093703          	ld	a4,0(s2)
 8ac:	853e                	mv	a0,a5
 8ae:	fef719e3          	bne	a4,a5,8a0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8b2:	8552                	mv	a0,s4
 8b4:	00000097          	auipc	ra,0x0
 8b8:	b66080e7          	jalr	-1178(ra) # 41a <sbrk>
  if(p == (char*)-1)
 8bc:	fd5518e3          	bne	a0,s5,88c <malloc+0xac>
        return 0;
 8c0:	4501                	li	a0,0
 8c2:	bf45                	j	872 <malloc+0x92>
