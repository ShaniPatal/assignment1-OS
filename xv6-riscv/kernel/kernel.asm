
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
    80000068:	17c78793          	addi	a5,a5,380 # 800061e0 <timervec>
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
    80000130:	8ca080e7          	jalr	-1846(ra) # 800029f6 <either_copyin>
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
    800001d8:	228080e7          	jalr	552(ra) # 800023fc <sleep>
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
    80000214:	790080e7          	jalr	1936(ra) # 800029a0 <either_copyout>
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
    800002f6:	75a080e7          	jalr	1882(ra) # 80002a4c <procdump>
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
    8000044a:	186080e7          	jalr	390(ra) # 800025cc <wakeup>
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
    800008a4:	d2c080e7          	jalr	-724(ra) # 800025cc <wakeup>
    
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
    80000930:	ad0080e7          	jalr	-1328(ra) # 800023fc <sleep>
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
    80000ed8:	d8e080e7          	jalr	-626(ra) # 80002c62 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	344080e7          	jalr	836(ra) # 80006220 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	11e080e7          	jalr	286(ra) # 80002002 <scheduler>
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
    80000f58:	ce6080e7          	jalr	-794(ra) # 80002c3a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	d06080e7          	jalr	-762(ra) # 80002c62 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	2a6080e7          	jalr	678(ra) # 8000620a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	2b4080e7          	jalr	692(ra) # 80006220 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	494080e7          	jalr	1172(ra) # 80003408 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	b24080e7          	jalr	-1244(ra) # 80003aa0 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	ace080e7          	jalr	-1330(ra) # 80004a52 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	3b6080e7          	jalr	950(ra) # 80006342 <virtio_disk_init>
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
void proc_mapstacks(pagetable_t kpgtbl)
{
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

  for (p = proc; p < &proc[NPROC]; p++)
    8000185c:	00009497          	auipc	s1,0x9
    80001860:	a0448493          	addi	s1,s1,-1532 # 8000a260 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001876:	0000fa17          	auipc	s4,0xf
    8000187a:	beaa0a13          	addi	s4,s4,-1046 # 80010460 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if (pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
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
  for (p = proc; p < &proc[NPROC]; p++)
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
void procinit(void)
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
  for (p = proc; p < &proc[NPROC]; p++)
    80001920:	00009497          	auipc	s1,0x9
    80001924:	94048493          	addi	s1,s1,-1728 # 8000a260 <proc>
  {
    initlock(&p->lock, "proc");
    80001928:	00007b17          	auipc	s6,0x7
    8000192c:	8d0b0b13          	addi	s6,s6,-1840 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001930:	8aa6                	mv	s5,s1
    80001932:	00006a17          	auipc	s4,0x6
    80001936:	6cea0a13          	addi	s4,s4,1742 # 80008000 <etext>
    8000193a:	04000937          	lui	s2,0x4000
    8000193e:	197d                	addi	s2,s2,-1
    80001940:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001942:	0000f997          	auipc	s3,0xf
    80001946:	b1e98993          	addi	s3,s3,-1250 # 80010460 <tickslock>
    initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	878d                	srai	a5,a5,0x3
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
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
int cpuid()
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
struct cpu *
mycpu(void)
{
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
struct proc *
myproc(void)
{
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
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
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

  if (first)
    80001a18:	00007797          	auipc	a5,0x7
    80001a1c:	ee87a783          	lw	a5,-280(a5) # 80008900 <first.1826>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	258080e7          	jalr	600(ra) # 80002c7a <usertrapret>
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
    80001a40:	fe4080e7          	jalr	-28(ra) # 80003a20 <fsinit>
    80001a44:	bff9                	j	80001a22 <forkret+0x22>

0000000080001a46 <allocpid>:
{
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
  if (pagetable == 0)
    80001aa4:	c121                	beqz	a0,80001ae4 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
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
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
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
  if (p->trapframe)
    80001b86:	6d28                	ld	a0,88(a0)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e6e080e7          	jalr	-402(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b92:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
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
  for (p = proc; p < &proc[NPROC]; p++)
    80001bde:	00008497          	auipc	s1,0x8
    80001be2:	68248493          	addi	s1,s1,1666 # 8000a260 <proc>
    80001be6:	0000f917          	auipc	s2,0xf
    80001bea:	87a90913          	addi	s2,s2,-1926 # 80010460 <tickslock>
    acquire(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001bf8:	4c9c                	lw	a5,24(s1)
    80001bfa:	cf81                	beqz	a5,80001c12 <allocproc+0x40>
      release(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
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
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
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
  if (p->pagetable == 0)
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
  p->trapframe->epc = 0;     // user program counter
    80001cea:	6cb8                	ld	a4,88(s1)
    80001cec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
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
    80001d16:	73c080e7          	jalr	1852(ra) # 8000444e <namei>
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
  if (n > 0)
    80001d60:	00904f63          	bgtz	s1,80001d7e <growproc+0x3c>
  else if (n < 0)
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
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
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
  if ((np = allocproc()) == 0)
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e02080e7          	jalr	-510(ra) # 80001bd2 <allocproc>
    80001dd8:	12050163          	beqz	a0,80001efa <fork+0x144>
    80001ddc:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
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
  for (i = 0; i < NOFILE; i++)
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
    80001e58:	c90080e7          	jalr	-880(ra) # 80004ae4 <filedup>
    80001e5c:	009987b3          	add	a5,s3,s1
    80001e60:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e62:	04a1                	addi	s1,s1,8
    80001e64:	01448763          	beq	s1,s4,80001e72 <fork+0xbc>
    if (p->ofile[i])
    80001e68:	009907b3          	add	a5,s2,s1
    80001e6c:	6388                	ld	a0,0(a5)
    80001e6e:	f17d                	bnez	a0,80001e54 <fork+0x9e>
    80001e70:	bfcd                	j	80001e62 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e72:	15093503          	ld	a0,336(s2)
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	de4080e7          	jalr	-540(ra) # 80003c5a <idup>
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
{
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
    80001f4a:	00008a97          	auipc	s5,0x8
    80001f4e:	266a8a93          	addi	s5,s5,614 # 8000a1b0 <pid_lock>
    80001f52:	9abe                	add	s5,s5,a5
        p->runnable_time += ticks - p->last_runnable_time;
    80001f54:	00007b17          	auipc	s6,0x7
    80001f58:	104b0b13          	addi	s6,s6,260 # 80009058 <ticks>
        if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    80001f5c:	00007b97          	auipc	s7,0x7
    80001f60:	0f0b8b93          	addi	s7,s7,240 # 8000904c <pause_time>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6c:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f70:	00008497          	auipc	s1,0x8
    80001f74:	2f048493          	addi	s1,s1,752 # 8000a260 <proc>
      if (p->state == RUNNABLE)
    80001f78:	4a0d                	li	s4,3
        if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    80001f7a:	4c05                	li	s8,1
    for (p = proc; p < &proc[NPROC]; p++)
    80001f7c:	0000e997          	auipc	s3,0xe
    80001f80:	4e498993          	addi	s3,s3,1252 # 80010460 <tickslock>
    80001f84:	a0a9                	j	80001fce <round_robin+0xd0>
            pause_time = 0;
    80001f86:	000ba023          	sw	zero,0(s7)
        p->state = RUNNING;
    80001f8a:	4791                	li	a5,4
    80001f8c:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    80001f8e:	029ab823          	sd	s1,48(s5)
        p->runnable_time += ticks - p->last_runnable_time;
    80001f92:	000b2703          	lw	a4,0(s6)
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
    80001fb4:	c20080e7          	jalr	-992(ra) # 80002bd0 <swtch>
        c->proc = 0;
    80001fb8:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	cda080e7          	jalr	-806(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fc6:	18848493          	addi	s1,s1,392
    80001fca:	f9348de3          	beq	s1,s3,80001f64 <round_robin+0x66>
      acquire(&p->lock);
    80001fce:	8926                	mv	s2,s1
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	c12080e7          	jalr	-1006(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    80001fda:	4c9c                	lw	a5,24(s1)
    80001fdc:	ff4790e3          	bne	a5,s4,80001fbc <round_robin+0xbe>
        if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    80001fe0:	589c                	lw	a5,48(s1)
    80001fe2:	37fd                	addiw	a5,a5,-1
    80001fe4:	fafc73e3          	bgeu	s8,a5,80001f8a <round_robin+0x8c>
    80001fe8:	000ba783          	lw	a5,0(s7)
    80001fec:	dfd9                	beqz	a5,80001f8a <round_robin+0x8c>
          if (ticks >= pause_time)
    80001fee:	000b2703          	lw	a4,0(s6)
    80001ff2:	f8f77ae3          	bgeu	a4,a5,80001f86 <round_robin+0x88>
            release(&p->lock);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	ca0080e7          	jalr	-864(ra) # 80000c98 <release>
            continue;
    80002000:	b7d9                	j	80001fc6 <round_robin+0xc8>

0000000080002002 <scheduler>:
{
    80002002:	1141                	addi	sp,sp,-16
    80002004:	e406                	sd	ra,8(sp)
    80002006:	e022                	sd	s0,0(sp)
    80002008:	0800                	addi	s0,sp,16
  round_robin();
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	ef4080e7          	jalr	-268(ra) # 80001efe <round_robin>

0000000080002012 <sjf>:
{
    80002012:	7159                	addi	sp,sp,-112
    80002014:	f486                	sd	ra,104(sp)
    80002016:	f0a2                	sd	s0,96(sp)
    80002018:	eca6                	sd	s1,88(sp)
    8000201a:	e8ca                	sd	s2,80(sp)
    8000201c:	e4ce                	sd	s3,72(sp)
    8000201e:	e0d2                	sd	s4,64(sp)
    80002020:	fc56                	sd	s5,56(sp)
    80002022:	f85a                	sd	s6,48(sp)
    80002024:	f45e                	sd	s7,40(sp)
    80002026:	f062                	sd	s8,32(sp)
    80002028:	ec66                	sd	s9,24(sp)
    8000202a:	e86a                	sd	s10,16(sp)
    8000202c:	e46e                	sd	s11,8(sp)
    8000202e:	1880                	addi	s0,sp,112
  printf("SJF Policy \n");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	20050513          	addi	a0,a0,512 # 80008230 <digits+0x1f0>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	550080e7          	jalr	1360(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002040:	8792                	mv	a5,tp
  int id = r_tp();
    80002042:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002044:	00779693          	slli	a3,a5,0x7
    80002048:	00008717          	auipc	a4,0x8
    8000204c:	16870713          	addi	a4,a4,360 # 8000a1b0 <pid_lock>
    80002050:	9736                	add	a4,a4,a3
    80002052:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &min_proc->context);
    80002056:	00008717          	auipc	a4,0x8
    8000205a:	19270713          	addi	a4,a4,402 # 8000a1e8 <cpus+0x8>
    8000205e:	00e68db3          	add	s11,a3,a4
    int min = -1;
    80002062:	5bfd                	li	s7,-1
      if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    80002064:	00007a97          	auipc	s5,0x7
    80002068:	fe8a8a93          	addi	s5,s5,-24 # 8000904c <pause_time>
        if (ticks >= pause_time)
    8000206c:	00007c17          	auipc	s8,0x7
    80002070:	fecc0c13          	addi	s8,s8,-20 # 80009058 <ticks>
      c->proc = min_proc;
    80002074:	00008d17          	auipc	s10,0x8
    80002078:	13cd0d13          	addi	s10,s10,316 # 8000a1b0 <pid_lock>
    8000207c:	9d36                	add	s10,s10,a3
    8000207e:	a08d                	j	800020e0 <sjf+0xce>
          pause_time = 0;
    80002080:	000aa023          	sw	zero,0(s5)
      if ((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min))
    80002084:	4c9c                	lw	a5,24(s1)
    80002086:	05478163          	beq	a5,s4,800020c8 <sjf+0xb6>
      release(&p->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c0c080e7          	jalr	-1012(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002094:	18848493          	addi	s1,s1,392
    80002098:	05248263          	beq	s1,s2,800020dc <sjf+0xca>
      acquire(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
      if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    800020a6:	589c                	lw	a5,48(s1)
    800020a8:	37fd                	addiw	a5,a5,-1
    800020aa:	fcf9fde3          	bgeu	s3,a5,80002084 <sjf+0x72>
    800020ae:	000aa783          	lw	a5,0(s5)
    800020b2:	dbe9                	beqz	a5,80002084 <sjf+0x72>
        if (ticks >= pause_time)
    800020b4:	000c2703          	lw	a4,0(s8)
    800020b8:	fcf774e3          	bgeu	a4,a5,80002080 <sjf+0x6e>
          release(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
          continue;
    800020c6:	b7f9                	j	80002094 <sjf+0x82>
      if ((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min))
    800020c8:	017b0663          	beq	s6,s7,800020d4 <sjf+0xc2>
    800020cc:	1684a783          	lw	a5,360(s1)
    800020d0:	fb67fde3          	bgeu	a5,s6,8000208a <sjf+0x78>
        min = p->mean_ticks;
    800020d4:	1684ab03          	lw	s6,360(s1)
    800020d8:	8ca6                	mv	s9,s1
    800020da:	bf45                	j	8000208a <sjf+0x78>
    if (min == -1)
    800020dc:	037b1463          	bne	s6,s7,80002104 <sjf+0xf2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e8:	10079073          	csrw	sstatus,a5
    int min = -1;
    800020ec:	8b5e                	mv	s6,s7
    for (p = proc; p < &proc[NPROC]; p++)
    800020ee:	00008497          	auipc	s1,0x8
    800020f2:	17248493          	addi	s1,s1,370 # 8000a260 <proc>
      if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    800020f6:	4985                	li	s3,1
      if ((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min))
    800020f8:	4a0d                	li	s4,3
    for (p = proc; p < &proc[NPROC]; p++)
    800020fa:	0000e917          	auipc	s2,0xe
    800020fe:	36690913          	addi	s2,s2,870 # 80010460 <tickslock>
    80002102:	bf69                	j	8000209c <sjf+0x8a>
    acquire(&min_proc->lock);
    80002104:	84e6                	mv	s1,s9
    80002106:	8566                	mv	a0,s9
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	adc080e7          	jalr	-1316(ra) # 80000be4 <acquire>
    if (min_proc->state == RUNNABLE)
    80002110:	018ca703          	lw	a4,24(s9)
    80002114:	478d                	li	a5,3
    80002116:	00f70863          	beq	a4,a5,80002126 <sjf+0x114>
    release(&min_proc->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	b7c080e7          	jalr	-1156(ra) # 80000c98 <release>
    80002124:	bf75                	j	800020e0 <sjf+0xce>
      min_proc->state = RUNNING;
    80002126:	4791                	li	a5,4
    80002128:	00fcac23          	sw	a5,24(s9)
      c->proc = min_proc;
    8000212c:	039d3823          	sd	s9,48(s10)
      min_proc->runnable_time += ticks - min_proc->last_runnable_time;
    80002130:	000c2703          	lw	a4,0(s8)
    80002134:	17cca783          	lw	a5,380(s9)
    80002138:	9fb9                	addw	a5,a5,a4
    8000213a:	174ca683          	lw	a3,372(s9)
    8000213e:	9f95                	subw	a5,a5,a3
    80002140:	16fcae23          	sw	a5,380(s9)
      min_proc->start_cpu_burst = ticks;
    80002144:	16eca823          	sw	a4,368(s9)
      swtch(&c->context, &min_proc->context);
    80002148:	060c8593          	addi	a1,s9,96
    8000214c:	856e                	mv	a0,s11
    8000214e:	00001097          	auipc	ra,0x1
    80002152:	a82080e7          	jalr	-1406(ra) # 80002bd0 <swtch>
      c->proc = 0;
    80002156:	020d3823          	sd	zero,48(s10)
    8000215a:	b7c1                	j	8000211a <sjf+0x108>

000000008000215c <fcfs>:
{
    8000215c:	7159                	addi	sp,sp,-112
    8000215e:	f486                	sd	ra,104(sp)
    80002160:	f0a2                	sd	s0,96(sp)
    80002162:	eca6                	sd	s1,88(sp)
    80002164:	e8ca                	sd	s2,80(sp)
    80002166:	e4ce                	sd	s3,72(sp)
    80002168:	e0d2                	sd	s4,64(sp)
    8000216a:	fc56                	sd	s5,56(sp)
    8000216c:	f85a                	sd	s6,48(sp)
    8000216e:	f45e                	sd	s7,40(sp)
    80002170:	f062                	sd	s8,32(sp)
    80002172:	ec66                	sd	s9,24(sp)
    80002174:	e86a                	sd	s10,16(sp)
    80002176:	e46e                	sd	s11,8(sp)
    80002178:	1880                	addi	s0,sp,112
  printf("FCFS Policy \n");
    8000217a:	00006517          	auipc	a0,0x6
    8000217e:	0c650513          	addi	a0,a0,198 # 80008240 <digits+0x200>
    80002182:	ffffe097          	auipc	ra,0xffffe
    80002186:	406080e7          	jalr	1030(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218a:	8792                	mv	a5,tp
  int id = r_tp();
    8000218c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000218e:	00779693          	slli	a3,a5,0x7
    80002192:	00008717          	auipc	a4,0x8
    80002196:	01e70713          	addi	a4,a4,30 # 8000a1b0 <pid_lock>
    8000219a:	9736                	add	a4,a4,a3
    8000219c:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &min_proc->context);
    800021a0:	00008717          	auipc	a4,0x8
    800021a4:	04870713          	addi	a4,a4,72 # 8000a1e8 <cpus+0x8>
    800021a8:	00e68db3          	add	s11,a3,a4
    int min = -1;
    800021ac:	5bfd                	li	s7,-1
      if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    800021ae:	00007a97          	auipc	s5,0x7
    800021b2:	e9ea8a93          	addi	s5,s5,-354 # 8000904c <pause_time>
        if (ticks >= pause_time)
    800021b6:	00007c17          	auipc	s8,0x7
    800021ba:	ea2c0c13          	addi	s8,s8,-350 # 80009058 <ticks>
      c->proc = min_proc;
    800021be:	00008d17          	auipc	s10,0x8
    800021c2:	ff2d0d13          	addi	s10,s10,-14 # 8000a1b0 <pid_lock>
    800021c6:	9d36                	add	s10,s10,a3
    800021c8:	a08d                	j	8000222a <fcfs+0xce>
          pause_time = 0;
    800021ca:	000aa023          	sw	zero,0(s5)
      if ((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min))
    800021ce:	4c9c                	lw	a5,24(s1)
    800021d0:	05478163          	beq	a5,s4,80002212 <fcfs+0xb6>
      release(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	ac2080e7          	jalr	-1342(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800021de:	18848493          	addi	s1,s1,392
    800021e2:	05248263          	beq	s1,s2,80002226 <fcfs+0xca>
      acquire(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	9fc080e7          	jalr	-1540(ra) # 80000be4 <acquire>
      if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    800021f0:	589c                	lw	a5,48(s1)
    800021f2:	37fd                	addiw	a5,a5,-1
    800021f4:	fcf9fde3          	bgeu	s3,a5,800021ce <fcfs+0x72>
    800021f8:	000aa783          	lw	a5,0(s5)
    800021fc:	dbe9                	beqz	a5,800021ce <fcfs+0x72>
        if (ticks >= pause_time)
    800021fe:	000c2703          	lw	a4,0(s8)
    80002202:	fcf774e3          	bgeu	a4,a5,800021ca <fcfs+0x6e>
          release(&p->lock);
    80002206:	8526                	mv	a0,s1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a90080e7          	jalr	-1392(ra) # 80000c98 <release>
          continue;
    80002210:	b7f9                	j	800021de <fcfs+0x82>
      if ((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min))
    80002212:	017b0663          	beq	s6,s7,8000221e <fcfs+0xc2>
    80002216:	1744a783          	lw	a5,372(s1)
    8000221a:	fb67fde3          	bgeu	a5,s6,800021d4 <fcfs+0x78>
        min = p->last_runnable_time;
    8000221e:	1744ab03          	lw	s6,372(s1)
    80002222:	8ca6                	mv	s9,s1
    80002224:	bf45                	j	800021d4 <fcfs+0x78>
    if (min == -1)
    80002226:	037b1463          	bne	s6,s7,8000224e <fcfs+0xf2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000222a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000222e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002232:	10079073          	csrw	sstatus,a5
    int min = -1;
    80002236:	8b5e                	mv	s6,s7
    for (p = proc; p < &proc[NPROC]; p++)
    80002238:	00008497          	auipc	s1,0x8
    8000223c:	02848493          	addi	s1,s1,40 # 8000a260 <proc>
      if (p->pid != 1 && p->pid != 2 && pause_time != 0)
    80002240:	4985                	li	s3,1
      if ((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min))
    80002242:	4a0d                	li	s4,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002244:	0000e917          	auipc	s2,0xe
    80002248:	21c90913          	addi	s2,s2,540 # 80010460 <tickslock>
    8000224c:	bf69                	j	800021e6 <fcfs+0x8a>
    acquire(&min_proc->lock);
    8000224e:	84e6                	mv	s1,s9
    80002250:	8566                	mv	a0,s9
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	992080e7          	jalr	-1646(ra) # 80000be4 <acquire>
    if (min_proc->state == RUNNABLE)
    8000225a:	018ca703          	lw	a4,24(s9)
    8000225e:	478d                	li	a5,3
    80002260:	00f70863          	beq	a4,a5,80002270 <fcfs+0x114>
    release(&min_proc->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
    8000226e:	bf75                	j	8000222a <fcfs+0xce>
      min_proc->state = RUNNING;
    80002270:	4791                	li	a5,4
    80002272:	00fcac23          	sw	a5,24(s9)
      c->proc = min_proc;
    80002276:	039d3823          	sd	s9,48(s10)
      min_proc->runnable_time += ticks - min_proc->last_runnable_time;
    8000227a:	000c2703          	lw	a4,0(s8)
    8000227e:	17cca783          	lw	a5,380(s9)
    80002282:	9fb9                	addw	a5,a5,a4
    80002284:	174ca683          	lw	a3,372(s9)
    80002288:	9f95                	subw	a5,a5,a3
    8000228a:	16fcae23          	sw	a5,380(s9)
      min_proc->start_cpu_burst = ticks;
    8000228e:	16eca823          	sw	a4,368(s9)
      swtch(&c->context, &min_proc->context);
    80002292:	060c8593          	addi	a1,s9,96
    80002296:	856e                	mv	a0,s11
    80002298:	00001097          	auipc	ra,0x1
    8000229c:	938080e7          	jalr	-1736(ra) # 80002bd0 <swtch>
      c->proc = 0;
    800022a0:	020d3823          	sd	zero,48(s10)
    800022a4:	b7c1                	j	80002264 <fcfs+0x108>

00000000800022a6 <sched>:
{
    800022a6:	7179                	addi	sp,sp,-48
    800022a8:	f406                	sd	ra,40(sp)
    800022aa:	f022                	sd	s0,32(sp)
    800022ac:	ec26                	sd	s1,24(sp)
    800022ae:	e84a                	sd	s2,16(sp)
    800022b0:	e44e                	sd	s3,8(sp)
    800022b2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	714080e7          	jalr	1812(ra) # 800019c8 <myproc>
    800022bc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	8ac080e7          	jalr	-1876(ra) # 80000b6a <holding>
    800022c6:	c93d                	beqz	a0,8000233c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c8:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022ca:	2781                	sext.w	a5,a5
    800022cc:	079e                	slli	a5,a5,0x7
    800022ce:	00008717          	auipc	a4,0x8
    800022d2:	ee270713          	addi	a4,a4,-286 # 8000a1b0 <pid_lock>
    800022d6:	97ba                	add	a5,a5,a4
    800022d8:	0a87a703          	lw	a4,168(a5)
    800022dc:	4785                	li	a5,1
    800022de:	06f71763          	bne	a4,a5,8000234c <sched+0xa6>
  if (p->state == RUNNING)
    800022e2:	4c98                	lw	a4,24(s1)
    800022e4:	4791                	li	a5,4
    800022e6:	06f70b63          	beq	a4,a5,8000235c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022ee:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022f0:	efb5                	bnez	a5,8000236c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022f2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022f4:	00008917          	auipc	s2,0x8
    800022f8:	ebc90913          	addi	s2,s2,-324 # 8000a1b0 <pid_lock>
    800022fc:	2781                	sext.w	a5,a5
    800022fe:	079e                	slli	a5,a5,0x7
    80002300:	97ca                	add	a5,a5,s2
    80002302:	0ac7a983          	lw	s3,172(a5)
    80002306:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002308:	2781                	sext.w	a5,a5
    8000230a:	079e                	slli	a5,a5,0x7
    8000230c:	00008597          	auipc	a1,0x8
    80002310:	edc58593          	addi	a1,a1,-292 # 8000a1e8 <cpus+0x8>
    80002314:	95be                	add	a1,a1,a5
    80002316:	06048513          	addi	a0,s1,96
    8000231a:	00001097          	auipc	ra,0x1
    8000231e:	8b6080e7          	jalr	-1866(ra) # 80002bd0 <swtch>
    80002322:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002324:	2781                	sext.w	a5,a5
    80002326:	079e                	slli	a5,a5,0x7
    80002328:	97ca                	add	a5,a5,s2
    8000232a:	0b37a623          	sw	s3,172(a5)
}
    8000232e:	70a2                	ld	ra,40(sp)
    80002330:	7402                	ld	s0,32(sp)
    80002332:	64e2                	ld	s1,24(sp)
    80002334:	6942                	ld	s2,16(sp)
    80002336:	69a2                	ld	s3,8(sp)
    80002338:	6145                	addi	sp,sp,48
    8000233a:	8082                	ret
    panic("sched p->lock");
    8000233c:	00006517          	auipc	a0,0x6
    80002340:	f1450513          	addi	a0,a0,-236 # 80008250 <digits+0x210>
    80002344:	ffffe097          	auipc	ra,0xffffe
    80002348:	1fa080e7          	jalr	506(ra) # 8000053e <panic>
    panic("sched locks");
    8000234c:	00006517          	auipc	a0,0x6
    80002350:	f1450513          	addi	a0,a0,-236 # 80008260 <digits+0x220>
    80002354:	ffffe097          	auipc	ra,0xffffe
    80002358:	1ea080e7          	jalr	490(ra) # 8000053e <panic>
    panic("sched running");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	f1450513          	addi	a0,a0,-236 # 80008270 <digits+0x230>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	1da080e7          	jalr	474(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	f1450513          	addi	a0,a0,-236 # 80008280 <digits+0x240>
    80002374:	ffffe097          	auipc	ra,0xffffe
    80002378:	1ca080e7          	jalr	458(ra) # 8000053e <panic>

000000008000237c <yield>:
{
    8000237c:	1101                	addi	sp,sp,-32
    8000237e:	ec06                	sd	ra,24(sp)
    80002380:	e822                	sd	s0,16(sp)
    80002382:	e426                	sd	s1,8(sp)
    80002384:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	642080e7          	jalr	1602(ra) # 800019c8 <myproc>
    8000238e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	854080e7          	jalr	-1964(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002398:	478d                	li	a5,3
    8000239a:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000239c:	00007717          	auipc	a4,0x7
    800023a0:	cbc72703          	lw	a4,-836(a4) # 80009058 <ticks>
    800023a4:	16e4aa23          	sw	a4,372(s1)
  p->last_ticks = ticks - p->start_cpu_burst;
    800023a8:	1704a783          	lw	a5,368(s1)
    800023ac:	9f1d                	subw	a4,a4,a5
    800023ae:	16e4a623          	sw	a4,364(s1)
  p->running_time += p->last_ticks;
    800023b2:	1804a783          	lw	a5,384(s1)
    800023b6:	9fb9                	addw	a5,a5,a4
    800023b8:	18f4a023          	sw	a5,384(s1)
  p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    800023bc:	00006697          	auipc	a3,0x6
    800023c0:	5486a683          	lw	a3,1352(a3) # 80008904 <rate>
    800023c4:	4629                	li	a2,10
    800023c6:	40d607bb          	subw	a5,a2,a3
    800023ca:	1684a583          	lw	a1,360(s1)
    800023ce:	02b787bb          	mulw	a5,a5,a1
    800023d2:	02e6873b          	mulw	a4,a3,a4
    800023d6:	9fb9                	addw	a5,a5,a4
    800023d8:	02c7d7bb          	divuw	a5,a5,a2
    800023dc:	16f4a423          	sw	a5,360(s1)
  sched();
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	ec6080e7          	jalr	-314(ra) # 800022a6 <sched>
  release(&p->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8ae080e7          	jalr	-1874(ra) # 80000c98 <release>
}
    800023f2:	60e2                	ld	ra,24(sp)
    800023f4:	6442                	ld	s0,16(sp)
    800023f6:	64a2                	ld	s1,8(sp)
    800023f8:	6105                	addi	sp,sp,32
    800023fa:	8082                	ret

00000000800023fc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	89aa                	mv	s3,a0
    8000240c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	5ba080e7          	jalr	1466(ra) # 800019c8 <myproc>
    80002416:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7cc080e7          	jalr	1996(ra) # 80000be4 <acquire>
  release(lk);
    80002420:	854a                	mv	a0,s2
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000242a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000242e:	4789                	li	a5,2
    80002430:	cc9c                	sw	a5,24(s1)
  p->start_sleeping = ticks;
    80002432:	00007717          	auipc	a4,0x7
    80002436:	c2672703          	lw	a4,-986(a4) # 80009058 <ticks>
    8000243a:	18e4a223          	sw	a4,388(s1)
  p->last_ticks = ticks - p->start_cpu_burst;
    8000243e:	1704a783          	lw	a5,368(s1)
    80002442:	9f1d                	subw	a4,a4,a5
    80002444:	16e4a623          	sw	a4,364(s1)
  p->running_time += p->last_ticks;
    80002448:	1804a783          	lw	a5,384(s1)
    8000244c:	9fb9                	addw	a5,a5,a4
    8000244e:	18f4a023          	sw	a5,384(s1)
  p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002452:	00006697          	auipc	a3,0x6
    80002456:	4b26a683          	lw	a3,1202(a3) # 80008904 <rate>
    8000245a:	4629                	li	a2,10
    8000245c:	40d607bb          	subw	a5,a2,a3
    80002460:	1684a583          	lw	a1,360(s1)
    80002464:	02b787bb          	mulw	a5,a5,a1
    80002468:	02e6873b          	mulw	a4,a3,a4
    8000246c:	9fb9                	addw	a5,a5,a4
    8000246e:	02c7d7bb          	divuw	a5,a5,a2
    80002472:	16f4a423          	sw	a5,360(s1)
  sched();
    80002476:	00000097          	auipc	ra,0x0
    8000247a:	e30080e7          	jalr	-464(ra) # 800022a6 <sched>

  // Tidy up.
  p->chan = 0;
    8000247e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	814080e7          	jalr	-2028(ra) # 80000c98 <release>
  acquire(lk);
    8000248c:	854a                	mv	a0,s2
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	756080e7          	jalr	1878(ra) # 80000be4 <acquire>
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6145                	addi	sp,sp,48
    800024a2:	8082                	ret

00000000800024a4 <wait>:
{
    800024a4:	715d                	addi	sp,sp,-80
    800024a6:	e486                	sd	ra,72(sp)
    800024a8:	e0a2                	sd	s0,64(sp)
    800024aa:	fc26                	sd	s1,56(sp)
    800024ac:	f84a                	sd	s2,48(sp)
    800024ae:	f44e                	sd	s3,40(sp)
    800024b0:	f052                	sd	s4,32(sp)
    800024b2:	ec56                	sd	s5,24(sp)
    800024b4:	e85a                	sd	s6,16(sp)
    800024b6:	e45e                	sd	s7,8(sp)
    800024b8:	e062                	sd	s8,0(sp)
    800024ba:	0880                	addi	s0,sp,80
    800024bc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	50a080e7          	jalr	1290(ra) # 800019c8 <myproc>
    800024c6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024c8:	00008517          	auipc	a0,0x8
    800024cc:	d0050513          	addi	a0,a0,-768 # 8000a1c8 <wait_lock>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	714080e7          	jalr	1812(ra) # 80000be4 <acquire>
    havekids = 0;
    800024d8:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800024da:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800024dc:	0000e997          	auipc	s3,0xe
    800024e0:	f8498993          	addi	s3,s3,-124 # 80010460 <tickslock>
        havekids = 1;
    800024e4:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024e6:	00008c17          	auipc	s8,0x8
    800024ea:	ce2c0c13          	addi	s8,s8,-798 # 8000a1c8 <wait_lock>
    havekids = 0;
    800024ee:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800024f0:	00008497          	auipc	s1,0x8
    800024f4:	d7048493          	addi	s1,s1,-656 # 8000a260 <proc>
    800024f8:	a0bd                	j	80002566 <wait+0xc2>
          pid = np->pid;
    800024fa:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024fe:	000b0e63          	beqz	s6,8000251a <wait+0x76>
    80002502:	4691                	li	a3,4
    80002504:	02c48613          	addi	a2,s1,44
    80002508:	85da                	mv	a1,s6
    8000250a:	05093503          	ld	a0,80(s2)
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	16c080e7          	jalr	364(ra) # 8000167a <copyout>
    80002516:	02054563          	bltz	a0,80002540 <wait+0x9c>
          freeproc(np);
    8000251a:	8526                	mv	a0,s1
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	65e080e7          	jalr	1630(ra) # 80001b7a <freeproc>
          release(&np->lock);
    80002524:	8526                	mv	a0,s1
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
          release(&wait_lock);
    8000252e:	00008517          	auipc	a0,0x8
    80002532:	c9a50513          	addi	a0,a0,-870 # 8000a1c8 <wait_lock>
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
          return pid;
    8000253e:	a09d                	j	800025a4 <wait+0x100>
            release(&np->lock);
    80002540:	8526                	mv	a0,s1
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	756080e7          	jalr	1878(ra) # 80000c98 <release>
            release(&wait_lock);
    8000254a:	00008517          	auipc	a0,0x8
    8000254e:	c7e50513          	addi	a0,a0,-898 # 8000a1c8 <wait_lock>
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	746080e7          	jalr	1862(ra) # 80000c98 <release>
            return -1;
    8000255a:	59fd                	li	s3,-1
    8000255c:	a0a1                	j	800025a4 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    8000255e:	18848493          	addi	s1,s1,392
    80002562:	03348463          	beq	s1,s3,8000258a <wait+0xe6>
      if (np->parent == p)
    80002566:	7c9c                	ld	a5,56(s1)
    80002568:	ff279be3          	bne	a5,s2,8000255e <wait+0xba>
        acquire(&np->lock);
    8000256c:	8526                	mv	a0,s1
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	676080e7          	jalr	1654(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002576:	4c9c                	lw	a5,24(s1)
    80002578:	f94781e3          	beq	a5,s4,800024fa <wait+0x56>
        release(&np->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	71a080e7          	jalr	1818(ra) # 80000c98 <release>
        havekids = 1;
    80002586:	8756                	mv	a4,s5
    80002588:	bfd9                	j	8000255e <wait+0xba>
    if (!havekids || p->killed)
    8000258a:	c701                	beqz	a4,80002592 <wait+0xee>
    8000258c:	02892783          	lw	a5,40(s2)
    80002590:	c79d                	beqz	a5,800025be <wait+0x11a>
      release(&wait_lock);
    80002592:	00008517          	auipc	a0,0x8
    80002596:	c3650513          	addi	a0,a0,-970 # 8000a1c8 <wait_lock>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
      return -1;
    800025a2:	59fd                	li	s3,-1
}
    800025a4:	854e                	mv	a0,s3
    800025a6:	60a6                	ld	ra,72(sp)
    800025a8:	6406                	ld	s0,64(sp)
    800025aa:	74e2                	ld	s1,56(sp)
    800025ac:	7942                	ld	s2,48(sp)
    800025ae:	79a2                	ld	s3,40(sp)
    800025b0:	7a02                	ld	s4,32(sp)
    800025b2:	6ae2                	ld	s5,24(sp)
    800025b4:	6b42                	ld	s6,16(sp)
    800025b6:	6ba2                	ld	s7,8(sp)
    800025b8:	6c02                	ld	s8,0(sp)
    800025ba:	6161                	addi	sp,sp,80
    800025bc:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025be:	85e2                	mv	a1,s8
    800025c0:	854a                	mv	a0,s2
    800025c2:	00000097          	auipc	ra,0x0
    800025c6:	e3a080e7          	jalr	-454(ra) # 800023fc <sleep>
    havekids = 0;
    800025ca:	b715                	j	800024ee <wait+0x4a>

00000000800025cc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800025cc:	7139                	addi	sp,sp,-64
    800025ce:	fc06                	sd	ra,56(sp)
    800025d0:	f822                	sd	s0,48(sp)
    800025d2:	f426                	sd	s1,40(sp)
    800025d4:	f04a                	sd	s2,32(sp)
    800025d6:	ec4e                	sd	s3,24(sp)
    800025d8:	e852                	sd	s4,16(sp)
    800025da:	e456                	sd	s5,8(sp)
    800025dc:	e05a                	sd	s6,0(sp)
    800025de:	0080                	addi	s0,sp,64
    800025e0:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025e2:	00008497          	auipc	s1,0x8
    800025e6:	c7e48493          	addi	s1,s1,-898 # 8000a260 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800025ea:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800025ec:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    800025ee:	00007a97          	auipc	s5,0x7
    800025f2:	a6aa8a93          	addi	s5,s5,-1430 # 80009058 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800025f6:	0000e917          	auipc	s2,0xe
    800025fa:	e6a90913          	addi	s2,s2,-406 # 80010460 <tickslock>
    800025fe:	a805                	j	8000262e <wakeup+0x62>
        p->state = RUNNABLE;
    80002600:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002604:	000aa703          	lw	a4,0(s5)
    80002608:	16e4aa23          	sw	a4,372(s1)
        p->sleeping_time += ticks - p->start_sleeping;
    8000260c:	1784a783          	lw	a5,376(s1)
    80002610:	9fb9                	addw	a5,a5,a4
    80002612:	1844a703          	lw	a4,388(s1)
    80002616:	9f99                	subw	a5,a5,a4
    80002618:	16f4ac23          	sw	a5,376(s1)
      }
      release(&p->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002626:	18848493          	addi	s1,s1,392
    8000262a:	03248463          	beq	s1,s2,80002652 <wakeup+0x86>
    if (p != myproc())
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	39a080e7          	jalr	922(ra) # 800019c8 <myproc>
    80002636:	fea488e3          	beq	s1,a0,80002626 <wakeup+0x5a>
      acquire(&p->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	5a8080e7          	jalr	1448(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002644:	4c9c                	lw	a5,24(s1)
    80002646:	fd379be3          	bne	a5,s3,8000261c <wakeup+0x50>
    8000264a:	709c                	ld	a5,32(s1)
    8000264c:	fd4798e3          	bne	a5,s4,8000261c <wakeup+0x50>
    80002650:	bf45                	j	80002600 <wakeup+0x34>
    }
  }
}
    80002652:	70e2                	ld	ra,56(sp)
    80002654:	7442                	ld	s0,48(sp)
    80002656:	74a2                	ld	s1,40(sp)
    80002658:	7902                	ld	s2,32(sp)
    8000265a:	69e2                	ld	s3,24(sp)
    8000265c:	6a42                	ld	s4,16(sp)
    8000265e:	6aa2                	ld	s5,8(sp)
    80002660:	6b02                	ld	s6,0(sp)
    80002662:	6121                	addi	sp,sp,64
    80002664:	8082                	ret

0000000080002666 <reparent>:
{
    80002666:	7179                	addi	sp,sp,-48
    80002668:	f406                	sd	ra,40(sp)
    8000266a:	f022                	sd	s0,32(sp)
    8000266c:	ec26                	sd	s1,24(sp)
    8000266e:	e84a                	sd	s2,16(sp)
    80002670:	e44e                	sd	s3,8(sp)
    80002672:	e052                	sd	s4,0(sp)
    80002674:	1800                	addi	s0,sp,48
    80002676:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002678:	00008497          	auipc	s1,0x8
    8000267c:	be848493          	addi	s1,s1,-1048 # 8000a260 <proc>
      pp->parent = initproc;
    80002680:	00007a17          	auipc	s4,0x7
    80002684:	9d0a0a13          	addi	s4,s4,-1584 # 80009050 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002688:	0000e997          	auipc	s3,0xe
    8000268c:	dd898993          	addi	s3,s3,-552 # 80010460 <tickslock>
    80002690:	a029                	j	8000269a <reparent+0x34>
    80002692:	18848493          	addi	s1,s1,392
    80002696:	01348d63          	beq	s1,s3,800026b0 <reparent+0x4a>
    if (pp->parent == p)
    8000269a:	7c9c                	ld	a5,56(s1)
    8000269c:	ff279be3          	bne	a5,s2,80002692 <reparent+0x2c>
      pp->parent = initproc;
    800026a0:	000a3503          	ld	a0,0(s4)
    800026a4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026a6:	00000097          	auipc	ra,0x0
    800026aa:	f26080e7          	jalr	-218(ra) # 800025cc <wakeup>
    800026ae:	b7d5                	j	80002692 <reparent+0x2c>
}
    800026b0:	70a2                	ld	ra,40(sp)
    800026b2:	7402                	ld	s0,32(sp)
    800026b4:	64e2                	ld	s1,24(sp)
    800026b6:	6942                	ld	s2,16(sp)
    800026b8:	69a2                	ld	s3,8(sp)
    800026ba:	6a02                	ld	s4,0(sp)
    800026bc:	6145                	addi	sp,sp,48
    800026be:	8082                	ret

00000000800026c0 <exit>:
{
    800026c0:	7179                	addi	sp,sp,-48
    800026c2:	f406                	sd	ra,40(sp)
    800026c4:	f022                	sd	s0,32(sp)
    800026c6:	ec26                	sd	s1,24(sp)
    800026c8:	e84a                	sd	s2,16(sp)
    800026ca:	e44e                	sd	s3,8(sp)
    800026cc:	e052                	sd	s4,0(sp)
    800026ce:	1800                	addi	s0,sp,48
    800026d0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	2f6080e7          	jalr	758(ra) # 800019c8 <myproc>
    800026da:	892a                	mv	s2,a0
  if (p == initproc)
    800026dc:	00007797          	auipc	a5,0x7
    800026e0:	9747b783          	ld	a5,-1676(a5) # 80009050 <initproc>
    800026e4:	0d050493          	addi	s1,a0,208
    800026e8:	15050993          	addi	s3,a0,336
    800026ec:	02a79363          	bne	a5,a0,80002712 <exit+0x52>
    panic("init exiting");
    800026f0:	00006517          	auipc	a0,0x6
    800026f4:	ba850513          	addi	a0,a0,-1112 # 80008298 <digits+0x258>
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	e46080e7          	jalr	-442(ra) # 8000053e <panic>
      fileclose(f);
    80002700:	00002097          	auipc	ra,0x2
    80002704:	436080e7          	jalr	1078(ra) # 80004b36 <fileclose>
      p->ofile[fd] = 0;
    80002708:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000270c:	04a1                	addi	s1,s1,8
    8000270e:	01348563          	beq	s1,s3,80002718 <exit+0x58>
    if (p->ofile[fd])
    80002712:	6088                	ld	a0,0(s1)
    80002714:	f575                	bnez	a0,80002700 <exit+0x40>
    80002716:	bfdd                	j	8000270c <exit+0x4c>
  begin_op();
    80002718:	00002097          	auipc	ra,0x2
    8000271c:	f52080e7          	jalr	-174(ra) # 8000466a <begin_op>
  iput(p->cwd);
    80002720:	15093503          	ld	a0,336(s2)
    80002724:	00001097          	auipc	ra,0x1
    80002728:	72e080e7          	jalr	1838(ra) # 80003e52 <iput>
  end_op();
    8000272c:	00002097          	auipc	ra,0x2
    80002730:	fbe080e7          	jalr	-66(ra) # 800046ea <end_op>
  p->cwd = 0;
    80002734:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002738:	00008497          	auipc	s1,0x8
    8000273c:	a9048493          	addi	s1,s1,-1392 # 8000a1c8 <wait_lock>
    80002740:	8526                	mv	a0,s1
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	4a2080e7          	jalr	1186(ra) # 80000be4 <acquire>
  reparent(p);
    8000274a:	854a                	mv	a0,s2
    8000274c:	00000097          	auipc	ra,0x0
    80002750:	f1a080e7          	jalr	-230(ra) # 80002666 <reparent>
  wakeup(p->parent);
    80002754:	03893503          	ld	a0,56(s2)
    80002758:	00000097          	auipc	ra,0x0
    8000275c:	e74080e7          	jalr	-396(ra) # 800025cc <wakeup>
  acquire(&p->lock);
    80002760:	854a                	mv	a0,s2
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	482080e7          	jalr	1154(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000276a:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000276e:	4795                	li	a5,5
    80002770:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	522080e7          	jalr	1314(ra) # 80000c98 <release>
  num_processes++;
    8000277e:	00007797          	auipc	a5,0x7
    80002782:	8b678793          	addi	a5,a5,-1866 # 80009034 <num_processes>
    80002786:	438c                	lw	a1,0(a5)
    80002788:	0015861b          	addiw	a2,a1,1
    8000278c:	c390                	sw	a2,0(a5)
  p->running_time += ticks - p->start_cpu_burst;
    8000278e:	00007517          	auipc	a0,0x7
    80002792:	8ca52503          	lw	a0,-1846(a0) # 80009058 <ticks>
    80002796:	18092683          	lw	a3,384(s2)
    8000279a:	9ea9                	addw	a3,a3,a0
    8000279c:	17092783          	lw	a5,368(s2)
    800027a0:	9e9d                	subw	a3,a3,a5
    800027a2:	18d92023          	sw	a3,384(s2)
  sleeping_processes_mean = ((sleeping_processes_mean * (num_processes - 1)) + p->sleeping_time) / (num_processes);
    800027a6:	00007797          	auipc	a5,0x7
    800027aa:	8a278793          	addi	a5,a5,-1886 # 80009048 <sleeping_processes_mean>
    800027ae:	4398                	lw	a4,0(a5)
    800027b0:	02b7073b          	mulw	a4,a4,a1
    800027b4:	17892803          	lw	a6,376(s2)
    800027b8:	0107073b          	addw	a4,a4,a6
    800027bc:	02c7573b          	divuw	a4,a4,a2
    800027c0:	c398                	sw	a4,0(a5)
  running_processes_mean = ((running_processes_mean * (num_processes - 1)) + p->running_time) / (num_processes);
    800027c2:	00007797          	auipc	a5,0x7
    800027c6:	88278793          	addi	a5,a5,-1918 # 80009044 <running_processes_mean>
    800027ca:	4398                	lw	a4,0(a5)
    800027cc:	02b7073b          	mulw	a4,a4,a1
    800027d0:	9f35                	addw	a4,a4,a3
    800027d2:	02c7573b          	divuw	a4,a4,a2
    800027d6:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ((runnable_processes_mean * (num_processes - 1)) + p->runnable_time) / (num_processes);
    800027d8:	00007717          	auipc	a4,0x7
    800027dc:	86870713          	addi	a4,a4,-1944 # 80009040 <runnable_processes_mean>
    800027e0:	431c                	lw	a5,0(a4)
    800027e2:	02b787bb          	mulw	a5,a5,a1
    800027e6:	17c92583          	lw	a1,380(s2)
    800027ea:	9fad                	addw	a5,a5,a1
    800027ec:	02c7d7bb          	divuw	a5,a5,a2
    800027f0:	c31c                	sw	a5,0(a4)
  if (p->pid != 1 && p->pid != 2)
    800027f2:	03092783          	lw	a5,48(s2)
    800027f6:	37fd                	addiw	a5,a5,-1
    800027f8:	4705                	li	a4,1
    800027fa:	02f77863          	bgeu	a4,a5,8000282a <exit+0x16a>
    program_time += p->running_time;
    800027fe:	00007717          	auipc	a4,0x7
    80002802:	83270713          	addi	a4,a4,-1998 # 80009030 <program_time>
    80002806:	431c                	lw	a5,0(a4)
    80002808:	9fb5                	addw	a5,a5,a3
    8000280a:	c31c                	sw	a5,0(a4)
    cpu_utilization = (program_time * 100) / (ticks - start_time);
    8000280c:	06400693          	li	a3,100
    80002810:	02f686bb          	mulw	a3,a3,a5
    80002814:	00007797          	auipc	a5,0x7
    80002818:	8147a783          	lw	a5,-2028(a5) # 80009028 <start_time>
    8000281c:	9d1d                	subw	a0,a0,a5
    8000281e:	02a6d53b          	divuw	a0,a3,a0
    80002822:	00007797          	auipc	a5,0x7
    80002826:	80a7a523          	sw	a0,-2038(a5) # 8000902c <cpu_utilization>
  sched();
    8000282a:	00000097          	auipc	ra,0x0
    8000282e:	a7c080e7          	jalr	-1412(ra) # 800022a6 <sched>
  panic("zombie exit");
    80002832:	00006517          	auipc	a0,0x6
    80002836:	a7650513          	addi	a0,a0,-1418 # 800082a8 <digits+0x268>
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	d04080e7          	jalr	-764(ra) # 8000053e <panic>

0000000080002842 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002842:	7179                	addi	sp,sp,-48
    80002844:	f406                	sd	ra,40(sp)
    80002846:	f022                	sd	s0,32(sp)
    80002848:	ec26                	sd	s1,24(sp)
    8000284a:	e84a                	sd	s2,16(sp)
    8000284c:	e44e                	sd	s3,8(sp)
    8000284e:	1800                	addi	s0,sp,48
    80002850:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002852:	00008497          	auipc	s1,0x8
    80002856:	a0e48493          	addi	s1,s1,-1522 # 8000a260 <proc>
    8000285a:	0000e997          	auipc	s3,0xe
    8000285e:	c0698993          	addi	s3,s3,-1018 # 80010460 <tickslock>
  {
    acquire(&p->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	380080e7          	jalr	896(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000286c:	589c                	lw	a5,48(s1)
    8000286e:	01278d63          	beq	a5,s2,80002888 <kill+0x46>
        p->sleeping_time += ticks - p->start_sleeping;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002872:	8526                	mv	a0,s1
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000287c:	18848493          	addi	s1,s1,392
    80002880:	ff3491e3          	bne	s1,s3,80002862 <kill+0x20>
  }
  return -1;
    80002884:	557d                	li	a0,-1
    80002886:	a829                	j	800028a0 <kill+0x5e>
      p->killed = 1;
    80002888:	4785                	li	a5,1
    8000288a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000288c:	4c98                	lw	a4,24(s1)
    8000288e:	4789                	li	a5,2
    80002890:	00f70f63          	beq	a4,a5,800028ae <kill+0x6c>
      release(&p->lock);
    80002894:	8526                	mv	a0,s1
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	402080e7          	jalr	1026(ra) # 80000c98 <release>
      return 0;
    8000289e:	4501                	li	a0,0
}
    800028a0:	70a2                	ld	ra,40(sp)
    800028a2:	7402                	ld	s0,32(sp)
    800028a4:	64e2                	ld	s1,24(sp)
    800028a6:	6942                	ld	s2,16(sp)
    800028a8:	69a2                	ld	s3,8(sp)
    800028aa:	6145                	addi	sp,sp,48
    800028ac:	8082                	ret
        p->state = RUNNABLE;
    800028ae:	478d                	li	a5,3
    800028b0:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    800028b2:	00006717          	auipc	a4,0x6
    800028b6:	7a672703          	lw	a4,1958(a4) # 80009058 <ticks>
    800028ba:	16e4aa23          	sw	a4,372(s1)
        p->sleeping_time += ticks - p->start_sleeping;
    800028be:	1784a783          	lw	a5,376(s1)
    800028c2:	9fb9                	addw	a5,a5,a4
    800028c4:	1844a703          	lw	a4,388(s1)
    800028c8:	9f99                	subw	a5,a5,a4
    800028ca:	16f4ac23          	sw	a5,376(s1)
    800028ce:	b7d9                	j	80002894 <kill+0x52>

00000000800028d0 <kill_system>:

int kill_system()
{
    800028d0:	711d                	addi	sp,sp,-96
    800028d2:	ec86                	sd	ra,88(sp)
    800028d4:	e8a2                	sd	s0,80(sp)
    800028d6:	e4a6                	sd	s1,72(sp)
    800028d8:	e0ca                	sd	s2,64(sp)
    800028da:	fc4e                	sd	s3,56(sp)
    800028dc:	f852                	sd	s4,48(sp)
    800028de:	f456                	sd	s5,40(sp)
    800028e0:	f05a                	sd	s6,32(sp)
    800028e2:	ec5e                	sd	s7,24(sp)
    800028e4:	e862                	sd	s8,16(sp)
    800028e6:	e466                	sd	s9,8(sp)
    800028e8:	1080                	addi	s0,sp,96
  struct proc *myp = myproc();
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	0de080e7          	jalr	222(ra) # 800019c8 <myproc>
    800028f2:	8caa                	mv	s9,a0
  int mypid = myp->pid;
    800028f4:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	2ec080e7          	jalr	748(ra) # 80000be4 <acquire>
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002900:	00008497          	auipc	s1,0x8
    80002904:	96048493          	addi	s1,s1,-1696 # 8000a260 <proc>
  {
    if (p->pid != mypid)
    {
      acquire(&p->lock);
      if (p->pid != 1 && p->pid != 2)
    80002908:	4a05                	li	s4,1
      {
        p->killed = 1;
    8000290a:	4b05                	li	s6,1
        if (p->state == SLEEPING)
    8000290c:	4a89                	li	s5,2
        {
          // Wake process from sleep().
          p->state = RUNNABLE;
    8000290e:	4c0d                	li	s8,3
          p->last_runnable_time = ticks;
    80002910:	00006b97          	auipc	s7,0x6
    80002914:	748b8b93          	addi	s7,s7,1864 # 80009058 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002918:	0000e917          	auipc	s2,0xe
    8000291c:	b4890913          	addi	s2,s2,-1208 # 80010460 <tickslock>
    80002920:	a811                	j	80002934 <kill_system+0x64>
          p->sleeping_time += ticks - p->start_sleeping;
        }
      }
      release(&p->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	374080e7          	jalr	884(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000292c:	18848493          	addi	s1,s1,392
    80002930:	05248263          	beq	s1,s2,80002974 <kill_system+0xa4>
    if (p->pid != mypid)
    80002934:	589c                	lw	a5,48(s1)
    80002936:	ff378be3          	beq	a5,s3,8000292c <kill_system+0x5c>
      acquire(&p->lock);
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	2a8080e7          	jalr	680(ra) # 80000be4 <acquire>
      if (p->pid != 1 && p->pid != 2)
    80002944:	589c                	lw	a5,48(s1)
    80002946:	37fd                	addiw	a5,a5,-1
    80002948:	fcfa7de3          	bgeu	s4,a5,80002922 <kill_system+0x52>
        p->killed = 1;
    8000294c:	0364a423          	sw	s6,40(s1)
        if (p->state == SLEEPING)
    80002950:	4c9c                	lw	a5,24(s1)
    80002952:	fd5798e3          	bne	a5,s5,80002922 <kill_system+0x52>
          p->state = RUNNABLE;
    80002956:	0184ac23          	sw	s8,24(s1)
          p->last_runnable_time = ticks;
    8000295a:	000ba703          	lw	a4,0(s7)
    8000295e:	16e4aa23          	sw	a4,372(s1)
          p->sleeping_time += ticks - p->start_sleeping;
    80002962:	1784a783          	lw	a5,376(s1)
    80002966:	9fb9                	addw	a5,a5,a4
    80002968:	1844a703          	lw	a4,388(s1)
    8000296c:	9f99                	subw	a5,a5,a4
    8000296e:	16f4ac23          	sw	a5,376(s1)
    80002972:	bf45                	j	80002922 <kill_system+0x52>
    }
  }

  myp->killed = 1;
    80002974:	4785                	li	a5,1
    80002976:	02fca423          	sw	a5,40(s9)
  release(&myp->lock);
    8000297a:	8566                	mv	a0,s9
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	31c080e7          	jalr	796(ra) # 80000c98 <release>
  return 0;
}
    80002984:	4501                	li	a0,0
    80002986:	60e6                	ld	ra,88(sp)
    80002988:	6446                	ld	s0,80(sp)
    8000298a:	64a6                	ld	s1,72(sp)
    8000298c:	6906                	ld	s2,64(sp)
    8000298e:	79e2                	ld	s3,56(sp)
    80002990:	7a42                	ld	s4,48(sp)
    80002992:	7aa2                	ld	s5,40(sp)
    80002994:	7b02                	ld	s6,32(sp)
    80002996:	6be2                	ld	s7,24(sp)
    80002998:	6c42                	ld	s8,16(sp)
    8000299a:	6ca2                	ld	s9,8(sp)
    8000299c:	6125                	addi	sp,sp,96
    8000299e:	8082                	ret

00000000800029a0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029a0:	7179                	addi	sp,sp,-48
    800029a2:	f406                	sd	ra,40(sp)
    800029a4:	f022                	sd	s0,32(sp)
    800029a6:	ec26                	sd	s1,24(sp)
    800029a8:	e84a                	sd	s2,16(sp)
    800029aa:	e44e                	sd	s3,8(sp)
    800029ac:	e052                	sd	s4,0(sp)
    800029ae:	1800                	addi	s0,sp,48
    800029b0:	84aa                	mv	s1,a0
    800029b2:	892e                	mv	s2,a1
    800029b4:	89b2                	mv	s3,a2
    800029b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	010080e7          	jalr	16(ra) # 800019c8 <myproc>
  if (user_dst)
    800029c0:	c08d                	beqz	s1,800029e2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800029c2:	86d2                	mv	a3,s4
    800029c4:	864e                	mv	a2,s3
    800029c6:	85ca                	mv	a1,s2
    800029c8:	6928                	ld	a0,80(a0)
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	cb0080e7          	jalr	-848(ra) # 8000167a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029d2:	70a2                	ld	ra,40(sp)
    800029d4:	7402                	ld	s0,32(sp)
    800029d6:	64e2                	ld	s1,24(sp)
    800029d8:	6942                	ld	s2,16(sp)
    800029da:	69a2                	ld	s3,8(sp)
    800029dc:	6a02                	ld	s4,0(sp)
    800029de:	6145                	addi	sp,sp,48
    800029e0:	8082                	ret
    memmove((char *)dst, src, len);
    800029e2:	000a061b          	sext.w	a2,s4
    800029e6:	85ce                	mv	a1,s3
    800029e8:	854a                	mv	a0,s2
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	356080e7          	jalr	854(ra) # 80000d40 <memmove>
    return 0;
    800029f2:	8526                	mv	a0,s1
    800029f4:	bff9                	j	800029d2 <either_copyout+0x32>

00000000800029f6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029f6:	7179                	addi	sp,sp,-48
    800029f8:	f406                	sd	ra,40(sp)
    800029fa:	f022                	sd	s0,32(sp)
    800029fc:	ec26                	sd	s1,24(sp)
    800029fe:	e84a                	sd	s2,16(sp)
    80002a00:	e44e                	sd	s3,8(sp)
    80002a02:	e052                	sd	s4,0(sp)
    80002a04:	1800                	addi	s0,sp,48
    80002a06:	892a                	mv	s2,a0
    80002a08:	84ae                	mv	s1,a1
    80002a0a:	89b2                	mv	s3,a2
    80002a0c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a0e:	fffff097          	auipc	ra,0xfffff
    80002a12:	fba080e7          	jalr	-70(ra) # 800019c8 <myproc>
  if (user_src)
    80002a16:	c08d                	beqz	s1,80002a38 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a18:	86d2                	mv	a3,s4
    80002a1a:	864e                	mv	a2,s3
    80002a1c:	85ca                	mv	a1,s2
    80002a1e:	6928                	ld	a0,80(a0)
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	ce6080e7          	jalr	-794(ra) # 80001706 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a28:	70a2                	ld	ra,40(sp)
    80002a2a:	7402                	ld	s0,32(sp)
    80002a2c:	64e2                	ld	s1,24(sp)
    80002a2e:	6942                	ld	s2,16(sp)
    80002a30:	69a2                	ld	s3,8(sp)
    80002a32:	6a02                	ld	s4,0(sp)
    80002a34:	6145                	addi	sp,sp,48
    80002a36:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a38:	000a061b          	sext.w	a2,s4
    80002a3c:	85ce                	mv	a1,s3
    80002a3e:	854a                	mv	a0,s2
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	300080e7          	jalr	768(ra) # 80000d40 <memmove>
    return 0;
    80002a48:	8526                	mv	a0,s1
    80002a4a:	bff9                	j	80002a28 <either_copyin+0x32>

0000000080002a4c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a4c:	715d                	addi	sp,sp,-80
    80002a4e:	e486                	sd	ra,72(sp)
    80002a50:	e0a2                	sd	s0,64(sp)
    80002a52:	fc26                	sd	s1,56(sp)
    80002a54:	f84a                	sd	s2,48(sp)
    80002a56:	f44e                	sd	s3,40(sp)
    80002a58:	f052                	sd	s4,32(sp)
    80002a5a:	ec56                	sd	s5,24(sp)
    80002a5c:	e85a                	sd	s6,16(sp)
    80002a5e:	e45e                	sd	s7,8(sp)
    80002a60:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	8fe50513          	addi	a0,a0,-1794 # 80008360 <digits+0x320>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b1e080e7          	jalr	-1250(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a72:	00008497          	auipc	s1,0x8
    80002a76:	94648493          	addi	s1,s1,-1722 # 8000a3b8 <proc+0x158>
    80002a7a:	0000e917          	auipc	s2,0xe
    80002a7e:	b3e90913          	addi	s2,s2,-1218 # 800105b8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a82:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a84:	00006997          	auipc	s3,0x6
    80002a88:	83498993          	addi	s3,s3,-1996 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    80002a8c:	00006a97          	auipc	s5,0x6
    80002a90:	834a8a93          	addi	s5,s5,-1996 # 800082c0 <digits+0x280>
    printf("\n");
    80002a94:	00006a17          	auipc	s4,0x6
    80002a98:	8cca0a13          	addi	s4,s4,-1844 # 80008360 <digits+0x320>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a9c:	00006b97          	auipc	s7,0x6
    80002aa0:	8f4b8b93          	addi	s7,s7,-1804 # 80008390 <states.1871>
    80002aa4:	a00d                	j	80002ac6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002aa6:	ed86a583          	lw	a1,-296(a3)
    80002aaa:	8556                	mv	a0,s5
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	adc080e7          	jalr	-1316(ra) # 80000588 <printf>
    printf("\n");
    80002ab4:	8552                	mv	a0,s4
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	ad2080e7          	jalr	-1326(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002abe:	18848493          	addi	s1,s1,392
    80002ac2:	03248163          	beq	s1,s2,80002ae4 <procdump+0x98>
    if (p->state == UNUSED)
    80002ac6:	86a6                	mv	a3,s1
    80002ac8:	ec04a783          	lw	a5,-320(s1)
    80002acc:	dbed                	beqz	a5,80002abe <procdump+0x72>
      state = "???";
    80002ace:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ad0:	fcfb6be3          	bltu	s6,a5,80002aa6 <procdump+0x5a>
    80002ad4:	1782                	slli	a5,a5,0x20
    80002ad6:	9381                	srli	a5,a5,0x20
    80002ad8:	078e                	slli	a5,a5,0x3
    80002ada:	97de                	add	a5,a5,s7
    80002adc:	6390                	ld	a2,0(a5)
    80002ade:	f661                	bnez	a2,80002aa6 <procdump+0x5a>
      state = "???";
    80002ae0:	864e                	mv	a2,s3
    80002ae2:	b7d1                	j	80002aa6 <procdump+0x5a>
  }
}
    80002ae4:	60a6                	ld	ra,72(sp)
    80002ae6:	6406                	ld	s0,64(sp)
    80002ae8:	74e2                	ld	s1,56(sp)
    80002aea:	7942                	ld	s2,48(sp)
    80002aec:	79a2                	ld	s3,40(sp)
    80002aee:	7a02                	ld	s4,32(sp)
    80002af0:	6ae2                	ld	s5,24(sp)
    80002af2:	6b42                	ld	s6,16(sp)
    80002af4:	6ba2                	ld	s7,8(sp)
    80002af6:	6161                	addi	sp,sp,80
    80002af8:	8082                	ret

0000000080002afa <pause_system>:

int pause_system(int seconds)
{
    80002afa:	1141                	addi	sp,sp,-16
    80002afc:	e406                	sd	ra,8(sp)
    80002afe:	e022                	sd	s0,0(sp)
    80002b00:	0800                	addi	s0,sp,16
  pause_time = ticks + seconds * 10;
    80002b02:	0025179b          	slliw	a5,a0,0x2
    80002b06:	9fa9                	addw	a5,a5,a0
    80002b08:	0017979b          	slliw	a5,a5,0x1
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	54c52503          	lw	a0,1356(a0) # 80009058 <ticks>
    80002b14:	9fa9                	addw	a5,a5,a0
    80002b16:	00006717          	auipc	a4,0x6
    80002b1a:	52f72b23          	sw	a5,1334(a4) # 8000904c <pause_time>
  yield();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	85e080e7          	jalr	-1954(ra) # 8000237c <yield>
  return 0;
}
    80002b26:	4501                	li	a0,0
    80002b28:	60a2                	ld	ra,8(sp)
    80002b2a:	6402                	ld	s0,0(sp)
    80002b2c:	0141                	addi	sp,sp,16
    80002b2e:	8082                	ret

0000000080002b30 <print_stats>:

void print_stats(void)
{
    80002b30:	1141                	addi	sp,sp,-16
    80002b32:	e406                	sd	ra,8(sp)
    80002b34:	e022                	sd	s0,0(sp)
    80002b36:	0800                	addi	s0,sp,16
  printf("Mean running time: %d\n", running_processes_mean);
    80002b38:	00006597          	auipc	a1,0x6
    80002b3c:	50c5a583          	lw	a1,1292(a1) # 80009044 <running_processes_mean>
    80002b40:	00005517          	auipc	a0,0x5
    80002b44:	79050513          	addi	a0,a0,1936 # 800082d0 <digits+0x290>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	a40080e7          	jalr	-1472(ra) # 80000588 <printf>
  printf("Number of processes: %d\n", num_processes);
    80002b50:	00006597          	auipc	a1,0x6
    80002b54:	4e45a583          	lw	a1,1252(a1) # 80009034 <num_processes>
    80002b58:	00005517          	auipc	a0,0x5
    80002b5c:	79050513          	addi	a0,a0,1936 # 800082e8 <digits+0x2a8>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	a28080e7          	jalr	-1496(ra) # 80000588 <printf>
  printf("Mean runnable time: %d\n", runnable_processes_mean);
    80002b68:	00006597          	auipc	a1,0x6
    80002b6c:	4d85a583          	lw	a1,1240(a1) # 80009040 <runnable_processes_mean>
    80002b70:	00005517          	auipc	a0,0x5
    80002b74:	79850513          	addi	a0,a0,1944 # 80008308 <digits+0x2c8>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a10080e7          	jalr	-1520(ra) # 80000588 <printf>
  printf("Mean sleeping time: %d\n", sleeping_processes_mean);
    80002b80:	00006597          	auipc	a1,0x6
    80002b84:	4c85a583          	lw	a1,1224(a1) # 80009048 <sleeping_processes_mean>
    80002b88:	00005517          	auipc	a0,0x5
    80002b8c:	79850513          	addi	a0,a0,1944 # 80008320 <digits+0x2e0>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9f8080e7          	jalr	-1544(ra) # 80000588 <printf>
  printf("CPU utilization: %d\n", cpu_utilization);
    80002b98:	00006597          	auipc	a1,0x6
    80002b9c:	4945a583          	lw	a1,1172(a1) # 8000902c <cpu_utilization>
    80002ba0:	00005517          	auipc	a0,0x5
    80002ba4:	79850513          	addi	a0,a0,1944 # 80008338 <digits+0x2f8>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9e0080e7          	jalr	-1568(ra) # 80000588 <printf>
  printf("Program time: %d\n", program_time);
    80002bb0:	00006597          	auipc	a1,0x6
    80002bb4:	4805a583          	lw	a1,1152(a1) # 80009030 <program_time>
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	79850513          	addi	a0,a0,1944 # 80008350 <digits+0x310>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9c8080e7          	jalr	-1592(ra) # 80000588 <printf>
    80002bc8:	60a2                	ld	ra,8(sp)
    80002bca:	6402                	ld	s0,0(sp)
    80002bcc:	0141                	addi	sp,sp,16
    80002bce:	8082                	ret

0000000080002bd0 <swtch>:
    80002bd0:	00153023          	sd	ra,0(a0)
    80002bd4:	00253423          	sd	sp,8(a0)
    80002bd8:	e900                	sd	s0,16(a0)
    80002bda:	ed04                	sd	s1,24(a0)
    80002bdc:	03253023          	sd	s2,32(a0)
    80002be0:	03353423          	sd	s3,40(a0)
    80002be4:	03453823          	sd	s4,48(a0)
    80002be8:	03553c23          	sd	s5,56(a0)
    80002bec:	05653023          	sd	s6,64(a0)
    80002bf0:	05753423          	sd	s7,72(a0)
    80002bf4:	05853823          	sd	s8,80(a0)
    80002bf8:	05953c23          	sd	s9,88(a0)
    80002bfc:	07a53023          	sd	s10,96(a0)
    80002c00:	07b53423          	sd	s11,104(a0)
    80002c04:	0005b083          	ld	ra,0(a1)
    80002c08:	0085b103          	ld	sp,8(a1)
    80002c0c:	6980                	ld	s0,16(a1)
    80002c0e:	6d84                	ld	s1,24(a1)
    80002c10:	0205b903          	ld	s2,32(a1)
    80002c14:	0285b983          	ld	s3,40(a1)
    80002c18:	0305ba03          	ld	s4,48(a1)
    80002c1c:	0385ba83          	ld	s5,56(a1)
    80002c20:	0405bb03          	ld	s6,64(a1)
    80002c24:	0485bb83          	ld	s7,72(a1)
    80002c28:	0505bc03          	ld	s8,80(a1)
    80002c2c:	0585bc83          	ld	s9,88(a1)
    80002c30:	0605bd03          	ld	s10,96(a1)
    80002c34:	0685bd83          	ld	s11,104(a1)
    80002c38:	8082                	ret

0000000080002c3a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c3a:	1141                	addi	sp,sp,-16
    80002c3c:	e406                	sd	ra,8(sp)
    80002c3e:	e022                	sd	s0,0(sp)
    80002c40:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c42:	00005597          	auipc	a1,0x5
    80002c46:	77e58593          	addi	a1,a1,1918 # 800083c0 <states.1871+0x30>
    80002c4a:	0000e517          	auipc	a0,0xe
    80002c4e:	81650513          	addi	a0,a0,-2026 # 80010460 <tickslock>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	f02080e7          	jalr	-254(ra) # 80000b54 <initlock>
}
    80002c5a:	60a2                	ld	ra,8(sp)
    80002c5c:	6402                	ld	s0,0(sp)
    80002c5e:	0141                	addi	sp,sp,16
    80002c60:	8082                	ret

0000000080002c62 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c62:	1141                	addi	sp,sp,-16
    80002c64:	e422                	sd	s0,8(sp)
    80002c66:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c68:	00003797          	auipc	a5,0x3
    80002c6c:	4e878793          	addi	a5,a5,1256 # 80006150 <kernelvec>
    80002c70:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c74:	6422                	ld	s0,8(sp)
    80002c76:	0141                	addi	sp,sp,16
    80002c78:	8082                	ret

0000000080002c7a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c7a:	1141                	addi	sp,sp,-16
    80002c7c:	e406                	sd	ra,8(sp)
    80002c7e:	e022                	sd	s0,0(sp)
    80002c80:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	d46080e7          	jalr	-698(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c8e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c90:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c94:	00004617          	auipc	a2,0x4
    80002c98:	36c60613          	addi	a2,a2,876 # 80007000 <_trampoline>
    80002c9c:	00004697          	auipc	a3,0x4
    80002ca0:	36468693          	addi	a3,a3,868 # 80007000 <_trampoline>
    80002ca4:	8e91                	sub	a3,a3,a2
    80002ca6:	040007b7          	lui	a5,0x4000
    80002caa:	17fd                	addi	a5,a5,-1
    80002cac:	07b2                	slli	a5,a5,0xc
    80002cae:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cb0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cb4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cb6:	180026f3          	csrr	a3,satp
    80002cba:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cbc:	6d38                	ld	a4,88(a0)
    80002cbe:	6134                	ld	a3,64(a0)
    80002cc0:	6585                	lui	a1,0x1
    80002cc2:	96ae                	add	a3,a3,a1
    80002cc4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cc6:	6d38                	ld	a4,88(a0)
    80002cc8:	00000697          	auipc	a3,0x0
    80002ccc:	13868693          	addi	a3,a3,312 # 80002e00 <usertrap>
    80002cd0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cd2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cd4:	8692                	mv	a3,tp
    80002cd6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cdc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ce0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ce8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cea:	6f18                	ld	a4,24(a4)
    80002cec:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cf0:	692c                	ld	a1,80(a0)
    80002cf2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cf4:	00004717          	auipc	a4,0x4
    80002cf8:	39c70713          	addi	a4,a4,924 # 80007090 <userret>
    80002cfc:	8f11                	sub	a4,a4,a2
    80002cfe:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d00:	577d                	li	a4,-1
    80002d02:	177e                	slli	a4,a4,0x3f
    80002d04:	8dd9                	or	a1,a1,a4
    80002d06:	02000537          	lui	a0,0x2000
    80002d0a:	157d                	addi	a0,a0,-1
    80002d0c:	0536                	slli	a0,a0,0xd
    80002d0e:	9782                	jalr	a5
}
    80002d10:	60a2                	ld	ra,8(sp)
    80002d12:	6402                	ld	s0,0(sp)
    80002d14:	0141                	addi	sp,sp,16
    80002d16:	8082                	ret

0000000080002d18 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d22:	0000d497          	auipc	s1,0xd
    80002d26:	73e48493          	addi	s1,s1,1854 # 80010460 <tickslock>
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	eb8080e7          	jalr	-328(ra) # 80000be4 <acquire>
  ticks++;
    80002d34:	00006517          	auipc	a0,0x6
    80002d38:	32450513          	addi	a0,a0,804 # 80009058 <ticks>
    80002d3c:	411c                	lw	a5,0(a0)
    80002d3e:	2785                	addiw	a5,a5,1
    80002d40:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	88a080e7          	jalr	-1910(ra) # 800025cc <wakeup>
  release(&tickslock);
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	ffffe097          	auipc	ra,0xffffe
    80002d50:	f4c080e7          	jalr	-180(ra) # 80000c98 <release>
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret

0000000080002d5e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d68:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d6c:	00074d63          	bltz	a4,80002d86 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d70:	57fd                	li	a5,-1
    80002d72:	17fe                	slli	a5,a5,0x3f
    80002d74:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d76:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d78:	06f70363          	beq	a4,a5,80002dde <devintr+0x80>
  }
}
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret
     (scause & 0xff) == 9){
    80002d86:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d8a:	46a5                	li	a3,9
    80002d8c:	fed792e3          	bne	a5,a3,80002d70 <devintr+0x12>
    int irq = plic_claim();
    80002d90:	00003097          	auipc	ra,0x3
    80002d94:	4c8080e7          	jalr	1224(ra) # 80006258 <plic_claim>
    80002d98:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d9a:	47a9                	li	a5,10
    80002d9c:	02f50763          	beq	a0,a5,80002dca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002da0:	4785                	li	a5,1
    80002da2:	02f50963          	beq	a0,a5,80002dd4 <devintr+0x76>
    return 1;
    80002da6:	4505                	li	a0,1
    } else if(irq){
    80002da8:	d8f1                	beqz	s1,80002d7c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002daa:	85a6                	mv	a1,s1
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	61c50513          	addi	a0,a0,1564 # 800083c8 <states.1871+0x38>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	7d4080e7          	jalr	2004(ra) # 80000588 <printf>
      plic_complete(irq);
    80002dbc:	8526                	mv	a0,s1
    80002dbe:	00003097          	auipc	ra,0x3
    80002dc2:	4be080e7          	jalr	1214(ra) # 8000627c <plic_complete>
    return 1;
    80002dc6:	4505                	li	a0,1
    80002dc8:	bf55                	j	80002d7c <devintr+0x1e>
      uartintr();
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	bde080e7          	jalr	-1058(ra) # 800009a8 <uartintr>
    80002dd2:	b7ed                	j	80002dbc <devintr+0x5e>
      virtio_disk_intr();
    80002dd4:	00004097          	auipc	ra,0x4
    80002dd8:	988080e7          	jalr	-1656(ra) # 8000675c <virtio_disk_intr>
    80002ddc:	b7c5                	j	80002dbc <devintr+0x5e>
    if(cpuid() == 0){
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	bbe080e7          	jalr	-1090(ra) # 8000199c <cpuid>
    80002de6:	c901                	beqz	a0,80002df6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002de8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dee:	14479073          	csrw	sip,a5
    return 2;
    80002df2:	4509                	li	a0,2
    80002df4:	b761                	j	80002d7c <devintr+0x1e>
      clockintr();
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	f22080e7          	jalr	-222(ra) # 80002d18 <clockintr>
    80002dfe:	b7ed                	j	80002de8 <devintr+0x8a>

0000000080002e00 <usertrap>:
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	e426                	sd	s1,8(sp)
    80002e08:	e04a                	sd	s2,0(sp)
    80002e0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e10:	1007f793          	andi	a5,a5,256
    80002e14:	e3ad                	bnez	a5,80002e76 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e16:	00003797          	auipc	a5,0x3
    80002e1a:	33a78793          	addi	a5,a5,826 # 80006150 <kernelvec>
    80002e1e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	ba6080e7          	jalr	-1114(ra) # 800019c8 <myproc>
    80002e2a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e2c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e2e:	14102773          	csrr	a4,sepc
    80002e32:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e34:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e38:	47a1                	li	a5,8
    80002e3a:	04f71c63          	bne	a4,a5,80002e92 <usertrap+0x92>
    if(p->killed)
    80002e3e:	551c                	lw	a5,40(a0)
    80002e40:	e3b9                	bnez	a5,80002e86 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e42:	6cb8                	ld	a4,88(s1)
    80002e44:	6f1c                	ld	a5,24(a4)
    80002e46:	0791                	addi	a5,a5,4
    80002e48:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e4a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e4e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e52:	10079073          	csrw	sstatus,a5
    syscall();
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	2e0080e7          	jalr	736(ra) # 80003136 <syscall>
  if(p->killed)
    80002e5e:	549c                	lw	a5,40(s1)
    80002e60:	ebc1                	bnez	a5,80002ef0 <usertrap+0xf0>
  usertrapret();
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	e18080e7          	jalr	-488(ra) # 80002c7a <usertrapret>
}
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	64a2                	ld	s1,8(sp)
    80002e70:	6902                	ld	s2,0(sp)
    80002e72:	6105                	addi	sp,sp,32
    80002e74:	8082                	ret
    panic("usertrap: not from user mode");
    80002e76:	00005517          	auipc	a0,0x5
    80002e7a:	57250513          	addi	a0,a0,1394 # 800083e8 <states.1871+0x58>
    80002e7e:	ffffd097          	auipc	ra,0xffffd
    80002e82:	6c0080e7          	jalr	1728(ra) # 8000053e <panic>
      exit(-1);
    80002e86:	557d                	li	a0,-1
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	838080e7          	jalr	-1992(ra) # 800026c0 <exit>
    80002e90:	bf4d                	j	80002e42 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	ecc080e7          	jalr	-308(ra) # 80002d5e <devintr>
    80002e9a:	892a                	mv	s2,a0
    80002e9c:	c501                	beqz	a0,80002ea4 <usertrap+0xa4>
  if(p->killed)
    80002e9e:	549c                	lw	a5,40(s1)
    80002ea0:	c3a1                	beqz	a5,80002ee0 <usertrap+0xe0>
    80002ea2:	a815                	j	80002ed6 <usertrap+0xd6>
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
    80002edc:	7e8080e7          	jalr	2024(ra) # 800026c0 <exit>
  if(which_dev == 2){
    80002ee0:	4789                	li	a5,2
    80002ee2:	f8f910e3          	bne	s2,a5,80002e62 <usertrap+0x62>
       yield();
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	496080e7          	jalr	1174(ra) # 8000237c <yield>
    80002eee:	bf95                	j	80002e62 <usertrap+0x62>
  int which_dev = 0;
    80002ef0:	4901                	li	s2,0
    80002ef2:	b7d5                	j	80002ed6 <usertrap+0xd6>

0000000080002ef4 <kerneltrap>:
{
    80002ef4:	7179                	addi	sp,sp,-48
    80002ef6:	f406                	sd	ra,40(sp)
    80002ef8:	f022                	sd	s0,32(sp)
    80002efa:	ec26                	sd	s1,24(sp)
    80002efc:	e84a                	sd	s2,16(sp)
    80002efe:	e44e                	sd	s3,8(sp)
    80002f00:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f02:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f06:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f0a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f0e:	1004f793          	andi	a5,s1,256
    80002f12:	cb85                	beqz	a5,80002f42 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f18:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f1a:	ef85                	bnez	a5,80002f52 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	e42080e7          	jalr	-446(ra) # 80002d5e <devintr>
    80002f24:	cd1d                	beqz	a0,80002f62 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f26:	4789                	li	a5,2
    80002f28:	06f50a63          	beq	a0,a5,80002f9c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f2c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f30:	10049073          	csrw	sstatus,s1
}
    80002f34:	70a2                	ld	ra,40(sp)
    80002f36:	7402                	ld	s0,32(sp)
    80002f38:	64e2                	ld	s1,24(sp)
    80002f3a:	6942                	ld	s2,16(sp)
    80002f3c:	69a2                	ld	s3,8(sp)
    80002f3e:	6145                	addi	sp,sp,48
    80002f40:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f42:	00005517          	auipc	a0,0x5
    80002f46:	51650513          	addi	a0,a0,1302 # 80008458 <states.1871+0xc8>
    80002f4a:	ffffd097          	auipc	ra,0xffffd
    80002f4e:	5f4080e7          	jalr	1524(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f52:	00005517          	auipc	a0,0x5
    80002f56:	52e50513          	addi	a0,a0,1326 # 80008480 <states.1871+0xf0>
    80002f5a:	ffffd097          	auipc	ra,0xffffd
    80002f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f62:	85ce                	mv	a1,s3
    80002f64:	00005517          	auipc	a0,0x5
    80002f68:	53c50513          	addi	a0,a0,1340 # 800084a0 <states.1871+0x110>
    80002f6c:	ffffd097          	auipc	ra,0xffffd
    80002f70:	61c080e7          	jalr	1564(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f78:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	53450513          	addi	a0,a0,1332 # 800084b0 <states.1871+0x120>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	604080e7          	jalr	1540(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f8c:	00005517          	auipc	a0,0x5
    80002f90:	53c50513          	addi	a0,a0,1340 # 800084c8 <states.1871+0x138>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	5aa080e7          	jalr	1450(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	a2c080e7          	jalr	-1492(ra) # 800019c8 <myproc>
    80002fa4:	d541                	beqz	a0,80002f2c <kerneltrap+0x38>
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	a22080e7          	jalr	-1502(ra) # 800019c8 <myproc>
    80002fae:	4d18                	lw	a4,24(a0)
    80002fb0:	4791                	li	a5,4
    80002fb2:	f6f71de3          	bne	a4,a5,80002f2c <kerneltrap+0x38>
       yield();
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	3c6080e7          	jalr	966(ra) # 8000237c <yield>
    80002fbe:	b7bd                	j	80002f2c <kerneltrap+0x38>

0000000080002fc0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	1000                	addi	s0,sp,32
    80002fca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	9fc080e7          	jalr	-1540(ra) # 800019c8 <myproc>
  switch (n) {
    80002fd4:	4795                	li	a5,5
    80002fd6:	0497e163          	bltu	a5,s1,80003018 <argraw+0x58>
    80002fda:	048a                	slli	s1,s1,0x2
    80002fdc:	00005717          	auipc	a4,0x5
    80002fe0:	52470713          	addi	a4,a4,1316 # 80008500 <states.1871+0x170>
    80002fe4:	94ba                	add	s1,s1,a4
    80002fe6:	409c                	lw	a5,0(s1)
    80002fe8:	97ba                	add	a5,a5,a4
    80002fea:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fec:	6d3c                	ld	a5,88(a0)
    80002fee:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ff0:	60e2                	ld	ra,24(sp)
    80002ff2:	6442                	ld	s0,16(sp)
    80002ff4:	64a2                	ld	s1,8(sp)
    80002ff6:	6105                	addi	sp,sp,32
    80002ff8:	8082                	ret
    return p->trapframe->a1;
    80002ffa:	6d3c                	ld	a5,88(a0)
    80002ffc:	7fa8                	ld	a0,120(a5)
    80002ffe:	bfcd                	j	80002ff0 <argraw+0x30>
    return p->trapframe->a2;
    80003000:	6d3c                	ld	a5,88(a0)
    80003002:	63c8                	ld	a0,128(a5)
    80003004:	b7f5                	j	80002ff0 <argraw+0x30>
    return p->trapframe->a3;
    80003006:	6d3c                	ld	a5,88(a0)
    80003008:	67c8                	ld	a0,136(a5)
    8000300a:	b7dd                	j	80002ff0 <argraw+0x30>
    return p->trapframe->a4;
    8000300c:	6d3c                	ld	a5,88(a0)
    8000300e:	6bc8                	ld	a0,144(a5)
    80003010:	b7c5                	j	80002ff0 <argraw+0x30>
    return p->trapframe->a5;
    80003012:	6d3c                	ld	a5,88(a0)
    80003014:	6fc8                	ld	a0,152(a5)
    80003016:	bfe9                	j	80002ff0 <argraw+0x30>
  panic("argraw");
    80003018:	00005517          	auipc	a0,0x5
    8000301c:	4c050513          	addi	a0,a0,1216 # 800084d8 <states.1871+0x148>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>

0000000080003028 <fetchaddr>:
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	e04a                	sd	s2,0(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84aa                	mv	s1,a0
    80003036:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	990080e7          	jalr	-1648(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003040:	653c                	ld	a5,72(a0)
    80003042:	02f4f863          	bgeu	s1,a5,80003072 <fetchaddr+0x4a>
    80003046:	00848713          	addi	a4,s1,8
    8000304a:	02e7e663          	bltu	a5,a4,80003076 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000304e:	46a1                	li	a3,8
    80003050:	8626                	mv	a2,s1
    80003052:	85ca                	mv	a1,s2
    80003054:	6928                	ld	a0,80(a0)
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	6b0080e7          	jalr	1712(ra) # 80001706 <copyin>
    8000305e:	00a03533          	snez	a0,a0
    80003062:	40a00533          	neg	a0,a0
}
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6902                	ld	s2,0(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret
    return -1;
    80003072:	557d                	li	a0,-1
    80003074:	bfcd                	j	80003066 <fetchaddr+0x3e>
    80003076:	557d                	li	a0,-1
    80003078:	b7fd                	j	80003066 <fetchaddr+0x3e>

000000008000307a <fetchstr>:
{
    8000307a:	7179                	addi	sp,sp,-48
    8000307c:	f406                	sd	ra,40(sp)
    8000307e:	f022                	sd	s0,32(sp)
    80003080:	ec26                	sd	s1,24(sp)
    80003082:	e84a                	sd	s2,16(sp)
    80003084:	e44e                	sd	s3,8(sp)
    80003086:	1800                	addi	s0,sp,48
    80003088:	892a                	mv	s2,a0
    8000308a:	84ae                	mv	s1,a1
    8000308c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	93a080e7          	jalr	-1734(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003096:	86ce                	mv	a3,s3
    80003098:	864a                	mv	a2,s2
    8000309a:	85a6                	mv	a1,s1
    8000309c:	6928                	ld	a0,80(a0)
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	6f4080e7          	jalr	1780(ra) # 80001792 <copyinstr>
  if(err < 0)
    800030a6:	00054763          	bltz	a0,800030b4 <fetchstr+0x3a>
  return strlen(buf);
    800030aa:	8526                	mv	a0,s1
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	db8080e7          	jalr	-584(ra) # 80000e64 <strlen>
}
    800030b4:	70a2                	ld	ra,40(sp)
    800030b6:	7402                	ld	s0,32(sp)
    800030b8:	64e2                	ld	s1,24(sp)
    800030ba:	6942                	ld	s2,16(sp)
    800030bc:	69a2                	ld	s3,8(sp)
    800030be:	6145                	addi	sp,sp,48
    800030c0:	8082                	ret

00000000800030c2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030c2:	1101                	addi	sp,sp,-32
    800030c4:	ec06                	sd	ra,24(sp)
    800030c6:	e822                	sd	s0,16(sp)
    800030c8:	e426                	sd	s1,8(sp)
    800030ca:	1000                	addi	s0,sp,32
    800030cc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	ef2080e7          	jalr	-270(ra) # 80002fc0 <argraw>
    800030d6:	c088                	sw	a0,0(s1)
  return 0;
}
    800030d8:	4501                	li	a0,0
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret

00000000800030e4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	1000                	addi	s0,sp,32
    800030ee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	ed0080e7          	jalr	-304(ra) # 80002fc0 <argraw>
    800030f8:	e088                	sd	a0,0(s1)
  return 0;
}
    800030fa:	4501                	li	a0,0
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	e04a                	sd	s2,0(sp)
    80003110:	1000                	addi	s0,sp,32
    80003112:	84ae                	mv	s1,a1
    80003114:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	eaa080e7          	jalr	-342(ra) # 80002fc0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000311e:	864a                	mv	a2,s2
    80003120:	85a6                	mv	a1,s1
    80003122:	00000097          	auipc	ra,0x0
    80003126:	f58080e7          	jalr	-168(ra) # 8000307a <fetchstr>
}
    8000312a:	60e2                	ld	ra,24(sp)
    8000312c:	6442                	ld	s0,16(sp)
    8000312e:	64a2                	ld	s1,8(sp)
    80003130:	6902                	ld	s2,0(sp)
    80003132:	6105                	addi	sp,sp,32
    80003134:	8082                	ret

0000000080003136 <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    80003136:	1101                	addi	sp,sp,-32
    80003138:	ec06                	sd	ra,24(sp)
    8000313a:	e822                	sd	s0,16(sp)
    8000313c:	e426                	sd	s1,8(sp)
    8000313e:	e04a                	sd	s2,0(sp)
    80003140:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003142:	fffff097          	auipc	ra,0xfffff
    80003146:	886080e7          	jalr	-1914(ra) # 800019c8 <myproc>
    8000314a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000314c:	05853903          	ld	s2,88(a0)
    80003150:	0a893783          	ld	a5,168(s2)
    80003154:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003158:	37fd                	addiw	a5,a5,-1
    8000315a:	475d                	li	a4,23
    8000315c:	00f76f63          	bltu	a4,a5,8000317a <syscall+0x44>
    80003160:	00369713          	slli	a4,a3,0x3
    80003164:	00005797          	auipc	a5,0x5
    80003168:	3b478793          	addi	a5,a5,948 # 80008518 <syscalls>
    8000316c:	97ba                	add	a5,a5,a4
    8000316e:	639c                	ld	a5,0(a5)
    80003170:	c789                	beqz	a5,8000317a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003172:	9782                	jalr	a5
    80003174:	06a93823          	sd	a0,112(s2)
    80003178:	a839                	j	80003196 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000317a:	15848613          	addi	a2,s1,344
    8000317e:	588c                	lw	a1,48(s1)
    80003180:	00005517          	auipc	a0,0x5
    80003184:	36050513          	addi	a0,a0,864 # 800084e0 <states.1871+0x150>
    80003188:	ffffd097          	auipc	ra,0xffffd
    8000318c:	400080e7          	jalr	1024(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003190:	6cbc                	ld	a5,88(s1)
    80003192:	577d                	li	a4,-1
    80003194:	fbb8                	sd	a4,112(a5)
  }
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6902                	ld	s2,0(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031aa:	fec40593          	addi	a1,s0,-20
    800031ae:	4501                	li	a0,0
    800031b0:	00000097          	auipc	ra,0x0
    800031b4:	f12080e7          	jalr	-238(ra) # 800030c2 <argint>
    return -1;
    800031b8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031ba:	00054963          	bltz	a0,800031cc <sys_exit+0x2a>
  exit(n);
    800031be:	fec42503          	lw	a0,-20(s0)
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	4fe080e7          	jalr	1278(ra) # 800026c0 <exit>
  return 0;  // not reached
    800031ca:	4781                	li	a5,0
}
    800031cc:	853e                	mv	a0,a5
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret

00000000800031d6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031d6:	1141                	addi	sp,sp,-16
    800031d8:	e406                	sd	ra,8(sp)
    800031da:	e022                	sd	s0,0(sp)
    800031dc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	7ea080e7          	jalr	2026(ra) # 800019c8 <myproc>
}
    800031e6:	5908                	lw	a0,48(a0)
    800031e8:	60a2                	ld	ra,8(sp)
    800031ea:	6402                	ld	s0,0(sp)
    800031ec:	0141                	addi	sp,sp,16
    800031ee:	8082                	ret

00000000800031f0 <sys_fork>:

uint64
sys_fork(void)
{
    800031f0:	1141                	addi	sp,sp,-16
    800031f2:	e406                	sd	ra,8(sp)
    800031f4:	e022                	sd	s0,0(sp)
    800031f6:	0800                	addi	s0,sp,16
  return fork();
    800031f8:	fffff097          	auipc	ra,0xfffff
    800031fc:	bbe080e7          	jalr	-1090(ra) # 80001db6 <fork>
}
    80003200:	60a2                	ld	ra,8(sp)
    80003202:	6402                	ld	s0,0(sp)
    80003204:	0141                	addi	sp,sp,16
    80003206:	8082                	ret

0000000080003208 <sys_wait>:

uint64
sys_wait(void)
{
    80003208:	1101                	addi	sp,sp,-32
    8000320a:	ec06                	sd	ra,24(sp)
    8000320c:	e822                	sd	s0,16(sp)
    8000320e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003210:	fe840593          	addi	a1,s0,-24
    80003214:	4501                	li	a0,0
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	ece080e7          	jalr	-306(ra) # 800030e4 <argaddr>
    8000321e:	87aa                	mv	a5,a0
    return -1;
    80003220:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003222:	0007c863          	bltz	a5,80003232 <sys_wait+0x2a>
  return wait(p);
    80003226:	fe843503          	ld	a0,-24(s0)
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	27a080e7          	jalr	634(ra) # 800024a4 <wait>
}
    80003232:	60e2                	ld	ra,24(sp)
    80003234:	6442                	ld	s0,16(sp)
    80003236:	6105                	addi	sp,sp,32
    80003238:	8082                	ret

000000008000323a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000323a:	7179                	addi	sp,sp,-48
    8000323c:	f406                	sd	ra,40(sp)
    8000323e:	f022                	sd	s0,32(sp)
    80003240:	ec26                	sd	s1,24(sp)
    80003242:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003244:	fdc40593          	addi	a1,s0,-36
    80003248:	4501                	li	a0,0
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	e78080e7          	jalr	-392(ra) # 800030c2 <argint>
    80003252:	87aa                	mv	a5,a0
    return -1;
    80003254:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003256:	0207c063          	bltz	a5,80003276 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	76e080e7          	jalr	1902(ra) # 800019c8 <myproc>
    80003262:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003264:	fdc42503          	lw	a0,-36(s0)
    80003268:	fffff097          	auipc	ra,0xfffff
    8000326c:	ada080e7          	jalr	-1318(ra) # 80001d42 <growproc>
    80003270:	00054863          	bltz	a0,80003280 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003274:	8526                	mv	a0,s1
}
    80003276:	70a2                	ld	ra,40(sp)
    80003278:	7402                	ld	s0,32(sp)
    8000327a:	64e2                	ld	s1,24(sp)
    8000327c:	6145                	addi	sp,sp,48
    8000327e:	8082                	ret
    return -1;
    80003280:	557d                	li	a0,-1
    80003282:	bfd5                	j	80003276 <sys_sbrk+0x3c>

0000000080003284 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003284:	7139                	addi	sp,sp,-64
    80003286:	fc06                	sd	ra,56(sp)
    80003288:	f822                	sd	s0,48(sp)
    8000328a:	f426                	sd	s1,40(sp)
    8000328c:	f04a                	sd	s2,32(sp)
    8000328e:	ec4e                	sd	s3,24(sp)
    80003290:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003292:	fcc40593          	addi	a1,s0,-52
    80003296:	4501                	li	a0,0
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	e2a080e7          	jalr	-470(ra) # 800030c2 <argint>
    return -1;
    800032a0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032a2:	06054563          	bltz	a0,8000330c <sys_sleep+0x88>
  acquire(&tickslock);
    800032a6:	0000d517          	auipc	a0,0xd
    800032aa:	1ba50513          	addi	a0,a0,442 # 80010460 <tickslock>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800032b6:	00006917          	auipc	s2,0x6
    800032ba:	da292903          	lw	s2,-606(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    800032be:	fcc42783          	lw	a5,-52(s0)
    800032c2:	cf85                	beqz	a5,800032fa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032c4:	0000d997          	auipc	s3,0xd
    800032c8:	19c98993          	addi	s3,s3,412 # 80010460 <tickslock>
    800032cc:	00006497          	auipc	s1,0x6
    800032d0:	d8c48493          	addi	s1,s1,-628 # 80009058 <ticks>
    if(myproc()->killed){
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	6f4080e7          	jalr	1780(ra) # 800019c8 <myproc>
    800032dc:	551c                	lw	a5,40(a0)
    800032de:	ef9d                	bnez	a5,8000331c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032e0:	85ce                	mv	a1,s3
    800032e2:	8526                	mv	a0,s1
    800032e4:	fffff097          	auipc	ra,0xfffff
    800032e8:	118080e7          	jalr	280(ra) # 800023fc <sleep>
  while(ticks - ticks0 < n){
    800032ec:	409c                	lw	a5,0(s1)
    800032ee:	412787bb          	subw	a5,a5,s2
    800032f2:	fcc42703          	lw	a4,-52(s0)
    800032f6:	fce7efe3          	bltu	a5,a4,800032d4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032fa:	0000d517          	auipc	a0,0xd
    800032fe:	16650513          	addi	a0,a0,358 # 80010460 <tickslock>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
  return 0;
    8000330a:	4781                	li	a5,0
}
    8000330c:	853e                	mv	a0,a5
    8000330e:	70e2                	ld	ra,56(sp)
    80003310:	7442                	ld	s0,48(sp)
    80003312:	74a2                	ld	s1,40(sp)
    80003314:	7902                	ld	s2,32(sp)
    80003316:	69e2                	ld	s3,24(sp)
    80003318:	6121                	addi	sp,sp,64
    8000331a:	8082                	ret
      release(&tickslock);
    8000331c:	0000d517          	auipc	a0,0xd
    80003320:	14450513          	addi	a0,a0,324 # 80010460 <tickslock>
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	974080e7          	jalr	-1676(ra) # 80000c98 <release>
      return -1;
    8000332c:	57fd                	li	a5,-1
    8000332e:	bff9                	j	8000330c <sys_sleep+0x88>

0000000080003330 <sys_kill>:

uint64
sys_kill(void)
{
    80003330:	1101                	addi	sp,sp,-32
    80003332:	ec06                	sd	ra,24(sp)
    80003334:	e822                	sd	s0,16(sp)
    80003336:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003338:	fec40593          	addi	a1,s0,-20
    8000333c:	4501                	li	a0,0
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	d84080e7          	jalr	-636(ra) # 800030c2 <argint>
    80003346:	87aa                	mv	a5,a0
    return -1;
    80003348:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000334a:	0007c863          	bltz	a5,8000335a <sys_kill+0x2a>
  return kill(pid);
    8000334e:	fec42503          	lw	a0,-20(s0)
    80003352:	fffff097          	auipc	ra,0xfffff
    80003356:	4f0080e7          	jalr	1264(ra) # 80002842 <kill>
}
    8000335a:	60e2                	ld	ra,24(sp)
    8000335c:	6442                	ld	s0,16(sp)
    8000335e:	6105                	addi	sp,sp,32
    80003360:	8082                	ret

0000000080003362 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003362:	1101                	addi	sp,sp,-32
    80003364:	ec06                	sd	ra,24(sp)
    80003366:	e822                	sd	s0,16(sp)
    80003368:	e426                	sd	s1,8(sp)
    8000336a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000336c:	0000d517          	auipc	a0,0xd
    80003370:	0f450513          	addi	a0,a0,244 # 80010460 <tickslock>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	870080e7          	jalr	-1936(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000337c:	00006497          	auipc	s1,0x6
    80003380:	cdc4a483          	lw	s1,-804(s1) # 80009058 <ticks>
  release(&tickslock);
    80003384:	0000d517          	auipc	a0,0xd
    80003388:	0dc50513          	addi	a0,a0,220 # 80010460 <tickslock>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	90c080e7          	jalr	-1780(ra) # 80000c98 <release>
  return xticks;
}
    80003394:	02049513          	slli	a0,s1,0x20
    80003398:	9101                	srli	a0,a0,0x20
    8000339a:	60e2                	ld	ra,24(sp)
    8000339c:	6442                	ld	s0,16(sp)
    8000339e:	64a2                	ld	s1,8(sp)
    800033a0:	6105                	addi	sp,sp,32
    800033a2:	8082                	ret

00000000800033a4 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    800033a4:	1141                	addi	sp,sp,-16
    800033a6:	e406                	sd	ra,8(sp)
    800033a8:	e022                	sd	s0,0(sp)
    800033aa:	0800                	addi	s0,sp,16
  return kill_system();
    800033ac:	fffff097          	auipc	ra,0xfffff
    800033b0:	524080e7          	jalr	1316(ra) # 800028d0 <kill_system>
}
    800033b4:	60a2                	ld	ra,8(sp)
    800033b6:	6402                	ld	s0,0(sp)
    800033b8:	0141                	addi	sp,sp,16
    800033ba:	8082                	ret

00000000800033bc <sys_pause_system>:

uint64
sys_pause_system(void)
{
    800033bc:	1101                	addi	sp,sp,-32
    800033be:	ec06                	sd	ra,24(sp)
    800033c0:	e822                	sd	s0,16(sp)
    800033c2:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    800033c4:	fec40593          	addi	a1,s0,-20
    800033c8:	4501                	li	a0,0
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	cf8080e7          	jalr	-776(ra) # 800030c2 <argint>
    800033d2:	87aa                	mv	a5,a0
    return -1;
    800033d4:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    800033d6:	0007c863          	bltz	a5,800033e6 <sys_pause_system+0x2a>
  return pause_system(seconds);
    800033da:	fec42503          	lw	a0,-20(s0)
    800033de:	fffff097          	auipc	ra,0xfffff
    800033e2:	71c080e7          	jalr	1820(ra) # 80002afa <pause_system>
}
    800033e6:	60e2                	ld	ra,24(sp)
    800033e8:	6442                	ld	s0,16(sp)
    800033ea:	6105                	addi	sp,sp,32
    800033ec:	8082                	ret

00000000800033ee <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800033ee:	1141                	addi	sp,sp,-16
    800033f0:	e406                	sd	ra,8(sp)
    800033f2:	e022                	sd	s0,0(sp)
    800033f4:	0800                	addi	s0,sp,16
   print_stats();
    800033f6:	fffff097          	auipc	ra,0xfffff
    800033fa:	73a080e7          	jalr	1850(ra) # 80002b30 <print_stats>
   return 0;
    800033fe:	4501                	li	a0,0
    80003400:	60a2                	ld	ra,8(sp)
    80003402:	6402                	ld	s0,0(sp)
    80003404:	0141                	addi	sp,sp,16
    80003406:	8082                	ret

0000000080003408 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003408:	7179                	addi	sp,sp,-48
    8000340a:	f406                	sd	ra,40(sp)
    8000340c:	f022                	sd	s0,32(sp)
    8000340e:	ec26                	sd	s1,24(sp)
    80003410:	e84a                	sd	s2,16(sp)
    80003412:	e44e                	sd	s3,8(sp)
    80003414:	e052                	sd	s4,0(sp)
    80003416:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003418:	00005597          	auipc	a1,0x5
    8000341c:	1c858593          	addi	a1,a1,456 # 800085e0 <syscalls+0xc8>
    80003420:	0000d517          	auipc	a0,0xd
    80003424:	05850513          	addi	a0,a0,88 # 80010478 <bcache>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	72c080e7          	jalr	1836(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003430:	00015797          	auipc	a5,0x15
    80003434:	04878793          	addi	a5,a5,72 # 80018478 <bcache+0x8000>
    80003438:	00015717          	auipc	a4,0x15
    8000343c:	2a870713          	addi	a4,a4,680 # 800186e0 <bcache+0x8268>
    80003440:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003444:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003448:	0000d497          	auipc	s1,0xd
    8000344c:	04848493          	addi	s1,s1,72 # 80010490 <bcache+0x18>
    b->next = bcache.head.next;
    80003450:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003452:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003454:	00005a17          	auipc	s4,0x5
    80003458:	194a0a13          	addi	s4,s4,404 # 800085e8 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000345c:	2b893783          	ld	a5,696(s2)
    80003460:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003462:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003466:	85d2                	mv	a1,s4
    80003468:	01048513          	addi	a0,s1,16
    8000346c:	00001097          	auipc	ra,0x1
    80003470:	4bc080e7          	jalr	1212(ra) # 80004928 <initsleeplock>
    bcache.head.next->prev = b;
    80003474:	2b893783          	ld	a5,696(s2)
    80003478:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000347a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000347e:	45848493          	addi	s1,s1,1112
    80003482:	fd349de3          	bne	s1,s3,8000345c <binit+0x54>
  }
}
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6942                	ld	s2,16(sp)
    8000348e:	69a2                	ld	s3,8(sp)
    80003490:	6a02                	ld	s4,0(sp)
    80003492:	6145                	addi	sp,sp,48
    80003494:	8082                	ret

0000000080003496 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003496:	7179                	addi	sp,sp,-48
    80003498:	f406                	sd	ra,40(sp)
    8000349a:	f022                	sd	s0,32(sp)
    8000349c:	ec26                	sd	s1,24(sp)
    8000349e:	e84a                	sd	s2,16(sp)
    800034a0:	e44e                	sd	s3,8(sp)
    800034a2:	1800                	addi	s0,sp,48
    800034a4:	89aa                	mv	s3,a0
    800034a6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800034a8:	0000d517          	auipc	a0,0xd
    800034ac:	fd050513          	addi	a0,a0,-48 # 80010478 <bcache>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	734080e7          	jalr	1844(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034b8:	00015497          	auipc	s1,0x15
    800034bc:	2784b483          	ld	s1,632(s1) # 80018730 <bcache+0x82b8>
    800034c0:	00015797          	auipc	a5,0x15
    800034c4:	22078793          	addi	a5,a5,544 # 800186e0 <bcache+0x8268>
    800034c8:	02f48f63          	beq	s1,a5,80003506 <bread+0x70>
    800034cc:	873e                	mv	a4,a5
    800034ce:	a021                	j	800034d6 <bread+0x40>
    800034d0:	68a4                	ld	s1,80(s1)
    800034d2:	02e48a63          	beq	s1,a4,80003506 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034d6:	449c                	lw	a5,8(s1)
    800034d8:	ff379ce3          	bne	a5,s3,800034d0 <bread+0x3a>
    800034dc:	44dc                	lw	a5,12(s1)
    800034de:	ff2799e3          	bne	a5,s2,800034d0 <bread+0x3a>
      b->refcnt++;
    800034e2:	40bc                	lw	a5,64(s1)
    800034e4:	2785                	addiw	a5,a5,1
    800034e6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034e8:	0000d517          	auipc	a0,0xd
    800034ec:	f9050513          	addi	a0,a0,-112 # 80010478 <bcache>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	7a8080e7          	jalr	1960(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034f8:	01048513          	addi	a0,s1,16
    800034fc:	00001097          	auipc	ra,0x1
    80003500:	466080e7          	jalr	1126(ra) # 80004962 <acquiresleep>
      return b;
    80003504:	a8b9                	j	80003562 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003506:	00015497          	auipc	s1,0x15
    8000350a:	2224b483          	ld	s1,546(s1) # 80018728 <bcache+0x82b0>
    8000350e:	00015797          	auipc	a5,0x15
    80003512:	1d278793          	addi	a5,a5,466 # 800186e0 <bcache+0x8268>
    80003516:	00f48863          	beq	s1,a5,80003526 <bread+0x90>
    8000351a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000351c:	40bc                	lw	a5,64(s1)
    8000351e:	cf81                	beqz	a5,80003536 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003520:	64a4                	ld	s1,72(s1)
    80003522:	fee49de3          	bne	s1,a4,8000351c <bread+0x86>
  panic("bget: no buffers");
    80003526:	00005517          	auipc	a0,0x5
    8000352a:	0ca50513          	addi	a0,a0,202 # 800085f0 <syscalls+0xd8>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	010080e7          	jalr	16(ra) # 8000053e <panic>
      b->dev = dev;
    80003536:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000353a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000353e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003542:	4785                	li	a5,1
    80003544:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003546:	0000d517          	auipc	a0,0xd
    8000354a:	f3250513          	addi	a0,a0,-206 # 80010478 <bcache>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	74a080e7          	jalr	1866(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003556:	01048513          	addi	a0,s1,16
    8000355a:	00001097          	auipc	ra,0x1
    8000355e:	408080e7          	jalr	1032(ra) # 80004962 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003562:	409c                	lw	a5,0(s1)
    80003564:	cb89                	beqz	a5,80003576 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003566:	8526                	mv	a0,s1
    80003568:	70a2                	ld	ra,40(sp)
    8000356a:	7402                	ld	s0,32(sp)
    8000356c:	64e2                	ld	s1,24(sp)
    8000356e:	6942                	ld	s2,16(sp)
    80003570:	69a2                	ld	s3,8(sp)
    80003572:	6145                	addi	sp,sp,48
    80003574:	8082                	ret
    virtio_disk_rw(b, 0);
    80003576:	4581                	li	a1,0
    80003578:	8526                	mv	a0,s1
    8000357a:	00003097          	auipc	ra,0x3
    8000357e:	f0c080e7          	jalr	-244(ra) # 80006486 <virtio_disk_rw>
    b->valid = 1;
    80003582:	4785                	li	a5,1
    80003584:	c09c                	sw	a5,0(s1)
  return b;
    80003586:	b7c5                	j	80003566 <bread+0xd0>

0000000080003588 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003588:	1101                	addi	sp,sp,-32
    8000358a:	ec06                	sd	ra,24(sp)
    8000358c:	e822                	sd	s0,16(sp)
    8000358e:	e426                	sd	s1,8(sp)
    80003590:	1000                	addi	s0,sp,32
    80003592:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003594:	0541                	addi	a0,a0,16
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	466080e7          	jalr	1126(ra) # 800049fc <holdingsleep>
    8000359e:	cd01                	beqz	a0,800035b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035a0:	4585                	li	a1,1
    800035a2:	8526                	mv	a0,s1
    800035a4:	00003097          	auipc	ra,0x3
    800035a8:	ee2080e7          	jalr	-286(ra) # 80006486 <virtio_disk_rw>
}
    800035ac:	60e2                	ld	ra,24(sp)
    800035ae:	6442                	ld	s0,16(sp)
    800035b0:	64a2                	ld	s1,8(sp)
    800035b2:	6105                	addi	sp,sp,32
    800035b4:	8082                	ret
    panic("bwrite");
    800035b6:	00005517          	auipc	a0,0x5
    800035ba:	05250513          	addi	a0,a0,82 # 80008608 <syscalls+0xf0>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>

00000000800035c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035c6:	1101                	addi	sp,sp,-32
    800035c8:	ec06                	sd	ra,24(sp)
    800035ca:	e822                	sd	s0,16(sp)
    800035cc:	e426                	sd	s1,8(sp)
    800035ce:	e04a                	sd	s2,0(sp)
    800035d0:	1000                	addi	s0,sp,32
    800035d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035d4:	01050913          	addi	s2,a0,16
    800035d8:	854a                	mv	a0,s2
    800035da:	00001097          	auipc	ra,0x1
    800035de:	422080e7          	jalr	1058(ra) # 800049fc <holdingsleep>
    800035e2:	c92d                	beqz	a0,80003654 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035e4:	854a                	mv	a0,s2
    800035e6:	00001097          	auipc	ra,0x1
    800035ea:	3d2080e7          	jalr	978(ra) # 800049b8 <releasesleep>

  acquire(&bcache.lock);
    800035ee:	0000d517          	auipc	a0,0xd
    800035f2:	e8a50513          	addi	a0,a0,-374 # 80010478 <bcache>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	5ee080e7          	jalr	1518(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035fe:	40bc                	lw	a5,64(s1)
    80003600:	37fd                	addiw	a5,a5,-1
    80003602:	0007871b          	sext.w	a4,a5
    80003606:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003608:	eb05                	bnez	a4,80003638 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000360a:	68bc                	ld	a5,80(s1)
    8000360c:	64b8                	ld	a4,72(s1)
    8000360e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003610:	64bc                	ld	a5,72(s1)
    80003612:	68b8                	ld	a4,80(s1)
    80003614:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003616:	00015797          	auipc	a5,0x15
    8000361a:	e6278793          	addi	a5,a5,-414 # 80018478 <bcache+0x8000>
    8000361e:	2b87b703          	ld	a4,696(a5)
    80003622:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003624:	00015717          	auipc	a4,0x15
    80003628:	0bc70713          	addi	a4,a4,188 # 800186e0 <bcache+0x8268>
    8000362c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000362e:	2b87b703          	ld	a4,696(a5)
    80003632:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003634:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003638:	0000d517          	auipc	a0,0xd
    8000363c:	e4050513          	addi	a0,a0,-448 # 80010478 <bcache>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
}
    80003648:	60e2                	ld	ra,24(sp)
    8000364a:	6442                	ld	s0,16(sp)
    8000364c:	64a2                	ld	s1,8(sp)
    8000364e:	6902                	ld	s2,0(sp)
    80003650:	6105                	addi	sp,sp,32
    80003652:	8082                	ret
    panic("brelse");
    80003654:	00005517          	auipc	a0,0x5
    80003658:	fbc50513          	addi	a0,a0,-68 # 80008610 <syscalls+0xf8>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>

0000000080003664 <bpin>:

void
bpin(struct buf *b) {
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	e426                	sd	s1,8(sp)
    8000366c:	1000                	addi	s0,sp,32
    8000366e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003670:	0000d517          	auipc	a0,0xd
    80003674:	e0850513          	addi	a0,a0,-504 # 80010478 <bcache>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	56c080e7          	jalr	1388(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003680:	40bc                	lw	a5,64(s1)
    80003682:	2785                	addiw	a5,a5,1
    80003684:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003686:	0000d517          	auipc	a0,0xd
    8000368a:	df250513          	addi	a0,a0,-526 # 80010478 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	60a080e7          	jalr	1546(ra) # 80000c98 <release>
}
    80003696:	60e2                	ld	ra,24(sp)
    80003698:	6442                	ld	s0,16(sp)
    8000369a:	64a2                	ld	s1,8(sp)
    8000369c:	6105                	addi	sp,sp,32
    8000369e:	8082                	ret

00000000800036a0 <bunpin>:

void
bunpin(struct buf *b) {
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	1000                	addi	s0,sp,32
    800036aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036ac:	0000d517          	auipc	a0,0xd
    800036b0:	dcc50513          	addi	a0,a0,-564 # 80010478 <bcache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	530080e7          	jalr	1328(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036bc:	40bc                	lw	a5,64(s1)
    800036be:	37fd                	addiw	a5,a5,-1
    800036c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036c2:	0000d517          	auipc	a0,0xd
    800036c6:	db650513          	addi	a0,a0,-586 # 80010478 <bcache>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
}
    800036d2:	60e2                	ld	ra,24(sp)
    800036d4:	6442                	ld	s0,16(sp)
    800036d6:	64a2                	ld	s1,8(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret

00000000800036dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	e04a                	sd	s2,0(sp)
    800036e6:	1000                	addi	s0,sp,32
    800036e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036ea:	00d5d59b          	srliw	a1,a1,0xd
    800036ee:	00015797          	auipc	a5,0x15
    800036f2:	4667a783          	lw	a5,1126(a5) # 80018b54 <sb+0x1c>
    800036f6:	9dbd                	addw	a1,a1,a5
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	d9e080e7          	jalr	-610(ra) # 80003496 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003700:	0074f713          	andi	a4,s1,7
    80003704:	4785                	li	a5,1
    80003706:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000370a:	14ce                	slli	s1,s1,0x33
    8000370c:	90d9                	srli	s1,s1,0x36
    8000370e:	00950733          	add	a4,a0,s1
    80003712:	05874703          	lbu	a4,88(a4)
    80003716:	00e7f6b3          	and	a3,a5,a4
    8000371a:	c69d                	beqz	a3,80003748 <bfree+0x6c>
    8000371c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000371e:	94aa                	add	s1,s1,a0
    80003720:	fff7c793          	not	a5,a5
    80003724:	8ff9                	and	a5,a5,a4
    80003726:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	118080e7          	jalr	280(ra) # 80004842 <log_write>
  brelse(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00000097          	auipc	ra,0x0
    80003738:	e92080e7          	jalr	-366(ra) # 800035c6 <brelse>
}
    8000373c:	60e2                	ld	ra,24(sp)
    8000373e:	6442                	ld	s0,16(sp)
    80003740:	64a2                	ld	s1,8(sp)
    80003742:	6902                	ld	s2,0(sp)
    80003744:	6105                	addi	sp,sp,32
    80003746:	8082                	ret
    panic("freeing free block");
    80003748:	00005517          	auipc	a0,0x5
    8000374c:	ed050513          	addi	a0,a0,-304 # 80008618 <syscalls+0x100>
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	dee080e7          	jalr	-530(ra) # 8000053e <panic>

0000000080003758 <balloc>:
{
    80003758:	711d                	addi	sp,sp,-96
    8000375a:	ec86                	sd	ra,88(sp)
    8000375c:	e8a2                	sd	s0,80(sp)
    8000375e:	e4a6                	sd	s1,72(sp)
    80003760:	e0ca                	sd	s2,64(sp)
    80003762:	fc4e                	sd	s3,56(sp)
    80003764:	f852                	sd	s4,48(sp)
    80003766:	f456                	sd	s5,40(sp)
    80003768:	f05a                	sd	s6,32(sp)
    8000376a:	ec5e                	sd	s7,24(sp)
    8000376c:	e862                	sd	s8,16(sp)
    8000376e:	e466                	sd	s9,8(sp)
    80003770:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003772:	00015797          	auipc	a5,0x15
    80003776:	3ca7a783          	lw	a5,970(a5) # 80018b3c <sb+0x4>
    8000377a:	cbd1                	beqz	a5,8000380e <balloc+0xb6>
    8000377c:	8baa                	mv	s7,a0
    8000377e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003780:	00015b17          	auipc	s6,0x15
    80003784:	3b8b0b13          	addi	s6,s6,952 # 80018b38 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003788:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000378a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000378c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000378e:	6c89                	lui	s9,0x2
    80003790:	a831                	j	800037ac <balloc+0x54>
    brelse(bp);
    80003792:	854a                	mv	a0,s2
    80003794:	00000097          	auipc	ra,0x0
    80003798:	e32080e7          	jalr	-462(ra) # 800035c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000379c:	015c87bb          	addw	a5,s9,s5
    800037a0:	00078a9b          	sext.w	s5,a5
    800037a4:	004b2703          	lw	a4,4(s6)
    800037a8:	06eaf363          	bgeu	s5,a4,8000380e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037ac:	41fad79b          	sraiw	a5,s5,0x1f
    800037b0:	0137d79b          	srliw	a5,a5,0x13
    800037b4:	015787bb          	addw	a5,a5,s5
    800037b8:	40d7d79b          	sraiw	a5,a5,0xd
    800037bc:	01cb2583          	lw	a1,28(s6)
    800037c0:	9dbd                	addw	a1,a1,a5
    800037c2:	855e                	mv	a0,s7
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	cd2080e7          	jalr	-814(ra) # 80003496 <bread>
    800037cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ce:	004b2503          	lw	a0,4(s6)
    800037d2:	000a849b          	sext.w	s1,s5
    800037d6:	8662                	mv	a2,s8
    800037d8:	faa4fde3          	bgeu	s1,a0,80003792 <balloc+0x3a>
      m = 1 << (bi % 8);
    800037dc:	41f6579b          	sraiw	a5,a2,0x1f
    800037e0:	01d7d69b          	srliw	a3,a5,0x1d
    800037e4:	00c6873b          	addw	a4,a3,a2
    800037e8:	00777793          	andi	a5,a4,7
    800037ec:	9f95                	subw	a5,a5,a3
    800037ee:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037f2:	4037571b          	sraiw	a4,a4,0x3
    800037f6:	00e906b3          	add	a3,s2,a4
    800037fa:	0586c683          	lbu	a3,88(a3)
    800037fe:	00d7f5b3          	and	a1,a5,a3
    80003802:	cd91                	beqz	a1,8000381e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003804:	2605                	addiw	a2,a2,1
    80003806:	2485                	addiw	s1,s1,1
    80003808:	fd4618e3          	bne	a2,s4,800037d8 <balloc+0x80>
    8000380c:	b759                	j	80003792 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000380e:	00005517          	auipc	a0,0x5
    80003812:	e2250513          	addi	a0,a0,-478 # 80008630 <syscalls+0x118>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	d28080e7          	jalr	-728(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000381e:	974a                	add	a4,a4,s2
    80003820:	8fd5                	or	a5,a5,a3
    80003822:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	01a080e7          	jalr	26(ra) # 80004842 <log_write>
        brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00000097          	auipc	ra,0x0
    80003836:	d94080e7          	jalr	-620(ra) # 800035c6 <brelse>
  bp = bread(dev, bno);
    8000383a:	85a6                	mv	a1,s1
    8000383c:	855e                	mv	a0,s7
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	c58080e7          	jalr	-936(ra) # 80003496 <bread>
    80003846:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003848:	40000613          	li	a2,1024
    8000384c:	4581                	li	a1,0
    8000384e:	05850513          	addi	a0,a0,88
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	48e080e7          	jalr	1166(ra) # 80000ce0 <memset>
  log_write(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	fe6080e7          	jalr	-26(ra) # 80004842 <log_write>
  brelse(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	d60080e7          	jalr	-672(ra) # 800035c6 <brelse>
}
    8000386e:	8526                	mv	a0,s1
    80003870:	60e6                	ld	ra,88(sp)
    80003872:	6446                	ld	s0,80(sp)
    80003874:	64a6                	ld	s1,72(sp)
    80003876:	6906                	ld	s2,64(sp)
    80003878:	79e2                	ld	s3,56(sp)
    8000387a:	7a42                	ld	s4,48(sp)
    8000387c:	7aa2                	ld	s5,40(sp)
    8000387e:	7b02                	ld	s6,32(sp)
    80003880:	6be2                	ld	s7,24(sp)
    80003882:	6c42                	ld	s8,16(sp)
    80003884:	6ca2                	ld	s9,8(sp)
    80003886:	6125                	addi	sp,sp,96
    80003888:	8082                	ret

000000008000388a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000388a:	7179                	addi	sp,sp,-48
    8000388c:	f406                	sd	ra,40(sp)
    8000388e:	f022                	sd	s0,32(sp)
    80003890:	ec26                	sd	s1,24(sp)
    80003892:	e84a                	sd	s2,16(sp)
    80003894:	e44e                	sd	s3,8(sp)
    80003896:	e052                	sd	s4,0(sp)
    80003898:	1800                	addi	s0,sp,48
    8000389a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000389c:	47ad                	li	a5,11
    8000389e:	04b7fe63          	bgeu	a5,a1,800038fa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038a2:	ff45849b          	addiw	s1,a1,-12
    800038a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038aa:	0ff00793          	li	a5,255
    800038ae:	0ae7e363          	bltu	a5,a4,80003954 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038b2:	08052583          	lw	a1,128(a0)
    800038b6:	c5ad                	beqz	a1,80003920 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038b8:	00092503          	lw	a0,0(s2)
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	bda080e7          	jalr	-1062(ra) # 80003496 <bread>
    800038c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038ca:	02049593          	slli	a1,s1,0x20
    800038ce:	9181                	srli	a1,a1,0x20
    800038d0:	058a                	slli	a1,a1,0x2
    800038d2:	00b784b3          	add	s1,a5,a1
    800038d6:	0004a983          	lw	s3,0(s1)
    800038da:	04098d63          	beqz	s3,80003934 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038de:	8552                	mv	a0,s4
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	ce6080e7          	jalr	-794(ra) # 800035c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038e8:	854e                	mv	a0,s3
    800038ea:	70a2                	ld	ra,40(sp)
    800038ec:	7402                	ld	s0,32(sp)
    800038ee:	64e2                	ld	s1,24(sp)
    800038f0:	6942                	ld	s2,16(sp)
    800038f2:	69a2                	ld	s3,8(sp)
    800038f4:	6a02                	ld	s4,0(sp)
    800038f6:	6145                	addi	sp,sp,48
    800038f8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038fa:	02059493          	slli	s1,a1,0x20
    800038fe:	9081                	srli	s1,s1,0x20
    80003900:	048a                	slli	s1,s1,0x2
    80003902:	94aa                	add	s1,s1,a0
    80003904:	0504a983          	lw	s3,80(s1)
    80003908:	fe0990e3          	bnez	s3,800038e8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000390c:	4108                	lw	a0,0(a0)
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	e4a080e7          	jalr	-438(ra) # 80003758 <balloc>
    80003916:	0005099b          	sext.w	s3,a0
    8000391a:	0534a823          	sw	s3,80(s1)
    8000391e:	b7e9                	j	800038e8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003920:	4108                	lw	a0,0(a0)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e36080e7          	jalr	-458(ra) # 80003758 <balloc>
    8000392a:	0005059b          	sext.w	a1,a0
    8000392e:	08b92023          	sw	a1,128(s2)
    80003932:	b759                	j	800038b8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003934:	00092503          	lw	a0,0(s2)
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	e20080e7          	jalr	-480(ra) # 80003758 <balloc>
    80003940:	0005099b          	sext.w	s3,a0
    80003944:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003948:	8552                	mv	a0,s4
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	ef8080e7          	jalr	-264(ra) # 80004842 <log_write>
    80003952:	b771                	j	800038de <bmap+0x54>
  panic("bmap: out of range");
    80003954:	00005517          	auipc	a0,0x5
    80003958:	cf450513          	addi	a0,a0,-780 # 80008648 <syscalls+0x130>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	be2080e7          	jalr	-1054(ra) # 8000053e <panic>

0000000080003964 <iget>:
{
    80003964:	7179                	addi	sp,sp,-48
    80003966:	f406                	sd	ra,40(sp)
    80003968:	f022                	sd	s0,32(sp)
    8000396a:	ec26                	sd	s1,24(sp)
    8000396c:	e84a                	sd	s2,16(sp)
    8000396e:	e44e                	sd	s3,8(sp)
    80003970:	e052                	sd	s4,0(sp)
    80003972:	1800                	addi	s0,sp,48
    80003974:	89aa                	mv	s3,a0
    80003976:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003978:	00015517          	auipc	a0,0x15
    8000397c:	1e050513          	addi	a0,a0,480 # 80018b58 <itable>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	264080e7          	jalr	612(ra) # 80000be4 <acquire>
  empty = 0;
    80003988:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000398a:	00015497          	auipc	s1,0x15
    8000398e:	1e648493          	addi	s1,s1,486 # 80018b70 <itable+0x18>
    80003992:	00017697          	auipc	a3,0x17
    80003996:	c6e68693          	addi	a3,a3,-914 # 8001a600 <log>
    8000399a:	a039                	j	800039a8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000399c:	02090b63          	beqz	s2,800039d2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039a0:	08848493          	addi	s1,s1,136
    800039a4:	02d48a63          	beq	s1,a3,800039d8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039a8:	449c                	lw	a5,8(s1)
    800039aa:	fef059e3          	blez	a5,8000399c <iget+0x38>
    800039ae:	4098                	lw	a4,0(s1)
    800039b0:	ff3716e3          	bne	a4,s3,8000399c <iget+0x38>
    800039b4:	40d8                	lw	a4,4(s1)
    800039b6:	ff4713e3          	bne	a4,s4,8000399c <iget+0x38>
      ip->ref++;
    800039ba:	2785                	addiw	a5,a5,1
    800039bc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039be:	00015517          	auipc	a0,0x15
    800039c2:	19a50513          	addi	a0,a0,410 # 80018b58 <itable>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	2d2080e7          	jalr	722(ra) # 80000c98 <release>
      return ip;
    800039ce:	8926                	mv	s2,s1
    800039d0:	a03d                	j	800039fe <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039d2:	f7f9                	bnez	a5,800039a0 <iget+0x3c>
    800039d4:	8926                	mv	s2,s1
    800039d6:	b7e9                	j	800039a0 <iget+0x3c>
  if(empty == 0)
    800039d8:	02090c63          	beqz	s2,80003a10 <iget+0xac>
  ip->dev = dev;
    800039dc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039e0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039e4:	4785                	li	a5,1
    800039e6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039ea:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039ee:	00015517          	auipc	a0,0x15
    800039f2:	16a50513          	addi	a0,a0,362 # 80018b58 <itable>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	2a2080e7          	jalr	674(ra) # 80000c98 <release>
}
    800039fe:	854a                	mv	a0,s2
    80003a00:	70a2                	ld	ra,40(sp)
    80003a02:	7402                	ld	s0,32(sp)
    80003a04:	64e2                	ld	s1,24(sp)
    80003a06:	6942                	ld	s2,16(sp)
    80003a08:	69a2                	ld	s3,8(sp)
    80003a0a:	6a02                	ld	s4,0(sp)
    80003a0c:	6145                	addi	sp,sp,48
    80003a0e:	8082                	ret
    panic("iget: no inodes");
    80003a10:	00005517          	auipc	a0,0x5
    80003a14:	c5050513          	addi	a0,a0,-944 # 80008660 <syscalls+0x148>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080003a20 <fsinit>:
fsinit(int dev) {
    80003a20:	7179                	addi	sp,sp,-48
    80003a22:	f406                	sd	ra,40(sp)
    80003a24:	f022                	sd	s0,32(sp)
    80003a26:	ec26                	sd	s1,24(sp)
    80003a28:	e84a                	sd	s2,16(sp)
    80003a2a:	e44e                	sd	s3,8(sp)
    80003a2c:	1800                	addi	s0,sp,48
    80003a2e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a30:	4585                	li	a1,1
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	a64080e7          	jalr	-1436(ra) # 80003496 <bread>
    80003a3a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a3c:	00015997          	auipc	s3,0x15
    80003a40:	0fc98993          	addi	s3,s3,252 # 80018b38 <sb>
    80003a44:	02000613          	li	a2,32
    80003a48:	05850593          	addi	a1,a0,88
    80003a4c:	854e                	mv	a0,s3
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	2f2080e7          	jalr	754(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a56:	8526                	mv	a0,s1
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	b6e080e7          	jalr	-1170(ra) # 800035c6 <brelse>
  if(sb.magic != FSMAGIC)
    80003a60:	0009a703          	lw	a4,0(s3)
    80003a64:	102037b7          	lui	a5,0x10203
    80003a68:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a6c:	02f71263          	bne	a4,a5,80003a90 <fsinit+0x70>
  initlog(dev, &sb);
    80003a70:	00015597          	auipc	a1,0x15
    80003a74:	0c858593          	addi	a1,a1,200 # 80018b38 <sb>
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	b4c080e7          	jalr	-1204(ra) # 800045c6 <initlog>
}
    80003a82:	70a2                	ld	ra,40(sp)
    80003a84:	7402                	ld	s0,32(sp)
    80003a86:	64e2                	ld	s1,24(sp)
    80003a88:	6942                	ld	s2,16(sp)
    80003a8a:	69a2                	ld	s3,8(sp)
    80003a8c:	6145                	addi	sp,sp,48
    80003a8e:	8082                	ret
    panic("invalid file system");
    80003a90:	00005517          	auipc	a0,0x5
    80003a94:	be050513          	addi	a0,a0,-1056 # 80008670 <syscalls+0x158>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>

0000000080003aa0 <iinit>:
{
    80003aa0:	7179                	addi	sp,sp,-48
    80003aa2:	f406                	sd	ra,40(sp)
    80003aa4:	f022                	sd	s0,32(sp)
    80003aa6:	ec26                	sd	s1,24(sp)
    80003aa8:	e84a                	sd	s2,16(sp)
    80003aaa:	e44e                	sd	s3,8(sp)
    80003aac:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003aae:	00005597          	auipc	a1,0x5
    80003ab2:	bda58593          	addi	a1,a1,-1062 # 80008688 <syscalls+0x170>
    80003ab6:	00015517          	auipc	a0,0x15
    80003aba:	0a250513          	addi	a0,a0,162 # 80018b58 <itable>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	096080e7          	jalr	150(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ac6:	00015497          	auipc	s1,0x15
    80003aca:	0ba48493          	addi	s1,s1,186 # 80018b80 <itable+0x28>
    80003ace:	00017997          	auipc	s3,0x17
    80003ad2:	b4298993          	addi	s3,s3,-1214 # 8001a610 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ad6:	00005917          	auipc	s2,0x5
    80003ada:	bba90913          	addi	s2,s2,-1094 # 80008690 <syscalls+0x178>
    80003ade:	85ca                	mv	a1,s2
    80003ae0:	8526                	mv	a0,s1
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	e46080e7          	jalr	-442(ra) # 80004928 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003aea:	08848493          	addi	s1,s1,136
    80003aee:	ff3498e3          	bne	s1,s3,80003ade <iinit+0x3e>
}
    80003af2:	70a2                	ld	ra,40(sp)
    80003af4:	7402                	ld	s0,32(sp)
    80003af6:	64e2                	ld	s1,24(sp)
    80003af8:	6942                	ld	s2,16(sp)
    80003afa:	69a2                	ld	s3,8(sp)
    80003afc:	6145                	addi	sp,sp,48
    80003afe:	8082                	ret

0000000080003b00 <ialloc>:
{
    80003b00:	715d                	addi	sp,sp,-80
    80003b02:	e486                	sd	ra,72(sp)
    80003b04:	e0a2                	sd	s0,64(sp)
    80003b06:	fc26                	sd	s1,56(sp)
    80003b08:	f84a                	sd	s2,48(sp)
    80003b0a:	f44e                	sd	s3,40(sp)
    80003b0c:	f052                	sd	s4,32(sp)
    80003b0e:	ec56                	sd	s5,24(sp)
    80003b10:	e85a                	sd	s6,16(sp)
    80003b12:	e45e                	sd	s7,8(sp)
    80003b14:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b16:	00015717          	auipc	a4,0x15
    80003b1a:	02e72703          	lw	a4,46(a4) # 80018b44 <sb+0xc>
    80003b1e:	4785                	li	a5,1
    80003b20:	04e7fa63          	bgeu	a5,a4,80003b74 <ialloc+0x74>
    80003b24:	8aaa                	mv	s5,a0
    80003b26:	8bae                	mv	s7,a1
    80003b28:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b2a:	00015a17          	auipc	s4,0x15
    80003b2e:	00ea0a13          	addi	s4,s4,14 # 80018b38 <sb>
    80003b32:	00048b1b          	sext.w	s6,s1
    80003b36:	0044d593          	srli	a1,s1,0x4
    80003b3a:	018a2783          	lw	a5,24(s4)
    80003b3e:	9dbd                	addw	a1,a1,a5
    80003b40:	8556                	mv	a0,s5
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	954080e7          	jalr	-1708(ra) # 80003496 <bread>
    80003b4a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b4c:	05850993          	addi	s3,a0,88
    80003b50:	00f4f793          	andi	a5,s1,15
    80003b54:	079a                	slli	a5,a5,0x6
    80003b56:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b58:	00099783          	lh	a5,0(s3)
    80003b5c:	c785                	beqz	a5,80003b84 <ialloc+0x84>
    brelse(bp);
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	a68080e7          	jalr	-1432(ra) # 800035c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b66:	0485                	addi	s1,s1,1
    80003b68:	00ca2703          	lw	a4,12(s4)
    80003b6c:	0004879b          	sext.w	a5,s1
    80003b70:	fce7e1e3          	bltu	a5,a4,80003b32 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b74:	00005517          	auipc	a0,0x5
    80003b78:	b2450513          	addi	a0,a0,-1244 # 80008698 <syscalls+0x180>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	9c2080e7          	jalr	-1598(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b84:	04000613          	li	a2,64
    80003b88:	4581                	li	a1,0
    80003b8a:	854e                	mv	a0,s3
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	154080e7          	jalr	340(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b94:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00001097          	auipc	ra,0x1
    80003b9e:	ca8080e7          	jalr	-856(ra) # 80004842 <log_write>
      brelse(bp);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	a22080e7          	jalr	-1502(ra) # 800035c6 <brelse>
      return iget(dev, inum);
    80003bac:	85da                	mv	a1,s6
    80003bae:	8556                	mv	a0,s5
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	db4080e7          	jalr	-588(ra) # 80003964 <iget>
}
    80003bb8:	60a6                	ld	ra,72(sp)
    80003bba:	6406                	ld	s0,64(sp)
    80003bbc:	74e2                	ld	s1,56(sp)
    80003bbe:	7942                	ld	s2,48(sp)
    80003bc0:	79a2                	ld	s3,40(sp)
    80003bc2:	7a02                	ld	s4,32(sp)
    80003bc4:	6ae2                	ld	s5,24(sp)
    80003bc6:	6b42                	ld	s6,16(sp)
    80003bc8:	6ba2                	ld	s7,8(sp)
    80003bca:	6161                	addi	sp,sp,80
    80003bcc:	8082                	ret

0000000080003bce <iupdate>:
{
    80003bce:	1101                	addi	sp,sp,-32
    80003bd0:	ec06                	sd	ra,24(sp)
    80003bd2:	e822                	sd	s0,16(sp)
    80003bd4:	e426                	sd	s1,8(sp)
    80003bd6:	e04a                	sd	s2,0(sp)
    80003bd8:	1000                	addi	s0,sp,32
    80003bda:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bdc:	415c                	lw	a5,4(a0)
    80003bde:	0047d79b          	srliw	a5,a5,0x4
    80003be2:	00015597          	auipc	a1,0x15
    80003be6:	f6e5a583          	lw	a1,-146(a1) # 80018b50 <sb+0x18>
    80003bea:	9dbd                	addw	a1,a1,a5
    80003bec:	4108                	lw	a0,0(a0)
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	8a8080e7          	jalr	-1880(ra) # 80003496 <bread>
    80003bf6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bf8:	05850793          	addi	a5,a0,88
    80003bfc:	40c8                	lw	a0,4(s1)
    80003bfe:	893d                	andi	a0,a0,15
    80003c00:	051a                	slli	a0,a0,0x6
    80003c02:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c04:	04449703          	lh	a4,68(s1)
    80003c08:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c0c:	04649703          	lh	a4,70(s1)
    80003c10:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c14:	04849703          	lh	a4,72(s1)
    80003c18:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c1c:	04a49703          	lh	a4,74(s1)
    80003c20:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c24:	44f8                	lw	a4,76(s1)
    80003c26:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c28:	03400613          	li	a2,52
    80003c2c:	05048593          	addi	a1,s1,80
    80003c30:	0531                	addi	a0,a0,12
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	10e080e7          	jalr	270(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00001097          	auipc	ra,0x1
    80003c40:	c06080e7          	jalr	-1018(ra) # 80004842 <log_write>
  brelse(bp);
    80003c44:	854a                	mv	a0,s2
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	980080e7          	jalr	-1664(ra) # 800035c6 <brelse>
}
    80003c4e:	60e2                	ld	ra,24(sp)
    80003c50:	6442                	ld	s0,16(sp)
    80003c52:	64a2                	ld	s1,8(sp)
    80003c54:	6902                	ld	s2,0(sp)
    80003c56:	6105                	addi	sp,sp,32
    80003c58:	8082                	ret

0000000080003c5a <idup>:
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	e426                	sd	s1,8(sp)
    80003c62:	1000                	addi	s0,sp,32
    80003c64:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c66:	00015517          	auipc	a0,0x15
    80003c6a:	ef250513          	addi	a0,a0,-270 # 80018b58 <itable>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	f76080e7          	jalr	-138(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c76:	449c                	lw	a5,8(s1)
    80003c78:	2785                	addiw	a5,a5,1
    80003c7a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c7c:	00015517          	auipc	a0,0x15
    80003c80:	edc50513          	addi	a0,a0,-292 # 80018b58 <itable>
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
}
    80003c8c:	8526                	mv	a0,s1
    80003c8e:	60e2                	ld	ra,24(sp)
    80003c90:	6442                	ld	s0,16(sp)
    80003c92:	64a2                	ld	s1,8(sp)
    80003c94:	6105                	addi	sp,sp,32
    80003c96:	8082                	ret

0000000080003c98 <ilock>:
{
    80003c98:	1101                	addi	sp,sp,-32
    80003c9a:	ec06                	sd	ra,24(sp)
    80003c9c:	e822                	sd	s0,16(sp)
    80003c9e:	e426                	sd	s1,8(sp)
    80003ca0:	e04a                	sd	s2,0(sp)
    80003ca2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ca4:	c115                	beqz	a0,80003cc8 <ilock+0x30>
    80003ca6:	84aa                	mv	s1,a0
    80003ca8:	451c                	lw	a5,8(a0)
    80003caa:	00f05f63          	blez	a5,80003cc8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cae:	0541                	addi	a0,a0,16
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	cb2080e7          	jalr	-846(ra) # 80004962 <acquiresleep>
  if(ip->valid == 0){
    80003cb8:	40bc                	lw	a5,64(s1)
    80003cba:	cf99                	beqz	a5,80003cd8 <ilock+0x40>
}
    80003cbc:	60e2                	ld	ra,24(sp)
    80003cbe:	6442                	ld	s0,16(sp)
    80003cc0:	64a2                	ld	s1,8(sp)
    80003cc2:	6902                	ld	s2,0(sp)
    80003cc4:	6105                	addi	sp,sp,32
    80003cc6:	8082                	ret
    panic("ilock");
    80003cc8:	00005517          	auipc	a0,0x5
    80003ccc:	9e850513          	addi	a0,a0,-1560 # 800086b0 <syscalls+0x198>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	86e080e7          	jalr	-1938(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cd8:	40dc                	lw	a5,4(s1)
    80003cda:	0047d79b          	srliw	a5,a5,0x4
    80003cde:	00015597          	auipc	a1,0x15
    80003ce2:	e725a583          	lw	a1,-398(a1) # 80018b50 <sb+0x18>
    80003ce6:	9dbd                	addw	a1,a1,a5
    80003ce8:	4088                	lw	a0,0(s1)
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	7ac080e7          	jalr	1964(ra) # 80003496 <bread>
    80003cf2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cf4:	05850593          	addi	a1,a0,88
    80003cf8:	40dc                	lw	a5,4(s1)
    80003cfa:	8bbd                	andi	a5,a5,15
    80003cfc:	079a                	slli	a5,a5,0x6
    80003cfe:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d00:	00059783          	lh	a5,0(a1)
    80003d04:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d08:	00259783          	lh	a5,2(a1)
    80003d0c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d10:	00459783          	lh	a5,4(a1)
    80003d14:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d18:	00659783          	lh	a5,6(a1)
    80003d1c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d20:	459c                	lw	a5,8(a1)
    80003d22:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d24:	03400613          	li	a2,52
    80003d28:	05b1                	addi	a1,a1,12
    80003d2a:	05048513          	addi	a0,s1,80
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	012080e7          	jalr	18(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d36:	854a                	mv	a0,s2
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	88e080e7          	jalr	-1906(ra) # 800035c6 <brelse>
    ip->valid = 1;
    80003d40:	4785                	li	a5,1
    80003d42:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d44:	04449783          	lh	a5,68(s1)
    80003d48:	fbb5                	bnez	a5,80003cbc <ilock+0x24>
      panic("ilock: no type");
    80003d4a:	00005517          	auipc	a0,0x5
    80003d4e:	96e50513          	addi	a0,a0,-1682 # 800086b8 <syscalls+0x1a0>
    80003d52:	ffffc097          	auipc	ra,0xffffc
    80003d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>

0000000080003d5a <iunlock>:
{
    80003d5a:	1101                	addi	sp,sp,-32
    80003d5c:	ec06                	sd	ra,24(sp)
    80003d5e:	e822                	sd	s0,16(sp)
    80003d60:	e426                	sd	s1,8(sp)
    80003d62:	e04a                	sd	s2,0(sp)
    80003d64:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d66:	c905                	beqz	a0,80003d96 <iunlock+0x3c>
    80003d68:	84aa                	mv	s1,a0
    80003d6a:	01050913          	addi	s2,a0,16
    80003d6e:	854a                	mv	a0,s2
    80003d70:	00001097          	auipc	ra,0x1
    80003d74:	c8c080e7          	jalr	-884(ra) # 800049fc <holdingsleep>
    80003d78:	cd19                	beqz	a0,80003d96 <iunlock+0x3c>
    80003d7a:	449c                	lw	a5,8(s1)
    80003d7c:	00f05d63          	blez	a5,80003d96 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d80:	854a                	mv	a0,s2
    80003d82:	00001097          	auipc	ra,0x1
    80003d86:	c36080e7          	jalr	-970(ra) # 800049b8 <releasesleep>
}
    80003d8a:	60e2                	ld	ra,24(sp)
    80003d8c:	6442                	ld	s0,16(sp)
    80003d8e:	64a2                	ld	s1,8(sp)
    80003d90:	6902                	ld	s2,0(sp)
    80003d92:	6105                	addi	sp,sp,32
    80003d94:	8082                	ret
    panic("iunlock");
    80003d96:	00005517          	auipc	a0,0x5
    80003d9a:	93250513          	addi	a0,a0,-1742 # 800086c8 <syscalls+0x1b0>
    80003d9e:	ffffc097          	auipc	ra,0xffffc
    80003da2:	7a0080e7          	jalr	1952(ra) # 8000053e <panic>

0000000080003da6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003da6:	7179                	addi	sp,sp,-48
    80003da8:	f406                	sd	ra,40(sp)
    80003daa:	f022                	sd	s0,32(sp)
    80003dac:	ec26                	sd	s1,24(sp)
    80003dae:	e84a                	sd	s2,16(sp)
    80003db0:	e44e                	sd	s3,8(sp)
    80003db2:	e052                	sd	s4,0(sp)
    80003db4:	1800                	addi	s0,sp,48
    80003db6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003db8:	05050493          	addi	s1,a0,80
    80003dbc:	08050913          	addi	s2,a0,128
    80003dc0:	a021                	j	80003dc8 <itrunc+0x22>
    80003dc2:	0491                	addi	s1,s1,4
    80003dc4:	01248d63          	beq	s1,s2,80003dde <itrunc+0x38>
    if(ip->addrs[i]){
    80003dc8:	408c                	lw	a1,0(s1)
    80003dca:	dde5                	beqz	a1,80003dc2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dcc:	0009a503          	lw	a0,0(s3)
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	90c080e7          	jalr	-1780(ra) # 800036dc <bfree>
      ip->addrs[i] = 0;
    80003dd8:	0004a023          	sw	zero,0(s1)
    80003ddc:	b7dd                	j	80003dc2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dde:	0809a583          	lw	a1,128(s3)
    80003de2:	e185                	bnez	a1,80003e02 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003de4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003de8:	854e                	mv	a0,s3
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	de4080e7          	jalr	-540(ra) # 80003bce <iupdate>
}
    80003df2:	70a2                	ld	ra,40(sp)
    80003df4:	7402                	ld	s0,32(sp)
    80003df6:	64e2                	ld	s1,24(sp)
    80003df8:	6942                	ld	s2,16(sp)
    80003dfa:	69a2                	ld	s3,8(sp)
    80003dfc:	6a02                	ld	s4,0(sp)
    80003dfe:	6145                	addi	sp,sp,48
    80003e00:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e02:	0009a503          	lw	a0,0(s3)
    80003e06:	fffff097          	auipc	ra,0xfffff
    80003e0a:	690080e7          	jalr	1680(ra) # 80003496 <bread>
    80003e0e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e10:	05850493          	addi	s1,a0,88
    80003e14:	45850913          	addi	s2,a0,1112
    80003e18:	a811                	j	80003e2c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e1a:	0009a503          	lw	a0,0(s3)
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	8be080e7          	jalr	-1858(ra) # 800036dc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e26:	0491                	addi	s1,s1,4
    80003e28:	01248563          	beq	s1,s2,80003e32 <itrunc+0x8c>
      if(a[j])
    80003e2c:	408c                	lw	a1,0(s1)
    80003e2e:	dde5                	beqz	a1,80003e26 <itrunc+0x80>
    80003e30:	b7ed                	j	80003e1a <itrunc+0x74>
    brelse(bp);
    80003e32:	8552                	mv	a0,s4
    80003e34:	fffff097          	auipc	ra,0xfffff
    80003e38:	792080e7          	jalr	1938(ra) # 800035c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e3c:	0809a583          	lw	a1,128(s3)
    80003e40:	0009a503          	lw	a0,0(s3)
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	898080e7          	jalr	-1896(ra) # 800036dc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e4c:	0809a023          	sw	zero,128(s3)
    80003e50:	bf51                	j	80003de4 <itrunc+0x3e>

0000000080003e52 <iput>:
{
    80003e52:	1101                	addi	sp,sp,-32
    80003e54:	ec06                	sd	ra,24(sp)
    80003e56:	e822                	sd	s0,16(sp)
    80003e58:	e426                	sd	s1,8(sp)
    80003e5a:	e04a                	sd	s2,0(sp)
    80003e5c:	1000                	addi	s0,sp,32
    80003e5e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e60:	00015517          	auipc	a0,0x15
    80003e64:	cf850513          	addi	a0,a0,-776 # 80018b58 <itable>
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	d7c080e7          	jalr	-644(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e70:	4498                	lw	a4,8(s1)
    80003e72:	4785                	li	a5,1
    80003e74:	02f70363          	beq	a4,a5,80003e9a <iput+0x48>
  ip->ref--;
    80003e78:	449c                	lw	a5,8(s1)
    80003e7a:	37fd                	addiw	a5,a5,-1
    80003e7c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e7e:	00015517          	auipc	a0,0x15
    80003e82:	cda50513          	addi	a0,a0,-806 # 80018b58 <itable>
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	e12080e7          	jalr	-494(ra) # 80000c98 <release>
}
    80003e8e:	60e2                	ld	ra,24(sp)
    80003e90:	6442                	ld	s0,16(sp)
    80003e92:	64a2                	ld	s1,8(sp)
    80003e94:	6902                	ld	s2,0(sp)
    80003e96:	6105                	addi	sp,sp,32
    80003e98:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e9a:	40bc                	lw	a5,64(s1)
    80003e9c:	dff1                	beqz	a5,80003e78 <iput+0x26>
    80003e9e:	04a49783          	lh	a5,74(s1)
    80003ea2:	fbf9                	bnez	a5,80003e78 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ea4:	01048913          	addi	s2,s1,16
    80003ea8:	854a                	mv	a0,s2
    80003eaa:	00001097          	auipc	ra,0x1
    80003eae:	ab8080e7          	jalr	-1352(ra) # 80004962 <acquiresleep>
    release(&itable.lock);
    80003eb2:	00015517          	auipc	a0,0x15
    80003eb6:	ca650513          	addi	a0,a0,-858 # 80018b58 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	dde080e7          	jalr	-546(ra) # 80000c98 <release>
    itrunc(ip);
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	ee2080e7          	jalr	-286(ra) # 80003da6 <itrunc>
    ip->type = 0;
    80003ecc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ed0:	8526                	mv	a0,s1
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	cfc080e7          	jalr	-772(ra) # 80003bce <iupdate>
    ip->valid = 0;
    80003eda:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ede:	854a                	mv	a0,s2
    80003ee0:	00001097          	auipc	ra,0x1
    80003ee4:	ad8080e7          	jalr	-1320(ra) # 800049b8 <releasesleep>
    acquire(&itable.lock);
    80003ee8:	00015517          	auipc	a0,0x15
    80003eec:	c7050513          	addi	a0,a0,-912 # 80018b58 <itable>
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	cf4080e7          	jalr	-780(ra) # 80000be4 <acquire>
    80003ef8:	b741                	j	80003e78 <iput+0x26>

0000000080003efa <iunlockput>:
{
    80003efa:	1101                	addi	sp,sp,-32
    80003efc:	ec06                	sd	ra,24(sp)
    80003efe:	e822                	sd	s0,16(sp)
    80003f00:	e426                	sd	s1,8(sp)
    80003f02:	1000                	addi	s0,sp,32
    80003f04:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	e54080e7          	jalr	-428(ra) # 80003d5a <iunlock>
  iput(ip);
    80003f0e:	8526                	mv	a0,s1
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	f42080e7          	jalr	-190(ra) # 80003e52 <iput>
}
    80003f18:	60e2                	ld	ra,24(sp)
    80003f1a:	6442                	ld	s0,16(sp)
    80003f1c:	64a2                	ld	s1,8(sp)
    80003f1e:	6105                	addi	sp,sp,32
    80003f20:	8082                	ret

0000000080003f22 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f22:	1141                	addi	sp,sp,-16
    80003f24:	e422                	sd	s0,8(sp)
    80003f26:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f28:	411c                	lw	a5,0(a0)
    80003f2a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f2c:	415c                	lw	a5,4(a0)
    80003f2e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f30:	04451783          	lh	a5,68(a0)
    80003f34:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f38:	04a51783          	lh	a5,74(a0)
    80003f3c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f40:	04c56783          	lwu	a5,76(a0)
    80003f44:	e99c                	sd	a5,16(a1)
}
    80003f46:	6422                	ld	s0,8(sp)
    80003f48:	0141                	addi	sp,sp,16
    80003f4a:	8082                	ret

0000000080003f4c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f4c:	457c                	lw	a5,76(a0)
    80003f4e:	0ed7e963          	bltu	a5,a3,80004040 <readi+0xf4>
{
    80003f52:	7159                	addi	sp,sp,-112
    80003f54:	f486                	sd	ra,104(sp)
    80003f56:	f0a2                	sd	s0,96(sp)
    80003f58:	eca6                	sd	s1,88(sp)
    80003f5a:	e8ca                	sd	s2,80(sp)
    80003f5c:	e4ce                	sd	s3,72(sp)
    80003f5e:	e0d2                	sd	s4,64(sp)
    80003f60:	fc56                	sd	s5,56(sp)
    80003f62:	f85a                	sd	s6,48(sp)
    80003f64:	f45e                	sd	s7,40(sp)
    80003f66:	f062                	sd	s8,32(sp)
    80003f68:	ec66                	sd	s9,24(sp)
    80003f6a:	e86a                	sd	s10,16(sp)
    80003f6c:	e46e                	sd	s11,8(sp)
    80003f6e:	1880                	addi	s0,sp,112
    80003f70:	8baa                	mv	s7,a0
    80003f72:	8c2e                	mv	s8,a1
    80003f74:	8ab2                	mv	s5,a2
    80003f76:	84b6                	mv	s1,a3
    80003f78:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f7a:	9f35                	addw	a4,a4,a3
    return 0;
    80003f7c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f7e:	0ad76063          	bltu	a4,a3,8000401e <readi+0xd2>
  if(off + n > ip->size)
    80003f82:	00e7f463          	bgeu	a5,a4,80003f8a <readi+0x3e>
    n = ip->size - off;
    80003f86:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8a:	0a0b0963          	beqz	s6,8000403c <readi+0xf0>
    80003f8e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f90:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f94:	5cfd                	li	s9,-1
    80003f96:	a82d                	j	80003fd0 <readi+0x84>
    80003f98:	020a1d93          	slli	s11,s4,0x20
    80003f9c:	020ddd93          	srli	s11,s11,0x20
    80003fa0:	05890613          	addi	a2,s2,88
    80003fa4:	86ee                	mv	a3,s11
    80003fa6:	963a                	add	a2,a2,a4
    80003fa8:	85d6                	mv	a1,s5
    80003faa:	8562                	mv	a0,s8
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	9f4080e7          	jalr	-1548(ra) # 800029a0 <either_copyout>
    80003fb4:	05950d63          	beq	a0,s9,8000400e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fb8:	854a                	mv	a0,s2
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	60c080e7          	jalr	1548(ra) # 800035c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fc2:	013a09bb          	addw	s3,s4,s3
    80003fc6:	009a04bb          	addw	s1,s4,s1
    80003fca:	9aee                	add	s5,s5,s11
    80003fcc:	0569f763          	bgeu	s3,s6,8000401a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fd0:	000ba903          	lw	s2,0(s7)
    80003fd4:	00a4d59b          	srliw	a1,s1,0xa
    80003fd8:	855e                	mv	a0,s7
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	8b0080e7          	jalr	-1872(ra) # 8000388a <bmap>
    80003fe2:	0005059b          	sext.w	a1,a0
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	4ae080e7          	jalr	1198(ra) # 80003496 <bread>
    80003ff0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff2:	3ff4f713          	andi	a4,s1,1023
    80003ff6:	40ed07bb          	subw	a5,s10,a4
    80003ffa:	413b06bb          	subw	a3,s6,s3
    80003ffe:	8a3e                	mv	s4,a5
    80004000:	2781                	sext.w	a5,a5
    80004002:	0006861b          	sext.w	a2,a3
    80004006:	f8f679e3          	bgeu	a2,a5,80003f98 <readi+0x4c>
    8000400a:	8a36                	mv	s4,a3
    8000400c:	b771                	j	80003f98 <readi+0x4c>
      brelse(bp);
    8000400e:	854a                	mv	a0,s2
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	5b6080e7          	jalr	1462(ra) # 800035c6 <brelse>
      tot = -1;
    80004018:	59fd                	li	s3,-1
  }
  return tot;
    8000401a:	0009851b          	sext.w	a0,s3
}
    8000401e:	70a6                	ld	ra,104(sp)
    80004020:	7406                	ld	s0,96(sp)
    80004022:	64e6                	ld	s1,88(sp)
    80004024:	6946                	ld	s2,80(sp)
    80004026:	69a6                	ld	s3,72(sp)
    80004028:	6a06                	ld	s4,64(sp)
    8000402a:	7ae2                	ld	s5,56(sp)
    8000402c:	7b42                	ld	s6,48(sp)
    8000402e:	7ba2                	ld	s7,40(sp)
    80004030:	7c02                	ld	s8,32(sp)
    80004032:	6ce2                	ld	s9,24(sp)
    80004034:	6d42                	ld	s10,16(sp)
    80004036:	6da2                	ld	s11,8(sp)
    80004038:	6165                	addi	sp,sp,112
    8000403a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000403c:	89da                	mv	s3,s6
    8000403e:	bff1                	j	8000401a <readi+0xce>
    return 0;
    80004040:	4501                	li	a0,0
}
    80004042:	8082                	ret

0000000080004044 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004044:	457c                	lw	a5,76(a0)
    80004046:	10d7e863          	bltu	a5,a3,80004156 <writei+0x112>
{
    8000404a:	7159                	addi	sp,sp,-112
    8000404c:	f486                	sd	ra,104(sp)
    8000404e:	f0a2                	sd	s0,96(sp)
    80004050:	eca6                	sd	s1,88(sp)
    80004052:	e8ca                	sd	s2,80(sp)
    80004054:	e4ce                	sd	s3,72(sp)
    80004056:	e0d2                	sd	s4,64(sp)
    80004058:	fc56                	sd	s5,56(sp)
    8000405a:	f85a                	sd	s6,48(sp)
    8000405c:	f45e                	sd	s7,40(sp)
    8000405e:	f062                	sd	s8,32(sp)
    80004060:	ec66                	sd	s9,24(sp)
    80004062:	e86a                	sd	s10,16(sp)
    80004064:	e46e                	sd	s11,8(sp)
    80004066:	1880                	addi	s0,sp,112
    80004068:	8b2a                	mv	s6,a0
    8000406a:	8c2e                	mv	s8,a1
    8000406c:	8ab2                	mv	s5,a2
    8000406e:	8936                	mv	s2,a3
    80004070:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004072:	00e687bb          	addw	a5,a3,a4
    80004076:	0ed7e263          	bltu	a5,a3,8000415a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000407a:	00043737          	lui	a4,0x43
    8000407e:	0ef76063          	bltu	a4,a5,8000415e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004082:	0c0b8863          	beqz	s7,80004152 <writei+0x10e>
    80004086:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004088:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000408c:	5cfd                	li	s9,-1
    8000408e:	a091                	j	800040d2 <writei+0x8e>
    80004090:	02099d93          	slli	s11,s3,0x20
    80004094:	020ddd93          	srli	s11,s11,0x20
    80004098:	05848513          	addi	a0,s1,88
    8000409c:	86ee                	mv	a3,s11
    8000409e:	8656                	mv	a2,s5
    800040a0:	85e2                	mv	a1,s8
    800040a2:	953a                	add	a0,a0,a4
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	952080e7          	jalr	-1710(ra) # 800029f6 <either_copyin>
    800040ac:	07950263          	beq	a0,s9,80004110 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040b0:	8526                	mv	a0,s1
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	790080e7          	jalr	1936(ra) # 80004842 <log_write>
    brelse(bp);
    800040ba:	8526                	mv	a0,s1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	50a080e7          	jalr	1290(ra) # 800035c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040c4:	01498a3b          	addw	s4,s3,s4
    800040c8:	0129893b          	addw	s2,s3,s2
    800040cc:	9aee                	add	s5,s5,s11
    800040ce:	057a7663          	bgeu	s4,s7,8000411a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040d2:	000b2483          	lw	s1,0(s6)
    800040d6:	00a9559b          	srliw	a1,s2,0xa
    800040da:	855a                	mv	a0,s6
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	7ae080e7          	jalr	1966(ra) # 8000388a <bmap>
    800040e4:	0005059b          	sext.w	a1,a0
    800040e8:	8526                	mv	a0,s1
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	3ac080e7          	jalr	940(ra) # 80003496 <bread>
    800040f2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040f4:	3ff97713          	andi	a4,s2,1023
    800040f8:	40ed07bb          	subw	a5,s10,a4
    800040fc:	414b86bb          	subw	a3,s7,s4
    80004100:	89be                	mv	s3,a5
    80004102:	2781                	sext.w	a5,a5
    80004104:	0006861b          	sext.w	a2,a3
    80004108:	f8f674e3          	bgeu	a2,a5,80004090 <writei+0x4c>
    8000410c:	89b6                	mv	s3,a3
    8000410e:	b749                	j	80004090 <writei+0x4c>
      brelse(bp);
    80004110:	8526                	mv	a0,s1
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	4b4080e7          	jalr	1204(ra) # 800035c6 <brelse>
  }

  if(off > ip->size)
    8000411a:	04cb2783          	lw	a5,76(s6)
    8000411e:	0127f463          	bgeu	a5,s2,80004126 <writei+0xe2>
    ip->size = off;
    80004122:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004126:	855a                	mv	a0,s6
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	aa6080e7          	jalr	-1370(ra) # 80003bce <iupdate>

  return tot;
    80004130:	000a051b          	sext.w	a0,s4
}
    80004134:	70a6                	ld	ra,104(sp)
    80004136:	7406                	ld	s0,96(sp)
    80004138:	64e6                	ld	s1,88(sp)
    8000413a:	6946                	ld	s2,80(sp)
    8000413c:	69a6                	ld	s3,72(sp)
    8000413e:	6a06                	ld	s4,64(sp)
    80004140:	7ae2                	ld	s5,56(sp)
    80004142:	7b42                	ld	s6,48(sp)
    80004144:	7ba2                	ld	s7,40(sp)
    80004146:	7c02                	ld	s8,32(sp)
    80004148:	6ce2                	ld	s9,24(sp)
    8000414a:	6d42                	ld	s10,16(sp)
    8000414c:	6da2                	ld	s11,8(sp)
    8000414e:	6165                	addi	sp,sp,112
    80004150:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004152:	8a5e                	mv	s4,s7
    80004154:	bfc9                	j	80004126 <writei+0xe2>
    return -1;
    80004156:	557d                	li	a0,-1
}
    80004158:	8082                	ret
    return -1;
    8000415a:	557d                	li	a0,-1
    8000415c:	bfe1                	j	80004134 <writei+0xf0>
    return -1;
    8000415e:	557d                	li	a0,-1
    80004160:	bfd1                	j	80004134 <writei+0xf0>

0000000080004162 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004162:	1141                	addi	sp,sp,-16
    80004164:	e406                	sd	ra,8(sp)
    80004166:	e022                	sd	s0,0(sp)
    80004168:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000416a:	4639                	li	a2,14
    8000416c:	ffffd097          	auipc	ra,0xffffd
    80004170:	c4c080e7          	jalr	-948(ra) # 80000db8 <strncmp>
}
    80004174:	60a2                	ld	ra,8(sp)
    80004176:	6402                	ld	s0,0(sp)
    80004178:	0141                	addi	sp,sp,16
    8000417a:	8082                	ret

000000008000417c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000417c:	7139                	addi	sp,sp,-64
    8000417e:	fc06                	sd	ra,56(sp)
    80004180:	f822                	sd	s0,48(sp)
    80004182:	f426                	sd	s1,40(sp)
    80004184:	f04a                	sd	s2,32(sp)
    80004186:	ec4e                	sd	s3,24(sp)
    80004188:	e852                	sd	s4,16(sp)
    8000418a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000418c:	04451703          	lh	a4,68(a0)
    80004190:	4785                	li	a5,1
    80004192:	00f71a63          	bne	a4,a5,800041a6 <dirlookup+0x2a>
    80004196:	892a                	mv	s2,a0
    80004198:	89ae                	mv	s3,a1
    8000419a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000419c:	457c                	lw	a5,76(a0)
    8000419e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041a0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a2:	e79d                	bnez	a5,800041d0 <dirlookup+0x54>
    800041a4:	a8a5                	j	8000421c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041a6:	00004517          	auipc	a0,0x4
    800041aa:	52a50513          	addi	a0,a0,1322 # 800086d0 <syscalls+0x1b8>
    800041ae:	ffffc097          	auipc	ra,0xffffc
    800041b2:	390080e7          	jalr	912(ra) # 8000053e <panic>
      panic("dirlookup read");
    800041b6:	00004517          	auipc	a0,0x4
    800041ba:	53250513          	addi	a0,a0,1330 # 800086e8 <syscalls+0x1d0>
    800041be:	ffffc097          	auipc	ra,0xffffc
    800041c2:	380080e7          	jalr	896(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041c6:	24c1                	addiw	s1,s1,16
    800041c8:	04c92783          	lw	a5,76(s2)
    800041cc:	04f4f763          	bgeu	s1,a5,8000421a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d0:	4741                	li	a4,16
    800041d2:	86a6                	mv	a3,s1
    800041d4:	fc040613          	addi	a2,s0,-64
    800041d8:	4581                	li	a1,0
    800041da:	854a                	mv	a0,s2
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	d70080e7          	jalr	-656(ra) # 80003f4c <readi>
    800041e4:	47c1                	li	a5,16
    800041e6:	fcf518e3          	bne	a0,a5,800041b6 <dirlookup+0x3a>
    if(de.inum == 0)
    800041ea:	fc045783          	lhu	a5,-64(s0)
    800041ee:	dfe1                	beqz	a5,800041c6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041f0:	fc240593          	addi	a1,s0,-62
    800041f4:	854e                	mv	a0,s3
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	f6c080e7          	jalr	-148(ra) # 80004162 <namecmp>
    800041fe:	f561                	bnez	a0,800041c6 <dirlookup+0x4a>
      if(poff)
    80004200:	000a0463          	beqz	s4,80004208 <dirlookup+0x8c>
        *poff = off;
    80004204:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004208:	fc045583          	lhu	a1,-64(s0)
    8000420c:	00092503          	lw	a0,0(s2)
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	754080e7          	jalr	1876(ra) # 80003964 <iget>
    80004218:	a011                	j	8000421c <dirlookup+0xa0>
  return 0;
    8000421a:	4501                	li	a0,0
}
    8000421c:	70e2                	ld	ra,56(sp)
    8000421e:	7442                	ld	s0,48(sp)
    80004220:	74a2                	ld	s1,40(sp)
    80004222:	7902                	ld	s2,32(sp)
    80004224:	69e2                	ld	s3,24(sp)
    80004226:	6a42                	ld	s4,16(sp)
    80004228:	6121                	addi	sp,sp,64
    8000422a:	8082                	ret

000000008000422c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000422c:	711d                	addi	sp,sp,-96
    8000422e:	ec86                	sd	ra,88(sp)
    80004230:	e8a2                	sd	s0,80(sp)
    80004232:	e4a6                	sd	s1,72(sp)
    80004234:	e0ca                	sd	s2,64(sp)
    80004236:	fc4e                	sd	s3,56(sp)
    80004238:	f852                	sd	s4,48(sp)
    8000423a:	f456                	sd	s5,40(sp)
    8000423c:	f05a                	sd	s6,32(sp)
    8000423e:	ec5e                	sd	s7,24(sp)
    80004240:	e862                	sd	s8,16(sp)
    80004242:	e466                	sd	s9,8(sp)
    80004244:	1080                	addi	s0,sp,96
    80004246:	84aa                	mv	s1,a0
    80004248:	8b2e                	mv	s6,a1
    8000424a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000424c:	00054703          	lbu	a4,0(a0)
    80004250:	02f00793          	li	a5,47
    80004254:	02f70363          	beq	a4,a5,8000427a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	770080e7          	jalr	1904(ra) # 800019c8 <myproc>
    80004260:	15053503          	ld	a0,336(a0)
    80004264:	00000097          	auipc	ra,0x0
    80004268:	9f6080e7          	jalr	-1546(ra) # 80003c5a <idup>
    8000426c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000426e:	02f00913          	li	s2,47
  len = path - s;
    80004272:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004274:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004276:	4c05                	li	s8,1
    80004278:	a865                	j	80004330 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000427a:	4585                	li	a1,1
    8000427c:	4505                	li	a0,1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	6e6080e7          	jalr	1766(ra) # 80003964 <iget>
    80004286:	89aa                	mv	s3,a0
    80004288:	b7dd                	j	8000426e <namex+0x42>
      iunlockput(ip);
    8000428a:	854e                	mv	a0,s3
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	c6e080e7          	jalr	-914(ra) # 80003efa <iunlockput>
      return 0;
    80004294:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004296:	854e                	mv	a0,s3
    80004298:	60e6                	ld	ra,88(sp)
    8000429a:	6446                	ld	s0,80(sp)
    8000429c:	64a6                	ld	s1,72(sp)
    8000429e:	6906                	ld	s2,64(sp)
    800042a0:	79e2                	ld	s3,56(sp)
    800042a2:	7a42                	ld	s4,48(sp)
    800042a4:	7aa2                	ld	s5,40(sp)
    800042a6:	7b02                	ld	s6,32(sp)
    800042a8:	6be2                	ld	s7,24(sp)
    800042aa:	6c42                	ld	s8,16(sp)
    800042ac:	6ca2                	ld	s9,8(sp)
    800042ae:	6125                	addi	sp,sp,96
    800042b0:	8082                	ret
      iunlock(ip);
    800042b2:	854e                	mv	a0,s3
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	aa6080e7          	jalr	-1370(ra) # 80003d5a <iunlock>
      return ip;
    800042bc:	bfe9                	j	80004296 <namex+0x6a>
      iunlockput(ip);
    800042be:	854e                	mv	a0,s3
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c3a080e7          	jalr	-966(ra) # 80003efa <iunlockput>
      return 0;
    800042c8:	89d2                	mv	s3,s4
    800042ca:	b7f1                	j	80004296 <namex+0x6a>
  len = path - s;
    800042cc:	40b48633          	sub	a2,s1,a1
    800042d0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042d4:	094cd463          	bge	s9,s4,8000435c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042d8:	4639                	li	a2,14
    800042da:	8556                	mv	a0,s5
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	a64080e7          	jalr	-1436(ra) # 80000d40 <memmove>
  while(*path == '/')
    800042e4:	0004c783          	lbu	a5,0(s1)
    800042e8:	01279763          	bne	a5,s2,800042f6 <namex+0xca>
    path++;
    800042ec:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ee:	0004c783          	lbu	a5,0(s1)
    800042f2:	ff278de3          	beq	a5,s2,800042ec <namex+0xc0>
    ilock(ip);
    800042f6:	854e                	mv	a0,s3
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	9a0080e7          	jalr	-1632(ra) # 80003c98 <ilock>
    if(ip->type != T_DIR){
    80004300:	04499783          	lh	a5,68(s3)
    80004304:	f98793e3          	bne	a5,s8,8000428a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004308:	000b0563          	beqz	s6,80004312 <namex+0xe6>
    8000430c:	0004c783          	lbu	a5,0(s1)
    80004310:	d3cd                	beqz	a5,800042b2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004312:	865e                	mv	a2,s7
    80004314:	85d6                	mv	a1,s5
    80004316:	854e                	mv	a0,s3
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	e64080e7          	jalr	-412(ra) # 8000417c <dirlookup>
    80004320:	8a2a                	mv	s4,a0
    80004322:	dd51                	beqz	a0,800042be <namex+0x92>
    iunlockput(ip);
    80004324:	854e                	mv	a0,s3
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	bd4080e7          	jalr	-1068(ra) # 80003efa <iunlockput>
    ip = next;
    8000432e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004330:	0004c783          	lbu	a5,0(s1)
    80004334:	05279763          	bne	a5,s2,80004382 <namex+0x156>
    path++;
    80004338:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000433a:	0004c783          	lbu	a5,0(s1)
    8000433e:	ff278de3          	beq	a5,s2,80004338 <namex+0x10c>
  if(*path == 0)
    80004342:	c79d                	beqz	a5,80004370 <namex+0x144>
    path++;
    80004344:	85a6                	mv	a1,s1
  len = path - s;
    80004346:	8a5e                	mv	s4,s7
    80004348:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000434a:	01278963          	beq	a5,s2,8000435c <namex+0x130>
    8000434e:	dfbd                	beqz	a5,800042cc <namex+0xa0>
    path++;
    80004350:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004352:	0004c783          	lbu	a5,0(s1)
    80004356:	ff279ce3          	bne	a5,s2,8000434e <namex+0x122>
    8000435a:	bf8d                	j	800042cc <namex+0xa0>
    memmove(name, s, len);
    8000435c:	2601                	sext.w	a2,a2
    8000435e:	8556                	mv	a0,s5
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	9e0080e7          	jalr	-1568(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004368:	9a56                	add	s4,s4,s5
    8000436a:	000a0023          	sb	zero,0(s4)
    8000436e:	bf9d                	j	800042e4 <namex+0xb8>
  if(nameiparent){
    80004370:	f20b03e3          	beqz	s6,80004296 <namex+0x6a>
    iput(ip);
    80004374:	854e                	mv	a0,s3
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	adc080e7          	jalr	-1316(ra) # 80003e52 <iput>
    return 0;
    8000437e:	4981                	li	s3,0
    80004380:	bf19                	j	80004296 <namex+0x6a>
  if(*path == 0)
    80004382:	d7fd                	beqz	a5,80004370 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004384:	0004c783          	lbu	a5,0(s1)
    80004388:	85a6                	mv	a1,s1
    8000438a:	b7d1                	j	8000434e <namex+0x122>

000000008000438c <dirlink>:
{
    8000438c:	7139                	addi	sp,sp,-64
    8000438e:	fc06                	sd	ra,56(sp)
    80004390:	f822                	sd	s0,48(sp)
    80004392:	f426                	sd	s1,40(sp)
    80004394:	f04a                	sd	s2,32(sp)
    80004396:	ec4e                	sd	s3,24(sp)
    80004398:	e852                	sd	s4,16(sp)
    8000439a:	0080                	addi	s0,sp,64
    8000439c:	892a                	mv	s2,a0
    8000439e:	8a2e                	mv	s4,a1
    800043a0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043a2:	4601                	li	a2,0
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	dd8080e7          	jalr	-552(ra) # 8000417c <dirlookup>
    800043ac:	e93d                	bnez	a0,80004422 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ae:	04c92483          	lw	s1,76(s2)
    800043b2:	c49d                	beqz	s1,800043e0 <dirlink+0x54>
    800043b4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b6:	4741                	li	a4,16
    800043b8:	86a6                	mv	a3,s1
    800043ba:	fc040613          	addi	a2,s0,-64
    800043be:	4581                	li	a1,0
    800043c0:	854a                	mv	a0,s2
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	b8a080e7          	jalr	-1142(ra) # 80003f4c <readi>
    800043ca:	47c1                	li	a5,16
    800043cc:	06f51163          	bne	a0,a5,8000442e <dirlink+0xa2>
    if(de.inum == 0)
    800043d0:	fc045783          	lhu	a5,-64(s0)
    800043d4:	c791                	beqz	a5,800043e0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043d6:	24c1                	addiw	s1,s1,16
    800043d8:	04c92783          	lw	a5,76(s2)
    800043dc:	fcf4ede3          	bltu	s1,a5,800043b6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043e0:	4639                	li	a2,14
    800043e2:	85d2                	mv	a1,s4
    800043e4:	fc240513          	addi	a0,s0,-62
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	a0c080e7          	jalr	-1524(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800043f0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043f4:	4741                	li	a4,16
    800043f6:	86a6                	mv	a3,s1
    800043f8:	fc040613          	addi	a2,s0,-64
    800043fc:	4581                	li	a1,0
    800043fe:	854a                	mv	a0,s2
    80004400:	00000097          	auipc	ra,0x0
    80004404:	c44080e7          	jalr	-956(ra) # 80004044 <writei>
    80004408:	872a                	mv	a4,a0
    8000440a:	47c1                	li	a5,16
  return 0;
    8000440c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440e:	02f71863          	bne	a4,a5,8000443e <dirlink+0xb2>
}
    80004412:	70e2                	ld	ra,56(sp)
    80004414:	7442                	ld	s0,48(sp)
    80004416:	74a2                	ld	s1,40(sp)
    80004418:	7902                	ld	s2,32(sp)
    8000441a:	69e2                	ld	s3,24(sp)
    8000441c:	6a42                	ld	s4,16(sp)
    8000441e:	6121                	addi	sp,sp,64
    80004420:	8082                	ret
    iput(ip);
    80004422:	00000097          	auipc	ra,0x0
    80004426:	a30080e7          	jalr	-1488(ra) # 80003e52 <iput>
    return -1;
    8000442a:	557d                	li	a0,-1
    8000442c:	b7dd                	j	80004412 <dirlink+0x86>
      panic("dirlink read");
    8000442e:	00004517          	auipc	a0,0x4
    80004432:	2ca50513          	addi	a0,a0,714 # 800086f8 <syscalls+0x1e0>
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	108080e7          	jalr	264(ra) # 8000053e <panic>
    panic("dirlink");
    8000443e:	00004517          	auipc	a0,0x4
    80004442:	3ca50513          	addi	a0,a0,970 # 80008808 <syscalls+0x2f0>
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	0f8080e7          	jalr	248(ra) # 8000053e <panic>

000000008000444e <namei>:

struct inode*
namei(char *path)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004456:	fe040613          	addi	a2,s0,-32
    8000445a:	4581                	li	a1,0
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	dd0080e7          	jalr	-560(ra) # 8000422c <namex>
}
    80004464:	60e2                	ld	ra,24(sp)
    80004466:	6442                	ld	s0,16(sp)
    80004468:	6105                	addi	sp,sp,32
    8000446a:	8082                	ret

000000008000446c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000446c:	1141                	addi	sp,sp,-16
    8000446e:	e406                	sd	ra,8(sp)
    80004470:	e022                	sd	s0,0(sp)
    80004472:	0800                	addi	s0,sp,16
    80004474:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004476:	4585                	li	a1,1
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	db4080e7          	jalr	-588(ra) # 8000422c <namex>
}
    80004480:	60a2                	ld	ra,8(sp)
    80004482:	6402                	ld	s0,0(sp)
    80004484:	0141                	addi	sp,sp,16
    80004486:	8082                	ret

0000000080004488 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004494:	00016917          	auipc	s2,0x16
    80004498:	16c90913          	addi	s2,s2,364 # 8001a600 <log>
    8000449c:	01892583          	lw	a1,24(s2)
    800044a0:	02892503          	lw	a0,40(s2)
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	ff2080e7          	jalr	-14(ra) # 80003496 <bread>
    800044ac:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044ae:	02c92683          	lw	a3,44(s2)
    800044b2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044b4:	02d05763          	blez	a3,800044e2 <write_head+0x5a>
    800044b8:	00016797          	auipc	a5,0x16
    800044bc:	17878793          	addi	a5,a5,376 # 8001a630 <log+0x30>
    800044c0:	05c50713          	addi	a4,a0,92
    800044c4:	36fd                	addiw	a3,a3,-1
    800044c6:	1682                	slli	a3,a3,0x20
    800044c8:	9281                	srli	a3,a3,0x20
    800044ca:	068a                	slli	a3,a3,0x2
    800044cc:	00016617          	auipc	a2,0x16
    800044d0:	16860613          	addi	a2,a2,360 # 8001a634 <log+0x34>
    800044d4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044d6:	4390                	lw	a2,0(a5)
    800044d8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044da:	0791                	addi	a5,a5,4
    800044dc:	0711                	addi	a4,a4,4
    800044de:	fed79ce3          	bne	a5,a3,800044d6 <write_head+0x4e>
  }
  bwrite(buf);
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	0a4080e7          	jalr	164(ra) # 80003588 <bwrite>
  brelse(buf);
    800044ec:	8526                	mv	a0,s1
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	0d8080e7          	jalr	216(ra) # 800035c6 <brelse>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6902                	ld	s2,0(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004502:	00016797          	auipc	a5,0x16
    80004506:	12a7a783          	lw	a5,298(a5) # 8001a62c <log+0x2c>
    8000450a:	0af05d63          	blez	a5,800045c4 <install_trans+0xc2>
{
    8000450e:	7139                	addi	sp,sp,-64
    80004510:	fc06                	sd	ra,56(sp)
    80004512:	f822                	sd	s0,48(sp)
    80004514:	f426                	sd	s1,40(sp)
    80004516:	f04a                	sd	s2,32(sp)
    80004518:	ec4e                	sd	s3,24(sp)
    8000451a:	e852                	sd	s4,16(sp)
    8000451c:	e456                	sd	s5,8(sp)
    8000451e:	e05a                	sd	s6,0(sp)
    80004520:	0080                	addi	s0,sp,64
    80004522:	8b2a                	mv	s6,a0
    80004524:	00016a97          	auipc	s5,0x16
    80004528:	10ca8a93          	addi	s5,s5,268 # 8001a630 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000452c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000452e:	00016997          	auipc	s3,0x16
    80004532:	0d298993          	addi	s3,s3,210 # 8001a600 <log>
    80004536:	a035                	j	80004562 <install_trans+0x60>
      bunpin(dbuf);
    80004538:	8526                	mv	a0,s1
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	166080e7          	jalr	358(ra) # 800036a0 <bunpin>
    brelse(lbuf);
    80004542:	854a                	mv	a0,s2
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	082080e7          	jalr	130(ra) # 800035c6 <brelse>
    brelse(dbuf);
    8000454c:	8526                	mv	a0,s1
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	078080e7          	jalr	120(ra) # 800035c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004556:	2a05                	addiw	s4,s4,1
    80004558:	0a91                	addi	s5,s5,4
    8000455a:	02c9a783          	lw	a5,44(s3)
    8000455e:	04fa5963          	bge	s4,a5,800045b0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004562:	0189a583          	lw	a1,24(s3)
    80004566:	014585bb          	addw	a1,a1,s4
    8000456a:	2585                	addiw	a1,a1,1
    8000456c:	0289a503          	lw	a0,40(s3)
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	f26080e7          	jalr	-218(ra) # 80003496 <bread>
    80004578:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000457a:	000aa583          	lw	a1,0(s5)
    8000457e:	0289a503          	lw	a0,40(s3)
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	f14080e7          	jalr	-236(ra) # 80003496 <bread>
    8000458a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000458c:	40000613          	li	a2,1024
    80004590:	05890593          	addi	a1,s2,88
    80004594:	05850513          	addi	a0,a0,88
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	7a8080e7          	jalr	1960(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045a0:	8526                	mv	a0,s1
    800045a2:	fffff097          	auipc	ra,0xfffff
    800045a6:	fe6080e7          	jalr	-26(ra) # 80003588 <bwrite>
    if(recovering == 0)
    800045aa:	f80b1ce3          	bnez	s6,80004542 <install_trans+0x40>
    800045ae:	b769                	j	80004538 <install_trans+0x36>
}
    800045b0:	70e2                	ld	ra,56(sp)
    800045b2:	7442                	ld	s0,48(sp)
    800045b4:	74a2                	ld	s1,40(sp)
    800045b6:	7902                	ld	s2,32(sp)
    800045b8:	69e2                	ld	s3,24(sp)
    800045ba:	6a42                	ld	s4,16(sp)
    800045bc:	6aa2                	ld	s5,8(sp)
    800045be:	6b02                	ld	s6,0(sp)
    800045c0:	6121                	addi	sp,sp,64
    800045c2:	8082                	ret
    800045c4:	8082                	ret

00000000800045c6 <initlog>:
{
    800045c6:	7179                	addi	sp,sp,-48
    800045c8:	f406                	sd	ra,40(sp)
    800045ca:	f022                	sd	s0,32(sp)
    800045cc:	ec26                	sd	s1,24(sp)
    800045ce:	e84a                	sd	s2,16(sp)
    800045d0:	e44e                	sd	s3,8(sp)
    800045d2:	1800                	addi	s0,sp,48
    800045d4:	892a                	mv	s2,a0
    800045d6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045d8:	00016497          	auipc	s1,0x16
    800045dc:	02848493          	addi	s1,s1,40 # 8001a600 <log>
    800045e0:	00004597          	auipc	a1,0x4
    800045e4:	12858593          	addi	a1,a1,296 # 80008708 <syscalls+0x1f0>
    800045e8:	8526                	mv	a0,s1
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	56a080e7          	jalr	1386(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800045f2:	0149a583          	lw	a1,20(s3)
    800045f6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045f8:	0109a783          	lw	a5,16(s3)
    800045fc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045fe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004602:	854a                	mv	a0,s2
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	e92080e7          	jalr	-366(ra) # 80003496 <bread>
  log.lh.n = lh->n;
    8000460c:	4d3c                	lw	a5,88(a0)
    8000460e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004610:	02f05563          	blez	a5,8000463a <initlog+0x74>
    80004614:	05c50713          	addi	a4,a0,92
    80004618:	00016697          	auipc	a3,0x16
    8000461c:	01868693          	addi	a3,a3,24 # 8001a630 <log+0x30>
    80004620:	37fd                	addiw	a5,a5,-1
    80004622:	1782                	slli	a5,a5,0x20
    80004624:	9381                	srli	a5,a5,0x20
    80004626:	078a                	slli	a5,a5,0x2
    80004628:	06050613          	addi	a2,a0,96
    8000462c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000462e:	4310                	lw	a2,0(a4)
    80004630:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004632:	0711                	addi	a4,a4,4
    80004634:	0691                	addi	a3,a3,4
    80004636:	fef71ce3          	bne	a4,a5,8000462e <initlog+0x68>
  brelse(buf);
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	f8c080e7          	jalr	-116(ra) # 800035c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004642:	4505                	li	a0,1
    80004644:	00000097          	auipc	ra,0x0
    80004648:	ebe080e7          	jalr	-322(ra) # 80004502 <install_trans>
  log.lh.n = 0;
    8000464c:	00016797          	auipc	a5,0x16
    80004650:	fe07a023          	sw	zero,-32(a5) # 8001a62c <log+0x2c>
  write_head(); // clear the log
    80004654:	00000097          	auipc	ra,0x0
    80004658:	e34080e7          	jalr	-460(ra) # 80004488 <write_head>
}
    8000465c:	70a2                	ld	ra,40(sp)
    8000465e:	7402                	ld	s0,32(sp)
    80004660:	64e2                	ld	s1,24(sp)
    80004662:	6942                	ld	s2,16(sp)
    80004664:	69a2                	ld	s3,8(sp)
    80004666:	6145                	addi	sp,sp,48
    80004668:	8082                	ret

000000008000466a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000466a:	1101                	addi	sp,sp,-32
    8000466c:	ec06                	sd	ra,24(sp)
    8000466e:	e822                	sd	s0,16(sp)
    80004670:	e426                	sd	s1,8(sp)
    80004672:	e04a                	sd	s2,0(sp)
    80004674:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004676:	00016517          	auipc	a0,0x16
    8000467a:	f8a50513          	addi	a0,a0,-118 # 8001a600 <log>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	566080e7          	jalr	1382(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004686:	00016497          	auipc	s1,0x16
    8000468a:	f7a48493          	addi	s1,s1,-134 # 8001a600 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000468e:	4979                	li	s2,30
    80004690:	a039                	j	8000469e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004692:	85a6                	mv	a1,s1
    80004694:	8526                	mv	a0,s1
    80004696:	ffffe097          	auipc	ra,0xffffe
    8000469a:	d66080e7          	jalr	-666(ra) # 800023fc <sleep>
    if(log.committing){
    8000469e:	50dc                	lw	a5,36(s1)
    800046a0:	fbed                	bnez	a5,80004692 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046a2:	509c                	lw	a5,32(s1)
    800046a4:	0017871b          	addiw	a4,a5,1
    800046a8:	0007069b          	sext.w	a3,a4
    800046ac:	0027179b          	slliw	a5,a4,0x2
    800046b0:	9fb9                	addw	a5,a5,a4
    800046b2:	0017979b          	slliw	a5,a5,0x1
    800046b6:	54d8                	lw	a4,44(s1)
    800046b8:	9fb9                	addw	a5,a5,a4
    800046ba:	00f95963          	bge	s2,a5,800046cc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046be:	85a6                	mv	a1,s1
    800046c0:	8526                	mv	a0,s1
    800046c2:	ffffe097          	auipc	ra,0xffffe
    800046c6:	d3a080e7          	jalr	-710(ra) # 800023fc <sleep>
    800046ca:	bfd1                	j	8000469e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046cc:	00016517          	auipc	a0,0x16
    800046d0:	f3450513          	addi	a0,a0,-204 # 8001a600 <log>
    800046d4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	5c2080e7          	jalr	1474(ra) # 80000c98 <release>
      break;
    }
  }
}
    800046de:	60e2                	ld	ra,24(sp)
    800046e0:	6442                	ld	s0,16(sp)
    800046e2:	64a2                	ld	s1,8(sp)
    800046e4:	6902                	ld	s2,0(sp)
    800046e6:	6105                	addi	sp,sp,32
    800046e8:	8082                	ret

00000000800046ea <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046ea:	7139                	addi	sp,sp,-64
    800046ec:	fc06                	sd	ra,56(sp)
    800046ee:	f822                	sd	s0,48(sp)
    800046f0:	f426                	sd	s1,40(sp)
    800046f2:	f04a                	sd	s2,32(sp)
    800046f4:	ec4e                	sd	s3,24(sp)
    800046f6:	e852                	sd	s4,16(sp)
    800046f8:	e456                	sd	s5,8(sp)
    800046fa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046fc:	00016497          	auipc	s1,0x16
    80004700:	f0448493          	addi	s1,s1,-252 # 8001a600 <log>
    80004704:	8526                	mv	a0,s1
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	4de080e7          	jalr	1246(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000470e:	509c                	lw	a5,32(s1)
    80004710:	37fd                	addiw	a5,a5,-1
    80004712:	0007891b          	sext.w	s2,a5
    80004716:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004718:	50dc                	lw	a5,36(s1)
    8000471a:	efb9                	bnez	a5,80004778 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000471c:	06091663          	bnez	s2,80004788 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004720:	00016497          	auipc	s1,0x16
    80004724:	ee048493          	addi	s1,s1,-288 # 8001a600 <log>
    80004728:	4785                	li	a5,1
    8000472a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	56a080e7          	jalr	1386(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004736:	54dc                	lw	a5,44(s1)
    80004738:	06f04763          	bgtz	a5,800047a6 <end_op+0xbc>
    acquire(&log.lock);
    8000473c:	00016497          	auipc	s1,0x16
    80004740:	ec448493          	addi	s1,s1,-316 # 8001a600 <log>
    80004744:	8526                	mv	a0,s1
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	49e080e7          	jalr	1182(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000474e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004752:	8526                	mv	a0,s1
    80004754:	ffffe097          	auipc	ra,0xffffe
    80004758:	e78080e7          	jalr	-392(ra) # 800025cc <wakeup>
    release(&log.lock);
    8000475c:	8526                	mv	a0,s1
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	53a080e7          	jalr	1338(ra) # 80000c98 <release>
}
    80004766:	70e2                	ld	ra,56(sp)
    80004768:	7442                	ld	s0,48(sp)
    8000476a:	74a2                	ld	s1,40(sp)
    8000476c:	7902                	ld	s2,32(sp)
    8000476e:	69e2                	ld	s3,24(sp)
    80004770:	6a42                	ld	s4,16(sp)
    80004772:	6aa2                	ld	s5,8(sp)
    80004774:	6121                	addi	sp,sp,64
    80004776:	8082                	ret
    panic("log.committing");
    80004778:	00004517          	auipc	a0,0x4
    8000477c:	f9850513          	addi	a0,a0,-104 # 80008710 <syscalls+0x1f8>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	dbe080e7          	jalr	-578(ra) # 8000053e <panic>
    wakeup(&log);
    80004788:	00016497          	auipc	s1,0x16
    8000478c:	e7848493          	addi	s1,s1,-392 # 8001a600 <log>
    80004790:	8526                	mv	a0,s1
    80004792:	ffffe097          	auipc	ra,0xffffe
    80004796:	e3a080e7          	jalr	-454(ra) # 800025cc <wakeup>
  release(&log.lock);
    8000479a:	8526                	mv	a0,s1
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	4fc080e7          	jalr	1276(ra) # 80000c98 <release>
  if(do_commit){
    800047a4:	b7c9                	j	80004766 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a6:	00016a97          	auipc	s5,0x16
    800047aa:	e8aa8a93          	addi	s5,s5,-374 # 8001a630 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047ae:	00016a17          	auipc	s4,0x16
    800047b2:	e52a0a13          	addi	s4,s4,-430 # 8001a600 <log>
    800047b6:	018a2583          	lw	a1,24(s4)
    800047ba:	012585bb          	addw	a1,a1,s2
    800047be:	2585                	addiw	a1,a1,1
    800047c0:	028a2503          	lw	a0,40(s4)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	cd2080e7          	jalr	-814(ra) # 80003496 <bread>
    800047cc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047ce:	000aa583          	lw	a1,0(s5)
    800047d2:	028a2503          	lw	a0,40(s4)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	cc0080e7          	jalr	-832(ra) # 80003496 <bread>
    800047de:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047e0:	40000613          	li	a2,1024
    800047e4:	05850593          	addi	a1,a0,88
    800047e8:	05848513          	addi	a0,s1,88
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	554080e7          	jalr	1364(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800047f4:	8526                	mv	a0,s1
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	d92080e7          	jalr	-622(ra) # 80003588 <bwrite>
    brelse(from);
    800047fe:	854e                	mv	a0,s3
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	dc6080e7          	jalr	-570(ra) # 800035c6 <brelse>
    brelse(to);
    80004808:	8526                	mv	a0,s1
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	dbc080e7          	jalr	-580(ra) # 800035c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004812:	2905                	addiw	s2,s2,1
    80004814:	0a91                	addi	s5,s5,4
    80004816:	02ca2783          	lw	a5,44(s4)
    8000481a:	f8f94ee3          	blt	s2,a5,800047b6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	c6a080e7          	jalr	-918(ra) # 80004488 <write_head>
    install_trans(0); // Now install writes to home locations
    80004826:	4501                	li	a0,0
    80004828:	00000097          	auipc	ra,0x0
    8000482c:	cda080e7          	jalr	-806(ra) # 80004502 <install_trans>
    log.lh.n = 0;
    80004830:	00016797          	auipc	a5,0x16
    80004834:	de07ae23          	sw	zero,-516(a5) # 8001a62c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	c50080e7          	jalr	-944(ra) # 80004488 <write_head>
    80004840:	bdf5                	j	8000473c <end_op+0x52>

0000000080004842 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004842:	1101                	addi	sp,sp,-32
    80004844:	ec06                	sd	ra,24(sp)
    80004846:	e822                	sd	s0,16(sp)
    80004848:	e426                	sd	s1,8(sp)
    8000484a:	e04a                	sd	s2,0(sp)
    8000484c:	1000                	addi	s0,sp,32
    8000484e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004850:	00016917          	auipc	s2,0x16
    80004854:	db090913          	addi	s2,s2,-592 # 8001a600 <log>
    80004858:	854a                	mv	a0,s2
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	38a080e7          	jalr	906(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004862:	02c92603          	lw	a2,44(s2)
    80004866:	47f5                	li	a5,29
    80004868:	06c7c563          	blt	a5,a2,800048d2 <log_write+0x90>
    8000486c:	00016797          	auipc	a5,0x16
    80004870:	db07a783          	lw	a5,-592(a5) # 8001a61c <log+0x1c>
    80004874:	37fd                	addiw	a5,a5,-1
    80004876:	04f65e63          	bge	a2,a5,800048d2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000487a:	00016797          	auipc	a5,0x16
    8000487e:	da67a783          	lw	a5,-602(a5) # 8001a620 <log+0x20>
    80004882:	06f05063          	blez	a5,800048e2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004886:	4781                	li	a5,0
    80004888:	06c05563          	blez	a2,800048f2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000488c:	44cc                	lw	a1,12(s1)
    8000488e:	00016717          	auipc	a4,0x16
    80004892:	da270713          	addi	a4,a4,-606 # 8001a630 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004896:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004898:	4314                	lw	a3,0(a4)
    8000489a:	04b68c63          	beq	a3,a1,800048f2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000489e:	2785                	addiw	a5,a5,1
    800048a0:	0711                	addi	a4,a4,4
    800048a2:	fef61be3          	bne	a2,a5,80004898 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048a6:	0621                	addi	a2,a2,8
    800048a8:	060a                	slli	a2,a2,0x2
    800048aa:	00016797          	auipc	a5,0x16
    800048ae:	d5678793          	addi	a5,a5,-682 # 8001a600 <log>
    800048b2:	963e                	add	a2,a2,a5
    800048b4:	44dc                	lw	a5,12(s1)
    800048b6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048b8:	8526                	mv	a0,s1
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	daa080e7          	jalr	-598(ra) # 80003664 <bpin>
    log.lh.n++;
    800048c2:	00016717          	auipc	a4,0x16
    800048c6:	d3e70713          	addi	a4,a4,-706 # 8001a600 <log>
    800048ca:	575c                	lw	a5,44(a4)
    800048cc:	2785                	addiw	a5,a5,1
    800048ce:	d75c                	sw	a5,44(a4)
    800048d0:	a835                	j	8000490c <log_write+0xca>
    panic("too big a transaction");
    800048d2:	00004517          	auipc	a0,0x4
    800048d6:	e4e50513          	addi	a0,a0,-434 # 80008720 <syscalls+0x208>
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	c64080e7          	jalr	-924(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048e2:	00004517          	auipc	a0,0x4
    800048e6:	e5650513          	addi	a0,a0,-426 # 80008738 <syscalls+0x220>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800048f2:	00878713          	addi	a4,a5,8
    800048f6:	00271693          	slli	a3,a4,0x2
    800048fa:	00016717          	auipc	a4,0x16
    800048fe:	d0670713          	addi	a4,a4,-762 # 8001a600 <log>
    80004902:	9736                	add	a4,a4,a3
    80004904:	44d4                	lw	a3,12(s1)
    80004906:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004908:	faf608e3          	beq	a2,a5,800048b8 <log_write+0x76>
  }
  release(&log.lock);
    8000490c:	00016517          	auipc	a0,0x16
    80004910:	cf450513          	addi	a0,a0,-780 # 8001a600 <log>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	384080e7          	jalr	900(ra) # 80000c98 <release>
}
    8000491c:	60e2                	ld	ra,24(sp)
    8000491e:	6442                	ld	s0,16(sp)
    80004920:	64a2                	ld	s1,8(sp)
    80004922:	6902                	ld	s2,0(sp)
    80004924:	6105                	addi	sp,sp,32
    80004926:	8082                	ret

0000000080004928 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004928:	1101                	addi	sp,sp,-32
    8000492a:	ec06                	sd	ra,24(sp)
    8000492c:	e822                	sd	s0,16(sp)
    8000492e:	e426                	sd	s1,8(sp)
    80004930:	e04a                	sd	s2,0(sp)
    80004932:	1000                	addi	s0,sp,32
    80004934:	84aa                	mv	s1,a0
    80004936:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004938:	00004597          	auipc	a1,0x4
    8000493c:	e2058593          	addi	a1,a1,-480 # 80008758 <syscalls+0x240>
    80004940:	0521                	addi	a0,a0,8
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	212080e7          	jalr	530(ra) # 80000b54 <initlock>
  lk->name = name;
    8000494a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000494e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004952:	0204a423          	sw	zero,40(s1)
}
    80004956:	60e2                	ld	ra,24(sp)
    80004958:	6442                	ld	s0,16(sp)
    8000495a:	64a2                	ld	s1,8(sp)
    8000495c:	6902                	ld	s2,0(sp)
    8000495e:	6105                	addi	sp,sp,32
    80004960:	8082                	ret

0000000080004962 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004962:	1101                	addi	sp,sp,-32
    80004964:	ec06                	sd	ra,24(sp)
    80004966:	e822                	sd	s0,16(sp)
    80004968:	e426                	sd	s1,8(sp)
    8000496a:	e04a                	sd	s2,0(sp)
    8000496c:	1000                	addi	s0,sp,32
    8000496e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004970:	00850913          	addi	s2,a0,8
    80004974:	854a                	mv	a0,s2
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	26e080e7          	jalr	622(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000497e:	409c                	lw	a5,0(s1)
    80004980:	cb89                	beqz	a5,80004992 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004982:	85ca                	mv	a1,s2
    80004984:	8526                	mv	a0,s1
    80004986:	ffffe097          	auipc	ra,0xffffe
    8000498a:	a76080e7          	jalr	-1418(ra) # 800023fc <sleep>
  while (lk->locked) {
    8000498e:	409c                	lw	a5,0(s1)
    80004990:	fbed                	bnez	a5,80004982 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004992:	4785                	li	a5,1
    80004994:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004996:	ffffd097          	auipc	ra,0xffffd
    8000499a:	032080e7          	jalr	50(ra) # 800019c8 <myproc>
    8000499e:	591c                	lw	a5,48(a0)
    800049a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049a2:	854a                	mv	a0,s2
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	2f4080e7          	jalr	756(ra) # 80000c98 <release>
}
    800049ac:	60e2                	ld	ra,24(sp)
    800049ae:	6442                	ld	s0,16(sp)
    800049b0:	64a2                	ld	s1,8(sp)
    800049b2:	6902                	ld	s2,0(sp)
    800049b4:	6105                	addi	sp,sp,32
    800049b6:	8082                	ret

00000000800049b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049b8:	1101                	addi	sp,sp,-32
    800049ba:	ec06                	sd	ra,24(sp)
    800049bc:	e822                	sd	s0,16(sp)
    800049be:	e426                	sd	s1,8(sp)
    800049c0:	e04a                	sd	s2,0(sp)
    800049c2:	1000                	addi	s0,sp,32
    800049c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049c6:	00850913          	addi	s2,a0,8
    800049ca:	854a                	mv	a0,s2
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	218080e7          	jalr	536(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffe097          	auipc	ra,0xffffe
    800049e2:	bee080e7          	jalr	-1042(ra) # 800025cc <wakeup>
  release(&lk->lk);
    800049e6:	854a                	mv	a0,s2
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	2b0080e7          	jalr	688(ra) # 80000c98 <release>
}
    800049f0:	60e2                	ld	ra,24(sp)
    800049f2:	6442                	ld	s0,16(sp)
    800049f4:	64a2                	ld	s1,8(sp)
    800049f6:	6902                	ld	s2,0(sp)
    800049f8:	6105                	addi	sp,sp,32
    800049fa:	8082                	ret

00000000800049fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049fc:	7179                	addi	sp,sp,-48
    800049fe:	f406                	sd	ra,40(sp)
    80004a00:	f022                	sd	s0,32(sp)
    80004a02:	ec26                	sd	s1,24(sp)
    80004a04:	e84a                	sd	s2,16(sp)
    80004a06:	e44e                	sd	s3,8(sp)
    80004a08:	1800                	addi	s0,sp,48
    80004a0a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a0c:	00850913          	addi	s2,a0,8
    80004a10:	854a                	mv	a0,s2
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	1d2080e7          	jalr	466(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a1a:	409c                	lw	a5,0(s1)
    80004a1c:	ef99                	bnez	a5,80004a3a <holdingsleep+0x3e>
    80004a1e:	4481                	li	s1,0
  release(&lk->lk);
    80004a20:	854a                	mv	a0,s2
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	276080e7          	jalr	630(ra) # 80000c98 <release>
  return r;
}
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	70a2                	ld	ra,40(sp)
    80004a2e:	7402                	ld	s0,32(sp)
    80004a30:	64e2                	ld	s1,24(sp)
    80004a32:	6942                	ld	s2,16(sp)
    80004a34:	69a2                	ld	s3,8(sp)
    80004a36:	6145                	addi	sp,sp,48
    80004a38:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a3a:	0284a983          	lw	s3,40(s1)
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	f8a080e7          	jalr	-118(ra) # 800019c8 <myproc>
    80004a46:	5904                	lw	s1,48(a0)
    80004a48:	413484b3          	sub	s1,s1,s3
    80004a4c:	0014b493          	seqz	s1,s1
    80004a50:	bfc1                	j	80004a20 <holdingsleep+0x24>

0000000080004a52 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a52:	1141                	addi	sp,sp,-16
    80004a54:	e406                	sd	ra,8(sp)
    80004a56:	e022                	sd	s0,0(sp)
    80004a58:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a5a:	00004597          	auipc	a1,0x4
    80004a5e:	d0e58593          	addi	a1,a1,-754 # 80008768 <syscalls+0x250>
    80004a62:	00016517          	auipc	a0,0x16
    80004a66:	ce650513          	addi	a0,a0,-794 # 8001a748 <ftable>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	0ea080e7          	jalr	234(ra) # 80000b54 <initlock>
}
    80004a72:	60a2                	ld	ra,8(sp)
    80004a74:	6402                	ld	s0,0(sp)
    80004a76:	0141                	addi	sp,sp,16
    80004a78:	8082                	ret

0000000080004a7a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a7a:	1101                	addi	sp,sp,-32
    80004a7c:	ec06                	sd	ra,24(sp)
    80004a7e:	e822                	sd	s0,16(sp)
    80004a80:	e426                	sd	s1,8(sp)
    80004a82:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a84:	00016517          	auipc	a0,0x16
    80004a88:	cc450513          	addi	a0,a0,-828 # 8001a748 <ftable>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	158080e7          	jalr	344(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a94:	00016497          	auipc	s1,0x16
    80004a98:	ccc48493          	addi	s1,s1,-820 # 8001a760 <ftable+0x18>
    80004a9c:	00017717          	auipc	a4,0x17
    80004aa0:	c6470713          	addi	a4,a4,-924 # 8001b700 <ftable+0xfb8>
    if(f->ref == 0){
    80004aa4:	40dc                	lw	a5,4(s1)
    80004aa6:	cf99                	beqz	a5,80004ac4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aa8:	02848493          	addi	s1,s1,40
    80004aac:	fee49ce3          	bne	s1,a4,80004aa4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ab0:	00016517          	auipc	a0,0x16
    80004ab4:	c9850513          	addi	a0,a0,-872 # 8001a748 <ftable>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1e0080e7          	jalr	480(ra) # 80000c98 <release>
  return 0;
    80004ac0:	4481                	li	s1,0
    80004ac2:	a819                	j	80004ad8 <filealloc+0x5e>
      f->ref = 1;
    80004ac4:	4785                	li	a5,1
    80004ac6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ac8:	00016517          	auipc	a0,0x16
    80004acc:	c8050513          	addi	a0,a0,-896 # 8001a748 <ftable>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	1c8080e7          	jalr	456(ra) # 80000c98 <release>
}
    80004ad8:	8526                	mv	a0,s1
    80004ada:	60e2                	ld	ra,24(sp)
    80004adc:	6442                	ld	s0,16(sp)
    80004ade:	64a2                	ld	s1,8(sp)
    80004ae0:	6105                	addi	sp,sp,32
    80004ae2:	8082                	ret

0000000080004ae4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ae4:	1101                	addi	sp,sp,-32
    80004ae6:	ec06                	sd	ra,24(sp)
    80004ae8:	e822                	sd	s0,16(sp)
    80004aea:	e426                	sd	s1,8(sp)
    80004aec:	1000                	addi	s0,sp,32
    80004aee:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004af0:	00016517          	auipc	a0,0x16
    80004af4:	c5850513          	addi	a0,a0,-936 # 8001a748 <ftable>
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	0ec080e7          	jalr	236(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b00:	40dc                	lw	a5,4(s1)
    80004b02:	02f05263          	blez	a5,80004b26 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b06:	2785                	addiw	a5,a5,1
    80004b08:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b0a:	00016517          	auipc	a0,0x16
    80004b0e:	c3e50513          	addi	a0,a0,-962 # 8001a748 <ftable>
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	186080e7          	jalr	390(ra) # 80000c98 <release>
  return f;
}
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6105                	addi	sp,sp,32
    80004b24:	8082                	ret
    panic("filedup");
    80004b26:	00004517          	auipc	a0,0x4
    80004b2a:	c4a50513          	addi	a0,a0,-950 # 80008770 <syscalls+0x258>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	a10080e7          	jalr	-1520(ra) # 8000053e <panic>

0000000080004b36 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b36:	7139                	addi	sp,sp,-64
    80004b38:	fc06                	sd	ra,56(sp)
    80004b3a:	f822                	sd	s0,48(sp)
    80004b3c:	f426                	sd	s1,40(sp)
    80004b3e:	f04a                	sd	s2,32(sp)
    80004b40:	ec4e                	sd	s3,24(sp)
    80004b42:	e852                	sd	s4,16(sp)
    80004b44:	e456                	sd	s5,8(sp)
    80004b46:	0080                	addi	s0,sp,64
    80004b48:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b4a:	00016517          	auipc	a0,0x16
    80004b4e:	bfe50513          	addi	a0,a0,-1026 # 8001a748 <ftable>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	092080e7          	jalr	146(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b5a:	40dc                	lw	a5,4(s1)
    80004b5c:	06f05163          	blez	a5,80004bbe <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b60:	37fd                	addiw	a5,a5,-1
    80004b62:	0007871b          	sext.w	a4,a5
    80004b66:	c0dc                	sw	a5,4(s1)
    80004b68:	06e04363          	bgtz	a4,80004bce <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b6c:	0004a903          	lw	s2,0(s1)
    80004b70:	0094ca83          	lbu	s5,9(s1)
    80004b74:	0104ba03          	ld	s4,16(s1)
    80004b78:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b7c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b80:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b84:	00016517          	auipc	a0,0x16
    80004b88:	bc450513          	addi	a0,a0,-1084 # 8001a748 <ftable>
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	10c080e7          	jalr	268(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b94:	4785                	li	a5,1
    80004b96:	04f90d63          	beq	s2,a5,80004bf0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b9a:	3979                	addiw	s2,s2,-2
    80004b9c:	4785                	li	a5,1
    80004b9e:	0527e063          	bltu	a5,s2,80004bde <fileclose+0xa8>
    begin_op();
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	ac8080e7          	jalr	-1336(ra) # 8000466a <begin_op>
    iput(ff.ip);
    80004baa:	854e                	mv	a0,s3
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	2a6080e7          	jalr	678(ra) # 80003e52 <iput>
    end_op();
    80004bb4:	00000097          	auipc	ra,0x0
    80004bb8:	b36080e7          	jalr	-1226(ra) # 800046ea <end_op>
    80004bbc:	a00d                	j	80004bde <fileclose+0xa8>
    panic("fileclose");
    80004bbe:	00004517          	auipc	a0,0x4
    80004bc2:	bba50513          	addi	a0,a0,-1094 # 80008778 <syscalls+0x260>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	978080e7          	jalr	-1672(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004bce:	00016517          	auipc	a0,0x16
    80004bd2:	b7a50513          	addi	a0,a0,-1158 # 8001a748 <ftable>
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	0c2080e7          	jalr	194(ra) # 80000c98 <release>
  }
}
    80004bde:	70e2                	ld	ra,56(sp)
    80004be0:	7442                	ld	s0,48(sp)
    80004be2:	74a2                	ld	s1,40(sp)
    80004be4:	7902                	ld	s2,32(sp)
    80004be6:	69e2                	ld	s3,24(sp)
    80004be8:	6a42                	ld	s4,16(sp)
    80004bea:	6aa2                	ld	s5,8(sp)
    80004bec:	6121                	addi	sp,sp,64
    80004bee:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bf0:	85d6                	mv	a1,s5
    80004bf2:	8552                	mv	a0,s4
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	34c080e7          	jalr	844(ra) # 80004f40 <pipeclose>
    80004bfc:	b7cd                	j	80004bde <fileclose+0xa8>

0000000080004bfe <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bfe:	715d                	addi	sp,sp,-80
    80004c00:	e486                	sd	ra,72(sp)
    80004c02:	e0a2                	sd	s0,64(sp)
    80004c04:	fc26                	sd	s1,56(sp)
    80004c06:	f84a                	sd	s2,48(sp)
    80004c08:	f44e                	sd	s3,40(sp)
    80004c0a:	0880                	addi	s0,sp,80
    80004c0c:	84aa                	mv	s1,a0
    80004c0e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	db8080e7          	jalr	-584(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c18:	409c                	lw	a5,0(s1)
    80004c1a:	37f9                	addiw	a5,a5,-2
    80004c1c:	4705                	li	a4,1
    80004c1e:	04f76763          	bltu	a4,a5,80004c6c <filestat+0x6e>
    80004c22:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c24:	6c88                	ld	a0,24(s1)
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	072080e7          	jalr	114(ra) # 80003c98 <ilock>
    stati(f->ip, &st);
    80004c2e:	fb840593          	addi	a1,s0,-72
    80004c32:	6c88                	ld	a0,24(s1)
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	2ee080e7          	jalr	750(ra) # 80003f22 <stati>
    iunlock(f->ip);
    80004c3c:	6c88                	ld	a0,24(s1)
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	11c080e7          	jalr	284(ra) # 80003d5a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c46:	46e1                	li	a3,24
    80004c48:	fb840613          	addi	a2,s0,-72
    80004c4c:	85ce                	mv	a1,s3
    80004c4e:	05093503          	ld	a0,80(s2)
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	a28080e7          	jalr	-1496(ra) # 8000167a <copyout>
    80004c5a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c5e:	60a6                	ld	ra,72(sp)
    80004c60:	6406                	ld	s0,64(sp)
    80004c62:	74e2                	ld	s1,56(sp)
    80004c64:	7942                	ld	s2,48(sp)
    80004c66:	79a2                	ld	s3,40(sp)
    80004c68:	6161                	addi	sp,sp,80
    80004c6a:	8082                	ret
  return -1;
    80004c6c:	557d                	li	a0,-1
    80004c6e:	bfc5                	j	80004c5e <filestat+0x60>

0000000080004c70 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c70:	7179                	addi	sp,sp,-48
    80004c72:	f406                	sd	ra,40(sp)
    80004c74:	f022                	sd	s0,32(sp)
    80004c76:	ec26                	sd	s1,24(sp)
    80004c78:	e84a                	sd	s2,16(sp)
    80004c7a:	e44e                	sd	s3,8(sp)
    80004c7c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c7e:	00854783          	lbu	a5,8(a0)
    80004c82:	c3d5                	beqz	a5,80004d26 <fileread+0xb6>
    80004c84:	84aa                	mv	s1,a0
    80004c86:	89ae                	mv	s3,a1
    80004c88:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c8a:	411c                	lw	a5,0(a0)
    80004c8c:	4705                	li	a4,1
    80004c8e:	04e78963          	beq	a5,a4,80004ce0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c92:	470d                	li	a4,3
    80004c94:	04e78d63          	beq	a5,a4,80004cee <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c98:	4709                	li	a4,2
    80004c9a:	06e79e63          	bne	a5,a4,80004d16 <fileread+0xa6>
    ilock(f->ip);
    80004c9e:	6d08                	ld	a0,24(a0)
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	ff8080e7          	jalr	-8(ra) # 80003c98 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ca8:	874a                	mv	a4,s2
    80004caa:	5094                	lw	a3,32(s1)
    80004cac:	864e                	mv	a2,s3
    80004cae:	4585                	li	a1,1
    80004cb0:	6c88                	ld	a0,24(s1)
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	29a080e7          	jalr	666(ra) # 80003f4c <readi>
    80004cba:	892a                	mv	s2,a0
    80004cbc:	00a05563          	blez	a0,80004cc6 <fileread+0x56>
      f->off += r;
    80004cc0:	509c                	lw	a5,32(s1)
    80004cc2:	9fa9                	addw	a5,a5,a0
    80004cc4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cc6:	6c88                	ld	a0,24(s1)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	092080e7          	jalr	146(ra) # 80003d5a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cd0:	854a                	mv	a0,s2
    80004cd2:	70a2                	ld	ra,40(sp)
    80004cd4:	7402                	ld	s0,32(sp)
    80004cd6:	64e2                	ld	s1,24(sp)
    80004cd8:	6942                	ld	s2,16(sp)
    80004cda:	69a2                	ld	s3,8(sp)
    80004cdc:	6145                	addi	sp,sp,48
    80004cde:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ce0:	6908                	ld	a0,16(a0)
    80004ce2:	00000097          	auipc	ra,0x0
    80004ce6:	3c8080e7          	jalr	968(ra) # 800050aa <piperead>
    80004cea:	892a                	mv	s2,a0
    80004cec:	b7d5                	j	80004cd0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cee:	02451783          	lh	a5,36(a0)
    80004cf2:	03079693          	slli	a3,a5,0x30
    80004cf6:	92c1                	srli	a3,a3,0x30
    80004cf8:	4725                	li	a4,9
    80004cfa:	02d76863          	bltu	a4,a3,80004d2a <fileread+0xba>
    80004cfe:	0792                	slli	a5,a5,0x4
    80004d00:	00016717          	auipc	a4,0x16
    80004d04:	9a870713          	addi	a4,a4,-1624 # 8001a6a8 <devsw>
    80004d08:	97ba                	add	a5,a5,a4
    80004d0a:	639c                	ld	a5,0(a5)
    80004d0c:	c38d                	beqz	a5,80004d2e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d0e:	4505                	li	a0,1
    80004d10:	9782                	jalr	a5
    80004d12:	892a                	mv	s2,a0
    80004d14:	bf75                	j	80004cd0 <fileread+0x60>
    panic("fileread");
    80004d16:	00004517          	auipc	a0,0x4
    80004d1a:	a7250513          	addi	a0,a0,-1422 # 80008788 <syscalls+0x270>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	820080e7          	jalr	-2016(ra) # 8000053e <panic>
    return -1;
    80004d26:	597d                	li	s2,-1
    80004d28:	b765                	j	80004cd0 <fileread+0x60>
      return -1;
    80004d2a:	597d                	li	s2,-1
    80004d2c:	b755                	j	80004cd0 <fileread+0x60>
    80004d2e:	597d                	li	s2,-1
    80004d30:	b745                	j	80004cd0 <fileread+0x60>

0000000080004d32 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d32:	715d                	addi	sp,sp,-80
    80004d34:	e486                	sd	ra,72(sp)
    80004d36:	e0a2                	sd	s0,64(sp)
    80004d38:	fc26                	sd	s1,56(sp)
    80004d3a:	f84a                	sd	s2,48(sp)
    80004d3c:	f44e                	sd	s3,40(sp)
    80004d3e:	f052                	sd	s4,32(sp)
    80004d40:	ec56                	sd	s5,24(sp)
    80004d42:	e85a                	sd	s6,16(sp)
    80004d44:	e45e                	sd	s7,8(sp)
    80004d46:	e062                	sd	s8,0(sp)
    80004d48:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d4a:	00954783          	lbu	a5,9(a0)
    80004d4e:	10078663          	beqz	a5,80004e5a <filewrite+0x128>
    80004d52:	892a                	mv	s2,a0
    80004d54:	8aae                	mv	s5,a1
    80004d56:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d58:	411c                	lw	a5,0(a0)
    80004d5a:	4705                	li	a4,1
    80004d5c:	02e78263          	beq	a5,a4,80004d80 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d60:	470d                	li	a4,3
    80004d62:	02e78663          	beq	a5,a4,80004d8e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d66:	4709                	li	a4,2
    80004d68:	0ee79163          	bne	a5,a4,80004e4a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d6c:	0ac05d63          	blez	a2,80004e26 <filewrite+0xf4>
    int i = 0;
    80004d70:	4981                	li	s3,0
    80004d72:	6b05                	lui	s6,0x1
    80004d74:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d78:	6b85                	lui	s7,0x1
    80004d7a:	c00b8b9b          	addiw	s7,s7,-1024
    80004d7e:	a861                	j	80004e16 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d80:	6908                	ld	a0,16(a0)
    80004d82:	00000097          	auipc	ra,0x0
    80004d86:	22e080e7          	jalr	558(ra) # 80004fb0 <pipewrite>
    80004d8a:	8a2a                	mv	s4,a0
    80004d8c:	a045                	j	80004e2c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d8e:	02451783          	lh	a5,36(a0)
    80004d92:	03079693          	slli	a3,a5,0x30
    80004d96:	92c1                	srli	a3,a3,0x30
    80004d98:	4725                	li	a4,9
    80004d9a:	0cd76263          	bltu	a4,a3,80004e5e <filewrite+0x12c>
    80004d9e:	0792                	slli	a5,a5,0x4
    80004da0:	00016717          	auipc	a4,0x16
    80004da4:	90870713          	addi	a4,a4,-1784 # 8001a6a8 <devsw>
    80004da8:	97ba                	add	a5,a5,a4
    80004daa:	679c                	ld	a5,8(a5)
    80004dac:	cbdd                	beqz	a5,80004e62 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004dae:	4505                	li	a0,1
    80004db0:	9782                	jalr	a5
    80004db2:	8a2a                	mv	s4,a0
    80004db4:	a8a5                	j	80004e2c <filewrite+0xfa>
    80004db6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dba:	00000097          	auipc	ra,0x0
    80004dbe:	8b0080e7          	jalr	-1872(ra) # 8000466a <begin_op>
      ilock(f->ip);
    80004dc2:	01893503          	ld	a0,24(s2)
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	ed2080e7          	jalr	-302(ra) # 80003c98 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dce:	8762                	mv	a4,s8
    80004dd0:	02092683          	lw	a3,32(s2)
    80004dd4:	01598633          	add	a2,s3,s5
    80004dd8:	4585                	li	a1,1
    80004dda:	01893503          	ld	a0,24(s2)
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	266080e7          	jalr	614(ra) # 80004044 <writei>
    80004de6:	84aa                	mv	s1,a0
    80004de8:	00a05763          	blez	a0,80004df6 <filewrite+0xc4>
        f->off += r;
    80004dec:	02092783          	lw	a5,32(s2)
    80004df0:	9fa9                	addw	a5,a5,a0
    80004df2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004df6:	01893503          	ld	a0,24(s2)
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	f60080e7          	jalr	-160(ra) # 80003d5a <iunlock>
      end_op();
    80004e02:	00000097          	auipc	ra,0x0
    80004e06:	8e8080e7          	jalr	-1816(ra) # 800046ea <end_op>

      if(r != n1){
    80004e0a:	009c1f63          	bne	s8,s1,80004e28 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e0e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e12:	0149db63          	bge	s3,s4,80004e28 <filewrite+0xf6>
      int n1 = n - i;
    80004e16:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e1a:	84be                	mv	s1,a5
    80004e1c:	2781                	sext.w	a5,a5
    80004e1e:	f8fb5ce3          	bge	s6,a5,80004db6 <filewrite+0x84>
    80004e22:	84de                	mv	s1,s7
    80004e24:	bf49                	j	80004db6 <filewrite+0x84>
    int i = 0;
    80004e26:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e28:	013a1f63          	bne	s4,s3,80004e46 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e2c:	8552                	mv	a0,s4
    80004e2e:	60a6                	ld	ra,72(sp)
    80004e30:	6406                	ld	s0,64(sp)
    80004e32:	74e2                	ld	s1,56(sp)
    80004e34:	7942                	ld	s2,48(sp)
    80004e36:	79a2                	ld	s3,40(sp)
    80004e38:	7a02                	ld	s4,32(sp)
    80004e3a:	6ae2                	ld	s5,24(sp)
    80004e3c:	6b42                	ld	s6,16(sp)
    80004e3e:	6ba2                	ld	s7,8(sp)
    80004e40:	6c02                	ld	s8,0(sp)
    80004e42:	6161                	addi	sp,sp,80
    80004e44:	8082                	ret
    ret = (i == n ? n : -1);
    80004e46:	5a7d                	li	s4,-1
    80004e48:	b7d5                	j	80004e2c <filewrite+0xfa>
    panic("filewrite");
    80004e4a:	00004517          	auipc	a0,0x4
    80004e4e:	94e50513          	addi	a0,a0,-1714 # 80008798 <syscalls+0x280>
    80004e52:	ffffb097          	auipc	ra,0xffffb
    80004e56:	6ec080e7          	jalr	1772(ra) # 8000053e <panic>
    return -1;
    80004e5a:	5a7d                	li	s4,-1
    80004e5c:	bfc1                	j	80004e2c <filewrite+0xfa>
      return -1;
    80004e5e:	5a7d                	li	s4,-1
    80004e60:	b7f1                	j	80004e2c <filewrite+0xfa>
    80004e62:	5a7d                	li	s4,-1
    80004e64:	b7e1                	j	80004e2c <filewrite+0xfa>

0000000080004e66 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e66:	7179                	addi	sp,sp,-48
    80004e68:	f406                	sd	ra,40(sp)
    80004e6a:	f022                	sd	s0,32(sp)
    80004e6c:	ec26                	sd	s1,24(sp)
    80004e6e:	e84a                	sd	s2,16(sp)
    80004e70:	e44e                	sd	s3,8(sp)
    80004e72:	e052                	sd	s4,0(sp)
    80004e74:	1800                	addi	s0,sp,48
    80004e76:	84aa                	mv	s1,a0
    80004e78:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e7a:	0005b023          	sd	zero,0(a1)
    80004e7e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e82:	00000097          	auipc	ra,0x0
    80004e86:	bf8080e7          	jalr	-1032(ra) # 80004a7a <filealloc>
    80004e8a:	e088                	sd	a0,0(s1)
    80004e8c:	c551                	beqz	a0,80004f18 <pipealloc+0xb2>
    80004e8e:	00000097          	auipc	ra,0x0
    80004e92:	bec080e7          	jalr	-1044(ra) # 80004a7a <filealloc>
    80004e96:	00aa3023          	sd	a0,0(s4)
    80004e9a:	c92d                	beqz	a0,80004f0c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	c58080e7          	jalr	-936(ra) # 80000af4 <kalloc>
    80004ea4:	892a                	mv	s2,a0
    80004ea6:	c125                	beqz	a0,80004f06 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ea8:	4985                	li	s3,1
    80004eaa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004eae:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004eb2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004eb6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eba:	00004597          	auipc	a1,0x4
    80004ebe:	8ee58593          	addi	a1,a1,-1810 # 800087a8 <syscalls+0x290>
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	c92080e7          	jalr	-878(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004eca:	609c                	ld	a5,0(s1)
    80004ecc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ed0:	609c                	ld	a5,0(s1)
    80004ed2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ed6:	609c                	ld	a5,0(s1)
    80004ed8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004edc:	609c                	ld	a5,0(s1)
    80004ede:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ee2:	000a3783          	ld	a5,0(s4)
    80004ee6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004eea:	000a3783          	ld	a5,0(s4)
    80004eee:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ef2:	000a3783          	ld	a5,0(s4)
    80004ef6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004efa:	000a3783          	ld	a5,0(s4)
    80004efe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f02:	4501                	li	a0,0
    80004f04:	a025                	j	80004f2c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f06:	6088                	ld	a0,0(s1)
    80004f08:	e501                	bnez	a0,80004f10 <pipealloc+0xaa>
    80004f0a:	a039                	j	80004f18 <pipealloc+0xb2>
    80004f0c:	6088                	ld	a0,0(s1)
    80004f0e:	c51d                	beqz	a0,80004f3c <pipealloc+0xd6>
    fileclose(*f0);
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	c26080e7          	jalr	-986(ra) # 80004b36 <fileclose>
  if(*f1)
    80004f18:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f1c:	557d                	li	a0,-1
  if(*f1)
    80004f1e:	c799                	beqz	a5,80004f2c <pipealloc+0xc6>
    fileclose(*f1);
    80004f20:	853e                	mv	a0,a5
    80004f22:	00000097          	auipc	ra,0x0
    80004f26:	c14080e7          	jalr	-1004(ra) # 80004b36 <fileclose>
  return -1;
    80004f2a:	557d                	li	a0,-1
}
    80004f2c:	70a2                	ld	ra,40(sp)
    80004f2e:	7402                	ld	s0,32(sp)
    80004f30:	64e2                	ld	s1,24(sp)
    80004f32:	6942                	ld	s2,16(sp)
    80004f34:	69a2                	ld	s3,8(sp)
    80004f36:	6a02                	ld	s4,0(sp)
    80004f38:	6145                	addi	sp,sp,48
    80004f3a:	8082                	ret
  return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	b7fd                	j	80004f2c <pipealloc+0xc6>

0000000080004f40 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f40:	1101                	addi	sp,sp,-32
    80004f42:	ec06                	sd	ra,24(sp)
    80004f44:	e822                	sd	s0,16(sp)
    80004f46:	e426                	sd	s1,8(sp)
    80004f48:	e04a                	sd	s2,0(sp)
    80004f4a:	1000                	addi	s0,sp,32
    80004f4c:	84aa                	mv	s1,a0
    80004f4e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	c94080e7          	jalr	-876(ra) # 80000be4 <acquire>
  if(writable){
    80004f58:	02090d63          	beqz	s2,80004f92 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f5c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f60:	21848513          	addi	a0,s1,536
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	668080e7          	jalr	1640(ra) # 800025cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f6c:	2204b783          	ld	a5,544(s1)
    80004f70:	eb95                	bnez	a5,80004fa4 <pipeclose+0x64>
    release(&pi->lock);
    80004f72:	8526                	mv	a0,s1
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	d24080e7          	jalr	-732(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f7c:	8526                	mv	a0,s1
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	a7a080e7          	jalr	-1414(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f86:	60e2                	ld	ra,24(sp)
    80004f88:	6442                	ld	s0,16(sp)
    80004f8a:	64a2                	ld	s1,8(sp)
    80004f8c:	6902                	ld	s2,0(sp)
    80004f8e:	6105                	addi	sp,sp,32
    80004f90:	8082                	ret
    pi->readopen = 0;
    80004f92:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f96:	21c48513          	addi	a0,s1,540
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	632080e7          	jalr	1586(ra) # 800025cc <wakeup>
    80004fa2:	b7e9                	j	80004f6c <pipeclose+0x2c>
    release(&pi->lock);
    80004fa4:	8526                	mv	a0,s1
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	cf2080e7          	jalr	-782(ra) # 80000c98 <release>
}
    80004fae:	bfe1                	j	80004f86 <pipeclose+0x46>

0000000080004fb0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fb0:	7159                	addi	sp,sp,-112
    80004fb2:	f486                	sd	ra,104(sp)
    80004fb4:	f0a2                	sd	s0,96(sp)
    80004fb6:	eca6                	sd	s1,88(sp)
    80004fb8:	e8ca                	sd	s2,80(sp)
    80004fba:	e4ce                	sd	s3,72(sp)
    80004fbc:	e0d2                	sd	s4,64(sp)
    80004fbe:	fc56                	sd	s5,56(sp)
    80004fc0:	f85a                	sd	s6,48(sp)
    80004fc2:	f45e                	sd	s7,40(sp)
    80004fc4:	f062                	sd	s8,32(sp)
    80004fc6:	ec66                	sd	s9,24(sp)
    80004fc8:	1880                	addi	s0,sp,112
    80004fca:	84aa                	mv	s1,a0
    80004fcc:	8aae                	mv	s5,a1
    80004fce:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fd0:	ffffd097          	auipc	ra,0xffffd
    80004fd4:	9f8080e7          	jalr	-1544(ra) # 800019c8 <myproc>
    80004fd8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	c08080e7          	jalr	-1016(ra) # 80000be4 <acquire>
  while(i < n){
    80004fe4:	0d405163          	blez	s4,800050a6 <pipewrite+0xf6>
    80004fe8:	8ba6                	mv	s7,s1
  int i = 0;
    80004fea:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fec:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fee:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ff2:	21c48c13          	addi	s8,s1,540
    80004ff6:	a08d                	j	80005058 <pipewrite+0xa8>
      release(&pi->lock);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	c9e080e7          	jalr	-866(ra) # 80000c98 <release>
      return -1;
    80005002:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005004:	854a                	mv	a0,s2
    80005006:	70a6                	ld	ra,104(sp)
    80005008:	7406                	ld	s0,96(sp)
    8000500a:	64e6                	ld	s1,88(sp)
    8000500c:	6946                	ld	s2,80(sp)
    8000500e:	69a6                	ld	s3,72(sp)
    80005010:	6a06                	ld	s4,64(sp)
    80005012:	7ae2                	ld	s5,56(sp)
    80005014:	7b42                	ld	s6,48(sp)
    80005016:	7ba2                	ld	s7,40(sp)
    80005018:	7c02                	ld	s8,32(sp)
    8000501a:	6ce2                	ld	s9,24(sp)
    8000501c:	6165                	addi	sp,sp,112
    8000501e:	8082                	ret
      wakeup(&pi->nread);
    80005020:	8566                	mv	a0,s9
    80005022:	ffffd097          	auipc	ra,0xffffd
    80005026:	5aa080e7          	jalr	1450(ra) # 800025cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000502a:	85de                	mv	a1,s7
    8000502c:	8562                	mv	a0,s8
    8000502e:	ffffd097          	auipc	ra,0xffffd
    80005032:	3ce080e7          	jalr	974(ra) # 800023fc <sleep>
    80005036:	a839                	j	80005054 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005038:	21c4a783          	lw	a5,540(s1)
    8000503c:	0017871b          	addiw	a4,a5,1
    80005040:	20e4ae23          	sw	a4,540(s1)
    80005044:	1ff7f793          	andi	a5,a5,511
    80005048:	97a6                	add	a5,a5,s1
    8000504a:	f9f44703          	lbu	a4,-97(s0)
    8000504e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005052:	2905                	addiw	s2,s2,1
  while(i < n){
    80005054:	03495d63          	bge	s2,s4,8000508e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005058:	2204a783          	lw	a5,544(s1)
    8000505c:	dfd1                	beqz	a5,80004ff8 <pipewrite+0x48>
    8000505e:	0289a783          	lw	a5,40(s3)
    80005062:	fbd9                	bnez	a5,80004ff8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005064:	2184a783          	lw	a5,536(s1)
    80005068:	21c4a703          	lw	a4,540(s1)
    8000506c:	2007879b          	addiw	a5,a5,512
    80005070:	faf708e3          	beq	a4,a5,80005020 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005074:	4685                	li	a3,1
    80005076:	01590633          	add	a2,s2,s5
    8000507a:	f9f40593          	addi	a1,s0,-97
    8000507e:	0509b503          	ld	a0,80(s3)
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	684080e7          	jalr	1668(ra) # 80001706 <copyin>
    8000508a:	fb6517e3          	bne	a0,s6,80005038 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000508e:	21848513          	addi	a0,s1,536
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	53a080e7          	jalr	1338(ra) # 800025cc <wakeup>
  release(&pi->lock);
    8000509a:	8526                	mv	a0,s1
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	bfc080e7          	jalr	-1028(ra) # 80000c98 <release>
  return i;
    800050a4:	b785                	j	80005004 <pipewrite+0x54>
  int i = 0;
    800050a6:	4901                	li	s2,0
    800050a8:	b7dd                	j	8000508e <pipewrite+0xde>

00000000800050aa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050aa:	715d                	addi	sp,sp,-80
    800050ac:	e486                	sd	ra,72(sp)
    800050ae:	e0a2                	sd	s0,64(sp)
    800050b0:	fc26                	sd	s1,56(sp)
    800050b2:	f84a                	sd	s2,48(sp)
    800050b4:	f44e                	sd	s3,40(sp)
    800050b6:	f052                	sd	s4,32(sp)
    800050b8:	ec56                	sd	s5,24(sp)
    800050ba:	e85a                	sd	s6,16(sp)
    800050bc:	0880                	addi	s0,sp,80
    800050be:	84aa                	mv	s1,a0
    800050c0:	892e                	mv	s2,a1
    800050c2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	904080e7          	jalr	-1788(ra) # 800019c8 <myproc>
    800050cc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050ce:	8b26                	mv	s6,s1
    800050d0:	8526                	mv	a0,s1
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	b12080e7          	jalr	-1262(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050da:	2184a703          	lw	a4,536(s1)
    800050de:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050e2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050e6:	02f71463          	bne	a4,a5,8000510e <piperead+0x64>
    800050ea:	2244a783          	lw	a5,548(s1)
    800050ee:	c385                	beqz	a5,8000510e <piperead+0x64>
    if(pr->killed){
    800050f0:	028a2783          	lw	a5,40(s4)
    800050f4:	ebc1                	bnez	a5,80005184 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050f6:	85da                	mv	a1,s6
    800050f8:	854e                	mv	a0,s3
    800050fa:	ffffd097          	auipc	ra,0xffffd
    800050fe:	302080e7          	jalr	770(ra) # 800023fc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005102:	2184a703          	lw	a4,536(s1)
    80005106:	21c4a783          	lw	a5,540(s1)
    8000510a:	fef700e3          	beq	a4,a5,800050ea <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000510e:	09505263          	blez	s5,80005192 <piperead+0xe8>
    80005112:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005114:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005116:	2184a783          	lw	a5,536(s1)
    8000511a:	21c4a703          	lw	a4,540(s1)
    8000511e:	02f70d63          	beq	a4,a5,80005158 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005122:	0017871b          	addiw	a4,a5,1
    80005126:	20e4ac23          	sw	a4,536(s1)
    8000512a:	1ff7f793          	andi	a5,a5,511
    8000512e:	97a6                	add	a5,a5,s1
    80005130:	0187c783          	lbu	a5,24(a5)
    80005134:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005138:	4685                	li	a3,1
    8000513a:	fbf40613          	addi	a2,s0,-65
    8000513e:	85ca                	mv	a1,s2
    80005140:	050a3503          	ld	a0,80(s4)
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	536080e7          	jalr	1334(ra) # 8000167a <copyout>
    8000514c:	01650663          	beq	a0,s6,80005158 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005150:	2985                	addiw	s3,s3,1
    80005152:	0905                	addi	s2,s2,1
    80005154:	fd3a91e3          	bne	s5,s3,80005116 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005158:	21c48513          	addi	a0,s1,540
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	470080e7          	jalr	1136(ra) # 800025cc <wakeup>
  release(&pi->lock);
    80005164:	8526                	mv	a0,s1
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	b32080e7          	jalr	-1230(ra) # 80000c98 <release>
  return i;
}
    8000516e:	854e                	mv	a0,s3
    80005170:	60a6                	ld	ra,72(sp)
    80005172:	6406                	ld	s0,64(sp)
    80005174:	74e2                	ld	s1,56(sp)
    80005176:	7942                	ld	s2,48(sp)
    80005178:	79a2                	ld	s3,40(sp)
    8000517a:	7a02                	ld	s4,32(sp)
    8000517c:	6ae2                	ld	s5,24(sp)
    8000517e:	6b42                	ld	s6,16(sp)
    80005180:	6161                	addi	sp,sp,80
    80005182:	8082                	ret
      release(&pi->lock);
    80005184:	8526                	mv	a0,s1
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
      return -1;
    8000518e:	59fd                	li	s3,-1
    80005190:	bff9                	j	8000516e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005192:	4981                	li	s3,0
    80005194:	b7d1                	j	80005158 <piperead+0xae>

0000000080005196 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005196:	df010113          	addi	sp,sp,-528
    8000519a:	20113423          	sd	ra,520(sp)
    8000519e:	20813023          	sd	s0,512(sp)
    800051a2:	ffa6                	sd	s1,504(sp)
    800051a4:	fbca                	sd	s2,496(sp)
    800051a6:	f7ce                	sd	s3,488(sp)
    800051a8:	f3d2                	sd	s4,480(sp)
    800051aa:	efd6                	sd	s5,472(sp)
    800051ac:	ebda                	sd	s6,464(sp)
    800051ae:	e7de                	sd	s7,456(sp)
    800051b0:	e3e2                	sd	s8,448(sp)
    800051b2:	ff66                	sd	s9,440(sp)
    800051b4:	fb6a                	sd	s10,432(sp)
    800051b6:	f76e                	sd	s11,424(sp)
    800051b8:	0c00                	addi	s0,sp,528
    800051ba:	84aa                	mv	s1,a0
    800051bc:	dea43c23          	sd	a0,-520(s0)
    800051c0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	804080e7          	jalr	-2044(ra) # 800019c8 <myproc>
    800051cc:	892a                	mv	s2,a0

  begin_op();
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	49c080e7          	jalr	1180(ra) # 8000466a <begin_op>

  if((ip = namei(path)) == 0){
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	276080e7          	jalr	630(ra) # 8000444e <namei>
    800051e0:	c92d                	beqz	a0,80005252 <exec+0xbc>
    800051e2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	ab4080e7          	jalr	-1356(ra) # 80003c98 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051ec:	04000713          	li	a4,64
    800051f0:	4681                	li	a3,0
    800051f2:	e5040613          	addi	a2,s0,-432
    800051f6:	4581                	li	a1,0
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	d52080e7          	jalr	-686(ra) # 80003f4c <readi>
    80005202:	04000793          	li	a5,64
    80005206:	00f51a63          	bne	a0,a5,8000521a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000520a:	e5042703          	lw	a4,-432(s0)
    8000520e:	464c47b7          	lui	a5,0x464c4
    80005212:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005216:	04f70463          	beq	a4,a5,8000525e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000521a:	8526                	mv	a0,s1
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	cde080e7          	jalr	-802(ra) # 80003efa <iunlockput>
    end_op();
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	4c6080e7          	jalr	1222(ra) # 800046ea <end_op>
  }
  return -1;
    8000522c:	557d                	li	a0,-1
}
    8000522e:	20813083          	ld	ra,520(sp)
    80005232:	20013403          	ld	s0,512(sp)
    80005236:	74fe                	ld	s1,504(sp)
    80005238:	795e                	ld	s2,496(sp)
    8000523a:	79be                	ld	s3,488(sp)
    8000523c:	7a1e                	ld	s4,480(sp)
    8000523e:	6afe                	ld	s5,472(sp)
    80005240:	6b5e                	ld	s6,464(sp)
    80005242:	6bbe                	ld	s7,456(sp)
    80005244:	6c1e                	ld	s8,448(sp)
    80005246:	7cfa                	ld	s9,440(sp)
    80005248:	7d5a                	ld	s10,432(sp)
    8000524a:	7dba                	ld	s11,424(sp)
    8000524c:	21010113          	addi	sp,sp,528
    80005250:	8082                	ret
    end_op();
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	498080e7          	jalr	1176(ra) # 800046ea <end_op>
    return -1;
    8000525a:	557d                	li	a0,-1
    8000525c:	bfc9                	j	8000522e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000525e:	854a                	mv	a0,s2
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	82c080e7          	jalr	-2004(ra) # 80001a8c <proc_pagetable>
    80005268:	8baa                	mv	s7,a0
    8000526a:	d945                	beqz	a0,8000521a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000526c:	e7042983          	lw	s3,-400(s0)
    80005270:	e8845783          	lhu	a5,-376(s0)
    80005274:	c7ad                	beqz	a5,800052de <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005276:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005278:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000527a:	6c85                	lui	s9,0x1
    8000527c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005280:	def43823          	sd	a5,-528(s0)
    80005284:	a42d                	j	800054ae <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005286:	00003517          	auipc	a0,0x3
    8000528a:	52a50513          	addi	a0,a0,1322 # 800087b0 <syscalls+0x298>
    8000528e:	ffffb097          	auipc	ra,0xffffb
    80005292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005296:	8756                	mv	a4,s5
    80005298:	012d86bb          	addw	a3,s11,s2
    8000529c:	4581                	li	a1,0
    8000529e:	8526                	mv	a0,s1
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	cac080e7          	jalr	-852(ra) # 80003f4c <readi>
    800052a8:	2501                	sext.w	a0,a0
    800052aa:	1aaa9963          	bne	s5,a0,8000545c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052ae:	6785                	lui	a5,0x1
    800052b0:	0127893b          	addw	s2,a5,s2
    800052b4:	77fd                	lui	a5,0xfffff
    800052b6:	01478a3b          	addw	s4,a5,s4
    800052ba:	1f897163          	bgeu	s2,s8,8000549c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052be:	02091593          	slli	a1,s2,0x20
    800052c2:	9181                	srli	a1,a1,0x20
    800052c4:	95ea                	add	a1,a1,s10
    800052c6:	855e                	mv	a0,s7
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	dae080e7          	jalr	-594(ra) # 80001076 <walkaddr>
    800052d0:	862a                	mv	a2,a0
    if(pa == 0)
    800052d2:	d955                	beqz	a0,80005286 <exec+0xf0>
      n = PGSIZE;
    800052d4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052d6:	fd9a70e3          	bgeu	s4,s9,80005296 <exec+0x100>
      n = sz - i;
    800052da:	8ad2                	mv	s5,s4
    800052dc:	bf6d                	j	80005296 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052de:	4901                	li	s2,0
  iunlockput(ip);
    800052e0:	8526                	mv	a0,s1
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	c18080e7          	jalr	-1000(ra) # 80003efa <iunlockput>
  end_op();
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	400080e7          	jalr	1024(ra) # 800046ea <end_op>
  p = myproc();
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	6d6080e7          	jalr	1750(ra) # 800019c8 <myproc>
    800052fa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052fc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005300:	6785                	lui	a5,0x1
    80005302:	17fd                	addi	a5,a5,-1
    80005304:	993e                	add	s2,s2,a5
    80005306:	757d                	lui	a0,0xfffff
    80005308:	00a977b3          	and	a5,s2,a0
    8000530c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005310:	6609                	lui	a2,0x2
    80005312:	963e                	add	a2,a2,a5
    80005314:	85be                	mv	a1,a5
    80005316:	855e                	mv	a0,s7
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	112080e7          	jalr	274(ra) # 8000142a <uvmalloc>
    80005320:	8b2a                	mv	s6,a0
  ip = 0;
    80005322:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005324:	12050c63          	beqz	a0,8000545c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005328:	75f9                	lui	a1,0xffffe
    8000532a:	95aa                	add	a1,a1,a0
    8000532c:	855e                	mv	a0,s7
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	31a080e7          	jalr	794(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005336:	7c7d                	lui	s8,0xfffff
    80005338:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000533a:	e0043783          	ld	a5,-512(s0)
    8000533e:	6388                	ld	a0,0(a5)
    80005340:	c535                	beqz	a0,800053ac <exec+0x216>
    80005342:	e9040993          	addi	s3,s0,-368
    80005346:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000534a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	b18080e7          	jalr	-1256(ra) # 80000e64 <strlen>
    80005354:	2505                	addiw	a0,a0,1
    80005356:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000535a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000535e:	13896363          	bltu	s2,s8,80005484 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005362:	e0043d83          	ld	s11,-512(s0)
    80005366:	000dba03          	ld	s4,0(s11)
    8000536a:	8552                	mv	a0,s4
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	af8080e7          	jalr	-1288(ra) # 80000e64 <strlen>
    80005374:	0015069b          	addiw	a3,a0,1
    80005378:	8652                	mv	a2,s4
    8000537a:	85ca                	mv	a1,s2
    8000537c:	855e                	mv	a0,s7
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	2fc080e7          	jalr	764(ra) # 8000167a <copyout>
    80005386:	10054363          	bltz	a0,8000548c <exec+0x2f6>
    ustack[argc] = sp;
    8000538a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000538e:	0485                	addi	s1,s1,1
    80005390:	008d8793          	addi	a5,s11,8
    80005394:	e0f43023          	sd	a5,-512(s0)
    80005398:	008db503          	ld	a0,8(s11)
    8000539c:	c911                	beqz	a0,800053b0 <exec+0x21a>
    if(argc >= MAXARG)
    8000539e:	09a1                	addi	s3,s3,8
    800053a0:	fb3c96e3          	bne	s9,s3,8000534c <exec+0x1b6>
  sz = sz1;
    800053a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053a8:	4481                	li	s1,0
    800053aa:	a84d                	j	8000545c <exec+0x2c6>
  sp = sz;
    800053ac:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053ae:	4481                	li	s1,0
  ustack[argc] = 0;
    800053b0:	00349793          	slli	a5,s1,0x3
    800053b4:	f9040713          	addi	a4,s0,-112
    800053b8:	97ba                	add	a5,a5,a4
    800053ba:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053be:	00148693          	addi	a3,s1,1
    800053c2:	068e                	slli	a3,a3,0x3
    800053c4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053c8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053cc:	01897663          	bgeu	s2,s8,800053d8 <exec+0x242>
  sz = sz1;
    800053d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d4:	4481                	li	s1,0
    800053d6:	a059                	j	8000545c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053d8:	e9040613          	addi	a2,s0,-368
    800053dc:	85ca                	mv	a1,s2
    800053de:	855e                	mv	a0,s7
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	29a080e7          	jalr	666(ra) # 8000167a <copyout>
    800053e8:	0a054663          	bltz	a0,80005494 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800053ec:	058ab783          	ld	a5,88(s5)
    800053f0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053f4:	df843783          	ld	a5,-520(s0)
    800053f8:	0007c703          	lbu	a4,0(a5)
    800053fc:	cf11                	beqz	a4,80005418 <exec+0x282>
    800053fe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005400:	02f00693          	li	a3,47
    80005404:	a039                	j	80005412 <exec+0x27c>
      last = s+1;
    80005406:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000540a:	0785                	addi	a5,a5,1
    8000540c:	fff7c703          	lbu	a4,-1(a5)
    80005410:	c701                	beqz	a4,80005418 <exec+0x282>
    if(*s == '/')
    80005412:	fed71ce3          	bne	a4,a3,8000540a <exec+0x274>
    80005416:	bfc5                	j	80005406 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005418:	4641                	li	a2,16
    8000541a:	df843583          	ld	a1,-520(s0)
    8000541e:	158a8513          	addi	a0,s5,344
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	a10080e7          	jalr	-1520(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000542a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000542e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005432:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005436:	058ab783          	ld	a5,88(s5)
    8000543a:	e6843703          	ld	a4,-408(s0)
    8000543e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005440:	058ab783          	ld	a5,88(s5)
    80005444:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005448:	85ea                	mv	a1,s10
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	6de080e7          	jalr	1758(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005452:	0004851b          	sext.w	a0,s1
    80005456:	bbe1                	j	8000522e <exec+0x98>
    80005458:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000545c:	e0843583          	ld	a1,-504(s0)
    80005460:	855e                	mv	a0,s7
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	6c6080e7          	jalr	1734(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    8000546a:	da0498e3          	bnez	s1,8000521a <exec+0x84>
  return -1;
    8000546e:	557d                	li	a0,-1
    80005470:	bb7d                	j	8000522e <exec+0x98>
    80005472:	e1243423          	sd	s2,-504(s0)
    80005476:	b7dd                	j	8000545c <exec+0x2c6>
    80005478:	e1243423          	sd	s2,-504(s0)
    8000547c:	b7c5                	j	8000545c <exec+0x2c6>
    8000547e:	e1243423          	sd	s2,-504(s0)
    80005482:	bfe9                	j	8000545c <exec+0x2c6>
  sz = sz1;
    80005484:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005488:	4481                	li	s1,0
    8000548a:	bfc9                	j	8000545c <exec+0x2c6>
  sz = sz1;
    8000548c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005490:	4481                	li	s1,0
    80005492:	b7e9                	j	8000545c <exec+0x2c6>
  sz = sz1;
    80005494:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005498:	4481                	li	s1,0
    8000549a:	b7c9                	j	8000545c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000549c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054a0:	2b05                	addiw	s6,s6,1
    800054a2:	0389899b          	addiw	s3,s3,56
    800054a6:	e8845783          	lhu	a5,-376(s0)
    800054aa:	e2fb5be3          	bge	s6,a5,800052e0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054ae:	2981                	sext.w	s3,s3
    800054b0:	03800713          	li	a4,56
    800054b4:	86ce                	mv	a3,s3
    800054b6:	e1840613          	addi	a2,s0,-488
    800054ba:	4581                	li	a1,0
    800054bc:	8526                	mv	a0,s1
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	a8e080e7          	jalr	-1394(ra) # 80003f4c <readi>
    800054c6:	03800793          	li	a5,56
    800054ca:	f8f517e3          	bne	a0,a5,80005458 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054ce:	e1842783          	lw	a5,-488(s0)
    800054d2:	4705                	li	a4,1
    800054d4:	fce796e3          	bne	a5,a4,800054a0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054d8:	e4043603          	ld	a2,-448(s0)
    800054dc:	e3843783          	ld	a5,-456(s0)
    800054e0:	f8f669e3          	bltu	a2,a5,80005472 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054e4:	e2843783          	ld	a5,-472(s0)
    800054e8:	963e                	add	a2,a2,a5
    800054ea:	f8f667e3          	bltu	a2,a5,80005478 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054ee:	85ca                	mv	a1,s2
    800054f0:	855e                	mv	a0,s7
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	f38080e7          	jalr	-200(ra) # 8000142a <uvmalloc>
    800054fa:	e0a43423          	sd	a0,-504(s0)
    800054fe:	d141                	beqz	a0,8000547e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005500:	e2843d03          	ld	s10,-472(s0)
    80005504:	df043783          	ld	a5,-528(s0)
    80005508:	00fd77b3          	and	a5,s10,a5
    8000550c:	fba1                	bnez	a5,8000545c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000550e:	e2042d83          	lw	s11,-480(s0)
    80005512:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005516:	f80c03e3          	beqz	s8,8000549c <exec+0x306>
    8000551a:	8a62                	mv	s4,s8
    8000551c:	4901                	li	s2,0
    8000551e:	b345                	j	800052be <exec+0x128>

0000000080005520 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005520:	7179                	addi	sp,sp,-48
    80005522:	f406                	sd	ra,40(sp)
    80005524:	f022                	sd	s0,32(sp)
    80005526:	ec26                	sd	s1,24(sp)
    80005528:	e84a                	sd	s2,16(sp)
    8000552a:	1800                	addi	s0,sp,48
    8000552c:	892e                	mv	s2,a1
    8000552e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005530:	fdc40593          	addi	a1,s0,-36
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	b8e080e7          	jalr	-1138(ra) # 800030c2 <argint>
    8000553c:	04054063          	bltz	a0,8000557c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005540:	fdc42703          	lw	a4,-36(s0)
    80005544:	47bd                	li	a5,15
    80005546:	02e7ed63          	bltu	a5,a4,80005580 <argfd+0x60>
    8000554a:	ffffc097          	auipc	ra,0xffffc
    8000554e:	47e080e7          	jalr	1150(ra) # 800019c8 <myproc>
    80005552:	fdc42703          	lw	a4,-36(s0)
    80005556:	01a70793          	addi	a5,a4,26
    8000555a:	078e                	slli	a5,a5,0x3
    8000555c:	953e                	add	a0,a0,a5
    8000555e:	611c                	ld	a5,0(a0)
    80005560:	c395                	beqz	a5,80005584 <argfd+0x64>
    return -1;
  if(pfd)
    80005562:	00090463          	beqz	s2,8000556a <argfd+0x4a>
    *pfd = fd;
    80005566:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000556a:	4501                	li	a0,0
  if(pf)
    8000556c:	c091                	beqz	s1,80005570 <argfd+0x50>
    *pf = f;
    8000556e:	e09c                	sd	a5,0(s1)
}
    80005570:	70a2                	ld	ra,40(sp)
    80005572:	7402                	ld	s0,32(sp)
    80005574:	64e2                	ld	s1,24(sp)
    80005576:	6942                	ld	s2,16(sp)
    80005578:	6145                	addi	sp,sp,48
    8000557a:	8082                	ret
    return -1;
    8000557c:	557d                	li	a0,-1
    8000557e:	bfcd                	j	80005570 <argfd+0x50>
    return -1;
    80005580:	557d                	li	a0,-1
    80005582:	b7fd                	j	80005570 <argfd+0x50>
    80005584:	557d                	li	a0,-1
    80005586:	b7ed                	j	80005570 <argfd+0x50>

0000000080005588 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005588:	1101                	addi	sp,sp,-32
    8000558a:	ec06                	sd	ra,24(sp)
    8000558c:	e822                	sd	s0,16(sp)
    8000558e:	e426                	sd	s1,8(sp)
    80005590:	1000                	addi	s0,sp,32
    80005592:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005594:	ffffc097          	auipc	ra,0xffffc
    80005598:	434080e7          	jalr	1076(ra) # 800019c8 <myproc>
    8000559c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000559e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    800055a2:	4501                	li	a0,0
    800055a4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055a6:	6398                	ld	a4,0(a5)
    800055a8:	cb19                	beqz	a4,800055be <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055aa:	2505                	addiw	a0,a0,1
    800055ac:	07a1                	addi	a5,a5,8
    800055ae:	fed51ce3          	bne	a0,a3,800055a6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055b2:	557d                	li	a0,-1
}
    800055b4:	60e2                	ld	ra,24(sp)
    800055b6:	6442                	ld	s0,16(sp)
    800055b8:	64a2                	ld	s1,8(sp)
    800055ba:	6105                	addi	sp,sp,32
    800055bc:	8082                	ret
      p->ofile[fd] = f;
    800055be:	01a50793          	addi	a5,a0,26
    800055c2:	078e                	slli	a5,a5,0x3
    800055c4:	963e                	add	a2,a2,a5
    800055c6:	e204                	sd	s1,0(a2)
      return fd;
    800055c8:	b7f5                	j	800055b4 <fdalloc+0x2c>

00000000800055ca <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055ca:	715d                	addi	sp,sp,-80
    800055cc:	e486                	sd	ra,72(sp)
    800055ce:	e0a2                	sd	s0,64(sp)
    800055d0:	fc26                	sd	s1,56(sp)
    800055d2:	f84a                	sd	s2,48(sp)
    800055d4:	f44e                	sd	s3,40(sp)
    800055d6:	f052                	sd	s4,32(sp)
    800055d8:	ec56                	sd	s5,24(sp)
    800055da:	0880                	addi	s0,sp,80
    800055dc:	89ae                	mv	s3,a1
    800055de:	8ab2                	mv	s5,a2
    800055e0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055e2:	fb040593          	addi	a1,s0,-80
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	e86080e7          	jalr	-378(ra) # 8000446c <nameiparent>
    800055ee:	892a                	mv	s2,a0
    800055f0:	12050f63          	beqz	a0,8000572e <create+0x164>
    return 0;

  ilock(dp);
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	6a4080e7          	jalr	1700(ra) # 80003c98 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055fc:	4601                	li	a2,0
    800055fe:	fb040593          	addi	a1,s0,-80
    80005602:	854a                	mv	a0,s2
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	b78080e7          	jalr	-1160(ra) # 8000417c <dirlookup>
    8000560c:	84aa                	mv	s1,a0
    8000560e:	c921                	beqz	a0,8000565e <create+0x94>
    iunlockput(dp);
    80005610:	854a                	mv	a0,s2
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	8e8080e7          	jalr	-1816(ra) # 80003efa <iunlockput>
    ilock(ip);
    8000561a:	8526                	mv	a0,s1
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	67c080e7          	jalr	1660(ra) # 80003c98 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005624:	2981                	sext.w	s3,s3
    80005626:	4789                	li	a5,2
    80005628:	02f99463          	bne	s3,a5,80005650 <create+0x86>
    8000562c:	0444d783          	lhu	a5,68(s1)
    80005630:	37f9                	addiw	a5,a5,-2
    80005632:	17c2                	slli	a5,a5,0x30
    80005634:	93c1                	srli	a5,a5,0x30
    80005636:	4705                	li	a4,1
    80005638:	00f76c63          	bltu	a4,a5,80005650 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000563c:	8526                	mv	a0,s1
    8000563e:	60a6                	ld	ra,72(sp)
    80005640:	6406                	ld	s0,64(sp)
    80005642:	74e2                	ld	s1,56(sp)
    80005644:	7942                	ld	s2,48(sp)
    80005646:	79a2                	ld	s3,40(sp)
    80005648:	7a02                	ld	s4,32(sp)
    8000564a:	6ae2                	ld	s5,24(sp)
    8000564c:	6161                	addi	sp,sp,80
    8000564e:	8082                	ret
    iunlockput(ip);
    80005650:	8526                	mv	a0,s1
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	8a8080e7          	jalr	-1880(ra) # 80003efa <iunlockput>
    return 0;
    8000565a:	4481                	li	s1,0
    8000565c:	b7c5                	j	8000563c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000565e:	85ce                	mv	a1,s3
    80005660:	00092503          	lw	a0,0(s2)
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	49c080e7          	jalr	1180(ra) # 80003b00 <ialloc>
    8000566c:	84aa                	mv	s1,a0
    8000566e:	c529                	beqz	a0,800056b8 <create+0xee>
  ilock(ip);
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	628080e7          	jalr	1576(ra) # 80003c98 <ilock>
  ip->major = major;
    80005678:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000567c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005680:	4785                	li	a5,1
    80005682:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005686:	8526                	mv	a0,s1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	546080e7          	jalr	1350(ra) # 80003bce <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005690:	2981                	sext.w	s3,s3
    80005692:	4785                	li	a5,1
    80005694:	02f98a63          	beq	s3,a5,800056c8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005698:	40d0                	lw	a2,4(s1)
    8000569a:	fb040593          	addi	a1,s0,-80
    8000569e:	854a                	mv	a0,s2
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	cec080e7          	jalr	-788(ra) # 8000438c <dirlink>
    800056a8:	06054b63          	bltz	a0,8000571e <create+0x154>
  iunlockput(dp);
    800056ac:	854a                	mv	a0,s2
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	84c080e7          	jalr	-1972(ra) # 80003efa <iunlockput>
  return ip;
    800056b6:	b759                	j	8000563c <create+0x72>
    panic("create: ialloc");
    800056b8:	00003517          	auipc	a0,0x3
    800056bc:	11850513          	addi	a0,a0,280 # 800087d0 <syscalls+0x2b8>
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	e7e080e7          	jalr	-386(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056c8:	04a95783          	lhu	a5,74(s2)
    800056cc:	2785                	addiw	a5,a5,1
    800056ce:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	4fa080e7          	jalr	1274(ra) # 80003bce <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056dc:	40d0                	lw	a2,4(s1)
    800056de:	00003597          	auipc	a1,0x3
    800056e2:	10258593          	addi	a1,a1,258 # 800087e0 <syscalls+0x2c8>
    800056e6:	8526                	mv	a0,s1
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	ca4080e7          	jalr	-860(ra) # 8000438c <dirlink>
    800056f0:	00054f63          	bltz	a0,8000570e <create+0x144>
    800056f4:	00492603          	lw	a2,4(s2)
    800056f8:	00003597          	auipc	a1,0x3
    800056fc:	0f058593          	addi	a1,a1,240 # 800087e8 <syscalls+0x2d0>
    80005700:	8526                	mv	a0,s1
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	c8a080e7          	jalr	-886(ra) # 8000438c <dirlink>
    8000570a:	f80557e3          	bgez	a0,80005698 <create+0xce>
      panic("create dots");
    8000570e:	00003517          	auipc	a0,0x3
    80005712:	0e250513          	addi	a0,a0,226 # 800087f0 <syscalls+0x2d8>
    80005716:	ffffb097          	auipc	ra,0xffffb
    8000571a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000571e:	00003517          	auipc	a0,0x3
    80005722:	0e250513          	addi	a0,a0,226 # 80008800 <syscalls+0x2e8>
    80005726:	ffffb097          	auipc	ra,0xffffb
    8000572a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>
    return 0;
    8000572e:	84aa                	mv	s1,a0
    80005730:	b731                	j	8000563c <create+0x72>

0000000080005732 <sys_dup>:
{
    80005732:	7179                	addi	sp,sp,-48
    80005734:	f406                	sd	ra,40(sp)
    80005736:	f022                	sd	s0,32(sp)
    80005738:	ec26                	sd	s1,24(sp)
    8000573a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000573c:	fd840613          	addi	a2,s0,-40
    80005740:	4581                	li	a1,0
    80005742:	4501                	li	a0,0
    80005744:	00000097          	auipc	ra,0x0
    80005748:	ddc080e7          	jalr	-548(ra) # 80005520 <argfd>
    return -1;
    8000574c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000574e:	02054363          	bltz	a0,80005774 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005752:	fd843503          	ld	a0,-40(s0)
    80005756:	00000097          	auipc	ra,0x0
    8000575a:	e32080e7          	jalr	-462(ra) # 80005588 <fdalloc>
    8000575e:	84aa                	mv	s1,a0
    return -1;
    80005760:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005762:	00054963          	bltz	a0,80005774 <sys_dup+0x42>
  filedup(f);
    80005766:	fd843503          	ld	a0,-40(s0)
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	37a080e7          	jalr	890(ra) # 80004ae4 <filedup>
  return fd;
    80005772:	87a6                	mv	a5,s1
}
    80005774:	853e                	mv	a0,a5
    80005776:	70a2                	ld	ra,40(sp)
    80005778:	7402                	ld	s0,32(sp)
    8000577a:	64e2                	ld	s1,24(sp)
    8000577c:	6145                	addi	sp,sp,48
    8000577e:	8082                	ret

0000000080005780 <sys_read>:
{
    80005780:	7179                	addi	sp,sp,-48
    80005782:	f406                	sd	ra,40(sp)
    80005784:	f022                	sd	s0,32(sp)
    80005786:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005788:	fe840613          	addi	a2,s0,-24
    8000578c:	4581                	li	a1,0
    8000578e:	4501                	li	a0,0
    80005790:	00000097          	auipc	ra,0x0
    80005794:	d90080e7          	jalr	-624(ra) # 80005520 <argfd>
    return -1;
    80005798:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000579a:	04054163          	bltz	a0,800057dc <sys_read+0x5c>
    8000579e:	fe440593          	addi	a1,s0,-28
    800057a2:	4509                	li	a0,2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	91e080e7          	jalr	-1762(ra) # 800030c2 <argint>
    return -1;
    800057ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ae:	02054763          	bltz	a0,800057dc <sys_read+0x5c>
    800057b2:	fd840593          	addi	a1,s0,-40
    800057b6:	4505                	li	a0,1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	92c080e7          	jalr	-1748(ra) # 800030e4 <argaddr>
    return -1;
    800057c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057c2:	00054d63          	bltz	a0,800057dc <sys_read+0x5c>
  return fileread(f, p, n);
    800057c6:	fe442603          	lw	a2,-28(s0)
    800057ca:	fd843583          	ld	a1,-40(s0)
    800057ce:	fe843503          	ld	a0,-24(s0)
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	49e080e7          	jalr	1182(ra) # 80004c70 <fileread>
    800057da:	87aa                	mv	a5,a0
}
    800057dc:	853e                	mv	a0,a5
    800057de:	70a2                	ld	ra,40(sp)
    800057e0:	7402                	ld	s0,32(sp)
    800057e2:	6145                	addi	sp,sp,48
    800057e4:	8082                	ret

00000000800057e6 <sys_write>:
{
    800057e6:	7179                	addi	sp,sp,-48
    800057e8:	f406                	sd	ra,40(sp)
    800057ea:	f022                	sd	s0,32(sp)
    800057ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ee:	fe840613          	addi	a2,s0,-24
    800057f2:	4581                	li	a1,0
    800057f4:	4501                	li	a0,0
    800057f6:	00000097          	auipc	ra,0x0
    800057fa:	d2a080e7          	jalr	-726(ra) # 80005520 <argfd>
    return -1;
    800057fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005800:	04054163          	bltz	a0,80005842 <sys_write+0x5c>
    80005804:	fe440593          	addi	a1,s0,-28
    80005808:	4509                	li	a0,2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	8b8080e7          	jalr	-1864(ra) # 800030c2 <argint>
    return -1;
    80005812:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005814:	02054763          	bltz	a0,80005842 <sys_write+0x5c>
    80005818:	fd840593          	addi	a1,s0,-40
    8000581c:	4505                	li	a0,1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	8c6080e7          	jalr	-1850(ra) # 800030e4 <argaddr>
    return -1;
    80005826:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005828:	00054d63          	bltz	a0,80005842 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000582c:	fe442603          	lw	a2,-28(s0)
    80005830:	fd843583          	ld	a1,-40(s0)
    80005834:	fe843503          	ld	a0,-24(s0)
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	4fa080e7          	jalr	1274(ra) # 80004d32 <filewrite>
    80005840:	87aa                	mv	a5,a0
}
    80005842:	853e                	mv	a0,a5
    80005844:	70a2                	ld	ra,40(sp)
    80005846:	7402                	ld	s0,32(sp)
    80005848:	6145                	addi	sp,sp,48
    8000584a:	8082                	ret

000000008000584c <sys_close>:
{
    8000584c:	1101                	addi	sp,sp,-32
    8000584e:	ec06                	sd	ra,24(sp)
    80005850:	e822                	sd	s0,16(sp)
    80005852:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005854:	fe040613          	addi	a2,s0,-32
    80005858:	fec40593          	addi	a1,s0,-20
    8000585c:	4501                	li	a0,0
    8000585e:	00000097          	auipc	ra,0x0
    80005862:	cc2080e7          	jalr	-830(ra) # 80005520 <argfd>
    return -1;
    80005866:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005868:	02054463          	bltz	a0,80005890 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000586c:	ffffc097          	auipc	ra,0xffffc
    80005870:	15c080e7          	jalr	348(ra) # 800019c8 <myproc>
    80005874:	fec42783          	lw	a5,-20(s0)
    80005878:	07e9                	addi	a5,a5,26
    8000587a:	078e                	slli	a5,a5,0x3
    8000587c:	97aa                	add	a5,a5,a0
    8000587e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005882:	fe043503          	ld	a0,-32(s0)
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	2b0080e7          	jalr	688(ra) # 80004b36 <fileclose>
  return 0;
    8000588e:	4781                	li	a5,0
}
    80005890:	853e                	mv	a0,a5
    80005892:	60e2                	ld	ra,24(sp)
    80005894:	6442                	ld	s0,16(sp)
    80005896:	6105                	addi	sp,sp,32
    80005898:	8082                	ret

000000008000589a <sys_fstat>:
{
    8000589a:	1101                	addi	sp,sp,-32
    8000589c:	ec06                	sd	ra,24(sp)
    8000589e:	e822                	sd	s0,16(sp)
    800058a0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058a2:	fe840613          	addi	a2,s0,-24
    800058a6:	4581                	li	a1,0
    800058a8:	4501                	li	a0,0
    800058aa:	00000097          	auipc	ra,0x0
    800058ae:	c76080e7          	jalr	-906(ra) # 80005520 <argfd>
    return -1;
    800058b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058b4:	02054563          	bltz	a0,800058de <sys_fstat+0x44>
    800058b8:	fe040593          	addi	a1,s0,-32
    800058bc:	4505                	li	a0,1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	826080e7          	jalr	-2010(ra) # 800030e4 <argaddr>
    return -1;
    800058c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058c8:	00054b63          	bltz	a0,800058de <sys_fstat+0x44>
  return filestat(f, st);
    800058cc:	fe043583          	ld	a1,-32(s0)
    800058d0:	fe843503          	ld	a0,-24(s0)
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	32a080e7          	jalr	810(ra) # 80004bfe <filestat>
    800058dc:	87aa                	mv	a5,a0
}
    800058de:	853e                	mv	a0,a5
    800058e0:	60e2                	ld	ra,24(sp)
    800058e2:	6442                	ld	s0,16(sp)
    800058e4:	6105                	addi	sp,sp,32
    800058e6:	8082                	ret

00000000800058e8 <sys_link>:
{
    800058e8:	7169                	addi	sp,sp,-304
    800058ea:	f606                	sd	ra,296(sp)
    800058ec:	f222                	sd	s0,288(sp)
    800058ee:	ee26                	sd	s1,280(sp)
    800058f0:	ea4a                	sd	s2,272(sp)
    800058f2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058f4:	08000613          	li	a2,128
    800058f8:	ed040593          	addi	a1,s0,-304
    800058fc:	4501                	li	a0,0
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	808080e7          	jalr	-2040(ra) # 80003106 <argstr>
    return -1;
    80005906:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005908:	10054e63          	bltz	a0,80005a24 <sys_link+0x13c>
    8000590c:	08000613          	li	a2,128
    80005910:	f5040593          	addi	a1,s0,-176
    80005914:	4505                	li	a0,1
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	7f0080e7          	jalr	2032(ra) # 80003106 <argstr>
    return -1;
    8000591e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005920:	10054263          	bltz	a0,80005a24 <sys_link+0x13c>
  begin_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	d46080e7          	jalr	-698(ra) # 8000466a <begin_op>
  if((ip = namei(old)) == 0){
    8000592c:	ed040513          	addi	a0,s0,-304
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	b1e080e7          	jalr	-1250(ra) # 8000444e <namei>
    80005938:	84aa                	mv	s1,a0
    8000593a:	c551                	beqz	a0,800059c6 <sys_link+0xde>
  ilock(ip);
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	35c080e7          	jalr	860(ra) # 80003c98 <ilock>
  if(ip->type == T_DIR){
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	4785                	li	a5,1
    8000594a:	08f70463          	beq	a4,a5,800059d2 <sys_link+0xea>
  ip->nlink++;
    8000594e:	04a4d783          	lhu	a5,74(s1)
    80005952:	2785                	addiw	a5,a5,1
    80005954:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	274080e7          	jalr	628(ra) # 80003bce <iupdate>
  iunlock(ip);
    80005962:	8526                	mv	a0,s1
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	3f6080e7          	jalr	1014(ra) # 80003d5a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000596c:	fd040593          	addi	a1,s0,-48
    80005970:	f5040513          	addi	a0,s0,-176
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	af8080e7          	jalr	-1288(ra) # 8000446c <nameiparent>
    8000597c:	892a                	mv	s2,a0
    8000597e:	c935                	beqz	a0,800059f2 <sys_link+0x10a>
  ilock(dp);
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	318080e7          	jalr	792(ra) # 80003c98 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005988:	00092703          	lw	a4,0(s2)
    8000598c:	409c                	lw	a5,0(s1)
    8000598e:	04f71d63          	bne	a4,a5,800059e8 <sys_link+0x100>
    80005992:	40d0                	lw	a2,4(s1)
    80005994:	fd040593          	addi	a1,s0,-48
    80005998:	854a                	mv	a0,s2
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	9f2080e7          	jalr	-1550(ra) # 8000438c <dirlink>
    800059a2:	04054363          	bltz	a0,800059e8 <sys_link+0x100>
  iunlockput(dp);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	552080e7          	jalr	1362(ra) # 80003efa <iunlockput>
  iput(ip);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	4a0080e7          	jalr	1184(ra) # 80003e52 <iput>
  end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	d30080e7          	jalr	-720(ra) # 800046ea <end_op>
  return 0;
    800059c2:	4781                	li	a5,0
    800059c4:	a085                	j	80005a24 <sys_link+0x13c>
    end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	d24080e7          	jalr	-732(ra) # 800046ea <end_op>
    return -1;
    800059ce:	57fd                	li	a5,-1
    800059d0:	a891                	j	80005a24 <sys_link+0x13c>
    iunlockput(ip);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	526080e7          	jalr	1318(ra) # 80003efa <iunlockput>
    end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	d0e080e7          	jalr	-754(ra) # 800046ea <end_op>
    return -1;
    800059e4:	57fd                	li	a5,-1
    800059e6:	a83d                	j	80005a24 <sys_link+0x13c>
    iunlockput(dp);
    800059e8:	854a                	mv	a0,s2
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	510080e7          	jalr	1296(ra) # 80003efa <iunlockput>
  ilock(ip);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	2a4080e7          	jalr	676(ra) # 80003c98 <ilock>
  ip->nlink--;
    800059fc:	04a4d783          	lhu	a5,74(s1)
    80005a00:	37fd                	addiw	a5,a5,-1
    80005a02:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	1c6080e7          	jalr	454(ra) # 80003bce <iupdate>
  iunlockput(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	4e8080e7          	jalr	1256(ra) # 80003efa <iunlockput>
  end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	cd0080e7          	jalr	-816(ra) # 800046ea <end_op>
  return -1;
    80005a22:	57fd                	li	a5,-1
}
    80005a24:	853e                	mv	a0,a5
    80005a26:	70b2                	ld	ra,296(sp)
    80005a28:	7412                	ld	s0,288(sp)
    80005a2a:	64f2                	ld	s1,280(sp)
    80005a2c:	6952                	ld	s2,272(sp)
    80005a2e:	6155                	addi	sp,sp,304
    80005a30:	8082                	ret

0000000080005a32 <sys_unlink>:
{
    80005a32:	7151                	addi	sp,sp,-240
    80005a34:	f586                	sd	ra,232(sp)
    80005a36:	f1a2                	sd	s0,224(sp)
    80005a38:	eda6                	sd	s1,216(sp)
    80005a3a:	e9ca                	sd	s2,208(sp)
    80005a3c:	e5ce                	sd	s3,200(sp)
    80005a3e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a40:	08000613          	li	a2,128
    80005a44:	f3040593          	addi	a1,s0,-208
    80005a48:	4501                	li	a0,0
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	6bc080e7          	jalr	1724(ra) # 80003106 <argstr>
    80005a52:	18054163          	bltz	a0,80005bd4 <sys_unlink+0x1a2>
  begin_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	c14080e7          	jalr	-1004(ra) # 8000466a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a5e:	fb040593          	addi	a1,s0,-80
    80005a62:	f3040513          	addi	a0,s0,-208
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	a06080e7          	jalr	-1530(ra) # 8000446c <nameiparent>
    80005a6e:	84aa                	mv	s1,a0
    80005a70:	c979                	beqz	a0,80005b46 <sys_unlink+0x114>
  ilock(dp);
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	226080e7          	jalr	550(ra) # 80003c98 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a7a:	00003597          	auipc	a1,0x3
    80005a7e:	d6658593          	addi	a1,a1,-666 # 800087e0 <syscalls+0x2c8>
    80005a82:	fb040513          	addi	a0,s0,-80
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	6dc080e7          	jalr	1756(ra) # 80004162 <namecmp>
    80005a8e:	14050a63          	beqz	a0,80005be2 <sys_unlink+0x1b0>
    80005a92:	00003597          	auipc	a1,0x3
    80005a96:	d5658593          	addi	a1,a1,-682 # 800087e8 <syscalls+0x2d0>
    80005a9a:	fb040513          	addi	a0,s0,-80
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	6c4080e7          	jalr	1732(ra) # 80004162 <namecmp>
    80005aa6:	12050e63          	beqz	a0,80005be2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aaa:	f2c40613          	addi	a2,s0,-212
    80005aae:	fb040593          	addi	a1,s0,-80
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	6c8080e7          	jalr	1736(ra) # 8000417c <dirlookup>
    80005abc:	892a                	mv	s2,a0
    80005abe:	12050263          	beqz	a0,80005be2 <sys_unlink+0x1b0>
  ilock(ip);
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	1d6080e7          	jalr	470(ra) # 80003c98 <ilock>
  if(ip->nlink < 1)
    80005aca:	04a91783          	lh	a5,74(s2)
    80005ace:	08f05263          	blez	a5,80005b52 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ad2:	04491703          	lh	a4,68(s2)
    80005ad6:	4785                	li	a5,1
    80005ad8:	08f70563          	beq	a4,a5,80005b62 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005adc:	4641                	li	a2,16
    80005ade:	4581                	li	a1,0
    80005ae0:	fc040513          	addi	a0,s0,-64
    80005ae4:	ffffb097          	auipc	ra,0xffffb
    80005ae8:	1fc080e7          	jalr	508(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aec:	4741                	li	a4,16
    80005aee:	f2c42683          	lw	a3,-212(s0)
    80005af2:	fc040613          	addi	a2,s0,-64
    80005af6:	4581                	li	a1,0
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	54a080e7          	jalr	1354(ra) # 80004044 <writei>
    80005b02:	47c1                	li	a5,16
    80005b04:	0af51563          	bne	a0,a5,80005bae <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b08:	04491703          	lh	a4,68(s2)
    80005b0c:	4785                	li	a5,1
    80005b0e:	0af70863          	beq	a4,a5,80005bbe <sys_unlink+0x18c>
  iunlockput(dp);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	3e6080e7          	jalr	998(ra) # 80003efa <iunlockput>
  ip->nlink--;
    80005b1c:	04a95783          	lhu	a5,74(s2)
    80005b20:	37fd                	addiw	a5,a5,-1
    80005b22:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b26:	854a                	mv	a0,s2
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	0a6080e7          	jalr	166(ra) # 80003bce <iupdate>
  iunlockput(ip);
    80005b30:	854a                	mv	a0,s2
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	3c8080e7          	jalr	968(ra) # 80003efa <iunlockput>
  end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	bb0080e7          	jalr	-1104(ra) # 800046ea <end_op>
  return 0;
    80005b42:	4501                	li	a0,0
    80005b44:	a84d                	j	80005bf6 <sys_unlink+0x1c4>
    end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	ba4080e7          	jalr	-1116(ra) # 800046ea <end_op>
    return -1;
    80005b4e:	557d                	li	a0,-1
    80005b50:	a05d                	j	80005bf6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b52:	00003517          	auipc	a0,0x3
    80005b56:	cbe50513          	addi	a0,a0,-834 # 80008810 <syscalls+0x2f8>
    80005b5a:	ffffb097          	auipc	ra,0xffffb
    80005b5e:	9e4080e7          	jalr	-1564(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b62:	04c92703          	lw	a4,76(s2)
    80005b66:	02000793          	li	a5,32
    80005b6a:	f6e7f9e3          	bgeu	a5,a4,80005adc <sys_unlink+0xaa>
    80005b6e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b72:	4741                	li	a4,16
    80005b74:	86ce                	mv	a3,s3
    80005b76:	f1840613          	addi	a2,s0,-232
    80005b7a:	4581                	li	a1,0
    80005b7c:	854a                	mv	a0,s2
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	3ce080e7          	jalr	974(ra) # 80003f4c <readi>
    80005b86:	47c1                	li	a5,16
    80005b88:	00f51b63          	bne	a0,a5,80005b9e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b8c:	f1845783          	lhu	a5,-232(s0)
    80005b90:	e7a1                	bnez	a5,80005bd8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b92:	29c1                	addiw	s3,s3,16
    80005b94:	04c92783          	lw	a5,76(s2)
    80005b98:	fcf9ede3          	bltu	s3,a5,80005b72 <sys_unlink+0x140>
    80005b9c:	b781                	j	80005adc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b9e:	00003517          	auipc	a0,0x3
    80005ba2:	c8a50513          	addi	a0,a0,-886 # 80008828 <syscalls+0x310>
    80005ba6:	ffffb097          	auipc	ra,0xffffb
    80005baa:	998080e7          	jalr	-1640(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005bae:	00003517          	auipc	a0,0x3
    80005bb2:	c9250513          	addi	a0,a0,-878 # 80008840 <syscalls+0x328>
    80005bb6:	ffffb097          	auipc	ra,0xffffb
    80005bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>
    dp->nlink--;
    80005bbe:	04a4d783          	lhu	a5,74(s1)
    80005bc2:	37fd                	addiw	a5,a5,-1
    80005bc4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	004080e7          	jalr	4(ra) # 80003bce <iupdate>
    80005bd2:	b781                	j	80005b12 <sys_unlink+0xe0>
    return -1;
    80005bd4:	557d                	li	a0,-1
    80005bd6:	a005                	j	80005bf6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bd8:	854a                	mv	a0,s2
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	320080e7          	jalr	800(ra) # 80003efa <iunlockput>
  iunlockput(dp);
    80005be2:	8526                	mv	a0,s1
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	316080e7          	jalr	790(ra) # 80003efa <iunlockput>
  end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	afe080e7          	jalr	-1282(ra) # 800046ea <end_op>
  return -1;
    80005bf4:	557d                	li	a0,-1
}
    80005bf6:	70ae                	ld	ra,232(sp)
    80005bf8:	740e                	ld	s0,224(sp)
    80005bfa:	64ee                	ld	s1,216(sp)
    80005bfc:	694e                	ld	s2,208(sp)
    80005bfe:	69ae                	ld	s3,200(sp)
    80005c00:	616d                	addi	sp,sp,240
    80005c02:	8082                	ret

0000000080005c04 <sys_open>:

uint64
sys_open(void)
{
    80005c04:	7131                	addi	sp,sp,-192
    80005c06:	fd06                	sd	ra,184(sp)
    80005c08:	f922                	sd	s0,176(sp)
    80005c0a:	f526                	sd	s1,168(sp)
    80005c0c:	f14a                	sd	s2,160(sp)
    80005c0e:	ed4e                	sd	s3,152(sp)
    80005c10:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c12:	08000613          	li	a2,128
    80005c16:	f5040593          	addi	a1,s0,-176
    80005c1a:	4501                	li	a0,0
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	4ea080e7          	jalr	1258(ra) # 80003106 <argstr>
    return -1;
    80005c24:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c26:	0c054163          	bltz	a0,80005ce8 <sys_open+0xe4>
    80005c2a:	f4c40593          	addi	a1,s0,-180
    80005c2e:	4505                	li	a0,1
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	492080e7          	jalr	1170(ra) # 800030c2 <argint>
    80005c38:	0a054863          	bltz	a0,80005ce8 <sys_open+0xe4>

  begin_op();
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a2e080e7          	jalr	-1490(ra) # 8000466a <begin_op>

  if(omode & O_CREATE){
    80005c44:	f4c42783          	lw	a5,-180(s0)
    80005c48:	2007f793          	andi	a5,a5,512
    80005c4c:	cbdd                	beqz	a5,80005d02 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c4e:	4681                	li	a3,0
    80005c50:	4601                	li	a2,0
    80005c52:	4589                	li	a1,2
    80005c54:	f5040513          	addi	a0,s0,-176
    80005c58:	00000097          	auipc	ra,0x0
    80005c5c:	972080e7          	jalr	-1678(ra) # 800055ca <create>
    80005c60:	892a                	mv	s2,a0
    if(ip == 0){
    80005c62:	c959                	beqz	a0,80005cf8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c64:	04491703          	lh	a4,68(s2)
    80005c68:	478d                	li	a5,3
    80005c6a:	00f71763          	bne	a4,a5,80005c78 <sys_open+0x74>
    80005c6e:	04695703          	lhu	a4,70(s2)
    80005c72:	47a5                	li	a5,9
    80005c74:	0ce7ec63          	bltu	a5,a4,80005d4c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	e02080e7          	jalr	-510(ra) # 80004a7a <filealloc>
    80005c80:	89aa                	mv	s3,a0
    80005c82:	10050263          	beqz	a0,80005d86 <sys_open+0x182>
    80005c86:	00000097          	auipc	ra,0x0
    80005c8a:	902080e7          	jalr	-1790(ra) # 80005588 <fdalloc>
    80005c8e:	84aa                	mv	s1,a0
    80005c90:	0e054663          	bltz	a0,80005d7c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c94:	04491703          	lh	a4,68(s2)
    80005c98:	478d                	li	a5,3
    80005c9a:	0cf70463          	beq	a4,a5,80005d62 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c9e:	4789                	li	a5,2
    80005ca0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ca4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ca8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cac:	f4c42783          	lw	a5,-180(s0)
    80005cb0:	0017c713          	xori	a4,a5,1
    80005cb4:	8b05                	andi	a4,a4,1
    80005cb6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cba:	0037f713          	andi	a4,a5,3
    80005cbe:	00e03733          	snez	a4,a4
    80005cc2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cc6:	4007f793          	andi	a5,a5,1024
    80005cca:	c791                	beqz	a5,80005cd6 <sys_open+0xd2>
    80005ccc:	04491703          	lh	a4,68(s2)
    80005cd0:	4789                	li	a5,2
    80005cd2:	08f70f63          	beq	a4,a5,80005d70 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cd6:	854a                	mv	a0,s2
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	082080e7          	jalr	130(ra) # 80003d5a <iunlock>
  end_op();
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	a0a080e7          	jalr	-1526(ra) # 800046ea <end_op>

  return fd;
}
    80005ce8:	8526                	mv	a0,s1
    80005cea:	70ea                	ld	ra,184(sp)
    80005cec:	744a                	ld	s0,176(sp)
    80005cee:	74aa                	ld	s1,168(sp)
    80005cf0:	790a                	ld	s2,160(sp)
    80005cf2:	69ea                	ld	s3,152(sp)
    80005cf4:	6129                	addi	sp,sp,192
    80005cf6:	8082                	ret
      end_op();
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	9f2080e7          	jalr	-1550(ra) # 800046ea <end_op>
      return -1;
    80005d00:	b7e5                	j	80005ce8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d02:	f5040513          	addi	a0,s0,-176
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	748080e7          	jalr	1864(ra) # 8000444e <namei>
    80005d0e:	892a                	mv	s2,a0
    80005d10:	c905                	beqz	a0,80005d40 <sys_open+0x13c>
    ilock(ip);
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	f86080e7          	jalr	-122(ra) # 80003c98 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d1a:	04491703          	lh	a4,68(s2)
    80005d1e:	4785                	li	a5,1
    80005d20:	f4f712e3          	bne	a4,a5,80005c64 <sys_open+0x60>
    80005d24:	f4c42783          	lw	a5,-180(s0)
    80005d28:	dba1                	beqz	a5,80005c78 <sys_open+0x74>
      iunlockput(ip);
    80005d2a:	854a                	mv	a0,s2
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	1ce080e7          	jalr	462(ra) # 80003efa <iunlockput>
      end_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	9b6080e7          	jalr	-1610(ra) # 800046ea <end_op>
      return -1;
    80005d3c:	54fd                	li	s1,-1
    80005d3e:	b76d                	j	80005ce8 <sys_open+0xe4>
      end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	9aa080e7          	jalr	-1622(ra) # 800046ea <end_op>
      return -1;
    80005d48:	54fd                	li	s1,-1
    80005d4a:	bf79                	j	80005ce8 <sys_open+0xe4>
    iunlockput(ip);
    80005d4c:	854a                	mv	a0,s2
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	1ac080e7          	jalr	428(ra) # 80003efa <iunlockput>
    end_op();
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	994080e7          	jalr	-1644(ra) # 800046ea <end_op>
    return -1;
    80005d5e:	54fd                	li	s1,-1
    80005d60:	b761                	j	80005ce8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d62:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d66:	04691783          	lh	a5,70(s2)
    80005d6a:	02f99223          	sh	a5,36(s3)
    80005d6e:	bf2d                	j	80005ca8 <sys_open+0xa4>
    itrunc(ip);
    80005d70:	854a                	mv	a0,s2
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	034080e7          	jalr	52(ra) # 80003da6 <itrunc>
    80005d7a:	bfb1                	j	80005cd6 <sys_open+0xd2>
      fileclose(f);
    80005d7c:	854e                	mv	a0,s3
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	db8080e7          	jalr	-584(ra) # 80004b36 <fileclose>
    iunlockput(ip);
    80005d86:	854a                	mv	a0,s2
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	172080e7          	jalr	370(ra) # 80003efa <iunlockput>
    end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	95a080e7          	jalr	-1702(ra) # 800046ea <end_op>
    return -1;
    80005d98:	54fd                	li	s1,-1
    80005d9a:	b7b9                	j	80005ce8 <sys_open+0xe4>

0000000080005d9c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d9c:	7175                	addi	sp,sp,-144
    80005d9e:	e506                	sd	ra,136(sp)
    80005da0:	e122                	sd	s0,128(sp)
    80005da2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	8c6080e7          	jalr	-1850(ra) # 8000466a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005dac:	08000613          	li	a2,128
    80005db0:	f7040593          	addi	a1,s0,-144
    80005db4:	4501                	li	a0,0
    80005db6:	ffffd097          	auipc	ra,0xffffd
    80005dba:	350080e7          	jalr	848(ra) # 80003106 <argstr>
    80005dbe:	02054963          	bltz	a0,80005df0 <sys_mkdir+0x54>
    80005dc2:	4681                	li	a3,0
    80005dc4:	4601                	li	a2,0
    80005dc6:	4585                	li	a1,1
    80005dc8:	f7040513          	addi	a0,s0,-144
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	7fe080e7          	jalr	2046(ra) # 800055ca <create>
    80005dd4:	cd11                	beqz	a0,80005df0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	124080e7          	jalr	292(ra) # 80003efa <iunlockput>
  end_op();
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	90c080e7          	jalr	-1780(ra) # 800046ea <end_op>
  return 0;
    80005de6:	4501                	li	a0,0
}
    80005de8:	60aa                	ld	ra,136(sp)
    80005dea:	640a                	ld	s0,128(sp)
    80005dec:	6149                	addi	sp,sp,144
    80005dee:	8082                	ret
    end_op();
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	8fa080e7          	jalr	-1798(ra) # 800046ea <end_op>
    return -1;
    80005df8:	557d                	li	a0,-1
    80005dfa:	b7fd                	j	80005de8 <sys_mkdir+0x4c>

0000000080005dfc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dfc:	7135                	addi	sp,sp,-160
    80005dfe:	ed06                	sd	ra,152(sp)
    80005e00:	e922                	sd	s0,144(sp)
    80005e02:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	866080e7          	jalr	-1946(ra) # 8000466a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e0c:	08000613          	li	a2,128
    80005e10:	f7040593          	addi	a1,s0,-144
    80005e14:	4501                	li	a0,0
    80005e16:	ffffd097          	auipc	ra,0xffffd
    80005e1a:	2f0080e7          	jalr	752(ra) # 80003106 <argstr>
    80005e1e:	04054a63          	bltz	a0,80005e72 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e22:	f6c40593          	addi	a1,s0,-148
    80005e26:	4505                	li	a0,1
    80005e28:	ffffd097          	auipc	ra,0xffffd
    80005e2c:	29a080e7          	jalr	666(ra) # 800030c2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e30:	04054163          	bltz	a0,80005e72 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e34:	f6840593          	addi	a1,s0,-152
    80005e38:	4509                	li	a0,2
    80005e3a:	ffffd097          	auipc	ra,0xffffd
    80005e3e:	288080e7          	jalr	648(ra) # 800030c2 <argint>
     argint(1, &major) < 0 ||
    80005e42:	02054863          	bltz	a0,80005e72 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e46:	f6841683          	lh	a3,-152(s0)
    80005e4a:	f6c41603          	lh	a2,-148(s0)
    80005e4e:	458d                	li	a1,3
    80005e50:	f7040513          	addi	a0,s0,-144
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	776080e7          	jalr	1910(ra) # 800055ca <create>
     argint(2, &minor) < 0 ||
    80005e5c:	c919                	beqz	a0,80005e72 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	09c080e7          	jalr	156(ra) # 80003efa <iunlockput>
  end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	884080e7          	jalr	-1916(ra) # 800046ea <end_op>
  return 0;
    80005e6e:	4501                	li	a0,0
    80005e70:	a031                	j	80005e7c <sys_mknod+0x80>
    end_op();
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	878080e7          	jalr	-1928(ra) # 800046ea <end_op>
    return -1;
    80005e7a:	557d                	li	a0,-1
}
    80005e7c:	60ea                	ld	ra,152(sp)
    80005e7e:	644a                	ld	s0,144(sp)
    80005e80:	610d                	addi	sp,sp,160
    80005e82:	8082                	ret

0000000080005e84 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e84:	7135                	addi	sp,sp,-160
    80005e86:	ed06                	sd	ra,152(sp)
    80005e88:	e922                	sd	s0,144(sp)
    80005e8a:	e526                	sd	s1,136(sp)
    80005e8c:	e14a                	sd	s2,128(sp)
    80005e8e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	b38080e7          	jalr	-1224(ra) # 800019c8 <myproc>
    80005e98:	892a                	mv	s2,a0
  
  begin_op();
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	7d0080e7          	jalr	2000(ra) # 8000466a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ea2:	08000613          	li	a2,128
    80005ea6:	f6040593          	addi	a1,s0,-160
    80005eaa:	4501                	li	a0,0
    80005eac:	ffffd097          	auipc	ra,0xffffd
    80005eb0:	25a080e7          	jalr	602(ra) # 80003106 <argstr>
    80005eb4:	04054b63          	bltz	a0,80005f0a <sys_chdir+0x86>
    80005eb8:	f6040513          	addi	a0,s0,-160
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	592080e7          	jalr	1426(ra) # 8000444e <namei>
    80005ec4:	84aa                	mv	s1,a0
    80005ec6:	c131                	beqz	a0,80005f0a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	dd0080e7          	jalr	-560(ra) # 80003c98 <ilock>
  if(ip->type != T_DIR){
    80005ed0:	04449703          	lh	a4,68(s1)
    80005ed4:	4785                	li	a5,1
    80005ed6:	04f71063          	bne	a4,a5,80005f16 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005eda:	8526                	mv	a0,s1
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	e7e080e7          	jalr	-386(ra) # 80003d5a <iunlock>
  iput(p->cwd);
    80005ee4:	15093503          	ld	a0,336(s2)
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	f6a080e7          	jalr	-150(ra) # 80003e52 <iput>
  end_op();
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	7fa080e7          	jalr	2042(ra) # 800046ea <end_op>
  p->cwd = ip;
    80005ef8:	14993823          	sd	s1,336(s2)
  return 0;
    80005efc:	4501                	li	a0,0
}
    80005efe:	60ea                	ld	ra,152(sp)
    80005f00:	644a                	ld	s0,144(sp)
    80005f02:	64aa                	ld	s1,136(sp)
    80005f04:	690a                	ld	s2,128(sp)
    80005f06:	610d                	addi	sp,sp,160
    80005f08:	8082                	ret
    end_op();
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	7e0080e7          	jalr	2016(ra) # 800046ea <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
    80005f14:	b7ed                	j	80005efe <sys_chdir+0x7a>
    iunlockput(ip);
    80005f16:	8526                	mv	a0,s1
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	fe2080e7          	jalr	-30(ra) # 80003efa <iunlockput>
    end_op();
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	7ca080e7          	jalr	1994(ra) # 800046ea <end_op>
    return -1;
    80005f28:	557d                	li	a0,-1
    80005f2a:	bfd1                	j	80005efe <sys_chdir+0x7a>

0000000080005f2c <sys_exec>:

uint64
sys_exec(void)
{
    80005f2c:	7145                	addi	sp,sp,-464
    80005f2e:	e786                	sd	ra,456(sp)
    80005f30:	e3a2                	sd	s0,448(sp)
    80005f32:	ff26                	sd	s1,440(sp)
    80005f34:	fb4a                	sd	s2,432(sp)
    80005f36:	f74e                	sd	s3,424(sp)
    80005f38:	f352                	sd	s4,416(sp)
    80005f3a:	ef56                	sd	s5,408(sp)
    80005f3c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f3e:	08000613          	li	a2,128
    80005f42:	f4040593          	addi	a1,s0,-192
    80005f46:	4501                	li	a0,0
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	1be080e7          	jalr	446(ra) # 80003106 <argstr>
    return -1;
    80005f50:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f52:	0c054a63          	bltz	a0,80006026 <sys_exec+0xfa>
    80005f56:	e3840593          	addi	a1,s0,-456
    80005f5a:	4505                	li	a0,1
    80005f5c:	ffffd097          	auipc	ra,0xffffd
    80005f60:	188080e7          	jalr	392(ra) # 800030e4 <argaddr>
    80005f64:	0c054163          	bltz	a0,80006026 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f68:	10000613          	li	a2,256
    80005f6c:	4581                	li	a1,0
    80005f6e:	e4040513          	addi	a0,s0,-448
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	d6e080e7          	jalr	-658(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f7a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f7e:	89a6                	mv	s3,s1
    80005f80:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f82:	02000a13          	li	s4,32
    80005f86:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f8a:	00391513          	slli	a0,s2,0x3
    80005f8e:	e3040593          	addi	a1,s0,-464
    80005f92:	e3843783          	ld	a5,-456(s0)
    80005f96:	953e                	add	a0,a0,a5
    80005f98:	ffffd097          	auipc	ra,0xffffd
    80005f9c:	090080e7          	jalr	144(ra) # 80003028 <fetchaddr>
    80005fa0:	02054a63          	bltz	a0,80005fd4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005fa4:	e3043783          	ld	a5,-464(s0)
    80005fa8:	c3b9                	beqz	a5,80005fee <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	b4a080e7          	jalr	-1206(ra) # 80000af4 <kalloc>
    80005fb2:	85aa                	mv	a1,a0
    80005fb4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fb8:	cd11                	beqz	a0,80005fd4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fba:	6605                	lui	a2,0x1
    80005fbc:	e3043503          	ld	a0,-464(s0)
    80005fc0:	ffffd097          	auipc	ra,0xffffd
    80005fc4:	0ba080e7          	jalr	186(ra) # 8000307a <fetchstr>
    80005fc8:	00054663          	bltz	a0,80005fd4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fcc:	0905                	addi	s2,s2,1
    80005fce:	09a1                	addi	s3,s3,8
    80005fd0:	fb491be3          	bne	s2,s4,80005f86 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd4:	10048913          	addi	s2,s1,256
    80005fd8:	6088                	ld	a0,0(s1)
    80005fda:	c529                	beqz	a0,80006024 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fdc:	ffffb097          	auipc	ra,0xffffb
    80005fe0:	a1c080e7          	jalr	-1508(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe4:	04a1                	addi	s1,s1,8
    80005fe6:	ff2499e3          	bne	s1,s2,80005fd8 <sys_exec+0xac>
  return -1;
    80005fea:	597d                	li	s2,-1
    80005fec:	a82d                	j	80006026 <sys_exec+0xfa>
      argv[i] = 0;
    80005fee:	0a8e                	slli	s5,s5,0x3
    80005ff0:	fc040793          	addi	a5,s0,-64
    80005ff4:	9abe                	add	s5,s5,a5
    80005ff6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ffa:	e4040593          	addi	a1,s0,-448
    80005ffe:	f4040513          	addi	a0,s0,-192
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	194080e7          	jalr	404(ra) # 80005196 <exec>
    8000600a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600c:	10048993          	addi	s3,s1,256
    80006010:	6088                	ld	a0,0(s1)
    80006012:	c911                	beqz	a0,80006026 <sys_exec+0xfa>
    kfree(argv[i]);
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	9e4080e7          	jalr	-1564(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000601c:	04a1                	addi	s1,s1,8
    8000601e:	ff3499e3          	bne	s1,s3,80006010 <sys_exec+0xe4>
    80006022:	a011                	j	80006026 <sys_exec+0xfa>
  return -1;
    80006024:	597d                	li	s2,-1
}
    80006026:	854a                	mv	a0,s2
    80006028:	60be                	ld	ra,456(sp)
    8000602a:	641e                	ld	s0,448(sp)
    8000602c:	74fa                	ld	s1,440(sp)
    8000602e:	795a                	ld	s2,432(sp)
    80006030:	79ba                	ld	s3,424(sp)
    80006032:	7a1a                	ld	s4,416(sp)
    80006034:	6afa                	ld	s5,408(sp)
    80006036:	6179                	addi	sp,sp,464
    80006038:	8082                	ret

000000008000603a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000603a:	7139                	addi	sp,sp,-64
    8000603c:	fc06                	sd	ra,56(sp)
    8000603e:	f822                	sd	s0,48(sp)
    80006040:	f426                	sd	s1,40(sp)
    80006042:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006044:	ffffc097          	auipc	ra,0xffffc
    80006048:	984080e7          	jalr	-1660(ra) # 800019c8 <myproc>
    8000604c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000604e:	fd840593          	addi	a1,s0,-40
    80006052:	4501                	li	a0,0
    80006054:	ffffd097          	auipc	ra,0xffffd
    80006058:	090080e7          	jalr	144(ra) # 800030e4 <argaddr>
    return -1;
    8000605c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000605e:	0e054063          	bltz	a0,8000613e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006062:	fc840593          	addi	a1,s0,-56
    80006066:	fd040513          	addi	a0,s0,-48
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	dfc080e7          	jalr	-516(ra) # 80004e66 <pipealloc>
    return -1;
    80006072:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006074:	0c054563          	bltz	a0,8000613e <sys_pipe+0x104>
  fd0 = -1;
    80006078:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000607c:	fd043503          	ld	a0,-48(s0)
    80006080:	fffff097          	auipc	ra,0xfffff
    80006084:	508080e7          	jalr	1288(ra) # 80005588 <fdalloc>
    80006088:	fca42223          	sw	a0,-60(s0)
    8000608c:	08054c63          	bltz	a0,80006124 <sys_pipe+0xea>
    80006090:	fc843503          	ld	a0,-56(s0)
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	4f4080e7          	jalr	1268(ra) # 80005588 <fdalloc>
    8000609c:	fca42023          	sw	a0,-64(s0)
    800060a0:	06054863          	bltz	a0,80006110 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060a4:	4691                	li	a3,4
    800060a6:	fc440613          	addi	a2,s0,-60
    800060aa:	fd843583          	ld	a1,-40(s0)
    800060ae:	68a8                	ld	a0,80(s1)
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	5ca080e7          	jalr	1482(ra) # 8000167a <copyout>
    800060b8:	02054063          	bltz	a0,800060d8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060bc:	4691                	li	a3,4
    800060be:	fc040613          	addi	a2,s0,-64
    800060c2:	fd843583          	ld	a1,-40(s0)
    800060c6:	0591                	addi	a1,a1,4
    800060c8:	68a8                	ld	a0,80(s1)
    800060ca:	ffffb097          	auipc	ra,0xffffb
    800060ce:	5b0080e7          	jalr	1456(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060d2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d4:	06055563          	bgez	a0,8000613e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060d8:	fc442783          	lw	a5,-60(s0)
    800060dc:	07e9                	addi	a5,a5,26
    800060de:	078e                	slli	a5,a5,0x3
    800060e0:	97a6                	add	a5,a5,s1
    800060e2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060e6:	fc042503          	lw	a0,-64(s0)
    800060ea:	0569                	addi	a0,a0,26
    800060ec:	050e                	slli	a0,a0,0x3
    800060ee:	9526                	add	a0,a0,s1
    800060f0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060f4:	fd043503          	ld	a0,-48(s0)
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	a3e080e7          	jalr	-1474(ra) # 80004b36 <fileclose>
    fileclose(wf);
    80006100:	fc843503          	ld	a0,-56(s0)
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	a32080e7          	jalr	-1486(ra) # 80004b36 <fileclose>
    return -1;
    8000610c:	57fd                	li	a5,-1
    8000610e:	a805                	j	8000613e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006110:	fc442783          	lw	a5,-60(s0)
    80006114:	0007c863          	bltz	a5,80006124 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006118:	01a78513          	addi	a0,a5,26
    8000611c:	050e                	slli	a0,a0,0x3
    8000611e:	9526                	add	a0,a0,s1
    80006120:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006124:	fd043503          	ld	a0,-48(s0)
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	a0e080e7          	jalr	-1522(ra) # 80004b36 <fileclose>
    fileclose(wf);
    80006130:	fc843503          	ld	a0,-56(s0)
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	a02080e7          	jalr	-1534(ra) # 80004b36 <fileclose>
    return -1;
    8000613c:	57fd                	li	a5,-1
}
    8000613e:	853e                	mv	a0,a5
    80006140:	70e2                	ld	ra,56(sp)
    80006142:	7442                	ld	s0,48(sp)
    80006144:	74a2                	ld	s1,40(sp)
    80006146:	6121                	addi	sp,sp,64
    80006148:	8082                	ret
    8000614a:	0000                	unimp
    8000614c:	0000                	unimp
	...

0000000080006150 <kernelvec>:
    80006150:	7111                	addi	sp,sp,-256
    80006152:	e006                	sd	ra,0(sp)
    80006154:	e40a                	sd	sp,8(sp)
    80006156:	e80e                	sd	gp,16(sp)
    80006158:	ec12                	sd	tp,24(sp)
    8000615a:	f016                	sd	t0,32(sp)
    8000615c:	f41a                	sd	t1,40(sp)
    8000615e:	f81e                	sd	t2,48(sp)
    80006160:	fc22                	sd	s0,56(sp)
    80006162:	e0a6                	sd	s1,64(sp)
    80006164:	e4aa                	sd	a0,72(sp)
    80006166:	e8ae                	sd	a1,80(sp)
    80006168:	ecb2                	sd	a2,88(sp)
    8000616a:	f0b6                	sd	a3,96(sp)
    8000616c:	f4ba                	sd	a4,104(sp)
    8000616e:	f8be                	sd	a5,112(sp)
    80006170:	fcc2                	sd	a6,120(sp)
    80006172:	e146                	sd	a7,128(sp)
    80006174:	e54a                	sd	s2,136(sp)
    80006176:	e94e                	sd	s3,144(sp)
    80006178:	ed52                	sd	s4,152(sp)
    8000617a:	f156                	sd	s5,160(sp)
    8000617c:	f55a                	sd	s6,168(sp)
    8000617e:	f95e                	sd	s7,176(sp)
    80006180:	fd62                	sd	s8,184(sp)
    80006182:	e1e6                	sd	s9,192(sp)
    80006184:	e5ea                	sd	s10,200(sp)
    80006186:	e9ee                	sd	s11,208(sp)
    80006188:	edf2                	sd	t3,216(sp)
    8000618a:	f1f6                	sd	t4,224(sp)
    8000618c:	f5fa                	sd	t5,232(sp)
    8000618e:	f9fe                	sd	t6,240(sp)
    80006190:	d65fc0ef          	jal	ra,80002ef4 <kerneltrap>
    80006194:	6082                	ld	ra,0(sp)
    80006196:	6122                	ld	sp,8(sp)
    80006198:	61c2                	ld	gp,16(sp)
    8000619a:	7282                	ld	t0,32(sp)
    8000619c:	7322                	ld	t1,40(sp)
    8000619e:	73c2                	ld	t2,48(sp)
    800061a0:	7462                	ld	s0,56(sp)
    800061a2:	6486                	ld	s1,64(sp)
    800061a4:	6526                	ld	a0,72(sp)
    800061a6:	65c6                	ld	a1,80(sp)
    800061a8:	6666                	ld	a2,88(sp)
    800061aa:	7686                	ld	a3,96(sp)
    800061ac:	7726                	ld	a4,104(sp)
    800061ae:	77c6                	ld	a5,112(sp)
    800061b0:	7866                	ld	a6,120(sp)
    800061b2:	688a                	ld	a7,128(sp)
    800061b4:	692a                	ld	s2,136(sp)
    800061b6:	69ca                	ld	s3,144(sp)
    800061b8:	6a6a                	ld	s4,152(sp)
    800061ba:	7a8a                	ld	s5,160(sp)
    800061bc:	7b2a                	ld	s6,168(sp)
    800061be:	7bca                	ld	s7,176(sp)
    800061c0:	7c6a                	ld	s8,184(sp)
    800061c2:	6c8e                	ld	s9,192(sp)
    800061c4:	6d2e                	ld	s10,200(sp)
    800061c6:	6dce                	ld	s11,208(sp)
    800061c8:	6e6e                	ld	t3,216(sp)
    800061ca:	7e8e                	ld	t4,224(sp)
    800061cc:	7f2e                	ld	t5,232(sp)
    800061ce:	7fce                	ld	t6,240(sp)
    800061d0:	6111                	addi	sp,sp,256
    800061d2:	10200073          	sret
    800061d6:	00000013          	nop
    800061da:	00000013          	nop
    800061de:	0001                	nop

00000000800061e0 <timervec>:
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	e10c                	sd	a1,0(a0)
    800061e6:	e510                	sd	a2,8(a0)
    800061e8:	e914                	sd	a3,16(a0)
    800061ea:	6d0c                	ld	a1,24(a0)
    800061ec:	7110                	ld	a2,32(a0)
    800061ee:	6194                	ld	a3,0(a1)
    800061f0:	96b2                	add	a3,a3,a2
    800061f2:	e194                	sd	a3,0(a1)
    800061f4:	4589                	li	a1,2
    800061f6:	14459073          	csrw	sip,a1
    800061fa:	6914                	ld	a3,16(a0)
    800061fc:	6510                	ld	a2,8(a0)
    800061fe:	610c                	ld	a1,0(a0)
    80006200:	34051573          	csrrw	a0,mscratch,a0
    80006204:	30200073          	mret
	...

000000008000620a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000620a:	1141                	addi	sp,sp,-16
    8000620c:	e422                	sd	s0,8(sp)
    8000620e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006210:	0c0007b7          	lui	a5,0xc000
    80006214:	4705                	li	a4,1
    80006216:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006218:	c3d8                	sw	a4,4(a5)
}
    8000621a:	6422                	ld	s0,8(sp)
    8000621c:	0141                	addi	sp,sp,16
    8000621e:	8082                	ret

0000000080006220 <plicinithart>:

void
plicinithart(void)
{
    80006220:	1141                	addi	sp,sp,-16
    80006222:	e406                	sd	ra,8(sp)
    80006224:	e022                	sd	s0,0(sp)
    80006226:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	774080e7          	jalr	1908(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006230:	0085171b          	slliw	a4,a0,0x8
    80006234:	0c0027b7          	lui	a5,0xc002
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	40200713          	li	a4,1026
    8000623e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006242:	00d5151b          	slliw	a0,a0,0xd
    80006246:	0c2017b7          	lui	a5,0xc201
    8000624a:	953e                	add	a0,a0,a5
    8000624c:	00052023          	sw	zero,0(a0)
}
    80006250:	60a2                	ld	ra,8(sp)
    80006252:	6402                	ld	s0,0(sp)
    80006254:	0141                	addi	sp,sp,16
    80006256:	8082                	ret

0000000080006258 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006258:	1141                	addi	sp,sp,-16
    8000625a:	e406                	sd	ra,8(sp)
    8000625c:	e022                	sd	s0,0(sp)
    8000625e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	73c080e7          	jalr	1852(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006268:	00d5179b          	slliw	a5,a0,0xd
    8000626c:	0c201537          	lui	a0,0xc201
    80006270:	953e                	add	a0,a0,a5
  return irq;
}
    80006272:	4148                	lw	a0,4(a0)
    80006274:	60a2                	ld	ra,8(sp)
    80006276:	6402                	ld	s0,0(sp)
    80006278:	0141                	addi	sp,sp,16
    8000627a:	8082                	ret

000000008000627c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000627c:	1101                	addi	sp,sp,-32
    8000627e:	ec06                	sd	ra,24(sp)
    80006280:	e822                	sd	s0,16(sp)
    80006282:	e426                	sd	s1,8(sp)
    80006284:	1000                	addi	s0,sp,32
    80006286:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006288:	ffffb097          	auipc	ra,0xffffb
    8000628c:	714080e7          	jalr	1812(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006290:	00d5151b          	slliw	a0,a0,0xd
    80006294:	0c2017b7          	lui	a5,0xc201
    80006298:	97aa                	add	a5,a5,a0
    8000629a:	c3c4                	sw	s1,4(a5)
}
    8000629c:	60e2                	ld	ra,24(sp)
    8000629e:	6442                	ld	s0,16(sp)
    800062a0:	64a2                	ld	s1,8(sp)
    800062a2:	6105                	addi	sp,sp,32
    800062a4:	8082                	ret

00000000800062a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062a6:	1141                	addi	sp,sp,-16
    800062a8:	e406                	sd	ra,8(sp)
    800062aa:	e022                	sd	s0,0(sp)
    800062ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062ae:	479d                	li	a5,7
    800062b0:	06a7c963          	blt	a5,a0,80006322 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062b4:	00016797          	auipc	a5,0x16
    800062b8:	d4c78793          	addi	a5,a5,-692 # 8001c000 <disk>
    800062bc:	00a78733          	add	a4,a5,a0
    800062c0:	6789                	lui	a5,0x2
    800062c2:	97ba                	add	a5,a5,a4
    800062c4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062c8:	e7ad                	bnez	a5,80006332 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ca:	00451793          	slli	a5,a0,0x4
    800062ce:	00018717          	auipc	a4,0x18
    800062d2:	d3270713          	addi	a4,a4,-718 # 8001e000 <disk+0x2000>
    800062d6:	6314                	ld	a3,0(a4)
    800062d8:	96be                	add	a3,a3,a5
    800062da:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062de:	6314                	ld	a3,0(a4)
    800062e0:	96be                	add	a3,a3,a5
    800062e2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062e6:	6314                	ld	a3,0(a4)
    800062e8:	96be                	add	a3,a3,a5
    800062ea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062ee:	6318                	ld	a4,0(a4)
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062f6:	00016797          	auipc	a5,0x16
    800062fa:	d0a78793          	addi	a5,a5,-758 # 8001c000 <disk>
    800062fe:	97aa                	add	a5,a5,a0
    80006300:	6509                	lui	a0,0x2
    80006302:	953e                	add	a0,a0,a5
    80006304:	4785                	li	a5,1
    80006306:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000630a:	00018517          	auipc	a0,0x18
    8000630e:	d0e50513          	addi	a0,a0,-754 # 8001e018 <disk+0x2018>
    80006312:	ffffc097          	auipc	ra,0xffffc
    80006316:	2ba080e7          	jalr	698(ra) # 800025cc <wakeup>
}
    8000631a:	60a2                	ld	ra,8(sp)
    8000631c:	6402                	ld	s0,0(sp)
    8000631e:	0141                	addi	sp,sp,16
    80006320:	8082                	ret
    panic("free_desc 1");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	52e50513          	addi	a0,a0,1326 # 80008850 <syscalls+0x338>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	214080e7          	jalr	532(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	52e50513          	addi	a0,a0,1326 # 80008860 <syscalls+0x348>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	204080e7          	jalr	516(ra) # 8000053e <panic>

0000000080006342 <virtio_disk_init>:
{
    80006342:	1101                	addi	sp,sp,-32
    80006344:	ec06                	sd	ra,24(sp)
    80006346:	e822                	sd	s0,16(sp)
    80006348:	e426                	sd	s1,8(sp)
    8000634a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000634c:	00002597          	auipc	a1,0x2
    80006350:	52458593          	addi	a1,a1,1316 # 80008870 <syscalls+0x358>
    80006354:	00018517          	auipc	a0,0x18
    80006358:	dd450513          	addi	a0,a0,-556 # 8001e128 <disk+0x2128>
    8000635c:	ffffa097          	auipc	ra,0xffffa
    80006360:	7f8080e7          	jalr	2040(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006364:	100017b7          	lui	a5,0x10001
    80006368:	4398                	lw	a4,0(a5)
    8000636a:	2701                	sext.w	a4,a4
    8000636c:	747277b7          	lui	a5,0x74727
    80006370:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006374:	0ef71163          	bne	a4,a5,80006456 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	43dc                	lw	a5,4(a5)
    8000637e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006380:	4705                	li	a4,1
    80006382:	0ce79a63          	bne	a5,a4,80006456 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006386:	100017b7          	lui	a5,0x10001
    8000638a:	479c                	lw	a5,8(a5)
    8000638c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000638e:	4709                	li	a4,2
    80006390:	0ce79363          	bne	a5,a4,80006456 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006394:	100017b7          	lui	a5,0x10001
    80006398:	47d8                	lw	a4,12(a5)
    8000639a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000639c:	554d47b7          	lui	a5,0x554d4
    800063a0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063a4:	0af71963          	bne	a4,a5,80006456 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a8:	100017b7          	lui	a5,0x10001
    800063ac:	4705                	li	a4,1
    800063ae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b0:	470d                	li	a4,3
    800063b2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063b4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063b6:	c7ffe737          	lui	a4,0xc7ffe
    800063ba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    800063be:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063c0:	2701                	sext.w	a4,a4
    800063c2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c4:	472d                	li	a4,11
    800063c6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c8:	473d                	li	a4,15
    800063ca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063cc:	6705                	lui	a4,0x1
    800063ce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063d4:	5bdc                	lw	a5,52(a5)
    800063d6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063d8:	c7d9                	beqz	a5,80006466 <virtio_disk_init+0x124>
  if(max < NUM)
    800063da:	471d                	li	a4,7
    800063dc:	08f77d63          	bgeu	a4,a5,80006476 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063e0:	100014b7          	lui	s1,0x10001
    800063e4:	47a1                	li	a5,8
    800063e6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063e8:	6609                	lui	a2,0x2
    800063ea:	4581                	li	a1,0
    800063ec:	00016517          	auipc	a0,0x16
    800063f0:	c1450513          	addi	a0,a0,-1004 # 8001c000 <disk>
    800063f4:	ffffb097          	auipc	ra,0xffffb
    800063f8:	8ec080e7          	jalr	-1812(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063fc:	00016717          	auipc	a4,0x16
    80006400:	c0470713          	addi	a4,a4,-1020 # 8001c000 <disk>
    80006404:	00c75793          	srli	a5,a4,0xc
    80006408:	2781                	sext.w	a5,a5
    8000640a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000640c:	00018797          	auipc	a5,0x18
    80006410:	bf478793          	addi	a5,a5,-1036 # 8001e000 <disk+0x2000>
    80006414:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006416:	00016717          	auipc	a4,0x16
    8000641a:	c6a70713          	addi	a4,a4,-918 # 8001c080 <disk+0x80>
    8000641e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006420:	00017717          	auipc	a4,0x17
    80006424:	be070713          	addi	a4,a4,-1056 # 8001d000 <disk+0x1000>
    80006428:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000642a:	4705                	li	a4,1
    8000642c:	00e78c23          	sb	a4,24(a5)
    80006430:	00e78ca3          	sb	a4,25(a5)
    80006434:	00e78d23          	sb	a4,26(a5)
    80006438:	00e78da3          	sb	a4,27(a5)
    8000643c:	00e78e23          	sb	a4,28(a5)
    80006440:	00e78ea3          	sb	a4,29(a5)
    80006444:	00e78f23          	sb	a4,30(a5)
    80006448:	00e78fa3          	sb	a4,31(a5)
}
    8000644c:	60e2                	ld	ra,24(sp)
    8000644e:	6442                	ld	s0,16(sp)
    80006450:	64a2                	ld	s1,8(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret
    panic("could not find virtio disk");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	42a50513          	addi	a0,a0,1066 # 80008880 <syscalls+0x368>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	43a50513          	addi	a0,a0,1082 # 800088a0 <syscalls+0x388>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006476:	00002517          	auipc	a0,0x2
    8000647a:	44a50513          	addi	a0,a0,1098 # 800088c0 <syscalls+0x3a8>
    8000647e:	ffffa097          	auipc	ra,0xffffa
    80006482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>

0000000080006486 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006486:	7159                	addi	sp,sp,-112
    80006488:	f486                	sd	ra,104(sp)
    8000648a:	f0a2                	sd	s0,96(sp)
    8000648c:	eca6                	sd	s1,88(sp)
    8000648e:	e8ca                	sd	s2,80(sp)
    80006490:	e4ce                	sd	s3,72(sp)
    80006492:	e0d2                	sd	s4,64(sp)
    80006494:	fc56                	sd	s5,56(sp)
    80006496:	f85a                	sd	s6,48(sp)
    80006498:	f45e                	sd	s7,40(sp)
    8000649a:	f062                	sd	s8,32(sp)
    8000649c:	ec66                	sd	s9,24(sp)
    8000649e:	e86a                	sd	s10,16(sp)
    800064a0:	1880                	addi	s0,sp,112
    800064a2:	892a                	mv	s2,a0
    800064a4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064a6:	00c52c83          	lw	s9,12(a0)
    800064aa:	001c9c9b          	slliw	s9,s9,0x1
    800064ae:	1c82                	slli	s9,s9,0x20
    800064b0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064b4:	00018517          	auipc	a0,0x18
    800064b8:	c7450513          	addi	a0,a0,-908 # 8001e128 <disk+0x2128>
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	728080e7          	jalr	1832(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064c6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064c8:	00016b97          	auipc	s7,0x16
    800064cc:	b38b8b93          	addi	s7,s7,-1224 # 8001c000 <disk>
    800064d0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064d4:	8a4e                	mv	s4,s3
    800064d6:	a051                	j	8000655a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064d8:	00fb86b3          	add	a3,s7,a5
    800064dc:	96da                	add	a3,a3,s6
    800064de:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064e2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064e4:	0207c563          	bltz	a5,8000650e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064e8:	2485                	addiw	s1,s1,1
    800064ea:	0711                	addi	a4,a4,4
    800064ec:	25548063          	beq	s1,s5,8000672c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064f0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064f2:	00018697          	auipc	a3,0x18
    800064f6:	b2668693          	addi	a3,a3,-1242 # 8001e018 <disk+0x2018>
    800064fa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064fc:	0006c583          	lbu	a1,0(a3)
    80006500:	fde1                	bnez	a1,800064d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006502:	2785                	addiw	a5,a5,1
    80006504:	0685                	addi	a3,a3,1
    80006506:	ff879be3          	bne	a5,s8,800064fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000650a:	57fd                	li	a5,-1
    8000650c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000650e:	02905a63          	blez	s1,80006542 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006512:	f9042503          	lw	a0,-112(s0)
    80006516:	00000097          	auipc	ra,0x0
    8000651a:	d90080e7          	jalr	-624(ra) # 800062a6 <free_desc>
      for(int j = 0; j < i; j++)
    8000651e:	4785                	li	a5,1
    80006520:	0297d163          	bge	a5,s1,80006542 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006524:	f9442503          	lw	a0,-108(s0)
    80006528:	00000097          	auipc	ra,0x0
    8000652c:	d7e080e7          	jalr	-642(ra) # 800062a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006530:	4789                	li	a5,2
    80006532:	0097d863          	bge	a5,s1,80006542 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006536:	f9842503          	lw	a0,-104(s0)
    8000653a:	00000097          	auipc	ra,0x0
    8000653e:	d6c080e7          	jalr	-660(ra) # 800062a6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006542:	00018597          	auipc	a1,0x18
    80006546:	be658593          	addi	a1,a1,-1050 # 8001e128 <disk+0x2128>
    8000654a:	00018517          	auipc	a0,0x18
    8000654e:	ace50513          	addi	a0,a0,-1330 # 8001e018 <disk+0x2018>
    80006552:	ffffc097          	auipc	ra,0xffffc
    80006556:	eaa080e7          	jalr	-342(ra) # 800023fc <sleep>
  for(int i = 0; i < 3; i++){
    8000655a:	f9040713          	addi	a4,s0,-112
    8000655e:	84ce                	mv	s1,s3
    80006560:	bf41                	j	800064f0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006562:	20058713          	addi	a4,a1,512
    80006566:	00471693          	slli	a3,a4,0x4
    8000656a:	00016717          	auipc	a4,0x16
    8000656e:	a9670713          	addi	a4,a4,-1386 # 8001c000 <disk>
    80006572:	9736                	add	a4,a4,a3
    80006574:	4685                	li	a3,1
    80006576:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000657a:	20058713          	addi	a4,a1,512
    8000657e:	00471693          	slli	a3,a4,0x4
    80006582:	00016717          	auipc	a4,0x16
    80006586:	a7e70713          	addi	a4,a4,-1410 # 8001c000 <disk>
    8000658a:	9736                	add	a4,a4,a3
    8000658c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006590:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006594:	7679                	lui	a2,0xffffe
    80006596:	963e                	add	a2,a2,a5
    80006598:	00018697          	auipc	a3,0x18
    8000659c:	a6868693          	addi	a3,a3,-1432 # 8001e000 <disk+0x2000>
    800065a0:	6298                	ld	a4,0(a3)
    800065a2:	9732                	add	a4,a4,a2
    800065a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065a6:	6298                	ld	a4,0(a3)
    800065a8:	9732                	add	a4,a4,a2
    800065aa:	4541                	li	a0,16
    800065ac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065ae:	6298                	ld	a4,0(a3)
    800065b0:	9732                	add	a4,a4,a2
    800065b2:	4505                	li	a0,1
    800065b4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065b8:	f9442703          	lw	a4,-108(s0)
    800065bc:	6288                	ld	a0,0(a3)
    800065be:	962a                	add	a2,a2,a0
    800065c0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065c4:	0712                	slli	a4,a4,0x4
    800065c6:	6290                	ld	a2,0(a3)
    800065c8:	963a                	add	a2,a2,a4
    800065ca:	05890513          	addi	a0,s2,88
    800065ce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065d0:	6294                	ld	a3,0(a3)
    800065d2:	96ba                	add	a3,a3,a4
    800065d4:	40000613          	li	a2,1024
    800065d8:	c690                	sw	a2,8(a3)
  if(write)
    800065da:	140d0063          	beqz	s10,8000671a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065de:	00018697          	auipc	a3,0x18
    800065e2:	a226b683          	ld	a3,-1502(a3) # 8001e000 <disk+0x2000>
    800065e6:	96ba                	add	a3,a3,a4
    800065e8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065ec:	00016817          	auipc	a6,0x16
    800065f0:	a1480813          	addi	a6,a6,-1516 # 8001c000 <disk>
    800065f4:	00018517          	auipc	a0,0x18
    800065f8:	a0c50513          	addi	a0,a0,-1524 # 8001e000 <disk+0x2000>
    800065fc:	6114                	ld	a3,0(a0)
    800065fe:	96ba                	add	a3,a3,a4
    80006600:	00c6d603          	lhu	a2,12(a3)
    80006604:	00166613          	ori	a2,a2,1
    80006608:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000660c:	f9842683          	lw	a3,-104(s0)
    80006610:	6110                	ld	a2,0(a0)
    80006612:	9732                	add	a4,a4,a2
    80006614:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006618:	20058613          	addi	a2,a1,512
    8000661c:	0612                	slli	a2,a2,0x4
    8000661e:	9642                	add	a2,a2,a6
    80006620:	577d                	li	a4,-1
    80006622:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006626:	00469713          	slli	a4,a3,0x4
    8000662a:	6114                	ld	a3,0(a0)
    8000662c:	96ba                	add	a3,a3,a4
    8000662e:	03078793          	addi	a5,a5,48
    80006632:	97c2                	add	a5,a5,a6
    80006634:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006636:	611c                	ld	a5,0(a0)
    80006638:	97ba                	add	a5,a5,a4
    8000663a:	4685                	li	a3,1
    8000663c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000663e:	611c                	ld	a5,0(a0)
    80006640:	97ba                	add	a5,a5,a4
    80006642:	4809                	li	a6,2
    80006644:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006648:	611c                	ld	a5,0(a0)
    8000664a:	973e                	add	a4,a4,a5
    8000664c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006650:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006654:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006658:	6518                	ld	a4,8(a0)
    8000665a:	00275783          	lhu	a5,2(a4)
    8000665e:	8b9d                	andi	a5,a5,7
    80006660:	0786                	slli	a5,a5,0x1
    80006662:	97ba                	add	a5,a5,a4
    80006664:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006668:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000666c:	6518                	ld	a4,8(a0)
    8000666e:	00275783          	lhu	a5,2(a4)
    80006672:	2785                	addiw	a5,a5,1
    80006674:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006678:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000667c:	100017b7          	lui	a5,0x10001
    80006680:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006684:	00492703          	lw	a4,4(s2)
    80006688:	4785                	li	a5,1
    8000668a:	02f71163          	bne	a4,a5,800066ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000668e:	00018997          	auipc	s3,0x18
    80006692:	a9a98993          	addi	s3,s3,-1382 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    80006696:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006698:	85ce                	mv	a1,s3
    8000669a:	854a                	mv	a0,s2
    8000669c:	ffffc097          	auipc	ra,0xffffc
    800066a0:	d60080e7          	jalr	-672(ra) # 800023fc <sleep>
  while(b->disk == 1) {
    800066a4:	00492783          	lw	a5,4(s2)
    800066a8:	fe9788e3          	beq	a5,s1,80006698 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800066ac:	f9042903          	lw	s2,-112(s0)
    800066b0:	20090793          	addi	a5,s2,512
    800066b4:	00479713          	slli	a4,a5,0x4
    800066b8:	00016797          	auipc	a5,0x16
    800066bc:	94878793          	addi	a5,a5,-1720 # 8001c000 <disk>
    800066c0:	97ba                	add	a5,a5,a4
    800066c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066c6:	00018997          	auipc	s3,0x18
    800066ca:	93a98993          	addi	s3,s3,-1734 # 8001e000 <disk+0x2000>
    800066ce:	00491713          	slli	a4,s2,0x4
    800066d2:	0009b783          	ld	a5,0(s3)
    800066d6:	97ba                	add	a5,a5,a4
    800066d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066dc:	854a                	mv	a0,s2
    800066de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066e2:	00000097          	auipc	ra,0x0
    800066e6:	bc4080e7          	jalr	-1084(ra) # 800062a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066ea:	8885                	andi	s1,s1,1
    800066ec:	f0ed                	bnez	s1,800066ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066ee:	00018517          	auipc	a0,0x18
    800066f2:	a3a50513          	addi	a0,a0,-1478 # 8001e128 <disk+0x2128>
    800066f6:	ffffa097          	auipc	ra,0xffffa
    800066fa:	5a2080e7          	jalr	1442(ra) # 80000c98 <release>
}
    800066fe:	70a6                	ld	ra,104(sp)
    80006700:	7406                	ld	s0,96(sp)
    80006702:	64e6                	ld	s1,88(sp)
    80006704:	6946                	ld	s2,80(sp)
    80006706:	69a6                	ld	s3,72(sp)
    80006708:	6a06                	ld	s4,64(sp)
    8000670a:	7ae2                	ld	s5,56(sp)
    8000670c:	7b42                	ld	s6,48(sp)
    8000670e:	7ba2                	ld	s7,40(sp)
    80006710:	7c02                	ld	s8,32(sp)
    80006712:	6ce2                	ld	s9,24(sp)
    80006714:	6d42                	ld	s10,16(sp)
    80006716:	6165                	addi	sp,sp,112
    80006718:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000671a:	00018697          	auipc	a3,0x18
    8000671e:	8e66b683          	ld	a3,-1818(a3) # 8001e000 <disk+0x2000>
    80006722:	96ba                	add	a3,a3,a4
    80006724:	4609                	li	a2,2
    80006726:	00c69623          	sh	a2,12(a3)
    8000672a:	b5c9                	j	800065ec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000672c:	f9042583          	lw	a1,-112(s0)
    80006730:	20058793          	addi	a5,a1,512
    80006734:	0792                	slli	a5,a5,0x4
    80006736:	00016517          	auipc	a0,0x16
    8000673a:	97250513          	addi	a0,a0,-1678 # 8001c0a8 <disk+0xa8>
    8000673e:	953e                	add	a0,a0,a5
  if(write)
    80006740:	e20d11e3          	bnez	s10,80006562 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006744:	20058713          	addi	a4,a1,512
    80006748:	00471693          	slli	a3,a4,0x4
    8000674c:	00016717          	auipc	a4,0x16
    80006750:	8b470713          	addi	a4,a4,-1868 # 8001c000 <disk>
    80006754:	9736                	add	a4,a4,a3
    80006756:	0a072423          	sw	zero,168(a4)
    8000675a:	b505                	j	8000657a <virtio_disk_rw+0xf4>

000000008000675c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000675c:	1101                	addi	sp,sp,-32
    8000675e:	ec06                	sd	ra,24(sp)
    80006760:	e822                	sd	s0,16(sp)
    80006762:	e426                	sd	s1,8(sp)
    80006764:	e04a                	sd	s2,0(sp)
    80006766:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006768:	00018517          	auipc	a0,0x18
    8000676c:	9c050513          	addi	a0,a0,-1600 # 8001e128 <disk+0x2128>
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	474080e7          	jalr	1140(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006778:	10001737          	lui	a4,0x10001
    8000677c:	533c                	lw	a5,96(a4)
    8000677e:	8b8d                	andi	a5,a5,3
    80006780:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006782:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006786:	00018797          	auipc	a5,0x18
    8000678a:	87a78793          	addi	a5,a5,-1926 # 8001e000 <disk+0x2000>
    8000678e:	6b94                	ld	a3,16(a5)
    80006790:	0207d703          	lhu	a4,32(a5)
    80006794:	0026d783          	lhu	a5,2(a3)
    80006798:	06f70163          	beq	a4,a5,800067fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000679c:	00016917          	auipc	s2,0x16
    800067a0:	86490913          	addi	s2,s2,-1948 # 8001c000 <disk>
    800067a4:	00018497          	auipc	s1,0x18
    800067a8:	85c48493          	addi	s1,s1,-1956 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800067ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067b0:	6898                	ld	a4,16(s1)
    800067b2:	0204d783          	lhu	a5,32(s1)
    800067b6:	8b9d                	andi	a5,a5,7
    800067b8:	078e                	slli	a5,a5,0x3
    800067ba:	97ba                	add	a5,a5,a4
    800067bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067be:	20078713          	addi	a4,a5,512
    800067c2:	0712                	slli	a4,a4,0x4
    800067c4:	974a                	add	a4,a4,s2
    800067c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ca:	e731                	bnez	a4,80006816 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067cc:	20078793          	addi	a5,a5,512
    800067d0:	0792                	slli	a5,a5,0x4
    800067d2:	97ca                	add	a5,a5,s2
    800067d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067da:	ffffc097          	auipc	ra,0xffffc
    800067de:	df2080e7          	jalr	-526(ra) # 800025cc <wakeup>

    disk.used_idx += 1;
    800067e2:	0204d783          	lhu	a5,32(s1)
    800067e6:	2785                	addiw	a5,a5,1
    800067e8:	17c2                	slli	a5,a5,0x30
    800067ea:	93c1                	srli	a5,a5,0x30
    800067ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067f0:	6898                	ld	a4,16(s1)
    800067f2:	00275703          	lhu	a4,2(a4)
    800067f6:	faf71be3          	bne	a4,a5,800067ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067fa:	00018517          	auipc	a0,0x18
    800067fe:	92e50513          	addi	a0,a0,-1746 # 8001e128 <disk+0x2128>
    80006802:	ffffa097          	auipc	ra,0xffffa
    80006806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
}
    8000680a:	60e2                	ld	ra,24(sp)
    8000680c:	6442                	ld	s0,16(sp)
    8000680e:	64a2                	ld	s1,8(sp)
    80006810:	6902                	ld	s2,0(sp)
    80006812:	6105                	addi	sp,sp,32
    80006814:	8082                	ret
      panic("virtio_disk_intr status");
    80006816:	00002517          	auipc	a0,0x2
    8000681a:	0ca50513          	addi	a0,a0,202 # 800088e0 <syscalls+0x3c8>
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>
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
