
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	95013103          	ld	sp,-1712(sp) # 80008950 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	15c78793          	addi	a5,a5,348 # 800061c0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdf7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8d6080e7          	jalr	-1834(ra) # 80002a02 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	0000a517          	auipc	a0,0xa
    80000190:	f0450513          	addi	a0,a0,-252 # 8000a090 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ef448493          	addi	s1,s1,-268 # 8000a090 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f8290913          	addi	s2,s2,-126 # 8000a128 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	804080e7          	jalr	-2044(ra) # 800019c8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	260080e7          	jalr	608(ra) # 80002434 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	79c080e7          	jalr	1948(ra) # 800029ac <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	0000a517          	auipc	a0,0xa
    80000228:	e6c50513          	addi	a0,a0,-404 # 8000a090 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e5650513          	addi	a0,a0,-426 # 8000a090 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	0000a717          	auipc	a4,0xa
    80000276:	eaf72b23          	sw	a5,-330(a4) # 8000a128 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	0000a517          	auipc	a0,0xa
    800002d0:	dc450513          	addi	a0,a0,-572 # 8000a090 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	766080e7          	jalr	1894(ra) # 80002a58 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d9650513          	addi	a0,a0,-618 # 8000a090 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	0000a717          	auipc	a4,0xa
    80000322:	d7270713          	addi	a4,a4,-654 # 8000a090 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	0000a797          	auipc	a5,0xa
    8000034c:	d4878793          	addi	a5,a5,-696 # 8000a090 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	0000a797          	auipc	a5,0xa
    8000037a:	db27a783          	lw	a5,-590(a5) # 8000a128 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	d0670713          	addi	a4,a4,-762 # 8000a090 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cf648493          	addi	s1,s1,-778 # 8000a090 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	0000a717          	auipc	a4,0xa
    800003da:	cba70713          	addi	a4,a4,-838 # 8000a090 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d4f72223          	sw	a5,-700(a4) # 8000a130 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	0000a797          	auipc	a5,0xa
    80000416:	c7e78793          	addi	a5,a5,-898 # 8000a090 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	0000a797          	auipc	a5,0xa
    8000043a:	cec7ab23          	sw	a2,-778(a5) # 8000a12c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cea50513          	addi	a0,a0,-790 # 8000a128 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	196080e7          	jalr	406(ra) # 800025dc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	0000a517          	auipc	a0,0xa
    80000464:	c3050513          	addi	a0,a0,-976 # 8000a090 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	23078793          	addi	a5,a5,560 # 8001a6a8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	0000a797          	auipc	a5,0xa
    8000054e:	c007a323          	sw	zero,-1018(a5) # 8000a150 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	df450513          	addi	a0,a0,-524 # 80008360 <digits+0x320>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	0000ad97          	auipc	s11,0xa
    800005be:	b96dad83          	lw	s11,-1130(s11) # 8000a150 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	0000a517          	auipc	a0,0xa
    800005fc:	b4050513          	addi	a0,a0,-1216 # 8000a138 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	0000a517          	auipc	a0,0xa
    80000760:	9dc50513          	addi	a0,a0,-1572 # 8000a138 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	0000a497          	auipc	s1,0xa
    8000077c:	9c048493          	addi	s1,s1,-1600 # 8000a138 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	0000a517          	auipc	a0,0xa
    800007dc:	98050513          	addi	a0,a0,-1664 # 8000a158 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	0000aa17          	auipc	s4,0xa
    8000086e:	8eea0a13          	addi	s4,s4,-1810 # 8000a158 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	d3c080e7          	jalr	-708(ra) # 800025dc <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	0000a517          	auipc	a0,0xa
    800008e0:	87c50513          	addi	a0,a0,-1924 # 8000a158 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	0000aa17          	auipc	s4,0xa
    80000914:	848a0a13          	addi	s4,s4,-1976 # 8000a158 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	b08080e7          	jalr	-1272(ra) # 80002434 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	0000a497          	auipc	s1,0xa
    80000946:	81648493          	addi	s1,s1,-2026 # 8000a158 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00009497          	auipc	s1,0x9
    800009ce:	78e48493          	addi	s1,s1,1934 # 8000a158 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	0001e797          	auipc	a5,0x1e
    80000a10:	5f478793          	addi	a5,a5,1524 # 8001f000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00009917          	auipc	s2,0x9
    80000a30:	76490913          	addi	s2,s2,1892 # 8000a190 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00009517          	auipc	a0,0x9
    80000acc:	6c850513          	addi	a0,a0,1736 # 8000a190 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001e517          	auipc	a0,0x1e
    80000ae0:	52450513          	addi	a0,a0,1316 # 8001f000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00009497          	auipc	s1,0x9
    80000b02:	69248493          	addi	s1,s1,1682 # 8000a190 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00009517          	auipc	a0,0x9
    80000b1a:	67a50513          	addi	a0,a0,1658 # 8000a190 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00009517          	auipc	a0,0x9
    80000b46:	64e50513          	addi	a0,a0,1614 # 8000a190 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e2e080e7          	jalr	-466(ra) # 800019ac <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	dfc080e7          	jalr	-516(ra) # 800019ac <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df0080e7          	jalr	-528(ra) # 800019ac <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dd8080e7          	jalr	-552(ra) # 800019ac <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d98080e7          	jalr	-616(ra) # 800019ac <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d6c080e7          	jalr	-660(ra) # 800019ac <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b06080e7          	jalr	-1274(ra) # 8000199c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	aea080e7          	jalr	-1302(ra) # 8000199c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	d9a080e7          	jalr	-614(ra) # 80002c6e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	324080e7          	jalr	804(ra) # 80006200 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	412080e7          	jalr	1042(ra) # 800022f6 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	45c50513          	addi	a0,a0,1116 # 80008360 <digits+0x320>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	43c50513          	addi	a0,a0,1084 # 80008360 <digits+0x320>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	990080e7          	jalr	-1648(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cf2080e7          	jalr	-782(ra) # 80002c46 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	d12080e7          	jalr	-750(ra) # 80002c6e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	286080e7          	jalr	646(ra) # 800061ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	294080e7          	jalr	660(ra) # 80006200 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	472080e7          	jalr	1138(ra) # 800033e6 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	b02080e7          	jalr	-1278(ra) # 80003a7e <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	aac080e7          	jalr	-1364(ra) # 80004a30 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	396080e7          	jalr	918(ra) # 80006322 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d20080e7          	jalr	-736(ra) # 80001cb4 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	5fe080e7          	jalr	1534(ra) # 80001846 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00009497          	auipc	s1,0x9
    80001860:	a0448493          	addi	s1,s1,-1532 # 8000a260 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	0000fa17          	auipc	s4,0xf
    8000187a:	beaa0a13          	addi	s4,s4,-1046 # 80010460 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	18848493          	addi	s1,s1,392
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
  }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f0:	00007597          	auipc	a1,0x7
    800018f4:	8f058593          	addi	a1,a1,-1808 # 800081e0 <digits+0x1a0>
    800018f8:	00009517          	auipc	a0,0x9
    800018fc:	8b850513          	addi	a0,a0,-1864 # 8000a1b0 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	254080e7          	jalr	596(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e058593          	addi	a1,a1,-1824 # 800081e8 <digits+0x1a8>
    80001910:	00009517          	auipc	a0,0x9
    80001914:	8b850513          	addi	a0,a0,-1864 # 8000a1c8 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00009497          	auipc	s1,0x9
    80001924:	94048493          	addi	s1,s1,-1728 # 8000a260 <proc>
      initlock(&p->lock, "proc");
    80001928:	00007b17          	auipc	s6,0x7
    8000192c:	8d0b0b13          	addi	s6,s6,-1840 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001930:	8aa6                	mv	s5,s1
    80001932:	00006a17          	auipc	s4,0x6
    80001936:	6cea0a13          	addi	s4,s4,1742 # 80008000 <etext>
    8000193a:	04000937          	lui	s2,0x4000
    8000193e:	197d                	addi	s2,s2,-1
    80001940:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001942:	0000f997          	auipc	s3,0xf
    80001946:	b1e98993          	addi	s3,s3,-1250 # 80010460 <tickslock>
      initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	878d                	srai	a5,a5,0x3
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	18848493          	addi	s1,s1,392
    80001974:	fd349be3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
  start_time = ticks;
    80001978:	00007797          	auipc	a5,0x7
    8000197c:	6e07a783          	lw	a5,1760(a5) # 80009058 <ticks>
    80001980:	00007717          	auipc	a4,0x7
    80001984:	6af72423          	sw	a5,1704(a4) # 80009028 <start_time>
}
    80001988:	70e2                	ld	ra,56(sp)
    8000198a:	7442                	ld	s0,48(sp)
    8000198c:	74a2                	ld	s1,40(sp)
    8000198e:	7902                	ld	s2,32(sp)
    80001990:	69e2                	ld	s3,24(sp)
    80001992:	6a42                	ld	s4,16(sp)
    80001994:	6aa2                	ld	s5,8(sp)
    80001996:	6b02                	ld	s6,0(sp)
    80001998:	6121                	addi	sp,sp,64
    8000199a:	8082                	ret

000000008000199c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a4:	2501                	sext.w	a0,a0
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019ac:	1141                	addi	sp,sp,-16
    800019ae:	e422                	sd	s0,8(sp)
    800019b0:	0800                	addi	s0,sp,16
    800019b2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b4:	2781                	sext.w	a5,a5
    800019b6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b8:	00009517          	auipc	a0,0x9
    800019bc:	82850513          	addi	a0,a0,-2008 # 8000a1e0 <cpus>
    800019c0:	953e                	add	a0,a0,a5
    800019c2:	6422                	ld	s0,8(sp)
    800019c4:	0141                	addi	sp,sp,16
    800019c6:	8082                	ret

00000000800019c8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c8:	1101                	addi	sp,sp,-32
    800019ca:	ec06                	sd	ra,24(sp)
    800019cc:	e822                	sd	s0,16(sp)
    800019ce:	e426                	sd	s1,8(sp)
    800019d0:	1000                	addi	s0,sp,32
  push_off();
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	1c6080e7          	jalr	454(ra) # 80000b98 <push_off>
    800019da:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019dc:	2781                	sext.w	a5,a5
    800019de:	079e                	slli	a5,a5,0x7
    800019e0:	00008717          	auipc	a4,0x8
    800019e4:	7d070713          	addi	a4,a4,2000 # 8000a1b0 <pid_lock>
    800019e8:	97ba                	add	a5,a5,a4
    800019ea:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	24c080e7          	jalr	588(ra) # 80000c38 <pop_off>
  return p;
}
    800019f4:	8526                	mv	a0,s1
    800019f6:	60e2                	ld	ra,24(sp)
    800019f8:	6442                	ld	s0,16(sp)
    800019fa:	64a2                	ld	s1,8(sp)
    800019fc:	6105                	addi	sp,sp,32
    800019fe:	8082                	ret

0000000080001a00 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e406                	sd	ra,8(sp)
    80001a04:	e022                	sd	s0,0(sp)
    80001a06:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	fc0080e7          	jalr	-64(ra) # 800019c8 <myproc>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	288080e7          	jalr	648(ra) # 80000c98 <release>

  if (first) {
    80001a18:	00007797          	auipc	a5,0x7
    80001a1c:	ee87a783          	lw	a5,-280(a5) # 80008900 <first.1826>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	264080e7          	jalr	612(ra) # 80002c86 <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
    first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	ec07a723          	sw	zero,-306(a5) # 80008900 <first.1826>
    fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	fc2080e7          	jalr	-62(ra) # 800039fe <fsinit>
    80001a44:	bff9                	j	80001a22 <forkret+0x22>

0000000080001a46 <allocpid>:
allocpid() {
    80001a46:	1101                	addi	sp,sp,-32
    80001a48:	ec06                	sd	ra,24(sp)
    80001a4a:	e822                	sd	s0,16(sp)
    80001a4c:	e426                	sd	s1,8(sp)
    80001a4e:	e04a                	sd	s2,0(sp)
    80001a50:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a52:	00008917          	auipc	s2,0x8
    80001a56:	75e90913          	addi	s2,s2,1886 # 8000a1b0 <pid_lock>
    80001a5a:	854a                	mv	a0,s2
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	188080e7          	jalr	392(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a64:	00007797          	auipc	a5,0x7
    80001a68:	ea478793          	addi	a5,a5,-348 # 80008908 <nextpid>
    80001a6c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6e:	0014871b          	addiw	a4,s1,1
    80001a72:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	222080e7          	jalr	546(ra) # 80000c98 <release>
}
    80001a7e:	8526                	mv	a0,s1
    80001a80:	60e2                	ld	ra,24(sp)
    80001a82:	6442                	ld	s0,16(sp)
    80001a84:	64a2                	ld	s1,8(sp)
    80001a86:	6902                	ld	s2,0(sp)
    80001a88:	6105                	addi	sp,sp,32
    80001a8a:	8082                	ret

0000000080001a8c <proc_pagetable>:
{
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
    80001a98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9a:	00000097          	auipc	ra,0x0
    80001a9e:	8a8080e7          	jalr	-1880(ra) # 80001342 <uvmcreate>
    80001aa2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa4:	c121                	beqz	a0,80001ae4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa6:	4729                	li	a4,10
    80001aa8:	00005697          	auipc	a3,0x5
    80001aac:	55868693          	addi	a3,a3,1368 # 80007000 <_trampoline>
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	040005b7          	lui	a1,0x4000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b2                	slli	a1,a1,0xc
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	5fe080e7          	jalr	1534(ra) # 800010b8 <mappages>
    80001ac2:	02054863          	bltz	a0,80001af2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac6:	4719                	li	a4,6
    80001ac8:	05893683          	ld	a3,88(s2)
    80001acc:	6605                	lui	a2,0x1
    80001ace:	020005b7          	lui	a1,0x2000
    80001ad2:	15fd                	addi	a1,a1,-1
    80001ad4:	05b6                	slli	a1,a1,0xd
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	5e0080e7          	jalr	1504(ra) # 800010b8 <mappages>
    80001ae0:	02054163          	bltz	a0,80001b02 <proc_pagetable+0x76>
}
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	60e2                	ld	ra,24(sp)
    80001ae8:	6442                	ld	s0,16(sp)
    80001aea:	64a2                	ld	s1,8(sp)
    80001aec:	6902                	ld	s2,0(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret
    uvmfree(pagetable, 0);
    80001af2:	4581                	li	a1,0
    80001af4:	8526                	mv	a0,s1
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	a48080e7          	jalr	-1464(ra) # 8000153e <uvmfree>
    return 0;
    80001afe:	4481                	li	s1,0
    80001b00:	b7d5                	j	80001ae4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	040005b7          	lui	a1,0x4000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b2                	slli	a1,a1,0xc
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	76e080e7          	jalr	1902(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b18:	4581                	li	a1,0
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	a22080e7          	jalr	-1502(ra) # 8000153e <uvmfree>
    return 0;
    80001b24:	4481                	li	s1,0
    80001b26:	bf7d                	j	80001ae4 <proc_pagetable+0x58>

0000000080001b28 <proc_freepagetable>:
{
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	84aa                	mv	s1,a0
    80001b36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	73a080e7          	jalr	1850(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4c:	4681                	li	a3,0
    80001b4e:	4605                	li	a2,1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	724080e7          	jalr	1828(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b62:	85ca                	mv	a1,s2
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	9d8080e7          	jalr	-1576(ra) # 8000153e <uvmfree>
}
    80001b6e:	60e2                	ld	ra,24(sp)
    80001b70:	6442                	ld	s0,16(sp)
    80001b72:	64a2                	ld	s1,8(sp)
    80001b74:	6902                	ld	s2,0(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret

0000000080001b7a <freeproc>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	1000                	addi	s0,sp,32
    80001b84:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b86:	6d28                	ld	a0,88(a0)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e6e080e7          	jalr	-402(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b92:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b96:	68a8                	ld	a0,80(s1)
    80001b98:	c511                	beqz	a0,80001ba4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9a:	64ac                	ld	a1,72(s1)
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	f8c080e7          	jalr	-116(ra) # 80001b28 <proc_freepagetable>
  p->pagetable = 0;
    80001ba4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bbc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc4:	0004ac23          	sw	zero,24(s1)
}
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6105                	addi	sp,sp,32
    80001bd0:	8082                	ret

0000000080001bd2 <allocproc>:
{
    80001bd2:	1101                	addi	sp,sp,-32
    80001bd4:	ec06                	sd	ra,24(sp)
    80001bd6:	e822                	sd	s0,16(sp)
    80001bd8:	e426                	sd	s1,8(sp)
    80001bda:	e04a                	sd	s2,0(sp)
    80001bdc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bde:	00008497          	auipc	s1,0x8
    80001be2:	68248493          	addi	s1,s1,1666 # 8000a260 <proc>
    80001be6:	0000f917          	auipc	s2,0xf
    80001bea:	87a90913          	addi	s2,s2,-1926 # 80010460 <tickslock>
    acquire(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bf8:	4c9c                	lw	a5,24(s1)
    80001bfa:	cf81                	beqz	a5,80001c12 <allocproc+0x40>
      release(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c06:	18848493          	addi	s1,s1,392
    80001c0a:	ff2492e3          	bne	s1,s2,80001bee <allocproc+0x1c>
  return 0;
    80001c0e:	4481                	li	s1,0
    80001c10:	a09d                	j	80001c76 <allocproc+0xa4>
  p->pid = allocpid();
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	e34080e7          	jalr	-460(ra) # 80001a46 <allocpid>
    80001c1a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1c:	4785                	li	a5,1
    80001c1e:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c20:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001c24:	1604a623          	sw	zero,364(s1)
  p->start_cpu_burst = 0;
    80001c28:	1604a823          	sw	zero,368(s1)
  p->last_runnable_time = 0;
    80001c2c:	1604aa23          	sw	zero,372(s1)
  p->start_sleeping = 0;
    80001c30:	1804a223          	sw	zero,388(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	ec0080e7          	jalr	-320(ra) # 80000af4 <kalloc>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	eca8                	sd	a0,88(s1)
    80001c40:	c131                	beqz	a0,80001c84 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e48080e7          	jalr	-440(ra) # 80001a8c <proc_pagetable>
    80001c4c:	892a                	mv	s2,a0
    80001c4e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c50:	c531                	beqz	a0,80001c9c <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c52:	07000613          	li	a2,112
    80001c56:	4581                	li	a1,0
    80001c58:	06048513          	addi	a0,s1,96
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	084080e7          	jalr	132(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c64:	00000797          	auipc	a5,0x0
    80001c68:	d9c78793          	addi	a5,a5,-612 # 80001a00 <forkret>
    80001c6c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6e:	60bc                	ld	a5,64(s1)
    80001c70:	6705                	lui	a4,0x1
    80001c72:	97ba                	add	a5,a5,a4
    80001c74:	f4bc                	sd	a5,104(s1)
}
    80001c76:	8526                	mv	a0,s1
    80001c78:	60e2                	ld	ra,24(sp)
    80001c7a:	6442                	ld	s0,16(sp)
    80001c7c:	64a2                	ld	s1,8(sp)
    80001c7e:	6902                	ld	s2,0(sp)
    80001c80:	6105                	addi	sp,sp,32
    80001c82:	8082                	ret
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ef4080e7          	jalr	-268(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	bff1                	j	80001c76 <allocproc+0xa4>
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	edc080e7          	jalr	-292(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	ff0080e7          	jalr	-16(ra) # 80000c98 <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7d1                	j	80001c76 <allocproc+0xa4>

0000000080001cb4 <userinit>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	f14080e7          	jalr	-236(ra) # 80001bd2 <allocproc>
    80001cc6:	84aa                	mv	s1,a0
  initproc = p;
    80001cc8:	00007797          	auipc	a5,0x7
    80001ccc:	38a7b423          	sd	a0,904(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd0:	03400613          	li	a2,52
    80001cd4:	00007597          	auipc	a1,0x7
    80001cd8:	c3c58593          	addi	a1,a1,-964 # 80008910 <initcode>
    80001cdc:	6928                	ld	a0,80(a0)
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	692080e7          	jalr	1682(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001ce6:	6785                	lui	a5,0x1
    80001ce8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cea:	6cb8                	ld	a4,88(s1)
    80001cec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf0:	6cb8                	ld	a4,88(s1)
    80001cf2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf4:	4641                	li	a2,16
    80001cf6:	00006597          	auipc	a1,0x6
    80001cfa:	50a58593          	addi	a1,a1,1290 # 80008200 <digits+0x1c0>
    80001cfe:	15848513          	addi	a0,s1,344
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	130080e7          	jalr	304(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	50650513          	addi	a0,a0,1286 # 80008210 <digits+0x1d0>
    80001d12:	00002097          	auipc	ra,0x2
    80001d16:	71a080e7          	jalr	1818(ra) # 8000442c <namei>
    80001d1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001d22:	00007797          	auipc	a5,0x7
    80001d26:	3367a783          	lw	a5,822(a5) # 80009058 <ticks>
    80001d2a:	16f4aa23          	sw	a5,372(s1)
  release(&p->lock);
    80001d2e:	8526                	mv	a0,s1
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	f68080e7          	jalr	-152(ra) # 80000c98 <release>
}
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6105                	addi	sp,sp,32
    80001d40:	8082                	ret

0000000080001d42 <growproc>:
{
    80001d42:	1101                	addi	sp,sp,-32
    80001d44:	ec06                	sd	ra,24(sp)
    80001d46:	e822                	sd	s0,16(sp)
    80001d48:	e426                	sd	s1,8(sp)
    80001d4a:	e04a                	sd	s2,0(sp)
    80001d4c:	1000                	addi	s0,sp,32
    80001d4e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	c78080e7          	jalr	-904(ra) # 800019c8 <myproc>
    80001d58:	892a                	mv	s2,a0
  sz = p->sz;
    80001d5a:	652c                	ld	a1,72(a0)
    80001d5c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d60:	00904f63          	bgtz	s1,80001d7e <growproc+0x3c>
  } else if(n < 0){
    80001d64:	0204cc63          	bltz	s1,80001d9c <growproc+0x5a>
  p->sz = sz;
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d70:	4501                	li	a0,0
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6902                	ld	s2,0(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d7e:	9e25                	addw	a2,a2,s1
    80001d80:	1602                	slli	a2,a2,0x20
    80001d82:	9201                	srli	a2,a2,0x20
    80001d84:	1582                	slli	a1,a1,0x20
    80001d86:	9181                	srli	a1,a1,0x20
    80001d88:	6928                	ld	a0,80(a0)
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	6a0080e7          	jalr	1696(ra) # 8000142a <uvmalloc>
    80001d92:	0005061b          	sext.w	a2,a0
    80001d96:	fa69                	bnez	a2,80001d68 <growproc+0x26>
      return -1;
    80001d98:	557d                	li	a0,-1
    80001d9a:	bfe1                	j	80001d72 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9c:	9e25                	addw	a2,a2,s1
    80001d9e:	1602                	slli	a2,a2,0x20
    80001da0:	9201                	srli	a2,a2,0x20
    80001da2:	1582                	slli	a1,a1,0x20
    80001da4:	9181                	srli	a1,a1,0x20
    80001da6:	6928                	ld	a0,80(a0)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	63a080e7          	jalr	1594(ra) # 800013e2 <uvmdealloc>
    80001db0:	0005061b          	sext.w	a2,a0
    80001db4:	bf55                	j	80001d68 <growproc+0x26>

0000000080001db6 <fork>:
{
    80001db6:	7179                	addi	sp,sp,-48
    80001db8:	f406                	sd	ra,40(sp)
    80001dba:	f022                	sd	s0,32(sp)
    80001dbc:	ec26                	sd	s1,24(sp)
    80001dbe:	e84a                	sd	s2,16(sp)
    80001dc0:	e44e                	sd	s3,8(sp)
    80001dc2:	e052                	sd	s4,0(sp)
    80001dc4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	c02080e7          	jalr	-1022(ra) # 800019c8 <myproc>
    80001dce:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e02080e7          	jalr	-510(ra) # 80001bd2 <allocproc>
    80001dd8:	12050163          	beqz	a0,80001efa <fork+0x144>
    80001ddc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dde:	04893603          	ld	a2,72(s2)
    80001de2:	692c                	ld	a1,80(a0)
    80001de4:	05093503          	ld	a0,80(s2)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	78e080e7          	jalr	1934(ra) # 80001576 <uvmcopy>
    80001df0:	04054663          	bltz	a0,80001e3c <fork+0x86>
  np->sz = p->sz;
    80001df4:	04893783          	ld	a5,72(s2)
    80001df8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfc:	05893683          	ld	a3,88(s2)
    80001e00:	87b6                	mv	a5,a3
    80001e02:	0589b703          	ld	a4,88(s3)
    80001e06:	12068693          	addi	a3,a3,288
    80001e0a:	0007b803          	ld	a6,0(a5)
    80001e0e:	6788                	ld	a0,8(a5)
    80001e10:	6b8c                	ld	a1,16(a5)
    80001e12:	6f90                	ld	a2,24(a5)
    80001e14:	01073023          	sd	a6,0(a4)
    80001e18:	e708                	sd	a0,8(a4)
    80001e1a:	eb0c                	sd	a1,16(a4)
    80001e1c:	ef10                	sd	a2,24(a4)
    80001e1e:	02078793          	addi	a5,a5,32
    80001e22:	02070713          	addi	a4,a4,32
    80001e26:	fed792e3          	bne	a5,a3,80001e0a <fork+0x54>
  np->trapframe->a0 = 0;
    80001e2a:	0589b783          	ld	a5,88(s3)
    80001e2e:	0607b823          	sd	zero,112(a5)
    80001e32:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e36:	15000a13          	li	s4,336
    80001e3a:	a03d                	j	80001e68 <fork+0xb2>
    freeproc(np);
    80001e3c:	854e                	mv	a0,s3
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	d3c080e7          	jalr	-708(ra) # 80001b7a <freeproc>
    release(&np->lock);
    80001e46:	854e                	mv	a0,s3
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
    return -1;
    80001e50:	5a7d                	li	s4,-1
    80001e52:	a859                	j	80001ee8 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e54:	00003097          	auipc	ra,0x3
    80001e58:	c6e080e7          	jalr	-914(ra) # 80004ac2 <filedup>
    80001e5c:	009987b3          	add	a5,s3,s1
    80001e60:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e62:	04a1                	addi	s1,s1,8
    80001e64:	01448763          	beq	s1,s4,80001e72 <fork+0xbc>
    if(p->ofile[i])
    80001e68:	009907b3          	add	a5,s2,s1
    80001e6c:	6388                	ld	a0,0(a5)
    80001e6e:	f17d                	bnez	a0,80001e54 <fork+0x9e>
    80001e70:	bfcd                	j	80001e62 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e72:	15093503          	ld	a0,336(s2)
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	dc2080e7          	jalr	-574(ra) # 80003c38 <idup>
    80001e7e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e82:	4641                	li	a2,16
    80001e84:	15890593          	addi	a1,s2,344
    80001e88:	15898513          	addi	a0,s3,344
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	fa6080e7          	jalr	-90(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e94:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	dfe080e7          	jalr	-514(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ea2:	00008497          	auipc	s1,0x8
    80001ea6:	32648493          	addi	s1,s1,806 # 8000a1c8 <wait_lock>
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	d38080e7          	jalr	-712(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eb4:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dde080e7          	jalr	-546(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ec2:	854e                	mv	a0,s3
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	d20080e7          	jalr	-736(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ecc:	478d                	li	a5,3
    80001ece:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001ed2:	00007797          	auipc	a5,0x7
    80001ed6:	1867a783          	lw	a5,390(a5) # 80009058 <ticks>
    80001eda:	16f9aa23          	sw	a5,372(s3)
  release(&np->lock);
    80001ede:	854e                	mv	a0,s3
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	db8080e7          	jalr	-584(ra) # 80000c98 <release>
}
    80001ee8:	8552                	mv	a0,s4
    80001eea:	70a2                	ld	ra,40(sp)
    80001eec:	7402                	ld	s0,32(sp)
    80001eee:	64e2                	ld	s1,24(sp)
    80001ef0:	6942                	ld	s2,16(sp)
    80001ef2:	69a2                	ld	s3,8(sp)
    80001ef4:	6a02                	ld	s4,0(sp)
    80001ef6:	6145                	addi	sp,sp,48
    80001ef8:	8082                	ret
    return -1;
    80001efa:	5a7d                	li	s4,-1
    80001efc:	b7f5                	j	80001ee8 <fork+0x132>

0000000080001efe <round_robin>:
round_robin(){
    80001efe:	711d                	addi	sp,sp,-96
    80001f00:	ec86                	sd	ra,88(sp)
    80001f02:	e8a2                	sd	s0,80(sp)
    80001f04:	e4a6                	sd	s1,72(sp)
    80001f06:	e0ca                	sd	s2,64(sp)
    80001f08:	fc4e                	sd	s3,56(sp)
    80001f0a:	f852                	sd	s4,48(sp)
    80001f0c:	f456                	sd	s5,40(sp)
    80001f0e:	f05a                	sd	s6,32(sp)
    80001f10:	ec5e                	sd	s7,24(sp)
    80001f12:	e862                	sd	s8,16(sp)
    80001f14:	e466                	sd	s9,8(sp)
    80001f16:	1080                	addi	s0,sp,96
    printf("Round Robin Policy \n");
    80001f18:	00006517          	auipc	a0,0x6
    80001f1c:	30050513          	addi	a0,a0,768 # 80008218 <digits+0x1d8>
    80001f20:	ffffe097          	auipc	ra,0xffffe
    80001f24:	668080e7          	jalr	1640(ra) # 80000588 <printf>
    80001f28:	8792                	mv	a5,tp
  int id = r_tp();
    80001f2a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f2c:	00779c93          	slli	s9,a5,0x7
    80001f30:	00008717          	auipc	a4,0x8
    80001f34:	28070713          	addi	a4,a4,640 # 8000a1b0 <pid_lock>
    80001f38:	9766                	add	a4,a4,s9
    80001f3a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f3e:	00008717          	auipc	a4,0x8
    80001f42:	2aa70713          	addi	a4,a4,682 # 8000a1e8 <cpus+0x8>
    80001f46:	9cba                	add	s9,s9,a4
          c->proc = p;
    80001f48:	079e                	slli	a5,a5,0x7
    80001f4a:	00008b17          	auipc	s6,0x8
    80001f4e:	266b0b13          	addi	s6,s6,614 # 8000a1b0 <pid_lock>
    80001f52:	9b3e                	add	s6,s6,a5
          p-> runnable_time += (ticks - p->last_runnable_time); 
    80001f54:	00007997          	auipc	s3,0x7
    80001f58:	10498993          	addi	s3,s3,260 # 80009058 <ticks>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f5c:	00007b97          	auipc	s7,0x7
    80001f60:	0f0b8b93          	addi	s7,s7,240 # 8000904c <pause_time>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6c:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	00008497          	auipc	s1,0x8
    80001f74:	2f048493          	addi	s1,s1,752 # 8000a260 <proc>
        if(p->state == RUNNABLE) {
    80001f78:	4a8d                	li	s5,3
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f7a:	4c05                	li	s8,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7c:	0000ea17          	auipc	s4,0xe
    80001f80:	4e4a0a13          	addi	s4,s4,1252 # 80010460 <tickslock>
    80001f84:	a08d                	j	80001fe6 <round_robin+0xe8>
              pause_time = 0;
    80001f86:	000ba023          	sw	zero,0(s7)
          p->state = RUNNING; 
    80001f8a:	4791                	li	a5,4
    80001f8c:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001f8e:	029b3823          	sd	s1,48(s6)
          p-> runnable_time += (ticks - p->last_runnable_time); 
    80001f92:	0009a703          	lw	a4,0(s3)
    80001f96:	17c4a783          	lw	a5,380(s1)
    80001f9a:	9fb9                	addw	a5,a5,a4
    80001f9c:	1744a683          	lw	a3,372(s1)
    80001fa0:	9f95                	subw	a5,a5,a3
    80001fa2:	16f4ae23          	sw	a5,380(s1)
          p->start_cpu_burst = ticks;
    80001fa6:	16e4a823          	sw	a4,368(s1)
          swtch(&c->context, &p->context);
    80001faa:	06090593          	addi	a1,s2,96
    80001fae:	8566                	mv	a0,s9
    80001fb0:	00001097          	auipc	ra,0x1
    80001fb4:	c2c080e7          	jalr	-980(ra) # 80002bdc <swtch>
          p->last_ticks = ticks - p->start_cpu_burst;
    80001fb8:	0009a783          	lw	a5,0(s3)
    80001fbc:	1704a703          	lw	a4,368(s1)
    80001fc0:	9f99                	subw	a5,a5,a4
    80001fc2:	16f4a623          	sw	a5,364(s1)
          p->running_time = p->running_time + p->last_ticks;
    80001fc6:	1804a703          	lw	a4,384(s1)
    80001fca:	9fb9                	addw	a5,a5,a4
    80001fcc:	18f4a023          	sw	a5,384(s1)
          c->proc = 0;
    80001fd0:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	cc2080e7          	jalr	-830(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fde:	18848493          	addi	s1,s1,392
    80001fe2:	f94481e3          	beq	s1,s4,80001f64 <round_robin+0x66>
        acquire(&p->lock);
    80001fe6:	8926                	mv	s2,s1
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	bfa080e7          	jalr	-1030(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001ff2:	4c9c                	lw	a5,24(s1)
    80001ff4:	ff5790e3          	bne	a5,s5,80001fd4 <round_robin+0xd6>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001ff8:	589c                	lw	a5,48(s1)
    80001ffa:	37fd                	addiw	a5,a5,-1
    80001ffc:	f8fc77e3          	bgeu	s8,a5,80001f8a <round_robin+0x8c>
    80002000:	000ba783          	lw	a5,0(s7)
    80002004:	d3d9                	beqz	a5,80001f8a <round_robin+0x8c>
            if(ticks >= pause_time){
    80002006:	0009a703          	lw	a4,0(s3)
    8000200a:	f6f77ee3          	bgeu	a4,a5,80001f86 <round_robin+0x88>
              release(&p->lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	c88080e7          	jalr	-888(ra) # 80000c98 <release>
              continue;
    80002018:	b7d9                	j	80001fde <round_robin+0xe0>

000000008000201a <sjf>:
sjf(void){
    8000201a:	7159                	addi	sp,sp,-112
    8000201c:	f486                	sd	ra,104(sp)
    8000201e:	f0a2                	sd	s0,96(sp)
    80002020:	eca6                	sd	s1,88(sp)
    80002022:	e8ca                	sd	s2,80(sp)
    80002024:	e4ce                	sd	s3,72(sp)
    80002026:	e0d2                	sd	s4,64(sp)
    80002028:	fc56                	sd	s5,56(sp)
    8000202a:	f85a                	sd	s6,48(sp)
    8000202c:	f45e                	sd	s7,40(sp)
    8000202e:	f062                	sd	s8,32(sp)
    80002030:	ec66                	sd	s9,24(sp)
    80002032:	e86a                	sd	s10,16(sp)
    80002034:	e46e                	sd	s11,8(sp)
    80002036:	1880                	addi	s0,sp,112
  printf("SJF Policy \n");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1f850513          	addi	a0,a0,504 # 80008230 <digits+0x1f0>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	548080e7          	jalr	1352(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002048:	8792                	mv	a5,tp
  int id = r_tp();
    8000204a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000204c:	00779693          	slli	a3,a5,0x7
    80002050:	00008717          	auipc	a4,0x8
    80002054:	16070713          	addi	a4,a4,352 # 8000a1b0 <pid_lock>
    80002058:	9736                	add	a4,a4,a3
    8000205a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &min_proc->context);
    8000205e:	00008717          	auipc	a4,0x8
    80002062:	18a70713          	addi	a4,a4,394 # 8000a1e8 <cpus+0x8>
    80002066:	00e68db3          	add	s11,a3,a4
    int min = -1;
    8000206a:	5c7d                	li	s8,-1
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    8000206c:	00007a17          	auipc	s4,0x7
    80002070:	fe0a0a13          	addi	s4,s4,-32 # 8000904c <pause_time>
          if(ticks >= pause_time){
    80002074:	00007b97          	auipc	s7,0x7
    80002078:	fe4b8b93          	addi	s7,s7,-28 # 80009058 <ticks>
          c->proc = min_proc;
    8000207c:	00008d17          	auipc	s10,0x8
    80002080:	134d0d13          	addi	s10,s10,308 # 8000a1b0 <pid_lock>
    80002084:	9d36                	add	s10,s10,a3
    80002086:	a095                	j	800020ea <sjf+0xd0>
           release(&p->lock);
    80002088:	8526                	mv	a0,s1
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	c0e080e7          	jalr	-1010(ra) # 80000c98 <release>
           continue;
    80002092:	a809                	j	800020a4 <sjf+0x8a>
      else if((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min)){
    80002094:	4c9c                	lw	a5,24(s1)
    80002096:	03578e63          	beq	a5,s5,800020d2 <sjf+0xb8>
        release(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bfc080e7          	jalr	-1028(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    800020a4:	18848493          	addi	s1,s1,392
    800020a8:	03248f63          	beq	s1,s2,800020e6 <sjf+0xcc>
      acquire(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b36080e7          	jalr	-1226(ra) # 80000be4 <acquire>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    800020b6:	589c                	lw	a5,48(s1)
    800020b8:	37fd                	addiw	a5,a5,-1
    800020ba:	fcf9fde3          	bgeu	s3,a5,80002094 <sjf+0x7a>
    800020be:	000a2783          	lw	a5,0(s4)
    800020c2:	dbe9                	beqz	a5,80002094 <sjf+0x7a>
          if(ticks >= pause_time){
    800020c4:	000ba703          	lw	a4,0(s7)
    800020c8:	fcf760e3          	bltu	a4,a5,80002088 <sjf+0x6e>
            pause_time = 0;
    800020cc:	000a2023          	sw	zero,0(s4)
          if(ticks >= pause_time){
    800020d0:	b7e9                	j	8000209a <sjf+0x80>
      else if((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min)){
    800020d2:	018b0663          	beq	s6,s8,800020de <sjf+0xc4>
    800020d6:	1684a783          	lw	a5,360(s1)
    800020da:	fd67f0e3          	bgeu	a5,s6,8000209a <sjf+0x80>
              min = p->mean_ticks;
    800020de:	1684ab03          	lw	s6,360(s1)
    800020e2:	8ca6                	mv	s9,s1
    800020e4:	bf5d                	j	8000209a <sjf+0x80>
    if(min == -1){
    800020e6:	038b1463          	bne	s6,s8,8000210e <sjf+0xf4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020f2:	10079073          	csrw	sstatus,a5
    int min = -1;
    800020f6:	8b62                	mv	s6,s8
    for(p = proc; p < &proc[NPROC]; p++) { 
    800020f8:	00008497          	auipc	s1,0x8
    800020fc:	16848493          	addi	s1,s1,360 # 8000a260 <proc>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002100:	4985                	li	s3,1
      else if((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min)){
    80002102:	4a8d                	li	s5,3
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002104:	0000e917          	auipc	s2,0xe
    80002108:	35c90913          	addi	s2,s2,860 # 80010460 <tickslock>
    8000210c:	b745                	j	800020ac <sjf+0x92>
      acquire(&min_proc->lock);
    8000210e:	84e6                	mv	s1,s9
    80002110:	8566                	mv	a0,s9
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	ad2080e7          	jalr	-1326(ra) # 80000be4 <acquire>
         if(min_proc->state == RUNNABLE) {
    8000211a:	018ca703          	lw	a4,24(s9)
    8000211e:	478d                	li	a5,3
    80002120:	00f70863          	beq	a4,a5,80002130 <sjf+0x116>
        release(&min_proc->lock);
    80002124:	8526                	mv	a0,s1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>
    8000212e:	bf75                	j	800020ea <sjf+0xd0>
          min_proc->state = RUNNING;
    80002130:	4791                	li	a5,4
    80002132:	00fcac23          	sw	a5,24(s9)
          c->proc = min_proc;
    80002136:	039d3823          	sd	s9,48(s10)
          min_proc->runnable_time += (ticks - min_proc->last_runnable_time); 
    8000213a:	000ba703          	lw	a4,0(s7)
    8000213e:	17cca783          	lw	a5,380(s9)
    80002142:	9fb9                	addw	a5,a5,a4
    80002144:	174ca683          	lw	a3,372(s9)
    80002148:	9f95                	subw	a5,a5,a3
    8000214a:	16fcae23          	sw	a5,380(s9)
          min_proc->start_cpu_burst = ticks;
    8000214e:	16eca823          	sw	a4,368(s9)
          swtch(&c->context, &min_proc->context);
    80002152:	060c8593          	addi	a1,s9,96
    80002156:	856e                	mv	a0,s11
    80002158:	00001097          	auipc	ra,0x1
    8000215c:	a84080e7          	jalr	-1404(ra) # 80002bdc <swtch>
          min_proc->last_ticks = ticks - min_proc->start_cpu_burst;
    80002160:	000ba783          	lw	a5,0(s7)
    80002164:	170ca703          	lw	a4,368(s9)
    80002168:	40e7873b          	subw	a4,a5,a4
    8000216c:	16eca623          	sw	a4,364(s9)
          min_proc->mean_ticks = ((10*rate)* min_proc->mean_ticks + min_proc->last_ticks*(rate)) / 10;
    80002170:	168ca683          	lw	a3,360(s9)
    80002174:	0026979b          	slliw	a5,a3,0x2
    80002178:	9fb5                	addw	a5,a5,a3
    8000217a:	0017979b          	slliw	a5,a5,0x1
    8000217e:	9fb9                	addw	a5,a5,a4
    80002180:	00006717          	auipc	a4,0x6
    80002184:	78472703          	lw	a4,1924(a4) # 80008904 <rate>
    80002188:	02e787bb          	mulw	a5,a5,a4
    8000218c:	4729                	li	a4,10
    8000218e:	02e7d7bb          	divuw	a5,a5,a4
    80002192:	16fca423          	sw	a5,360(s9)
          c->proc = 0;
    80002196:	020d3823          	sd	zero,48(s10)
    8000219a:	b769                	j	80002124 <sjf+0x10a>

000000008000219c <fcfs>:
fcfs(void){
    8000219c:	7159                	addi	sp,sp,-112
    8000219e:	f486                	sd	ra,104(sp)
    800021a0:	f0a2                	sd	s0,96(sp)
    800021a2:	eca6                	sd	s1,88(sp)
    800021a4:	e8ca                	sd	s2,80(sp)
    800021a6:	e4ce                	sd	s3,72(sp)
    800021a8:	e0d2                	sd	s4,64(sp)
    800021aa:	fc56                	sd	s5,56(sp)
    800021ac:	f85a                	sd	s6,48(sp)
    800021ae:	f45e                	sd	s7,40(sp)
    800021b0:	f062                	sd	s8,32(sp)
    800021b2:	ec66                	sd	s9,24(sp)
    800021b4:	e86a                	sd	s10,16(sp)
    800021b6:	e46e                	sd	s11,8(sp)
    800021b8:	1880                	addi	s0,sp,112
  printf("FCFS Policy \n");
    800021ba:	00006517          	auipc	a0,0x6
    800021be:	08650513          	addi	a0,a0,134 # 80008240 <digits+0x200>
    800021c2:	ffffe097          	auipc	ra,0xffffe
    800021c6:	3c6080e7          	jalr	966(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ca:	8792                	mv	a5,tp
  int id = r_tp();
    800021cc:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021ce:	00779693          	slli	a3,a5,0x7
    800021d2:	00008717          	auipc	a4,0x8
    800021d6:	fde70713          	addi	a4,a4,-34 # 8000a1b0 <pid_lock>
    800021da:	9736                	add	a4,a4,a3
    800021dc:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &min_proc->context);
    800021e0:	00008717          	auipc	a4,0x8
    800021e4:	00870713          	addi	a4,a4,8 # 8000a1e8 <cpus+0x8>
    800021e8:	00e68db3          	add	s11,a3,a4
    int min = -1;
    800021ec:	5c7d                	li	s8,-1
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    800021ee:	00007a17          	auipc	s4,0x7
    800021f2:	e5ea0a13          	addi	s4,s4,-418 # 8000904c <pause_time>
          if(ticks >= pause_time){
    800021f6:	00007b97          	auipc	s7,0x7
    800021fa:	e62b8b93          	addi	s7,s7,-414 # 80009058 <ticks>
          c->proc = min_proc;
    800021fe:	00008d17          	auipc	s10,0x8
    80002202:	fb2d0d13          	addi	s10,s10,-78 # 8000a1b0 <pid_lock>
    80002206:	9d36                	add	s10,s10,a3
    80002208:	a095                	j	8000226c <fcfs+0xd0>
           release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a8c080e7          	jalr	-1396(ra) # 80000c98 <release>
           continue;
    80002214:	a809                	j	80002226 <fcfs+0x8a>
      else if((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min)){
    80002216:	4c9c                	lw	a5,24(s1)
    80002218:	03578e63          	beq	a5,s5,80002254 <fcfs+0xb8>
        release(&p->lock);
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	a7a080e7          	jalr	-1414(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002226:	18848493          	addi	s1,s1,392
    8000222a:	03248f63          	beq	s1,s2,80002268 <fcfs+0xcc>
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	9b4080e7          	jalr	-1612(ra) # 80000be4 <acquire>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002238:	589c                	lw	a5,48(s1)
    8000223a:	37fd                	addiw	a5,a5,-1
    8000223c:	fcf9fde3          	bgeu	s3,a5,80002216 <fcfs+0x7a>
    80002240:	000a2783          	lw	a5,0(s4)
    80002244:	dbe9                	beqz	a5,80002216 <fcfs+0x7a>
          if(ticks >= pause_time){
    80002246:	000ba703          	lw	a4,0(s7)
    8000224a:	fcf760e3          	bltu	a4,a5,8000220a <fcfs+0x6e>
            pause_time = 0;
    8000224e:	000a2023          	sw	zero,0(s4)
          if(ticks >= pause_time){
    80002252:	b7e9                	j	8000221c <fcfs+0x80>
      else if((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min)){
    80002254:	018b0663          	beq	s6,s8,80002260 <fcfs+0xc4>
    80002258:	1744a783          	lw	a5,372(s1)
    8000225c:	fd67f0e3          	bgeu	a5,s6,8000221c <fcfs+0x80>
              min = p->last_runnable_time;
    80002260:	1744ab03          	lw	s6,372(s1)
    80002264:	8ca6                	mv	s9,s1
    80002266:	bf5d                	j	8000221c <fcfs+0x80>
    if(min == -1){
    80002268:	038b1463          	bne	s6,s8,80002290 <fcfs+0xf4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000226c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002270:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002274:	10079073          	csrw	sstatus,a5
    int min = -1;
    80002278:	8b62                	mv	s6,s8
    for(p = proc; p < &proc[NPROC]; p++) { 
    8000227a:	00008497          	auipc	s1,0x8
    8000227e:	fe648493          	addi	s1,s1,-26 # 8000a260 <proc>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002282:	4985                	li	s3,1
      else if((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min)){
    80002284:	4a8d                	li	s5,3
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002286:	0000e917          	auipc	s2,0xe
    8000228a:	1da90913          	addi	s2,s2,474 # 80010460 <tickslock>
    8000228e:	b745                	j	8000222e <fcfs+0x92>
      acquire(&min_proc->lock);
    80002290:	84e6                	mv	s1,s9
    80002292:	8566                	mv	a0,s9
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
         if(min_proc->state == RUNNABLE) {
    8000229c:	018ca703          	lw	a4,24(s9)
    800022a0:	478d                	li	a5,3
    800022a2:	00f70863          	beq	a4,a5,800022b2 <fcfs+0x116>
        release(&min_proc->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
    800022b0:	bf75                	j	8000226c <fcfs+0xd0>
          min_proc->state = RUNNING;
    800022b2:	4791                	li	a5,4
    800022b4:	00fcac23          	sw	a5,24(s9)
          c->proc = min_proc;
    800022b8:	039d3823          	sd	s9,48(s10)
          min_proc->runnable_time += (ticks - min_proc->last_runnable_time); 
    800022bc:	000ba703          	lw	a4,0(s7)
    800022c0:	17cca783          	lw	a5,380(s9)
    800022c4:	9fb9                	addw	a5,a5,a4
    800022c6:	174ca683          	lw	a3,372(s9)
    800022ca:	9f95                	subw	a5,a5,a3
    800022cc:	16fcae23          	sw	a5,380(s9)
          min_proc->start_cpu_burst = ticks;
    800022d0:	16eca823          	sw	a4,368(s9)
          swtch(&c->context, &min_proc->context);
    800022d4:	060c8593          	addi	a1,s9,96
    800022d8:	856e                	mv	a0,s11
    800022da:	00001097          	auipc	ra,0x1
    800022de:	902080e7          	jalr	-1790(ra) # 80002bdc <swtch>
          min_proc->last_ticks = ticks - min_proc->start_cpu_burst;
    800022e2:	000ba783          	lw	a5,0(s7)
    800022e6:	170ca703          	lw	a4,368(s9)
    800022ea:	9f99                	subw	a5,a5,a4
    800022ec:	16fca623          	sw	a5,364(s9)
          c->proc = 0;
    800022f0:	020d3823          	sd	zero,48(s10)
    800022f4:	bf4d                	j	800022a6 <fcfs+0x10a>

00000000800022f6 <scheduler>:
{
    800022f6:	1141                	addi	sp,sp,-16
    800022f8:	e406                	sd	ra,8(sp)
    800022fa:	e022                	sd	s0,0(sp)
    800022fc:	0800                	addi	s0,sp,16
    fcfs();
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	e9e080e7          	jalr	-354(ra) # 8000219c <fcfs>

0000000080002306 <sched>:
{
    80002306:	7179                	addi	sp,sp,-48
    80002308:	f406                	sd	ra,40(sp)
    8000230a:	f022                	sd	s0,32(sp)
    8000230c:	ec26                	sd	s1,24(sp)
    8000230e:	e84a                	sd	s2,16(sp)
    80002310:	e44e                	sd	s3,8(sp)
    80002312:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	6b4080e7          	jalr	1716(ra) # 800019c8 <myproc>
    8000231c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	84c080e7          	jalr	-1972(ra) # 80000b6a <holding>
    80002326:	c93d                	beqz	a0,8000239c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002328:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000232a:	2781                	sext.w	a5,a5
    8000232c:	079e                	slli	a5,a5,0x7
    8000232e:	00008717          	auipc	a4,0x8
    80002332:	e8270713          	addi	a4,a4,-382 # 8000a1b0 <pid_lock>
    80002336:	97ba                	add	a5,a5,a4
    80002338:	0a87a703          	lw	a4,168(a5)
    8000233c:	4785                	li	a5,1
    8000233e:	06f71763          	bne	a4,a5,800023ac <sched+0xa6>
  if(p->state == RUNNING)
    80002342:	4c98                	lw	a4,24(s1)
    80002344:	4791                	li	a5,4
    80002346:	06f70b63          	beq	a4,a5,800023bc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000234a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000234e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002350:	efb5                	bnez	a5,800023cc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002352:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002354:	00008917          	auipc	s2,0x8
    80002358:	e5c90913          	addi	s2,s2,-420 # 8000a1b0 <pid_lock>
    8000235c:	2781                	sext.w	a5,a5
    8000235e:	079e                	slli	a5,a5,0x7
    80002360:	97ca                	add	a5,a5,s2
    80002362:	0ac7a983          	lw	s3,172(a5)
    80002366:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002368:	2781                	sext.w	a5,a5
    8000236a:	079e                	slli	a5,a5,0x7
    8000236c:	00008597          	auipc	a1,0x8
    80002370:	e7c58593          	addi	a1,a1,-388 # 8000a1e8 <cpus+0x8>
    80002374:	95be                	add	a1,a1,a5
    80002376:	06048513          	addi	a0,s1,96
    8000237a:	00001097          	auipc	ra,0x1
    8000237e:	862080e7          	jalr	-1950(ra) # 80002bdc <swtch>
    80002382:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002384:	2781                	sext.w	a5,a5
    80002386:	079e                	slli	a5,a5,0x7
    80002388:	97ca                	add	a5,a5,s2
    8000238a:	0b37a623          	sw	s3,172(a5)
}
    8000238e:	70a2                	ld	ra,40(sp)
    80002390:	7402                	ld	s0,32(sp)
    80002392:	64e2                	ld	s1,24(sp)
    80002394:	6942                	ld	s2,16(sp)
    80002396:	69a2                	ld	s3,8(sp)
    80002398:	6145                	addi	sp,sp,48
    8000239a:	8082                	ret
    panic("sched p->lock");
    8000239c:	00006517          	auipc	a0,0x6
    800023a0:	eb450513          	addi	a0,a0,-332 # 80008250 <digits+0x210>
    800023a4:	ffffe097          	auipc	ra,0xffffe
    800023a8:	19a080e7          	jalr	410(ra) # 8000053e <panic>
    panic("sched locks");
    800023ac:	00006517          	auipc	a0,0x6
    800023b0:	eb450513          	addi	a0,a0,-332 # 80008260 <digits+0x220>
    800023b4:	ffffe097          	auipc	ra,0xffffe
    800023b8:	18a080e7          	jalr	394(ra) # 8000053e <panic>
    panic("sched running");
    800023bc:	00006517          	auipc	a0,0x6
    800023c0:	eb450513          	addi	a0,a0,-332 # 80008270 <digits+0x230>
    800023c4:	ffffe097          	auipc	ra,0xffffe
    800023c8:	17a080e7          	jalr	378(ra) # 8000053e <panic>
    panic("sched interruptible");
    800023cc:	00006517          	auipc	a0,0x6
    800023d0:	eb450513          	addi	a0,a0,-332 # 80008280 <digits+0x240>
    800023d4:	ffffe097          	auipc	ra,0xffffe
    800023d8:	16a080e7          	jalr	362(ra) # 8000053e <panic>

00000000800023dc <yield>:
{
    800023dc:	1101                	addi	sp,sp,-32
    800023de:	ec06                	sd	ra,24(sp)
    800023e0:	e822                	sd	s0,16(sp)
    800023e2:	e426                	sd	s1,8(sp)
    800023e4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	5e2080e7          	jalr	1506(ra) # 800019c8 <myproc>
    800023ee:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7f4080e7          	jalr	2036(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800023f8:	478d                	li	a5,3
    800023fa:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;  
    800023fc:	00007717          	auipc	a4,0x7
    80002400:	c5c72703          	lw	a4,-932(a4) # 80009058 <ticks>
    80002404:	16e4aa23          	sw	a4,372(s1)
  p->running_time += ticks - p->start_cpu_burst;   //IS IT GOOD WITH RR?
    80002408:	1804a783          	lw	a5,384(s1)
    8000240c:	9fb9                	addw	a5,a5,a4
    8000240e:	1704a703          	lw	a4,368(s1)
    80002412:	9f99                	subw	a5,a5,a4
    80002414:	18f4a023          	sw	a5,384(s1)
  sched();
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	eee080e7          	jalr	-274(ra) # 80002306 <sched>
  release(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
}
    8000242a:	60e2                	ld	ra,24(sp)
    8000242c:	6442                	ld	s0,16(sp)
    8000242e:	64a2                	ld	s1,8(sp)
    80002430:	6105                	addi	sp,sp,32
    80002432:	8082                	ret

0000000080002434 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002434:	7179                	addi	sp,sp,-48
    80002436:	f406                	sd	ra,40(sp)
    80002438:	f022                	sd	s0,32(sp)
    8000243a:	ec26                	sd	s1,24(sp)
    8000243c:	e84a                	sd	s2,16(sp)
    8000243e:	e44e                	sd	s3,8(sp)
    80002440:	1800                	addi	s0,sp,48
    80002442:	89aa                	mv	s3,a0
    80002444:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	582080e7          	jalr	1410(ra) # 800019c8 <myproc>
    8000244e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  release(lk);
    80002458:	854a                	mv	a0,s2
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002462:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002466:	4789                	li	a5,2
    80002468:	cc9c                	sw	a5,24(s1)
  p->start_sleeping = ticks;
    8000246a:	00007717          	auipc	a4,0x7
    8000246e:	bee72703          	lw	a4,-1042(a4) # 80009058 <ticks>
    80002472:	18e4a223          	sw	a4,388(s1)
  p->running_time += (ticks - p->start_cpu_burst);
    80002476:	1804a783          	lw	a5,384(s1)
    8000247a:	9fb9                	addw	a5,a5,a4
    8000247c:	1704a703          	lw	a4,368(s1)
    80002480:	9f99                	subw	a5,a5,a4
    80002482:	18f4a023          	sw	a5,384(s1)
  sched();
    80002486:	00000097          	auipc	ra,0x0
    8000248a:	e80080e7          	jalr	-384(ra) # 80002306 <sched>

  // Tidy up.
  p->chan = 0;
    8000248e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
  acquire(lk);
    8000249c:	854a                	mv	a0,s2
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	746080e7          	jalr	1862(ra) # 80000be4 <acquire>
}
    800024a6:	70a2                	ld	ra,40(sp)
    800024a8:	7402                	ld	s0,32(sp)
    800024aa:	64e2                	ld	s1,24(sp)
    800024ac:	6942                	ld	s2,16(sp)
    800024ae:	69a2                	ld	s3,8(sp)
    800024b0:	6145                	addi	sp,sp,48
    800024b2:	8082                	ret

00000000800024b4 <wait>:
{
    800024b4:	715d                	addi	sp,sp,-80
    800024b6:	e486                	sd	ra,72(sp)
    800024b8:	e0a2                	sd	s0,64(sp)
    800024ba:	fc26                	sd	s1,56(sp)
    800024bc:	f84a                	sd	s2,48(sp)
    800024be:	f44e                	sd	s3,40(sp)
    800024c0:	f052                	sd	s4,32(sp)
    800024c2:	ec56                	sd	s5,24(sp)
    800024c4:	e85a                	sd	s6,16(sp)
    800024c6:	e45e                	sd	s7,8(sp)
    800024c8:	e062                	sd	s8,0(sp)
    800024ca:	0880                	addi	s0,sp,80
    800024cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	4fa080e7          	jalr	1274(ra) # 800019c8 <myproc>
    800024d6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024d8:	00008517          	auipc	a0,0x8
    800024dc:	cf050513          	addi	a0,a0,-784 # 8000a1c8 <wait_lock>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	704080e7          	jalr	1796(ra) # 80000be4 <acquire>
    havekids = 0;
    800024e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024ea:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800024ec:	0000e997          	auipc	s3,0xe
    800024f0:	f7498993          	addi	s3,s3,-140 # 80010460 <tickslock>
        havekids = 1;
    800024f4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024f6:	00008c17          	auipc	s8,0x8
    800024fa:	cd2c0c13          	addi	s8,s8,-814 # 8000a1c8 <wait_lock>
    havekids = 0;
    800024fe:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002500:	00008497          	auipc	s1,0x8
    80002504:	d6048493          	addi	s1,s1,-672 # 8000a260 <proc>
    80002508:	a0bd                	j	80002576 <wait+0xc2>
          pid = np->pid;
    8000250a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000250e:	000b0e63          	beqz	s6,8000252a <wait+0x76>
    80002512:	4691                	li	a3,4
    80002514:	02c48613          	addi	a2,s1,44
    80002518:	85da                	mv	a1,s6
    8000251a:	05093503          	ld	a0,80(s2)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	15c080e7          	jalr	348(ra) # 8000167a <copyout>
    80002526:	02054563          	bltz	a0,80002550 <wait+0x9c>
          freeproc(np);
    8000252a:	8526                	mv	a0,s1
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	64e080e7          	jalr	1614(ra) # 80001b7a <freeproc>
          release(&np->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
          release(&wait_lock);
    8000253e:	00008517          	auipc	a0,0x8
    80002542:	c8a50513          	addi	a0,a0,-886 # 8000a1c8 <wait_lock>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
          return pid;
    8000254e:	a09d                	j	800025b4 <wait+0x100>
            release(&np->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	746080e7          	jalr	1862(ra) # 80000c98 <release>
            release(&wait_lock);
    8000255a:	00008517          	auipc	a0,0x8
    8000255e:	c6e50513          	addi	a0,a0,-914 # 8000a1c8 <wait_lock>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	736080e7          	jalr	1846(ra) # 80000c98 <release>
            return -1;
    8000256a:	59fd                	li	s3,-1
    8000256c:	a0a1                	j	800025b4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000256e:	18848493          	addi	s1,s1,392
    80002572:	03348463          	beq	s1,s3,8000259a <wait+0xe6>
      if(np->parent == p){
    80002576:	7c9c                	ld	a5,56(s1)
    80002578:	ff279be3          	bne	a5,s2,8000256e <wait+0xba>
        acquire(&np->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	666080e7          	jalr	1638(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002586:	4c9c                	lw	a5,24(s1)
    80002588:	f94781e3          	beq	a5,s4,8000250a <wait+0x56>
        release(&np->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
        havekids = 1;
    80002596:	8756                	mv	a4,s5
    80002598:	bfd9                	j	8000256e <wait+0xba>
    if(!havekids || p->killed){
    8000259a:	c701                	beqz	a4,800025a2 <wait+0xee>
    8000259c:	02892783          	lw	a5,40(s2)
    800025a0:	c79d                	beqz	a5,800025ce <wait+0x11a>
      release(&wait_lock);
    800025a2:	00008517          	auipc	a0,0x8
    800025a6:	c2650513          	addi	a0,a0,-986 # 8000a1c8 <wait_lock>
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6ee080e7          	jalr	1774(ra) # 80000c98 <release>
      return -1;
    800025b2:	59fd                	li	s3,-1
}
    800025b4:	854e                	mv	a0,s3
    800025b6:	60a6                	ld	ra,72(sp)
    800025b8:	6406                	ld	s0,64(sp)
    800025ba:	74e2                	ld	s1,56(sp)
    800025bc:	7942                	ld	s2,48(sp)
    800025be:	79a2                	ld	s3,40(sp)
    800025c0:	7a02                	ld	s4,32(sp)
    800025c2:	6ae2                	ld	s5,24(sp)
    800025c4:	6b42                	ld	s6,16(sp)
    800025c6:	6ba2                	ld	s7,8(sp)
    800025c8:	6c02                	ld	s8,0(sp)
    800025ca:	6161                	addi	sp,sp,80
    800025cc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025ce:	85e2                	mv	a1,s8
    800025d0:	854a                	mv	a0,s2
    800025d2:	00000097          	auipc	ra,0x0
    800025d6:	e62080e7          	jalr	-414(ra) # 80002434 <sleep>
    havekids = 0;
    800025da:	b715                	j	800024fe <wait+0x4a>

00000000800025dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025dc:	7139                	addi	sp,sp,-64
    800025de:	fc06                	sd	ra,56(sp)
    800025e0:	f822                	sd	s0,48(sp)
    800025e2:	f426                	sd	s1,40(sp)
    800025e4:	f04a                	sd	s2,32(sp)
    800025e6:	ec4e                	sd	s3,24(sp)
    800025e8:	e852                	sd	s4,16(sp)
    800025ea:	e456                	sd	s5,8(sp)
    800025ec:	e05a                	sd	s6,0(sp)
    800025ee:	0080                	addi	s0,sp,64
    800025f0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800025f2:	00008497          	auipc	s1,0x8
    800025f6:	c6e48493          	addi	s1,s1,-914 # 8000a260 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800025fa:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025fc:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    800025fe:	00007a97          	auipc	s5,0x7
    80002602:	a5aa8a93          	addi	s5,s5,-1446 # 80009058 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002606:	0000e917          	auipc	s2,0xe
    8000260a:	e5a90913          	addi	s2,s2,-422 # 80010460 <tickslock>
    8000260e:	a805                	j	8000263e <wakeup+0x62>
        p->state = RUNNABLE;
    80002610:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002614:	000aa703          	lw	a4,0(s5)
    80002618:	16e4aa23          	sw	a4,372(s1)
        // p->start_cpu_burst = ticks;
        p->sleeping_time += ticks - p->start_sleeping;
    8000261c:	1784a783          	lw	a5,376(s1)
    80002620:	9fb9                	addw	a5,a5,a4
    80002622:	1844a703          	lw	a4,388(s1)
    80002626:	9f99                	subw	a5,a5,a4
    80002628:	16f4ac23          	sw	a5,376(s1)
      }
      release(&p->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002636:	18848493          	addi	s1,s1,392
    8000263a:	03248463          	beq	s1,s2,80002662 <wakeup+0x86>
    if(p != myproc()){
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	38a080e7          	jalr	906(ra) # 800019c8 <myproc>
    80002646:	fea488e3          	beq	s1,a0,80002636 <wakeup+0x5a>
      acquire(&p->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	598080e7          	jalr	1432(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002654:	4c9c                	lw	a5,24(s1)
    80002656:	fd379be3          	bne	a5,s3,8000262c <wakeup+0x50>
    8000265a:	709c                	ld	a5,32(s1)
    8000265c:	fd4798e3          	bne	a5,s4,8000262c <wakeup+0x50>
    80002660:	bf45                	j	80002610 <wakeup+0x34>
    }
  }
}
    80002662:	70e2                	ld	ra,56(sp)
    80002664:	7442                	ld	s0,48(sp)
    80002666:	74a2                	ld	s1,40(sp)
    80002668:	7902                	ld	s2,32(sp)
    8000266a:	69e2                	ld	s3,24(sp)
    8000266c:	6a42                	ld	s4,16(sp)
    8000266e:	6aa2                	ld	s5,8(sp)
    80002670:	6b02                	ld	s6,0(sp)
    80002672:	6121                	addi	sp,sp,64
    80002674:	8082                	ret

0000000080002676 <reparent>:
{
    80002676:	7179                	addi	sp,sp,-48
    80002678:	f406                	sd	ra,40(sp)
    8000267a:	f022                	sd	s0,32(sp)
    8000267c:	ec26                	sd	s1,24(sp)
    8000267e:	e84a                	sd	s2,16(sp)
    80002680:	e44e                	sd	s3,8(sp)
    80002682:	e052                	sd	s4,0(sp)
    80002684:	1800                	addi	s0,sp,48
    80002686:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002688:	00008497          	auipc	s1,0x8
    8000268c:	bd848493          	addi	s1,s1,-1064 # 8000a260 <proc>
      pp->parent = initproc;
    80002690:	00007a17          	auipc	s4,0x7
    80002694:	9c0a0a13          	addi	s4,s4,-1600 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002698:	0000e997          	auipc	s3,0xe
    8000269c:	dc898993          	addi	s3,s3,-568 # 80010460 <tickslock>
    800026a0:	a029                	j	800026aa <reparent+0x34>
    800026a2:	18848493          	addi	s1,s1,392
    800026a6:	01348d63          	beq	s1,s3,800026c0 <reparent+0x4a>
    if(pp->parent == p){
    800026aa:	7c9c                	ld	a5,56(s1)
    800026ac:	ff279be3          	bne	a5,s2,800026a2 <reparent+0x2c>
      pp->parent = initproc;
    800026b0:	000a3503          	ld	a0,0(s4)
    800026b4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026b6:	00000097          	auipc	ra,0x0
    800026ba:	f26080e7          	jalr	-218(ra) # 800025dc <wakeup>
    800026be:	b7d5                	j	800026a2 <reparent+0x2c>
}
    800026c0:	70a2                	ld	ra,40(sp)
    800026c2:	7402                	ld	s0,32(sp)
    800026c4:	64e2                	ld	s1,24(sp)
    800026c6:	6942                	ld	s2,16(sp)
    800026c8:	69a2                	ld	s3,8(sp)
    800026ca:	6a02                	ld	s4,0(sp)
    800026cc:	6145                	addi	sp,sp,48
    800026ce:	8082                	ret

00000000800026d0 <exit>:
{
    800026d0:	7179                	addi	sp,sp,-48
    800026d2:	f406                	sd	ra,40(sp)
    800026d4:	f022                	sd	s0,32(sp)
    800026d6:	ec26                	sd	s1,24(sp)
    800026d8:	e84a                	sd	s2,16(sp)
    800026da:	e44e                	sd	s3,8(sp)
    800026dc:	e052                	sd	s4,0(sp)
    800026de:	1800                	addi	s0,sp,48
    800026e0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026e2:	fffff097          	auipc	ra,0xfffff
    800026e6:	2e6080e7          	jalr	742(ra) # 800019c8 <myproc>
    800026ea:	892a                	mv	s2,a0
  if(p == initproc)
    800026ec:	00007797          	auipc	a5,0x7
    800026f0:	9647b783          	ld	a5,-1692(a5) # 80009050 <initproc>
    800026f4:	0d050493          	addi	s1,a0,208
    800026f8:	15050993          	addi	s3,a0,336
    800026fc:	02a79363          	bne	a5,a0,80002722 <exit+0x52>
    panic("init exiting");
    80002700:	00006517          	auipc	a0,0x6
    80002704:	b9850513          	addi	a0,a0,-1128 # 80008298 <digits+0x258>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	e36080e7          	jalr	-458(ra) # 8000053e <panic>
      fileclose(f);
    80002710:	00002097          	auipc	ra,0x2
    80002714:	404080e7          	jalr	1028(ra) # 80004b14 <fileclose>
      p->ofile[fd] = 0;
    80002718:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000271c:	04a1                	addi	s1,s1,8
    8000271e:	01348563          	beq	s1,s3,80002728 <exit+0x58>
    if(p->ofile[fd]){
    80002722:	6088                	ld	a0,0(s1)
    80002724:	f575                	bnez	a0,80002710 <exit+0x40>
    80002726:	bfdd                	j	8000271c <exit+0x4c>
  begin_op();
    80002728:	00002097          	auipc	ra,0x2
    8000272c:	f20080e7          	jalr	-224(ra) # 80004648 <begin_op>
  iput(p->cwd);
    80002730:	15093503          	ld	a0,336(s2)
    80002734:	00001097          	auipc	ra,0x1
    80002738:	6fc080e7          	jalr	1788(ra) # 80003e30 <iput>
  end_op();
    8000273c:	00002097          	auipc	ra,0x2
    80002740:	f8c080e7          	jalr	-116(ra) # 800046c8 <end_op>
  p->cwd = 0;
    80002744:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002748:	00008497          	auipc	s1,0x8
    8000274c:	a8048493          	addi	s1,s1,-1408 # 8000a1c8 <wait_lock>
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	492080e7          	jalr	1170(ra) # 80000be4 <acquire>
  reparent(p);
    8000275a:	854a                	mv	a0,s2
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	f1a080e7          	jalr	-230(ra) # 80002676 <reparent>
  wakeup(p->parent);
    80002764:	03893503          	ld	a0,56(s2)
    80002768:	00000097          	auipc	ra,0x0
    8000276c:	e74080e7          	jalr	-396(ra) # 800025dc <wakeup>
  acquire(&p->lock);
    80002770:	854a                	mv	a0,s2
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	472080e7          	jalr	1138(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000277a:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000277e:	4795                	li	a5,5
    80002780:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
  num_processes++;
    8000278e:	00007717          	auipc	a4,0x7
    80002792:	8a670713          	addi	a4,a4,-1882 # 80009034 <num_processes>
    80002796:	431c                	lw	a5,0(a4)
    80002798:	2785                	addiw	a5,a5,1
    8000279a:	c31c                	sw	a5,0(a4)
  p->running_time += (ticks - p->start_cpu_burst);
    8000279c:	00007617          	auipc	a2,0x7
    800027a0:	8bc62603          	lw	a2,-1860(a2) # 80009058 <ticks>
    800027a4:	18092683          	lw	a3,384(s2)
    800027a8:	9eb1                	addw	a3,a3,a2
    800027aa:	17092703          	lw	a4,368(s2)
    800027ae:	9e99                	subw	a3,a3,a4
    800027b0:	18d92023          	sw	a3,384(s2)
  sleeping_processes_mean = ((sleeping_processes_mean * num_processes) + p->sleeping_time) / (num_processes);
    800027b4:	00007597          	auipc	a1,0x7
    800027b8:	89458593          	addi	a1,a1,-1900 # 80009048 <sleeping_processes_mean>
    800027bc:	4198                	lw	a4,0(a1)
    800027be:	02f7073b          	mulw	a4,a4,a5
    800027c2:	17892503          	lw	a0,376(s2)
    800027c6:	9f29                	addw	a4,a4,a0
    800027c8:	02f7573b          	divuw	a4,a4,a5
    800027cc:	c198                	sw	a4,0(a1)
  running_processes_mean = (((running_processes_mean) * num_processes) + p->running_time) / (num_processes);
    800027ce:	00007597          	auipc	a1,0x7
    800027d2:	87658593          	addi	a1,a1,-1930 # 80009044 <running_processes_mean>
    800027d6:	4198                	lw	a4,0(a1)
    800027d8:	02f7073b          	mulw	a4,a4,a5
    800027dc:	9f35                	addw	a4,a4,a3
    800027de:	02f7573b          	divuw	a4,a4,a5
    800027e2:	c198                	sw	a4,0(a1)
  runnable_processes_mean = ((runnable_processes_mean * num_processes) + p->runnable_time) / (num_processes);
    800027e4:	00007597          	auipc	a1,0x7
    800027e8:	85c58593          	addi	a1,a1,-1956 # 80009040 <runnable_processes_mean>
    800027ec:	4198                	lw	a4,0(a1)
    800027ee:	02f7073b          	mulw	a4,a4,a5
    800027f2:	17c92503          	lw	a0,380(s2)
    800027f6:	9f29                	addw	a4,a4,a0
    800027f8:	02f757bb          	divuw	a5,a4,a5
    800027fc:	c19c                	sw	a5,0(a1)
  if(p->pid != 1 && p->pid != 2){
    800027fe:	03092783          	lw	a5,48(s2)
    80002802:	37fd                	addiw	a5,a5,-1
    80002804:	4705                	li	a4,1
    80002806:	02f77863          	bgeu	a4,a5,80002836 <exit+0x166>
    program_time += p->running_time;
    8000280a:	00007717          	auipc	a4,0x7
    8000280e:	82670713          	addi	a4,a4,-2010 # 80009030 <program_time>
    80002812:	431c                	lw	a5,0(a4)
    80002814:	9fb5                	addw	a5,a5,a3
    80002816:	c31c                	sw	a5,0(a4)
    cpu_utilization = (program_time * 100) / (ticks - start_time);
    80002818:	06400693          	li	a3,100
    8000281c:	02f686bb          	mulw	a3,a3,a5
    80002820:	00007797          	auipc	a5,0x7
    80002824:	8087a783          	lw	a5,-2040(a5) # 80009028 <start_time>
    80002828:	9e1d                	subw	a2,a2,a5
    8000282a:	02c6d63b          	divuw	a2,a3,a2
    8000282e:	00006797          	auipc	a5,0x6
    80002832:	7ec7af23          	sw	a2,2046(a5) # 8000902c <cpu_utilization>
  sched();
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	ad0080e7          	jalr	-1328(ra) # 80002306 <sched>
  panic("zombie exit");
    8000283e:	00006517          	auipc	a0,0x6
    80002842:	a6a50513          	addi	a0,a0,-1430 # 800082a8 <digits+0x268>
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	cf8080e7          	jalr	-776(ra) # 8000053e <panic>

000000008000284e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000284e:	7179                	addi	sp,sp,-48
    80002850:	f406                	sd	ra,40(sp)
    80002852:	f022                	sd	s0,32(sp)
    80002854:	ec26                	sd	s1,24(sp)
    80002856:	e84a                	sd	s2,16(sp)
    80002858:	e44e                	sd	s3,8(sp)
    8000285a:	1800                	addi	s0,sp,48
    8000285c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000285e:	00008497          	auipc	s1,0x8
    80002862:	a0248493          	addi	s1,s1,-1534 # 8000a260 <proc>
    80002866:	0000e997          	auipc	s3,0xe
    8000286a:	bfa98993          	addi	s3,s3,-1030 # 80010460 <tickslock>
    acquire(&p->lock);
    8000286e:	8526                	mv	a0,s1
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	374080e7          	jalr	884(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002878:	589c                	lw	a5,48(s1)
    8000287a:	01278d63          	beq	a5,s2,80002894 <kill+0x46>
        p->sleeping_time +=  ticks - p->start_sleeping;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000287e:	8526                	mv	a0,s1
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	418080e7          	jalr	1048(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002888:	18848493          	addi	s1,s1,392
    8000288c:	ff3491e3          	bne	s1,s3,8000286e <kill+0x20>
  }
  return -1;
    80002890:	557d                	li	a0,-1
    80002892:	a829                	j	800028ac <kill+0x5e>
      p->killed = 1;
    80002894:	4785                	li	a5,1
    80002896:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002898:	4c98                	lw	a4,24(s1)
    8000289a:	4789                	li	a5,2
    8000289c:	00f70f63          	beq	a4,a5,800028ba <kill+0x6c>
      release(&p->lock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	3f6080e7          	jalr	1014(ra) # 80000c98 <release>
      return 0;
    800028aa:	4501                	li	a0,0
}
    800028ac:	70a2                	ld	ra,40(sp)
    800028ae:	7402                	ld	s0,32(sp)
    800028b0:	64e2                	ld	s1,24(sp)
    800028b2:	6942                	ld	s2,16(sp)
    800028b4:	69a2                	ld	s3,8(sp)
    800028b6:	6145                	addi	sp,sp,48
    800028b8:	8082                	ret
        p->state = RUNNABLE;
    800028ba:	478d                	li	a5,3
    800028bc:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    800028be:	00006717          	auipc	a4,0x6
    800028c2:	79a72703          	lw	a4,1946(a4) # 80009058 <ticks>
    800028c6:	16e4aa23          	sw	a4,372(s1)
        p->sleeping_time +=  ticks - p->start_sleeping;
    800028ca:	1784a783          	lw	a5,376(s1)
    800028ce:	9fb9                	addw	a5,a5,a4
    800028d0:	1844a703          	lw	a4,388(s1)
    800028d4:	9f99                	subw	a5,a5,a4
    800028d6:	16f4ac23          	sw	a5,376(s1)
    800028da:	b7d9                	j	800028a0 <kill+0x52>

00000000800028dc <kill_system>:

int
kill_system()
{
    800028dc:	711d                	addi	sp,sp,-96
    800028de:	ec86                	sd	ra,88(sp)
    800028e0:	e8a2                	sd	s0,80(sp)
    800028e2:	e4a6                	sd	s1,72(sp)
    800028e4:	e0ca                	sd	s2,64(sp)
    800028e6:	fc4e                	sd	s3,56(sp)
    800028e8:	f852                	sd	s4,48(sp)
    800028ea:	f456                	sd	s5,40(sp)
    800028ec:	f05a                	sd	s6,32(sp)
    800028ee:	ec5e                	sd	s7,24(sp)
    800028f0:	e862                	sd	s8,16(sp)
    800028f2:	e466                	sd	s9,8(sp)
    800028f4:	1080                	addi	s0,sp,96
  struct proc *myp = myproc();
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	0d2080e7          	jalr	210(ra) # 800019c8 <myproc>
    800028fe:	8caa                	mv	s9,a0
  int mypid = myp->pid;
    80002900:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	2e0080e7          	jalr	736(ra) # 80000be4 <acquire>
  struct proc *p;

  for(p = proc;p < &proc[NPROC]; p++){
    8000290c:	00008497          	auipc	s1,0x8
    80002910:	95448493          	addi	s1,s1,-1708 # 8000a260 <proc>
    if(p->pid != mypid){
      acquire(&p->lock);
      if(p->pid != 1 && p->pid != 2){
    80002914:	4a05                	li	s4,1
        p->killed = 1;
    80002916:	4b05                	li	s6,1
        if(p->state == SLEEPING){
    80002918:	4a89                	li	s5,2
          // Wake process from sleep().
          p->state = RUNNABLE;
    8000291a:	4c0d                	li	s8,3
          p->last_runnable_time = ticks;
    8000291c:	00006b97          	auipc	s7,0x6
    80002920:	73cb8b93          	addi	s7,s7,1852 # 80009058 <ticks>
  for(p = proc;p < &proc[NPROC]; p++){
    80002924:	0000e917          	auipc	s2,0xe
    80002928:	b3c90913          	addi	s2,s2,-1220 # 80010460 <tickslock>
    8000292c:	a811                	j	80002940 <kill_system+0x64>
          p->sleeping_time +=  ticks - p->start_sleeping;
        }
      }
      release(&p->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	368080e7          	jalr	872(ra) # 80000c98 <release>
  for(p = proc;p < &proc[NPROC]; p++){
    80002938:	18848493          	addi	s1,s1,392
    8000293c:	05248263          	beq	s1,s2,80002980 <kill_system+0xa4>
    if(p->pid != mypid){
    80002940:	589c                	lw	a5,48(s1)
    80002942:	ff378be3          	beq	a5,s3,80002938 <kill_system+0x5c>
      acquire(&p->lock);
    80002946:	8526                	mv	a0,s1
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
      if(p->pid != 1 && p->pid != 2){
    80002950:	589c                	lw	a5,48(s1)
    80002952:	37fd                	addiw	a5,a5,-1
    80002954:	fcfa7de3          	bgeu	s4,a5,8000292e <kill_system+0x52>
        p->killed = 1;
    80002958:	0364a423          	sw	s6,40(s1)
        if(p->state == SLEEPING){
    8000295c:	4c9c                	lw	a5,24(s1)
    8000295e:	fd5798e3          	bne	a5,s5,8000292e <kill_system+0x52>
          p->state = RUNNABLE;
    80002962:	0184ac23          	sw	s8,24(s1)
          p->last_runnable_time = ticks;
    80002966:	000ba703          	lw	a4,0(s7)
    8000296a:	16e4aa23          	sw	a4,372(s1)
          p->sleeping_time +=  ticks - p->start_sleeping;
    8000296e:	1784a783          	lw	a5,376(s1)
    80002972:	9fb9                	addw	a5,a5,a4
    80002974:	1844a703          	lw	a4,388(s1)
    80002978:	9f99                	subw	a5,a5,a4
    8000297a:	16f4ac23          	sw	a5,376(s1)
    8000297e:	bf45                	j	8000292e <kill_system+0x52>
    }
  }

  myp->killed = 1;
    80002980:	4785                	li	a5,1
    80002982:	02fca423          	sw	a5,40(s9)
  release(&myp->lock);
    80002986:	8566                	mv	a0,s9
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	310080e7          	jalr	784(ra) # 80000c98 <release>
  return 0;
}
    80002990:	4501                	li	a0,0
    80002992:	60e6                	ld	ra,88(sp)
    80002994:	6446                	ld	s0,80(sp)
    80002996:	64a6                	ld	s1,72(sp)
    80002998:	6906                	ld	s2,64(sp)
    8000299a:	79e2                	ld	s3,56(sp)
    8000299c:	7a42                	ld	s4,48(sp)
    8000299e:	7aa2                	ld	s5,40(sp)
    800029a0:	7b02                	ld	s6,32(sp)
    800029a2:	6be2                	ld	s7,24(sp)
    800029a4:	6c42                	ld	s8,16(sp)
    800029a6:	6ca2                	ld	s9,8(sp)
    800029a8:	6125                	addi	sp,sp,96
    800029aa:	8082                	ret

00000000800029ac <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029ac:	7179                	addi	sp,sp,-48
    800029ae:	f406                	sd	ra,40(sp)
    800029b0:	f022                	sd	s0,32(sp)
    800029b2:	ec26                	sd	s1,24(sp)
    800029b4:	e84a                	sd	s2,16(sp)
    800029b6:	e44e                	sd	s3,8(sp)
    800029b8:	e052                	sd	s4,0(sp)
    800029ba:	1800                	addi	s0,sp,48
    800029bc:	84aa                	mv	s1,a0
    800029be:	892e                	mv	s2,a1
    800029c0:	89b2                	mv	s3,a2
    800029c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	004080e7          	jalr	4(ra) # 800019c8 <myproc>
  if(user_dst){
    800029cc:	c08d                	beqz	s1,800029ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029ce:	86d2                	mv	a3,s4
    800029d0:	864e                	mv	a2,s3
    800029d2:	85ca                	mv	a1,s2
    800029d4:	6928                	ld	a0,80(a0)
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	ca4080e7          	jalr	-860(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029de:	70a2                	ld	ra,40(sp)
    800029e0:	7402                	ld	s0,32(sp)
    800029e2:	64e2                	ld	s1,24(sp)
    800029e4:	6942                	ld	s2,16(sp)
    800029e6:	69a2                	ld	s3,8(sp)
    800029e8:	6a02                	ld	s4,0(sp)
    800029ea:	6145                	addi	sp,sp,48
    800029ec:	8082                	ret
    memmove((char *)dst, src, len);
    800029ee:	000a061b          	sext.w	a2,s4
    800029f2:	85ce                	mv	a1,s3
    800029f4:	854a                	mv	a0,s2
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	34a080e7          	jalr	842(ra) # 80000d40 <memmove>
    return 0;
    800029fe:	8526                	mv	a0,s1
    80002a00:	bff9                	j	800029de <either_copyout+0x32>

0000000080002a02 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a02:	7179                	addi	sp,sp,-48
    80002a04:	f406                	sd	ra,40(sp)
    80002a06:	f022                	sd	s0,32(sp)
    80002a08:	ec26                	sd	s1,24(sp)
    80002a0a:	e84a                	sd	s2,16(sp)
    80002a0c:	e44e                	sd	s3,8(sp)
    80002a0e:	e052                	sd	s4,0(sp)
    80002a10:	1800                	addi	s0,sp,48
    80002a12:	892a                	mv	s2,a0
    80002a14:	84ae                	mv	s1,a1
    80002a16:	89b2                	mv	s3,a2
    80002a18:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	fae080e7          	jalr	-82(ra) # 800019c8 <myproc>
  if(user_src){
    80002a22:	c08d                	beqz	s1,80002a44 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a24:	86d2                	mv	a3,s4
    80002a26:	864e                	mv	a2,s3
    80002a28:	85ca                	mv	a1,s2
    80002a2a:	6928                	ld	a0,80(a0)
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	cda080e7          	jalr	-806(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a34:	70a2                	ld	ra,40(sp)
    80002a36:	7402                	ld	s0,32(sp)
    80002a38:	64e2                	ld	s1,24(sp)
    80002a3a:	6942                	ld	s2,16(sp)
    80002a3c:	69a2                	ld	s3,8(sp)
    80002a3e:	6a02                	ld	s4,0(sp)
    80002a40:	6145                	addi	sp,sp,48
    80002a42:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a44:	000a061b          	sext.w	a2,s4
    80002a48:	85ce                	mv	a1,s3
    80002a4a:	854a                	mv	a0,s2
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	2f4080e7          	jalr	756(ra) # 80000d40 <memmove>
    return 0;
    80002a54:	8526                	mv	a0,s1
    80002a56:	bff9                	j	80002a34 <either_copyin+0x32>

0000000080002a58 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a58:	715d                	addi	sp,sp,-80
    80002a5a:	e486                	sd	ra,72(sp)
    80002a5c:	e0a2                	sd	s0,64(sp)
    80002a5e:	fc26                	sd	s1,56(sp)
    80002a60:	f84a                	sd	s2,48(sp)
    80002a62:	f44e                	sd	s3,40(sp)
    80002a64:	f052                	sd	s4,32(sp)
    80002a66:	ec56                	sd	s5,24(sp)
    80002a68:	e85a                	sd	s6,16(sp)
    80002a6a:	e45e                	sd	s7,8(sp)
    80002a6c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	8f250513          	addi	a0,a0,-1806 # 80008360 <digits+0x320>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	b12080e7          	jalr	-1262(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a7e:	00008497          	auipc	s1,0x8
    80002a82:	93a48493          	addi	s1,s1,-1734 # 8000a3b8 <proc+0x158>
    80002a86:	0000e917          	auipc	s2,0xe
    80002a8a:	b3290913          	addi	s2,s2,-1230 # 800105b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a8e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a90:	00006997          	auipc	s3,0x6
    80002a94:	82898993          	addi	s3,s3,-2008 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    80002a98:	00006a97          	auipc	s5,0x6
    80002a9c:	828a8a93          	addi	s5,s5,-2008 # 800082c0 <digits+0x280>
    printf("\n");
    80002aa0:	00006a17          	auipc	s4,0x6
    80002aa4:	8c0a0a13          	addi	s4,s4,-1856 # 80008360 <digits+0x320>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa8:	00006b97          	auipc	s7,0x6
    80002aac:	8e8b8b93          	addi	s7,s7,-1816 # 80008390 <states.1871>
    80002ab0:	a00d                	j	80002ad2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ab2:	ed86a583          	lw	a1,-296(a3)
    80002ab6:	8556                	mv	a0,s5
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	ad0080e7          	jalr	-1328(ra) # 80000588 <printf>
    printf("\n");
    80002ac0:	8552                	mv	a0,s4
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	ac6080e7          	jalr	-1338(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002aca:	18848493          	addi	s1,s1,392
    80002ace:	03248163          	beq	s1,s2,80002af0 <procdump+0x98>
    if(p->state == UNUSED)
    80002ad2:	86a6                	mv	a3,s1
    80002ad4:	ec04a783          	lw	a5,-320(s1)
    80002ad8:	dbed                	beqz	a5,80002aca <procdump+0x72>
      state = "???";
    80002ada:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002adc:	fcfb6be3          	bltu	s6,a5,80002ab2 <procdump+0x5a>
    80002ae0:	1782                	slli	a5,a5,0x20
    80002ae2:	9381                	srli	a5,a5,0x20
    80002ae4:	078e                	slli	a5,a5,0x3
    80002ae6:	97de                	add	a5,a5,s7
    80002ae8:	6390                	ld	a2,0(a5)
    80002aea:	f661                	bnez	a2,80002ab2 <procdump+0x5a>
      state = "???";
    80002aec:	864e                	mv	a2,s3
    80002aee:	b7d1                	j	80002ab2 <procdump+0x5a>
  }
}
    80002af0:	60a6                	ld	ra,72(sp)
    80002af2:	6406                	ld	s0,64(sp)
    80002af4:	74e2                	ld	s1,56(sp)
    80002af6:	7942                	ld	s2,48(sp)
    80002af8:	79a2                	ld	s3,40(sp)
    80002afa:	7a02                	ld	s4,32(sp)
    80002afc:	6ae2                	ld	s5,24(sp)
    80002afe:	6b42                	ld	s6,16(sp)
    80002b00:	6ba2                	ld	s7,8(sp)
    80002b02:	6161                	addi	sp,sp,80
    80002b04:	8082                	ret

0000000080002b06 <pause_system>:

int
pause_system(int seconds)
{
    80002b06:	1141                	addi	sp,sp,-16
    80002b08:	e406                	sd	ra,8(sp)
    80002b0a:	e022                	sd	s0,0(sp)
    80002b0c:	0800                	addi	s0,sp,16
  pause_time = ticks + seconds*10;  
    80002b0e:	0025179b          	slliw	a5,a0,0x2
    80002b12:	9fa9                	addw	a5,a5,a0
    80002b14:	0017979b          	slliw	a5,a5,0x1
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	54052503          	lw	a0,1344(a0) # 80009058 <ticks>
    80002b20:	9fa9                	addw	a5,a5,a0
    80002b22:	00006717          	auipc	a4,0x6
    80002b26:	52f72523          	sw	a5,1322(a4) # 8000904c <pause_time>
  yield();
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	8b2080e7          	jalr	-1870(ra) # 800023dc <yield>
  return 0;
}
    80002b32:	4501                	li	a0,0
    80002b34:	60a2                	ld	ra,8(sp)
    80002b36:	6402                	ld	s0,0(sp)
    80002b38:	0141                	addi	sp,sp,16
    80002b3a:	8082                	ret

0000000080002b3c <print_stats>:

void
print_stats(void){
    80002b3c:	1141                	addi	sp,sp,-16
    80002b3e:	e406                	sd	ra,8(sp)
    80002b40:	e022                	sd	s0,0(sp)
    80002b42:	0800                	addi	s0,sp,16
    printf("Mean running time: %d\n", running_processes_mean);
    80002b44:	00006597          	auipc	a1,0x6
    80002b48:	5005a583          	lw	a1,1280(a1) # 80009044 <running_processes_mean>
    80002b4c:	00005517          	auipc	a0,0x5
    80002b50:	78450513          	addi	a0,a0,1924 # 800082d0 <digits+0x290>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	a34080e7          	jalr	-1484(ra) # 80000588 <printf>
    printf("Number of processes: %d\n", num_processes);
    80002b5c:	00006597          	auipc	a1,0x6
    80002b60:	4d85a583          	lw	a1,1240(a1) # 80009034 <num_processes>
    80002b64:	00005517          	auipc	a0,0x5
    80002b68:	78450513          	addi	a0,a0,1924 # 800082e8 <digits+0x2a8>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	a1c080e7          	jalr	-1508(ra) # 80000588 <printf>
    printf("Mean runnable time: %d\n", runnable_processes_mean);
    80002b74:	00006597          	auipc	a1,0x6
    80002b78:	4cc5a583          	lw	a1,1228(a1) # 80009040 <runnable_processes_mean>
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	78c50513          	addi	a0,a0,1932 # 80008308 <digits+0x2c8>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a04080e7          	jalr	-1532(ra) # 80000588 <printf>
    printf("Mean sleeping time: %d\n", sleeping_processes_mean);
    80002b8c:	00006597          	auipc	a1,0x6
    80002b90:	4bc5a583          	lw	a1,1212(a1) # 80009048 <sleeping_processes_mean>
    80002b94:	00005517          	auipc	a0,0x5
    80002b98:	78c50513          	addi	a0,a0,1932 # 80008320 <digits+0x2e0>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9ec080e7          	jalr	-1556(ra) # 80000588 <printf>
    printf("CPU utilization: %d\n", cpu_utilization);
    80002ba4:	00006597          	auipc	a1,0x6
    80002ba8:	4885a583          	lw	a1,1160(a1) # 8000902c <cpu_utilization>
    80002bac:	00005517          	auipc	a0,0x5
    80002bb0:	78c50513          	addi	a0,a0,1932 # 80008338 <digits+0x2f8>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	9d4080e7          	jalr	-1580(ra) # 80000588 <printf>
    printf("Program time: %d\n", program_time);
    80002bbc:	00006597          	auipc	a1,0x6
    80002bc0:	4745a583          	lw	a1,1140(a1) # 80009030 <program_time>
    80002bc4:	00005517          	auipc	a0,0x5
    80002bc8:	78c50513          	addi	a0,a0,1932 # 80008350 <digits+0x310>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9bc080e7          	jalr	-1604(ra) # 80000588 <printf>
}
    80002bd4:	60a2                	ld	ra,8(sp)
    80002bd6:	6402                	ld	s0,0(sp)
    80002bd8:	0141                	addi	sp,sp,16
    80002bda:	8082                	ret

0000000080002bdc <swtch>:
    80002bdc:	00153023          	sd	ra,0(a0)
    80002be0:	00253423          	sd	sp,8(a0)
    80002be4:	e900                	sd	s0,16(a0)
    80002be6:	ed04                	sd	s1,24(a0)
    80002be8:	03253023          	sd	s2,32(a0)
    80002bec:	03353423          	sd	s3,40(a0)
    80002bf0:	03453823          	sd	s4,48(a0)
    80002bf4:	03553c23          	sd	s5,56(a0)
    80002bf8:	05653023          	sd	s6,64(a0)
    80002bfc:	05753423          	sd	s7,72(a0)
    80002c00:	05853823          	sd	s8,80(a0)
    80002c04:	05953c23          	sd	s9,88(a0)
    80002c08:	07a53023          	sd	s10,96(a0)
    80002c0c:	07b53423          	sd	s11,104(a0)
    80002c10:	0005b083          	ld	ra,0(a1)
    80002c14:	0085b103          	ld	sp,8(a1)
    80002c18:	6980                	ld	s0,16(a1)
    80002c1a:	6d84                	ld	s1,24(a1)
    80002c1c:	0205b903          	ld	s2,32(a1)
    80002c20:	0285b983          	ld	s3,40(a1)
    80002c24:	0305ba03          	ld	s4,48(a1)
    80002c28:	0385ba83          	ld	s5,56(a1)
    80002c2c:	0405bb03          	ld	s6,64(a1)
    80002c30:	0485bb83          	ld	s7,72(a1)
    80002c34:	0505bc03          	ld	s8,80(a1)
    80002c38:	0585bc83          	ld	s9,88(a1)
    80002c3c:	0605bd03          	ld	s10,96(a1)
    80002c40:	0685bd83          	ld	s11,104(a1)
    80002c44:	8082                	ret

0000000080002c46 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c46:	1141                	addi	sp,sp,-16
    80002c48:	e406                	sd	ra,8(sp)
    80002c4a:	e022                	sd	s0,0(sp)
    80002c4c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c4e:	00005597          	auipc	a1,0x5
    80002c52:	77258593          	addi	a1,a1,1906 # 800083c0 <states.1871+0x30>
    80002c56:	0000e517          	auipc	a0,0xe
    80002c5a:	80a50513          	addi	a0,a0,-2038 # 80010460 <tickslock>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	ef6080e7          	jalr	-266(ra) # 80000b54 <initlock>
}
    80002c66:	60a2                	ld	ra,8(sp)
    80002c68:	6402                	ld	s0,0(sp)
    80002c6a:	0141                	addi	sp,sp,16
    80002c6c:	8082                	ret

0000000080002c6e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c6e:	1141                	addi	sp,sp,-16
    80002c70:	e422                	sd	s0,8(sp)
    80002c72:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c74:	00003797          	auipc	a5,0x3
    80002c78:	4bc78793          	addi	a5,a5,1212 # 80006130 <kernelvec>
    80002c7c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c80:	6422                	ld	s0,8(sp)
    80002c82:	0141                	addi	sp,sp,16
    80002c84:	8082                	ret

0000000080002c86 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e406                	sd	ra,8(sp)
    80002c8a:	e022                	sd	s0,0(sp)
    80002c8c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	d3a080e7          	jalr	-710(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c9a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c9c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ca0:	00004617          	auipc	a2,0x4
    80002ca4:	36060613          	addi	a2,a2,864 # 80007000 <_trampoline>
    80002ca8:	00004697          	auipc	a3,0x4
    80002cac:	35868693          	addi	a3,a3,856 # 80007000 <_trampoline>
    80002cb0:	8e91                	sub	a3,a3,a2
    80002cb2:	040007b7          	lui	a5,0x4000
    80002cb6:	17fd                	addi	a5,a5,-1
    80002cb8:	07b2                	slli	a5,a5,0xc
    80002cba:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cbc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cc0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cc2:	180026f3          	csrr	a3,satp
    80002cc6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cc8:	6d38                	ld	a4,88(a0)
    80002cca:	6134                	ld	a3,64(a0)
    80002ccc:	6585                	lui	a1,0x1
    80002cce:	96ae                	add	a3,a3,a1
    80002cd0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cd2:	6d38                	ld	a4,88(a0)
    80002cd4:	00000697          	auipc	a3,0x0
    80002cd8:	13868693          	addi	a3,a3,312 # 80002e0c <usertrap>
    80002cdc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cde:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ce0:	8692                	mv	a3,tp
    80002ce2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ce8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cec:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cf4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cf6:	6f18                	ld	a4,24(a4)
    80002cf8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cfc:	692c                	ld	a1,80(a0)
    80002cfe:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d00:	00004717          	auipc	a4,0x4
    80002d04:	39070713          	addi	a4,a4,912 # 80007090 <userret>
    80002d08:	8f11                	sub	a4,a4,a2
    80002d0a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d0c:	577d                	li	a4,-1
    80002d0e:	177e                	slli	a4,a4,0x3f
    80002d10:	8dd9                	or	a1,a1,a4
    80002d12:	02000537          	lui	a0,0x2000
    80002d16:	157d                	addi	a0,a0,-1
    80002d18:	0536                	slli	a0,a0,0xd
    80002d1a:	9782                	jalr	a5
}
    80002d1c:	60a2                	ld	ra,8(sp)
    80002d1e:	6402                	ld	s0,0(sp)
    80002d20:	0141                	addi	sp,sp,16
    80002d22:	8082                	ret

0000000080002d24 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	e426                	sd	s1,8(sp)
    80002d2c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d2e:	0000d497          	auipc	s1,0xd
    80002d32:	73248493          	addi	s1,s1,1842 # 80010460 <tickslock>
    80002d36:	8526                	mv	a0,s1
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	eac080e7          	jalr	-340(ra) # 80000be4 <acquire>
  ticks++;
    80002d40:	00006517          	auipc	a0,0x6
    80002d44:	31850513          	addi	a0,a0,792 # 80009058 <ticks>
    80002d48:	411c                	lw	a5,0(a0)
    80002d4a:	2785                	addiw	a5,a5,1
    80002d4c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	88e080e7          	jalr	-1906(ra) # 800025dc <wakeup>
  release(&tickslock);
    80002d56:	8526                	mv	a0,s1
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	f40080e7          	jalr	-192(ra) # 80000c98 <release>
}
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	64a2                	ld	s1,8(sp)
    80002d66:	6105                	addi	sp,sp,32
    80002d68:	8082                	ret

0000000080002d6a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d74:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d78:	00074d63          	bltz	a4,80002d92 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d7c:	57fd                	li	a5,-1
    80002d7e:	17fe                	slli	a5,a5,0x3f
    80002d80:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d82:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d84:	06f70363          	beq	a4,a5,80002dea <devintr+0x80>
  }
}
    80002d88:	60e2                	ld	ra,24(sp)
    80002d8a:	6442                	ld	s0,16(sp)
    80002d8c:	64a2                	ld	s1,8(sp)
    80002d8e:	6105                	addi	sp,sp,32
    80002d90:	8082                	ret
     (scause & 0xff) == 9){
    80002d92:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d96:	46a5                	li	a3,9
    80002d98:	fed792e3          	bne	a5,a3,80002d7c <devintr+0x12>
    int irq = plic_claim();
    80002d9c:	00003097          	auipc	ra,0x3
    80002da0:	49c080e7          	jalr	1180(ra) # 80006238 <plic_claim>
    80002da4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002da6:	47a9                	li	a5,10
    80002da8:	02f50763          	beq	a0,a5,80002dd6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002dac:	4785                	li	a5,1
    80002dae:	02f50963          	beq	a0,a5,80002de0 <devintr+0x76>
    return 1;
    80002db2:	4505                	li	a0,1
    } else if(irq){
    80002db4:	d8f1                	beqz	s1,80002d88 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002db6:	85a6                	mv	a1,s1
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	61050513          	addi	a0,a0,1552 # 800083c8 <states.1871+0x38>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	7c8080e7          	jalr	1992(ra) # 80000588 <printf>
      plic_complete(irq);
    80002dc8:	8526                	mv	a0,s1
    80002dca:	00003097          	auipc	ra,0x3
    80002dce:	492080e7          	jalr	1170(ra) # 8000625c <plic_complete>
    return 1;
    80002dd2:	4505                	li	a0,1
    80002dd4:	bf55                	j	80002d88 <devintr+0x1e>
      uartintr();
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	bd2080e7          	jalr	-1070(ra) # 800009a8 <uartintr>
    80002dde:	b7ed                	j	80002dc8 <devintr+0x5e>
      virtio_disk_intr();
    80002de0:	00004097          	auipc	ra,0x4
    80002de4:	95c080e7          	jalr	-1700(ra) # 8000673c <virtio_disk_intr>
    80002de8:	b7c5                	j	80002dc8 <devintr+0x5e>
    if(cpuid() == 0){
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	bb2080e7          	jalr	-1102(ra) # 8000199c <cpuid>
    80002df2:	c901                	beqz	a0,80002e02 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002df4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002df8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dfa:	14479073          	csrw	sip,a5
    return 2;
    80002dfe:	4509                	li	a0,2
    80002e00:	b761                	j	80002d88 <devintr+0x1e>
      clockintr();
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	f22080e7          	jalr	-222(ra) # 80002d24 <clockintr>
    80002e0a:	b7ed                	j	80002df4 <devintr+0x8a>

0000000080002e0c <usertrap>:
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e16:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e1a:	1007f793          	andi	a5,a5,256
    80002e1e:	e3a5                	bnez	a5,80002e7e <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e20:	00003797          	auipc	a5,0x3
    80002e24:	31078793          	addi	a5,a5,784 # 80006130 <kernelvec>
    80002e28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	b9c080e7          	jalr	-1124(ra) # 800019c8 <myproc>
    80002e34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e36:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e38:	14102773          	csrr	a4,sepc
    80002e3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e3e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e42:	47a1                	li	a5,8
    80002e44:	04f71b63          	bne	a4,a5,80002e9a <usertrap+0x8e>
    if(p->killed)
    80002e48:	551c                	lw	a5,40(a0)
    80002e4a:	e3b1                	bnez	a5,80002e8e <usertrap+0x82>
    p->trapframe->epc += 4;
    80002e4c:	6cb8                	ld	a4,88(s1)
    80002e4e:	6f1c                	ld	a5,24(a4)
    80002e50:	0791                	addi	a5,a5,4
    80002e52:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e5c:	10079073          	csrw	sstatus,a5
    syscall();
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	2b4080e7          	jalr	692(ra) # 80003114 <syscall>
  if(p->killed)
    80002e68:	549c                	lw	a5,40(s1)
    80002e6a:	e7b5                	bnez	a5,80002ed6 <usertrap+0xca>
  usertrapret();
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	e1a080e7          	jalr	-486(ra) # 80002c86 <usertrapret>
}
    80002e74:	60e2                	ld	ra,24(sp)
    80002e76:	6442                	ld	s0,16(sp)
    80002e78:	64a2                	ld	s1,8(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret
    panic("usertrap: not from user mode");
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	56a50513          	addi	a0,a0,1386 # 800083e8 <states.1871+0x58>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
      exit(-1);
    80002e8e:	557d                	li	a0,-1
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	840080e7          	jalr	-1984(ra) # 800026d0 <exit>
    80002e98:	bf55                	j	80002e4c <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	ed0080e7          	jalr	-304(ra) # 80002d6a <devintr>
    80002ea2:	f179                	bnez	a0,80002e68 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ea4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ea8:	5890                	lw	a2,48(s1)
    80002eaa:	00005517          	auipc	a0,0x5
    80002eae:	55e50513          	addi	a0,a0,1374 # 80008408 <states.1871+0x78>
    80002eb2:	ffffd097          	auipc	ra,0xffffd
    80002eb6:	6d6080e7          	jalr	1750(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ebe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	57650513          	addi	a0,a0,1398 # 80008438 <states.1871+0xa8>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	6be080e7          	jalr	1726(ra) # 80000588 <printf>
    p->killed = 1;
    80002ed2:	4785                	li	a5,1
    80002ed4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ed6:	557d                	li	a0,-1
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	7f8080e7          	jalr	2040(ra) # 800026d0 <exit>
    80002ee0:	b771                	j	80002e6c <usertrap+0x60>

0000000080002ee2 <kerneltrap>:
{
    80002ee2:	7179                	addi	sp,sp,-48
    80002ee4:	f406                	sd	ra,40(sp)
    80002ee6:	f022                	sd	s0,32(sp)
    80002ee8:	ec26                	sd	s1,24(sp)
    80002eea:	e84a                	sd	s2,16(sp)
    80002eec:	e44e                	sd	s3,8(sp)
    80002eee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002efc:	1004f793          	andi	a5,s1,256
    80002f00:	cb85                	beqz	a5,80002f30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f08:	ef85                	bnez	a5,80002f40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f0a:	00000097          	auipc	ra,0x0
    80002f0e:	e60080e7          	jalr	-416(ra) # 80002d6a <devintr>
    80002f12:	cd1d                	beqz	a0,80002f50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f14:	4789                	li	a5,2
    80002f16:	06f50a63          	beq	a0,a5,80002f8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f1e:	10049073          	csrw	sstatus,s1
}
    80002f22:	70a2                	ld	ra,40(sp)
    80002f24:	7402                	ld	s0,32(sp)
    80002f26:	64e2                	ld	s1,24(sp)
    80002f28:	6942                	ld	s2,16(sp)
    80002f2a:	69a2                	ld	s3,8(sp)
    80002f2c:	6145                	addi	sp,sp,48
    80002f2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	52850513          	addi	a0,a0,1320 # 80008458 <states.1871+0xc8>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	606080e7          	jalr	1542(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f40:	00005517          	auipc	a0,0x5
    80002f44:	54050513          	addi	a0,a0,1344 # 80008480 <states.1871+0xf0>
    80002f48:	ffffd097          	auipc	ra,0xffffd
    80002f4c:	5f6080e7          	jalr	1526(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f50:	85ce                	mv	a1,s3
    80002f52:	00005517          	auipc	a0,0x5
    80002f56:	54e50513          	addi	a0,a0,1358 # 800084a0 <states.1871+0x110>
    80002f5a:	ffffd097          	auipc	ra,0xffffd
    80002f5e:	62e080e7          	jalr	1582(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f6a:	00005517          	auipc	a0,0x5
    80002f6e:	54650513          	addi	a0,a0,1350 # 800084b0 <states.1871+0x120>
    80002f72:	ffffd097          	auipc	ra,0xffffd
    80002f76:	616080e7          	jalr	1558(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f7a:	00005517          	auipc	a0,0x5
    80002f7e:	54e50513          	addi	a0,a0,1358 # 800084c8 <states.1871+0x138>
    80002f82:	ffffd097          	auipc	ra,0xffffd
    80002f86:	5bc080e7          	jalr	1468(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	a3e080e7          	jalr	-1474(ra) # 800019c8 <myproc>
    80002f92:	d541                	beqz	a0,80002f1a <kerneltrap+0x38>
    80002f94:	fffff097          	auipc	ra,0xfffff
    80002f98:	a34080e7          	jalr	-1484(ra) # 800019c8 <myproc>
    80002f9c:	bfbd                	j	80002f1a <kerneltrap+0x38>

0000000080002f9e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f9e:	1101                	addi	sp,sp,-32
    80002fa0:	ec06                	sd	ra,24(sp)
    80002fa2:	e822                	sd	s0,16(sp)
    80002fa4:	e426                	sd	s1,8(sp)
    80002fa6:	1000                	addi	s0,sp,32
    80002fa8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	a1e080e7          	jalr	-1506(ra) # 800019c8 <myproc>
  switch (n) {
    80002fb2:	4795                	li	a5,5
    80002fb4:	0497e163          	bltu	a5,s1,80002ff6 <argraw+0x58>
    80002fb8:	048a                	slli	s1,s1,0x2
    80002fba:	00005717          	auipc	a4,0x5
    80002fbe:	54670713          	addi	a4,a4,1350 # 80008500 <states.1871+0x170>
    80002fc2:	94ba                	add	s1,s1,a4
    80002fc4:	409c                	lw	a5,0(s1)
    80002fc6:	97ba                	add	a5,a5,a4
    80002fc8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fca:	6d3c                	ld	a5,88(a0)
    80002fcc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fce:	60e2                	ld	ra,24(sp)
    80002fd0:	6442                	ld	s0,16(sp)
    80002fd2:	64a2                	ld	s1,8(sp)
    80002fd4:	6105                	addi	sp,sp,32
    80002fd6:	8082                	ret
    return p->trapframe->a1;
    80002fd8:	6d3c                	ld	a5,88(a0)
    80002fda:	7fa8                	ld	a0,120(a5)
    80002fdc:	bfcd                	j	80002fce <argraw+0x30>
    return p->trapframe->a2;
    80002fde:	6d3c                	ld	a5,88(a0)
    80002fe0:	63c8                	ld	a0,128(a5)
    80002fe2:	b7f5                	j	80002fce <argraw+0x30>
    return p->trapframe->a3;
    80002fe4:	6d3c                	ld	a5,88(a0)
    80002fe6:	67c8                	ld	a0,136(a5)
    80002fe8:	b7dd                	j	80002fce <argraw+0x30>
    return p->trapframe->a4;
    80002fea:	6d3c                	ld	a5,88(a0)
    80002fec:	6bc8                	ld	a0,144(a5)
    80002fee:	b7c5                	j	80002fce <argraw+0x30>
    return p->trapframe->a5;
    80002ff0:	6d3c                	ld	a5,88(a0)
    80002ff2:	6fc8                	ld	a0,152(a5)
    80002ff4:	bfe9                	j	80002fce <argraw+0x30>
  panic("argraw");
    80002ff6:	00005517          	auipc	a0,0x5
    80002ffa:	4e250513          	addi	a0,a0,1250 # 800084d8 <states.1871+0x148>
    80002ffe:	ffffd097          	auipc	ra,0xffffd
    80003002:	540080e7          	jalr	1344(ra) # 8000053e <panic>

0000000080003006 <fetchaddr>:
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	e426                	sd	s1,8(sp)
    8000300e:	e04a                	sd	s2,0(sp)
    80003010:	1000                	addi	s0,sp,32
    80003012:	84aa                	mv	s1,a0
    80003014:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	9b2080e7          	jalr	-1614(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000301e:	653c                	ld	a5,72(a0)
    80003020:	02f4f863          	bgeu	s1,a5,80003050 <fetchaddr+0x4a>
    80003024:	00848713          	addi	a4,s1,8
    80003028:	02e7e663          	bltu	a5,a4,80003054 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000302c:	46a1                	li	a3,8
    8000302e:	8626                	mv	a2,s1
    80003030:	85ca                	mv	a1,s2
    80003032:	6928                	ld	a0,80(a0)
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	6d2080e7          	jalr	1746(ra) # 80001706 <copyin>
    8000303c:	00a03533          	snez	a0,a0
    80003040:	40a00533          	neg	a0,a0
}
    80003044:	60e2                	ld	ra,24(sp)
    80003046:	6442                	ld	s0,16(sp)
    80003048:	64a2                	ld	s1,8(sp)
    8000304a:	6902                	ld	s2,0(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret
    return -1;
    80003050:	557d                	li	a0,-1
    80003052:	bfcd                	j	80003044 <fetchaddr+0x3e>
    80003054:	557d                	li	a0,-1
    80003056:	b7fd                	j	80003044 <fetchaddr+0x3e>

0000000080003058 <fetchstr>:
{
    80003058:	7179                	addi	sp,sp,-48
    8000305a:	f406                	sd	ra,40(sp)
    8000305c:	f022                	sd	s0,32(sp)
    8000305e:	ec26                	sd	s1,24(sp)
    80003060:	e84a                	sd	s2,16(sp)
    80003062:	e44e                	sd	s3,8(sp)
    80003064:	1800                	addi	s0,sp,48
    80003066:	892a                	mv	s2,a0
    80003068:	84ae                	mv	s1,a1
    8000306a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	95c080e7          	jalr	-1700(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003074:	86ce                	mv	a3,s3
    80003076:	864a                	mv	a2,s2
    80003078:	85a6                	mv	a1,s1
    8000307a:	6928                	ld	a0,80(a0)
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	716080e7          	jalr	1814(ra) # 80001792 <copyinstr>
  if(err < 0)
    80003084:	00054763          	bltz	a0,80003092 <fetchstr+0x3a>
  return strlen(buf);
    80003088:	8526                	mv	a0,s1
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	dda080e7          	jalr	-550(ra) # 80000e64 <strlen>
}
    80003092:	70a2                	ld	ra,40(sp)
    80003094:	7402                	ld	s0,32(sp)
    80003096:	64e2                	ld	s1,24(sp)
    80003098:	6942                	ld	s2,16(sp)
    8000309a:	69a2                	ld	s3,8(sp)
    8000309c:	6145                	addi	sp,sp,48
    8000309e:	8082                	ret

00000000800030a0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	ef2080e7          	jalr	-270(ra) # 80002f9e <argraw>
    800030b4:	c088                	sw	a0,0(s1)
  return 0;
}
    800030b6:	4501                	li	a0,0
    800030b8:	60e2                	ld	ra,24(sp)
    800030ba:	6442                	ld	s0,16(sp)
    800030bc:	64a2                	ld	s1,8(sp)
    800030be:	6105                	addi	sp,sp,32
    800030c0:	8082                	ret

00000000800030c2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030c2:	1101                	addi	sp,sp,-32
    800030c4:	ec06                	sd	ra,24(sp)
    800030c6:	e822                	sd	s0,16(sp)
    800030c8:	e426                	sd	s1,8(sp)
    800030ca:	1000                	addi	s0,sp,32
    800030cc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	ed0080e7          	jalr	-304(ra) # 80002f9e <argraw>
    800030d6:	e088                	sd	a0,0(s1)
  return 0;
}
    800030d8:	4501                	li	a0,0
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret

00000000800030e4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	e04a                	sd	s2,0(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84ae                	mv	s1,a1
    800030f2:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030f4:	00000097          	auipc	ra,0x0
    800030f8:	eaa080e7          	jalr	-342(ra) # 80002f9e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030fc:	864a                	mv	a2,s2
    800030fe:	85a6                	mv	a1,s1
    80003100:	00000097          	auipc	ra,0x0
    80003104:	f58080e7          	jalr	-168(ra) # 80003058 <fetchstr>
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6902                	ld	s2,0(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret

0000000080003114 <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	e04a                	sd	s2,0(sp)
    8000311e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	8a8080e7          	jalr	-1880(ra) # 800019c8 <myproc>
    80003128:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000312a:	05853903          	ld	s2,88(a0)
    8000312e:	0a893783          	ld	a5,168(s2)
    80003132:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003136:	37fd                	addiw	a5,a5,-1
    80003138:	475d                	li	a4,23
    8000313a:	00f76f63          	bltu	a4,a5,80003158 <syscall+0x44>
    8000313e:	00369713          	slli	a4,a3,0x3
    80003142:	00005797          	auipc	a5,0x5
    80003146:	3d678793          	addi	a5,a5,982 # 80008518 <syscalls>
    8000314a:	97ba                	add	a5,a5,a4
    8000314c:	639c                	ld	a5,0(a5)
    8000314e:	c789                	beqz	a5,80003158 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003150:	9782                	jalr	a5
    80003152:	06a93823          	sd	a0,112(s2)
    80003156:	a839                	j	80003174 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003158:	15848613          	addi	a2,s1,344
    8000315c:	588c                	lw	a1,48(s1)
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	38250513          	addi	a0,a0,898 # 800084e0 <states.1871+0x150>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	422080e7          	jalr	1058(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000316e:	6cbc                	ld	a5,88(s1)
    80003170:	577d                	li	a4,-1
    80003172:	fbb8                	sd	a4,112(a5)
  }
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6902                	ld	s2,0(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003188:	fec40593          	addi	a1,s0,-20
    8000318c:	4501                	li	a0,0
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	f12080e7          	jalr	-238(ra) # 800030a0 <argint>
    return -1;
    80003196:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003198:	00054963          	bltz	a0,800031aa <sys_exit+0x2a>
  exit(n);
    8000319c:	fec42503          	lw	a0,-20(s0)
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	530080e7          	jalr	1328(ra) # 800026d0 <exit>
  return 0;  // not reached
    800031a8:	4781                	li	a5,0
}
    800031aa:	853e                	mv	a0,a5
    800031ac:	60e2                	ld	ra,24(sp)
    800031ae:	6442                	ld	s0,16(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret

00000000800031b4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031b4:	1141                	addi	sp,sp,-16
    800031b6:	e406                	sd	ra,8(sp)
    800031b8:	e022                	sd	s0,0(sp)
    800031ba:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031bc:	fffff097          	auipc	ra,0xfffff
    800031c0:	80c080e7          	jalr	-2036(ra) # 800019c8 <myproc>
}
    800031c4:	5908                	lw	a0,48(a0)
    800031c6:	60a2                	ld	ra,8(sp)
    800031c8:	6402                	ld	s0,0(sp)
    800031ca:	0141                	addi	sp,sp,16
    800031cc:	8082                	ret

00000000800031ce <sys_fork>:

uint64
sys_fork(void)
{
    800031ce:	1141                	addi	sp,sp,-16
    800031d0:	e406                	sd	ra,8(sp)
    800031d2:	e022                	sd	s0,0(sp)
    800031d4:	0800                	addi	s0,sp,16
  return fork();
    800031d6:	fffff097          	auipc	ra,0xfffff
    800031da:	be0080e7          	jalr	-1056(ra) # 80001db6 <fork>
}
    800031de:	60a2                	ld	ra,8(sp)
    800031e0:	6402                	ld	s0,0(sp)
    800031e2:	0141                	addi	sp,sp,16
    800031e4:	8082                	ret

00000000800031e6 <sys_wait>:

uint64
sys_wait(void)
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031ee:	fe840593          	addi	a1,s0,-24
    800031f2:	4501                	li	a0,0
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	ece080e7          	jalr	-306(ra) # 800030c2 <argaddr>
    800031fc:	87aa                	mv	a5,a0
    return -1;
    800031fe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003200:	0007c863          	bltz	a5,80003210 <sys_wait+0x2a>
  return wait(p);
    80003204:	fe843503          	ld	a0,-24(s0)
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	2ac080e7          	jalr	684(ra) # 800024b4 <wait>
}
    80003210:	60e2                	ld	ra,24(sp)
    80003212:	6442                	ld	s0,16(sp)
    80003214:	6105                	addi	sp,sp,32
    80003216:	8082                	ret

0000000080003218 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003218:	7179                	addi	sp,sp,-48
    8000321a:	f406                	sd	ra,40(sp)
    8000321c:	f022                	sd	s0,32(sp)
    8000321e:	ec26                	sd	s1,24(sp)
    80003220:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003222:	fdc40593          	addi	a1,s0,-36
    80003226:	4501                	li	a0,0
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	e78080e7          	jalr	-392(ra) # 800030a0 <argint>
    80003230:	87aa                	mv	a5,a0
    return -1;
    80003232:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003234:	0207c063          	bltz	a5,80003254 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	790080e7          	jalr	1936(ra) # 800019c8 <myproc>
    80003240:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003242:	fdc42503          	lw	a0,-36(s0)
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	afc080e7          	jalr	-1284(ra) # 80001d42 <growproc>
    8000324e:	00054863          	bltz	a0,8000325e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003252:	8526                	mv	a0,s1
}
    80003254:	70a2                	ld	ra,40(sp)
    80003256:	7402                	ld	s0,32(sp)
    80003258:	64e2                	ld	s1,24(sp)
    8000325a:	6145                	addi	sp,sp,48
    8000325c:	8082                	ret
    return -1;
    8000325e:	557d                	li	a0,-1
    80003260:	bfd5                	j	80003254 <sys_sbrk+0x3c>

0000000080003262 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003262:	7139                	addi	sp,sp,-64
    80003264:	fc06                	sd	ra,56(sp)
    80003266:	f822                	sd	s0,48(sp)
    80003268:	f426                	sd	s1,40(sp)
    8000326a:	f04a                	sd	s2,32(sp)
    8000326c:	ec4e                	sd	s3,24(sp)
    8000326e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003270:	fcc40593          	addi	a1,s0,-52
    80003274:	4501                	li	a0,0
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	e2a080e7          	jalr	-470(ra) # 800030a0 <argint>
    return -1;
    8000327e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003280:	06054563          	bltz	a0,800032ea <sys_sleep+0x88>
  acquire(&tickslock);
    80003284:	0000d517          	auipc	a0,0xd
    80003288:	1dc50513          	addi	a0,a0,476 # 80010460 <tickslock>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	958080e7          	jalr	-1704(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003294:	00006917          	auipc	s2,0x6
    80003298:	dc492903          	lw	s2,-572(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    8000329c:	fcc42783          	lw	a5,-52(s0)
    800032a0:	cf85                	beqz	a5,800032d8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032a2:	0000d997          	auipc	s3,0xd
    800032a6:	1be98993          	addi	s3,s3,446 # 80010460 <tickslock>
    800032aa:	00006497          	auipc	s1,0x6
    800032ae:	dae48493          	addi	s1,s1,-594 # 80009058 <ticks>
    if(myproc()->killed){
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	716080e7          	jalr	1814(ra) # 800019c8 <myproc>
    800032ba:	551c                	lw	a5,40(a0)
    800032bc:	ef9d                	bnez	a5,800032fa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032be:	85ce                	mv	a1,s3
    800032c0:	8526                	mv	a0,s1
    800032c2:	fffff097          	auipc	ra,0xfffff
    800032c6:	172080e7          	jalr	370(ra) # 80002434 <sleep>
  while(ticks - ticks0 < n){
    800032ca:	409c                	lw	a5,0(s1)
    800032cc:	412787bb          	subw	a5,a5,s2
    800032d0:	fcc42703          	lw	a4,-52(s0)
    800032d4:	fce7efe3          	bltu	a5,a4,800032b2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032d8:	0000d517          	auipc	a0,0xd
    800032dc:	18850513          	addi	a0,a0,392 # 80010460 <tickslock>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	9b8080e7          	jalr	-1608(ra) # 80000c98 <release>
  return 0;
    800032e8:	4781                	li	a5,0
}
    800032ea:	853e                	mv	a0,a5
    800032ec:	70e2                	ld	ra,56(sp)
    800032ee:	7442                	ld	s0,48(sp)
    800032f0:	74a2                	ld	s1,40(sp)
    800032f2:	7902                	ld	s2,32(sp)
    800032f4:	69e2                	ld	s3,24(sp)
    800032f6:	6121                	addi	sp,sp,64
    800032f8:	8082                	ret
      release(&tickslock);
    800032fa:	0000d517          	auipc	a0,0xd
    800032fe:	16650513          	addi	a0,a0,358 # 80010460 <tickslock>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
      return -1;
    8000330a:	57fd                	li	a5,-1
    8000330c:	bff9                	j	800032ea <sys_sleep+0x88>

000000008000330e <sys_kill>:

uint64
sys_kill(void)
{
    8000330e:	1101                	addi	sp,sp,-32
    80003310:	ec06                	sd	ra,24(sp)
    80003312:	e822                	sd	s0,16(sp)
    80003314:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003316:	fec40593          	addi	a1,s0,-20
    8000331a:	4501                	li	a0,0
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	d84080e7          	jalr	-636(ra) # 800030a0 <argint>
    80003324:	87aa                	mv	a5,a0
    return -1;
    80003326:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003328:	0007c863          	bltz	a5,80003338 <sys_kill+0x2a>
  return kill(pid);
    8000332c:	fec42503          	lw	a0,-20(s0)
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	51e080e7          	jalr	1310(ra) # 8000284e <kill>
}
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret

0000000080003340 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003340:	1101                	addi	sp,sp,-32
    80003342:	ec06                	sd	ra,24(sp)
    80003344:	e822                	sd	s0,16(sp)
    80003346:	e426                	sd	s1,8(sp)
    80003348:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000334a:	0000d517          	auipc	a0,0xd
    8000334e:	11650513          	addi	a0,a0,278 # 80010460 <tickslock>
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	892080e7          	jalr	-1902(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000335a:	00006497          	auipc	s1,0x6
    8000335e:	cfe4a483          	lw	s1,-770(s1) # 80009058 <ticks>
  release(&tickslock);
    80003362:	0000d517          	auipc	a0,0xd
    80003366:	0fe50513          	addi	a0,a0,254 # 80010460 <tickslock>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	92e080e7          	jalr	-1746(ra) # 80000c98 <release>
  return xticks;
}
    80003372:	02049513          	slli	a0,s1,0x20
    80003376:	9101                	srli	a0,a0,0x20
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	64a2                	ld	s1,8(sp)
    8000337e:	6105                	addi	sp,sp,32
    80003380:	8082                	ret

0000000080003382 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003382:	1141                	addi	sp,sp,-16
    80003384:	e406                	sd	ra,8(sp)
    80003386:	e022                	sd	s0,0(sp)
    80003388:	0800                	addi	s0,sp,16
  return kill_system();
    8000338a:	fffff097          	auipc	ra,0xfffff
    8000338e:	552080e7          	jalr	1362(ra) # 800028dc <kill_system>
}
    80003392:	60a2                	ld	ra,8(sp)
    80003394:	6402                	ld	s0,0(sp)
    80003396:	0141                	addi	sp,sp,16
    80003398:	8082                	ret

000000008000339a <sys_pause_system>:

uint64
sys_pause_system(void)
{
    8000339a:	1101                	addi	sp,sp,-32
    8000339c:	ec06                	sd	ra,24(sp)
    8000339e:	e822                	sd	s0,16(sp)
    800033a0:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    800033a2:	fec40593          	addi	a1,s0,-20
    800033a6:	4501                	li	a0,0
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	cf8080e7          	jalr	-776(ra) # 800030a0 <argint>
    800033b0:	87aa                	mv	a5,a0
    return -1;
    800033b2:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    800033b4:	0007c863          	bltz	a5,800033c4 <sys_pause_system+0x2a>
  return pause_system(seconds);
    800033b8:	fec42503          	lw	a0,-20(s0)
    800033bc:	fffff097          	auipc	ra,0xfffff
    800033c0:	74a080e7          	jalr	1866(ra) # 80002b06 <pause_system>
}
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret

00000000800033cc <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800033cc:	1141                	addi	sp,sp,-16
    800033ce:	e406                	sd	ra,8(sp)
    800033d0:	e022                	sd	s0,0(sp)
    800033d2:	0800                	addi	s0,sp,16
   print_stats();
    800033d4:	fffff097          	auipc	ra,0xfffff
    800033d8:	768080e7          	jalr	1896(ra) # 80002b3c <print_stats>
   return 0;
    800033dc:	4501                	li	a0,0
    800033de:	60a2                	ld	ra,8(sp)
    800033e0:	6402                	ld	s0,0(sp)
    800033e2:	0141                	addi	sp,sp,16
    800033e4:	8082                	ret

00000000800033e6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033e6:	7179                	addi	sp,sp,-48
    800033e8:	f406                	sd	ra,40(sp)
    800033ea:	f022                	sd	s0,32(sp)
    800033ec:	ec26                	sd	s1,24(sp)
    800033ee:	e84a                	sd	s2,16(sp)
    800033f0:	e44e                	sd	s3,8(sp)
    800033f2:	e052                	sd	s4,0(sp)
    800033f4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033f6:	00005597          	auipc	a1,0x5
    800033fa:	1ea58593          	addi	a1,a1,490 # 800085e0 <syscalls+0xc8>
    800033fe:	0000d517          	auipc	a0,0xd
    80003402:	07a50513          	addi	a0,a0,122 # 80010478 <bcache>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	74e080e7          	jalr	1870(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000340e:	00015797          	auipc	a5,0x15
    80003412:	06a78793          	addi	a5,a5,106 # 80018478 <bcache+0x8000>
    80003416:	00015717          	auipc	a4,0x15
    8000341a:	2ca70713          	addi	a4,a4,714 # 800186e0 <bcache+0x8268>
    8000341e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003422:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003426:	0000d497          	auipc	s1,0xd
    8000342a:	06a48493          	addi	s1,s1,106 # 80010490 <bcache+0x18>
    b->next = bcache.head.next;
    8000342e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003430:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003432:	00005a17          	auipc	s4,0x5
    80003436:	1b6a0a13          	addi	s4,s4,438 # 800085e8 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000343a:	2b893783          	ld	a5,696(s2)
    8000343e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003440:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003444:	85d2                	mv	a1,s4
    80003446:	01048513          	addi	a0,s1,16
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	4bc080e7          	jalr	1212(ra) # 80004906 <initsleeplock>
    bcache.head.next->prev = b;
    80003452:	2b893783          	ld	a5,696(s2)
    80003456:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003458:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000345c:	45848493          	addi	s1,s1,1112
    80003460:	fd349de3          	bne	s1,s3,8000343a <binit+0x54>
  }
}
    80003464:	70a2                	ld	ra,40(sp)
    80003466:	7402                	ld	s0,32(sp)
    80003468:	64e2                	ld	s1,24(sp)
    8000346a:	6942                	ld	s2,16(sp)
    8000346c:	69a2                	ld	s3,8(sp)
    8000346e:	6a02                	ld	s4,0(sp)
    80003470:	6145                	addi	sp,sp,48
    80003472:	8082                	ret

0000000080003474 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003474:	7179                	addi	sp,sp,-48
    80003476:	f406                	sd	ra,40(sp)
    80003478:	f022                	sd	s0,32(sp)
    8000347a:	ec26                	sd	s1,24(sp)
    8000347c:	e84a                	sd	s2,16(sp)
    8000347e:	e44e                	sd	s3,8(sp)
    80003480:	1800                	addi	s0,sp,48
    80003482:	89aa                	mv	s3,a0
    80003484:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003486:	0000d517          	auipc	a0,0xd
    8000348a:	ff250513          	addi	a0,a0,-14 # 80010478 <bcache>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	756080e7          	jalr	1878(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003496:	00015497          	auipc	s1,0x15
    8000349a:	29a4b483          	ld	s1,666(s1) # 80018730 <bcache+0x82b8>
    8000349e:	00015797          	auipc	a5,0x15
    800034a2:	24278793          	addi	a5,a5,578 # 800186e0 <bcache+0x8268>
    800034a6:	02f48f63          	beq	s1,a5,800034e4 <bread+0x70>
    800034aa:	873e                	mv	a4,a5
    800034ac:	a021                	j	800034b4 <bread+0x40>
    800034ae:	68a4                	ld	s1,80(s1)
    800034b0:	02e48a63          	beq	s1,a4,800034e4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034b4:	449c                	lw	a5,8(s1)
    800034b6:	ff379ce3          	bne	a5,s3,800034ae <bread+0x3a>
    800034ba:	44dc                	lw	a5,12(s1)
    800034bc:	ff2799e3          	bne	a5,s2,800034ae <bread+0x3a>
      b->refcnt++;
    800034c0:	40bc                	lw	a5,64(s1)
    800034c2:	2785                	addiw	a5,a5,1
    800034c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034c6:	0000d517          	auipc	a0,0xd
    800034ca:	fb250513          	addi	a0,a0,-78 # 80010478 <bcache>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	7ca080e7          	jalr	1994(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034d6:	01048513          	addi	a0,s1,16
    800034da:	00001097          	auipc	ra,0x1
    800034de:	466080e7          	jalr	1126(ra) # 80004940 <acquiresleep>
      return b;
    800034e2:	a8b9                	j	80003540 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034e4:	00015497          	auipc	s1,0x15
    800034e8:	2444b483          	ld	s1,580(s1) # 80018728 <bcache+0x82b0>
    800034ec:	00015797          	auipc	a5,0x15
    800034f0:	1f478793          	addi	a5,a5,500 # 800186e0 <bcache+0x8268>
    800034f4:	00f48863          	beq	s1,a5,80003504 <bread+0x90>
    800034f8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034fa:	40bc                	lw	a5,64(s1)
    800034fc:	cf81                	beqz	a5,80003514 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034fe:	64a4                	ld	s1,72(s1)
    80003500:	fee49de3          	bne	s1,a4,800034fa <bread+0x86>
  panic("bget: no buffers");
    80003504:	00005517          	auipc	a0,0x5
    80003508:	0ec50513          	addi	a0,a0,236 # 800085f0 <syscalls+0xd8>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	032080e7          	jalr	50(ra) # 8000053e <panic>
      b->dev = dev;
    80003514:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003518:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000351c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003520:	4785                	li	a5,1
    80003522:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003524:	0000d517          	auipc	a0,0xd
    80003528:	f5450513          	addi	a0,a0,-172 # 80010478 <bcache>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	76c080e7          	jalr	1900(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003534:	01048513          	addi	a0,s1,16
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	408080e7          	jalr	1032(ra) # 80004940 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003540:	409c                	lw	a5,0(s1)
    80003542:	cb89                	beqz	a5,80003554 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003544:	8526                	mv	a0,s1
    80003546:	70a2                	ld	ra,40(sp)
    80003548:	7402                	ld	s0,32(sp)
    8000354a:	64e2                	ld	s1,24(sp)
    8000354c:	6942                	ld	s2,16(sp)
    8000354e:	69a2                	ld	s3,8(sp)
    80003550:	6145                	addi	sp,sp,48
    80003552:	8082                	ret
    virtio_disk_rw(b, 0);
    80003554:	4581                	li	a1,0
    80003556:	8526                	mv	a0,s1
    80003558:	00003097          	auipc	ra,0x3
    8000355c:	f0e080e7          	jalr	-242(ra) # 80006466 <virtio_disk_rw>
    b->valid = 1;
    80003560:	4785                	li	a5,1
    80003562:	c09c                	sw	a5,0(s1)
  return b;
    80003564:	b7c5                	j	80003544 <bread+0xd0>

0000000080003566 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003566:	1101                	addi	sp,sp,-32
    80003568:	ec06                	sd	ra,24(sp)
    8000356a:	e822                	sd	s0,16(sp)
    8000356c:	e426                	sd	s1,8(sp)
    8000356e:	1000                	addi	s0,sp,32
    80003570:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003572:	0541                	addi	a0,a0,16
    80003574:	00001097          	auipc	ra,0x1
    80003578:	466080e7          	jalr	1126(ra) # 800049da <holdingsleep>
    8000357c:	cd01                	beqz	a0,80003594 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000357e:	4585                	li	a1,1
    80003580:	8526                	mv	a0,s1
    80003582:	00003097          	auipc	ra,0x3
    80003586:	ee4080e7          	jalr	-284(ra) # 80006466 <virtio_disk_rw>
}
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	64a2                	ld	s1,8(sp)
    80003590:	6105                	addi	sp,sp,32
    80003592:	8082                	ret
    panic("bwrite");
    80003594:	00005517          	auipc	a0,0x5
    80003598:	07450513          	addi	a0,a0,116 # 80008608 <syscalls+0xf0>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	fa2080e7          	jalr	-94(ra) # 8000053e <panic>

00000000800035a4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035a4:	1101                	addi	sp,sp,-32
    800035a6:	ec06                	sd	ra,24(sp)
    800035a8:	e822                	sd	s0,16(sp)
    800035aa:	e426                	sd	s1,8(sp)
    800035ac:	e04a                	sd	s2,0(sp)
    800035ae:	1000                	addi	s0,sp,32
    800035b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035b2:	01050913          	addi	s2,a0,16
    800035b6:	854a                	mv	a0,s2
    800035b8:	00001097          	auipc	ra,0x1
    800035bc:	422080e7          	jalr	1058(ra) # 800049da <holdingsleep>
    800035c0:	c92d                	beqz	a0,80003632 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	3d2080e7          	jalr	978(ra) # 80004996 <releasesleep>

  acquire(&bcache.lock);
    800035cc:	0000d517          	auipc	a0,0xd
    800035d0:	eac50513          	addi	a0,a0,-340 # 80010478 <bcache>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	610080e7          	jalr	1552(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035dc:	40bc                	lw	a5,64(s1)
    800035de:	37fd                	addiw	a5,a5,-1
    800035e0:	0007871b          	sext.w	a4,a5
    800035e4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035e6:	eb05                	bnez	a4,80003616 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035e8:	68bc                	ld	a5,80(s1)
    800035ea:	64b8                	ld	a4,72(s1)
    800035ec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035ee:	64bc                	ld	a5,72(s1)
    800035f0:	68b8                	ld	a4,80(s1)
    800035f2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035f4:	00015797          	auipc	a5,0x15
    800035f8:	e8478793          	addi	a5,a5,-380 # 80018478 <bcache+0x8000>
    800035fc:	2b87b703          	ld	a4,696(a5)
    80003600:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003602:	00015717          	auipc	a4,0x15
    80003606:	0de70713          	addi	a4,a4,222 # 800186e0 <bcache+0x8268>
    8000360a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000360c:	2b87b703          	ld	a4,696(a5)
    80003610:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003612:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003616:	0000d517          	auipc	a0,0xd
    8000361a:	e6250513          	addi	a0,a0,-414 # 80010478 <bcache>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
}
    80003626:	60e2                	ld	ra,24(sp)
    80003628:	6442                	ld	s0,16(sp)
    8000362a:	64a2                	ld	s1,8(sp)
    8000362c:	6902                	ld	s2,0(sp)
    8000362e:	6105                	addi	sp,sp,32
    80003630:	8082                	ret
    panic("brelse");
    80003632:	00005517          	auipc	a0,0x5
    80003636:	fde50513          	addi	a0,a0,-34 # 80008610 <syscalls+0xf8>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	f04080e7          	jalr	-252(ra) # 8000053e <panic>

0000000080003642 <bpin>:

void
bpin(struct buf *b) {
    80003642:	1101                	addi	sp,sp,-32
    80003644:	ec06                	sd	ra,24(sp)
    80003646:	e822                	sd	s0,16(sp)
    80003648:	e426                	sd	s1,8(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000364e:	0000d517          	auipc	a0,0xd
    80003652:	e2a50513          	addi	a0,a0,-470 # 80010478 <bcache>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	58e080e7          	jalr	1422(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000365e:	40bc                	lw	a5,64(s1)
    80003660:	2785                	addiw	a5,a5,1
    80003662:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003664:	0000d517          	auipc	a0,0xd
    80003668:	e1450513          	addi	a0,a0,-492 # 80010478 <bcache>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	62c080e7          	jalr	1580(ra) # 80000c98 <release>
}
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret

000000008000367e <bunpin>:

void
bunpin(struct buf *b) {
    8000367e:	1101                	addi	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	1000                	addi	s0,sp,32
    80003688:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000368a:	0000d517          	auipc	a0,0xd
    8000368e:	dee50513          	addi	a0,a0,-530 # 80010478 <bcache>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	552080e7          	jalr	1362(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000369a:	40bc                	lw	a5,64(s1)
    8000369c:	37fd                	addiw	a5,a5,-1
    8000369e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036a0:	0000d517          	auipc	a0,0xd
    800036a4:	dd850513          	addi	a0,a0,-552 # 80010478 <bcache>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	5f0080e7          	jalr	1520(ra) # 80000c98 <release>
}
    800036b0:	60e2                	ld	ra,24(sp)
    800036b2:	6442                	ld	s0,16(sp)
    800036b4:	64a2                	ld	s1,8(sp)
    800036b6:	6105                	addi	sp,sp,32
    800036b8:	8082                	ret

00000000800036ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036ba:	1101                	addi	sp,sp,-32
    800036bc:	ec06                	sd	ra,24(sp)
    800036be:	e822                	sd	s0,16(sp)
    800036c0:	e426                	sd	s1,8(sp)
    800036c2:	e04a                	sd	s2,0(sp)
    800036c4:	1000                	addi	s0,sp,32
    800036c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036c8:	00d5d59b          	srliw	a1,a1,0xd
    800036cc:	00015797          	auipc	a5,0x15
    800036d0:	4887a783          	lw	a5,1160(a5) # 80018b54 <sb+0x1c>
    800036d4:	9dbd                	addw	a1,a1,a5
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	d9e080e7          	jalr	-610(ra) # 80003474 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036de:	0074f713          	andi	a4,s1,7
    800036e2:	4785                	li	a5,1
    800036e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036e8:	14ce                	slli	s1,s1,0x33
    800036ea:	90d9                	srli	s1,s1,0x36
    800036ec:	00950733          	add	a4,a0,s1
    800036f0:	05874703          	lbu	a4,88(a4)
    800036f4:	00e7f6b3          	and	a3,a5,a4
    800036f8:	c69d                	beqz	a3,80003726 <bfree+0x6c>
    800036fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036fc:	94aa                	add	s1,s1,a0
    800036fe:	fff7c793          	not	a5,a5
    80003702:	8ff9                	and	a5,a5,a4
    80003704:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003708:	00001097          	auipc	ra,0x1
    8000370c:	118080e7          	jalr	280(ra) # 80004820 <log_write>
  brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00000097          	auipc	ra,0x0
    80003716:	e92080e7          	jalr	-366(ra) # 800035a4 <brelse>
}
    8000371a:	60e2                	ld	ra,24(sp)
    8000371c:	6442                	ld	s0,16(sp)
    8000371e:	64a2                	ld	s1,8(sp)
    80003720:	6902                	ld	s2,0(sp)
    80003722:	6105                	addi	sp,sp,32
    80003724:	8082                	ret
    panic("freeing free block");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	ef250513          	addi	a0,a0,-270 # 80008618 <syscalls+0x100>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>

0000000080003736 <balloc>:
{
    80003736:	711d                	addi	sp,sp,-96
    80003738:	ec86                	sd	ra,88(sp)
    8000373a:	e8a2                	sd	s0,80(sp)
    8000373c:	e4a6                	sd	s1,72(sp)
    8000373e:	e0ca                	sd	s2,64(sp)
    80003740:	fc4e                	sd	s3,56(sp)
    80003742:	f852                	sd	s4,48(sp)
    80003744:	f456                	sd	s5,40(sp)
    80003746:	f05a                	sd	s6,32(sp)
    80003748:	ec5e                	sd	s7,24(sp)
    8000374a:	e862                	sd	s8,16(sp)
    8000374c:	e466                	sd	s9,8(sp)
    8000374e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003750:	00015797          	auipc	a5,0x15
    80003754:	3ec7a783          	lw	a5,1004(a5) # 80018b3c <sb+0x4>
    80003758:	cbd1                	beqz	a5,800037ec <balloc+0xb6>
    8000375a:	8baa                	mv	s7,a0
    8000375c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000375e:	00015b17          	auipc	s6,0x15
    80003762:	3dab0b13          	addi	s6,s6,986 # 80018b38 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003766:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003768:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000376a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000376c:	6c89                	lui	s9,0x2
    8000376e:	a831                	j	8000378a <balloc+0x54>
    brelse(bp);
    80003770:	854a                	mv	a0,s2
    80003772:	00000097          	auipc	ra,0x0
    80003776:	e32080e7          	jalr	-462(ra) # 800035a4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000377a:	015c87bb          	addw	a5,s9,s5
    8000377e:	00078a9b          	sext.w	s5,a5
    80003782:	004b2703          	lw	a4,4(s6)
    80003786:	06eaf363          	bgeu	s5,a4,800037ec <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000378a:	41fad79b          	sraiw	a5,s5,0x1f
    8000378e:	0137d79b          	srliw	a5,a5,0x13
    80003792:	015787bb          	addw	a5,a5,s5
    80003796:	40d7d79b          	sraiw	a5,a5,0xd
    8000379a:	01cb2583          	lw	a1,28(s6)
    8000379e:	9dbd                	addw	a1,a1,a5
    800037a0:	855e                	mv	a0,s7
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	cd2080e7          	jalr	-814(ra) # 80003474 <bread>
    800037aa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ac:	004b2503          	lw	a0,4(s6)
    800037b0:	000a849b          	sext.w	s1,s5
    800037b4:	8662                	mv	a2,s8
    800037b6:	faa4fde3          	bgeu	s1,a0,80003770 <balloc+0x3a>
      m = 1 << (bi % 8);
    800037ba:	41f6579b          	sraiw	a5,a2,0x1f
    800037be:	01d7d69b          	srliw	a3,a5,0x1d
    800037c2:	00c6873b          	addw	a4,a3,a2
    800037c6:	00777793          	andi	a5,a4,7
    800037ca:	9f95                	subw	a5,a5,a3
    800037cc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037d0:	4037571b          	sraiw	a4,a4,0x3
    800037d4:	00e906b3          	add	a3,s2,a4
    800037d8:	0586c683          	lbu	a3,88(a3)
    800037dc:	00d7f5b3          	and	a1,a5,a3
    800037e0:	cd91                	beqz	a1,800037fc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037e2:	2605                	addiw	a2,a2,1
    800037e4:	2485                	addiw	s1,s1,1
    800037e6:	fd4618e3          	bne	a2,s4,800037b6 <balloc+0x80>
    800037ea:	b759                	j	80003770 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	e4450513          	addi	a0,a0,-444 # 80008630 <syscalls+0x118>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d4a080e7          	jalr	-694(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037fc:	974a                	add	a4,a4,s2
    800037fe:	8fd5                	or	a5,a5,a3
    80003800:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003804:	854a                	mv	a0,s2
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	01a080e7          	jalr	26(ra) # 80004820 <log_write>
        brelse(bp);
    8000380e:	854a                	mv	a0,s2
    80003810:	00000097          	auipc	ra,0x0
    80003814:	d94080e7          	jalr	-620(ra) # 800035a4 <brelse>
  bp = bread(dev, bno);
    80003818:	85a6                	mv	a1,s1
    8000381a:	855e                	mv	a0,s7
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	c58080e7          	jalr	-936(ra) # 80003474 <bread>
    80003824:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003826:	40000613          	li	a2,1024
    8000382a:	4581                	li	a1,0
    8000382c:	05850513          	addi	a0,a0,88
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	4b0080e7          	jalr	1200(ra) # 80000ce0 <memset>
  log_write(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	fe6080e7          	jalr	-26(ra) # 80004820 <log_write>
  brelse(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00000097          	auipc	ra,0x0
    80003848:	d60080e7          	jalr	-672(ra) # 800035a4 <brelse>
}
    8000384c:	8526                	mv	a0,s1
    8000384e:	60e6                	ld	ra,88(sp)
    80003850:	6446                	ld	s0,80(sp)
    80003852:	64a6                	ld	s1,72(sp)
    80003854:	6906                	ld	s2,64(sp)
    80003856:	79e2                	ld	s3,56(sp)
    80003858:	7a42                	ld	s4,48(sp)
    8000385a:	7aa2                	ld	s5,40(sp)
    8000385c:	7b02                	ld	s6,32(sp)
    8000385e:	6be2                	ld	s7,24(sp)
    80003860:	6c42                	ld	s8,16(sp)
    80003862:	6ca2                	ld	s9,8(sp)
    80003864:	6125                	addi	sp,sp,96
    80003866:	8082                	ret

0000000080003868 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003868:	7179                	addi	sp,sp,-48
    8000386a:	f406                	sd	ra,40(sp)
    8000386c:	f022                	sd	s0,32(sp)
    8000386e:	ec26                	sd	s1,24(sp)
    80003870:	e84a                	sd	s2,16(sp)
    80003872:	e44e                	sd	s3,8(sp)
    80003874:	e052                	sd	s4,0(sp)
    80003876:	1800                	addi	s0,sp,48
    80003878:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000387a:	47ad                	li	a5,11
    8000387c:	04b7fe63          	bgeu	a5,a1,800038d8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003880:	ff45849b          	addiw	s1,a1,-12
    80003884:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003888:	0ff00793          	li	a5,255
    8000388c:	0ae7e363          	bltu	a5,a4,80003932 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003890:	08052583          	lw	a1,128(a0)
    80003894:	c5ad                	beqz	a1,800038fe <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003896:	00092503          	lw	a0,0(s2)
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	bda080e7          	jalr	-1062(ra) # 80003474 <bread>
    800038a2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038a4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038a8:	02049593          	slli	a1,s1,0x20
    800038ac:	9181                	srli	a1,a1,0x20
    800038ae:	058a                	slli	a1,a1,0x2
    800038b0:	00b784b3          	add	s1,a5,a1
    800038b4:	0004a983          	lw	s3,0(s1)
    800038b8:	04098d63          	beqz	s3,80003912 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038bc:	8552                	mv	a0,s4
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	ce6080e7          	jalr	-794(ra) # 800035a4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038c6:	854e                	mv	a0,s3
    800038c8:	70a2                	ld	ra,40(sp)
    800038ca:	7402                	ld	s0,32(sp)
    800038cc:	64e2                	ld	s1,24(sp)
    800038ce:	6942                	ld	s2,16(sp)
    800038d0:	69a2                	ld	s3,8(sp)
    800038d2:	6a02                	ld	s4,0(sp)
    800038d4:	6145                	addi	sp,sp,48
    800038d6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038d8:	02059493          	slli	s1,a1,0x20
    800038dc:	9081                	srli	s1,s1,0x20
    800038de:	048a                	slli	s1,s1,0x2
    800038e0:	94aa                	add	s1,s1,a0
    800038e2:	0504a983          	lw	s3,80(s1)
    800038e6:	fe0990e3          	bnez	s3,800038c6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038ea:	4108                	lw	a0,0(a0)
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	e4a080e7          	jalr	-438(ra) # 80003736 <balloc>
    800038f4:	0005099b          	sext.w	s3,a0
    800038f8:	0534a823          	sw	s3,80(s1)
    800038fc:	b7e9                	j	800038c6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038fe:	4108                	lw	a0,0(a0)
    80003900:	00000097          	auipc	ra,0x0
    80003904:	e36080e7          	jalr	-458(ra) # 80003736 <balloc>
    80003908:	0005059b          	sext.w	a1,a0
    8000390c:	08b92023          	sw	a1,128(s2)
    80003910:	b759                	j	80003896 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003912:	00092503          	lw	a0,0(s2)
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	e20080e7          	jalr	-480(ra) # 80003736 <balloc>
    8000391e:	0005099b          	sext.w	s3,a0
    80003922:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003926:	8552                	mv	a0,s4
    80003928:	00001097          	auipc	ra,0x1
    8000392c:	ef8080e7          	jalr	-264(ra) # 80004820 <log_write>
    80003930:	b771                	j	800038bc <bmap+0x54>
  panic("bmap: out of range");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	d1650513          	addi	a0,a0,-746 # 80008648 <syscalls+0x130>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c04080e7          	jalr	-1020(ra) # 8000053e <panic>

0000000080003942 <iget>:
{
    80003942:	7179                	addi	sp,sp,-48
    80003944:	f406                	sd	ra,40(sp)
    80003946:	f022                	sd	s0,32(sp)
    80003948:	ec26                	sd	s1,24(sp)
    8000394a:	e84a                	sd	s2,16(sp)
    8000394c:	e44e                	sd	s3,8(sp)
    8000394e:	e052                	sd	s4,0(sp)
    80003950:	1800                	addi	s0,sp,48
    80003952:	89aa                	mv	s3,a0
    80003954:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003956:	00015517          	auipc	a0,0x15
    8000395a:	20250513          	addi	a0,a0,514 # 80018b58 <itable>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	286080e7          	jalr	646(ra) # 80000be4 <acquire>
  empty = 0;
    80003966:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003968:	00015497          	auipc	s1,0x15
    8000396c:	20848493          	addi	s1,s1,520 # 80018b70 <itable+0x18>
    80003970:	00017697          	auipc	a3,0x17
    80003974:	c9068693          	addi	a3,a3,-880 # 8001a600 <log>
    80003978:	a039                	j	80003986 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000397a:	02090b63          	beqz	s2,800039b0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000397e:	08848493          	addi	s1,s1,136
    80003982:	02d48a63          	beq	s1,a3,800039b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003986:	449c                	lw	a5,8(s1)
    80003988:	fef059e3          	blez	a5,8000397a <iget+0x38>
    8000398c:	4098                	lw	a4,0(s1)
    8000398e:	ff3716e3          	bne	a4,s3,8000397a <iget+0x38>
    80003992:	40d8                	lw	a4,4(s1)
    80003994:	ff4713e3          	bne	a4,s4,8000397a <iget+0x38>
      ip->ref++;
    80003998:	2785                	addiw	a5,a5,1
    8000399a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000399c:	00015517          	auipc	a0,0x15
    800039a0:	1bc50513          	addi	a0,a0,444 # 80018b58 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	2f4080e7          	jalr	756(ra) # 80000c98 <release>
      return ip;
    800039ac:	8926                	mv	s2,s1
    800039ae:	a03d                	j	800039dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039b0:	f7f9                	bnez	a5,8000397e <iget+0x3c>
    800039b2:	8926                	mv	s2,s1
    800039b4:	b7e9                	j	8000397e <iget+0x3c>
  if(empty == 0)
    800039b6:	02090c63          	beqz	s2,800039ee <iget+0xac>
  ip->dev = dev;
    800039ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039c2:	4785                	li	a5,1
    800039c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039c8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039cc:	00015517          	auipc	a0,0x15
    800039d0:	18c50513          	addi	a0,a0,396 # 80018b58 <itable>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	2c4080e7          	jalr	708(ra) # 80000c98 <release>
}
    800039dc:	854a                	mv	a0,s2
    800039de:	70a2                	ld	ra,40(sp)
    800039e0:	7402                	ld	s0,32(sp)
    800039e2:	64e2                	ld	s1,24(sp)
    800039e4:	6942                	ld	s2,16(sp)
    800039e6:	69a2                	ld	s3,8(sp)
    800039e8:	6a02                	ld	s4,0(sp)
    800039ea:	6145                	addi	sp,sp,48
    800039ec:	8082                	ret
    panic("iget: no inodes");
    800039ee:	00005517          	auipc	a0,0x5
    800039f2:	c7250513          	addi	a0,a0,-910 # 80008660 <syscalls+0x148>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>

00000000800039fe <fsinit>:
fsinit(int dev) {
    800039fe:	7179                	addi	sp,sp,-48
    80003a00:	f406                	sd	ra,40(sp)
    80003a02:	f022                	sd	s0,32(sp)
    80003a04:	ec26                	sd	s1,24(sp)
    80003a06:	e84a                	sd	s2,16(sp)
    80003a08:	e44e                	sd	s3,8(sp)
    80003a0a:	1800                	addi	s0,sp,48
    80003a0c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a0e:	4585                	li	a1,1
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	a64080e7          	jalr	-1436(ra) # 80003474 <bread>
    80003a18:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a1a:	00015997          	auipc	s3,0x15
    80003a1e:	11e98993          	addi	s3,s3,286 # 80018b38 <sb>
    80003a22:	02000613          	li	a2,32
    80003a26:	05850593          	addi	a1,a0,88
    80003a2a:	854e                	mv	a0,s3
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	314080e7          	jalr	788(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a34:	8526                	mv	a0,s1
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	b6e080e7          	jalr	-1170(ra) # 800035a4 <brelse>
  if(sb.magic != FSMAGIC)
    80003a3e:	0009a703          	lw	a4,0(s3)
    80003a42:	102037b7          	lui	a5,0x10203
    80003a46:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a4a:	02f71263          	bne	a4,a5,80003a6e <fsinit+0x70>
  initlog(dev, &sb);
    80003a4e:	00015597          	auipc	a1,0x15
    80003a52:	0ea58593          	addi	a1,a1,234 # 80018b38 <sb>
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	b4c080e7          	jalr	-1204(ra) # 800045a4 <initlog>
}
    80003a60:	70a2                	ld	ra,40(sp)
    80003a62:	7402                	ld	s0,32(sp)
    80003a64:	64e2                	ld	s1,24(sp)
    80003a66:	6942                	ld	s2,16(sp)
    80003a68:	69a2                	ld	s3,8(sp)
    80003a6a:	6145                	addi	sp,sp,48
    80003a6c:	8082                	ret
    panic("invalid file system");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	c0250513          	addi	a0,a0,-1022 # 80008670 <syscalls+0x158>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>

0000000080003a7e <iinit>:
{
    80003a7e:	7179                	addi	sp,sp,-48
    80003a80:	f406                	sd	ra,40(sp)
    80003a82:	f022                	sd	s0,32(sp)
    80003a84:	ec26                	sd	s1,24(sp)
    80003a86:	e84a                	sd	s2,16(sp)
    80003a88:	e44e                	sd	s3,8(sp)
    80003a8a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a8c:	00005597          	auipc	a1,0x5
    80003a90:	bfc58593          	addi	a1,a1,-1028 # 80008688 <syscalls+0x170>
    80003a94:	00015517          	auipc	a0,0x15
    80003a98:	0c450513          	addi	a0,a0,196 # 80018b58 <itable>
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	0b8080e7          	jalr	184(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003aa4:	00015497          	auipc	s1,0x15
    80003aa8:	0dc48493          	addi	s1,s1,220 # 80018b80 <itable+0x28>
    80003aac:	00017997          	auipc	s3,0x17
    80003ab0:	b6498993          	addi	s3,s3,-1180 # 8001a610 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ab4:	00005917          	auipc	s2,0x5
    80003ab8:	bdc90913          	addi	s2,s2,-1060 # 80008690 <syscalls+0x178>
    80003abc:	85ca                	mv	a1,s2
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	e46080e7          	jalr	-442(ra) # 80004906 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ac8:	08848493          	addi	s1,s1,136
    80003acc:	ff3498e3          	bne	s1,s3,80003abc <iinit+0x3e>
}
    80003ad0:	70a2                	ld	ra,40(sp)
    80003ad2:	7402                	ld	s0,32(sp)
    80003ad4:	64e2                	ld	s1,24(sp)
    80003ad6:	6942                	ld	s2,16(sp)
    80003ad8:	69a2                	ld	s3,8(sp)
    80003ada:	6145                	addi	sp,sp,48
    80003adc:	8082                	ret

0000000080003ade <ialloc>:
{
    80003ade:	715d                	addi	sp,sp,-80
    80003ae0:	e486                	sd	ra,72(sp)
    80003ae2:	e0a2                	sd	s0,64(sp)
    80003ae4:	fc26                	sd	s1,56(sp)
    80003ae6:	f84a                	sd	s2,48(sp)
    80003ae8:	f44e                	sd	s3,40(sp)
    80003aea:	f052                	sd	s4,32(sp)
    80003aec:	ec56                	sd	s5,24(sp)
    80003aee:	e85a                	sd	s6,16(sp)
    80003af0:	e45e                	sd	s7,8(sp)
    80003af2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003af4:	00015717          	auipc	a4,0x15
    80003af8:	05072703          	lw	a4,80(a4) # 80018b44 <sb+0xc>
    80003afc:	4785                	li	a5,1
    80003afe:	04e7fa63          	bgeu	a5,a4,80003b52 <ialloc+0x74>
    80003b02:	8aaa                	mv	s5,a0
    80003b04:	8bae                	mv	s7,a1
    80003b06:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b08:	00015a17          	auipc	s4,0x15
    80003b0c:	030a0a13          	addi	s4,s4,48 # 80018b38 <sb>
    80003b10:	00048b1b          	sext.w	s6,s1
    80003b14:	0044d593          	srli	a1,s1,0x4
    80003b18:	018a2783          	lw	a5,24(s4)
    80003b1c:	9dbd                	addw	a1,a1,a5
    80003b1e:	8556                	mv	a0,s5
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	954080e7          	jalr	-1708(ra) # 80003474 <bread>
    80003b28:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b2a:	05850993          	addi	s3,a0,88
    80003b2e:	00f4f793          	andi	a5,s1,15
    80003b32:	079a                	slli	a5,a5,0x6
    80003b34:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b36:	00099783          	lh	a5,0(s3)
    80003b3a:	c785                	beqz	a5,80003b62 <ialloc+0x84>
    brelse(bp);
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	a68080e7          	jalr	-1432(ra) # 800035a4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b44:	0485                	addi	s1,s1,1
    80003b46:	00ca2703          	lw	a4,12(s4)
    80003b4a:	0004879b          	sext.w	a5,s1
    80003b4e:	fce7e1e3          	bltu	a5,a4,80003b10 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b52:	00005517          	auipc	a0,0x5
    80003b56:	b4650513          	addi	a0,a0,-1210 # 80008698 <syscalls+0x180>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	9e4080e7          	jalr	-1564(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b62:	04000613          	li	a2,64
    80003b66:	4581                	li	a1,0
    80003b68:	854e                	mv	a0,s3
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	176080e7          	jalr	374(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b72:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b76:	854a                	mv	a0,s2
    80003b78:	00001097          	auipc	ra,0x1
    80003b7c:	ca8080e7          	jalr	-856(ra) # 80004820 <log_write>
      brelse(bp);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	a22080e7          	jalr	-1502(ra) # 800035a4 <brelse>
      return iget(dev, inum);
    80003b8a:	85da                	mv	a1,s6
    80003b8c:	8556                	mv	a0,s5
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	db4080e7          	jalr	-588(ra) # 80003942 <iget>
}
    80003b96:	60a6                	ld	ra,72(sp)
    80003b98:	6406                	ld	s0,64(sp)
    80003b9a:	74e2                	ld	s1,56(sp)
    80003b9c:	7942                	ld	s2,48(sp)
    80003b9e:	79a2                	ld	s3,40(sp)
    80003ba0:	7a02                	ld	s4,32(sp)
    80003ba2:	6ae2                	ld	s5,24(sp)
    80003ba4:	6b42                	ld	s6,16(sp)
    80003ba6:	6ba2                	ld	s7,8(sp)
    80003ba8:	6161                	addi	sp,sp,80
    80003baa:	8082                	ret

0000000080003bac <iupdate>:
{
    80003bac:	1101                	addi	sp,sp,-32
    80003bae:	ec06                	sd	ra,24(sp)
    80003bb0:	e822                	sd	s0,16(sp)
    80003bb2:	e426                	sd	s1,8(sp)
    80003bb4:	e04a                	sd	s2,0(sp)
    80003bb6:	1000                	addi	s0,sp,32
    80003bb8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bba:	415c                	lw	a5,4(a0)
    80003bbc:	0047d79b          	srliw	a5,a5,0x4
    80003bc0:	00015597          	auipc	a1,0x15
    80003bc4:	f905a583          	lw	a1,-112(a1) # 80018b50 <sb+0x18>
    80003bc8:	9dbd                	addw	a1,a1,a5
    80003bca:	4108                	lw	a0,0(a0)
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	8a8080e7          	jalr	-1880(ra) # 80003474 <bread>
    80003bd4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bd6:	05850793          	addi	a5,a0,88
    80003bda:	40c8                	lw	a0,4(s1)
    80003bdc:	893d                	andi	a0,a0,15
    80003bde:	051a                	slli	a0,a0,0x6
    80003be0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003be2:	04449703          	lh	a4,68(s1)
    80003be6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bea:	04649703          	lh	a4,70(s1)
    80003bee:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bf2:	04849703          	lh	a4,72(s1)
    80003bf6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bfa:	04a49703          	lh	a4,74(s1)
    80003bfe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c02:	44f8                	lw	a4,76(s1)
    80003c04:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c06:	03400613          	li	a2,52
    80003c0a:	05048593          	addi	a1,s1,80
    80003c0e:	0531                	addi	a0,a0,12
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	130080e7          	jalr	304(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c18:	854a                	mv	a0,s2
    80003c1a:	00001097          	auipc	ra,0x1
    80003c1e:	c06080e7          	jalr	-1018(ra) # 80004820 <log_write>
  brelse(bp);
    80003c22:	854a                	mv	a0,s2
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	980080e7          	jalr	-1664(ra) # 800035a4 <brelse>
}
    80003c2c:	60e2                	ld	ra,24(sp)
    80003c2e:	6442                	ld	s0,16(sp)
    80003c30:	64a2                	ld	s1,8(sp)
    80003c32:	6902                	ld	s2,0(sp)
    80003c34:	6105                	addi	sp,sp,32
    80003c36:	8082                	ret

0000000080003c38 <idup>:
{
    80003c38:	1101                	addi	sp,sp,-32
    80003c3a:	ec06                	sd	ra,24(sp)
    80003c3c:	e822                	sd	s0,16(sp)
    80003c3e:	e426                	sd	s1,8(sp)
    80003c40:	1000                	addi	s0,sp,32
    80003c42:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c44:	00015517          	auipc	a0,0x15
    80003c48:	f1450513          	addi	a0,a0,-236 # 80018b58 <itable>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	f98080e7          	jalr	-104(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c54:	449c                	lw	a5,8(s1)
    80003c56:	2785                	addiw	a5,a5,1
    80003c58:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c5a:	00015517          	auipc	a0,0x15
    80003c5e:	efe50513          	addi	a0,a0,-258 # 80018b58 <itable>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
}
    80003c6a:	8526                	mv	a0,s1
    80003c6c:	60e2                	ld	ra,24(sp)
    80003c6e:	6442                	ld	s0,16(sp)
    80003c70:	64a2                	ld	s1,8(sp)
    80003c72:	6105                	addi	sp,sp,32
    80003c74:	8082                	ret

0000000080003c76 <ilock>:
{
    80003c76:	1101                	addi	sp,sp,-32
    80003c78:	ec06                	sd	ra,24(sp)
    80003c7a:	e822                	sd	s0,16(sp)
    80003c7c:	e426                	sd	s1,8(sp)
    80003c7e:	e04a                	sd	s2,0(sp)
    80003c80:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c82:	c115                	beqz	a0,80003ca6 <ilock+0x30>
    80003c84:	84aa                	mv	s1,a0
    80003c86:	451c                	lw	a5,8(a0)
    80003c88:	00f05f63          	blez	a5,80003ca6 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c8c:	0541                	addi	a0,a0,16
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	cb2080e7          	jalr	-846(ra) # 80004940 <acquiresleep>
  if(ip->valid == 0){
    80003c96:	40bc                	lw	a5,64(s1)
    80003c98:	cf99                	beqz	a5,80003cb6 <ilock+0x40>
}
    80003c9a:	60e2                	ld	ra,24(sp)
    80003c9c:	6442                	ld	s0,16(sp)
    80003c9e:	64a2                	ld	s1,8(sp)
    80003ca0:	6902                	ld	s2,0(sp)
    80003ca2:	6105                	addi	sp,sp,32
    80003ca4:	8082                	ret
    panic("ilock");
    80003ca6:	00005517          	auipc	a0,0x5
    80003caa:	a0a50513          	addi	a0,a0,-1526 # 800086b0 <syscalls+0x198>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cb6:	40dc                	lw	a5,4(s1)
    80003cb8:	0047d79b          	srliw	a5,a5,0x4
    80003cbc:	00015597          	auipc	a1,0x15
    80003cc0:	e945a583          	lw	a1,-364(a1) # 80018b50 <sb+0x18>
    80003cc4:	9dbd                	addw	a1,a1,a5
    80003cc6:	4088                	lw	a0,0(s1)
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	7ac080e7          	jalr	1964(ra) # 80003474 <bread>
    80003cd0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cd2:	05850593          	addi	a1,a0,88
    80003cd6:	40dc                	lw	a5,4(s1)
    80003cd8:	8bbd                	andi	a5,a5,15
    80003cda:	079a                	slli	a5,a5,0x6
    80003cdc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cde:	00059783          	lh	a5,0(a1)
    80003ce2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ce6:	00259783          	lh	a5,2(a1)
    80003cea:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cee:	00459783          	lh	a5,4(a1)
    80003cf2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cf6:	00659783          	lh	a5,6(a1)
    80003cfa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cfe:	459c                	lw	a5,8(a1)
    80003d00:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d02:	03400613          	li	a2,52
    80003d06:	05b1                	addi	a1,a1,12
    80003d08:	05048513          	addi	a0,s1,80
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	034080e7          	jalr	52(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d14:	854a                	mv	a0,s2
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	88e080e7          	jalr	-1906(ra) # 800035a4 <brelse>
    ip->valid = 1;
    80003d1e:	4785                	li	a5,1
    80003d20:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d22:	04449783          	lh	a5,68(s1)
    80003d26:	fbb5                	bnez	a5,80003c9a <ilock+0x24>
      panic("ilock: no type");
    80003d28:	00005517          	auipc	a0,0x5
    80003d2c:	99050513          	addi	a0,a0,-1648 # 800086b8 <syscalls+0x1a0>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	80e080e7          	jalr	-2034(ra) # 8000053e <panic>

0000000080003d38 <iunlock>:
{
    80003d38:	1101                	addi	sp,sp,-32
    80003d3a:	ec06                	sd	ra,24(sp)
    80003d3c:	e822                	sd	s0,16(sp)
    80003d3e:	e426                	sd	s1,8(sp)
    80003d40:	e04a                	sd	s2,0(sp)
    80003d42:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d44:	c905                	beqz	a0,80003d74 <iunlock+0x3c>
    80003d46:	84aa                	mv	s1,a0
    80003d48:	01050913          	addi	s2,a0,16
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	00001097          	auipc	ra,0x1
    80003d52:	c8c080e7          	jalr	-884(ra) # 800049da <holdingsleep>
    80003d56:	cd19                	beqz	a0,80003d74 <iunlock+0x3c>
    80003d58:	449c                	lw	a5,8(s1)
    80003d5a:	00f05d63          	blez	a5,80003d74 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d5e:	854a                	mv	a0,s2
    80003d60:	00001097          	auipc	ra,0x1
    80003d64:	c36080e7          	jalr	-970(ra) # 80004996 <releasesleep>
}
    80003d68:	60e2                	ld	ra,24(sp)
    80003d6a:	6442                	ld	s0,16(sp)
    80003d6c:	64a2                	ld	s1,8(sp)
    80003d6e:	6902                	ld	s2,0(sp)
    80003d70:	6105                	addi	sp,sp,32
    80003d72:	8082                	ret
    panic("iunlock");
    80003d74:	00005517          	auipc	a0,0x5
    80003d78:	95450513          	addi	a0,a0,-1708 # 800086c8 <syscalls+0x1b0>
    80003d7c:	ffffc097          	auipc	ra,0xffffc
    80003d80:	7c2080e7          	jalr	1986(ra) # 8000053e <panic>

0000000080003d84 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d84:	7179                	addi	sp,sp,-48
    80003d86:	f406                	sd	ra,40(sp)
    80003d88:	f022                	sd	s0,32(sp)
    80003d8a:	ec26                	sd	s1,24(sp)
    80003d8c:	e84a                	sd	s2,16(sp)
    80003d8e:	e44e                	sd	s3,8(sp)
    80003d90:	e052                	sd	s4,0(sp)
    80003d92:	1800                	addi	s0,sp,48
    80003d94:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d96:	05050493          	addi	s1,a0,80
    80003d9a:	08050913          	addi	s2,a0,128
    80003d9e:	a021                	j	80003da6 <itrunc+0x22>
    80003da0:	0491                	addi	s1,s1,4
    80003da2:	01248d63          	beq	s1,s2,80003dbc <itrunc+0x38>
    if(ip->addrs[i]){
    80003da6:	408c                	lw	a1,0(s1)
    80003da8:	dde5                	beqz	a1,80003da0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003daa:	0009a503          	lw	a0,0(s3)
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	90c080e7          	jalr	-1780(ra) # 800036ba <bfree>
      ip->addrs[i] = 0;
    80003db6:	0004a023          	sw	zero,0(s1)
    80003dba:	b7dd                	j	80003da0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dbc:	0809a583          	lw	a1,128(s3)
    80003dc0:	e185                	bnez	a1,80003de0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dc2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dc6:	854e                	mv	a0,s3
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	de4080e7          	jalr	-540(ra) # 80003bac <iupdate>
}
    80003dd0:	70a2                	ld	ra,40(sp)
    80003dd2:	7402                	ld	s0,32(sp)
    80003dd4:	64e2                	ld	s1,24(sp)
    80003dd6:	6942                	ld	s2,16(sp)
    80003dd8:	69a2                	ld	s3,8(sp)
    80003dda:	6a02                	ld	s4,0(sp)
    80003ddc:	6145                	addi	sp,sp,48
    80003dde:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003de0:	0009a503          	lw	a0,0(s3)
    80003de4:	fffff097          	auipc	ra,0xfffff
    80003de8:	690080e7          	jalr	1680(ra) # 80003474 <bread>
    80003dec:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dee:	05850493          	addi	s1,a0,88
    80003df2:	45850913          	addi	s2,a0,1112
    80003df6:	a811                	j	80003e0a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003df8:	0009a503          	lw	a0,0(s3)
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	8be080e7          	jalr	-1858(ra) # 800036ba <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e04:	0491                	addi	s1,s1,4
    80003e06:	01248563          	beq	s1,s2,80003e10 <itrunc+0x8c>
      if(a[j])
    80003e0a:	408c                	lw	a1,0(s1)
    80003e0c:	dde5                	beqz	a1,80003e04 <itrunc+0x80>
    80003e0e:	b7ed                	j	80003df8 <itrunc+0x74>
    brelse(bp);
    80003e10:	8552                	mv	a0,s4
    80003e12:	fffff097          	auipc	ra,0xfffff
    80003e16:	792080e7          	jalr	1938(ra) # 800035a4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e1a:	0809a583          	lw	a1,128(s3)
    80003e1e:	0009a503          	lw	a0,0(s3)
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	898080e7          	jalr	-1896(ra) # 800036ba <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e2a:	0809a023          	sw	zero,128(s3)
    80003e2e:	bf51                	j	80003dc2 <itrunc+0x3e>

0000000080003e30 <iput>:
{
    80003e30:	1101                	addi	sp,sp,-32
    80003e32:	ec06                	sd	ra,24(sp)
    80003e34:	e822                	sd	s0,16(sp)
    80003e36:	e426                	sd	s1,8(sp)
    80003e38:	e04a                	sd	s2,0(sp)
    80003e3a:	1000                	addi	s0,sp,32
    80003e3c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e3e:	00015517          	auipc	a0,0x15
    80003e42:	d1a50513          	addi	a0,a0,-742 # 80018b58 <itable>
    80003e46:	ffffd097          	auipc	ra,0xffffd
    80003e4a:	d9e080e7          	jalr	-610(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e4e:	4498                	lw	a4,8(s1)
    80003e50:	4785                	li	a5,1
    80003e52:	02f70363          	beq	a4,a5,80003e78 <iput+0x48>
  ip->ref--;
    80003e56:	449c                	lw	a5,8(s1)
    80003e58:	37fd                	addiw	a5,a5,-1
    80003e5a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e5c:	00015517          	auipc	a0,0x15
    80003e60:	cfc50513          	addi	a0,a0,-772 # 80018b58 <itable>
    80003e64:	ffffd097          	auipc	ra,0xffffd
    80003e68:	e34080e7          	jalr	-460(ra) # 80000c98 <release>
}
    80003e6c:	60e2                	ld	ra,24(sp)
    80003e6e:	6442                	ld	s0,16(sp)
    80003e70:	64a2                	ld	s1,8(sp)
    80003e72:	6902                	ld	s2,0(sp)
    80003e74:	6105                	addi	sp,sp,32
    80003e76:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e78:	40bc                	lw	a5,64(s1)
    80003e7a:	dff1                	beqz	a5,80003e56 <iput+0x26>
    80003e7c:	04a49783          	lh	a5,74(s1)
    80003e80:	fbf9                	bnez	a5,80003e56 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e82:	01048913          	addi	s2,s1,16
    80003e86:	854a                	mv	a0,s2
    80003e88:	00001097          	auipc	ra,0x1
    80003e8c:	ab8080e7          	jalr	-1352(ra) # 80004940 <acquiresleep>
    release(&itable.lock);
    80003e90:	00015517          	auipc	a0,0x15
    80003e94:	cc850513          	addi	a0,a0,-824 # 80018b58 <itable>
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	e00080e7          	jalr	-512(ra) # 80000c98 <release>
    itrunc(ip);
    80003ea0:	8526                	mv	a0,s1
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	ee2080e7          	jalr	-286(ra) # 80003d84 <itrunc>
    ip->type = 0;
    80003eaa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003eae:	8526                	mv	a0,s1
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	cfc080e7          	jalr	-772(ra) # 80003bac <iupdate>
    ip->valid = 0;
    80003eb8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00001097          	auipc	ra,0x1
    80003ec2:	ad8080e7          	jalr	-1320(ra) # 80004996 <releasesleep>
    acquire(&itable.lock);
    80003ec6:	00015517          	auipc	a0,0x15
    80003eca:	c9250513          	addi	a0,a0,-878 # 80018b58 <itable>
    80003ece:	ffffd097          	auipc	ra,0xffffd
    80003ed2:	d16080e7          	jalr	-746(ra) # 80000be4 <acquire>
    80003ed6:	b741                	j	80003e56 <iput+0x26>

0000000080003ed8 <iunlockput>:
{
    80003ed8:	1101                	addi	sp,sp,-32
    80003eda:	ec06                	sd	ra,24(sp)
    80003edc:	e822                	sd	s0,16(sp)
    80003ede:	e426                	sd	s1,8(sp)
    80003ee0:	1000                	addi	s0,sp,32
    80003ee2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	e54080e7          	jalr	-428(ra) # 80003d38 <iunlock>
  iput(ip);
    80003eec:	8526                	mv	a0,s1
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	f42080e7          	jalr	-190(ra) # 80003e30 <iput>
}
    80003ef6:	60e2                	ld	ra,24(sp)
    80003ef8:	6442                	ld	s0,16(sp)
    80003efa:	64a2                	ld	s1,8(sp)
    80003efc:	6105                	addi	sp,sp,32
    80003efe:	8082                	ret

0000000080003f00 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f00:	1141                	addi	sp,sp,-16
    80003f02:	e422                	sd	s0,8(sp)
    80003f04:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f06:	411c                	lw	a5,0(a0)
    80003f08:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f0a:	415c                	lw	a5,4(a0)
    80003f0c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f0e:	04451783          	lh	a5,68(a0)
    80003f12:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f16:	04a51783          	lh	a5,74(a0)
    80003f1a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f1e:	04c56783          	lwu	a5,76(a0)
    80003f22:	e99c                	sd	a5,16(a1)
}
    80003f24:	6422                	ld	s0,8(sp)
    80003f26:	0141                	addi	sp,sp,16
    80003f28:	8082                	ret

0000000080003f2a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f2a:	457c                	lw	a5,76(a0)
    80003f2c:	0ed7e963          	bltu	a5,a3,8000401e <readi+0xf4>
{
    80003f30:	7159                	addi	sp,sp,-112
    80003f32:	f486                	sd	ra,104(sp)
    80003f34:	f0a2                	sd	s0,96(sp)
    80003f36:	eca6                	sd	s1,88(sp)
    80003f38:	e8ca                	sd	s2,80(sp)
    80003f3a:	e4ce                	sd	s3,72(sp)
    80003f3c:	e0d2                	sd	s4,64(sp)
    80003f3e:	fc56                	sd	s5,56(sp)
    80003f40:	f85a                	sd	s6,48(sp)
    80003f42:	f45e                	sd	s7,40(sp)
    80003f44:	f062                	sd	s8,32(sp)
    80003f46:	ec66                	sd	s9,24(sp)
    80003f48:	e86a                	sd	s10,16(sp)
    80003f4a:	e46e                	sd	s11,8(sp)
    80003f4c:	1880                	addi	s0,sp,112
    80003f4e:	8baa                	mv	s7,a0
    80003f50:	8c2e                	mv	s8,a1
    80003f52:	8ab2                	mv	s5,a2
    80003f54:	84b6                	mv	s1,a3
    80003f56:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f58:	9f35                	addw	a4,a4,a3
    return 0;
    80003f5a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f5c:	0ad76063          	bltu	a4,a3,80003ffc <readi+0xd2>
  if(off + n > ip->size)
    80003f60:	00e7f463          	bgeu	a5,a4,80003f68 <readi+0x3e>
    n = ip->size - off;
    80003f64:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f68:	0a0b0963          	beqz	s6,8000401a <readi+0xf0>
    80003f6c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f6e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f72:	5cfd                	li	s9,-1
    80003f74:	a82d                	j	80003fae <readi+0x84>
    80003f76:	020a1d93          	slli	s11,s4,0x20
    80003f7a:	020ddd93          	srli	s11,s11,0x20
    80003f7e:	05890613          	addi	a2,s2,88
    80003f82:	86ee                	mv	a3,s11
    80003f84:	963a                	add	a2,a2,a4
    80003f86:	85d6                	mv	a1,s5
    80003f88:	8562                	mv	a0,s8
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	a22080e7          	jalr	-1502(ra) # 800029ac <either_copyout>
    80003f92:	05950d63          	beq	a0,s9,80003fec <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f96:	854a                	mv	a0,s2
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	60c080e7          	jalr	1548(ra) # 800035a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fa0:	013a09bb          	addw	s3,s4,s3
    80003fa4:	009a04bb          	addw	s1,s4,s1
    80003fa8:	9aee                	add	s5,s5,s11
    80003faa:	0569f763          	bgeu	s3,s6,80003ff8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fae:	000ba903          	lw	s2,0(s7)
    80003fb2:	00a4d59b          	srliw	a1,s1,0xa
    80003fb6:	855e                	mv	a0,s7
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	8b0080e7          	jalr	-1872(ra) # 80003868 <bmap>
    80003fc0:	0005059b          	sext.w	a1,a0
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	4ae080e7          	jalr	1198(ra) # 80003474 <bread>
    80003fce:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd0:	3ff4f713          	andi	a4,s1,1023
    80003fd4:	40ed07bb          	subw	a5,s10,a4
    80003fd8:	413b06bb          	subw	a3,s6,s3
    80003fdc:	8a3e                	mv	s4,a5
    80003fde:	2781                	sext.w	a5,a5
    80003fe0:	0006861b          	sext.w	a2,a3
    80003fe4:	f8f679e3          	bgeu	a2,a5,80003f76 <readi+0x4c>
    80003fe8:	8a36                	mv	s4,a3
    80003fea:	b771                	j	80003f76 <readi+0x4c>
      brelse(bp);
    80003fec:	854a                	mv	a0,s2
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	5b6080e7          	jalr	1462(ra) # 800035a4 <brelse>
      tot = -1;
    80003ff6:	59fd                	li	s3,-1
  }
  return tot;
    80003ff8:	0009851b          	sext.w	a0,s3
}
    80003ffc:	70a6                	ld	ra,104(sp)
    80003ffe:	7406                	ld	s0,96(sp)
    80004000:	64e6                	ld	s1,88(sp)
    80004002:	6946                	ld	s2,80(sp)
    80004004:	69a6                	ld	s3,72(sp)
    80004006:	6a06                	ld	s4,64(sp)
    80004008:	7ae2                	ld	s5,56(sp)
    8000400a:	7b42                	ld	s6,48(sp)
    8000400c:	7ba2                	ld	s7,40(sp)
    8000400e:	7c02                	ld	s8,32(sp)
    80004010:	6ce2                	ld	s9,24(sp)
    80004012:	6d42                	ld	s10,16(sp)
    80004014:	6da2                	ld	s11,8(sp)
    80004016:	6165                	addi	sp,sp,112
    80004018:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000401a:	89da                	mv	s3,s6
    8000401c:	bff1                	j	80003ff8 <readi+0xce>
    return 0;
    8000401e:	4501                	li	a0,0
}
    80004020:	8082                	ret

0000000080004022 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004022:	457c                	lw	a5,76(a0)
    80004024:	10d7e863          	bltu	a5,a3,80004134 <writei+0x112>
{
    80004028:	7159                	addi	sp,sp,-112
    8000402a:	f486                	sd	ra,104(sp)
    8000402c:	f0a2                	sd	s0,96(sp)
    8000402e:	eca6                	sd	s1,88(sp)
    80004030:	e8ca                	sd	s2,80(sp)
    80004032:	e4ce                	sd	s3,72(sp)
    80004034:	e0d2                	sd	s4,64(sp)
    80004036:	fc56                	sd	s5,56(sp)
    80004038:	f85a                	sd	s6,48(sp)
    8000403a:	f45e                	sd	s7,40(sp)
    8000403c:	f062                	sd	s8,32(sp)
    8000403e:	ec66                	sd	s9,24(sp)
    80004040:	e86a                	sd	s10,16(sp)
    80004042:	e46e                	sd	s11,8(sp)
    80004044:	1880                	addi	s0,sp,112
    80004046:	8b2a                	mv	s6,a0
    80004048:	8c2e                	mv	s8,a1
    8000404a:	8ab2                	mv	s5,a2
    8000404c:	8936                	mv	s2,a3
    8000404e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004050:	00e687bb          	addw	a5,a3,a4
    80004054:	0ed7e263          	bltu	a5,a3,80004138 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004058:	00043737          	lui	a4,0x43
    8000405c:	0ef76063          	bltu	a4,a5,8000413c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004060:	0c0b8863          	beqz	s7,80004130 <writei+0x10e>
    80004064:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004066:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000406a:	5cfd                	li	s9,-1
    8000406c:	a091                	j	800040b0 <writei+0x8e>
    8000406e:	02099d93          	slli	s11,s3,0x20
    80004072:	020ddd93          	srli	s11,s11,0x20
    80004076:	05848513          	addi	a0,s1,88
    8000407a:	86ee                	mv	a3,s11
    8000407c:	8656                	mv	a2,s5
    8000407e:	85e2                	mv	a1,s8
    80004080:	953a                	add	a0,a0,a4
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	980080e7          	jalr	-1664(ra) # 80002a02 <either_copyin>
    8000408a:	07950263          	beq	a0,s9,800040ee <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000408e:	8526                	mv	a0,s1
    80004090:	00000097          	auipc	ra,0x0
    80004094:	790080e7          	jalr	1936(ra) # 80004820 <log_write>
    brelse(bp);
    80004098:	8526                	mv	a0,s1
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	50a080e7          	jalr	1290(ra) # 800035a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040a2:	01498a3b          	addw	s4,s3,s4
    800040a6:	0129893b          	addw	s2,s3,s2
    800040aa:	9aee                	add	s5,s5,s11
    800040ac:	057a7663          	bgeu	s4,s7,800040f8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040b0:	000b2483          	lw	s1,0(s6)
    800040b4:	00a9559b          	srliw	a1,s2,0xa
    800040b8:	855a                	mv	a0,s6
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	7ae080e7          	jalr	1966(ra) # 80003868 <bmap>
    800040c2:	0005059b          	sext.w	a1,a0
    800040c6:	8526                	mv	a0,s1
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	3ac080e7          	jalr	940(ra) # 80003474 <bread>
    800040d0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d2:	3ff97713          	andi	a4,s2,1023
    800040d6:	40ed07bb          	subw	a5,s10,a4
    800040da:	414b86bb          	subw	a3,s7,s4
    800040de:	89be                	mv	s3,a5
    800040e0:	2781                	sext.w	a5,a5
    800040e2:	0006861b          	sext.w	a2,a3
    800040e6:	f8f674e3          	bgeu	a2,a5,8000406e <writei+0x4c>
    800040ea:	89b6                	mv	s3,a3
    800040ec:	b749                	j	8000406e <writei+0x4c>
      brelse(bp);
    800040ee:	8526                	mv	a0,s1
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	4b4080e7          	jalr	1204(ra) # 800035a4 <brelse>
  }

  if(off > ip->size)
    800040f8:	04cb2783          	lw	a5,76(s6)
    800040fc:	0127f463          	bgeu	a5,s2,80004104 <writei+0xe2>
    ip->size = off;
    80004100:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004104:	855a                	mv	a0,s6
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	aa6080e7          	jalr	-1370(ra) # 80003bac <iupdate>

  return tot;
    8000410e:	000a051b          	sext.w	a0,s4
}
    80004112:	70a6                	ld	ra,104(sp)
    80004114:	7406                	ld	s0,96(sp)
    80004116:	64e6                	ld	s1,88(sp)
    80004118:	6946                	ld	s2,80(sp)
    8000411a:	69a6                	ld	s3,72(sp)
    8000411c:	6a06                	ld	s4,64(sp)
    8000411e:	7ae2                	ld	s5,56(sp)
    80004120:	7b42                	ld	s6,48(sp)
    80004122:	7ba2                	ld	s7,40(sp)
    80004124:	7c02                	ld	s8,32(sp)
    80004126:	6ce2                	ld	s9,24(sp)
    80004128:	6d42                	ld	s10,16(sp)
    8000412a:	6da2                	ld	s11,8(sp)
    8000412c:	6165                	addi	sp,sp,112
    8000412e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004130:	8a5e                	mv	s4,s7
    80004132:	bfc9                	j	80004104 <writei+0xe2>
    return -1;
    80004134:	557d                	li	a0,-1
}
    80004136:	8082                	ret
    return -1;
    80004138:	557d                	li	a0,-1
    8000413a:	bfe1                	j	80004112 <writei+0xf0>
    return -1;
    8000413c:	557d                	li	a0,-1
    8000413e:	bfd1                	j	80004112 <writei+0xf0>

0000000080004140 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004140:	1141                	addi	sp,sp,-16
    80004142:	e406                	sd	ra,8(sp)
    80004144:	e022                	sd	s0,0(sp)
    80004146:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004148:	4639                	li	a2,14
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	c6e080e7          	jalr	-914(ra) # 80000db8 <strncmp>
}
    80004152:	60a2                	ld	ra,8(sp)
    80004154:	6402                	ld	s0,0(sp)
    80004156:	0141                	addi	sp,sp,16
    80004158:	8082                	ret

000000008000415a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000415a:	7139                	addi	sp,sp,-64
    8000415c:	fc06                	sd	ra,56(sp)
    8000415e:	f822                	sd	s0,48(sp)
    80004160:	f426                	sd	s1,40(sp)
    80004162:	f04a                	sd	s2,32(sp)
    80004164:	ec4e                	sd	s3,24(sp)
    80004166:	e852                	sd	s4,16(sp)
    80004168:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000416a:	04451703          	lh	a4,68(a0)
    8000416e:	4785                	li	a5,1
    80004170:	00f71a63          	bne	a4,a5,80004184 <dirlookup+0x2a>
    80004174:	892a                	mv	s2,a0
    80004176:	89ae                	mv	s3,a1
    80004178:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000417a:	457c                	lw	a5,76(a0)
    8000417c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000417e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004180:	e79d                	bnez	a5,800041ae <dirlookup+0x54>
    80004182:	a8a5                	j	800041fa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004184:	00004517          	auipc	a0,0x4
    80004188:	54c50513          	addi	a0,a0,1356 # 800086d0 <syscalls+0x1b8>
    8000418c:	ffffc097          	auipc	ra,0xffffc
    80004190:	3b2080e7          	jalr	946(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004194:	00004517          	auipc	a0,0x4
    80004198:	55450513          	addi	a0,a0,1364 # 800086e8 <syscalls+0x1d0>
    8000419c:	ffffc097          	auipc	ra,0xffffc
    800041a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a4:	24c1                	addiw	s1,s1,16
    800041a6:	04c92783          	lw	a5,76(s2)
    800041aa:	04f4f763          	bgeu	s1,a5,800041f8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ae:	4741                	li	a4,16
    800041b0:	86a6                	mv	a3,s1
    800041b2:	fc040613          	addi	a2,s0,-64
    800041b6:	4581                	li	a1,0
    800041b8:	854a                	mv	a0,s2
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	d70080e7          	jalr	-656(ra) # 80003f2a <readi>
    800041c2:	47c1                	li	a5,16
    800041c4:	fcf518e3          	bne	a0,a5,80004194 <dirlookup+0x3a>
    if(de.inum == 0)
    800041c8:	fc045783          	lhu	a5,-64(s0)
    800041cc:	dfe1                	beqz	a5,800041a4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041ce:	fc240593          	addi	a1,s0,-62
    800041d2:	854e                	mv	a0,s3
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	f6c080e7          	jalr	-148(ra) # 80004140 <namecmp>
    800041dc:	f561                	bnez	a0,800041a4 <dirlookup+0x4a>
      if(poff)
    800041de:	000a0463          	beqz	s4,800041e6 <dirlookup+0x8c>
        *poff = off;
    800041e2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041e6:	fc045583          	lhu	a1,-64(s0)
    800041ea:	00092503          	lw	a0,0(s2)
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	754080e7          	jalr	1876(ra) # 80003942 <iget>
    800041f6:	a011                	j	800041fa <dirlookup+0xa0>
  return 0;
    800041f8:	4501                	li	a0,0
}
    800041fa:	70e2                	ld	ra,56(sp)
    800041fc:	7442                	ld	s0,48(sp)
    800041fe:	74a2                	ld	s1,40(sp)
    80004200:	7902                	ld	s2,32(sp)
    80004202:	69e2                	ld	s3,24(sp)
    80004204:	6a42                	ld	s4,16(sp)
    80004206:	6121                	addi	sp,sp,64
    80004208:	8082                	ret

000000008000420a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000420a:	711d                	addi	sp,sp,-96
    8000420c:	ec86                	sd	ra,88(sp)
    8000420e:	e8a2                	sd	s0,80(sp)
    80004210:	e4a6                	sd	s1,72(sp)
    80004212:	e0ca                	sd	s2,64(sp)
    80004214:	fc4e                	sd	s3,56(sp)
    80004216:	f852                	sd	s4,48(sp)
    80004218:	f456                	sd	s5,40(sp)
    8000421a:	f05a                	sd	s6,32(sp)
    8000421c:	ec5e                	sd	s7,24(sp)
    8000421e:	e862                	sd	s8,16(sp)
    80004220:	e466                	sd	s9,8(sp)
    80004222:	1080                	addi	s0,sp,96
    80004224:	84aa                	mv	s1,a0
    80004226:	8b2e                	mv	s6,a1
    80004228:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000422a:	00054703          	lbu	a4,0(a0)
    8000422e:	02f00793          	li	a5,47
    80004232:	02f70363          	beq	a4,a5,80004258 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	792080e7          	jalr	1938(ra) # 800019c8 <myproc>
    8000423e:	15053503          	ld	a0,336(a0)
    80004242:	00000097          	auipc	ra,0x0
    80004246:	9f6080e7          	jalr	-1546(ra) # 80003c38 <idup>
    8000424a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000424c:	02f00913          	li	s2,47
  len = path - s;
    80004250:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004252:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004254:	4c05                	li	s8,1
    80004256:	a865                	j	8000430e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004258:	4585                	li	a1,1
    8000425a:	4505                	li	a0,1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	6e6080e7          	jalr	1766(ra) # 80003942 <iget>
    80004264:	89aa                	mv	s3,a0
    80004266:	b7dd                	j	8000424c <namex+0x42>
      iunlockput(ip);
    80004268:	854e                	mv	a0,s3
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	c6e080e7          	jalr	-914(ra) # 80003ed8 <iunlockput>
      return 0;
    80004272:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004274:	854e                	mv	a0,s3
    80004276:	60e6                	ld	ra,88(sp)
    80004278:	6446                	ld	s0,80(sp)
    8000427a:	64a6                	ld	s1,72(sp)
    8000427c:	6906                	ld	s2,64(sp)
    8000427e:	79e2                	ld	s3,56(sp)
    80004280:	7a42                	ld	s4,48(sp)
    80004282:	7aa2                	ld	s5,40(sp)
    80004284:	7b02                	ld	s6,32(sp)
    80004286:	6be2                	ld	s7,24(sp)
    80004288:	6c42                	ld	s8,16(sp)
    8000428a:	6ca2                	ld	s9,8(sp)
    8000428c:	6125                	addi	sp,sp,96
    8000428e:	8082                	ret
      iunlock(ip);
    80004290:	854e                	mv	a0,s3
    80004292:	00000097          	auipc	ra,0x0
    80004296:	aa6080e7          	jalr	-1370(ra) # 80003d38 <iunlock>
      return ip;
    8000429a:	bfe9                	j	80004274 <namex+0x6a>
      iunlockput(ip);
    8000429c:	854e                	mv	a0,s3
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	c3a080e7          	jalr	-966(ra) # 80003ed8 <iunlockput>
      return 0;
    800042a6:	89d2                	mv	s3,s4
    800042a8:	b7f1                	j	80004274 <namex+0x6a>
  len = path - s;
    800042aa:	40b48633          	sub	a2,s1,a1
    800042ae:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042b2:	094cd463          	bge	s9,s4,8000433a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042b6:	4639                	li	a2,14
    800042b8:	8556                	mv	a0,s5
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	a86080e7          	jalr	-1402(ra) # 80000d40 <memmove>
  while(*path == '/')
    800042c2:	0004c783          	lbu	a5,0(s1)
    800042c6:	01279763          	bne	a5,s2,800042d4 <namex+0xca>
    path++;
    800042ca:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042cc:	0004c783          	lbu	a5,0(s1)
    800042d0:	ff278de3          	beq	a5,s2,800042ca <namex+0xc0>
    ilock(ip);
    800042d4:	854e                	mv	a0,s3
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	9a0080e7          	jalr	-1632(ra) # 80003c76 <ilock>
    if(ip->type != T_DIR){
    800042de:	04499783          	lh	a5,68(s3)
    800042e2:	f98793e3          	bne	a5,s8,80004268 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042e6:	000b0563          	beqz	s6,800042f0 <namex+0xe6>
    800042ea:	0004c783          	lbu	a5,0(s1)
    800042ee:	d3cd                	beqz	a5,80004290 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042f0:	865e                	mv	a2,s7
    800042f2:	85d6                	mv	a1,s5
    800042f4:	854e                	mv	a0,s3
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	e64080e7          	jalr	-412(ra) # 8000415a <dirlookup>
    800042fe:	8a2a                	mv	s4,a0
    80004300:	dd51                	beqz	a0,8000429c <namex+0x92>
    iunlockput(ip);
    80004302:	854e                	mv	a0,s3
    80004304:	00000097          	auipc	ra,0x0
    80004308:	bd4080e7          	jalr	-1068(ra) # 80003ed8 <iunlockput>
    ip = next;
    8000430c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000430e:	0004c783          	lbu	a5,0(s1)
    80004312:	05279763          	bne	a5,s2,80004360 <namex+0x156>
    path++;
    80004316:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004318:	0004c783          	lbu	a5,0(s1)
    8000431c:	ff278de3          	beq	a5,s2,80004316 <namex+0x10c>
  if(*path == 0)
    80004320:	c79d                	beqz	a5,8000434e <namex+0x144>
    path++;
    80004322:	85a6                	mv	a1,s1
  len = path - s;
    80004324:	8a5e                	mv	s4,s7
    80004326:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004328:	01278963          	beq	a5,s2,8000433a <namex+0x130>
    8000432c:	dfbd                	beqz	a5,800042aa <namex+0xa0>
    path++;
    8000432e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004330:	0004c783          	lbu	a5,0(s1)
    80004334:	ff279ce3          	bne	a5,s2,8000432c <namex+0x122>
    80004338:	bf8d                	j	800042aa <namex+0xa0>
    memmove(name, s, len);
    8000433a:	2601                	sext.w	a2,a2
    8000433c:	8556                	mv	a0,s5
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	a02080e7          	jalr	-1534(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004346:	9a56                	add	s4,s4,s5
    80004348:	000a0023          	sb	zero,0(s4)
    8000434c:	bf9d                	j	800042c2 <namex+0xb8>
  if(nameiparent){
    8000434e:	f20b03e3          	beqz	s6,80004274 <namex+0x6a>
    iput(ip);
    80004352:	854e                	mv	a0,s3
    80004354:	00000097          	auipc	ra,0x0
    80004358:	adc080e7          	jalr	-1316(ra) # 80003e30 <iput>
    return 0;
    8000435c:	4981                	li	s3,0
    8000435e:	bf19                	j	80004274 <namex+0x6a>
  if(*path == 0)
    80004360:	d7fd                	beqz	a5,8000434e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004362:	0004c783          	lbu	a5,0(s1)
    80004366:	85a6                	mv	a1,s1
    80004368:	b7d1                	j	8000432c <namex+0x122>

000000008000436a <dirlink>:
{
    8000436a:	7139                	addi	sp,sp,-64
    8000436c:	fc06                	sd	ra,56(sp)
    8000436e:	f822                	sd	s0,48(sp)
    80004370:	f426                	sd	s1,40(sp)
    80004372:	f04a                	sd	s2,32(sp)
    80004374:	ec4e                	sd	s3,24(sp)
    80004376:	e852                	sd	s4,16(sp)
    80004378:	0080                	addi	s0,sp,64
    8000437a:	892a                	mv	s2,a0
    8000437c:	8a2e                	mv	s4,a1
    8000437e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004380:	4601                	li	a2,0
    80004382:	00000097          	auipc	ra,0x0
    80004386:	dd8080e7          	jalr	-552(ra) # 8000415a <dirlookup>
    8000438a:	e93d                	bnez	a0,80004400 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000438c:	04c92483          	lw	s1,76(s2)
    80004390:	c49d                	beqz	s1,800043be <dirlink+0x54>
    80004392:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004394:	4741                	li	a4,16
    80004396:	86a6                	mv	a3,s1
    80004398:	fc040613          	addi	a2,s0,-64
    8000439c:	4581                	li	a1,0
    8000439e:	854a                	mv	a0,s2
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	b8a080e7          	jalr	-1142(ra) # 80003f2a <readi>
    800043a8:	47c1                	li	a5,16
    800043aa:	06f51163          	bne	a0,a5,8000440c <dirlink+0xa2>
    if(de.inum == 0)
    800043ae:	fc045783          	lhu	a5,-64(s0)
    800043b2:	c791                	beqz	a5,800043be <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b4:	24c1                	addiw	s1,s1,16
    800043b6:	04c92783          	lw	a5,76(s2)
    800043ba:	fcf4ede3          	bltu	s1,a5,80004394 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043be:	4639                	li	a2,14
    800043c0:	85d2                	mv	a1,s4
    800043c2:	fc240513          	addi	a0,s0,-62
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	a2e080e7          	jalr	-1490(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800043ce:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043d2:	4741                	li	a4,16
    800043d4:	86a6                	mv	a3,s1
    800043d6:	fc040613          	addi	a2,s0,-64
    800043da:	4581                	li	a1,0
    800043dc:	854a                	mv	a0,s2
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	c44080e7          	jalr	-956(ra) # 80004022 <writei>
    800043e6:	872a                	mv	a4,a0
    800043e8:	47c1                	li	a5,16
  return 0;
    800043ea:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ec:	02f71863          	bne	a4,a5,8000441c <dirlink+0xb2>
}
    800043f0:	70e2                	ld	ra,56(sp)
    800043f2:	7442                	ld	s0,48(sp)
    800043f4:	74a2                	ld	s1,40(sp)
    800043f6:	7902                	ld	s2,32(sp)
    800043f8:	69e2                	ld	s3,24(sp)
    800043fa:	6a42                	ld	s4,16(sp)
    800043fc:	6121                	addi	sp,sp,64
    800043fe:	8082                	ret
    iput(ip);
    80004400:	00000097          	auipc	ra,0x0
    80004404:	a30080e7          	jalr	-1488(ra) # 80003e30 <iput>
    return -1;
    80004408:	557d                	li	a0,-1
    8000440a:	b7dd                	j	800043f0 <dirlink+0x86>
      panic("dirlink read");
    8000440c:	00004517          	auipc	a0,0x4
    80004410:	2ec50513          	addi	a0,a0,748 # 800086f8 <syscalls+0x1e0>
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	12a080e7          	jalr	298(ra) # 8000053e <panic>
    panic("dirlink");
    8000441c:	00004517          	auipc	a0,0x4
    80004420:	3ec50513          	addi	a0,a0,1004 # 80008808 <syscalls+0x2f0>
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	11a080e7          	jalr	282(ra) # 8000053e <panic>

000000008000442c <namei>:

struct inode*
namei(char *path)
{
    8000442c:	1101                	addi	sp,sp,-32
    8000442e:	ec06                	sd	ra,24(sp)
    80004430:	e822                	sd	s0,16(sp)
    80004432:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004434:	fe040613          	addi	a2,s0,-32
    80004438:	4581                	li	a1,0
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	dd0080e7          	jalr	-560(ra) # 8000420a <namex>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000444a:	1141                	addi	sp,sp,-16
    8000444c:	e406                	sd	ra,8(sp)
    8000444e:	e022                	sd	s0,0(sp)
    80004450:	0800                	addi	s0,sp,16
    80004452:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004454:	4585                	li	a1,1
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	db4080e7          	jalr	-588(ra) # 8000420a <namex>
}
    8000445e:	60a2                	ld	ra,8(sp)
    80004460:	6402                	ld	s0,0(sp)
    80004462:	0141                	addi	sp,sp,16
    80004464:	8082                	ret

0000000080004466 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004466:	1101                	addi	sp,sp,-32
    80004468:	ec06                	sd	ra,24(sp)
    8000446a:	e822                	sd	s0,16(sp)
    8000446c:	e426                	sd	s1,8(sp)
    8000446e:	e04a                	sd	s2,0(sp)
    80004470:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004472:	00016917          	auipc	s2,0x16
    80004476:	18e90913          	addi	s2,s2,398 # 8001a600 <log>
    8000447a:	01892583          	lw	a1,24(s2)
    8000447e:	02892503          	lw	a0,40(s2)
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	ff2080e7          	jalr	-14(ra) # 80003474 <bread>
    8000448a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000448c:	02c92683          	lw	a3,44(s2)
    80004490:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004492:	02d05763          	blez	a3,800044c0 <write_head+0x5a>
    80004496:	00016797          	auipc	a5,0x16
    8000449a:	19a78793          	addi	a5,a5,410 # 8001a630 <log+0x30>
    8000449e:	05c50713          	addi	a4,a0,92
    800044a2:	36fd                	addiw	a3,a3,-1
    800044a4:	1682                	slli	a3,a3,0x20
    800044a6:	9281                	srli	a3,a3,0x20
    800044a8:	068a                	slli	a3,a3,0x2
    800044aa:	00016617          	auipc	a2,0x16
    800044ae:	18a60613          	addi	a2,a2,394 # 8001a634 <log+0x34>
    800044b2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044b4:	4390                	lw	a2,0(a5)
    800044b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044b8:	0791                	addi	a5,a5,4
    800044ba:	0711                	addi	a4,a4,4
    800044bc:	fed79ce3          	bne	a5,a3,800044b4 <write_head+0x4e>
  }
  bwrite(buf);
    800044c0:	8526                	mv	a0,s1
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	0a4080e7          	jalr	164(ra) # 80003566 <bwrite>
  brelse(buf);
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	0d8080e7          	jalr	216(ra) # 800035a4 <brelse>
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e0:	00016797          	auipc	a5,0x16
    800044e4:	14c7a783          	lw	a5,332(a5) # 8001a62c <log+0x2c>
    800044e8:	0af05d63          	blez	a5,800045a2 <install_trans+0xc2>
{
    800044ec:	7139                	addi	sp,sp,-64
    800044ee:	fc06                	sd	ra,56(sp)
    800044f0:	f822                	sd	s0,48(sp)
    800044f2:	f426                	sd	s1,40(sp)
    800044f4:	f04a                	sd	s2,32(sp)
    800044f6:	ec4e                	sd	s3,24(sp)
    800044f8:	e852                	sd	s4,16(sp)
    800044fa:	e456                	sd	s5,8(sp)
    800044fc:	e05a                	sd	s6,0(sp)
    800044fe:	0080                	addi	s0,sp,64
    80004500:	8b2a                	mv	s6,a0
    80004502:	00016a97          	auipc	s5,0x16
    80004506:	12ea8a93          	addi	s5,s5,302 # 8001a630 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000450a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000450c:	00016997          	auipc	s3,0x16
    80004510:	0f498993          	addi	s3,s3,244 # 8001a600 <log>
    80004514:	a035                	j	80004540 <install_trans+0x60>
      bunpin(dbuf);
    80004516:	8526                	mv	a0,s1
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	166080e7          	jalr	358(ra) # 8000367e <bunpin>
    brelse(lbuf);
    80004520:	854a                	mv	a0,s2
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	082080e7          	jalr	130(ra) # 800035a4 <brelse>
    brelse(dbuf);
    8000452a:	8526                	mv	a0,s1
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	078080e7          	jalr	120(ra) # 800035a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004534:	2a05                	addiw	s4,s4,1
    80004536:	0a91                	addi	s5,s5,4
    80004538:	02c9a783          	lw	a5,44(s3)
    8000453c:	04fa5963          	bge	s4,a5,8000458e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004540:	0189a583          	lw	a1,24(s3)
    80004544:	014585bb          	addw	a1,a1,s4
    80004548:	2585                	addiw	a1,a1,1
    8000454a:	0289a503          	lw	a0,40(s3)
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	f26080e7          	jalr	-218(ra) # 80003474 <bread>
    80004556:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004558:	000aa583          	lw	a1,0(s5)
    8000455c:	0289a503          	lw	a0,40(s3)
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	f14080e7          	jalr	-236(ra) # 80003474 <bread>
    80004568:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000456a:	40000613          	li	a2,1024
    8000456e:	05890593          	addi	a1,s2,88
    80004572:	05850513          	addi	a0,a0,88
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	7ca080e7          	jalr	1994(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000457e:	8526                	mv	a0,s1
    80004580:	fffff097          	auipc	ra,0xfffff
    80004584:	fe6080e7          	jalr	-26(ra) # 80003566 <bwrite>
    if(recovering == 0)
    80004588:	f80b1ce3          	bnez	s6,80004520 <install_trans+0x40>
    8000458c:	b769                	j	80004516 <install_trans+0x36>
}
    8000458e:	70e2                	ld	ra,56(sp)
    80004590:	7442                	ld	s0,48(sp)
    80004592:	74a2                	ld	s1,40(sp)
    80004594:	7902                	ld	s2,32(sp)
    80004596:	69e2                	ld	s3,24(sp)
    80004598:	6a42                	ld	s4,16(sp)
    8000459a:	6aa2                	ld	s5,8(sp)
    8000459c:	6b02                	ld	s6,0(sp)
    8000459e:	6121                	addi	sp,sp,64
    800045a0:	8082                	ret
    800045a2:	8082                	ret

00000000800045a4 <initlog>:
{
    800045a4:	7179                	addi	sp,sp,-48
    800045a6:	f406                	sd	ra,40(sp)
    800045a8:	f022                	sd	s0,32(sp)
    800045aa:	ec26                	sd	s1,24(sp)
    800045ac:	e84a                	sd	s2,16(sp)
    800045ae:	e44e                	sd	s3,8(sp)
    800045b0:	1800                	addi	s0,sp,48
    800045b2:	892a                	mv	s2,a0
    800045b4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045b6:	00016497          	auipc	s1,0x16
    800045ba:	04a48493          	addi	s1,s1,74 # 8001a600 <log>
    800045be:	00004597          	auipc	a1,0x4
    800045c2:	14a58593          	addi	a1,a1,330 # 80008708 <syscalls+0x1f0>
    800045c6:	8526                	mv	a0,s1
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	58c080e7          	jalr	1420(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800045d0:	0149a583          	lw	a1,20(s3)
    800045d4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045d6:	0109a783          	lw	a5,16(s3)
    800045da:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045dc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045e0:	854a                	mv	a0,s2
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	e92080e7          	jalr	-366(ra) # 80003474 <bread>
  log.lh.n = lh->n;
    800045ea:	4d3c                	lw	a5,88(a0)
    800045ec:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045ee:	02f05563          	blez	a5,80004618 <initlog+0x74>
    800045f2:	05c50713          	addi	a4,a0,92
    800045f6:	00016697          	auipc	a3,0x16
    800045fa:	03a68693          	addi	a3,a3,58 # 8001a630 <log+0x30>
    800045fe:	37fd                	addiw	a5,a5,-1
    80004600:	1782                	slli	a5,a5,0x20
    80004602:	9381                	srli	a5,a5,0x20
    80004604:	078a                	slli	a5,a5,0x2
    80004606:	06050613          	addi	a2,a0,96
    8000460a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000460c:	4310                	lw	a2,0(a4)
    8000460e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004610:	0711                	addi	a4,a4,4
    80004612:	0691                	addi	a3,a3,4
    80004614:	fef71ce3          	bne	a4,a5,8000460c <initlog+0x68>
  brelse(buf);
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	f8c080e7          	jalr	-116(ra) # 800035a4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004620:	4505                	li	a0,1
    80004622:	00000097          	auipc	ra,0x0
    80004626:	ebe080e7          	jalr	-322(ra) # 800044e0 <install_trans>
  log.lh.n = 0;
    8000462a:	00016797          	auipc	a5,0x16
    8000462e:	0007a123          	sw	zero,2(a5) # 8001a62c <log+0x2c>
  write_head(); // clear the log
    80004632:	00000097          	auipc	ra,0x0
    80004636:	e34080e7          	jalr	-460(ra) # 80004466 <write_head>
}
    8000463a:	70a2                	ld	ra,40(sp)
    8000463c:	7402                	ld	s0,32(sp)
    8000463e:	64e2                	ld	s1,24(sp)
    80004640:	6942                	ld	s2,16(sp)
    80004642:	69a2                	ld	s3,8(sp)
    80004644:	6145                	addi	sp,sp,48
    80004646:	8082                	ret

0000000080004648 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004648:	1101                	addi	sp,sp,-32
    8000464a:	ec06                	sd	ra,24(sp)
    8000464c:	e822                	sd	s0,16(sp)
    8000464e:	e426                	sd	s1,8(sp)
    80004650:	e04a                	sd	s2,0(sp)
    80004652:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004654:	00016517          	auipc	a0,0x16
    80004658:	fac50513          	addi	a0,a0,-84 # 8001a600 <log>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	588080e7          	jalr	1416(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004664:	00016497          	auipc	s1,0x16
    80004668:	f9c48493          	addi	s1,s1,-100 # 8001a600 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000466c:	4979                	li	s2,30
    8000466e:	a039                	j	8000467c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004670:	85a6                	mv	a1,s1
    80004672:	8526                	mv	a0,s1
    80004674:	ffffe097          	auipc	ra,0xffffe
    80004678:	dc0080e7          	jalr	-576(ra) # 80002434 <sleep>
    if(log.committing){
    8000467c:	50dc                	lw	a5,36(s1)
    8000467e:	fbed                	bnez	a5,80004670 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004680:	509c                	lw	a5,32(s1)
    80004682:	0017871b          	addiw	a4,a5,1
    80004686:	0007069b          	sext.w	a3,a4
    8000468a:	0027179b          	slliw	a5,a4,0x2
    8000468e:	9fb9                	addw	a5,a5,a4
    80004690:	0017979b          	slliw	a5,a5,0x1
    80004694:	54d8                	lw	a4,44(s1)
    80004696:	9fb9                	addw	a5,a5,a4
    80004698:	00f95963          	bge	s2,a5,800046aa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000469c:	85a6                	mv	a1,s1
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffe097          	auipc	ra,0xffffe
    800046a4:	d94080e7          	jalr	-620(ra) # 80002434 <sleep>
    800046a8:	bfd1                	j	8000467c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046aa:	00016517          	auipc	a0,0x16
    800046ae:	f5650513          	addi	a0,a0,-170 # 8001a600 <log>
    800046b2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	5e4080e7          	jalr	1508(ra) # 80000c98 <release>
      break;
    }
  }
}
    800046bc:	60e2                	ld	ra,24(sp)
    800046be:	6442                	ld	s0,16(sp)
    800046c0:	64a2                	ld	s1,8(sp)
    800046c2:	6902                	ld	s2,0(sp)
    800046c4:	6105                	addi	sp,sp,32
    800046c6:	8082                	ret

00000000800046c8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046c8:	7139                	addi	sp,sp,-64
    800046ca:	fc06                	sd	ra,56(sp)
    800046cc:	f822                	sd	s0,48(sp)
    800046ce:	f426                	sd	s1,40(sp)
    800046d0:	f04a                	sd	s2,32(sp)
    800046d2:	ec4e                	sd	s3,24(sp)
    800046d4:	e852                	sd	s4,16(sp)
    800046d6:	e456                	sd	s5,8(sp)
    800046d8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046da:	00016497          	auipc	s1,0x16
    800046de:	f2648493          	addi	s1,s1,-218 # 8001a600 <log>
    800046e2:	8526                	mv	a0,s1
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	500080e7          	jalr	1280(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800046ec:	509c                	lw	a5,32(s1)
    800046ee:	37fd                	addiw	a5,a5,-1
    800046f0:	0007891b          	sext.w	s2,a5
    800046f4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046f6:	50dc                	lw	a5,36(s1)
    800046f8:	efb9                	bnez	a5,80004756 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046fa:	06091663          	bnez	s2,80004766 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046fe:	00016497          	auipc	s1,0x16
    80004702:	f0248493          	addi	s1,s1,-254 # 8001a600 <log>
    80004706:	4785                	li	a5,1
    80004708:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000470a:	8526                	mv	a0,s1
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	58c080e7          	jalr	1420(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004714:	54dc                	lw	a5,44(s1)
    80004716:	06f04763          	bgtz	a5,80004784 <end_op+0xbc>
    acquire(&log.lock);
    8000471a:	00016497          	auipc	s1,0x16
    8000471e:	ee648493          	addi	s1,s1,-282 # 8001a600 <log>
    80004722:	8526                	mv	a0,s1
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	4c0080e7          	jalr	1216(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000472c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004730:	8526                	mv	a0,s1
    80004732:	ffffe097          	auipc	ra,0xffffe
    80004736:	eaa080e7          	jalr	-342(ra) # 800025dc <wakeup>
    release(&log.lock);
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
}
    80004744:	70e2                	ld	ra,56(sp)
    80004746:	7442                	ld	s0,48(sp)
    80004748:	74a2                	ld	s1,40(sp)
    8000474a:	7902                	ld	s2,32(sp)
    8000474c:	69e2                	ld	s3,24(sp)
    8000474e:	6a42                	ld	s4,16(sp)
    80004750:	6aa2                	ld	s5,8(sp)
    80004752:	6121                	addi	sp,sp,64
    80004754:	8082                	ret
    panic("log.committing");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	fba50513          	addi	a0,a0,-70 # 80008710 <syscalls+0x1f8>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
    wakeup(&log);
    80004766:	00016497          	auipc	s1,0x16
    8000476a:	e9a48493          	addi	s1,s1,-358 # 8001a600 <log>
    8000476e:	8526                	mv	a0,s1
    80004770:	ffffe097          	auipc	ra,0xffffe
    80004774:	e6c080e7          	jalr	-404(ra) # 800025dc <wakeup>
  release(&log.lock);
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	51e080e7          	jalr	1310(ra) # 80000c98 <release>
  if(do_commit){
    80004782:	b7c9                	j	80004744 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004784:	00016a97          	auipc	s5,0x16
    80004788:	eaca8a93          	addi	s5,s5,-340 # 8001a630 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000478c:	00016a17          	auipc	s4,0x16
    80004790:	e74a0a13          	addi	s4,s4,-396 # 8001a600 <log>
    80004794:	018a2583          	lw	a1,24(s4)
    80004798:	012585bb          	addw	a1,a1,s2
    8000479c:	2585                	addiw	a1,a1,1
    8000479e:	028a2503          	lw	a0,40(s4)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	cd2080e7          	jalr	-814(ra) # 80003474 <bread>
    800047aa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047ac:	000aa583          	lw	a1,0(s5)
    800047b0:	028a2503          	lw	a0,40(s4)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	cc0080e7          	jalr	-832(ra) # 80003474 <bread>
    800047bc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047be:	40000613          	li	a2,1024
    800047c2:	05850593          	addi	a1,a0,88
    800047c6:	05848513          	addi	a0,s1,88
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	576080e7          	jalr	1398(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800047d2:	8526                	mv	a0,s1
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	d92080e7          	jalr	-622(ra) # 80003566 <bwrite>
    brelse(from);
    800047dc:	854e                	mv	a0,s3
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	dc6080e7          	jalr	-570(ra) # 800035a4 <brelse>
    brelse(to);
    800047e6:	8526                	mv	a0,s1
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	dbc080e7          	jalr	-580(ra) # 800035a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047f0:	2905                	addiw	s2,s2,1
    800047f2:	0a91                	addi	s5,s5,4
    800047f4:	02ca2783          	lw	a5,44(s4)
    800047f8:	f8f94ee3          	blt	s2,a5,80004794 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	c6a080e7          	jalr	-918(ra) # 80004466 <write_head>
    install_trans(0); // Now install writes to home locations
    80004804:	4501                	li	a0,0
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	cda080e7          	jalr	-806(ra) # 800044e0 <install_trans>
    log.lh.n = 0;
    8000480e:	00016797          	auipc	a5,0x16
    80004812:	e007af23          	sw	zero,-482(a5) # 8001a62c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	c50080e7          	jalr	-944(ra) # 80004466 <write_head>
    8000481e:	bdf5                	j	8000471a <end_op+0x52>

0000000080004820 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004820:	1101                	addi	sp,sp,-32
    80004822:	ec06                	sd	ra,24(sp)
    80004824:	e822                	sd	s0,16(sp)
    80004826:	e426                	sd	s1,8(sp)
    80004828:	e04a                	sd	s2,0(sp)
    8000482a:	1000                	addi	s0,sp,32
    8000482c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000482e:	00016917          	auipc	s2,0x16
    80004832:	dd290913          	addi	s2,s2,-558 # 8001a600 <log>
    80004836:	854a                	mv	a0,s2
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	3ac080e7          	jalr	940(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004840:	02c92603          	lw	a2,44(s2)
    80004844:	47f5                	li	a5,29
    80004846:	06c7c563          	blt	a5,a2,800048b0 <log_write+0x90>
    8000484a:	00016797          	auipc	a5,0x16
    8000484e:	dd27a783          	lw	a5,-558(a5) # 8001a61c <log+0x1c>
    80004852:	37fd                	addiw	a5,a5,-1
    80004854:	04f65e63          	bge	a2,a5,800048b0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004858:	00016797          	auipc	a5,0x16
    8000485c:	dc87a783          	lw	a5,-568(a5) # 8001a620 <log+0x20>
    80004860:	06f05063          	blez	a5,800048c0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004864:	4781                	li	a5,0
    80004866:	06c05563          	blez	a2,800048d0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000486a:	44cc                	lw	a1,12(s1)
    8000486c:	00016717          	auipc	a4,0x16
    80004870:	dc470713          	addi	a4,a4,-572 # 8001a630 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004874:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004876:	4314                	lw	a3,0(a4)
    80004878:	04b68c63          	beq	a3,a1,800048d0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000487c:	2785                	addiw	a5,a5,1
    8000487e:	0711                	addi	a4,a4,4
    80004880:	fef61be3          	bne	a2,a5,80004876 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004884:	0621                	addi	a2,a2,8
    80004886:	060a                	slli	a2,a2,0x2
    80004888:	00016797          	auipc	a5,0x16
    8000488c:	d7878793          	addi	a5,a5,-648 # 8001a600 <log>
    80004890:	963e                	add	a2,a2,a5
    80004892:	44dc                	lw	a5,12(s1)
    80004894:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004896:	8526                	mv	a0,s1
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	daa080e7          	jalr	-598(ra) # 80003642 <bpin>
    log.lh.n++;
    800048a0:	00016717          	auipc	a4,0x16
    800048a4:	d6070713          	addi	a4,a4,-672 # 8001a600 <log>
    800048a8:	575c                	lw	a5,44(a4)
    800048aa:	2785                	addiw	a5,a5,1
    800048ac:	d75c                	sw	a5,44(a4)
    800048ae:	a835                	j	800048ea <log_write+0xca>
    panic("too big a transaction");
    800048b0:	00004517          	auipc	a0,0x4
    800048b4:	e7050513          	addi	a0,a0,-400 # 80008720 <syscalls+0x208>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	c86080e7          	jalr	-890(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048c0:	00004517          	auipc	a0,0x4
    800048c4:	e7850513          	addi	a0,a0,-392 # 80008738 <syscalls+0x220>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	c76080e7          	jalr	-906(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800048d0:	00878713          	addi	a4,a5,8
    800048d4:	00271693          	slli	a3,a4,0x2
    800048d8:	00016717          	auipc	a4,0x16
    800048dc:	d2870713          	addi	a4,a4,-728 # 8001a600 <log>
    800048e0:	9736                	add	a4,a4,a3
    800048e2:	44d4                	lw	a3,12(s1)
    800048e4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048e6:	faf608e3          	beq	a2,a5,80004896 <log_write+0x76>
  }
  release(&log.lock);
    800048ea:	00016517          	auipc	a0,0x16
    800048ee:	d1650513          	addi	a0,a0,-746 # 8001a600 <log>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	3a6080e7          	jalr	934(ra) # 80000c98 <release>
}
    800048fa:	60e2                	ld	ra,24(sp)
    800048fc:	6442                	ld	s0,16(sp)
    800048fe:	64a2                	ld	s1,8(sp)
    80004900:	6902                	ld	s2,0(sp)
    80004902:	6105                	addi	sp,sp,32
    80004904:	8082                	ret

0000000080004906 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004906:	1101                	addi	sp,sp,-32
    80004908:	ec06                	sd	ra,24(sp)
    8000490a:	e822                	sd	s0,16(sp)
    8000490c:	e426                	sd	s1,8(sp)
    8000490e:	e04a                	sd	s2,0(sp)
    80004910:	1000                	addi	s0,sp,32
    80004912:	84aa                	mv	s1,a0
    80004914:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004916:	00004597          	auipc	a1,0x4
    8000491a:	e4258593          	addi	a1,a1,-446 # 80008758 <syscalls+0x240>
    8000491e:	0521                	addi	a0,a0,8
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	234080e7          	jalr	564(ra) # 80000b54 <initlock>
  lk->name = name;
    80004928:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000492c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004930:	0204a423          	sw	zero,40(s1)
}
    80004934:	60e2                	ld	ra,24(sp)
    80004936:	6442                	ld	s0,16(sp)
    80004938:	64a2                	ld	s1,8(sp)
    8000493a:	6902                	ld	s2,0(sp)
    8000493c:	6105                	addi	sp,sp,32
    8000493e:	8082                	ret

0000000080004940 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004940:	1101                	addi	sp,sp,-32
    80004942:	ec06                	sd	ra,24(sp)
    80004944:	e822                	sd	s0,16(sp)
    80004946:	e426                	sd	s1,8(sp)
    80004948:	e04a                	sd	s2,0(sp)
    8000494a:	1000                	addi	s0,sp,32
    8000494c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000494e:	00850913          	addi	s2,a0,8
    80004952:	854a                	mv	a0,s2
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	290080e7          	jalr	656(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000495c:	409c                	lw	a5,0(s1)
    8000495e:	cb89                	beqz	a5,80004970 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004960:	85ca                	mv	a1,s2
    80004962:	8526                	mv	a0,s1
    80004964:	ffffe097          	auipc	ra,0xffffe
    80004968:	ad0080e7          	jalr	-1328(ra) # 80002434 <sleep>
  while (lk->locked) {
    8000496c:	409c                	lw	a5,0(s1)
    8000496e:	fbed                	bnez	a5,80004960 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004970:	4785                	li	a5,1
    80004972:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004974:	ffffd097          	auipc	ra,0xffffd
    80004978:	054080e7          	jalr	84(ra) # 800019c8 <myproc>
    8000497c:	591c                	lw	a5,48(a0)
    8000497e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004980:	854a                	mv	a0,s2
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	316080e7          	jalr	790(ra) # 80000c98 <release>
}
    8000498a:	60e2                	ld	ra,24(sp)
    8000498c:	6442                	ld	s0,16(sp)
    8000498e:	64a2                	ld	s1,8(sp)
    80004990:	6902                	ld	s2,0(sp)
    80004992:	6105                	addi	sp,sp,32
    80004994:	8082                	ret

0000000080004996 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004996:	1101                	addi	sp,sp,-32
    80004998:	ec06                	sd	ra,24(sp)
    8000499a:	e822                	sd	s0,16(sp)
    8000499c:	e426                	sd	s1,8(sp)
    8000499e:	e04a                	sd	s2,0(sp)
    800049a0:	1000                	addi	s0,sp,32
    800049a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049a4:	00850913          	addi	s2,a0,8
    800049a8:	854a                	mv	a0,s2
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	23a080e7          	jalr	570(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049b6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049ba:	8526                	mv	a0,s1
    800049bc:	ffffe097          	auipc	ra,0xffffe
    800049c0:	c20080e7          	jalr	-992(ra) # 800025dc <wakeup>
  release(&lk->lk);
    800049c4:	854a                	mv	a0,s2
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	2d2080e7          	jalr	722(ra) # 80000c98 <release>
}
    800049ce:	60e2                	ld	ra,24(sp)
    800049d0:	6442                	ld	s0,16(sp)
    800049d2:	64a2                	ld	s1,8(sp)
    800049d4:	6902                	ld	s2,0(sp)
    800049d6:	6105                	addi	sp,sp,32
    800049d8:	8082                	ret

00000000800049da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049da:	7179                	addi	sp,sp,-48
    800049dc:	f406                	sd	ra,40(sp)
    800049de:	f022                	sd	s0,32(sp)
    800049e0:	ec26                	sd	s1,24(sp)
    800049e2:	e84a                	sd	s2,16(sp)
    800049e4:	e44e                	sd	s3,8(sp)
    800049e6:	1800                	addi	s0,sp,48
    800049e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049ea:	00850913          	addi	s2,a0,8
    800049ee:	854a                	mv	a0,s2
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	1f4080e7          	jalr	500(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049f8:	409c                	lw	a5,0(s1)
    800049fa:	ef99                	bnez	a5,80004a18 <holdingsleep+0x3e>
    800049fc:	4481                	li	s1,0
  release(&lk->lk);
    800049fe:	854a                	mv	a0,s2
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
  return r;
}
    80004a08:	8526                	mv	a0,s1
    80004a0a:	70a2                	ld	ra,40(sp)
    80004a0c:	7402                	ld	s0,32(sp)
    80004a0e:	64e2                	ld	s1,24(sp)
    80004a10:	6942                	ld	s2,16(sp)
    80004a12:	69a2                	ld	s3,8(sp)
    80004a14:	6145                	addi	sp,sp,48
    80004a16:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a18:	0284a983          	lw	s3,40(s1)
    80004a1c:	ffffd097          	auipc	ra,0xffffd
    80004a20:	fac080e7          	jalr	-84(ra) # 800019c8 <myproc>
    80004a24:	5904                	lw	s1,48(a0)
    80004a26:	413484b3          	sub	s1,s1,s3
    80004a2a:	0014b493          	seqz	s1,s1
    80004a2e:	bfc1                	j	800049fe <holdingsleep+0x24>

0000000080004a30 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a30:	1141                	addi	sp,sp,-16
    80004a32:	e406                	sd	ra,8(sp)
    80004a34:	e022                	sd	s0,0(sp)
    80004a36:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a38:	00004597          	auipc	a1,0x4
    80004a3c:	d3058593          	addi	a1,a1,-720 # 80008768 <syscalls+0x250>
    80004a40:	00016517          	auipc	a0,0x16
    80004a44:	d0850513          	addi	a0,a0,-760 # 8001a748 <ftable>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	10c080e7          	jalr	268(ra) # 80000b54 <initlock>
}
    80004a50:	60a2                	ld	ra,8(sp)
    80004a52:	6402                	ld	s0,0(sp)
    80004a54:	0141                	addi	sp,sp,16
    80004a56:	8082                	ret

0000000080004a58 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a58:	1101                	addi	sp,sp,-32
    80004a5a:	ec06                	sd	ra,24(sp)
    80004a5c:	e822                	sd	s0,16(sp)
    80004a5e:	e426                	sd	s1,8(sp)
    80004a60:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a62:	00016517          	auipc	a0,0x16
    80004a66:	ce650513          	addi	a0,a0,-794 # 8001a748 <ftable>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	17a080e7          	jalr	378(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a72:	00016497          	auipc	s1,0x16
    80004a76:	cee48493          	addi	s1,s1,-786 # 8001a760 <ftable+0x18>
    80004a7a:	00017717          	auipc	a4,0x17
    80004a7e:	c8670713          	addi	a4,a4,-890 # 8001b700 <ftable+0xfb8>
    if(f->ref == 0){
    80004a82:	40dc                	lw	a5,4(s1)
    80004a84:	cf99                	beqz	a5,80004aa2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a86:	02848493          	addi	s1,s1,40
    80004a8a:	fee49ce3          	bne	s1,a4,80004a82 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a8e:	00016517          	auipc	a0,0x16
    80004a92:	cba50513          	addi	a0,a0,-838 # 8001a748 <ftable>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>
  return 0;
    80004a9e:	4481                	li	s1,0
    80004aa0:	a819                	j	80004ab6 <filealloc+0x5e>
      f->ref = 1;
    80004aa2:	4785                	li	a5,1
    80004aa4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004aa6:	00016517          	auipc	a0,0x16
    80004aaa:	ca250513          	addi	a0,a0,-862 # 8001a748 <ftable>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	1ea080e7          	jalr	490(ra) # 80000c98 <release>
}
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	60e2                	ld	ra,24(sp)
    80004aba:	6442                	ld	s0,16(sp)
    80004abc:	64a2                	ld	s1,8(sp)
    80004abe:	6105                	addi	sp,sp,32
    80004ac0:	8082                	ret

0000000080004ac2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ac2:	1101                	addi	sp,sp,-32
    80004ac4:	ec06                	sd	ra,24(sp)
    80004ac6:	e822                	sd	s0,16(sp)
    80004ac8:	e426                	sd	s1,8(sp)
    80004aca:	1000                	addi	s0,sp,32
    80004acc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ace:	00016517          	auipc	a0,0x16
    80004ad2:	c7a50513          	addi	a0,a0,-902 # 8001a748 <ftable>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	10e080e7          	jalr	270(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ade:	40dc                	lw	a5,4(s1)
    80004ae0:	02f05263          	blez	a5,80004b04 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ae4:	2785                	addiw	a5,a5,1
    80004ae6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ae8:	00016517          	auipc	a0,0x16
    80004aec:	c6050513          	addi	a0,a0,-928 # 8001a748 <ftable>
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	1a8080e7          	jalr	424(ra) # 80000c98 <release>
  return f;
}
    80004af8:	8526                	mv	a0,s1
    80004afa:	60e2                	ld	ra,24(sp)
    80004afc:	6442                	ld	s0,16(sp)
    80004afe:	64a2                	ld	s1,8(sp)
    80004b00:	6105                	addi	sp,sp,32
    80004b02:	8082                	ret
    panic("filedup");
    80004b04:	00004517          	auipc	a0,0x4
    80004b08:	c6c50513          	addi	a0,a0,-916 # 80008770 <syscalls+0x258>
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>

0000000080004b14 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b14:	7139                	addi	sp,sp,-64
    80004b16:	fc06                	sd	ra,56(sp)
    80004b18:	f822                	sd	s0,48(sp)
    80004b1a:	f426                	sd	s1,40(sp)
    80004b1c:	f04a                	sd	s2,32(sp)
    80004b1e:	ec4e                	sd	s3,24(sp)
    80004b20:	e852                	sd	s4,16(sp)
    80004b22:	e456                	sd	s5,8(sp)
    80004b24:	0080                	addi	s0,sp,64
    80004b26:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b28:	00016517          	auipc	a0,0x16
    80004b2c:	c2050513          	addi	a0,a0,-992 # 8001a748 <ftable>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	0b4080e7          	jalr	180(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b38:	40dc                	lw	a5,4(s1)
    80004b3a:	06f05163          	blez	a5,80004b9c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b3e:	37fd                	addiw	a5,a5,-1
    80004b40:	0007871b          	sext.w	a4,a5
    80004b44:	c0dc                	sw	a5,4(s1)
    80004b46:	06e04363          	bgtz	a4,80004bac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b4a:	0004a903          	lw	s2,0(s1)
    80004b4e:	0094ca83          	lbu	s5,9(s1)
    80004b52:	0104ba03          	ld	s4,16(s1)
    80004b56:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b5a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b5e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b62:	00016517          	auipc	a0,0x16
    80004b66:	be650513          	addi	a0,a0,-1050 # 8001a748 <ftable>
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	12e080e7          	jalr	302(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b72:	4785                	li	a5,1
    80004b74:	04f90d63          	beq	s2,a5,80004bce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b78:	3979                	addiw	s2,s2,-2
    80004b7a:	4785                	li	a5,1
    80004b7c:	0527e063          	bltu	a5,s2,80004bbc <fileclose+0xa8>
    begin_op();
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	ac8080e7          	jalr	-1336(ra) # 80004648 <begin_op>
    iput(ff.ip);
    80004b88:	854e                	mv	a0,s3
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	2a6080e7          	jalr	678(ra) # 80003e30 <iput>
    end_op();
    80004b92:	00000097          	auipc	ra,0x0
    80004b96:	b36080e7          	jalr	-1226(ra) # 800046c8 <end_op>
    80004b9a:	a00d                	j	80004bbc <fileclose+0xa8>
    panic("fileclose");
    80004b9c:	00004517          	auipc	a0,0x4
    80004ba0:	bdc50513          	addi	a0,a0,-1060 # 80008778 <syscalls+0x260>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	99a080e7          	jalr	-1638(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004bac:	00016517          	auipc	a0,0x16
    80004bb0:	b9c50513          	addi	a0,a0,-1124 # 8001a748 <ftable>
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0e4080e7          	jalr	228(ra) # 80000c98 <release>
  }
}
    80004bbc:	70e2                	ld	ra,56(sp)
    80004bbe:	7442                	ld	s0,48(sp)
    80004bc0:	74a2                	ld	s1,40(sp)
    80004bc2:	7902                	ld	s2,32(sp)
    80004bc4:	69e2                	ld	s3,24(sp)
    80004bc6:	6a42                	ld	s4,16(sp)
    80004bc8:	6aa2                	ld	s5,8(sp)
    80004bca:	6121                	addi	sp,sp,64
    80004bcc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bce:	85d6                	mv	a1,s5
    80004bd0:	8552                	mv	a0,s4
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	34c080e7          	jalr	844(ra) # 80004f1e <pipeclose>
    80004bda:	b7cd                	j	80004bbc <fileclose+0xa8>

0000000080004bdc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bdc:	715d                	addi	sp,sp,-80
    80004bde:	e486                	sd	ra,72(sp)
    80004be0:	e0a2                	sd	s0,64(sp)
    80004be2:	fc26                	sd	s1,56(sp)
    80004be4:	f84a                	sd	s2,48(sp)
    80004be6:	f44e                	sd	s3,40(sp)
    80004be8:	0880                	addi	s0,sp,80
    80004bea:	84aa                	mv	s1,a0
    80004bec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	dda080e7          	jalr	-550(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bf6:	409c                	lw	a5,0(s1)
    80004bf8:	37f9                	addiw	a5,a5,-2
    80004bfa:	4705                	li	a4,1
    80004bfc:	04f76763          	bltu	a4,a5,80004c4a <filestat+0x6e>
    80004c00:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c02:	6c88                	ld	a0,24(s1)
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	072080e7          	jalr	114(ra) # 80003c76 <ilock>
    stati(f->ip, &st);
    80004c0c:	fb840593          	addi	a1,s0,-72
    80004c10:	6c88                	ld	a0,24(s1)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	2ee080e7          	jalr	750(ra) # 80003f00 <stati>
    iunlock(f->ip);
    80004c1a:	6c88                	ld	a0,24(s1)
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	11c080e7          	jalr	284(ra) # 80003d38 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c24:	46e1                	li	a3,24
    80004c26:	fb840613          	addi	a2,s0,-72
    80004c2a:	85ce                	mv	a1,s3
    80004c2c:	05093503          	ld	a0,80(s2)
    80004c30:	ffffd097          	auipc	ra,0xffffd
    80004c34:	a4a080e7          	jalr	-1462(ra) # 8000167a <copyout>
    80004c38:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c3c:	60a6                	ld	ra,72(sp)
    80004c3e:	6406                	ld	s0,64(sp)
    80004c40:	74e2                	ld	s1,56(sp)
    80004c42:	7942                	ld	s2,48(sp)
    80004c44:	79a2                	ld	s3,40(sp)
    80004c46:	6161                	addi	sp,sp,80
    80004c48:	8082                	ret
  return -1;
    80004c4a:	557d                	li	a0,-1
    80004c4c:	bfc5                	j	80004c3c <filestat+0x60>

0000000080004c4e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c4e:	7179                	addi	sp,sp,-48
    80004c50:	f406                	sd	ra,40(sp)
    80004c52:	f022                	sd	s0,32(sp)
    80004c54:	ec26                	sd	s1,24(sp)
    80004c56:	e84a                	sd	s2,16(sp)
    80004c58:	e44e                	sd	s3,8(sp)
    80004c5a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c5c:	00854783          	lbu	a5,8(a0)
    80004c60:	c3d5                	beqz	a5,80004d04 <fileread+0xb6>
    80004c62:	84aa                	mv	s1,a0
    80004c64:	89ae                	mv	s3,a1
    80004c66:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c68:	411c                	lw	a5,0(a0)
    80004c6a:	4705                	li	a4,1
    80004c6c:	04e78963          	beq	a5,a4,80004cbe <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c70:	470d                	li	a4,3
    80004c72:	04e78d63          	beq	a5,a4,80004ccc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c76:	4709                	li	a4,2
    80004c78:	06e79e63          	bne	a5,a4,80004cf4 <fileread+0xa6>
    ilock(f->ip);
    80004c7c:	6d08                	ld	a0,24(a0)
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	ff8080e7          	jalr	-8(ra) # 80003c76 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c86:	874a                	mv	a4,s2
    80004c88:	5094                	lw	a3,32(s1)
    80004c8a:	864e                	mv	a2,s3
    80004c8c:	4585                	li	a1,1
    80004c8e:	6c88                	ld	a0,24(s1)
    80004c90:	fffff097          	auipc	ra,0xfffff
    80004c94:	29a080e7          	jalr	666(ra) # 80003f2a <readi>
    80004c98:	892a                	mv	s2,a0
    80004c9a:	00a05563          	blez	a0,80004ca4 <fileread+0x56>
      f->off += r;
    80004c9e:	509c                	lw	a5,32(s1)
    80004ca0:	9fa9                	addw	a5,a5,a0
    80004ca2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ca4:	6c88                	ld	a0,24(s1)
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	092080e7          	jalr	146(ra) # 80003d38 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cae:	854a                	mv	a0,s2
    80004cb0:	70a2                	ld	ra,40(sp)
    80004cb2:	7402                	ld	s0,32(sp)
    80004cb4:	64e2                	ld	s1,24(sp)
    80004cb6:	6942                	ld	s2,16(sp)
    80004cb8:	69a2                	ld	s3,8(sp)
    80004cba:	6145                	addi	sp,sp,48
    80004cbc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cbe:	6908                	ld	a0,16(a0)
    80004cc0:	00000097          	auipc	ra,0x0
    80004cc4:	3c8080e7          	jalr	968(ra) # 80005088 <piperead>
    80004cc8:	892a                	mv	s2,a0
    80004cca:	b7d5                	j	80004cae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ccc:	02451783          	lh	a5,36(a0)
    80004cd0:	03079693          	slli	a3,a5,0x30
    80004cd4:	92c1                	srli	a3,a3,0x30
    80004cd6:	4725                	li	a4,9
    80004cd8:	02d76863          	bltu	a4,a3,80004d08 <fileread+0xba>
    80004cdc:	0792                	slli	a5,a5,0x4
    80004cde:	00016717          	auipc	a4,0x16
    80004ce2:	9ca70713          	addi	a4,a4,-1590 # 8001a6a8 <devsw>
    80004ce6:	97ba                	add	a5,a5,a4
    80004ce8:	639c                	ld	a5,0(a5)
    80004cea:	c38d                	beqz	a5,80004d0c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cec:	4505                	li	a0,1
    80004cee:	9782                	jalr	a5
    80004cf0:	892a                	mv	s2,a0
    80004cf2:	bf75                	j	80004cae <fileread+0x60>
    panic("fileread");
    80004cf4:	00004517          	auipc	a0,0x4
    80004cf8:	a9450513          	addi	a0,a0,-1388 # 80008788 <syscalls+0x270>
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>
    return -1;
    80004d04:	597d                	li	s2,-1
    80004d06:	b765                	j	80004cae <fileread+0x60>
      return -1;
    80004d08:	597d                	li	s2,-1
    80004d0a:	b755                	j	80004cae <fileread+0x60>
    80004d0c:	597d                	li	s2,-1
    80004d0e:	b745                	j	80004cae <fileread+0x60>

0000000080004d10 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d10:	715d                	addi	sp,sp,-80
    80004d12:	e486                	sd	ra,72(sp)
    80004d14:	e0a2                	sd	s0,64(sp)
    80004d16:	fc26                	sd	s1,56(sp)
    80004d18:	f84a                	sd	s2,48(sp)
    80004d1a:	f44e                	sd	s3,40(sp)
    80004d1c:	f052                	sd	s4,32(sp)
    80004d1e:	ec56                	sd	s5,24(sp)
    80004d20:	e85a                	sd	s6,16(sp)
    80004d22:	e45e                	sd	s7,8(sp)
    80004d24:	e062                	sd	s8,0(sp)
    80004d26:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d28:	00954783          	lbu	a5,9(a0)
    80004d2c:	10078663          	beqz	a5,80004e38 <filewrite+0x128>
    80004d30:	892a                	mv	s2,a0
    80004d32:	8aae                	mv	s5,a1
    80004d34:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d36:	411c                	lw	a5,0(a0)
    80004d38:	4705                	li	a4,1
    80004d3a:	02e78263          	beq	a5,a4,80004d5e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d3e:	470d                	li	a4,3
    80004d40:	02e78663          	beq	a5,a4,80004d6c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d44:	4709                	li	a4,2
    80004d46:	0ee79163          	bne	a5,a4,80004e28 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d4a:	0ac05d63          	blez	a2,80004e04 <filewrite+0xf4>
    int i = 0;
    80004d4e:	4981                	li	s3,0
    80004d50:	6b05                	lui	s6,0x1
    80004d52:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d56:	6b85                	lui	s7,0x1
    80004d58:	c00b8b9b          	addiw	s7,s7,-1024
    80004d5c:	a861                	j	80004df4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d5e:	6908                	ld	a0,16(a0)
    80004d60:	00000097          	auipc	ra,0x0
    80004d64:	22e080e7          	jalr	558(ra) # 80004f8e <pipewrite>
    80004d68:	8a2a                	mv	s4,a0
    80004d6a:	a045                	j	80004e0a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d6c:	02451783          	lh	a5,36(a0)
    80004d70:	03079693          	slli	a3,a5,0x30
    80004d74:	92c1                	srli	a3,a3,0x30
    80004d76:	4725                	li	a4,9
    80004d78:	0cd76263          	bltu	a4,a3,80004e3c <filewrite+0x12c>
    80004d7c:	0792                	slli	a5,a5,0x4
    80004d7e:	00016717          	auipc	a4,0x16
    80004d82:	92a70713          	addi	a4,a4,-1750 # 8001a6a8 <devsw>
    80004d86:	97ba                	add	a5,a5,a4
    80004d88:	679c                	ld	a5,8(a5)
    80004d8a:	cbdd                	beqz	a5,80004e40 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d8c:	4505                	li	a0,1
    80004d8e:	9782                	jalr	a5
    80004d90:	8a2a                	mv	s4,a0
    80004d92:	a8a5                	j	80004e0a <filewrite+0xfa>
    80004d94:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d98:	00000097          	auipc	ra,0x0
    80004d9c:	8b0080e7          	jalr	-1872(ra) # 80004648 <begin_op>
      ilock(f->ip);
    80004da0:	01893503          	ld	a0,24(s2)
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	ed2080e7          	jalr	-302(ra) # 80003c76 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dac:	8762                	mv	a4,s8
    80004dae:	02092683          	lw	a3,32(s2)
    80004db2:	01598633          	add	a2,s3,s5
    80004db6:	4585                	li	a1,1
    80004db8:	01893503          	ld	a0,24(s2)
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	266080e7          	jalr	614(ra) # 80004022 <writei>
    80004dc4:	84aa                	mv	s1,a0
    80004dc6:	00a05763          	blez	a0,80004dd4 <filewrite+0xc4>
        f->off += r;
    80004dca:	02092783          	lw	a5,32(s2)
    80004dce:	9fa9                	addw	a5,a5,a0
    80004dd0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dd4:	01893503          	ld	a0,24(s2)
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	f60080e7          	jalr	-160(ra) # 80003d38 <iunlock>
      end_op();
    80004de0:	00000097          	auipc	ra,0x0
    80004de4:	8e8080e7          	jalr	-1816(ra) # 800046c8 <end_op>

      if(r != n1){
    80004de8:	009c1f63          	bne	s8,s1,80004e06 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004df0:	0149db63          	bge	s3,s4,80004e06 <filewrite+0xf6>
      int n1 = n - i;
    80004df4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004df8:	84be                	mv	s1,a5
    80004dfa:	2781                	sext.w	a5,a5
    80004dfc:	f8fb5ce3          	bge	s6,a5,80004d94 <filewrite+0x84>
    80004e00:	84de                	mv	s1,s7
    80004e02:	bf49                	j	80004d94 <filewrite+0x84>
    int i = 0;
    80004e04:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e06:	013a1f63          	bne	s4,s3,80004e24 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e0a:	8552                	mv	a0,s4
    80004e0c:	60a6                	ld	ra,72(sp)
    80004e0e:	6406                	ld	s0,64(sp)
    80004e10:	74e2                	ld	s1,56(sp)
    80004e12:	7942                	ld	s2,48(sp)
    80004e14:	79a2                	ld	s3,40(sp)
    80004e16:	7a02                	ld	s4,32(sp)
    80004e18:	6ae2                	ld	s5,24(sp)
    80004e1a:	6b42                	ld	s6,16(sp)
    80004e1c:	6ba2                	ld	s7,8(sp)
    80004e1e:	6c02                	ld	s8,0(sp)
    80004e20:	6161                	addi	sp,sp,80
    80004e22:	8082                	ret
    ret = (i == n ? n : -1);
    80004e24:	5a7d                	li	s4,-1
    80004e26:	b7d5                	j	80004e0a <filewrite+0xfa>
    panic("filewrite");
    80004e28:	00004517          	auipc	a0,0x4
    80004e2c:	97050513          	addi	a0,a0,-1680 # 80008798 <syscalls+0x280>
    80004e30:	ffffb097          	auipc	ra,0xffffb
    80004e34:	70e080e7          	jalr	1806(ra) # 8000053e <panic>
    return -1;
    80004e38:	5a7d                	li	s4,-1
    80004e3a:	bfc1                	j	80004e0a <filewrite+0xfa>
      return -1;
    80004e3c:	5a7d                	li	s4,-1
    80004e3e:	b7f1                	j	80004e0a <filewrite+0xfa>
    80004e40:	5a7d                	li	s4,-1
    80004e42:	b7e1                	j	80004e0a <filewrite+0xfa>

0000000080004e44 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e44:	7179                	addi	sp,sp,-48
    80004e46:	f406                	sd	ra,40(sp)
    80004e48:	f022                	sd	s0,32(sp)
    80004e4a:	ec26                	sd	s1,24(sp)
    80004e4c:	e84a                	sd	s2,16(sp)
    80004e4e:	e44e                	sd	s3,8(sp)
    80004e50:	e052                	sd	s4,0(sp)
    80004e52:	1800                	addi	s0,sp,48
    80004e54:	84aa                	mv	s1,a0
    80004e56:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e58:	0005b023          	sd	zero,0(a1)
    80004e5c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	bf8080e7          	jalr	-1032(ra) # 80004a58 <filealloc>
    80004e68:	e088                	sd	a0,0(s1)
    80004e6a:	c551                	beqz	a0,80004ef6 <pipealloc+0xb2>
    80004e6c:	00000097          	auipc	ra,0x0
    80004e70:	bec080e7          	jalr	-1044(ra) # 80004a58 <filealloc>
    80004e74:	00aa3023          	sd	a0,0(s4)
    80004e78:	c92d                	beqz	a0,80004eea <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	c7a080e7          	jalr	-902(ra) # 80000af4 <kalloc>
    80004e82:	892a                	mv	s2,a0
    80004e84:	c125                	beqz	a0,80004ee4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e86:	4985                	li	s3,1
    80004e88:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e8c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e90:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e94:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e98:	00004597          	auipc	a1,0x4
    80004e9c:	91058593          	addi	a1,a1,-1776 # 800087a8 <syscalls+0x290>
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	cb4080e7          	jalr	-844(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ea8:	609c                	ld	a5,0(s1)
    80004eaa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004eae:	609c                	ld	a5,0(s1)
    80004eb0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004eb4:	609c                	ld	a5,0(s1)
    80004eb6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004eba:	609c                	ld	a5,0(s1)
    80004ebc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ec0:	000a3783          	ld	a5,0(s4)
    80004ec4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ec8:	000a3783          	ld	a5,0(s4)
    80004ecc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ed0:	000a3783          	ld	a5,0(s4)
    80004ed4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ed8:	000a3783          	ld	a5,0(s4)
    80004edc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ee0:	4501                	li	a0,0
    80004ee2:	a025                	j	80004f0a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ee4:	6088                	ld	a0,0(s1)
    80004ee6:	e501                	bnez	a0,80004eee <pipealloc+0xaa>
    80004ee8:	a039                	j	80004ef6 <pipealloc+0xb2>
    80004eea:	6088                	ld	a0,0(s1)
    80004eec:	c51d                	beqz	a0,80004f1a <pipealloc+0xd6>
    fileclose(*f0);
    80004eee:	00000097          	auipc	ra,0x0
    80004ef2:	c26080e7          	jalr	-986(ra) # 80004b14 <fileclose>
  if(*f1)
    80004ef6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004efa:	557d                	li	a0,-1
  if(*f1)
    80004efc:	c799                	beqz	a5,80004f0a <pipealloc+0xc6>
    fileclose(*f1);
    80004efe:	853e                	mv	a0,a5
    80004f00:	00000097          	auipc	ra,0x0
    80004f04:	c14080e7          	jalr	-1004(ra) # 80004b14 <fileclose>
  return -1;
    80004f08:	557d                	li	a0,-1
}
    80004f0a:	70a2                	ld	ra,40(sp)
    80004f0c:	7402                	ld	s0,32(sp)
    80004f0e:	64e2                	ld	s1,24(sp)
    80004f10:	6942                	ld	s2,16(sp)
    80004f12:	69a2                	ld	s3,8(sp)
    80004f14:	6a02                	ld	s4,0(sp)
    80004f16:	6145                	addi	sp,sp,48
    80004f18:	8082                	ret
  return -1;
    80004f1a:	557d                	li	a0,-1
    80004f1c:	b7fd                	j	80004f0a <pipealloc+0xc6>

0000000080004f1e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f1e:	1101                	addi	sp,sp,-32
    80004f20:	ec06                	sd	ra,24(sp)
    80004f22:	e822                	sd	s0,16(sp)
    80004f24:	e426                	sd	s1,8(sp)
    80004f26:	e04a                	sd	s2,0(sp)
    80004f28:	1000                	addi	s0,sp,32
    80004f2a:	84aa                	mv	s1,a0
    80004f2c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	cb6080e7          	jalr	-842(ra) # 80000be4 <acquire>
  if(writable){
    80004f36:	02090d63          	beqz	s2,80004f70 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f3a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f3e:	21848513          	addi	a0,s1,536
    80004f42:	ffffd097          	auipc	ra,0xffffd
    80004f46:	69a080e7          	jalr	1690(ra) # 800025dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f4a:	2204b783          	ld	a5,544(s1)
    80004f4e:	eb95                	bnez	a5,80004f82 <pipeclose+0x64>
    release(&pi->lock);
    80004f50:	8526                	mv	a0,s1
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	d46080e7          	jalr	-698(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f5a:	8526                	mv	a0,s1
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	a9c080e7          	jalr	-1380(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f64:	60e2                	ld	ra,24(sp)
    80004f66:	6442                	ld	s0,16(sp)
    80004f68:	64a2                	ld	s1,8(sp)
    80004f6a:	6902                	ld	s2,0(sp)
    80004f6c:	6105                	addi	sp,sp,32
    80004f6e:	8082                	ret
    pi->readopen = 0;
    80004f70:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f74:	21c48513          	addi	a0,s1,540
    80004f78:	ffffd097          	auipc	ra,0xffffd
    80004f7c:	664080e7          	jalr	1636(ra) # 800025dc <wakeup>
    80004f80:	b7e9                	j	80004f4a <pipeclose+0x2c>
    release(&pi->lock);
    80004f82:	8526                	mv	a0,s1
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
}
    80004f8c:	bfe1                	j	80004f64 <pipeclose+0x46>

0000000080004f8e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f8e:	7159                	addi	sp,sp,-112
    80004f90:	f486                	sd	ra,104(sp)
    80004f92:	f0a2                	sd	s0,96(sp)
    80004f94:	eca6                	sd	s1,88(sp)
    80004f96:	e8ca                	sd	s2,80(sp)
    80004f98:	e4ce                	sd	s3,72(sp)
    80004f9a:	e0d2                	sd	s4,64(sp)
    80004f9c:	fc56                	sd	s5,56(sp)
    80004f9e:	f85a                	sd	s6,48(sp)
    80004fa0:	f45e                	sd	s7,40(sp)
    80004fa2:	f062                	sd	s8,32(sp)
    80004fa4:	ec66                	sd	s9,24(sp)
    80004fa6:	1880                	addi	s0,sp,112
    80004fa8:	84aa                	mv	s1,a0
    80004faa:	8aae                	mv	s5,a1
    80004fac:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	a1a080e7          	jalr	-1510(ra) # 800019c8 <myproc>
    80004fb6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fb8:	8526                	mv	a0,s1
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	c2a080e7          	jalr	-982(ra) # 80000be4 <acquire>
  while(i < n){
    80004fc2:	0d405163          	blez	s4,80005084 <pipewrite+0xf6>
    80004fc6:	8ba6                	mv	s7,s1
  int i = 0;
    80004fc8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fca:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fcc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fd0:	21c48c13          	addi	s8,s1,540
    80004fd4:	a08d                	j	80005036 <pipewrite+0xa8>
      release(&pi->lock);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
      return -1;
    80004fe0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fe2:	854a                	mv	a0,s2
    80004fe4:	70a6                	ld	ra,104(sp)
    80004fe6:	7406                	ld	s0,96(sp)
    80004fe8:	64e6                	ld	s1,88(sp)
    80004fea:	6946                	ld	s2,80(sp)
    80004fec:	69a6                	ld	s3,72(sp)
    80004fee:	6a06                	ld	s4,64(sp)
    80004ff0:	7ae2                	ld	s5,56(sp)
    80004ff2:	7b42                	ld	s6,48(sp)
    80004ff4:	7ba2                	ld	s7,40(sp)
    80004ff6:	7c02                	ld	s8,32(sp)
    80004ff8:	6ce2                	ld	s9,24(sp)
    80004ffa:	6165                	addi	sp,sp,112
    80004ffc:	8082                	ret
      wakeup(&pi->nread);
    80004ffe:	8566                	mv	a0,s9
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	5dc080e7          	jalr	1500(ra) # 800025dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005008:	85de                	mv	a1,s7
    8000500a:	8562                	mv	a0,s8
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	428080e7          	jalr	1064(ra) # 80002434 <sleep>
    80005014:	a839                	j	80005032 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005016:	21c4a783          	lw	a5,540(s1)
    8000501a:	0017871b          	addiw	a4,a5,1
    8000501e:	20e4ae23          	sw	a4,540(s1)
    80005022:	1ff7f793          	andi	a5,a5,511
    80005026:	97a6                	add	a5,a5,s1
    80005028:	f9f44703          	lbu	a4,-97(s0)
    8000502c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005030:	2905                	addiw	s2,s2,1
  while(i < n){
    80005032:	03495d63          	bge	s2,s4,8000506c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005036:	2204a783          	lw	a5,544(s1)
    8000503a:	dfd1                	beqz	a5,80004fd6 <pipewrite+0x48>
    8000503c:	0289a783          	lw	a5,40(s3)
    80005040:	fbd9                	bnez	a5,80004fd6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005042:	2184a783          	lw	a5,536(s1)
    80005046:	21c4a703          	lw	a4,540(s1)
    8000504a:	2007879b          	addiw	a5,a5,512
    8000504e:	faf708e3          	beq	a4,a5,80004ffe <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005052:	4685                	li	a3,1
    80005054:	01590633          	add	a2,s2,s5
    80005058:	f9f40593          	addi	a1,s0,-97
    8000505c:	0509b503          	ld	a0,80(s3)
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	6a6080e7          	jalr	1702(ra) # 80001706 <copyin>
    80005068:	fb6517e3          	bne	a0,s6,80005016 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000506c:	21848513          	addi	a0,s1,536
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	56c080e7          	jalr	1388(ra) # 800025dc <wakeup>
  release(&pi->lock);
    80005078:	8526                	mv	a0,s1
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	c1e080e7          	jalr	-994(ra) # 80000c98 <release>
  return i;
    80005082:	b785                	j	80004fe2 <pipewrite+0x54>
  int i = 0;
    80005084:	4901                	li	s2,0
    80005086:	b7dd                	j	8000506c <pipewrite+0xde>

0000000080005088 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005088:	715d                	addi	sp,sp,-80
    8000508a:	e486                	sd	ra,72(sp)
    8000508c:	e0a2                	sd	s0,64(sp)
    8000508e:	fc26                	sd	s1,56(sp)
    80005090:	f84a                	sd	s2,48(sp)
    80005092:	f44e                	sd	s3,40(sp)
    80005094:	f052                	sd	s4,32(sp)
    80005096:	ec56                	sd	s5,24(sp)
    80005098:	e85a                	sd	s6,16(sp)
    8000509a:	0880                	addi	s0,sp,80
    8000509c:	84aa                	mv	s1,a0
    8000509e:	892e                	mv	s2,a1
    800050a0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050a2:	ffffd097          	auipc	ra,0xffffd
    800050a6:	926080e7          	jalr	-1754(ra) # 800019c8 <myproc>
    800050aa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050ac:	8b26                	mv	s6,s1
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	b34080e7          	jalr	-1228(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050b8:	2184a703          	lw	a4,536(s1)
    800050bc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050c0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050c4:	02f71463          	bne	a4,a5,800050ec <piperead+0x64>
    800050c8:	2244a783          	lw	a5,548(s1)
    800050cc:	c385                	beqz	a5,800050ec <piperead+0x64>
    if(pr->killed){
    800050ce:	028a2783          	lw	a5,40(s4)
    800050d2:	ebc1                	bnez	a5,80005162 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d4:	85da                	mv	a1,s6
    800050d6:	854e                	mv	a0,s3
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	35c080e7          	jalr	860(ra) # 80002434 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050e0:	2184a703          	lw	a4,536(s1)
    800050e4:	21c4a783          	lw	a5,540(s1)
    800050e8:	fef700e3          	beq	a4,a5,800050c8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ec:	09505263          	blez	s5,80005170 <piperead+0xe8>
    800050f0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050f2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050f4:	2184a783          	lw	a5,536(s1)
    800050f8:	21c4a703          	lw	a4,540(s1)
    800050fc:	02f70d63          	beq	a4,a5,80005136 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005100:	0017871b          	addiw	a4,a5,1
    80005104:	20e4ac23          	sw	a4,536(s1)
    80005108:	1ff7f793          	andi	a5,a5,511
    8000510c:	97a6                	add	a5,a5,s1
    8000510e:	0187c783          	lbu	a5,24(a5)
    80005112:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005116:	4685                	li	a3,1
    80005118:	fbf40613          	addi	a2,s0,-65
    8000511c:	85ca                	mv	a1,s2
    8000511e:	050a3503          	ld	a0,80(s4)
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	558080e7          	jalr	1368(ra) # 8000167a <copyout>
    8000512a:	01650663          	beq	a0,s6,80005136 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000512e:	2985                	addiw	s3,s3,1
    80005130:	0905                	addi	s2,s2,1
    80005132:	fd3a91e3          	bne	s5,s3,800050f4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005136:	21c48513          	addi	a0,s1,540
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	4a2080e7          	jalr	1186(ra) # 800025dc <wakeup>
  release(&pi->lock);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	b54080e7          	jalr	-1196(ra) # 80000c98 <release>
  return i;
}
    8000514c:	854e                	mv	a0,s3
    8000514e:	60a6                	ld	ra,72(sp)
    80005150:	6406                	ld	s0,64(sp)
    80005152:	74e2                	ld	s1,56(sp)
    80005154:	7942                	ld	s2,48(sp)
    80005156:	79a2                	ld	s3,40(sp)
    80005158:	7a02                	ld	s4,32(sp)
    8000515a:	6ae2                	ld	s5,24(sp)
    8000515c:	6b42                	ld	s6,16(sp)
    8000515e:	6161                	addi	sp,sp,80
    80005160:	8082                	ret
      release(&pi->lock);
    80005162:	8526                	mv	a0,s1
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	b34080e7          	jalr	-1228(ra) # 80000c98 <release>
      return -1;
    8000516c:	59fd                	li	s3,-1
    8000516e:	bff9                	j	8000514c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005170:	4981                	li	s3,0
    80005172:	b7d1                	j	80005136 <piperead+0xae>

0000000080005174 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005174:	df010113          	addi	sp,sp,-528
    80005178:	20113423          	sd	ra,520(sp)
    8000517c:	20813023          	sd	s0,512(sp)
    80005180:	ffa6                	sd	s1,504(sp)
    80005182:	fbca                	sd	s2,496(sp)
    80005184:	f7ce                	sd	s3,488(sp)
    80005186:	f3d2                	sd	s4,480(sp)
    80005188:	efd6                	sd	s5,472(sp)
    8000518a:	ebda                	sd	s6,464(sp)
    8000518c:	e7de                	sd	s7,456(sp)
    8000518e:	e3e2                	sd	s8,448(sp)
    80005190:	ff66                	sd	s9,440(sp)
    80005192:	fb6a                	sd	s10,432(sp)
    80005194:	f76e                	sd	s11,424(sp)
    80005196:	0c00                	addi	s0,sp,528
    80005198:	84aa                	mv	s1,a0
    8000519a:	dea43c23          	sd	a0,-520(s0)
    8000519e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	826080e7          	jalr	-2010(ra) # 800019c8 <myproc>
    800051aa:	892a                	mv	s2,a0

  begin_op();
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	49c080e7          	jalr	1180(ra) # 80004648 <begin_op>

  if((ip = namei(path)) == 0){
    800051b4:	8526                	mv	a0,s1
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	276080e7          	jalr	630(ra) # 8000442c <namei>
    800051be:	c92d                	beqz	a0,80005230 <exec+0xbc>
    800051c0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	ab4080e7          	jalr	-1356(ra) # 80003c76 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051ca:	04000713          	li	a4,64
    800051ce:	4681                	li	a3,0
    800051d0:	e5040613          	addi	a2,s0,-432
    800051d4:	4581                	li	a1,0
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	d52080e7          	jalr	-686(ra) # 80003f2a <readi>
    800051e0:	04000793          	li	a5,64
    800051e4:	00f51a63          	bne	a0,a5,800051f8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051e8:	e5042703          	lw	a4,-432(s0)
    800051ec:	464c47b7          	lui	a5,0x464c4
    800051f0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051f4:	04f70463          	beq	a4,a5,8000523c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	cde080e7          	jalr	-802(ra) # 80003ed8 <iunlockput>
    end_op();
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	4c6080e7          	jalr	1222(ra) # 800046c8 <end_op>
  }
  return -1;
    8000520a:	557d                	li	a0,-1
}
    8000520c:	20813083          	ld	ra,520(sp)
    80005210:	20013403          	ld	s0,512(sp)
    80005214:	74fe                	ld	s1,504(sp)
    80005216:	795e                	ld	s2,496(sp)
    80005218:	79be                	ld	s3,488(sp)
    8000521a:	7a1e                	ld	s4,480(sp)
    8000521c:	6afe                	ld	s5,472(sp)
    8000521e:	6b5e                	ld	s6,464(sp)
    80005220:	6bbe                	ld	s7,456(sp)
    80005222:	6c1e                	ld	s8,448(sp)
    80005224:	7cfa                	ld	s9,440(sp)
    80005226:	7d5a                	ld	s10,432(sp)
    80005228:	7dba                	ld	s11,424(sp)
    8000522a:	21010113          	addi	sp,sp,528
    8000522e:	8082                	ret
    end_op();
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	498080e7          	jalr	1176(ra) # 800046c8 <end_op>
    return -1;
    80005238:	557d                	li	a0,-1
    8000523a:	bfc9                	j	8000520c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000523c:	854a                	mv	a0,s2
    8000523e:	ffffd097          	auipc	ra,0xffffd
    80005242:	84e080e7          	jalr	-1970(ra) # 80001a8c <proc_pagetable>
    80005246:	8baa                	mv	s7,a0
    80005248:	d945                	beqz	a0,800051f8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000524a:	e7042983          	lw	s3,-400(s0)
    8000524e:	e8845783          	lhu	a5,-376(s0)
    80005252:	c7ad                	beqz	a5,800052bc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005254:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005256:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005258:	6c85                	lui	s9,0x1
    8000525a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000525e:	def43823          	sd	a5,-528(s0)
    80005262:	a42d                	j	8000548c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005264:	00003517          	auipc	a0,0x3
    80005268:	54c50513          	addi	a0,a0,1356 # 800087b0 <syscalls+0x298>
    8000526c:	ffffb097          	auipc	ra,0xffffb
    80005270:	2d2080e7          	jalr	722(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005274:	8756                	mv	a4,s5
    80005276:	012d86bb          	addw	a3,s11,s2
    8000527a:	4581                	li	a1,0
    8000527c:	8526                	mv	a0,s1
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	cac080e7          	jalr	-852(ra) # 80003f2a <readi>
    80005286:	2501                	sext.w	a0,a0
    80005288:	1aaa9963          	bne	s5,a0,8000543a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000528c:	6785                	lui	a5,0x1
    8000528e:	0127893b          	addw	s2,a5,s2
    80005292:	77fd                	lui	a5,0xfffff
    80005294:	01478a3b          	addw	s4,a5,s4
    80005298:	1f897163          	bgeu	s2,s8,8000547a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000529c:	02091593          	slli	a1,s2,0x20
    800052a0:	9181                	srli	a1,a1,0x20
    800052a2:	95ea                	add	a1,a1,s10
    800052a4:	855e                	mv	a0,s7
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	dd0080e7          	jalr	-560(ra) # 80001076 <walkaddr>
    800052ae:	862a                	mv	a2,a0
    if(pa == 0)
    800052b0:	d955                	beqz	a0,80005264 <exec+0xf0>
      n = PGSIZE;
    800052b2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052b4:	fd9a70e3          	bgeu	s4,s9,80005274 <exec+0x100>
      n = sz - i;
    800052b8:	8ad2                	mv	s5,s4
    800052ba:	bf6d                	j	80005274 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052bc:	4901                	li	s2,0
  iunlockput(ip);
    800052be:	8526                	mv	a0,s1
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	c18080e7          	jalr	-1000(ra) # 80003ed8 <iunlockput>
  end_op();
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	400080e7          	jalr	1024(ra) # 800046c8 <end_op>
  p = myproc();
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	6f8080e7          	jalr	1784(ra) # 800019c8 <myproc>
    800052d8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052da:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052de:	6785                	lui	a5,0x1
    800052e0:	17fd                	addi	a5,a5,-1
    800052e2:	993e                	add	s2,s2,a5
    800052e4:	757d                	lui	a0,0xfffff
    800052e6:	00a977b3          	and	a5,s2,a0
    800052ea:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052ee:	6609                	lui	a2,0x2
    800052f0:	963e                	add	a2,a2,a5
    800052f2:	85be                	mv	a1,a5
    800052f4:	855e                	mv	a0,s7
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	134080e7          	jalr	308(ra) # 8000142a <uvmalloc>
    800052fe:	8b2a                	mv	s6,a0
  ip = 0;
    80005300:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005302:	12050c63          	beqz	a0,8000543a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005306:	75f9                	lui	a1,0xffffe
    80005308:	95aa                	add	a1,a1,a0
    8000530a:	855e                	mv	a0,s7
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	33c080e7          	jalr	828(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005314:	7c7d                	lui	s8,0xfffff
    80005316:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005318:	e0043783          	ld	a5,-512(s0)
    8000531c:	6388                	ld	a0,0(a5)
    8000531e:	c535                	beqz	a0,8000538a <exec+0x216>
    80005320:	e9040993          	addi	s3,s0,-368
    80005324:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005328:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000532a:	ffffc097          	auipc	ra,0xffffc
    8000532e:	b3a080e7          	jalr	-1222(ra) # 80000e64 <strlen>
    80005332:	2505                	addiw	a0,a0,1
    80005334:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005338:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000533c:	13896363          	bltu	s2,s8,80005462 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005340:	e0043d83          	ld	s11,-512(s0)
    80005344:	000dba03          	ld	s4,0(s11)
    80005348:	8552                	mv	a0,s4
    8000534a:	ffffc097          	auipc	ra,0xffffc
    8000534e:	b1a080e7          	jalr	-1254(ra) # 80000e64 <strlen>
    80005352:	0015069b          	addiw	a3,a0,1
    80005356:	8652                	mv	a2,s4
    80005358:	85ca                	mv	a1,s2
    8000535a:	855e                	mv	a0,s7
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	31e080e7          	jalr	798(ra) # 8000167a <copyout>
    80005364:	10054363          	bltz	a0,8000546a <exec+0x2f6>
    ustack[argc] = sp;
    80005368:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000536c:	0485                	addi	s1,s1,1
    8000536e:	008d8793          	addi	a5,s11,8
    80005372:	e0f43023          	sd	a5,-512(s0)
    80005376:	008db503          	ld	a0,8(s11)
    8000537a:	c911                	beqz	a0,8000538e <exec+0x21a>
    if(argc >= MAXARG)
    8000537c:	09a1                	addi	s3,s3,8
    8000537e:	fb3c96e3          	bne	s9,s3,8000532a <exec+0x1b6>
  sz = sz1;
    80005382:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005386:	4481                	li	s1,0
    80005388:	a84d                	j	8000543a <exec+0x2c6>
  sp = sz;
    8000538a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000538c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000538e:	00349793          	slli	a5,s1,0x3
    80005392:	f9040713          	addi	a4,s0,-112
    80005396:	97ba                	add	a5,a5,a4
    80005398:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000539c:	00148693          	addi	a3,s1,1
    800053a0:	068e                	slli	a3,a3,0x3
    800053a2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053a6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053aa:	01897663          	bgeu	s2,s8,800053b6 <exec+0x242>
  sz = sz1;
    800053ae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053b2:	4481                	li	s1,0
    800053b4:	a059                	j	8000543a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053b6:	e9040613          	addi	a2,s0,-368
    800053ba:	85ca                	mv	a1,s2
    800053bc:	855e                	mv	a0,s7
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	2bc080e7          	jalr	700(ra) # 8000167a <copyout>
    800053c6:	0a054663          	bltz	a0,80005472 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053ca:	058ab783          	ld	a5,88(s5)
    800053ce:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053d2:	df843783          	ld	a5,-520(s0)
    800053d6:	0007c703          	lbu	a4,0(a5)
    800053da:	cf11                	beqz	a4,800053f6 <exec+0x282>
    800053dc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053de:	02f00693          	li	a3,47
    800053e2:	a039                	j	800053f0 <exec+0x27c>
      last = s+1;
    800053e4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053e8:	0785                	addi	a5,a5,1
    800053ea:	fff7c703          	lbu	a4,-1(a5)
    800053ee:	c701                	beqz	a4,800053f6 <exec+0x282>
    if(*s == '/')
    800053f0:	fed71ce3          	bne	a4,a3,800053e8 <exec+0x274>
    800053f4:	bfc5                	j	800053e4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800053f6:	4641                	li	a2,16
    800053f8:	df843583          	ld	a1,-520(s0)
    800053fc:	158a8513          	addi	a0,s5,344
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	a32080e7          	jalr	-1486(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005408:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000540c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005410:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005414:	058ab783          	ld	a5,88(s5)
    80005418:	e6843703          	ld	a4,-408(s0)
    8000541c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000541e:	058ab783          	ld	a5,88(s5)
    80005422:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005426:	85ea                	mv	a1,s10
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	700080e7          	jalr	1792(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005430:	0004851b          	sext.w	a0,s1
    80005434:	bbe1                	j	8000520c <exec+0x98>
    80005436:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000543a:	e0843583          	ld	a1,-504(s0)
    8000543e:	855e                	mv	a0,s7
    80005440:	ffffc097          	auipc	ra,0xffffc
    80005444:	6e8080e7          	jalr	1768(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    80005448:	da0498e3          	bnez	s1,800051f8 <exec+0x84>
  return -1;
    8000544c:	557d                	li	a0,-1
    8000544e:	bb7d                	j	8000520c <exec+0x98>
    80005450:	e1243423          	sd	s2,-504(s0)
    80005454:	b7dd                	j	8000543a <exec+0x2c6>
    80005456:	e1243423          	sd	s2,-504(s0)
    8000545a:	b7c5                	j	8000543a <exec+0x2c6>
    8000545c:	e1243423          	sd	s2,-504(s0)
    80005460:	bfe9                	j	8000543a <exec+0x2c6>
  sz = sz1;
    80005462:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005466:	4481                	li	s1,0
    80005468:	bfc9                	j	8000543a <exec+0x2c6>
  sz = sz1;
    8000546a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000546e:	4481                	li	s1,0
    80005470:	b7e9                	j	8000543a <exec+0x2c6>
  sz = sz1;
    80005472:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005476:	4481                	li	s1,0
    80005478:	b7c9                	j	8000543a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000547a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000547e:	2b05                	addiw	s6,s6,1
    80005480:	0389899b          	addiw	s3,s3,56
    80005484:	e8845783          	lhu	a5,-376(s0)
    80005488:	e2fb5be3          	bge	s6,a5,800052be <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000548c:	2981                	sext.w	s3,s3
    8000548e:	03800713          	li	a4,56
    80005492:	86ce                	mv	a3,s3
    80005494:	e1840613          	addi	a2,s0,-488
    80005498:	4581                	li	a1,0
    8000549a:	8526                	mv	a0,s1
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	a8e080e7          	jalr	-1394(ra) # 80003f2a <readi>
    800054a4:	03800793          	li	a5,56
    800054a8:	f8f517e3          	bne	a0,a5,80005436 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054ac:	e1842783          	lw	a5,-488(s0)
    800054b0:	4705                	li	a4,1
    800054b2:	fce796e3          	bne	a5,a4,8000547e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054b6:	e4043603          	ld	a2,-448(s0)
    800054ba:	e3843783          	ld	a5,-456(s0)
    800054be:	f8f669e3          	bltu	a2,a5,80005450 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054c2:	e2843783          	ld	a5,-472(s0)
    800054c6:	963e                	add	a2,a2,a5
    800054c8:	f8f667e3          	bltu	a2,a5,80005456 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054cc:	85ca                	mv	a1,s2
    800054ce:	855e                	mv	a0,s7
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	f5a080e7          	jalr	-166(ra) # 8000142a <uvmalloc>
    800054d8:	e0a43423          	sd	a0,-504(s0)
    800054dc:	d141                	beqz	a0,8000545c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800054de:	e2843d03          	ld	s10,-472(s0)
    800054e2:	df043783          	ld	a5,-528(s0)
    800054e6:	00fd77b3          	and	a5,s10,a5
    800054ea:	fba1                	bnez	a5,8000543a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054ec:	e2042d83          	lw	s11,-480(s0)
    800054f0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054f4:	f80c03e3          	beqz	s8,8000547a <exec+0x306>
    800054f8:	8a62                	mv	s4,s8
    800054fa:	4901                	li	s2,0
    800054fc:	b345                	j	8000529c <exec+0x128>

00000000800054fe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054fe:	7179                	addi	sp,sp,-48
    80005500:	f406                	sd	ra,40(sp)
    80005502:	f022                	sd	s0,32(sp)
    80005504:	ec26                	sd	s1,24(sp)
    80005506:	e84a                	sd	s2,16(sp)
    80005508:	1800                	addi	s0,sp,48
    8000550a:	892e                	mv	s2,a1
    8000550c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000550e:	fdc40593          	addi	a1,s0,-36
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	b8e080e7          	jalr	-1138(ra) # 800030a0 <argint>
    8000551a:	04054063          	bltz	a0,8000555a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000551e:	fdc42703          	lw	a4,-36(s0)
    80005522:	47bd                	li	a5,15
    80005524:	02e7ed63          	bltu	a5,a4,8000555e <argfd+0x60>
    80005528:	ffffc097          	auipc	ra,0xffffc
    8000552c:	4a0080e7          	jalr	1184(ra) # 800019c8 <myproc>
    80005530:	fdc42703          	lw	a4,-36(s0)
    80005534:	01a70793          	addi	a5,a4,26
    80005538:	078e                	slli	a5,a5,0x3
    8000553a:	953e                	add	a0,a0,a5
    8000553c:	611c                	ld	a5,0(a0)
    8000553e:	c395                	beqz	a5,80005562 <argfd+0x64>
    return -1;
  if(pfd)
    80005540:	00090463          	beqz	s2,80005548 <argfd+0x4a>
    *pfd = fd;
    80005544:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005548:	4501                	li	a0,0
  if(pf)
    8000554a:	c091                	beqz	s1,8000554e <argfd+0x50>
    *pf = f;
    8000554c:	e09c                	sd	a5,0(s1)
}
    8000554e:	70a2                	ld	ra,40(sp)
    80005550:	7402                	ld	s0,32(sp)
    80005552:	64e2                	ld	s1,24(sp)
    80005554:	6942                	ld	s2,16(sp)
    80005556:	6145                	addi	sp,sp,48
    80005558:	8082                	ret
    return -1;
    8000555a:	557d                	li	a0,-1
    8000555c:	bfcd                	j	8000554e <argfd+0x50>
    return -1;
    8000555e:	557d                	li	a0,-1
    80005560:	b7fd                	j	8000554e <argfd+0x50>
    80005562:	557d                	li	a0,-1
    80005564:	b7ed                	j	8000554e <argfd+0x50>

0000000080005566 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005566:	1101                	addi	sp,sp,-32
    80005568:	ec06                	sd	ra,24(sp)
    8000556a:	e822                	sd	s0,16(sp)
    8000556c:	e426                	sd	s1,8(sp)
    8000556e:	1000                	addi	s0,sp,32
    80005570:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005572:	ffffc097          	auipc	ra,0xffffc
    80005576:	456080e7          	jalr	1110(ra) # 800019c8 <myproc>
    8000557a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000557c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    80005580:	4501                	li	a0,0
    80005582:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005584:	6398                	ld	a4,0(a5)
    80005586:	cb19                	beqz	a4,8000559c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005588:	2505                	addiw	a0,a0,1
    8000558a:	07a1                	addi	a5,a5,8
    8000558c:	fed51ce3          	bne	a0,a3,80005584 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005590:	557d                	li	a0,-1
}
    80005592:	60e2                	ld	ra,24(sp)
    80005594:	6442                	ld	s0,16(sp)
    80005596:	64a2                	ld	s1,8(sp)
    80005598:	6105                	addi	sp,sp,32
    8000559a:	8082                	ret
      p->ofile[fd] = f;
    8000559c:	01a50793          	addi	a5,a0,26
    800055a0:	078e                	slli	a5,a5,0x3
    800055a2:	963e                	add	a2,a2,a5
    800055a4:	e204                	sd	s1,0(a2)
      return fd;
    800055a6:	b7f5                	j	80005592 <fdalloc+0x2c>

00000000800055a8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055a8:	715d                	addi	sp,sp,-80
    800055aa:	e486                	sd	ra,72(sp)
    800055ac:	e0a2                	sd	s0,64(sp)
    800055ae:	fc26                	sd	s1,56(sp)
    800055b0:	f84a                	sd	s2,48(sp)
    800055b2:	f44e                	sd	s3,40(sp)
    800055b4:	f052                	sd	s4,32(sp)
    800055b6:	ec56                	sd	s5,24(sp)
    800055b8:	0880                	addi	s0,sp,80
    800055ba:	89ae                	mv	s3,a1
    800055bc:	8ab2                	mv	s5,a2
    800055be:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055c0:	fb040593          	addi	a1,s0,-80
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	e86080e7          	jalr	-378(ra) # 8000444a <nameiparent>
    800055cc:	892a                	mv	s2,a0
    800055ce:	12050f63          	beqz	a0,8000570c <create+0x164>
    return 0;

  ilock(dp);
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	6a4080e7          	jalr	1700(ra) # 80003c76 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055da:	4601                	li	a2,0
    800055dc:	fb040593          	addi	a1,s0,-80
    800055e0:	854a                	mv	a0,s2
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	b78080e7          	jalr	-1160(ra) # 8000415a <dirlookup>
    800055ea:	84aa                	mv	s1,a0
    800055ec:	c921                	beqz	a0,8000563c <create+0x94>
    iunlockput(dp);
    800055ee:	854a                	mv	a0,s2
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	8e8080e7          	jalr	-1816(ra) # 80003ed8 <iunlockput>
    ilock(ip);
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	67c080e7          	jalr	1660(ra) # 80003c76 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005602:	2981                	sext.w	s3,s3
    80005604:	4789                	li	a5,2
    80005606:	02f99463          	bne	s3,a5,8000562e <create+0x86>
    8000560a:	0444d783          	lhu	a5,68(s1)
    8000560e:	37f9                	addiw	a5,a5,-2
    80005610:	17c2                	slli	a5,a5,0x30
    80005612:	93c1                	srli	a5,a5,0x30
    80005614:	4705                	li	a4,1
    80005616:	00f76c63          	bltu	a4,a5,8000562e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000561a:	8526                	mv	a0,s1
    8000561c:	60a6                	ld	ra,72(sp)
    8000561e:	6406                	ld	s0,64(sp)
    80005620:	74e2                	ld	s1,56(sp)
    80005622:	7942                	ld	s2,48(sp)
    80005624:	79a2                	ld	s3,40(sp)
    80005626:	7a02                	ld	s4,32(sp)
    80005628:	6ae2                	ld	s5,24(sp)
    8000562a:	6161                	addi	sp,sp,80
    8000562c:	8082                	ret
    iunlockput(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	8a8080e7          	jalr	-1880(ra) # 80003ed8 <iunlockput>
    return 0;
    80005638:	4481                	li	s1,0
    8000563a:	b7c5                	j	8000561a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000563c:	85ce                	mv	a1,s3
    8000563e:	00092503          	lw	a0,0(s2)
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	49c080e7          	jalr	1180(ra) # 80003ade <ialloc>
    8000564a:	84aa                	mv	s1,a0
    8000564c:	c529                	beqz	a0,80005696 <create+0xee>
  ilock(ip);
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	628080e7          	jalr	1576(ra) # 80003c76 <ilock>
  ip->major = major;
    80005656:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000565a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000565e:	4785                	li	a5,1
    80005660:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	546080e7          	jalr	1350(ra) # 80003bac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000566e:	2981                	sext.w	s3,s3
    80005670:	4785                	li	a5,1
    80005672:	02f98a63          	beq	s3,a5,800056a6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005676:	40d0                	lw	a2,4(s1)
    80005678:	fb040593          	addi	a1,s0,-80
    8000567c:	854a                	mv	a0,s2
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	cec080e7          	jalr	-788(ra) # 8000436a <dirlink>
    80005686:	06054b63          	bltz	a0,800056fc <create+0x154>
  iunlockput(dp);
    8000568a:	854a                	mv	a0,s2
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	84c080e7          	jalr	-1972(ra) # 80003ed8 <iunlockput>
  return ip;
    80005694:	b759                	j	8000561a <create+0x72>
    panic("create: ialloc");
    80005696:	00003517          	auipc	a0,0x3
    8000569a:	13a50513          	addi	a0,a0,314 # 800087d0 <syscalls+0x2b8>
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056a6:	04a95783          	lhu	a5,74(s2)
    800056aa:	2785                	addiw	a5,a5,1
    800056ac:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056b0:	854a                	mv	a0,s2
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	4fa080e7          	jalr	1274(ra) # 80003bac <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056ba:	40d0                	lw	a2,4(s1)
    800056bc:	00003597          	auipc	a1,0x3
    800056c0:	12458593          	addi	a1,a1,292 # 800087e0 <syscalls+0x2c8>
    800056c4:	8526                	mv	a0,s1
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	ca4080e7          	jalr	-860(ra) # 8000436a <dirlink>
    800056ce:	00054f63          	bltz	a0,800056ec <create+0x144>
    800056d2:	00492603          	lw	a2,4(s2)
    800056d6:	00003597          	auipc	a1,0x3
    800056da:	11258593          	addi	a1,a1,274 # 800087e8 <syscalls+0x2d0>
    800056de:	8526                	mv	a0,s1
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	c8a080e7          	jalr	-886(ra) # 8000436a <dirlink>
    800056e8:	f80557e3          	bgez	a0,80005676 <create+0xce>
      panic("create dots");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	10450513          	addi	a0,a0,260 # 800087f0 <syscalls+0x2d8>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e4a080e7          	jalr	-438(ra) # 8000053e <panic>
    panic("create: dirlink");
    800056fc:	00003517          	auipc	a0,0x3
    80005700:	10450513          	addi	a0,a0,260 # 80008800 <syscalls+0x2e8>
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>
    return 0;
    8000570c:	84aa                	mv	s1,a0
    8000570e:	b731                	j	8000561a <create+0x72>

0000000080005710 <sys_dup>:
{
    80005710:	7179                	addi	sp,sp,-48
    80005712:	f406                	sd	ra,40(sp)
    80005714:	f022                	sd	s0,32(sp)
    80005716:	ec26                	sd	s1,24(sp)
    80005718:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000571a:	fd840613          	addi	a2,s0,-40
    8000571e:	4581                	li	a1,0
    80005720:	4501                	li	a0,0
    80005722:	00000097          	auipc	ra,0x0
    80005726:	ddc080e7          	jalr	-548(ra) # 800054fe <argfd>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000572c:	02054363          	bltz	a0,80005752 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005730:	fd843503          	ld	a0,-40(s0)
    80005734:	00000097          	auipc	ra,0x0
    80005738:	e32080e7          	jalr	-462(ra) # 80005566 <fdalloc>
    8000573c:	84aa                	mv	s1,a0
    return -1;
    8000573e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005740:	00054963          	bltz	a0,80005752 <sys_dup+0x42>
  filedup(f);
    80005744:	fd843503          	ld	a0,-40(s0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	37a080e7          	jalr	890(ra) # 80004ac2 <filedup>
  return fd;
    80005750:	87a6                	mv	a5,s1
}
    80005752:	853e                	mv	a0,a5
    80005754:	70a2                	ld	ra,40(sp)
    80005756:	7402                	ld	s0,32(sp)
    80005758:	64e2                	ld	s1,24(sp)
    8000575a:	6145                	addi	sp,sp,48
    8000575c:	8082                	ret

000000008000575e <sys_read>:
{
    8000575e:	7179                	addi	sp,sp,-48
    80005760:	f406                	sd	ra,40(sp)
    80005762:	f022                	sd	s0,32(sp)
    80005764:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005766:	fe840613          	addi	a2,s0,-24
    8000576a:	4581                	li	a1,0
    8000576c:	4501                	li	a0,0
    8000576e:	00000097          	auipc	ra,0x0
    80005772:	d90080e7          	jalr	-624(ra) # 800054fe <argfd>
    return -1;
    80005776:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005778:	04054163          	bltz	a0,800057ba <sys_read+0x5c>
    8000577c:	fe440593          	addi	a1,s0,-28
    80005780:	4509                	li	a0,2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	91e080e7          	jalr	-1762(ra) # 800030a0 <argint>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578c:	02054763          	bltz	a0,800057ba <sys_read+0x5c>
    80005790:	fd840593          	addi	a1,s0,-40
    80005794:	4505                	li	a0,1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	92c080e7          	jalr	-1748(ra) # 800030c2 <argaddr>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a0:	00054d63          	bltz	a0,800057ba <sys_read+0x5c>
  return fileread(f, p, n);
    800057a4:	fe442603          	lw	a2,-28(s0)
    800057a8:	fd843583          	ld	a1,-40(s0)
    800057ac:	fe843503          	ld	a0,-24(s0)
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	49e080e7          	jalr	1182(ra) # 80004c4e <fileread>
    800057b8:	87aa                	mv	a5,a0
}
    800057ba:	853e                	mv	a0,a5
    800057bc:	70a2                	ld	ra,40(sp)
    800057be:	7402                	ld	s0,32(sp)
    800057c0:	6145                	addi	sp,sp,48
    800057c2:	8082                	ret

00000000800057c4 <sys_write>:
{
    800057c4:	7179                	addi	sp,sp,-48
    800057c6:	f406                	sd	ra,40(sp)
    800057c8:	f022                	sd	s0,32(sp)
    800057ca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057cc:	fe840613          	addi	a2,s0,-24
    800057d0:	4581                	li	a1,0
    800057d2:	4501                	li	a0,0
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	d2a080e7          	jalr	-726(ra) # 800054fe <argfd>
    return -1;
    800057dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057de:	04054163          	bltz	a0,80005820 <sys_write+0x5c>
    800057e2:	fe440593          	addi	a1,s0,-28
    800057e6:	4509                	li	a0,2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	8b8080e7          	jalr	-1864(ra) # 800030a0 <argint>
    return -1;
    800057f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f2:	02054763          	bltz	a0,80005820 <sys_write+0x5c>
    800057f6:	fd840593          	addi	a1,s0,-40
    800057fa:	4505                	li	a0,1
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	8c6080e7          	jalr	-1850(ra) # 800030c2 <argaddr>
    return -1;
    80005804:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005806:	00054d63          	bltz	a0,80005820 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000580a:	fe442603          	lw	a2,-28(s0)
    8000580e:	fd843583          	ld	a1,-40(s0)
    80005812:	fe843503          	ld	a0,-24(s0)
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	4fa080e7          	jalr	1274(ra) # 80004d10 <filewrite>
    8000581e:	87aa                	mv	a5,a0
}
    80005820:	853e                	mv	a0,a5
    80005822:	70a2                	ld	ra,40(sp)
    80005824:	7402                	ld	s0,32(sp)
    80005826:	6145                	addi	sp,sp,48
    80005828:	8082                	ret

000000008000582a <sys_close>:
{
    8000582a:	1101                	addi	sp,sp,-32
    8000582c:	ec06                	sd	ra,24(sp)
    8000582e:	e822                	sd	s0,16(sp)
    80005830:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005832:	fe040613          	addi	a2,s0,-32
    80005836:	fec40593          	addi	a1,s0,-20
    8000583a:	4501                	li	a0,0
    8000583c:	00000097          	auipc	ra,0x0
    80005840:	cc2080e7          	jalr	-830(ra) # 800054fe <argfd>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005846:	02054463          	bltz	a0,8000586e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000584a:	ffffc097          	auipc	ra,0xffffc
    8000584e:	17e080e7          	jalr	382(ra) # 800019c8 <myproc>
    80005852:	fec42783          	lw	a5,-20(s0)
    80005856:	07e9                	addi	a5,a5,26
    80005858:	078e                	slli	a5,a5,0x3
    8000585a:	97aa                	add	a5,a5,a0
    8000585c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005860:	fe043503          	ld	a0,-32(s0)
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	2b0080e7          	jalr	688(ra) # 80004b14 <fileclose>
  return 0;
    8000586c:	4781                	li	a5,0
}
    8000586e:	853e                	mv	a0,a5
    80005870:	60e2                	ld	ra,24(sp)
    80005872:	6442                	ld	s0,16(sp)
    80005874:	6105                	addi	sp,sp,32
    80005876:	8082                	ret

0000000080005878 <sys_fstat>:
{
    80005878:	1101                	addi	sp,sp,-32
    8000587a:	ec06                	sd	ra,24(sp)
    8000587c:	e822                	sd	s0,16(sp)
    8000587e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005880:	fe840613          	addi	a2,s0,-24
    80005884:	4581                	li	a1,0
    80005886:	4501                	li	a0,0
    80005888:	00000097          	auipc	ra,0x0
    8000588c:	c76080e7          	jalr	-906(ra) # 800054fe <argfd>
    return -1;
    80005890:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005892:	02054563          	bltz	a0,800058bc <sys_fstat+0x44>
    80005896:	fe040593          	addi	a1,s0,-32
    8000589a:	4505                	li	a0,1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	826080e7          	jalr	-2010(ra) # 800030c2 <argaddr>
    return -1;
    800058a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058a6:	00054b63          	bltz	a0,800058bc <sys_fstat+0x44>
  return filestat(f, st);
    800058aa:	fe043583          	ld	a1,-32(s0)
    800058ae:	fe843503          	ld	a0,-24(s0)
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	32a080e7          	jalr	810(ra) # 80004bdc <filestat>
    800058ba:	87aa                	mv	a5,a0
}
    800058bc:	853e                	mv	a0,a5
    800058be:	60e2                	ld	ra,24(sp)
    800058c0:	6442                	ld	s0,16(sp)
    800058c2:	6105                	addi	sp,sp,32
    800058c4:	8082                	ret

00000000800058c6 <sys_link>:
{
    800058c6:	7169                	addi	sp,sp,-304
    800058c8:	f606                	sd	ra,296(sp)
    800058ca:	f222                	sd	s0,288(sp)
    800058cc:	ee26                	sd	s1,280(sp)
    800058ce:	ea4a                	sd	s2,272(sp)
    800058d0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d2:	08000613          	li	a2,128
    800058d6:	ed040593          	addi	a1,s0,-304
    800058da:	4501                	li	a0,0
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	808080e7          	jalr	-2040(ra) # 800030e4 <argstr>
    return -1;
    800058e4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e6:	10054e63          	bltz	a0,80005a02 <sys_link+0x13c>
    800058ea:	08000613          	li	a2,128
    800058ee:	f5040593          	addi	a1,s0,-176
    800058f2:	4505                	li	a0,1
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	7f0080e7          	jalr	2032(ra) # 800030e4 <argstr>
    return -1;
    800058fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fe:	10054263          	bltz	a0,80005a02 <sys_link+0x13c>
  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	d46080e7          	jalr	-698(ra) # 80004648 <begin_op>
  if((ip = namei(old)) == 0){
    8000590a:	ed040513          	addi	a0,s0,-304
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	b1e080e7          	jalr	-1250(ra) # 8000442c <namei>
    80005916:	84aa                	mv	s1,a0
    80005918:	c551                	beqz	a0,800059a4 <sys_link+0xde>
  ilock(ip);
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	35c080e7          	jalr	860(ra) # 80003c76 <ilock>
  if(ip->type == T_DIR){
    80005922:	04449703          	lh	a4,68(s1)
    80005926:	4785                	li	a5,1
    80005928:	08f70463          	beq	a4,a5,800059b0 <sys_link+0xea>
  ip->nlink++;
    8000592c:	04a4d783          	lhu	a5,74(s1)
    80005930:	2785                	addiw	a5,a5,1
    80005932:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005936:	8526                	mv	a0,s1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	274080e7          	jalr	628(ra) # 80003bac <iupdate>
  iunlock(ip);
    80005940:	8526                	mv	a0,s1
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	3f6080e7          	jalr	1014(ra) # 80003d38 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000594a:	fd040593          	addi	a1,s0,-48
    8000594e:	f5040513          	addi	a0,s0,-176
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	af8080e7          	jalr	-1288(ra) # 8000444a <nameiparent>
    8000595a:	892a                	mv	s2,a0
    8000595c:	c935                	beqz	a0,800059d0 <sys_link+0x10a>
  ilock(dp);
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	318080e7          	jalr	792(ra) # 80003c76 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005966:	00092703          	lw	a4,0(s2)
    8000596a:	409c                	lw	a5,0(s1)
    8000596c:	04f71d63          	bne	a4,a5,800059c6 <sys_link+0x100>
    80005970:	40d0                	lw	a2,4(s1)
    80005972:	fd040593          	addi	a1,s0,-48
    80005976:	854a                	mv	a0,s2
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	9f2080e7          	jalr	-1550(ra) # 8000436a <dirlink>
    80005980:	04054363          	bltz	a0,800059c6 <sys_link+0x100>
  iunlockput(dp);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	552080e7          	jalr	1362(ra) # 80003ed8 <iunlockput>
  iput(ip);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	4a0080e7          	jalr	1184(ra) # 80003e30 <iput>
  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	d30080e7          	jalr	-720(ra) # 800046c8 <end_op>
  return 0;
    800059a0:	4781                	li	a5,0
    800059a2:	a085                	j	80005a02 <sys_link+0x13c>
    end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	d24080e7          	jalr	-732(ra) # 800046c8 <end_op>
    return -1;
    800059ac:	57fd                	li	a5,-1
    800059ae:	a891                	j	80005a02 <sys_link+0x13c>
    iunlockput(ip);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	526080e7          	jalr	1318(ra) # 80003ed8 <iunlockput>
    end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	d0e080e7          	jalr	-754(ra) # 800046c8 <end_op>
    return -1;
    800059c2:	57fd                	li	a5,-1
    800059c4:	a83d                	j	80005a02 <sys_link+0x13c>
    iunlockput(dp);
    800059c6:	854a                	mv	a0,s2
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	510080e7          	jalr	1296(ra) # 80003ed8 <iunlockput>
  ilock(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	2a4080e7          	jalr	676(ra) # 80003c76 <ilock>
  ip->nlink--;
    800059da:	04a4d783          	lhu	a5,74(s1)
    800059de:	37fd                	addiw	a5,a5,-1
    800059e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	1c6080e7          	jalr	454(ra) # 80003bac <iupdate>
  iunlockput(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	4e8080e7          	jalr	1256(ra) # 80003ed8 <iunlockput>
  end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	cd0080e7          	jalr	-816(ra) # 800046c8 <end_op>
  return -1;
    80005a00:	57fd                	li	a5,-1
}
    80005a02:	853e                	mv	a0,a5
    80005a04:	70b2                	ld	ra,296(sp)
    80005a06:	7412                	ld	s0,288(sp)
    80005a08:	64f2                	ld	s1,280(sp)
    80005a0a:	6952                	ld	s2,272(sp)
    80005a0c:	6155                	addi	sp,sp,304
    80005a0e:	8082                	ret

0000000080005a10 <sys_unlink>:
{
    80005a10:	7151                	addi	sp,sp,-240
    80005a12:	f586                	sd	ra,232(sp)
    80005a14:	f1a2                	sd	s0,224(sp)
    80005a16:	eda6                	sd	s1,216(sp)
    80005a18:	e9ca                	sd	s2,208(sp)
    80005a1a:	e5ce                	sd	s3,200(sp)
    80005a1c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a1e:	08000613          	li	a2,128
    80005a22:	f3040593          	addi	a1,s0,-208
    80005a26:	4501                	li	a0,0
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	6bc080e7          	jalr	1724(ra) # 800030e4 <argstr>
    80005a30:	18054163          	bltz	a0,80005bb2 <sys_unlink+0x1a2>
  begin_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	c14080e7          	jalr	-1004(ra) # 80004648 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a3c:	fb040593          	addi	a1,s0,-80
    80005a40:	f3040513          	addi	a0,s0,-208
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	a06080e7          	jalr	-1530(ra) # 8000444a <nameiparent>
    80005a4c:	84aa                	mv	s1,a0
    80005a4e:	c979                	beqz	a0,80005b24 <sys_unlink+0x114>
  ilock(dp);
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	226080e7          	jalr	550(ra) # 80003c76 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a58:	00003597          	auipc	a1,0x3
    80005a5c:	d8858593          	addi	a1,a1,-632 # 800087e0 <syscalls+0x2c8>
    80005a60:	fb040513          	addi	a0,s0,-80
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	6dc080e7          	jalr	1756(ra) # 80004140 <namecmp>
    80005a6c:	14050a63          	beqz	a0,80005bc0 <sys_unlink+0x1b0>
    80005a70:	00003597          	auipc	a1,0x3
    80005a74:	d7858593          	addi	a1,a1,-648 # 800087e8 <syscalls+0x2d0>
    80005a78:	fb040513          	addi	a0,s0,-80
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	6c4080e7          	jalr	1732(ra) # 80004140 <namecmp>
    80005a84:	12050e63          	beqz	a0,80005bc0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a88:	f2c40613          	addi	a2,s0,-212
    80005a8c:	fb040593          	addi	a1,s0,-80
    80005a90:	8526                	mv	a0,s1
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	6c8080e7          	jalr	1736(ra) # 8000415a <dirlookup>
    80005a9a:	892a                	mv	s2,a0
    80005a9c:	12050263          	beqz	a0,80005bc0 <sys_unlink+0x1b0>
  ilock(ip);
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	1d6080e7          	jalr	470(ra) # 80003c76 <ilock>
  if(ip->nlink < 1)
    80005aa8:	04a91783          	lh	a5,74(s2)
    80005aac:	08f05263          	blez	a5,80005b30 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ab0:	04491703          	lh	a4,68(s2)
    80005ab4:	4785                	li	a5,1
    80005ab6:	08f70563          	beq	a4,a5,80005b40 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005aba:	4641                	li	a2,16
    80005abc:	4581                	li	a1,0
    80005abe:	fc040513          	addi	a0,s0,-64
    80005ac2:	ffffb097          	auipc	ra,0xffffb
    80005ac6:	21e080e7          	jalr	542(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aca:	4741                	li	a4,16
    80005acc:	f2c42683          	lw	a3,-212(s0)
    80005ad0:	fc040613          	addi	a2,s0,-64
    80005ad4:	4581                	li	a1,0
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	54a080e7          	jalr	1354(ra) # 80004022 <writei>
    80005ae0:	47c1                	li	a5,16
    80005ae2:	0af51563          	bne	a0,a5,80005b8c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ae6:	04491703          	lh	a4,68(s2)
    80005aea:	4785                	li	a5,1
    80005aec:	0af70863          	beq	a4,a5,80005b9c <sys_unlink+0x18c>
  iunlockput(dp);
    80005af0:	8526                	mv	a0,s1
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	3e6080e7          	jalr	998(ra) # 80003ed8 <iunlockput>
  ip->nlink--;
    80005afa:	04a95783          	lhu	a5,74(s2)
    80005afe:	37fd                	addiw	a5,a5,-1
    80005b00:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b04:	854a                	mv	a0,s2
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	0a6080e7          	jalr	166(ra) # 80003bac <iupdate>
  iunlockput(ip);
    80005b0e:	854a                	mv	a0,s2
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	3c8080e7          	jalr	968(ra) # 80003ed8 <iunlockput>
  end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	bb0080e7          	jalr	-1104(ra) # 800046c8 <end_op>
  return 0;
    80005b20:	4501                	li	a0,0
    80005b22:	a84d                	j	80005bd4 <sys_unlink+0x1c4>
    end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	ba4080e7          	jalr	-1116(ra) # 800046c8 <end_op>
    return -1;
    80005b2c:	557d                	li	a0,-1
    80005b2e:	a05d                	j	80005bd4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b30:	00003517          	auipc	a0,0x3
    80005b34:	ce050513          	addi	a0,a0,-800 # 80008810 <syscalls+0x2f8>
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	a06080e7          	jalr	-1530(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b40:	04c92703          	lw	a4,76(s2)
    80005b44:	02000793          	li	a5,32
    80005b48:	f6e7f9e3          	bgeu	a5,a4,80005aba <sys_unlink+0xaa>
    80005b4c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b50:	4741                	li	a4,16
    80005b52:	86ce                	mv	a3,s3
    80005b54:	f1840613          	addi	a2,s0,-232
    80005b58:	4581                	li	a1,0
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	3ce080e7          	jalr	974(ra) # 80003f2a <readi>
    80005b64:	47c1                	li	a5,16
    80005b66:	00f51b63          	bne	a0,a5,80005b7c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b6a:	f1845783          	lhu	a5,-232(s0)
    80005b6e:	e7a1                	bnez	a5,80005bb6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b70:	29c1                	addiw	s3,s3,16
    80005b72:	04c92783          	lw	a5,76(s2)
    80005b76:	fcf9ede3          	bltu	s3,a5,80005b50 <sys_unlink+0x140>
    80005b7a:	b781                	j	80005aba <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b7c:	00003517          	auipc	a0,0x3
    80005b80:	cac50513          	addi	a0,a0,-852 # 80008828 <syscalls+0x310>
    80005b84:	ffffb097          	auipc	ra,0xffffb
    80005b88:	9ba080e7          	jalr	-1606(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b8c:	00003517          	auipc	a0,0x3
    80005b90:	cb450513          	addi	a0,a0,-844 # 80008840 <syscalls+0x328>
    80005b94:	ffffb097          	auipc	ra,0xffffb
    80005b98:	9aa080e7          	jalr	-1622(ra) # 8000053e <panic>
    dp->nlink--;
    80005b9c:	04a4d783          	lhu	a5,74(s1)
    80005ba0:	37fd                	addiw	a5,a5,-1
    80005ba2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	004080e7          	jalr	4(ra) # 80003bac <iupdate>
    80005bb0:	b781                	j	80005af0 <sys_unlink+0xe0>
    return -1;
    80005bb2:	557d                	li	a0,-1
    80005bb4:	a005                	j	80005bd4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bb6:	854a                	mv	a0,s2
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	320080e7          	jalr	800(ra) # 80003ed8 <iunlockput>
  iunlockput(dp);
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	316080e7          	jalr	790(ra) # 80003ed8 <iunlockput>
  end_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	afe080e7          	jalr	-1282(ra) # 800046c8 <end_op>
  return -1;
    80005bd2:	557d                	li	a0,-1
}
    80005bd4:	70ae                	ld	ra,232(sp)
    80005bd6:	740e                	ld	s0,224(sp)
    80005bd8:	64ee                	ld	s1,216(sp)
    80005bda:	694e                	ld	s2,208(sp)
    80005bdc:	69ae                	ld	s3,200(sp)
    80005bde:	616d                	addi	sp,sp,240
    80005be0:	8082                	ret

0000000080005be2 <sys_open>:

uint64
sys_open(void)
{
    80005be2:	7131                	addi	sp,sp,-192
    80005be4:	fd06                	sd	ra,184(sp)
    80005be6:	f922                	sd	s0,176(sp)
    80005be8:	f526                	sd	s1,168(sp)
    80005bea:	f14a                	sd	s2,160(sp)
    80005bec:	ed4e                	sd	s3,152(sp)
    80005bee:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bf0:	08000613          	li	a2,128
    80005bf4:	f5040593          	addi	a1,s0,-176
    80005bf8:	4501                	li	a0,0
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	4ea080e7          	jalr	1258(ra) # 800030e4 <argstr>
    return -1;
    80005c02:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c04:	0c054163          	bltz	a0,80005cc6 <sys_open+0xe4>
    80005c08:	f4c40593          	addi	a1,s0,-180
    80005c0c:	4505                	li	a0,1
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	492080e7          	jalr	1170(ra) # 800030a0 <argint>
    80005c16:	0a054863          	bltz	a0,80005cc6 <sys_open+0xe4>

  begin_op();
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	a2e080e7          	jalr	-1490(ra) # 80004648 <begin_op>

  if(omode & O_CREATE){
    80005c22:	f4c42783          	lw	a5,-180(s0)
    80005c26:	2007f793          	andi	a5,a5,512
    80005c2a:	cbdd                	beqz	a5,80005ce0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c2c:	4681                	li	a3,0
    80005c2e:	4601                	li	a2,0
    80005c30:	4589                	li	a1,2
    80005c32:	f5040513          	addi	a0,s0,-176
    80005c36:	00000097          	auipc	ra,0x0
    80005c3a:	972080e7          	jalr	-1678(ra) # 800055a8 <create>
    80005c3e:	892a                	mv	s2,a0
    if(ip == 0){
    80005c40:	c959                	beqz	a0,80005cd6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c42:	04491703          	lh	a4,68(s2)
    80005c46:	478d                	li	a5,3
    80005c48:	00f71763          	bne	a4,a5,80005c56 <sys_open+0x74>
    80005c4c:	04695703          	lhu	a4,70(s2)
    80005c50:	47a5                	li	a5,9
    80005c52:	0ce7ec63          	bltu	a5,a4,80005d2a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	e02080e7          	jalr	-510(ra) # 80004a58 <filealloc>
    80005c5e:	89aa                	mv	s3,a0
    80005c60:	10050263          	beqz	a0,80005d64 <sys_open+0x182>
    80005c64:	00000097          	auipc	ra,0x0
    80005c68:	902080e7          	jalr	-1790(ra) # 80005566 <fdalloc>
    80005c6c:	84aa                	mv	s1,a0
    80005c6e:	0e054663          	bltz	a0,80005d5a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c72:	04491703          	lh	a4,68(s2)
    80005c76:	478d                	li	a5,3
    80005c78:	0cf70463          	beq	a4,a5,80005d40 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c7c:	4789                	li	a5,2
    80005c7e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c82:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c86:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c8a:	f4c42783          	lw	a5,-180(s0)
    80005c8e:	0017c713          	xori	a4,a5,1
    80005c92:	8b05                	andi	a4,a4,1
    80005c94:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c98:	0037f713          	andi	a4,a5,3
    80005c9c:	00e03733          	snez	a4,a4
    80005ca0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ca4:	4007f793          	andi	a5,a5,1024
    80005ca8:	c791                	beqz	a5,80005cb4 <sys_open+0xd2>
    80005caa:	04491703          	lh	a4,68(s2)
    80005cae:	4789                	li	a5,2
    80005cb0:	08f70f63          	beq	a4,a5,80005d4e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	082080e7          	jalr	130(ra) # 80003d38 <iunlock>
  end_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	a0a080e7          	jalr	-1526(ra) # 800046c8 <end_op>

  return fd;
}
    80005cc6:	8526                	mv	a0,s1
    80005cc8:	70ea                	ld	ra,184(sp)
    80005cca:	744a                	ld	s0,176(sp)
    80005ccc:	74aa                	ld	s1,168(sp)
    80005cce:	790a                	ld	s2,160(sp)
    80005cd0:	69ea                	ld	s3,152(sp)
    80005cd2:	6129                	addi	sp,sp,192
    80005cd4:	8082                	ret
      end_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	9f2080e7          	jalr	-1550(ra) # 800046c8 <end_op>
      return -1;
    80005cde:	b7e5                	j	80005cc6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ce0:	f5040513          	addi	a0,s0,-176
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	748080e7          	jalr	1864(ra) # 8000442c <namei>
    80005cec:	892a                	mv	s2,a0
    80005cee:	c905                	beqz	a0,80005d1e <sys_open+0x13c>
    ilock(ip);
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	f86080e7          	jalr	-122(ra) # 80003c76 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cf8:	04491703          	lh	a4,68(s2)
    80005cfc:	4785                	li	a5,1
    80005cfe:	f4f712e3          	bne	a4,a5,80005c42 <sys_open+0x60>
    80005d02:	f4c42783          	lw	a5,-180(s0)
    80005d06:	dba1                	beqz	a5,80005c56 <sys_open+0x74>
      iunlockput(ip);
    80005d08:	854a                	mv	a0,s2
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	1ce080e7          	jalr	462(ra) # 80003ed8 <iunlockput>
      end_op();
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	9b6080e7          	jalr	-1610(ra) # 800046c8 <end_op>
      return -1;
    80005d1a:	54fd                	li	s1,-1
    80005d1c:	b76d                	j	80005cc6 <sys_open+0xe4>
      end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	9aa080e7          	jalr	-1622(ra) # 800046c8 <end_op>
      return -1;
    80005d26:	54fd                	li	s1,-1
    80005d28:	bf79                	j	80005cc6 <sys_open+0xe4>
    iunlockput(ip);
    80005d2a:	854a                	mv	a0,s2
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	1ac080e7          	jalr	428(ra) # 80003ed8 <iunlockput>
    end_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	994080e7          	jalr	-1644(ra) # 800046c8 <end_op>
    return -1;
    80005d3c:	54fd                	li	s1,-1
    80005d3e:	b761                	j	80005cc6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d40:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d44:	04691783          	lh	a5,70(s2)
    80005d48:	02f99223          	sh	a5,36(s3)
    80005d4c:	bf2d                	j	80005c86 <sys_open+0xa4>
    itrunc(ip);
    80005d4e:	854a                	mv	a0,s2
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	034080e7          	jalr	52(ra) # 80003d84 <itrunc>
    80005d58:	bfb1                	j	80005cb4 <sys_open+0xd2>
      fileclose(f);
    80005d5a:	854e                	mv	a0,s3
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	db8080e7          	jalr	-584(ra) # 80004b14 <fileclose>
    iunlockput(ip);
    80005d64:	854a                	mv	a0,s2
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	172080e7          	jalr	370(ra) # 80003ed8 <iunlockput>
    end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	95a080e7          	jalr	-1702(ra) # 800046c8 <end_op>
    return -1;
    80005d76:	54fd                	li	s1,-1
    80005d78:	b7b9                	j	80005cc6 <sys_open+0xe4>

0000000080005d7a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d7a:	7175                	addi	sp,sp,-144
    80005d7c:	e506                	sd	ra,136(sp)
    80005d7e:	e122                	sd	s0,128(sp)
    80005d80:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	8c6080e7          	jalr	-1850(ra) # 80004648 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d8a:	08000613          	li	a2,128
    80005d8e:	f7040593          	addi	a1,s0,-144
    80005d92:	4501                	li	a0,0
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	350080e7          	jalr	848(ra) # 800030e4 <argstr>
    80005d9c:	02054963          	bltz	a0,80005dce <sys_mkdir+0x54>
    80005da0:	4681                	li	a3,0
    80005da2:	4601                	li	a2,0
    80005da4:	4585                	li	a1,1
    80005da6:	f7040513          	addi	a0,s0,-144
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	7fe080e7          	jalr	2046(ra) # 800055a8 <create>
    80005db2:	cd11                	beqz	a0,80005dce <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	124080e7          	jalr	292(ra) # 80003ed8 <iunlockput>
  end_op();
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	90c080e7          	jalr	-1780(ra) # 800046c8 <end_op>
  return 0;
    80005dc4:	4501                	li	a0,0
}
    80005dc6:	60aa                	ld	ra,136(sp)
    80005dc8:	640a                	ld	s0,128(sp)
    80005dca:	6149                	addi	sp,sp,144
    80005dcc:	8082                	ret
    end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	8fa080e7          	jalr	-1798(ra) # 800046c8 <end_op>
    return -1;
    80005dd6:	557d                	li	a0,-1
    80005dd8:	b7fd                	j	80005dc6 <sys_mkdir+0x4c>

0000000080005dda <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dda:	7135                	addi	sp,sp,-160
    80005ddc:	ed06                	sd	ra,152(sp)
    80005dde:	e922                	sd	s0,144(sp)
    80005de0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	866080e7          	jalr	-1946(ra) # 80004648 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dea:	08000613          	li	a2,128
    80005dee:	f7040593          	addi	a1,s0,-144
    80005df2:	4501                	li	a0,0
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	2f0080e7          	jalr	752(ra) # 800030e4 <argstr>
    80005dfc:	04054a63          	bltz	a0,80005e50 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e00:	f6c40593          	addi	a1,s0,-148
    80005e04:	4505                	li	a0,1
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	29a080e7          	jalr	666(ra) # 800030a0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e0e:	04054163          	bltz	a0,80005e50 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e12:	f6840593          	addi	a1,s0,-152
    80005e16:	4509                	li	a0,2
    80005e18:	ffffd097          	auipc	ra,0xffffd
    80005e1c:	288080e7          	jalr	648(ra) # 800030a0 <argint>
     argint(1, &major) < 0 ||
    80005e20:	02054863          	bltz	a0,80005e50 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e24:	f6841683          	lh	a3,-152(s0)
    80005e28:	f6c41603          	lh	a2,-148(s0)
    80005e2c:	458d                	li	a1,3
    80005e2e:	f7040513          	addi	a0,s0,-144
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	776080e7          	jalr	1910(ra) # 800055a8 <create>
     argint(2, &minor) < 0 ||
    80005e3a:	c919                	beqz	a0,80005e50 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e3c:	ffffe097          	auipc	ra,0xffffe
    80005e40:	09c080e7          	jalr	156(ra) # 80003ed8 <iunlockput>
  end_op();
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	884080e7          	jalr	-1916(ra) # 800046c8 <end_op>
  return 0;
    80005e4c:	4501                	li	a0,0
    80005e4e:	a031                	j	80005e5a <sys_mknod+0x80>
    end_op();
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	878080e7          	jalr	-1928(ra) # 800046c8 <end_op>
    return -1;
    80005e58:	557d                	li	a0,-1
}
    80005e5a:	60ea                	ld	ra,152(sp)
    80005e5c:	644a                	ld	s0,144(sp)
    80005e5e:	610d                	addi	sp,sp,160
    80005e60:	8082                	ret

0000000080005e62 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e62:	7135                	addi	sp,sp,-160
    80005e64:	ed06                	sd	ra,152(sp)
    80005e66:	e922                	sd	s0,144(sp)
    80005e68:	e526                	sd	s1,136(sp)
    80005e6a:	e14a                	sd	s2,128(sp)
    80005e6c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e6e:	ffffc097          	auipc	ra,0xffffc
    80005e72:	b5a080e7          	jalr	-1190(ra) # 800019c8 <myproc>
    80005e76:	892a                	mv	s2,a0
  
  begin_op();
    80005e78:	ffffe097          	auipc	ra,0xffffe
    80005e7c:	7d0080e7          	jalr	2000(ra) # 80004648 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e80:	08000613          	li	a2,128
    80005e84:	f6040593          	addi	a1,s0,-160
    80005e88:	4501                	li	a0,0
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	25a080e7          	jalr	602(ra) # 800030e4 <argstr>
    80005e92:	04054b63          	bltz	a0,80005ee8 <sys_chdir+0x86>
    80005e96:	f6040513          	addi	a0,s0,-160
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	592080e7          	jalr	1426(ra) # 8000442c <namei>
    80005ea2:	84aa                	mv	s1,a0
    80005ea4:	c131                	beqz	a0,80005ee8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	dd0080e7          	jalr	-560(ra) # 80003c76 <ilock>
  if(ip->type != T_DIR){
    80005eae:	04449703          	lh	a4,68(s1)
    80005eb2:	4785                	li	a5,1
    80005eb4:	04f71063          	bne	a4,a5,80005ef4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005eb8:	8526                	mv	a0,s1
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	e7e080e7          	jalr	-386(ra) # 80003d38 <iunlock>
  iput(p->cwd);
    80005ec2:	15093503          	ld	a0,336(s2)
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	f6a080e7          	jalr	-150(ra) # 80003e30 <iput>
  end_op();
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	7fa080e7          	jalr	2042(ra) # 800046c8 <end_op>
  p->cwd = ip;
    80005ed6:	14993823          	sd	s1,336(s2)
  return 0;
    80005eda:	4501                	li	a0,0
}
    80005edc:	60ea                	ld	ra,152(sp)
    80005ede:	644a                	ld	s0,144(sp)
    80005ee0:	64aa                	ld	s1,136(sp)
    80005ee2:	690a                	ld	s2,128(sp)
    80005ee4:	610d                	addi	sp,sp,160
    80005ee6:	8082                	ret
    end_op();
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	7e0080e7          	jalr	2016(ra) # 800046c8 <end_op>
    return -1;
    80005ef0:	557d                	li	a0,-1
    80005ef2:	b7ed                	j	80005edc <sys_chdir+0x7a>
    iunlockput(ip);
    80005ef4:	8526                	mv	a0,s1
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	fe2080e7          	jalr	-30(ra) # 80003ed8 <iunlockput>
    end_op();
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	7ca080e7          	jalr	1994(ra) # 800046c8 <end_op>
    return -1;
    80005f06:	557d                	li	a0,-1
    80005f08:	bfd1                	j	80005edc <sys_chdir+0x7a>

0000000080005f0a <sys_exec>:

uint64
sys_exec(void)
{
    80005f0a:	7145                	addi	sp,sp,-464
    80005f0c:	e786                	sd	ra,456(sp)
    80005f0e:	e3a2                	sd	s0,448(sp)
    80005f10:	ff26                	sd	s1,440(sp)
    80005f12:	fb4a                	sd	s2,432(sp)
    80005f14:	f74e                	sd	s3,424(sp)
    80005f16:	f352                	sd	s4,416(sp)
    80005f18:	ef56                	sd	s5,408(sp)
    80005f1a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f1c:	08000613          	li	a2,128
    80005f20:	f4040593          	addi	a1,s0,-192
    80005f24:	4501                	li	a0,0
    80005f26:	ffffd097          	auipc	ra,0xffffd
    80005f2a:	1be080e7          	jalr	446(ra) # 800030e4 <argstr>
    return -1;
    80005f2e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f30:	0c054a63          	bltz	a0,80006004 <sys_exec+0xfa>
    80005f34:	e3840593          	addi	a1,s0,-456
    80005f38:	4505                	li	a0,1
    80005f3a:	ffffd097          	auipc	ra,0xffffd
    80005f3e:	188080e7          	jalr	392(ra) # 800030c2 <argaddr>
    80005f42:	0c054163          	bltz	a0,80006004 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f46:	10000613          	li	a2,256
    80005f4a:	4581                	li	a1,0
    80005f4c:	e4040513          	addi	a0,s0,-448
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	d90080e7          	jalr	-624(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f58:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f5c:	89a6                	mv	s3,s1
    80005f5e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f60:	02000a13          	li	s4,32
    80005f64:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f68:	00391513          	slli	a0,s2,0x3
    80005f6c:	e3040593          	addi	a1,s0,-464
    80005f70:	e3843783          	ld	a5,-456(s0)
    80005f74:	953e                	add	a0,a0,a5
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	090080e7          	jalr	144(ra) # 80003006 <fetchaddr>
    80005f7e:	02054a63          	bltz	a0,80005fb2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f82:	e3043783          	ld	a5,-464(s0)
    80005f86:	c3b9                	beqz	a5,80005fcc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f88:	ffffb097          	auipc	ra,0xffffb
    80005f8c:	b6c080e7          	jalr	-1172(ra) # 80000af4 <kalloc>
    80005f90:	85aa                	mv	a1,a0
    80005f92:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f96:	cd11                	beqz	a0,80005fb2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f98:	6605                	lui	a2,0x1
    80005f9a:	e3043503          	ld	a0,-464(s0)
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	0ba080e7          	jalr	186(ra) # 80003058 <fetchstr>
    80005fa6:	00054663          	bltz	a0,80005fb2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005faa:	0905                	addi	s2,s2,1
    80005fac:	09a1                	addi	s3,s3,8
    80005fae:	fb491be3          	bne	s2,s4,80005f64 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb2:	10048913          	addi	s2,s1,256
    80005fb6:	6088                	ld	a0,0(s1)
    80005fb8:	c529                	beqz	a0,80006002 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	a3e080e7          	jalr	-1474(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc2:	04a1                	addi	s1,s1,8
    80005fc4:	ff2499e3          	bne	s1,s2,80005fb6 <sys_exec+0xac>
  return -1;
    80005fc8:	597d                	li	s2,-1
    80005fca:	a82d                	j	80006004 <sys_exec+0xfa>
      argv[i] = 0;
    80005fcc:	0a8e                	slli	s5,s5,0x3
    80005fce:	fc040793          	addi	a5,s0,-64
    80005fd2:	9abe                	add	s5,s5,a5
    80005fd4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fd8:	e4040593          	addi	a1,s0,-448
    80005fdc:	f4040513          	addi	a0,s0,-192
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	194080e7          	jalr	404(ra) # 80005174 <exec>
    80005fe8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fea:	10048993          	addi	s3,s1,256
    80005fee:	6088                	ld	a0,0(s1)
    80005ff0:	c911                	beqz	a0,80006004 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ff2:	ffffb097          	auipc	ra,0xffffb
    80005ff6:	a06080e7          	jalr	-1530(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffa:	04a1                	addi	s1,s1,8
    80005ffc:	ff3499e3          	bne	s1,s3,80005fee <sys_exec+0xe4>
    80006000:	a011                	j	80006004 <sys_exec+0xfa>
  return -1;
    80006002:	597d                	li	s2,-1
}
    80006004:	854a                	mv	a0,s2
    80006006:	60be                	ld	ra,456(sp)
    80006008:	641e                	ld	s0,448(sp)
    8000600a:	74fa                	ld	s1,440(sp)
    8000600c:	795a                	ld	s2,432(sp)
    8000600e:	79ba                	ld	s3,424(sp)
    80006010:	7a1a                	ld	s4,416(sp)
    80006012:	6afa                	ld	s5,408(sp)
    80006014:	6179                	addi	sp,sp,464
    80006016:	8082                	ret

0000000080006018 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006018:	7139                	addi	sp,sp,-64
    8000601a:	fc06                	sd	ra,56(sp)
    8000601c:	f822                	sd	s0,48(sp)
    8000601e:	f426                	sd	s1,40(sp)
    80006020:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006022:	ffffc097          	auipc	ra,0xffffc
    80006026:	9a6080e7          	jalr	-1626(ra) # 800019c8 <myproc>
    8000602a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000602c:	fd840593          	addi	a1,s0,-40
    80006030:	4501                	li	a0,0
    80006032:	ffffd097          	auipc	ra,0xffffd
    80006036:	090080e7          	jalr	144(ra) # 800030c2 <argaddr>
    return -1;
    8000603a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000603c:	0e054063          	bltz	a0,8000611c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006040:	fc840593          	addi	a1,s0,-56
    80006044:	fd040513          	addi	a0,s0,-48
    80006048:	fffff097          	auipc	ra,0xfffff
    8000604c:	dfc080e7          	jalr	-516(ra) # 80004e44 <pipealloc>
    return -1;
    80006050:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006052:	0c054563          	bltz	a0,8000611c <sys_pipe+0x104>
  fd0 = -1;
    80006056:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000605a:	fd043503          	ld	a0,-48(s0)
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	508080e7          	jalr	1288(ra) # 80005566 <fdalloc>
    80006066:	fca42223          	sw	a0,-60(s0)
    8000606a:	08054c63          	bltz	a0,80006102 <sys_pipe+0xea>
    8000606e:	fc843503          	ld	a0,-56(s0)
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	4f4080e7          	jalr	1268(ra) # 80005566 <fdalloc>
    8000607a:	fca42023          	sw	a0,-64(s0)
    8000607e:	06054863          	bltz	a0,800060ee <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006082:	4691                	li	a3,4
    80006084:	fc440613          	addi	a2,s0,-60
    80006088:	fd843583          	ld	a1,-40(s0)
    8000608c:	68a8                	ld	a0,80(s1)
    8000608e:	ffffb097          	auipc	ra,0xffffb
    80006092:	5ec080e7          	jalr	1516(ra) # 8000167a <copyout>
    80006096:	02054063          	bltz	a0,800060b6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000609a:	4691                	li	a3,4
    8000609c:	fc040613          	addi	a2,s0,-64
    800060a0:	fd843583          	ld	a1,-40(s0)
    800060a4:	0591                	addi	a1,a1,4
    800060a6:	68a8                	ld	a0,80(s1)
    800060a8:	ffffb097          	auipc	ra,0xffffb
    800060ac:	5d2080e7          	jalr	1490(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060b0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060b2:	06055563          	bgez	a0,8000611c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060b6:	fc442783          	lw	a5,-60(s0)
    800060ba:	07e9                	addi	a5,a5,26
    800060bc:	078e                	slli	a5,a5,0x3
    800060be:	97a6                	add	a5,a5,s1
    800060c0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060c4:	fc042503          	lw	a0,-64(s0)
    800060c8:	0569                	addi	a0,a0,26
    800060ca:	050e                	slli	a0,a0,0x3
    800060cc:	9526                	add	a0,a0,s1
    800060ce:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060d2:	fd043503          	ld	a0,-48(s0)
    800060d6:	fffff097          	auipc	ra,0xfffff
    800060da:	a3e080e7          	jalr	-1474(ra) # 80004b14 <fileclose>
    fileclose(wf);
    800060de:	fc843503          	ld	a0,-56(s0)
    800060e2:	fffff097          	auipc	ra,0xfffff
    800060e6:	a32080e7          	jalr	-1486(ra) # 80004b14 <fileclose>
    return -1;
    800060ea:	57fd                	li	a5,-1
    800060ec:	a805                	j	8000611c <sys_pipe+0x104>
    if(fd0 >= 0)
    800060ee:	fc442783          	lw	a5,-60(s0)
    800060f2:	0007c863          	bltz	a5,80006102 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800060f6:	01a78513          	addi	a0,a5,26
    800060fa:	050e                	slli	a0,a0,0x3
    800060fc:	9526                	add	a0,a0,s1
    800060fe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006102:	fd043503          	ld	a0,-48(s0)
    80006106:	fffff097          	auipc	ra,0xfffff
    8000610a:	a0e080e7          	jalr	-1522(ra) # 80004b14 <fileclose>
    fileclose(wf);
    8000610e:	fc843503          	ld	a0,-56(s0)
    80006112:	fffff097          	auipc	ra,0xfffff
    80006116:	a02080e7          	jalr	-1534(ra) # 80004b14 <fileclose>
    return -1;
    8000611a:	57fd                	li	a5,-1
}
    8000611c:	853e                	mv	a0,a5
    8000611e:	70e2                	ld	ra,56(sp)
    80006120:	7442                	ld	s0,48(sp)
    80006122:	74a2                	ld	s1,40(sp)
    80006124:	6121                	addi	sp,sp,64
    80006126:	8082                	ret
	...

0000000080006130 <kernelvec>:
    80006130:	7111                	addi	sp,sp,-256
    80006132:	e006                	sd	ra,0(sp)
    80006134:	e40a                	sd	sp,8(sp)
    80006136:	e80e                	sd	gp,16(sp)
    80006138:	ec12                	sd	tp,24(sp)
    8000613a:	f016                	sd	t0,32(sp)
    8000613c:	f41a                	sd	t1,40(sp)
    8000613e:	f81e                	sd	t2,48(sp)
    80006140:	fc22                	sd	s0,56(sp)
    80006142:	e0a6                	sd	s1,64(sp)
    80006144:	e4aa                	sd	a0,72(sp)
    80006146:	e8ae                	sd	a1,80(sp)
    80006148:	ecb2                	sd	a2,88(sp)
    8000614a:	f0b6                	sd	a3,96(sp)
    8000614c:	f4ba                	sd	a4,104(sp)
    8000614e:	f8be                	sd	a5,112(sp)
    80006150:	fcc2                	sd	a6,120(sp)
    80006152:	e146                	sd	a7,128(sp)
    80006154:	e54a                	sd	s2,136(sp)
    80006156:	e94e                	sd	s3,144(sp)
    80006158:	ed52                	sd	s4,152(sp)
    8000615a:	f156                	sd	s5,160(sp)
    8000615c:	f55a                	sd	s6,168(sp)
    8000615e:	f95e                	sd	s7,176(sp)
    80006160:	fd62                	sd	s8,184(sp)
    80006162:	e1e6                	sd	s9,192(sp)
    80006164:	e5ea                	sd	s10,200(sp)
    80006166:	e9ee                	sd	s11,208(sp)
    80006168:	edf2                	sd	t3,216(sp)
    8000616a:	f1f6                	sd	t4,224(sp)
    8000616c:	f5fa                	sd	t5,232(sp)
    8000616e:	f9fe                	sd	t6,240(sp)
    80006170:	d73fc0ef          	jal	ra,80002ee2 <kerneltrap>
    80006174:	6082                	ld	ra,0(sp)
    80006176:	6122                	ld	sp,8(sp)
    80006178:	61c2                	ld	gp,16(sp)
    8000617a:	7282                	ld	t0,32(sp)
    8000617c:	7322                	ld	t1,40(sp)
    8000617e:	73c2                	ld	t2,48(sp)
    80006180:	7462                	ld	s0,56(sp)
    80006182:	6486                	ld	s1,64(sp)
    80006184:	6526                	ld	a0,72(sp)
    80006186:	65c6                	ld	a1,80(sp)
    80006188:	6666                	ld	a2,88(sp)
    8000618a:	7686                	ld	a3,96(sp)
    8000618c:	7726                	ld	a4,104(sp)
    8000618e:	77c6                	ld	a5,112(sp)
    80006190:	7866                	ld	a6,120(sp)
    80006192:	688a                	ld	a7,128(sp)
    80006194:	692a                	ld	s2,136(sp)
    80006196:	69ca                	ld	s3,144(sp)
    80006198:	6a6a                	ld	s4,152(sp)
    8000619a:	7a8a                	ld	s5,160(sp)
    8000619c:	7b2a                	ld	s6,168(sp)
    8000619e:	7bca                	ld	s7,176(sp)
    800061a0:	7c6a                	ld	s8,184(sp)
    800061a2:	6c8e                	ld	s9,192(sp)
    800061a4:	6d2e                	ld	s10,200(sp)
    800061a6:	6dce                	ld	s11,208(sp)
    800061a8:	6e6e                	ld	t3,216(sp)
    800061aa:	7e8e                	ld	t4,224(sp)
    800061ac:	7f2e                	ld	t5,232(sp)
    800061ae:	7fce                	ld	t6,240(sp)
    800061b0:	6111                	addi	sp,sp,256
    800061b2:	10200073          	sret
    800061b6:	00000013          	nop
    800061ba:	00000013          	nop
    800061be:	0001                	nop

00000000800061c0 <timervec>:
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	e10c                	sd	a1,0(a0)
    800061c6:	e510                	sd	a2,8(a0)
    800061c8:	e914                	sd	a3,16(a0)
    800061ca:	6d0c                	ld	a1,24(a0)
    800061cc:	7110                	ld	a2,32(a0)
    800061ce:	6194                	ld	a3,0(a1)
    800061d0:	96b2                	add	a3,a3,a2
    800061d2:	e194                	sd	a3,0(a1)
    800061d4:	4589                	li	a1,2
    800061d6:	14459073          	csrw	sip,a1
    800061da:	6914                	ld	a3,16(a0)
    800061dc:	6510                	ld	a2,8(a0)
    800061de:	610c                	ld	a1,0(a0)
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	30200073          	mret
	...

00000000800061ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ea:	1141                	addi	sp,sp,-16
    800061ec:	e422                	sd	s0,8(sp)
    800061ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061f0:	0c0007b7          	lui	a5,0xc000
    800061f4:	4705                	li	a4,1
    800061f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061f8:	c3d8                	sw	a4,4(a5)
}
    800061fa:	6422                	ld	s0,8(sp)
    800061fc:	0141                	addi	sp,sp,16
    800061fe:	8082                	ret

0000000080006200 <plicinithart>:

void
plicinithart(void)
{
    80006200:	1141                	addi	sp,sp,-16
    80006202:	e406                	sd	ra,8(sp)
    80006204:	e022                	sd	s0,0(sp)
    80006206:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	794080e7          	jalr	1940(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006210:	0085171b          	slliw	a4,a0,0x8
    80006214:	0c0027b7          	lui	a5,0xc002
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	40200713          	li	a4,1026
    8000621e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006222:	00d5151b          	slliw	a0,a0,0xd
    80006226:	0c2017b7          	lui	a5,0xc201
    8000622a:	953e                	add	a0,a0,a5
    8000622c:	00052023          	sw	zero,0(a0)
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret

0000000080006238 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006238:	1141                	addi	sp,sp,-16
    8000623a:	e406                	sd	ra,8(sp)
    8000623c:	e022                	sd	s0,0(sp)
    8000623e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	75c080e7          	jalr	1884(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006248:	00d5179b          	slliw	a5,a0,0xd
    8000624c:	0c201537          	lui	a0,0xc201
    80006250:	953e                	add	a0,a0,a5
  return irq;
}
    80006252:	4148                	lw	a0,4(a0)
    80006254:	60a2                	ld	ra,8(sp)
    80006256:	6402                	ld	s0,0(sp)
    80006258:	0141                	addi	sp,sp,16
    8000625a:	8082                	ret

000000008000625c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000625c:	1101                	addi	sp,sp,-32
    8000625e:	ec06                	sd	ra,24(sp)
    80006260:	e822                	sd	s0,16(sp)
    80006262:	e426                	sd	s1,8(sp)
    80006264:	1000                	addi	s0,sp,32
    80006266:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006268:	ffffb097          	auipc	ra,0xffffb
    8000626c:	734080e7          	jalr	1844(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006270:	00d5151b          	slliw	a0,a0,0xd
    80006274:	0c2017b7          	lui	a5,0xc201
    80006278:	97aa                	add	a5,a5,a0
    8000627a:	c3c4                	sw	s1,4(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret

0000000080006286 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006286:	1141                	addi	sp,sp,-16
    80006288:	e406                	sd	ra,8(sp)
    8000628a:	e022                	sd	s0,0(sp)
    8000628c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000628e:	479d                	li	a5,7
    80006290:	06a7c963          	blt	a5,a0,80006302 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006294:	00016797          	auipc	a5,0x16
    80006298:	d6c78793          	addi	a5,a5,-660 # 8001c000 <disk>
    8000629c:	00a78733          	add	a4,a5,a0
    800062a0:	6789                	lui	a5,0x2
    800062a2:	97ba                	add	a5,a5,a4
    800062a4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062a8:	e7ad                	bnez	a5,80006312 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062aa:	00451793          	slli	a5,a0,0x4
    800062ae:	00018717          	auipc	a4,0x18
    800062b2:	d5270713          	addi	a4,a4,-686 # 8001e000 <disk+0x2000>
    800062b6:	6314                	ld	a3,0(a4)
    800062b8:	96be                	add	a3,a3,a5
    800062ba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062be:	6314                	ld	a3,0(a4)
    800062c0:	96be                	add	a3,a3,a5
    800062c2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062c6:	6314                	ld	a3,0(a4)
    800062c8:	96be                	add	a3,a3,a5
    800062ca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062ce:	6318                	ld	a4,0(a4)
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062d6:	00016797          	auipc	a5,0x16
    800062da:	d2a78793          	addi	a5,a5,-726 # 8001c000 <disk>
    800062de:	97aa                	add	a5,a5,a0
    800062e0:	6509                	lui	a0,0x2
    800062e2:	953e                	add	a0,a0,a5
    800062e4:	4785                	li	a5,1
    800062e6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062ea:	00018517          	auipc	a0,0x18
    800062ee:	d2e50513          	addi	a0,a0,-722 # 8001e018 <disk+0x2018>
    800062f2:	ffffc097          	auipc	ra,0xffffc
    800062f6:	2ea080e7          	jalr	746(ra) # 800025dc <wakeup>
}
    800062fa:	60a2                	ld	ra,8(sp)
    800062fc:	6402                	ld	s0,0(sp)
    800062fe:	0141                	addi	sp,sp,16
    80006300:	8082                	ret
    panic("free_desc 1");
    80006302:	00002517          	auipc	a0,0x2
    80006306:	54e50513          	addi	a0,a0,1358 # 80008850 <syscalls+0x338>
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	234080e7          	jalr	564(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	54e50513          	addi	a0,a0,1358 # 80008860 <syscalls+0x348>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	224080e7          	jalr	548(ra) # 8000053e <panic>

0000000080006322 <virtio_disk_init>:
{
    80006322:	1101                	addi	sp,sp,-32
    80006324:	ec06                	sd	ra,24(sp)
    80006326:	e822                	sd	s0,16(sp)
    80006328:	e426                	sd	s1,8(sp)
    8000632a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000632c:	00002597          	auipc	a1,0x2
    80006330:	54458593          	addi	a1,a1,1348 # 80008870 <syscalls+0x358>
    80006334:	00018517          	auipc	a0,0x18
    80006338:	df450513          	addi	a0,a0,-524 # 8001e128 <disk+0x2128>
    8000633c:	ffffb097          	auipc	ra,0xffffb
    80006340:	818080e7          	jalr	-2024(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006344:	100017b7          	lui	a5,0x10001
    80006348:	4398                	lw	a4,0(a5)
    8000634a:	2701                	sext.w	a4,a4
    8000634c:	747277b7          	lui	a5,0x74727
    80006350:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006354:	0ef71163          	bne	a4,a5,80006436 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006358:	100017b7          	lui	a5,0x10001
    8000635c:	43dc                	lw	a5,4(a5)
    8000635e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006360:	4705                	li	a4,1
    80006362:	0ce79a63          	bne	a5,a4,80006436 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006366:	100017b7          	lui	a5,0x10001
    8000636a:	479c                	lw	a5,8(a5)
    8000636c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000636e:	4709                	li	a4,2
    80006370:	0ce79363          	bne	a5,a4,80006436 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006374:	100017b7          	lui	a5,0x10001
    80006378:	47d8                	lw	a4,12(a5)
    8000637a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000637c:	554d47b7          	lui	a5,0x554d4
    80006380:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006384:	0af71963          	bne	a4,a5,80006436 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006388:	100017b7          	lui	a5,0x10001
    8000638c:	4705                	li	a4,1
    8000638e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006390:	470d                	li	a4,3
    80006392:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006394:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006396:	c7ffe737          	lui	a4,0xc7ffe
    8000639a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    8000639e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063a0:	2701                	sext.w	a4,a4
    800063a2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a4:	472d                	li	a4,11
    800063a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a8:	473d                	li	a4,15
    800063aa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063ac:	6705                	lui	a4,0x1
    800063ae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063b4:	5bdc                	lw	a5,52(a5)
    800063b6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063b8:	c7d9                	beqz	a5,80006446 <virtio_disk_init+0x124>
  if(max < NUM)
    800063ba:	471d                	li	a4,7
    800063bc:	08f77d63          	bgeu	a4,a5,80006456 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063c0:	100014b7          	lui	s1,0x10001
    800063c4:	47a1                	li	a5,8
    800063c6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063c8:	6609                	lui	a2,0x2
    800063ca:	4581                	li	a1,0
    800063cc:	00016517          	auipc	a0,0x16
    800063d0:	c3450513          	addi	a0,a0,-972 # 8001c000 <disk>
    800063d4:	ffffb097          	auipc	ra,0xffffb
    800063d8:	90c080e7          	jalr	-1780(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063dc:	00016717          	auipc	a4,0x16
    800063e0:	c2470713          	addi	a4,a4,-988 # 8001c000 <disk>
    800063e4:	00c75793          	srli	a5,a4,0xc
    800063e8:	2781                	sext.w	a5,a5
    800063ea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063ec:	00018797          	auipc	a5,0x18
    800063f0:	c1478793          	addi	a5,a5,-1004 # 8001e000 <disk+0x2000>
    800063f4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063f6:	00016717          	auipc	a4,0x16
    800063fa:	c8a70713          	addi	a4,a4,-886 # 8001c080 <disk+0x80>
    800063fe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006400:	00017717          	auipc	a4,0x17
    80006404:	c0070713          	addi	a4,a4,-1024 # 8001d000 <disk+0x1000>
    80006408:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000640a:	4705                	li	a4,1
    8000640c:	00e78c23          	sb	a4,24(a5)
    80006410:	00e78ca3          	sb	a4,25(a5)
    80006414:	00e78d23          	sb	a4,26(a5)
    80006418:	00e78da3          	sb	a4,27(a5)
    8000641c:	00e78e23          	sb	a4,28(a5)
    80006420:	00e78ea3          	sb	a4,29(a5)
    80006424:	00e78f23          	sb	a4,30(a5)
    80006428:	00e78fa3          	sb	a4,31(a5)
}
    8000642c:	60e2                	ld	ra,24(sp)
    8000642e:	6442                	ld	s0,16(sp)
    80006430:	64a2                	ld	s1,8(sp)
    80006432:	6105                	addi	sp,sp,32
    80006434:	8082                	ret
    panic("could not find virtio disk");
    80006436:	00002517          	auipc	a0,0x2
    8000643a:	44a50513          	addi	a0,a0,1098 # 80008880 <syscalls+0x368>
    8000643e:	ffffa097          	auipc	ra,0xffffa
    80006442:	100080e7          	jalr	256(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	45a50513          	addi	a0,a0,1114 # 800088a0 <syscalls+0x388>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	46a50513          	addi	a0,a0,1130 # 800088c0 <syscalls+0x3a8>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>

0000000080006466 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006466:	7159                	addi	sp,sp,-112
    80006468:	f486                	sd	ra,104(sp)
    8000646a:	f0a2                	sd	s0,96(sp)
    8000646c:	eca6                	sd	s1,88(sp)
    8000646e:	e8ca                	sd	s2,80(sp)
    80006470:	e4ce                	sd	s3,72(sp)
    80006472:	e0d2                	sd	s4,64(sp)
    80006474:	fc56                	sd	s5,56(sp)
    80006476:	f85a                	sd	s6,48(sp)
    80006478:	f45e                	sd	s7,40(sp)
    8000647a:	f062                	sd	s8,32(sp)
    8000647c:	ec66                	sd	s9,24(sp)
    8000647e:	e86a                	sd	s10,16(sp)
    80006480:	1880                	addi	s0,sp,112
    80006482:	892a                	mv	s2,a0
    80006484:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006486:	00c52c83          	lw	s9,12(a0)
    8000648a:	001c9c9b          	slliw	s9,s9,0x1
    8000648e:	1c82                	slli	s9,s9,0x20
    80006490:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006494:	00018517          	auipc	a0,0x18
    80006498:	c9450513          	addi	a0,a0,-876 # 8001e128 <disk+0x2128>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	748080e7          	jalr	1864(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064a8:	00016b97          	auipc	s7,0x16
    800064ac:	b58b8b93          	addi	s7,s7,-1192 # 8001c000 <disk>
    800064b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064b4:	8a4e                	mv	s4,s3
    800064b6:	a051                	j	8000653a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064b8:	00fb86b3          	add	a3,s7,a5
    800064bc:	96da                	add	a3,a3,s6
    800064be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064c4:	0207c563          	bltz	a5,800064ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064c8:	2485                	addiw	s1,s1,1
    800064ca:	0711                	addi	a4,a4,4
    800064cc:	25548063          	beq	s1,s5,8000670c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064d2:	00018697          	auipc	a3,0x18
    800064d6:	b4668693          	addi	a3,a3,-1210 # 8001e018 <disk+0x2018>
    800064da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064dc:	0006c583          	lbu	a1,0(a3)
    800064e0:	fde1                	bnez	a1,800064b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064e2:	2785                	addiw	a5,a5,1
    800064e4:	0685                	addi	a3,a3,1
    800064e6:	ff879be3          	bne	a5,s8,800064dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064ea:	57fd                	li	a5,-1
    800064ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064ee:	02905a63          	blez	s1,80006522 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064f2:	f9042503          	lw	a0,-112(s0)
    800064f6:	00000097          	auipc	ra,0x0
    800064fa:	d90080e7          	jalr	-624(ra) # 80006286 <free_desc>
      for(int j = 0; j < i; j++)
    800064fe:	4785                	li	a5,1
    80006500:	0297d163          	bge	a5,s1,80006522 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006504:	f9442503          	lw	a0,-108(s0)
    80006508:	00000097          	auipc	ra,0x0
    8000650c:	d7e080e7          	jalr	-642(ra) # 80006286 <free_desc>
      for(int j = 0; j < i; j++)
    80006510:	4789                	li	a5,2
    80006512:	0097d863          	bge	a5,s1,80006522 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006516:	f9842503          	lw	a0,-104(s0)
    8000651a:	00000097          	auipc	ra,0x0
    8000651e:	d6c080e7          	jalr	-660(ra) # 80006286 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006522:	00018597          	auipc	a1,0x18
    80006526:	c0658593          	addi	a1,a1,-1018 # 8001e128 <disk+0x2128>
    8000652a:	00018517          	auipc	a0,0x18
    8000652e:	aee50513          	addi	a0,a0,-1298 # 8001e018 <disk+0x2018>
    80006532:	ffffc097          	auipc	ra,0xffffc
    80006536:	f02080e7          	jalr	-254(ra) # 80002434 <sleep>
  for(int i = 0; i < 3; i++){
    8000653a:	f9040713          	addi	a4,s0,-112
    8000653e:	84ce                	mv	s1,s3
    80006540:	bf41                	j	800064d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006542:	20058713          	addi	a4,a1,512
    80006546:	00471693          	slli	a3,a4,0x4
    8000654a:	00016717          	auipc	a4,0x16
    8000654e:	ab670713          	addi	a4,a4,-1354 # 8001c000 <disk>
    80006552:	9736                	add	a4,a4,a3
    80006554:	4685                	li	a3,1
    80006556:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000655a:	20058713          	addi	a4,a1,512
    8000655e:	00471693          	slli	a3,a4,0x4
    80006562:	00016717          	auipc	a4,0x16
    80006566:	a9e70713          	addi	a4,a4,-1378 # 8001c000 <disk>
    8000656a:	9736                	add	a4,a4,a3
    8000656c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006570:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006574:	7679                	lui	a2,0xffffe
    80006576:	963e                	add	a2,a2,a5
    80006578:	00018697          	auipc	a3,0x18
    8000657c:	a8868693          	addi	a3,a3,-1400 # 8001e000 <disk+0x2000>
    80006580:	6298                	ld	a4,0(a3)
    80006582:	9732                	add	a4,a4,a2
    80006584:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006586:	6298                	ld	a4,0(a3)
    80006588:	9732                	add	a4,a4,a2
    8000658a:	4541                	li	a0,16
    8000658c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000658e:	6298                	ld	a4,0(a3)
    80006590:	9732                	add	a4,a4,a2
    80006592:	4505                	li	a0,1
    80006594:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006598:	f9442703          	lw	a4,-108(s0)
    8000659c:	6288                	ld	a0,0(a3)
    8000659e:	962a                	add	a2,a2,a0
    800065a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065a4:	0712                	slli	a4,a4,0x4
    800065a6:	6290                	ld	a2,0(a3)
    800065a8:	963a                	add	a2,a2,a4
    800065aa:	05890513          	addi	a0,s2,88
    800065ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065b0:	6294                	ld	a3,0(a3)
    800065b2:	96ba                	add	a3,a3,a4
    800065b4:	40000613          	li	a2,1024
    800065b8:	c690                	sw	a2,8(a3)
  if(write)
    800065ba:	140d0063          	beqz	s10,800066fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065be:	00018697          	auipc	a3,0x18
    800065c2:	a426b683          	ld	a3,-1470(a3) # 8001e000 <disk+0x2000>
    800065c6:	96ba                	add	a3,a3,a4
    800065c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065cc:	00016817          	auipc	a6,0x16
    800065d0:	a3480813          	addi	a6,a6,-1484 # 8001c000 <disk>
    800065d4:	00018517          	auipc	a0,0x18
    800065d8:	a2c50513          	addi	a0,a0,-1492 # 8001e000 <disk+0x2000>
    800065dc:	6114                	ld	a3,0(a0)
    800065de:	96ba                	add	a3,a3,a4
    800065e0:	00c6d603          	lhu	a2,12(a3)
    800065e4:	00166613          	ori	a2,a2,1
    800065e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065ec:	f9842683          	lw	a3,-104(s0)
    800065f0:	6110                	ld	a2,0(a0)
    800065f2:	9732                	add	a4,a4,a2
    800065f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065f8:	20058613          	addi	a2,a1,512
    800065fc:	0612                	slli	a2,a2,0x4
    800065fe:	9642                	add	a2,a2,a6
    80006600:	577d                	li	a4,-1
    80006602:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006606:	00469713          	slli	a4,a3,0x4
    8000660a:	6114                	ld	a3,0(a0)
    8000660c:	96ba                	add	a3,a3,a4
    8000660e:	03078793          	addi	a5,a5,48
    80006612:	97c2                	add	a5,a5,a6
    80006614:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006616:	611c                	ld	a5,0(a0)
    80006618:	97ba                	add	a5,a5,a4
    8000661a:	4685                	li	a3,1
    8000661c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000661e:	611c                	ld	a5,0(a0)
    80006620:	97ba                	add	a5,a5,a4
    80006622:	4809                	li	a6,2
    80006624:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006628:	611c                	ld	a5,0(a0)
    8000662a:	973e                	add	a4,a4,a5
    8000662c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006630:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006634:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006638:	6518                	ld	a4,8(a0)
    8000663a:	00275783          	lhu	a5,2(a4)
    8000663e:	8b9d                	andi	a5,a5,7
    80006640:	0786                	slli	a5,a5,0x1
    80006642:	97ba                	add	a5,a5,a4
    80006644:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006648:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000664c:	6518                	ld	a4,8(a0)
    8000664e:	00275783          	lhu	a5,2(a4)
    80006652:	2785                	addiw	a5,a5,1
    80006654:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006658:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000665c:	100017b7          	lui	a5,0x10001
    80006660:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006664:	00492703          	lw	a4,4(s2)
    80006668:	4785                	li	a5,1
    8000666a:	02f71163          	bne	a4,a5,8000668c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000666e:	00018997          	auipc	s3,0x18
    80006672:	aba98993          	addi	s3,s3,-1350 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    80006676:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006678:	85ce                	mv	a1,s3
    8000667a:	854a                	mv	a0,s2
    8000667c:	ffffc097          	auipc	ra,0xffffc
    80006680:	db8080e7          	jalr	-584(ra) # 80002434 <sleep>
  while(b->disk == 1) {
    80006684:	00492783          	lw	a5,4(s2)
    80006688:	fe9788e3          	beq	a5,s1,80006678 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000668c:	f9042903          	lw	s2,-112(s0)
    80006690:	20090793          	addi	a5,s2,512
    80006694:	00479713          	slli	a4,a5,0x4
    80006698:	00016797          	auipc	a5,0x16
    8000669c:	96878793          	addi	a5,a5,-1688 # 8001c000 <disk>
    800066a0:	97ba                	add	a5,a5,a4
    800066a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066a6:	00018997          	auipc	s3,0x18
    800066aa:	95a98993          	addi	s3,s3,-1702 # 8001e000 <disk+0x2000>
    800066ae:	00491713          	slli	a4,s2,0x4
    800066b2:	0009b783          	ld	a5,0(s3)
    800066b6:	97ba                	add	a5,a5,a4
    800066b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066bc:	854a                	mv	a0,s2
    800066be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066c2:	00000097          	auipc	ra,0x0
    800066c6:	bc4080e7          	jalr	-1084(ra) # 80006286 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066ca:	8885                	andi	s1,s1,1
    800066cc:	f0ed                	bnez	s1,800066ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066ce:	00018517          	auipc	a0,0x18
    800066d2:	a5a50513          	addi	a0,a0,-1446 # 8001e128 <disk+0x2128>
    800066d6:	ffffa097          	auipc	ra,0xffffa
    800066da:	5c2080e7          	jalr	1474(ra) # 80000c98 <release>
}
    800066de:	70a6                	ld	ra,104(sp)
    800066e0:	7406                	ld	s0,96(sp)
    800066e2:	64e6                	ld	s1,88(sp)
    800066e4:	6946                	ld	s2,80(sp)
    800066e6:	69a6                	ld	s3,72(sp)
    800066e8:	6a06                	ld	s4,64(sp)
    800066ea:	7ae2                	ld	s5,56(sp)
    800066ec:	7b42                	ld	s6,48(sp)
    800066ee:	7ba2                	ld	s7,40(sp)
    800066f0:	7c02                	ld	s8,32(sp)
    800066f2:	6ce2                	ld	s9,24(sp)
    800066f4:	6d42                	ld	s10,16(sp)
    800066f6:	6165                	addi	sp,sp,112
    800066f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066fa:	00018697          	auipc	a3,0x18
    800066fe:	9066b683          	ld	a3,-1786(a3) # 8001e000 <disk+0x2000>
    80006702:	96ba                	add	a3,a3,a4
    80006704:	4609                	li	a2,2
    80006706:	00c69623          	sh	a2,12(a3)
    8000670a:	b5c9                	j	800065cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000670c:	f9042583          	lw	a1,-112(s0)
    80006710:	20058793          	addi	a5,a1,512
    80006714:	0792                	slli	a5,a5,0x4
    80006716:	00016517          	auipc	a0,0x16
    8000671a:	99250513          	addi	a0,a0,-1646 # 8001c0a8 <disk+0xa8>
    8000671e:	953e                	add	a0,a0,a5
  if(write)
    80006720:	e20d11e3          	bnez	s10,80006542 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006724:	20058713          	addi	a4,a1,512
    80006728:	00471693          	slli	a3,a4,0x4
    8000672c:	00016717          	auipc	a4,0x16
    80006730:	8d470713          	addi	a4,a4,-1836 # 8001c000 <disk>
    80006734:	9736                	add	a4,a4,a3
    80006736:	0a072423          	sw	zero,168(a4)
    8000673a:	b505                	j	8000655a <virtio_disk_rw+0xf4>

000000008000673c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000673c:	1101                	addi	sp,sp,-32
    8000673e:	ec06                	sd	ra,24(sp)
    80006740:	e822                	sd	s0,16(sp)
    80006742:	e426                	sd	s1,8(sp)
    80006744:	e04a                	sd	s2,0(sp)
    80006746:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006748:	00018517          	auipc	a0,0x18
    8000674c:	9e050513          	addi	a0,a0,-1568 # 8001e128 <disk+0x2128>
    80006750:	ffffa097          	auipc	ra,0xffffa
    80006754:	494080e7          	jalr	1172(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006758:	10001737          	lui	a4,0x10001
    8000675c:	533c                	lw	a5,96(a4)
    8000675e:	8b8d                	andi	a5,a5,3
    80006760:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006762:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006766:	00018797          	auipc	a5,0x18
    8000676a:	89a78793          	addi	a5,a5,-1894 # 8001e000 <disk+0x2000>
    8000676e:	6b94                	ld	a3,16(a5)
    80006770:	0207d703          	lhu	a4,32(a5)
    80006774:	0026d783          	lhu	a5,2(a3)
    80006778:	06f70163          	beq	a4,a5,800067da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000677c:	00016917          	auipc	s2,0x16
    80006780:	88490913          	addi	s2,s2,-1916 # 8001c000 <disk>
    80006784:	00018497          	auipc	s1,0x18
    80006788:	87c48493          	addi	s1,s1,-1924 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    8000678c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006790:	6898                	ld	a4,16(s1)
    80006792:	0204d783          	lhu	a5,32(s1)
    80006796:	8b9d                	andi	a5,a5,7
    80006798:	078e                	slli	a5,a5,0x3
    8000679a:	97ba                	add	a5,a5,a4
    8000679c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000679e:	20078713          	addi	a4,a5,512
    800067a2:	0712                	slli	a4,a4,0x4
    800067a4:	974a                	add	a4,a4,s2
    800067a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067aa:	e731                	bnez	a4,800067f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067ac:	20078793          	addi	a5,a5,512
    800067b0:	0792                	slli	a5,a5,0x4
    800067b2:	97ca                	add	a5,a5,s2
    800067b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ba:	ffffc097          	auipc	ra,0xffffc
    800067be:	e22080e7          	jalr	-478(ra) # 800025dc <wakeup>

    disk.used_idx += 1;
    800067c2:	0204d783          	lhu	a5,32(s1)
    800067c6:	2785                	addiw	a5,a5,1
    800067c8:	17c2                	slli	a5,a5,0x30
    800067ca:	93c1                	srli	a5,a5,0x30
    800067cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067d0:	6898                	ld	a4,16(s1)
    800067d2:	00275703          	lhu	a4,2(a4)
    800067d6:	faf71be3          	bne	a4,a5,8000678c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067da:	00018517          	auipc	a0,0x18
    800067de:	94e50513          	addi	a0,a0,-1714 # 8001e128 <disk+0x2128>
    800067e2:	ffffa097          	auipc	ra,0xffffa
    800067e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
}
    800067ea:	60e2                	ld	ra,24(sp)
    800067ec:	6442                	ld	s0,16(sp)
    800067ee:	64a2                	ld	s1,8(sp)
    800067f0:	6902                	ld	s2,0(sp)
    800067f2:	6105                	addi	sp,sp,32
    800067f4:	8082                	ret
      panic("virtio_disk_intr status");
    800067f6:	00002517          	auipc	a0,0x2
    800067fa:	0ea50513          	addi	a0,a0,234 # 800088e0 <syscalls+0x3c8>
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
