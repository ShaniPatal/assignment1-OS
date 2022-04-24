
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <env_large>:
//         }
//     }
//     printf("\n");
// }

void env_large(){
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	e852                	sd	s4,16(sp)
   e:	0080                	addi	s0,sp,64
  10:	4911                	li	s2,4

    int pid;
    int status;

    for (int i=0; i<4; i++) {
        if ((pid = fork()) == 0) {
  12:	00000097          	auipc	ra,0x0
  16:	2fe080e7          	jalr	766(ra) # 310 <fork>
  1a:	84aa                	mv	s1,a0
  1c:	c505                	beqz	a0,44 <env_large+0x44>
    for (int i=0; i<4; i++) {
  1e:	397d                	addiw	s2,s2,-1
  20:	fe0919e3          	bnez	s2,12 <env_large+0x12>
            }
            exit(0);
        }
    }

    while (wait(&status) > 0);
  24:	fcc40513          	addi	a0,s0,-52
  28:	00000097          	auipc	ra,0x0
  2c:	2f8080e7          	jalr	760(ra) # 320 <wait>
  30:	fea04ae3          	bgtz	a0,24 <env_large+0x24>
}   
  34:	70e2                	ld	ra,56(sp)
  36:	7442                	ld	s0,48(sp)
  38:	74a2                	ld	s1,40(sp)
  3a:	7902                	ld	s2,32(sp)
  3c:	69e2                	ld	s3,24(sp)
  3e:	6a42                	ld	s4,16(sp)
  40:	6121                	addi	sp,sp,64
  42:	8082                	ret
                if (i % 10000 == 0){
  44:	6989                	lui	s3,0x2
  46:	7109899b          	addiw	s3,s3,1808
                    printf("%d", i);
  4a:	00001a17          	auipc	s4,0x1
  4e:	806a0a13          	addi	s4,s4,-2042 # 850 <malloc+0xea>
            for (int i = 0; i <= 10000000; i++){
  52:	00989937          	lui	s2,0x989
  56:	68190913          	addi	s2,s2,1665 # 989681 <__global_pointer$+0x988610>
  5a:	a021                	j	62 <env_large+0x62>
  5c:	2485                	addiw	s1,s1,1
  5e:	01248c63          	beq	s1,s2,76 <env_large+0x76>
                if (i % 10000 == 0){
  62:	0334e7bb          	remw	a5,s1,s3
  66:	fbfd                	bnez	a5,5c <env_large+0x5c>
                    printf("%d", i);
  68:	85a6                	mv	a1,s1
  6a:	8552                	mv	a0,s4
  6c:	00000097          	auipc	ra,0x0
  70:	63c080e7          	jalr	1596(ra) # 6a8 <printf>
  74:	b7e5                	j	5c <env_large+0x5c>
            exit(0);
  76:	4501                	li	a0,0
  78:	00000097          	auipc	ra,0x0
  7c:	2a0080e7          	jalr	672(ra) # 318 <exit>

0000000000000080 <main>:
//     env(10e1, 10e1, "env_freq");
// }


int
main(int argc, char *argv[]){
  80:	1141                	addi	sp,sp,-16
  82:	e406                	sd	ra,8(sp)
  84:	e022                	sd	s0,0(sp)
  86:	0800                	addi	s0,sp,16
    env_large();
  88:	00000097          	auipc	ra,0x0
  8c:	f78080e7          	jalr	-136(ra) # 0 <env_large>
    // env_freq();
    print_stats();
  90:	00000097          	auipc	ra,0x0
  94:	338080e7          	jalr	824(ra) # 3c8 <print_stats>
   
    
    exit(0);
  98:	4501                	li	a0,0
  9a:	00000097          	auipc	ra,0x0
  9e:	27e080e7          	jalr	638(ra) # 318 <exit>

00000000000000a2 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  a2:	1141                	addi	sp,sp,-16
  a4:	e422                	sd	s0,8(sp)
  a6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  a8:	87aa                	mv	a5,a0
  aa:	0585                	addi	a1,a1,1
  ac:	0785                	addi	a5,a5,1
  ae:	fff5c703          	lbu	a4,-1(a1)
  b2:	fee78fa3          	sb	a4,-1(a5)
  b6:	fb75                	bnez	a4,aa <strcpy+0x8>
    ;
  return os;
}
  b8:	6422                	ld	s0,8(sp)
  ba:	0141                	addi	sp,sp,16
  bc:	8082                	ret

00000000000000be <strcmp>:

int
strcmp(const char *p, const char *q)
{
  be:	1141                	addi	sp,sp,-16
  c0:	e422                	sd	s0,8(sp)
  c2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  c4:	00054783          	lbu	a5,0(a0)
  c8:	cb91                	beqz	a5,dc <strcmp+0x1e>
  ca:	0005c703          	lbu	a4,0(a1)
  ce:	00f71763          	bne	a4,a5,dc <strcmp+0x1e>
    p++, q++;
  d2:	0505                	addi	a0,a0,1
  d4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  d6:	00054783          	lbu	a5,0(a0)
  da:	fbe5                	bnez	a5,ca <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  dc:	0005c503          	lbu	a0,0(a1)
}
  e0:	40a7853b          	subw	a0,a5,a0
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret

00000000000000ea <strlen>:

uint
strlen(const char *s)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	cf91                	beqz	a5,110 <strlen+0x26>
  f6:	0505                	addi	a0,a0,1
  f8:	87aa                	mv	a5,a0
  fa:	4685                	li	a3,1
  fc:	9e89                	subw	a3,a3,a0
  fe:	00f6853b          	addw	a0,a3,a5
 102:	0785                	addi	a5,a5,1
 104:	fff7c703          	lbu	a4,-1(a5)
 108:	fb7d                	bnez	a4,fe <strlen+0x14>
    ;
  return n;
}
 10a:	6422                	ld	s0,8(sp)
 10c:	0141                	addi	sp,sp,16
 10e:	8082                	ret
  for(n = 0; s[n]; n++)
 110:	4501                	li	a0,0
 112:	bfe5                	j	10a <strlen+0x20>

0000000000000114 <memset>:

void*
memset(void *dst, int c, uint n)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 11a:	ce09                	beqz	a2,134 <memset+0x20>
 11c:	87aa                	mv	a5,a0
 11e:	fff6071b          	addiw	a4,a2,-1
 122:	1702                	slli	a4,a4,0x20
 124:	9301                	srli	a4,a4,0x20
 126:	0705                	addi	a4,a4,1
 128:	972a                	add	a4,a4,a0
    cdst[i] = c;
 12a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 12e:	0785                	addi	a5,a5,1
 130:	fee79de3          	bne	a5,a4,12a <memset+0x16>
  }
  return dst;
}
 134:	6422                	ld	s0,8(sp)
 136:	0141                	addi	sp,sp,16
 138:	8082                	ret

000000000000013a <strchr>:

char*
strchr(const char *s, char c)
{
 13a:	1141                	addi	sp,sp,-16
 13c:	e422                	sd	s0,8(sp)
 13e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 140:	00054783          	lbu	a5,0(a0)
 144:	cb99                	beqz	a5,15a <strchr+0x20>
    if(*s == c)
 146:	00f58763          	beq	a1,a5,154 <strchr+0x1a>
  for(; *s; s++)
 14a:	0505                	addi	a0,a0,1
 14c:	00054783          	lbu	a5,0(a0)
 150:	fbfd                	bnez	a5,146 <strchr+0xc>
      return (char*)s;
  return 0;
 152:	4501                	li	a0,0
}
 154:	6422                	ld	s0,8(sp)
 156:	0141                	addi	sp,sp,16
 158:	8082                	ret
  return 0;
 15a:	4501                	li	a0,0
 15c:	bfe5                	j	154 <strchr+0x1a>

000000000000015e <gets>:

char*
gets(char *buf, int max)
{
 15e:	711d                	addi	sp,sp,-96
 160:	ec86                	sd	ra,88(sp)
 162:	e8a2                	sd	s0,80(sp)
 164:	e4a6                	sd	s1,72(sp)
 166:	e0ca                	sd	s2,64(sp)
 168:	fc4e                	sd	s3,56(sp)
 16a:	f852                	sd	s4,48(sp)
 16c:	f456                	sd	s5,40(sp)
 16e:	f05a                	sd	s6,32(sp)
 170:	ec5e                	sd	s7,24(sp)
 172:	1080                	addi	s0,sp,96
 174:	8baa                	mv	s7,a0
 176:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 178:	892a                	mv	s2,a0
 17a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 17c:	4aa9                	li	s5,10
 17e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 180:	89a6                	mv	s3,s1
 182:	2485                	addiw	s1,s1,1
 184:	0344d863          	bge	s1,s4,1b4 <gets+0x56>
    cc = read(0, &c, 1);
 188:	4605                	li	a2,1
 18a:	faf40593          	addi	a1,s0,-81
 18e:	4501                	li	a0,0
 190:	00000097          	auipc	ra,0x0
 194:	1a0080e7          	jalr	416(ra) # 330 <read>
    if(cc < 1)
 198:	00a05e63          	blez	a0,1b4 <gets+0x56>
    buf[i++] = c;
 19c:	faf44783          	lbu	a5,-81(s0)
 1a0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1a4:	01578763          	beq	a5,s5,1b2 <gets+0x54>
 1a8:	0905                	addi	s2,s2,1
 1aa:	fd679be3          	bne	a5,s6,180 <gets+0x22>
  for(i=0; i+1 < max; ){
 1ae:	89a6                	mv	s3,s1
 1b0:	a011                	j	1b4 <gets+0x56>
 1b2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1b4:	99de                	add	s3,s3,s7
 1b6:	00098023          	sb	zero,0(s3) # 2000 <__global_pointer$+0xf8f>
  return buf;
}
 1ba:	855e                	mv	a0,s7
 1bc:	60e6                	ld	ra,88(sp)
 1be:	6446                	ld	s0,80(sp)
 1c0:	64a6                	ld	s1,72(sp)
 1c2:	6906                	ld	s2,64(sp)
 1c4:	79e2                	ld	s3,56(sp)
 1c6:	7a42                	ld	s4,48(sp)
 1c8:	7aa2                	ld	s5,40(sp)
 1ca:	7b02                	ld	s6,32(sp)
 1cc:	6be2                	ld	s7,24(sp)
 1ce:	6125                	addi	sp,sp,96
 1d0:	8082                	ret

00000000000001d2 <stat>:

int
stat(const char *n, struct stat *st)
{
 1d2:	1101                	addi	sp,sp,-32
 1d4:	ec06                	sd	ra,24(sp)
 1d6:	e822                	sd	s0,16(sp)
 1d8:	e426                	sd	s1,8(sp)
 1da:	e04a                	sd	s2,0(sp)
 1dc:	1000                	addi	s0,sp,32
 1de:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1e0:	4581                	li	a1,0
 1e2:	00000097          	auipc	ra,0x0
 1e6:	176080e7          	jalr	374(ra) # 358 <open>
  if(fd < 0)
 1ea:	02054563          	bltz	a0,214 <stat+0x42>
 1ee:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1f0:	85ca                	mv	a1,s2
 1f2:	00000097          	auipc	ra,0x0
 1f6:	17e080e7          	jalr	382(ra) # 370 <fstat>
 1fa:	892a                	mv	s2,a0
  close(fd);
 1fc:	8526                	mv	a0,s1
 1fe:	00000097          	auipc	ra,0x0
 202:	142080e7          	jalr	322(ra) # 340 <close>
  return r;
}
 206:	854a                	mv	a0,s2
 208:	60e2                	ld	ra,24(sp)
 20a:	6442                	ld	s0,16(sp)
 20c:	64a2                	ld	s1,8(sp)
 20e:	6902                	ld	s2,0(sp)
 210:	6105                	addi	sp,sp,32
 212:	8082                	ret
    return -1;
 214:	597d                	li	s2,-1
 216:	bfc5                	j	206 <stat+0x34>

0000000000000218 <atoi>:

int
atoi(const char *s)
{
 218:	1141                	addi	sp,sp,-16
 21a:	e422                	sd	s0,8(sp)
 21c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 21e:	00054603          	lbu	a2,0(a0)
 222:	fd06079b          	addiw	a5,a2,-48
 226:	0ff7f793          	andi	a5,a5,255
 22a:	4725                	li	a4,9
 22c:	02f76963          	bltu	a4,a5,25e <atoi+0x46>
 230:	86aa                	mv	a3,a0
  n = 0;
 232:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 234:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 236:	0685                	addi	a3,a3,1
 238:	0025179b          	slliw	a5,a0,0x2
 23c:	9fa9                	addw	a5,a5,a0
 23e:	0017979b          	slliw	a5,a5,0x1
 242:	9fb1                	addw	a5,a5,a2
 244:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 248:	0006c603          	lbu	a2,0(a3)
 24c:	fd06071b          	addiw	a4,a2,-48
 250:	0ff77713          	andi	a4,a4,255
 254:	fee5f1e3          	bgeu	a1,a4,236 <atoi+0x1e>
  return n;
}
 258:	6422                	ld	s0,8(sp)
 25a:	0141                	addi	sp,sp,16
 25c:	8082                	ret
  n = 0;
 25e:	4501                	li	a0,0
 260:	bfe5                	j	258 <atoi+0x40>

0000000000000262 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 268:	02b57663          	bgeu	a0,a1,294 <memmove+0x32>
    while(n-- > 0)
 26c:	02c05163          	blez	a2,28e <memmove+0x2c>
 270:	fff6079b          	addiw	a5,a2,-1
 274:	1782                	slli	a5,a5,0x20
 276:	9381                	srli	a5,a5,0x20
 278:	0785                	addi	a5,a5,1
 27a:	97aa                	add	a5,a5,a0
  dst = vdst;
 27c:	872a                	mv	a4,a0
      *dst++ = *src++;
 27e:	0585                	addi	a1,a1,1
 280:	0705                	addi	a4,a4,1
 282:	fff5c683          	lbu	a3,-1(a1)
 286:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 28a:	fee79ae3          	bne	a5,a4,27e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 28e:	6422                	ld	s0,8(sp)
 290:	0141                	addi	sp,sp,16
 292:	8082                	ret
    dst += n;
 294:	00c50733          	add	a4,a0,a2
    src += n;
 298:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 29a:	fec05ae3          	blez	a2,28e <memmove+0x2c>
 29e:	fff6079b          	addiw	a5,a2,-1
 2a2:	1782                	slli	a5,a5,0x20
 2a4:	9381                	srli	a5,a5,0x20
 2a6:	fff7c793          	not	a5,a5
 2aa:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2ac:	15fd                	addi	a1,a1,-1
 2ae:	177d                	addi	a4,a4,-1
 2b0:	0005c683          	lbu	a3,0(a1)
 2b4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2b8:	fee79ae3          	bne	a5,a4,2ac <memmove+0x4a>
 2bc:	bfc9                	j	28e <memmove+0x2c>

00000000000002be <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2be:	1141                	addi	sp,sp,-16
 2c0:	e422                	sd	s0,8(sp)
 2c2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2c4:	ca05                	beqz	a2,2f4 <memcmp+0x36>
 2c6:	fff6069b          	addiw	a3,a2,-1
 2ca:	1682                	slli	a3,a3,0x20
 2cc:	9281                	srli	a3,a3,0x20
 2ce:	0685                	addi	a3,a3,1
 2d0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2d2:	00054783          	lbu	a5,0(a0)
 2d6:	0005c703          	lbu	a4,0(a1)
 2da:	00e79863          	bne	a5,a4,2ea <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2de:	0505                	addi	a0,a0,1
    p2++;
 2e0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2e2:	fed518e3          	bne	a0,a3,2d2 <memcmp+0x14>
  }
  return 0;
 2e6:	4501                	li	a0,0
 2e8:	a019                	j	2ee <memcmp+0x30>
      return *p1 - *p2;
 2ea:	40e7853b          	subw	a0,a5,a4
}
 2ee:	6422                	ld	s0,8(sp)
 2f0:	0141                	addi	sp,sp,16
 2f2:	8082                	ret
  return 0;
 2f4:	4501                	li	a0,0
 2f6:	bfe5                	j	2ee <memcmp+0x30>

00000000000002f8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2f8:	1141                	addi	sp,sp,-16
 2fa:	e406                	sd	ra,8(sp)
 2fc:	e022                	sd	s0,0(sp)
 2fe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 300:	00000097          	auipc	ra,0x0
 304:	f62080e7          	jalr	-158(ra) # 262 <memmove>
}
 308:	60a2                	ld	ra,8(sp)
 30a:	6402                	ld	s0,0(sp)
 30c:	0141                	addi	sp,sp,16
 30e:	8082                	ret

0000000000000310 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 310:	4885                	li	a7,1
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <exit>:
.global exit
exit:
 li a7, SYS_exit
 318:	4889                	li	a7,2
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <wait>:
.global wait
wait:
 li a7, SYS_wait
 320:	488d                	li	a7,3
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 328:	4891                	li	a7,4
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <read>:
.global read
read:
 li a7, SYS_read
 330:	4895                	li	a7,5
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <write>:
.global write
write:
 li a7, SYS_write
 338:	48c1                	li	a7,16
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <close>:
.global close
close:
 li a7, SYS_close
 340:	48d5                	li	a7,21
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <kill>:
.global kill
kill:
 li a7, SYS_kill
 348:	4899                	li	a7,6
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <exec>:
.global exec
exec:
 li a7, SYS_exec
 350:	489d                	li	a7,7
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <open>:
.global open
open:
 li a7, SYS_open
 358:	48bd                	li	a7,15
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 360:	48c5                	li	a7,17
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 368:	48c9                	li	a7,18
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 370:	48a1                	li	a7,8
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <link>:
.global link
link:
 li a7, SYS_link
 378:	48cd                	li	a7,19
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 380:	48d1                	li	a7,20
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 388:	48a5                	li	a7,9
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <dup>:
.global dup
dup:
 li a7, SYS_dup
 390:	48a9                	li	a7,10
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 398:	48ad                	li	a7,11
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3a0:	48b1                	li	a7,12
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3a8:	48b5                	li	a7,13
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3b0:	48b9                	li	a7,14
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 3b8:	48d9                	li	a7,22
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 3c0:	48dd                	li	a7,23
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 3c8:	48e1                	li	a7,24
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3d0:	1101                	addi	sp,sp,-32
 3d2:	ec06                	sd	ra,24(sp)
 3d4:	e822                	sd	s0,16(sp)
 3d6:	1000                	addi	s0,sp,32
 3d8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3dc:	4605                	li	a2,1
 3de:	fef40593          	addi	a1,s0,-17
 3e2:	00000097          	auipc	ra,0x0
 3e6:	f56080e7          	jalr	-170(ra) # 338 <write>
}
 3ea:	60e2                	ld	ra,24(sp)
 3ec:	6442                	ld	s0,16(sp)
 3ee:	6105                	addi	sp,sp,32
 3f0:	8082                	ret

00000000000003f2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3f2:	7139                	addi	sp,sp,-64
 3f4:	fc06                	sd	ra,56(sp)
 3f6:	f822                	sd	s0,48(sp)
 3f8:	f426                	sd	s1,40(sp)
 3fa:	f04a                	sd	s2,32(sp)
 3fc:	ec4e                	sd	s3,24(sp)
 3fe:	0080                	addi	s0,sp,64
 400:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 402:	c299                	beqz	a3,408 <printint+0x16>
 404:	0805c863          	bltz	a1,494 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 408:	2581                	sext.w	a1,a1
  neg = 0;
 40a:	4881                	li	a7,0
 40c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 410:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 412:	2601                	sext.w	a2,a2
 414:	00000517          	auipc	a0,0x0
 418:	44c50513          	addi	a0,a0,1100 # 860 <digits>
 41c:	883a                	mv	a6,a4
 41e:	2705                	addiw	a4,a4,1
 420:	02c5f7bb          	remuw	a5,a1,a2
 424:	1782                	slli	a5,a5,0x20
 426:	9381                	srli	a5,a5,0x20
 428:	97aa                	add	a5,a5,a0
 42a:	0007c783          	lbu	a5,0(a5)
 42e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 432:	0005879b          	sext.w	a5,a1
 436:	02c5d5bb          	divuw	a1,a1,a2
 43a:	0685                	addi	a3,a3,1
 43c:	fec7f0e3          	bgeu	a5,a2,41c <printint+0x2a>
  if(neg)
 440:	00088b63          	beqz	a7,456 <printint+0x64>
    buf[i++] = '-';
 444:	fd040793          	addi	a5,s0,-48
 448:	973e                	add	a4,a4,a5
 44a:	02d00793          	li	a5,45
 44e:	fef70823          	sb	a5,-16(a4)
 452:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 456:	02e05863          	blez	a4,486 <printint+0x94>
 45a:	fc040793          	addi	a5,s0,-64
 45e:	00e78933          	add	s2,a5,a4
 462:	fff78993          	addi	s3,a5,-1
 466:	99ba                	add	s3,s3,a4
 468:	377d                	addiw	a4,a4,-1
 46a:	1702                	slli	a4,a4,0x20
 46c:	9301                	srli	a4,a4,0x20
 46e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 472:	fff94583          	lbu	a1,-1(s2)
 476:	8526                	mv	a0,s1
 478:	00000097          	auipc	ra,0x0
 47c:	f58080e7          	jalr	-168(ra) # 3d0 <putc>
  while(--i >= 0)
 480:	197d                	addi	s2,s2,-1
 482:	ff3918e3          	bne	s2,s3,472 <printint+0x80>
}
 486:	70e2                	ld	ra,56(sp)
 488:	7442                	ld	s0,48(sp)
 48a:	74a2                	ld	s1,40(sp)
 48c:	7902                	ld	s2,32(sp)
 48e:	69e2                	ld	s3,24(sp)
 490:	6121                	addi	sp,sp,64
 492:	8082                	ret
    x = -xx;
 494:	40b005bb          	negw	a1,a1
    neg = 1;
 498:	4885                	li	a7,1
    x = -xx;
 49a:	bf8d                	j	40c <printint+0x1a>

000000000000049c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 49c:	7119                	addi	sp,sp,-128
 49e:	fc86                	sd	ra,120(sp)
 4a0:	f8a2                	sd	s0,112(sp)
 4a2:	f4a6                	sd	s1,104(sp)
 4a4:	f0ca                	sd	s2,96(sp)
 4a6:	ecce                	sd	s3,88(sp)
 4a8:	e8d2                	sd	s4,80(sp)
 4aa:	e4d6                	sd	s5,72(sp)
 4ac:	e0da                	sd	s6,64(sp)
 4ae:	fc5e                	sd	s7,56(sp)
 4b0:	f862                	sd	s8,48(sp)
 4b2:	f466                	sd	s9,40(sp)
 4b4:	f06a                	sd	s10,32(sp)
 4b6:	ec6e                	sd	s11,24(sp)
 4b8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ba:	0005c903          	lbu	s2,0(a1)
 4be:	18090f63          	beqz	s2,65c <vprintf+0x1c0>
 4c2:	8aaa                	mv	s5,a0
 4c4:	8b32                	mv	s6,a2
 4c6:	00158493          	addi	s1,a1,1
  state = 0;
 4ca:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4cc:	02500a13          	li	s4,37
      if(c == 'd'){
 4d0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4d4:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4d8:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4dc:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4e0:	00000b97          	auipc	s7,0x0
 4e4:	380b8b93          	addi	s7,s7,896 # 860 <digits>
 4e8:	a839                	j	506 <vprintf+0x6a>
        putc(fd, c);
 4ea:	85ca                	mv	a1,s2
 4ec:	8556                	mv	a0,s5
 4ee:	00000097          	auipc	ra,0x0
 4f2:	ee2080e7          	jalr	-286(ra) # 3d0 <putc>
 4f6:	a019                	j	4fc <vprintf+0x60>
    } else if(state == '%'){
 4f8:	01498f63          	beq	s3,s4,516 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4fc:	0485                	addi	s1,s1,1
 4fe:	fff4c903          	lbu	s2,-1(s1)
 502:	14090d63          	beqz	s2,65c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 506:	0009079b          	sext.w	a5,s2
    if(state == 0){
 50a:	fe0997e3          	bnez	s3,4f8 <vprintf+0x5c>
      if(c == '%'){
 50e:	fd479ee3          	bne	a5,s4,4ea <vprintf+0x4e>
        state = '%';
 512:	89be                	mv	s3,a5
 514:	b7e5                	j	4fc <vprintf+0x60>
      if(c == 'd'){
 516:	05878063          	beq	a5,s8,556 <vprintf+0xba>
      } else if(c == 'l') {
 51a:	05978c63          	beq	a5,s9,572 <vprintf+0xd6>
      } else if(c == 'x') {
 51e:	07a78863          	beq	a5,s10,58e <vprintf+0xf2>
      } else if(c == 'p') {
 522:	09b78463          	beq	a5,s11,5aa <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 526:	07300713          	li	a4,115
 52a:	0ce78663          	beq	a5,a4,5f6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 52e:	06300713          	li	a4,99
 532:	0ee78e63          	beq	a5,a4,62e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 536:	11478863          	beq	a5,s4,646 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 53a:	85d2                	mv	a1,s4
 53c:	8556                	mv	a0,s5
 53e:	00000097          	auipc	ra,0x0
 542:	e92080e7          	jalr	-366(ra) # 3d0 <putc>
        putc(fd, c);
 546:	85ca                	mv	a1,s2
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	e86080e7          	jalr	-378(ra) # 3d0 <putc>
      }
      state = 0;
 552:	4981                	li	s3,0
 554:	b765                	j	4fc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 556:	008b0913          	addi	s2,s6,8
 55a:	4685                	li	a3,1
 55c:	4629                	li	a2,10
 55e:	000b2583          	lw	a1,0(s6)
 562:	8556                	mv	a0,s5
 564:	00000097          	auipc	ra,0x0
 568:	e8e080e7          	jalr	-370(ra) # 3f2 <printint>
 56c:	8b4a                	mv	s6,s2
      state = 0;
 56e:	4981                	li	s3,0
 570:	b771                	j	4fc <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 572:	008b0913          	addi	s2,s6,8
 576:	4681                	li	a3,0
 578:	4629                	li	a2,10
 57a:	000b2583          	lw	a1,0(s6)
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	e72080e7          	jalr	-398(ra) # 3f2 <printint>
 588:	8b4a                	mv	s6,s2
      state = 0;
 58a:	4981                	li	s3,0
 58c:	bf85                	j	4fc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 58e:	008b0913          	addi	s2,s6,8
 592:	4681                	li	a3,0
 594:	4641                	li	a2,16
 596:	000b2583          	lw	a1,0(s6)
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	e56080e7          	jalr	-426(ra) # 3f2 <printint>
 5a4:	8b4a                	mv	s6,s2
      state = 0;
 5a6:	4981                	li	s3,0
 5a8:	bf91                	j	4fc <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5aa:	008b0793          	addi	a5,s6,8
 5ae:	f8f43423          	sd	a5,-120(s0)
 5b2:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5b6:	03000593          	li	a1,48
 5ba:	8556                	mv	a0,s5
 5bc:	00000097          	auipc	ra,0x0
 5c0:	e14080e7          	jalr	-492(ra) # 3d0 <putc>
  putc(fd, 'x');
 5c4:	85ea                	mv	a1,s10
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	e08080e7          	jalr	-504(ra) # 3d0 <putc>
 5d0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5d2:	03c9d793          	srli	a5,s3,0x3c
 5d6:	97de                	add	a5,a5,s7
 5d8:	0007c583          	lbu	a1,0(a5)
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	df2080e7          	jalr	-526(ra) # 3d0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5e6:	0992                	slli	s3,s3,0x4
 5e8:	397d                	addiw	s2,s2,-1
 5ea:	fe0914e3          	bnez	s2,5d2 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5ee:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	b721                	j	4fc <vprintf+0x60>
        s = va_arg(ap, char*);
 5f6:	008b0993          	addi	s3,s6,8
 5fa:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5fe:	02090163          	beqz	s2,620 <vprintf+0x184>
        while(*s != 0){
 602:	00094583          	lbu	a1,0(s2)
 606:	c9a1                	beqz	a1,656 <vprintf+0x1ba>
          putc(fd, *s);
 608:	8556                	mv	a0,s5
 60a:	00000097          	auipc	ra,0x0
 60e:	dc6080e7          	jalr	-570(ra) # 3d0 <putc>
          s++;
 612:	0905                	addi	s2,s2,1
        while(*s != 0){
 614:	00094583          	lbu	a1,0(s2)
 618:	f9e5                	bnez	a1,608 <vprintf+0x16c>
        s = va_arg(ap, char*);
 61a:	8b4e                	mv	s6,s3
      state = 0;
 61c:	4981                	li	s3,0
 61e:	bdf9                	j	4fc <vprintf+0x60>
          s = "(null)";
 620:	00000917          	auipc	s2,0x0
 624:	23890913          	addi	s2,s2,568 # 858 <malloc+0xf2>
        while(*s != 0){
 628:	02800593          	li	a1,40
 62c:	bff1                	j	608 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 62e:	008b0913          	addi	s2,s6,8
 632:	000b4583          	lbu	a1,0(s6)
 636:	8556                	mv	a0,s5
 638:	00000097          	auipc	ra,0x0
 63c:	d98080e7          	jalr	-616(ra) # 3d0 <putc>
 640:	8b4a                	mv	s6,s2
      state = 0;
 642:	4981                	li	s3,0
 644:	bd65                	j	4fc <vprintf+0x60>
        putc(fd, c);
 646:	85d2                	mv	a1,s4
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	d86080e7          	jalr	-634(ra) # 3d0 <putc>
      state = 0;
 652:	4981                	li	s3,0
 654:	b565                	j	4fc <vprintf+0x60>
        s = va_arg(ap, char*);
 656:	8b4e                	mv	s6,s3
      state = 0;
 658:	4981                	li	s3,0
 65a:	b54d                	j	4fc <vprintf+0x60>
    }
  }
}
 65c:	70e6                	ld	ra,120(sp)
 65e:	7446                	ld	s0,112(sp)
 660:	74a6                	ld	s1,104(sp)
 662:	7906                	ld	s2,96(sp)
 664:	69e6                	ld	s3,88(sp)
 666:	6a46                	ld	s4,80(sp)
 668:	6aa6                	ld	s5,72(sp)
 66a:	6b06                	ld	s6,64(sp)
 66c:	7be2                	ld	s7,56(sp)
 66e:	7c42                	ld	s8,48(sp)
 670:	7ca2                	ld	s9,40(sp)
 672:	7d02                	ld	s10,32(sp)
 674:	6de2                	ld	s11,24(sp)
 676:	6109                	addi	sp,sp,128
 678:	8082                	ret

000000000000067a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 67a:	715d                	addi	sp,sp,-80
 67c:	ec06                	sd	ra,24(sp)
 67e:	e822                	sd	s0,16(sp)
 680:	1000                	addi	s0,sp,32
 682:	e010                	sd	a2,0(s0)
 684:	e414                	sd	a3,8(s0)
 686:	e818                	sd	a4,16(s0)
 688:	ec1c                	sd	a5,24(s0)
 68a:	03043023          	sd	a6,32(s0)
 68e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 692:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 696:	8622                	mv	a2,s0
 698:	00000097          	auipc	ra,0x0
 69c:	e04080e7          	jalr	-508(ra) # 49c <vprintf>
}
 6a0:	60e2                	ld	ra,24(sp)
 6a2:	6442                	ld	s0,16(sp)
 6a4:	6161                	addi	sp,sp,80
 6a6:	8082                	ret

00000000000006a8 <printf>:

void
printf(const char *fmt, ...)
{
 6a8:	711d                	addi	sp,sp,-96
 6aa:	ec06                	sd	ra,24(sp)
 6ac:	e822                	sd	s0,16(sp)
 6ae:	1000                	addi	s0,sp,32
 6b0:	e40c                	sd	a1,8(s0)
 6b2:	e810                	sd	a2,16(s0)
 6b4:	ec14                	sd	a3,24(s0)
 6b6:	f018                	sd	a4,32(s0)
 6b8:	f41c                	sd	a5,40(s0)
 6ba:	03043823          	sd	a6,48(s0)
 6be:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6c2:	00840613          	addi	a2,s0,8
 6c6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ca:	85aa                	mv	a1,a0
 6cc:	4505                	li	a0,1
 6ce:	00000097          	auipc	ra,0x0
 6d2:	dce080e7          	jalr	-562(ra) # 49c <vprintf>
}
 6d6:	60e2                	ld	ra,24(sp)
 6d8:	6442                	ld	s0,16(sp)
 6da:	6125                	addi	sp,sp,96
 6dc:	8082                	ret

00000000000006de <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6de:	1141                	addi	sp,sp,-16
 6e0:	e422                	sd	s0,8(sp)
 6e2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6e4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e8:	00000797          	auipc	a5,0x0
 6ec:	1907b783          	ld	a5,400(a5) # 878 <freep>
 6f0:	a805                	j	720 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6f2:	4618                	lw	a4,8(a2)
 6f4:	9db9                	addw	a1,a1,a4
 6f6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6fa:	6398                	ld	a4,0(a5)
 6fc:	6318                	ld	a4,0(a4)
 6fe:	fee53823          	sd	a4,-16(a0)
 702:	a091                	j	746 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 704:	ff852703          	lw	a4,-8(a0)
 708:	9e39                	addw	a2,a2,a4
 70a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 70c:	ff053703          	ld	a4,-16(a0)
 710:	e398                	sd	a4,0(a5)
 712:	a099                	j	758 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 714:	6398                	ld	a4,0(a5)
 716:	00e7e463          	bltu	a5,a4,71e <free+0x40>
 71a:	00e6ea63          	bltu	a3,a4,72e <free+0x50>
{
 71e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 720:	fed7fae3          	bgeu	a5,a3,714 <free+0x36>
 724:	6398                	ld	a4,0(a5)
 726:	00e6e463          	bltu	a3,a4,72e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72a:	fee7eae3          	bltu	a5,a4,71e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 72e:	ff852583          	lw	a1,-8(a0)
 732:	6390                	ld	a2,0(a5)
 734:	02059713          	slli	a4,a1,0x20
 738:	9301                	srli	a4,a4,0x20
 73a:	0712                	slli	a4,a4,0x4
 73c:	9736                	add	a4,a4,a3
 73e:	fae60ae3          	beq	a2,a4,6f2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 742:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 746:	4790                	lw	a2,8(a5)
 748:	02061713          	slli	a4,a2,0x20
 74c:	9301                	srli	a4,a4,0x20
 74e:	0712                	slli	a4,a4,0x4
 750:	973e                	add	a4,a4,a5
 752:	fae689e3          	beq	a3,a4,704 <free+0x26>
  } else
    p->s.ptr = bp;
 756:	e394                	sd	a3,0(a5)
  freep = p;
 758:	00000717          	auipc	a4,0x0
 75c:	12f73023          	sd	a5,288(a4) # 878 <freep>
}
 760:	6422                	ld	s0,8(sp)
 762:	0141                	addi	sp,sp,16
 764:	8082                	ret

0000000000000766 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 766:	7139                	addi	sp,sp,-64
 768:	fc06                	sd	ra,56(sp)
 76a:	f822                	sd	s0,48(sp)
 76c:	f426                	sd	s1,40(sp)
 76e:	f04a                	sd	s2,32(sp)
 770:	ec4e                	sd	s3,24(sp)
 772:	e852                	sd	s4,16(sp)
 774:	e456                	sd	s5,8(sp)
 776:	e05a                	sd	s6,0(sp)
 778:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 77a:	02051493          	slli	s1,a0,0x20
 77e:	9081                	srli	s1,s1,0x20
 780:	04bd                	addi	s1,s1,15
 782:	8091                	srli	s1,s1,0x4
 784:	0014899b          	addiw	s3,s1,1
 788:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 78a:	00000517          	auipc	a0,0x0
 78e:	0ee53503          	ld	a0,238(a0) # 878 <freep>
 792:	c515                	beqz	a0,7be <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 794:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 796:	4798                	lw	a4,8(a5)
 798:	02977f63          	bgeu	a4,s1,7d6 <malloc+0x70>
 79c:	8a4e                	mv	s4,s3
 79e:	0009871b          	sext.w	a4,s3
 7a2:	6685                	lui	a3,0x1
 7a4:	00d77363          	bgeu	a4,a3,7aa <malloc+0x44>
 7a8:	6a05                	lui	s4,0x1
 7aa:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7ae:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b2:	00000917          	auipc	s2,0x0
 7b6:	0c690913          	addi	s2,s2,198 # 878 <freep>
  if(p == (char*)-1)
 7ba:	5afd                	li	s5,-1
 7bc:	a88d                	j	82e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7be:	00000797          	auipc	a5,0x0
 7c2:	0c278793          	addi	a5,a5,194 # 880 <base>
 7c6:	00000717          	auipc	a4,0x0
 7ca:	0af73923          	sd	a5,178(a4) # 878 <freep>
 7ce:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7d0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7d4:	b7e1                	j	79c <malloc+0x36>
      if(p->s.size == nunits)
 7d6:	02e48b63          	beq	s1,a4,80c <malloc+0xa6>
        p->s.size -= nunits;
 7da:	4137073b          	subw	a4,a4,s3
 7de:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7e0:	1702                	slli	a4,a4,0x20
 7e2:	9301                	srli	a4,a4,0x20
 7e4:	0712                	slli	a4,a4,0x4
 7e6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7e8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7ec:	00000717          	auipc	a4,0x0
 7f0:	08a73623          	sd	a0,140(a4) # 878 <freep>
      return (void*)(p + 1);
 7f4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7f8:	70e2                	ld	ra,56(sp)
 7fa:	7442                	ld	s0,48(sp)
 7fc:	74a2                	ld	s1,40(sp)
 7fe:	7902                	ld	s2,32(sp)
 800:	69e2                	ld	s3,24(sp)
 802:	6a42                	ld	s4,16(sp)
 804:	6aa2                	ld	s5,8(sp)
 806:	6b02                	ld	s6,0(sp)
 808:	6121                	addi	sp,sp,64
 80a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 80c:	6398                	ld	a4,0(a5)
 80e:	e118                	sd	a4,0(a0)
 810:	bff1                	j	7ec <malloc+0x86>
  hp->s.size = nu;
 812:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 816:	0541                	addi	a0,a0,16
 818:	00000097          	auipc	ra,0x0
 81c:	ec6080e7          	jalr	-314(ra) # 6de <free>
  return freep;
 820:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 824:	d971                	beqz	a0,7f8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 826:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 828:	4798                	lw	a4,8(a5)
 82a:	fa9776e3          	bgeu	a4,s1,7d6 <malloc+0x70>
    if(p == freep)
 82e:	00093703          	ld	a4,0(s2)
 832:	853e                	mv	a0,a5
 834:	fef719e3          	bne	a4,a5,826 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 838:	8552                	mv	a0,s4
 83a:	00000097          	auipc	ra,0x0
 83e:	b66080e7          	jalr	-1178(ra) # 3a0 <sbrk>
  if(p == (char*)-1)
 842:	fd5518e3          	bne	a0,s5,812 <malloc+0xac>
        return 0;
 846:	4501                	li	a0,0
 848:	bf45                	j	7f8 <malloc+0x92>
