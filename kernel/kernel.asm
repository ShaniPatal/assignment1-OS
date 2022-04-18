
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	c1c78793          	addi	a5,a5,-996 # 80005c80 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffe07ff>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	428080e7          	jalr	1064(ra) # 80002554 <either_copyin>
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
    80000190:	ee450513          	addi	a0,a0,-284 # 8000a070 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ed448493          	addi	s1,s1,-300 # 8000a070 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f6290913          	addi	s2,s2,-158 # 8000a108 <cons+0x98>
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
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	eda080e7          	jalr	-294(ra) # 800020ae <sleep>
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
    80000214:	2ee080e7          	jalr	750(ra) # 800024fe <either_copyout>
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
    80000228:	e4c50513          	addi	a0,a0,-436 # 8000a070 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e3650513          	addi	a0,a0,-458 # 8000a070 <cons>
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
    80000276:	e8f72b23          	sw	a5,-362(a4) # 8000a108 <cons+0x98>
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
    800002d0:	da450513          	addi	a0,a0,-604 # 8000a070 <cons>
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
    800002f6:	2b8080e7          	jalr	696(ra) # 800025aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d7650513          	addi	a0,a0,-650 # 8000a070 <cons>
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
    80000322:	d5270713          	addi	a4,a4,-686 # 8000a070 <cons>
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
    8000034c:	d2878793          	addi	a5,a5,-728 # 8000a070 <cons>
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
    8000037a:	d927a783          	lw	a5,-622(a5) # 8000a108 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	ce670713          	addi	a4,a4,-794 # 8000a070 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cd648493          	addi	s1,s1,-810 # 8000a070 <cons>
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
    800003da:	c9a70713          	addi	a4,a4,-870 # 8000a070 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d2f72223          	sw	a5,-732(a4) # 8000a110 <cons+0xa0>
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
    80000416:	c5e78793          	addi	a5,a5,-930 # 8000a070 <cons>
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
    8000043a:	ccc7ab23          	sw	a2,-810(a5) # 8000a10c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cca50513          	addi	a0,a0,-822 # 8000a108 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	df4080e7          	jalr	-524(ra) # 8000223a <wakeup>
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
    80000464:	c1050513          	addi	a0,a0,-1008 # 8000a070 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	a1078793          	addi	a5,a5,-1520 # 80019e88 <devsw>
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
    8000054e:	be07a323          	sw	zero,-1050(a5) # 8000a130 <pr+0x18>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800005be:	b76dad83          	lw	s11,-1162(s11) # 8000a130 <pr+0x18>
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
    800005fc:	b2050513          	addi	a0,a0,-1248 # 8000a118 <pr>
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
    80000760:	9bc50513          	addi	a0,a0,-1604 # 8000a118 <pr>
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
    8000077c:	9a048493          	addi	s1,s1,-1632 # 8000a118 <pr>
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
    800007dc:	96050513          	addi	a0,a0,-1696 # 8000a138 <uart_tx_lock>
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
    8000086e:	8cea0a13          	addi	s4,s4,-1842 # 8000a138 <uart_tx_lock>
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
    800008a4:	99a080e7          	jalr	-1638(ra) # 8000223a <wakeup>
    
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
    800008e0:	85c50513          	addi	a0,a0,-1956 # 8000a138 <uart_tx_lock>
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
    80000914:	828a0a13          	addi	s4,s4,-2008 # 8000a138 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	782080e7          	jalr	1922(ra) # 800020ae <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00009497          	auipc	s1,0x9
    80000946:	7f648493          	addi	s1,s1,2038 # 8000a138 <uart_tx_lock>
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
    800009ce:	76e48493          	addi	s1,s1,1902 # 8000a138 <uart_tx_lock>
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
    80000a0c:	0001d797          	auipc	a5,0x1d
    80000a10:	5f478793          	addi	a5,a5,1524 # 8001e000 <end>
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
    80000a30:	74490913          	addi	s2,s2,1860 # 8000a170 <kmem>
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
    80000acc:	6a850513          	addi	a0,a0,1704 # 8000a170 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001d517          	auipc	a0,0x1d
    80000ae0:	52450513          	addi	a0,a0,1316 # 8001e000 <end>
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
    80000b02:	67248493          	addi	s1,s1,1650 # 8000a170 <kmem>
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
    80000b1a:	65a50513          	addi	a0,a0,1626 # 8000a170 <kmem>
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
    80000b46:	62e50513          	addi	a0,a0,1582 # 8000a170 <kmem>
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
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
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
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
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
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
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
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
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
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
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
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	84c080e7          	jalr	-1972(ra) # 80002720 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	de4080e7          	jalr	-540(ra) # 80005cc0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fd6080e7          	jalr	-42(ra) # 80001eba <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7ac080e7          	jalr	1964(ra) # 800026f8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	7cc080e7          	jalr	1996(ra) # 80002720 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d4e080e7          	jalr	-690(ra) # 80005caa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d5c080e7          	jalr	-676(ra) # 80005cc0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f40080e7          	jalr	-192(ra) # 80002eac <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	5d0080e7          	jalr	1488(ra) # 80003544 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	57a080e7          	jalr	1402(ra) # 800044f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e5e080e7          	jalr	-418(ra) # 80005de2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00009497          	auipc	s1,0x9
    80001858:	9ec48493          	addi	s1,s1,-1556 # 8000a240 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	0000ea17          	auipc	s4,0xe
    80001872:	3d2a0a13          	addi	s4,s4,978 # 8000fc40 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00009517          	auipc	a0,0x9
    800018f4:	8a050513          	addi	a0,a0,-1888 # 8000a190 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00009517          	auipc	a0,0x9
    8000190c:	8a050513          	addi	a0,a0,-1888 # 8000a1a8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00009497          	auipc	s1,0x9
    8000191c:	92848493          	addi	s1,s1,-1752 # 8000a240 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	0000e997          	auipc	s3,0xe
    8000193e:	30698993          	addi	s3,s3,774 # 8000fc40 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00009517          	auipc	a0,0x9
    800019a4:	82050513          	addi	a0,a0,-2016 # 8000a1c0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00008717          	auipc	a4,0x8
    800019cc:	7c870713          	addi	a4,a4,1992 # 8000a190 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e207a783          	lw	a5,-480(a5) # 80008820 <first.1680>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d2e080e7          	jalr	-722(ra) # 80002738 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e007a323          	sw	zero,-506(a5) # 80008820 <first.1680>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	aa0080e7          	jalr	-1376(ra) # 800034c4 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00008917          	auipc	s2,0x8
    80001a3e:	75690913          	addi	s2,s2,1878 # 8000a190 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	dd878793          	addi	a5,a5,-552 # 80008824 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00008497          	auipc	s1,0x8
    80001bca:	67a48493          	addi	s1,s1,1658 # 8000a240 <proc>
    80001bce:	0000e917          	auipc	s2,0xe
    80001bd2:	07290913          	addi	s2,s2,114 # 8000fc40 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7ba23          	sd	a0,916(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	b8858593          	addi	a1,a1,-1144 # 80008830 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	20c080e7          	jalr	524(ra) # 80003ef2 <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050b63          	beqz	a0,80001eb6 <fork+0x138>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054663          	bltz	a0,80001e04 <fork+0x86>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0589b703          	ld	a4,88(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df2:	0589b783          	ld	a5,88(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000a13          	li	s4,336
    80001e02:	a03d                	j	80001e30 <fork+0xb2>
    freeproc(np);
    80001e04:	854e                	mv	a0,s3
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d5c080e7          	jalr	-676(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e88080e7          	jalr	-376(ra) # 80000c98 <release>
    return -1;
    80001e18:	5a7d                	li	s4,-1
    80001e1a:	a069                	j	80001ea4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	76c080e7          	jalr	1900(ra) # 80004588 <filedup>
    80001e24:	009987b3          	add	a5,s3,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01448763          	beq	s1,s4,80001e3a <fork+0xbc>
    if(p->ofile[i])
    80001e30:	009907b3          	add	a5,s2,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0x9e>
    80001e38:	bfcd                	j	80001e2a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e3a:	15093503          	ld	a0,336(s2)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	8c0080e7          	jalr	-1856(ra) # 800036fe <idup>
    80001e46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	15890593          	addi	a1,s2,344
    80001e50:	15898513          	addi	a0,s3,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fde080e7          	jalr	-34(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e6a:	00008497          	auipc	s1,0x8
    80001e6e:	33e48493          	addi	s1,s1,830 # 8000a1a8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e7c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	70a2                	ld	ra,40(sp)
    80001ea8:	7402                	ld	s0,32(sp)
    80001eaa:	64e2                	ld	s1,24(sp)
    80001eac:	6942                	ld	s2,16(sp)
    80001eae:	69a2                	ld	s3,8(sp)
    80001eb0:	6a02                	ld	s4,0(sp)
    80001eb2:	6145                	addi	sp,sp,48
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	5a7d                	li	s4,-1
    80001eb8:	b7f5                	j	80001ea4 <fork+0x126>

0000000080001eba <scheduler>:
{
    80001eba:	711d                	addi	sp,sp,-96
    80001ebc:	ec86                	sd	ra,88(sp)
    80001ebe:	e8a2                	sd	s0,80(sp)
    80001ec0:	e4a6                	sd	s1,72(sp)
    80001ec2:	e0ca                	sd	s2,64(sp)
    80001ec4:	fc4e                	sd	s3,56(sp)
    80001ec6:	f852                	sd	s4,48(sp)
    80001ec8:	f456                	sd	s5,40(sp)
    80001eca:	f05a                	sd	s6,32(sp)
    80001ecc:	ec5e                	sd	s7,24(sp)
    80001ece:	e862                	sd	s8,16(sp)
    80001ed0:	e466                	sd	s9,8(sp)
    80001ed2:	1080                	addi	s0,sp,96
    80001ed4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed8:	00779c13          	slli	s8,a5,0x7
    80001edc:	00008717          	auipc	a4,0x8
    80001ee0:	2b470713          	addi	a4,a4,692 # 8000a190 <pid_lock>
    80001ee4:	9762                	add	a4,a4,s8
    80001ee6:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001eea:	00008717          	auipc	a4,0x8
    80001eee:	2de70713          	addi	a4,a4,734 # 8000a1c8 <cpus+0x8>
    80001ef2:	9c3a                	add	s8,s8,a4
          c->proc = p;
    80001ef4:	079e                	slli	a5,a5,0x7
    80001ef6:	00008a97          	auipc	s5,0x8
    80001efa:	29aa8a93          	addi	s5,s5,666 # 8000a190 <pid_lock>
    80001efe:	9abe                	add	s5,s5,a5
          while(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f00:	00007b17          	auipc	s6,0x7
    80001f04:	128b0b13          	addi	s6,s6,296 # 80009028 <pause_time>
            if(ticks*10 >= pause_time){
    80001f08:	00007c97          	auipc	s9,0x7
    80001f0c:	130c8c93          	addi	s9,s9,304 # 80009038 <ticks>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f14:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f18:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f1c:	00008497          	auipc	s1,0x8
    80001f20:	32448493          	addi	s1,s1,804 # 8000a240 <proc>
        if(p->state == RUNNABLE) {
    80001f24:	4a0d                	li	s4,3
          p->state = RUNNING;
    80001f26:	4b91                	li	s7,4
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f28:	0000e997          	auipc	s3,0xe
    80001f2c:	d1898993          	addi	s3,s3,-744 # 8000fc40 <tickslock>
    80001f30:	a01d                	j	80001f56 <scheduler+0x9c>
          swtch(&c->context, &p->context);
    80001f32:	06090593          	addi	a1,s2,96
    80001f36:	8562                	mv	a0,s8
    80001f38:	00000097          	auipc	ra,0x0
    80001f3c:	756080e7          	jalr	1878(ra) # 8000268e <swtch>
          c->proc = 0;
    80001f40:	020ab823          	sd	zero,48(s5)
        release(&p->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d52080e7          	jalr	-686(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4e:	16848493          	addi	s1,s1,360
    80001f52:	fb348fe3          	beq	s1,s3,80001f10 <scheduler+0x56>
        acquire(&p->lock);
    80001f56:	8926                	mv	s2,s1
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c8a080e7          	jalr	-886(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f62:	4c9c                	lw	a5,24(s1)
    80001f64:	ff4790e3          	bne	a5,s4,80001f44 <scheduler+0x8a>
          p->state = RUNNING;
    80001f68:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80001f6c:	029ab823          	sd	s1,48(s5)
          while(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f70:	5898                	lw	a4,48(s1)
    80001f72:	377d                	addiw	a4,a4,-1
    80001f74:	000b2683          	lw	a3,0(s6)
            if(ticks*10 >= pause_time){
    80001f78:	000ca603          	lw	a2,0(s9)
    80001f7c:	0026179b          	slliw	a5,a2,0x2
    80001f80:	9fb1                	addw	a5,a5,a2
    80001f82:	0017979b          	slliw	a5,a5,0x1
    80001f86:	0006859b          	sext.w	a1,a3
          while(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f8a:	4605                	li	a2,1
    80001f8c:	fae673e3          	bgeu	a2,a4,80001f32 <scheduler+0x78>
    80001f90:	d2cd                	beqz	a3,80001f32 <scheduler+0x78>
            if(ticks*10 >= pause_time){
    80001f92:	feb7ede3          	bltu	a5,a1,80001f8c <scheduler+0xd2>
              pause_time = 0;
    80001f96:	000b2023          	sw	zero,0(s6)
              break;
    80001f9a:	bf61                	j	80001f32 <scheduler+0x78>

0000000080001f9c <sched>:
{
    80001f9c:	7179                	addi	sp,sp,-48
    80001f9e:	f406                	sd	ra,40(sp)
    80001fa0:	f022                	sd	s0,32(sp)
    80001fa2:	ec26                	sd	s1,24(sp)
    80001fa4:	e84a                	sd	s2,16(sp)
    80001fa6:	e44e                	sd	s3,8(sp)
    80001fa8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001faa:	00000097          	auipc	ra,0x0
    80001fae:	a06080e7          	jalr	-1530(ra) # 800019b0 <myproc>
    80001fb2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	bb6080e7          	jalr	-1098(ra) # 80000b6a <holding>
    80001fbc:	c93d                	beqz	a0,80002032 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbe:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	00008717          	auipc	a4,0x8
    80001fc8:	1cc70713          	addi	a4,a4,460 # 8000a190 <pid_lock>
    80001fcc:	97ba                	add	a5,a5,a4
    80001fce:	0a87a703          	lw	a4,168(a5)
    80001fd2:	4785                	li	a5,1
    80001fd4:	06f71763          	bne	a4,a5,80002042 <sched+0xa6>
  if(p->state == RUNNING)
    80001fd8:	4c98                	lw	a4,24(s1)
    80001fda:	4791                	li	a5,4
    80001fdc:	06f70b63          	beq	a4,a5,80002052 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fe6:	efb5                	bnez	a5,80002062 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fea:	00008917          	auipc	s2,0x8
    80001fee:	1a690913          	addi	s2,s2,422 # 8000a190 <pid_lock>
    80001ff2:	2781                	sext.w	a5,a5
    80001ff4:	079e                	slli	a5,a5,0x7
    80001ff6:	97ca                	add	a5,a5,s2
    80001ff8:	0ac7a983          	lw	s3,172(a5)
    80001ffc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	00008597          	auipc	a1,0x8
    80002006:	1c658593          	addi	a1,a1,454 # 8000a1c8 <cpus+0x8>
    8000200a:	95be                	add	a1,a1,a5
    8000200c:	06048513          	addi	a0,s1,96
    80002010:	00000097          	auipc	ra,0x0
    80002014:	67e080e7          	jalr	1662(ra) # 8000268e <swtch>
    80002018:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	97ca                	add	a5,a5,s2
    80002020:	0b37a623          	sw	s3,172(a5)
}
    80002024:	70a2                	ld	ra,40(sp)
    80002026:	7402                	ld	s0,32(sp)
    80002028:	64e2                	ld	s1,24(sp)
    8000202a:	6942                	ld	s2,16(sp)
    8000202c:	69a2                	ld	s3,8(sp)
    8000202e:	6145                	addi	sp,sp,48
    80002030:	8082                	ret
    panic("sched p->lock");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	1e650513          	addi	a0,a0,486 # 80008218 <digits+0x1d8>
    8000203a:	ffffe097          	auipc	ra,0xffffe
    8000203e:	504080e7          	jalr	1284(ra) # 8000053e <panic>
    panic("sched locks");
    80002042:	00006517          	auipc	a0,0x6
    80002046:	1e650513          	addi	a0,a0,486 # 80008228 <digits+0x1e8>
    8000204a:	ffffe097          	auipc	ra,0xffffe
    8000204e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
    panic("sched running");
    80002052:	00006517          	auipc	a0,0x6
    80002056:	1e650513          	addi	a0,a0,486 # 80008238 <digits+0x1f8>
    8000205a:	ffffe097          	auipc	ra,0xffffe
    8000205e:	4e4080e7          	jalr	1252(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	1e650513          	addi	a0,a0,486 # 80008248 <digits+0x208>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>

0000000080002072 <yield>:
{
    80002072:	1101                	addi	sp,sp,-32
    80002074:	ec06                	sd	ra,24(sp)
    80002076:	e822                	sd	s0,16(sp)
    80002078:	e426                	sd	s1,8(sp)
    8000207a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	934080e7          	jalr	-1740(ra) # 800019b0 <myproc>
    80002084:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b5e080e7          	jalr	-1186(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000208e:	478d                	li	a5,3
    80002090:	cc9c                	sw	a5,24(s1)
  sched();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	f0a080e7          	jalr	-246(ra) # 80001f9c <sched>
  release(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bfc080e7          	jalr	-1028(ra) # 80000c98 <release>
}
    800020a4:	60e2                	ld	ra,24(sp)
    800020a6:	6442                	ld	s0,16(sp)
    800020a8:	64a2                	ld	s1,8(sp)
    800020aa:	6105                	addi	sp,sp,32
    800020ac:	8082                	ret

00000000800020ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ae:	7179                	addi	sp,sp,-48
    800020b0:	f406                	sd	ra,40(sp)
    800020b2:	f022                	sd	s0,32(sp)
    800020b4:	ec26                	sd	s1,24(sp)
    800020b6:	e84a                	sd	s2,16(sp)
    800020b8:	e44e                	sd	s3,8(sp)
    800020ba:	1800                	addi	s0,sp,48
    800020bc:	89aa                	mv	s3,a0
    800020be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	8f0080e7          	jalr	-1808(ra) # 800019b0 <myproc>
    800020c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <acquire>
  release(lk);
    800020d2:	854a                	mv	a0,s2
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020e0:	4789                	li	a5,2
    800020e2:	cc9c                	sw	a5,24(s1)

  sched();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	eb8080e7          	jalr	-328(ra) # 80001f9c <sched>

  // Tidy up.
  p->chan = 0;
    800020ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	ba6080e7          	jalr	-1114(ra) # 80000c98 <release>
  acquire(lk);
    800020fa:	854a                	mv	a0,s2
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
}
    80002104:	70a2                	ld	ra,40(sp)
    80002106:	7402                	ld	s0,32(sp)
    80002108:	64e2                	ld	s1,24(sp)
    8000210a:	6942                	ld	s2,16(sp)
    8000210c:	69a2                	ld	s3,8(sp)
    8000210e:	6145                	addi	sp,sp,48
    80002110:	8082                	ret

0000000080002112 <wait>:
{
    80002112:	715d                	addi	sp,sp,-80
    80002114:	e486                	sd	ra,72(sp)
    80002116:	e0a2                	sd	s0,64(sp)
    80002118:	fc26                	sd	s1,56(sp)
    8000211a:	f84a                	sd	s2,48(sp)
    8000211c:	f44e                	sd	s3,40(sp)
    8000211e:	f052                	sd	s4,32(sp)
    80002120:	ec56                	sd	s5,24(sp)
    80002122:	e85a                	sd	s6,16(sp)
    80002124:	e45e                	sd	s7,8(sp)
    80002126:	e062                	sd	s8,0(sp)
    80002128:	0880                	addi	s0,sp,80
    8000212a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	884080e7          	jalr	-1916(ra) # 800019b0 <myproc>
    80002134:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002136:	00008517          	auipc	a0,0x8
    8000213a:	07250513          	addi	a0,a0,114 # 8000a1a8 <wait_lock>
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	aa6080e7          	jalr	-1370(ra) # 80000be4 <acquire>
    havekids = 0;
    80002146:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002148:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000214a:	0000e997          	auipc	s3,0xe
    8000214e:	af698993          	addi	s3,s3,-1290 # 8000fc40 <tickslock>
        havekids = 1;
    80002152:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002154:	00008c17          	auipc	s8,0x8
    80002158:	054c0c13          	addi	s8,s8,84 # 8000a1a8 <wait_lock>
    havekids = 0;
    8000215c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000215e:	00008497          	auipc	s1,0x8
    80002162:	0e248493          	addi	s1,s1,226 # 8000a240 <proc>
    80002166:	a0bd                	j	800021d4 <wait+0xc2>
          pid = np->pid;
    80002168:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000216c:	000b0e63          	beqz	s6,80002188 <wait+0x76>
    80002170:	4691                	li	a3,4
    80002172:	02c48613          	addi	a2,s1,44
    80002176:	85da                	mv	a1,s6
    80002178:	05093503          	ld	a0,80(s2)
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	4f6080e7          	jalr	1270(ra) # 80001672 <copyout>
    80002184:	02054563          	bltz	a0,800021ae <wait+0x9c>
          freeproc(np);
    80002188:	8526                	mv	a0,s1
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	9d8080e7          	jalr	-1576(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
          release(&wait_lock);
    8000219c:	00008517          	auipc	a0,0x8
    800021a0:	00c50513          	addi	a0,a0,12 # 8000a1a8 <wait_lock>
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	af4080e7          	jalr	-1292(ra) # 80000c98 <release>
          return pid;
    800021ac:	a09d                	j	80002212 <wait+0x100>
            release(&np->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ae8080e7          	jalr	-1304(ra) # 80000c98 <release>
            release(&wait_lock);
    800021b8:	00008517          	auipc	a0,0x8
    800021bc:	ff050513          	addi	a0,a0,-16 # 8000a1a8 <wait_lock>
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ad8080e7          	jalr	-1320(ra) # 80000c98 <release>
            return -1;
    800021c8:	59fd                	li	s3,-1
    800021ca:	a0a1                	j	80002212 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021cc:	16848493          	addi	s1,s1,360
    800021d0:	03348463          	beq	s1,s3,800021f8 <wait+0xe6>
      if(np->parent == p){
    800021d4:	7c9c                	ld	a5,56(s1)
    800021d6:	ff279be3          	bne	a5,s2,800021cc <wait+0xba>
        acquire(&np->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	a08080e7          	jalr	-1528(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021e4:	4c9c                	lw	a5,24(s1)
    800021e6:	f94781e3          	beq	a5,s4,80002168 <wait+0x56>
        release(&np->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	aac080e7          	jalr	-1364(ra) # 80000c98 <release>
        havekids = 1;
    800021f4:	8756                	mv	a4,s5
    800021f6:	bfd9                	j	800021cc <wait+0xba>
    if(!havekids || p->killed){
    800021f8:	c701                	beqz	a4,80002200 <wait+0xee>
    800021fa:	02892783          	lw	a5,40(s2)
    800021fe:	c79d                	beqz	a5,8000222c <wait+0x11a>
      release(&wait_lock);
    80002200:	00008517          	auipc	a0,0x8
    80002204:	fa850513          	addi	a0,a0,-88 # 8000a1a8 <wait_lock>
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a90080e7          	jalr	-1392(ra) # 80000c98 <release>
      return -1;
    80002210:	59fd                	li	s3,-1
}
    80002212:	854e                	mv	a0,s3
    80002214:	60a6                	ld	ra,72(sp)
    80002216:	6406                	ld	s0,64(sp)
    80002218:	74e2                	ld	s1,56(sp)
    8000221a:	7942                	ld	s2,48(sp)
    8000221c:	79a2                	ld	s3,40(sp)
    8000221e:	7a02                	ld	s4,32(sp)
    80002220:	6ae2                	ld	s5,24(sp)
    80002222:	6b42                	ld	s6,16(sp)
    80002224:	6ba2                	ld	s7,8(sp)
    80002226:	6c02                	ld	s8,0(sp)
    80002228:	6161                	addi	sp,sp,80
    8000222a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000222c:	85e2                	mv	a1,s8
    8000222e:	854a                	mv	a0,s2
    80002230:	00000097          	auipc	ra,0x0
    80002234:	e7e080e7          	jalr	-386(ra) # 800020ae <sleep>
    havekids = 0;
    80002238:	b715                	j	8000215c <wait+0x4a>

000000008000223a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000223a:	7139                	addi	sp,sp,-64
    8000223c:	fc06                	sd	ra,56(sp)
    8000223e:	f822                	sd	s0,48(sp)
    80002240:	f426                	sd	s1,40(sp)
    80002242:	f04a                	sd	s2,32(sp)
    80002244:	ec4e                	sd	s3,24(sp)
    80002246:	e852                	sd	s4,16(sp)
    80002248:	e456                	sd	s5,8(sp)
    8000224a:	0080                	addi	s0,sp,64
    8000224c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000224e:	00008497          	auipc	s1,0x8
    80002252:	ff248493          	addi	s1,s1,-14 # 8000a240 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002256:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002258:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000225a:	0000e917          	auipc	s2,0xe
    8000225e:	9e690913          	addi	s2,s2,-1562 # 8000fc40 <tickslock>
    80002262:	a821                	j	8000227a <wakeup+0x40>
        p->state = RUNNABLE;
    80002264:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002272:	16848493          	addi	s1,s1,360
    80002276:	03248463          	beq	s1,s2,8000229e <wakeup+0x64>
    if(p != myproc()){
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	736080e7          	jalr	1846(ra) # 800019b0 <myproc>
    80002282:	fea488e3          	beq	s1,a0,80002272 <wakeup+0x38>
      acquire(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	95c080e7          	jalr	-1700(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002290:	4c9c                	lw	a5,24(s1)
    80002292:	fd379be3          	bne	a5,s3,80002268 <wakeup+0x2e>
    80002296:	709c                	ld	a5,32(s1)
    80002298:	fd4798e3          	bne	a5,s4,80002268 <wakeup+0x2e>
    8000229c:	b7e1                	j	80002264 <wakeup+0x2a>
    }
  }
}
    8000229e:	70e2                	ld	ra,56(sp)
    800022a0:	7442                	ld	s0,48(sp)
    800022a2:	74a2                	ld	s1,40(sp)
    800022a4:	7902                	ld	s2,32(sp)
    800022a6:	69e2                	ld	s3,24(sp)
    800022a8:	6a42                	ld	s4,16(sp)
    800022aa:	6aa2                	ld	s5,8(sp)
    800022ac:	6121                	addi	sp,sp,64
    800022ae:	8082                	ret

00000000800022b0 <reparent>:
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	e052                	sd	s4,0(sp)
    800022be:	1800                	addi	s0,sp,48
    800022c0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c2:	00008497          	auipc	s1,0x8
    800022c6:	f7e48493          	addi	s1,s1,-130 # 8000a240 <proc>
      pp->parent = initproc;
    800022ca:	00007a17          	auipc	s4,0x7
    800022ce:	d66a0a13          	addi	s4,s4,-666 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d2:	0000e997          	auipc	s3,0xe
    800022d6:	96e98993          	addi	s3,s3,-1682 # 8000fc40 <tickslock>
    800022da:	a029                	j	800022e4 <reparent+0x34>
    800022dc:	16848493          	addi	s1,s1,360
    800022e0:	01348d63          	beq	s1,s3,800022fa <reparent+0x4a>
    if(pp->parent == p){
    800022e4:	7c9c                	ld	a5,56(s1)
    800022e6:	ff279be3          	bne	a5,s2,800022dc <reparent+0x2c>
      pp->parent = initproc;
    800022ea:	000a3503          	ld	a0,0(s4)
    800022ee:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022f0:	00000097          	auipc	ra,0x0
    800022f4:	f4a080e7          	jalr	-182(ra) # 8000223a <wakeup>
    800022f8:	b7d5                	j	800022dc <reparent+0x2c>
}
    800022fa:	70a2                	ld	ra,40(sp)
    800022fc:	7402                	ld	s0,32(sp)
    800022fe:	64e2                	ld	s1,24(sp)
    80002300:	6942                	ld	s2,16(sp)
    80002302:	69a2                	ld	s3,8(sp)
    80002304:	6a02                	ld	s4,0(sp)
    80002306:	6145                	addi	sp,sp,48
    80002308:	8082                	ret

000000008000230a <exit>:
{
    8000230a:	7179                	addi	sp,sp,-48
    8000230c:	f406                	sd	ra,40(sp)
    8000230e:	f022                	sd	s0,32(sp)
    80002310:	ec26                	sd	s1,24(sp)
    80002312:	e84a                	sd	s2,16(sp)
    80002314:	e44e                	sd	s3,8(sp)
    80002316:	e052                	sd	s4,0(sp)
    80002318:	1800                	addi	s0,sp,48
    8000231a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	694080e7          	jalr	1684(ra) # 800019b0 <myproc>
    80002324:	89aa                	mv	s3,a0
  if(p == initproc)
    80002326:	00007797          	auipc	a5,0x7
    8000232a:	d0a7b783          	ld	a5,-758(a5) # 80009030 <initproc>
    8000232e:	0d050493          	addi	s1,a0,208
    80002332:	15050913          	addi	s2,a0,336
    80002336:	02a79363          	bne	a5,a0,8000235c <exit+0x52>
    panic("init exiting");
    8000233a:	00006517          	auipc	a0,0x6
    8000233e:	f2650513          	addi	a0,a0,-218 # 80008260 <digits+0x220>
    80002342:	ffffe097          	auipc	ra,0xffffe
    80002346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>
      fileclose(f);
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	290080e7          	jalr	656(ra) # 800045da <fileclose>
      p->ofile[fd] = 0;
    80002352:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002356:	04a1                	addi	s1,s1,8
    80002358:	01248563          	beq	s1,s2,80002362 <exit+0x58>
    if(p->ofile[fd]){
    8000235c:	6088                	ld	a0,0(s1)
    8000235e:	f575                	bnez	a0,8000234a <exit+0x40>
    80002360:	bfdd                	j	80002356 <exit+0x4c>
  begin_op();
    80002362:	00002097          	auipc	ra,0x2
    80002366:	dac080e7          	jalr	-596(ra) # 8000410e <begin_op>
  iput(p->cwd);
    8000236a:	1509b503          	ld	a0,336(s3)
    8000236e:	00001097          	auipc	ra,0x1
    80002372:	588080e7          	jalr	1416(ra) # 800038f6 <iput>
  end_op();
    80002376:	00002097          	auipc	ra,0x2
    8000237a:	e18080e7          	jalr	-488(ra) # 8000418e <end_op>
  p->cwd = 0;
    8000237e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002382:	00008497          	auipc	s1,0x8
    80002386:	e2648493          	addi	s1,s1,-474 # 8000a1a8 <wait_lock>
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
  reparent(p);
    80002394:	854e                	mv	a0,s3
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	f1a080e7          	jalr	-230(ra) # 800022b0 <reparent>
  wakeup(p->parent);
    8000239e:	0389b503          	ld	a0,56(s3)
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	e98080e7          	jalr	-360(ra) # 8000223a <wakeup>
  acquire(&p->lock);
    800023aa:	854e                	mv	a0,s3
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023b4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023b8:	4795                	li	a5,5
    800023ba:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
  sched();
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	bd4080e7          	jalr	-1068(ra) # 80001f9c <sched>
  panic("zombie exit");
    800023d0:	00006517          	auipc	a0,0x6
    800023d4:	ea050513          	addi	a0,a0,-352 # 80008270 <digits+0x230>
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	166080e7          	jalr	358(ra) # 8000053e <panic>

00000000800023e0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	1800                	addi	s0,sp,48
    800023ee:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	00008497          	auipc	s1,0x8
    800023f4:	e5048493          	addi	s1,s1,-432 # 8000a240 <proc>
    800023f8:	0000e997          	auipc	s3,0xe
    800023fc:	84898993          	addi	s3,s3,-1976 # 8000fc40 <tickslock>
    acquire(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	7e2080e7          	jalr	2018(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000240a:	589c                	lw	a5,48(s1)
    8000240c:	01278d63          	beq	a5,s2,80002426 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000241a:	16848493          	addi	s1,s1,360
    8000241e:	ff3491e3          	bne	s1,s3,80002400 <kill+0x20>
  }
  return -1;
    80002422:	557d                	li	a0,-1
    80002424:	a829                	j	8000243e <kill+0x5e>
      p->killed = 1;
    80002426:	4785                	li	a5,1
    80002428:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000242a:	4c98                	lw	a4,24(s1)
    8000242c:	4789                	li	a5,2
    8000242e:	00f70f63          	beq	a4,a5,8000244c <kill+0x6c>
      release(&p->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	864080e7          	jalr	-1948(ra) # 80000c98 <release>
      return 0;
    8000243c:	4501                	li	a0,0
}
    8000243e:	70a2                	ld	ra,40(sp)
    80002440:	7402                	ld	s0,32(sp)
    80002442:	64e2                	ld	s1,24(sp)
    80002444:	6942                	ld	s2,16(sp)
    80002446:	69a2                	ld	s3,8(sp)
    80002448:	6145                	addi	sp,sp,48
    8000244a:	8082                	ret
        p->state = RUNNABLE;
    8000244c:	478d                	li	a5,3
    8000244e:	cc9c                	sw	a5,24(s1)
    80002450:	b7cd                	j	80002432 <kill+0x52>

0000000080002452 <kill_system>:

int
kill_system()
{
    80002452:	715d                	addi	sp,sp,-80
    80002454:	e486                	sd	ra,72(sp)
    80002456:	e0a2                	sd	s0,64(sp)
    80002458:	fc26                	sd	s1,56(sp)
    8000245a:	f84a                	sd	s2,48(sp)
    8000245c:	f44e                	sd	s3,40(sp)
    8000245e:	f052                	sd	s4,32(sp)
    80002460:	ec56                	sd	s5,24(sp)
    80002462:	e85a                	sd	s6,16(sp)
    80002464:	e45e                	sd	s7,8(sp)
    80002466:	e062                	sd	s8,0(sp)
    80002468:	0880                	addi	s0,sp,80
  struct proc *myp = myproc();
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	546080e7          	jalr	1350(ra) # 800019b0 <myproc>
    80002472:	8c2a                	mv	s8,a0
  int mypid = myp->pid;
    80002474:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	76c080e7          	jalr	1900(ra) # 80000be4 <acquire>
  struct proc *p;

  for(p = proc;p < &proc[NPROC]; p++){
    80002480:	00008497          	auipc	s1,0x8
    80002484:	dc048493          	addi	s1,s1,-576 # 8000a240 <proc>
    if(p->pid != mypid){
      acquire(&p->lock);
      if(p->pid != 1 && p->pid != 2){
    80002488:	4a05                	li	s4,1
        p->killed = 1;
    8000248a:	4b05                	li	s6,1
        if(p->state == SLEEPING){
    8000248c:	4a89                	li	s5,2
          // Wake process from sleep().
          p->state = RUNNABLE;
    8000248e:	4b8d                	li	s7,3
  for(p = proc;p < &proc[NPROC]; p++){
    80002490:	0000d917          	auipc	s2,0xd
    80002494:	7b090913          	addi	s2,s2,1968 # 8000fc40 <tickslock>
    80002498:	a811                	j	800024ac <kill_system+0x5a>
        }
      }
      release(&p->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7fc080e7          	jalr	2044(ra) # 80000c98 <release>
  for(p = proc;p < &proc[NPROC]; p++){
    800024a4:	16848493          	addi	s1,s1,360
    800024a8:	03248663          	beq	s1,s2,800024d4 <kill_system+0x82>
    if(p->pid != mypid){
    800024ac:	589c                	lw	a5,48(s1)
    800024ae:	ff378be3          	beq	a5,s3,800024a4 <kill_system+0x52>
      acquire(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	730080e7          	jalr	1840(ra) # 80000be4 <acquire>
      if(p->pid != 1 && p->pid != 2){
    800024bc:	589c                	lw	a5,48(s1)
    800024be:	37fd                	addiw	a5,a5,-1
    800024c0:	fcfa7de3          	bgeu	s4,a5,8000249a <kill_system+0x48>
        p->killed = 1;
    800024c4:	0364a423          	sw	s6,40(s1)
        if(p->state == SLEEPING){
    800024c8:	4c9c                	lw	a5,24(s1)
    800024ca:	fd5798e3          	bne	a5,s5,8000249a <kill_system+0x48>
          p->state = RUNNABLE;
    800024ce:	0174ac23          	sw	s7,24(s1)
    800024d2:	b7e1                	j	8000249a <kill_system+0x48>
    }
  }

  myp->killed = 1;
    800024d4:	4785                	li	a5,1
    800024d6:	02fc2423          	sw	a5,40(s8)
  release(&myp->lock);
    800024da:	8562                	mv	a0,s8
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	7bc080e7          	jalr	1980(ra) # 80000c98 <release>
  return 0;
}
    800024e4:	4501                	li	a0,0
    800024e6:	60a6                	ld	ra,72(sp)
    800024e8:	6406                	ld	s0,64(sp)
    800024ea:	74e2                	ld	s1,56(sp)
    800024ec:	7942                	ld	s2,48(sp)
    800024ee:	79a2                	ld	s3,40(sp)
    800024f0:	7a02                	ld	s4,32(sp)
    800024f2:	6ae2                	ld	s5,24(sp)
    800024f4:	6b42                	ld	s6,16(sp)
    800024f6:	6ba2                	ld	s7,8(sp)
    800024f8:	6c02                	ld	s8,0(sp)
    800024fa:	6161                	addi	sp,sp,80
    800024fc:	8082                	ret

00000000800024fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024fe:	7179                	addi	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	e052                	sd	s4,0(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	84aa                	mv	s1,a0
    80002510:	892e                	mv	s2,a1
    80002512:	89b2                	mv	s3,a2
    80002514:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	49a080e7          	jalr	1178(ra) # 800019b0 <myproc>
  if(user_dst){
    8000251e:	c08d                	beqz	s1,80002540 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002520:	86d2                	mv	a3,s4
    80002522:	864e                	mv	a2,s3
    80002524:	85ca                	mv	a1,s2
    80002526:	6928                	ld	a0,80(a0)
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	14a080e7          	jalr	330(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002530:	70a2                	ld	ra,40(sp)
    80002532:	7402                	ld	s0,32(sp)
    80002534:	64e2                	ld	s1,24(sp)
    80002536:	6942                	ld	s2,16(sp)
    80002538:	69a2                	ld	s3,8(sp)
    8000253a:	6a02                	ld	s4,0(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret
    memmove((char *)dst, src, len);
    80002540:	000a061b          	sext.w	a2,s4
    80002544:	85ce                	mv	a1,s3
    80002546:	854a                	mv	a0,s2
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	7f8080e7          	jalr	2040(ra) # 80000d40 <memmove>
    return 0;
    80002550:	8526                	mv	a0,s1
    80002552:	bff9                	j	80002530 <either_copyout+0x32>

0000000080002554 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002554:	7179                	addi	sp,sp,-48
    80002556:	f406                	sd	ra,40(sp)
    80002558:	f022                	sd	s0,32(sp)
    8000255a:	ec26                	sd	s1,24(sp)
    8000255c:	e84a                	sd	s2,16(sp)
    8000255e:	e44e                	sd	s3,8(sp)
    80002560:	e052                	sd	s4,0(sp)
    80002562:	1800                	addi	s0,sp,48
    80002564:	892a                	mv	s2,a0
    80002566:	84ae                	mv	s1,a1
    80002568:	89b2                	mv	s3,a2
    8000256a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	444080e7          	jalr	1092(ra) # 800019b0 <myproc>
  if(user_src){
    80002574:	c08d                	beqz	s1,80002596 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002576:	86d2                	mv	a3,s4
    80002578:	864e                	mv	a2,s3
    8000257a:	85ca                	mv	a1,s2
    8000257c:	6928                	ld	a0,80(a0)
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	180080e7          	jalr	384(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002586:	70a2                	ld	ra,40(sp)
    80002588:	7402                	ld	s0,32(sp)
    8000258a:	64e2                	ld	s1,24(sp)
    8000258c:	6942                	ld	s2,16(sp)
    8000258e:	69a2                	ld	s3,8(sp)
    80002590:	6a02                	ld	s4,0(sp)
    80002592:	6145                	addi	sp,sp,48
    80002594:	8082                	ret
    memmove(dst, (char*)src, len);
    80002596:	000a061b          	sext.w	a2,s4
    8000259a:	85ce                	mv	a1,s3
    8000259c:	854a                	mv	a0,s2
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	7a2080e7          	jalr	1954(ra) # 80000d40 <memmove>
    return 0;
    800025a6:	8526                	mv	a0,s1
    800025a8:	bff9                	j	80002586 <either_copyin+0x32>

00000000800025aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025aa:	715d                	addi	sp,sp,-80
    800025ac:	e486                	sd	ra,72(sp)
    800025ae:	e0a2                	sd	s0,64(sp)
    800025b0:	fc26                	sd	s1,56(sp)
    800025b2:	f84a                	sd	s2,48(sp)
    800025b4:	f44e                	sd	s3,40(sp)
    800025b6:	f052                	sd	s4,32(sp)
    800025b8:	ec56                	sd	s5,24(sp)
    800025ba:	e85a                	sd	s6,16(sp)
    800025bc:	e45e                	sd	s7,8(sp)
    800025be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c0:	00006517          	auipc	a0,0x6
    800025c4:	b0850513          	addi	a0,a0,-1272 # 800080c8 <digits+0x88>
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	fc0080e7          	jalr	-64(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d0:	00008497          	auipc	s1,0x8
    800025d4:	dc848493          	addi	s1,s1,-568 # 8000a398 <proc+0x158>
    800025d8:	0000d917          	auipc	s2,0xd
    800025dc:	7c090913          	addi	s2,s2,1984 # 8000fd98 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e2:	00006997          	auipc	s3,0x6
    800025e6:	c9e98993          	addi	s3,s3,-866 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025ea:	00006a97          	auipc	s5,0x6
    800025ee:	c9ea8a93          	addi	s5,s5,-866 # 80008288 <digits+0x248>
    printf("\n");
    800025f2:	00006a17          	auipc	s4,0x6
    800025f6:	ad6a0a13          	addi	s4,s4,-1322 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fa:	00006b97          	auipc	s7,0x6
    800025fe:	cc6b8b93          	addi	s7,s7,-826 # 800082c0 <states.1725>
    80002602:	a00d                	j	80002624 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002604:	ed86a583          	lw	a1,-296(a3)
    80002608:	8556                	mv	a0,s5
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f7e080e7          	jalr	-130(ra) # 80000588 <printf>
    printf("\n");
    80002612:	8552                	mv	a0,s4
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	f74080e7          	jalr	-140(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261c:	16848493          	addi	s1,s1,360
    80002620:	03248163          	beq	s1,s2,80002642 <procdump+0x98>
    if(p->state == UNUSED)
    80002624:	86a6                	mv	a3,s1
    80002626:	ec04a783          	lw	a5,-320(s1)
    8000262a:	dbed                	beqz	a5,8000261c <procdump+0x72>
      state = "???";
    8000262c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262e:	fcfb6be3          	bltu	s6,a5,80002604 <procdump+0x5a>
    80002632:	1782                	slli	a5,a5,0x20
    80002634:	9381                	srli	a5,a5,0x20
    80002636:	078e                	slli	a5,a5,0x3
    80002638:	97de                	add	a5,a5,s7
    8000263a:	6390                	ld	a2,0(a5)
    8000263c:	f661                	bnez	a2,80002604 <procdump+0x5a>
      state = "???";
    8000263e:	864e                	mv	a2,s3
    80002640:	b7d1                	j	80002604 <procdump+0x5a>
  }
}
    80002642:	60a6                	ld	ra,72(sp)
    80002644:	6406                	ld	s0,64(sp)
    80002646:	74e2                	ld	s1,56(sp)
    80002648:	7942                	ld	s2,48(sp)
    8000264a:	79a2                	ld	s3,40(sp)
    8000264c:	7a02                	ld	s4,32(sp)
    8000264e:	6ae2                	ld	s5,24(sp)
    80002650:	6b42                	ld	s6,16(sp)
    80002652:	6ba2                	ld	s7,8(sp)
    80002654:	6161                	addi	sp,sp,80
    80002656:	8082                	ret

0000000080002658 <pause_system>:

int
pause_system(int seconds)
{
    80002658:	1141                	addi	sp,sp,-16
    8000265a:	e406                	sd	ra,8(sp)
    8000265c:	e022                	sd	s0,0(sp)
    8000265e:	0800                	addi	s0,sp,16
  pause_time = (ticks * 10) + seconds;
    80002660:	00007717          	auipc	a4,0x7
    80002664:	9d872703          	lw	a4,-1576(a4) # 80009038 <ticks>
    80002668:	0027179b          	slliw	a5,a4,0x2
    8000266c:	9fb9                	addw	a5,a5,a4
    8000266e:	0017979b          	slliw	a5,a5,0x1
    80002672:	9fa9                	addw	a5,a5,a0
    80002674:	00007717          	auipc	a4,0x7
    80002678:	9af72a23          	sw	a5,-1612(a4) # 80009028 <pause_time>
  yield();
    8000267c:	00000097          	auipc	ra,0x0
    80002680:	9f6080e7          	jalr	-1546(ra) # 80002072 <yield>
  return 0;
}
    80002684:	4501                	li	a0,0
    80002686:	60a2                	ld	ra,8(sp)
    80002688:	6402                	ld	s0,0(sp)
    8000268a:	0141                	addi	sp,sp,16
    8000268c:	8082                	ret

000000008000268e <swtch>:
    8000268e:	00153023          	sd	ra,0(a0)
    80002692:	00253423          	sd	sp,8(a0)
    80002696:	e900                	sd	s0,16(a0)
    80002698:	ed04                	sd	s1,24(a0)
    8000269a:	03253023          	sd	s2,32(a0)
    8000269e:	03353423          	sd	s3,40(a0)
    800026a2:	03453823          	sd	s4,48(a0)
    800026a6:	03553c23          	sd	s5,56(a0)
    800026aa:	05653023          	sd	s6,64(a0)
    800026ae:	05753423          	sd	s7,72(a0)
    800026b2:	05853823          	sd	s8,80(a0)
    800026b6:	05953c23          	sd	s9,88(a0)
    800026ba:	07a53023          	sd	s10,96(a0)
    800026be:	07b53423          	sd	s11,104(a0)
    800026c2:	0005b083          	ld	ra,0(a1)
    800026c6:	0085b103          	ld	sp,8(a1)
    800026ca:	6980                	ld	s0,16(a1)
    800026cc:	6d84                	ld	s1,24(a1)
    800026ce:	0205b903          	ld	s2,32(a1)
    800026d2:	0285b983          	ld	s3,40(a1)
    800026d6:	0305ba03          	ld	s4,48(a1)
    800026da:	0385ba83          	ld	s5,56(a1)
    800026de:	0405bb03          	ld	s6,64(a1)
    800026e2:	0485bb83          	ld	s7,72(a1)
    800026e6:	0505bc03          	ld	s8,80(a1)
    800026ea:	0585bc83          	ld	s9,88(a1)
    800026ee:	0605bd03          	ld	s10,96(a1)
    800026f2:	0685bd83          	ld	s11,104(a1)
    800026f6:	8082                	ret

00000000800026f8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e406                	sd	ra,8(sp)
    800026fc:	e022                	sd	s0,0(sp)
    800026fe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002700:	00006597          	auipc	a1,0x6
    80002704:	bf058593          	addi	a1,a1,-1040 # 800082f0 <states.1725+0x30>
    80002708:	0000d517          	auipc	a0,0xd
    8000270c:	53850513          	addi	a0,a0,1336 # 8000fc40 <tickslock>
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	444080e7          	jalr	1092(ra) # 80000b54 <initlock>
}
    80002718:	60a2                	ld	ra,8(sp)
    8000271a:	6402                	ld	s0,0(sp)
    8000271c:	0141                	addi	sp,sp,16
    8000271e:	8082                	ret

0000000080002720 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002720:	1141                	addi	sp,sp,-16
    80002722:	e422                	sd	s0,8(sp)
    80002724:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002726:	00003797          	auipc	a5,0x3
    8000272a:	4ca78793          	addi	a5,a5,1226 # 80005bf0 <kernelvec>
    8000272e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002732:	6422                	ld	s0,8(sp)
    80002734:	0141                	addi	sp,sp,16
    80002736:	8082                	ret

0000000080002738 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002738:	1141                	addi	sp,sp,-16
    8000273a:	e406                	sd	ra,8(sp)
    8000273c:	e022                	sd	s0,0(sp)
    8000273e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	270080e7          	jalr	624(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002748:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000274c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002752:	00005617          	auipc	a2,0x5
    80002756:	8ae60613          	addi	a2,a2,-1874 # 80007000 <_trampoline>
    8000275a:	00005697          	auipc	a3,0x5
    8000275e:	8a668693          	addi	a3,a3,-1882 # 80007000 <_trampoline>
    80002762:	8e91                	sub	a3,a3,a2
    80002764:	040007b7          	lui	a5,0x4000
    80002768:	17fd                	addi	a5,a5,-1
    8000276a:	07b2                	slli	a5,a5,0xc
    8000276c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002772:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002774:	180026f3          	csrr	a3,satp
    80002778:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000277a:	6d38                	ld	a4,88(a0)
    8000277c:	6134                	ld	a3,64(a0)
    8000277e:	6585                	lui	a1,0x1
    80002780:	96ae                	add	a3,a3,a1
    80002782:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002784:	6d38                	ld	a4,88(a0)
    80002786:	00000697          	auipc	a3,0x0
    8000278a:	13868693          	addi	a3,a3,312 # 800028be <usertrap>
    8000278e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002790:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002792:	8692                	mv	a3,tp
    80002794:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002796:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000279a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a8:	6f18                	ld	a4,24(a4)
    800027aa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027ae:	692c                	ld	a1,80(a0)
    800027b0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027b2:	00005717          	auipc	a4,0x5
    800027b6:	8de70713          	addi	a4,a4,-1826 # 80007090 <userret>
    800027ba:	8f11                	sub	a4,a4,a2
    800027bc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027be:	577d                	li	a4,-1
    800027c0:	177e                	slli	a4,a4,0x3f
    800027c2:	8dd9                	or	a1,a1,a4
    800027c4:	02000537          	lui	a0,0x2000
    800027c8:	157d                	addi	a0,a0,-1
    800027ca:	0536                	slli	a0,a0,0xd
    800027cc:	9782                	jalr	a5
}
    800027ce:	60a2                	ld	ra,8(sp)
    800027d0:	6402                	ld	s0,0(sp)
    800027d2:	0141                	addi	sp,sp,16
    800027d4:	8082                	ret

00000000800027d6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d6:	1101                	addi	sp,sp,-32
    800027d8:	ec06                	sd	ra,24(sp)
    800027da:	e822                	sd	s0,16(sp)
    800027dc:	e426                	sd	s1,8(sp)
    800027de:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027e0:	0000d497          	auipc	s1,0xd
    800027e4:	46048493          	addi	s1,s1,1120 # 8000fc40 <tickslock>
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	3fa080e7          	jalr	1018(ra) # 80000be4 <acquire>
  ticks++;
    800027f2:	00007517          	auipc	a0,0x7
    800027f6:	84650513          	addi	a0,a0,-1978 # 80009038 <ticks>
    800027fa:	411c                	lw	a5,0(a0)
    800027fc:	2785                	addiw	a5,a5,1
    800027fe:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002800:	00000097          	auipc	ra,0x0
    80002804:	a3a080e7          	jalr	-1478(ra) # 8000223a <wakeup>
  release(&tickslock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	48e080e7          	jalr	1166(ra) # 80000c98 <release>
}
    80002812:	60e2                	ld	ra,24(sp)
    80002814:	6442                	ld	s0,16(sp)
    80002816:	64a2                	ld	s1,8(sp)
    80002818:	6105                	addi	sp,sp,32
    8000281a:	8082                	ret

000000008000281c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000281c:	1101                	addi	sp,sp,-32
    8000281e:	ec06                	sd	ra,24(sp)
    80002820:	e822                	sd	s0,16(sp)
    80002822:	e426                	sd	s1,8(sp)
    80002824:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002826:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000282a:	00074d63          	bltz	a4,80002844 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282e:	57fd                	li	a5,-1
    80002830:	17fe                	slli	a5,a5,0x3f
    80002832:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002834:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002836:	06f70363          	beq	a4,a5,8000289c <devintr+0x80>
  }
}
    8000283a:	60e2                	ld	ra,24(sp)
    8000283c:	6442                	ld	s0,16(sp)
    8000283e:	64a2                	ld	s1,8(sp)
    80002840:	6105                	addi	sp,sp,32
    80002842:	8082                	ret
     (scause & 0xff) == 9){
    80002844:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002848:	46a5                	li	a3,9
    8000284a:	fed792e3          	bne	a5,a3,8000282e <devintr+0x12>
    int irq = plic_claim();
    8000284e:	00003097          	auipc	ra,0x3
    80002852:	4aa080e7          	jalr	1194(ra) # 80005cf8 <plic_claim>
    80002856:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002858:	47a9                	li	a5,10
    8000285a:	02f50763          	beq	a0,a5,80002888 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285e:	4785                	li	a5,1
    80002860:	02f50963          	beq	a0,a5,80002892 <devintr+0x76>
    return 1;
    80002864:	4505                	li	a0,1
    } else if(irq){
    80002866:	d8f1                	beqz	s1,8000283a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002868:	85a6                	mv	a1,s1
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	a8e50513          	addi	a0,a0,-1394 # 800082f8 <states.1725+0x38>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d16080e7          	jalr	-746(ra) # 80000588 <printf>
      plic_complete(irq);
    8000287a:	8526                	mv	a0,s1
    8000287c:	00003097          	auipc	ra,0x3
    80002880:	4a0080e7          	jalr	1184(ra) # 80005d1c <plic_complete>
    return 1;
    80002884:	4505                	li	a0,1
    80002886:	bf55                	j	8000283a <devintr+0x1e>
      uartintr();
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	120080e7          	jalr	288(ra) # 800009a8 <uartintr>
    80002890:	b7ed                	j	8000287a <devintr+0x5e>
      virtio_disk_intr();
    80002892:	00004097          	auipc	ra,0x4
    80002896:	96a080e7          	jalr	-1686(ra) # 800061fc <virtio_disk_intr>
    8000289a:	b7c5                	j	8000287a <devintr+0x5e>
    if(cpuid() == 0){
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	0e8080e7          	jalr	232(ra) # 80001984 <cpuid>
    800028a4:	c901                	beqz	a0,800028b4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ac:	14479073          	csrw	sip,a5
    return 2;
    800028b0:	4509                	li	a0,2
    800028b2:	b761                	j	8000283a <devintr+0x1e>
      clockintr();
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	f22080e7          	jalr	-222(ra) # 800027d6 <clockintr>
    800028bc:	b7ed                	j	800028a6 <devintr+0x8a>

00000000800028be <usertrap>:
{
    800028be:	1101                	addi	sp,sp,-32
    800028c0:	ec06                	sd	ra,24(sp)
    800028c2:	e822                	sd	s0,16(sp)
    800028c4:	e426                	sd	s1,8(sp)
    800028c6:	e04a                	sd	s2,0(sp)
    800028c8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ce:	1007f793          	andi	a5,a5,256
    800028d2:	e3ad                	bnez	a5,80002934 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d4:	00003797          	auipc	a5,0x3
    800028d8:	31c78793          	addi	a5,a5,796 # 80005bf0 <kernelvec>
    800028dc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	0d0080e7          	jalr	208(ra) # 800019b0 <myproc>
    800028e8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ea:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	14102773          	csrr	a4,sepc
    800028f0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f6:	47a1                	li	a5,8
    800028f8:	04f71c63          	bne	a4,a5,80002950 <usertrap+0x92>
    if(p->killed)
    800028fc:	551c                	lw	a5,40(a0)
    800028fe:	e3b9                	bnez	a5,80002944 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002900:	6cb8                	ld	a4,88(s1)
    80002902:	6f1c                	ld	a5,24(a4)
    80002904:	0791                	addi	a5,a5,4
    80002906:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10079073          	csrw	sstatus,a5
    syscall();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	2e0080e7          	jalr	736(ra) # 80002bf4 <syscall>
  if(p->killed)
    8000291c:	549c                	lw	a5,40(s1)
    8000291e:	ebc1                	bnez	a5,800029ae <usertrap+0xf0>
  usertrapret();
    80002920:	00000097          	auipc	ra,0x0
    80002924:	e18080e7          	jalr	-488(ra) # 80002738 <usertrapret>
}
    80002928:	60e2                	ld	ra,24(sp)
    8000292a:	6442                	ld	s0,16(sp)
    8000292c:	64a2                	ld	s1,8(sp)
    8000292e:	6902                	ld	s2,0(sp)
    80002930:	6105                	addi	sp,sp,32
    80002932:	8082                	ret
    panic("usertrap: not from user mode");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	9e450513          	addi	a0,a0,-1564 # 80008318 <states.1725+0x58>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c02080e7          	jalr	-1022(ra) # 8000053e <panic>
      exit(-1);
    80002944:	557d                	li	a0,-1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	9c4080e7          	jalr	-1596(ra) # 8000230a <exit>
    8000294e:	bf4d                	j	80002900 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002950:	00000097          	auipc	ra,0x0
    80002954:	ecc080e7          	jalr	-308(ra) # 8000281c <devintr>
    80002958:	892a                	mv	s2,a0
    8000295a:	c501                	beqz	a0,80002962 <usertrap+0xa4>
  if(p->killed)
    8000295c:	549c                	lw	a5,40(s1)
    8000295e:	c3a1                	beqz	a5,8000299e <usertrap+0xe0>
    80002960:	a815                	j	80002994 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002962:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002966:	5890                	lw	a2,48(s1)
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	9d050513          	addi	a0,a0,-1584 # 80008338 <states.1725+0x78>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	c18080e7          	jalr	-1000(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002978:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002980:	00006517          	auipc	a0,0x6
    80002984:	9e850513          	addi	a0,a0,-1560 # 80008368 <states.1725+0xa8>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c00080e7          	jalr	-1024(ra) # 80000588 <printf>
    p->killed = 1;
    80002990:	4785                	li	a5,1
    80002992:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002994:	557d                	li	a0,-1
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	974080e7          	jalr	-1676(ra) # 8000230a <exit>
  if(which_dev == 2)
    8000299e:	4789                	li	a5,2
    800029a0:	f8f910e3          	bne	s2,a5,80002920 <usertrap+0x62>
    yield();
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	6ce080e7          	jalr	1742(ra) # 80002072 <yield>
    800029ac:	bf95                	j	80002920 <usertrap+0x62>
  int which_dev = 0;
    800029ae:	4901                	li	s2,0
    800029b0:	b7d5                	j	80002994 <usertrap+0xd6>

00000000800029b2 <kerneltrap>:
{
    800029b2:	7179                	addi	sp,sp,-48
    800029b4:	f406                	sd	ra,40(sp)
    800029b6:	f022                	sd	s0,32(sp)
    800029b8:	ec26                	sd	s1,24(sp)
    800029ba:	e84a                	sd	s2,16(sp)
    800029bc:	e44e                	sd	s3,8(sp)
    800029be:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029cc:	1004f793          	andi	a5,s1,256
    800029d0:	cb85                	beqz	a5,80002a00 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d8:	ef85                	bnez	a5,80002a10 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029da:	00000097          	auipc	ra,0x0
    800029de:	e42080e7          	jalr	-446(ra) # 8000281c <devintr>
    800029e2:	cd1d                	beqz	a0,80002a20 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e4:	4789                	li	a5,2
    800029e6:	06f50a63          	beq	a0,a5,80002a5a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ea:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ee:	10049073          	csrw	sstatus,s1
}
    800029f2:	70a2                	ld	ra,40(sp)
    800029f4:	7402                	ld	s0,32(sp)
    800029f6:	64e2                	ld	s1,24(sp)
    800029f8:	6942                	ld	s2,16(sp)
    800029fa:	69a2                	ld	s3,8(sp)
    800029fc:	6145                	addi	sp,sp,48
    800029fe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	98850513          	addi	a0,a0,-1656 # 80008388 <states.1725+0xc8>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b36080e7          	jalr	-1226(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	9a050513          	addi	a0,a0,-1632 # 800083b0 <states.1725+0xf0>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a20:	85ce                	mv	a1,s3
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	9ae50513          	addi	a0,a0,-1618 # 800083d0 <states.1725+0x110>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b5e080e7          	jalr	-1186(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a36:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	9a650513          	addi	a0,a0,-1626 # 800083e0 <states.1725+0x120>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b46080e7          	jalr	-1210(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	9ae50513          	addi	a0,a0,-1618 # 800083f8 <states.1725+0x138>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	f56080e7          	jalr	-170(ra) # 800019b0 <myproc>
    80002a62:	d541                	beqz	a0,800029ea <kerneltrap+0x38>
    80002a64:	fffff097          	auipc	ra,0xfffff
    80002a68:	f4c080e7          	jalr	-180(ra) # 800019b0 <myproc>
    80002a6c:	4d18                	lw	a4,24(a0)
    80002a6e:	4791                	li	a5,4
    80002a70:	f6f71de3          	bne	a4,a5,800029ea <kerneltrap+0x38>
    yield();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	5fe080e7          	jalr	1534(ra) # 80002072 <yield>
    80002a7c:	b7bd                	j	800029ea <kerneltrap+0x38>

0000000080002a7e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a7e:	1101                	addi	sp,sp,-32
    80002a80:	ec06                	sd	ra,24(sp)
    80002a82:	e822                	sd	s0,16(sp)
    80002a84:	e426                	sd	s1,8(sp)
    80002a86:	1000                	addi	s0,sp,32
    80002a88:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f26080e7          	jalr	-218(ra) # 800019b0 <myproc>
  switch (n) {
    80002a92:	4795                	li	a5,5
    80002a94:	0497e163          	bltu	a5,s1,80002ad6 <argraw+0x58>
    80002a98:	048a                	slli	s1,s1,0x2
    80002a9a:	00006717          	auipc	a4,0x6
    80002a9e:	99670713          	addi	a4,a4,-1642 # 80008430 <states.1725+0x170>
    80002aa2:	94ba                	add	s1,s1,a4
    80002aa4:	409c                	lw	a5,0(s1)
    80002aa6:	97ba                	add	a5,a5,a4
    80002aa8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret
    return p->trapframe->a1;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	7fa8                	ld	a0,120(a5)
    80002abc:	bfcd                	j	80002aae <argraw+0x30>
    return p->trapframe->a2;
    80002abe:	6d3c                	ld	a5,88(a0)
    80002ac0:	63c8                	ld	a0,128(a5)
    80002ac2:	b7f5                	j	80002aae <argraw+0x30>
    return p->trapframe->a3;
    80002ac4:	6d3c                	ld	a5,88(a0)
    80002ac6:	67c8                	ld	a0,136(a5)
    80002ac8:	b7dd                	j	80002aae <argraw+0x30>
    return p->trapframe->a4;
    80002aca:	6d3c                	ld	a5,88(a0)
    80002acc:	6bc8                	ld	a0,144(a5)
    80002ace:	b7c5                	j	80002aae <argraw+0x30>
    return p->trapframe->a5;
    80002ad0:	6d3c                	ld	a5,88(a0)
    80002ad2:	6fc8                	ld	a0,152(a5)
    80002ad4:	bfe9                	j	80002aae <argraw+0x30>
  panic("argraw");
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	93250513          	addi	a0,a0,-1742 # 80008408 <states.1725+0x148>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	a60080e7          	jalr	-1440(ra) # 8000053e <panic>

0000000080002ae6 <fetchaddr>:
{
    80002ae6:	1101                	addi	sp,sp,-32
    80002ae8:	ec06                	sd	ra,24(sp)
    80002aea:	e822                	sd	s0,16(sp)
    80002aec:	e426                	sd	s1,8(sp)
    80002aee:	e04a                	sd	s2,0(sp)
    80002af0:	1000                	addi	s0,sp,32
    80002af2:	84aa                	mv	s1,a0
    80002af4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	eba080e7          	jalr	-326(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002afe:	653c                	ld	a5,72(a0)
    80002b00:	02f4f863          	bgeu	s1,a5,80002b30 <fetchaddr+0x4a>
    80002b04:	00848713          	addi	a4,s1,8
    80002b08:	02e7e663          	bltu	a5,a4,80002b34 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0c:	46a1                	li	a3,8
    80002b0e:	8626                	mv	a2,s1
    80002b10:	85ca                	mv	a1,s2
    80002b12:	6928                	ld	a0,80(a0)
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	bea080e7          	jalr	-1046(ra) # 800016fe <copyin>
    80002b1c:	00a03533          	snez	a0,a0
    80002b20:	40a00533          	neg	a0,a0
}
    80002b24:	60e2                	ld	ra,24(sp)
    80002b26:	6442                	ld	s0,16(sp)
    80002b28:	64a2                	ld	s1,8(sp)
    80002b2a:	6902                	ld	s2,0(sp)
    80002b2c:	6105                	addi	sp,sp,32
    80002b2e:	8082                	ret
    return -1;
    80002b30:	557d                	li	a0,-1
    80002b32:	bfcd                	j	80002b24 <fetchaddr+0x3e>
    80002b34:	557d                	li	a0,-1
    80002b36:	b7fd                	j	80002b24 <fetchaddr+0x3e>

0000000080002b38 <fetchstr>:
{
    80002b38:	7179                	addi	sp,sp,-48
    80002b3a:	f406                	sd	ra,40(sp)
    80002b3c:	f022                	sd	s0,32(sp)
    80002b3e:	ec26                	sd	s1,24(sp)
    80002b40:	e84a                	sd	s2,16(sp)
    80002b42:	e44e                	sd	s3,8(sp)
    80002b44:	1800                	addi	s0,sp,48
    80002b46:	892a                	mv	s2,a0
    80002b48:	84ae                	mv	s1,a1
    80002b4a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	e64080e7          	jalr	-412(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b54:	86ce                	mv	a3,s3
    80002b56:	864a                	mv	a2,s2
    80002b58:	85a6                	mv	a1,s1
    80002b5a:	6928                	ld	a0,80(a0)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	c2e080e7          	jalr	-978(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b64:	00054763          	bltz	a0,80002b72 <fetchstr+0x3a>
  return strlen(buf);
    80002b68:	8526                	mv	a0,s1
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	2fa080e7          	jalr	762(ra) # 80000e64 <strlen>
}
    80002b72:	70a2                	ld	ra,40(sp)
    80002b74:	7402                	ld	s0,32(sp)
    80002b76:	64e2                	ld	s1,24(sp)
    80002b78:	6942                	ld	s2,16(sp)
    80002b7a:	69a2                	ld	s3,8(sp)
    80002b7c:	6145                	addi	sp,sp,48
    80002b7e:	8082                	ret

0000000080002b80 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	e426                	sd	s1,8(sp)
    80002b88:	1000                	addi	s0,sp,32
    80002b8a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	ef2080e7          	jalr	-270(ra) # 80002a7e <argraw>
    80002b94:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b96:	4501                	li	a0,0
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6105                	addi	sp,sp,32
    80002ba0:	8082                	ret

0000000080002ba2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ba2:	1101                	addi	sp,sp,-32
    80002ba4:	ec06                	sd	ra,24(sp)
    80002ba6:	e822                	sd	s0,16(sp)
    80002ba8:	e426                	sd	s1,8(sp)
    80002baa:	1000                	addi	s0,sp,32
    80002bac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	ed0080e7          	jalr	-304(ra) # 80002a7e <argraw>
    80002bb6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bb8:	4501                	li	a0,0
    80002bba:	60e2                	ld	ra,24(sp)
    80002bbc:	6442                	ld	s0,16(sp)
    80002bbe:	64a2                	ld	s1,8(sp)
    80002bc0:	6105                	addi	sp,sp,32
    80002bc2:	8082                	ret

0000000080002bc4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84ae                	mv	s1,a1
    80002bd2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	eaa080e7          	jalr	-342(ra) # 80002a7e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bdc:	864a                	mv	a2,s2
    80002bde:	85a6                	mv	a1,s1
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	f58080e7          	jalr	-168(ra) # 80002b38 <fetchstr>
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6902                	ld	s2,0(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <syscall>:
[SYS_pause_system] sys_pause_system,
};

void
syscall(void)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	db0080e7          	jalr	-592(ra) # 800019b0 <myproc>
    80002c08:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c0a:	05853903          	ld	s2,88(a0)
    80002c0e:	0a893783          	ld	a5,168(s2)
    80002c12:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c16:	37fd                	addiw	a5,a5,-1
    80002c18:	4759                	li	a4,22
    80002c1a:	00f76f63          	bltu	a4,a5,80002c38 <syscall+0x44>
    80002c1e:	00369713          	slli	a4,a3,0x3
    80002c22:	00006797          	auipc	a5,0x6
    80002c26:	82678793          	addi	a5,a5,-2010 # 80008448 <syscalls>
    80002c2a:	97ba                	add	a5,a5,a4
    80002c2c:	639c                	ld	a5,0(a5)
    80002c2e:	c789                	beqz	a5,80002c38 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c30:	9782                	jalr	a5
    80002c32:	06a93823          	sd	a0,112(s2)
    80002c36:	a839                	j	80002c54 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c38:	15848613          	addi	a2,s1,344
    80002c3c:	588c                	lw	a1,48(s1)
    80002c3e:	00005517          	auipc	a0,0x5
    80002c42:	7d250513          	addi	a0,a0,2002 # 80008410 <states.1725+0x150>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	942080e7          	jalr	-1726(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c4e:	6cbc                	ld	a5,88(s1)
    80002c50:	577d                	li	a4,-1
    80002c52:	fbb8                	sd	a4,112(a5)
  }
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	64a2                	ld	s1,8(sp)
    80002c5a:	6902                	ld	s2,0(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret

0000000080002c60 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c60:	1101                	addi	sp,sp,-32
    80002c62:	ec06                	sd	ra,24(sp)
    80002c64:	e822                	sd	s0,16(sp)
    80002c66:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c68:	fec40593          	addi	a1,s0,-20
    80002c6c:	4501                	li	a0,0
    80002c6e:	00000097          	auipc	ra,0x0
    80002c72:	f12080e7          	jalr	-238(ra) # 80002b80 <argint>
    return -1;
    80002c76:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c78:	00054963          	bltz	a0,80002c8a <sys_exit+0x2a>
  exit(n);
    80002c7c:	fec42503          	lw	a0,-20(s0)
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	68a080e7          	jalr	1674(ra) # 8000230a <exit>
  return 0;  // not reached
    80002c88:	4781                	li	a5,0
}
    80002c8a:	853e                	mv	a0,a5
    80002c8c:	60e2                	ld	ra,24(sp)
    80002c8e:	6442                	ld	s0,16(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c94:	1141                	addi	sp,sp,-16
    80002c96:	e406                	sd	ra,8(sp)
    80002c98:	e022                	sd	s0,0(sp)
    80002c9a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d14080e7          	jalr	-748(ra) # 800019b0 <myproc>
}
    80002ca4:	5908                	lw	a0,48(a0)
    80002ca6:	60a2                	ld	ra,8(sp)
    80002ca8:	6402                	ld	s0,0(sp)
    80002caa:	0141                	addi	sp,sp,16
    80002cac:	8082                	ret

0000000080002cae <sys_fork>:

uint64
sys_fork(void)
{
    80002cae:	1141                	addi	sp,sp,-16
    80002cb0:	e406                	sd	ra,8(sp)
    80002cb2:	e022                	sd	s0,0(sp)
    80002cb4:	0800                	addi	s0,sp,16
  return fork();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	0c8080e7          	jalr	200(ra) # 80001d7e <fork>
}
    80002cbe:	60a2                	ld	ra,8(sp)
    80002cc0:	6402                	ld	s0,0(sp)
    80002cc2:	0141                	addi	sp,sp,16
    80002cc4:	8082                	ret

0000000080002cc6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc6:	1101                	addi	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cce:	fe840593          	addi	a1,s0,-24
    80002cd2:	4501                	li	a0,0
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	ece080e7          	jalr	-306(ra) # 80002ba2 <argaddr>
    80002cdc:	87aa                	mv	a5,a0
    return -1;
    80002cde:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ce0:	0007c863          	bltz	a5,80002cf0 <sys_wait+0x2a>
  return wait(p);
    80002ce4:	fe843503          	ld	a0,-24(s0)
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	42a080e7          	jalr	1066(ra) # 80002112 <wait>
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret

0000000080002cf8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cf8:	7179                	addi	sp,sp,-48
    80002cfa:	f406                	sd	ra,40(sp)
    80002cfc:	f022                	sd	s0,32(sp)
    80002cfe:	ec26                	sd	s1,24(sp)
    80002d00:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d02:	fdc40593          	addi	a1,s0,-36
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	e78080e7          	jalr	-392(ra) # 80002b80 <argint>
    80002d10:	87aa                	mv	a5,a0
    return -1;
    80002d12:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d14:	0207c063          	bltz	a5,80002d34 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80002d20:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d22:	fdc42503          	lw	a0,-36(s0)
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	fe4080e7          	jalr	-28(ra) # 80001d0a <growproc>
    80002d2e:	00054863          	bltz	a0,80002d3e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d32:	8526                	mv	a0,s1
}
    80002d34:	70a2                	ld	ra,40(sp)
    80002d36:	7402                	ld	s0,32(sp)
    80002d38:	64e2                	ld	s1,24(sp)
    80002d3a:	6145                	addi	sp,sp,48
    80002d3c:	8082                	ret
    return -1;
    80002d3e:	557d                	li	a0,-1
    80002d40:	bfd5                	j	80002d34 <sys_sbrk+0x3c>

0000000080002d42 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d42:	7139                	addi	sp,sp,-64
    80002d44:	fc06                	sd	ra,56(sp)
    80002d46:	f822                	sd	s0,48(sp)
    80002d48:	f426                	sd	s1,40(sp)
    80002d4a:	f04a                	sd	s2,32(sp)
    80002d4c:	ec4e                	sd	s3,24(sp)
    80002d4e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d50:	fcc40593          	addi	a1,s0,-52
    80002d54:	4501                	li	a0,0
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	e2a080e7          	jalr	-470(ra) # 80002b80 <argint>
    return -1;
    80002d5e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d60:	06054563          	bltz	a0,80002dca <sys_sleep+0x88>
  acquire(&tickslock);
    80002d64:	0000d517          	auipc	a0,0xd
    80002d68:	edc50513          	addi	a0,a0,-292 # 8000fc40 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	e78080e7          	jalr	-392(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d74:	00006917          	auipc	s2,0x6
    80002d78:	2c492903          	lw	s2,708(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002d7c:	fcc42783          	lw	a5,-52(s0)
    80002d80:	cf85                	beqz	a5,80002db8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d82:	0000d997          	auipc	s3,0xd
    80002d86:	ebe98993          	addi	s3,s3,-322 # 8000fc40 <tickslock>
    80002d8a:	00006497          	auipc	s1,0x6
    80002d8e:	2ae48493          	addi	s1,s1,686 # 80009038 <ticks>
    if(myproc()->killed){
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	c1e080e7          	jalr	-994(ra) # 800019b0 <myproc>
    80002d9a:	551c                	lw	a5,40(a0)
    80002d9c:	ef9d                	bnez	a5,80002dda <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d9e:	85ce                	mv	a1,s3
    80002da0:	8526                	mv	a0,s1
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	30c080e7          	jalr	780(ra) # 800020ae <sleep>
  while(ticks - ticks0 < n){
    80002daa:	409c                	lw	a5,0(s1)
    80002dac:	412787bb          	subw	a5,a5,s2
    80002db0:	fcc42703          	lw	a4,-52(s0)
    80002db4:	fce7efe3          	bltu	a5,a4,80002d92 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002db8:	0000d517          	auipc	a0,0xd
    80002dbc:	e8850513          	addi	a0,a0,-376 # 8000fc40 <tickslock>
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	ed8080e7          	jalr	-296(ra) # 80000c98 <release>
  return 0;
    80002dc8:	4781                	li	a5,0
}
    80002dca:	853e                	mv	a0,a5
    80002dcc:	70e2                	ld	ra,56(sp)
    80002dce:	7442                	ld	s0,48(sp)
    80002dd0:	74a2                	ld	s1,40(sp)
    80002dd2:	7902                	ld	s2,32(sp)
    80002dd4:	69e2                	ld	s3,24(sp)
    80002dd6:	6121                	addi	sp,sp,64
    80002dd8:	8082                	ret
      release(&tickslock);
    80002dda:	0000d517          	auipc	a0,0xd
    80002dde:	e6650513          	addi	a0,a0,-410 # 8000fc40 <tickslock>
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	eb6080e7          	jalr	-330(ra) # 80000c98 <release>
      return -1;
    80002dea:	57fd                	li	a5,-1
    80002dec:	bff9                	j	80002dca <sys_sleep+0x88>

0000000080002dee <sys_kill>:

uint64
sys_kill(void)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002df6:	fec40593          	addi	a1,s0,-20
    80002dfa:	4501                	li	a0,0
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	d84080e7          	jalr	-636(ra) # 80002b80 <argint>
    80002e04:	87aa                	mv	a5,a0
    return -1;
    80002e06:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e08:	0007c863          	bltz	a5,80002e18 <sys_kill+0x2a>
  return kill(pid);
    80002e0c:	fec42503          	lw	a0,-20(s0)
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	5d0080e7          	jalr	1488(ra) # 800023e0 <kill>
}
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret

0000000080002e20 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e2a:	0000d517          	auipc	a0,0xd
    80002e2e:	e1650513          	addi	a0,a0,-490 # 8000fc40 <tickslock>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	db2080e7          	jalr	-590(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e3a:	00006497          	auipc	s1,0x6
    80002e3e:	1fe4a483          	lw	s1,510(s1) # 80009038 <ticks>
  release(&tickslock);
    80002e42:	0000d517          	auipc	a0,0xd
    80002e46:	dfe50513          	addi	a0,a0,-514 # 8000fc40 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	e4e080e7          	jalr	-434(ra) # 80000c98 <release>
  return xticks;
}
    80002e52:	02049513          	slli	a0,s1,0x20
    80002e56:	9101                	srli	a0,a0,0x20
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret

0000000080002e62 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002e62:	1141                	addi	sp,sp,-16
    80002e64:	e406                	sd	ra,8(sp)
    80002e66:	e022                	sd	s0,0(sp)
    80002e68:	0800                	addi	s0,sp,16
  return kill_system();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	5e8080e7          	jalr	1512(ra) # 80002452 <kill_system>
}
    80002e72:	60a2                	ld	ra,8(sp)
    80002e74:	6402                	ld	s0,0(sp)
    80002e76:	0141                	addi	sp,sp,16
    80002e78:	8082                	ret

0000000080002e7a <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80002e82:	fec40593          	addi	a1,s0,-20
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	cf8080e7          	jalr	-776(ra) # 80002b80 <argint>
    80002e90:	87aa                	mv	a5,a0
    return -1;
    80002e92:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80002e94:	0007c863          	bltz	a5,80002ea4 <sys_pause_system+0x2a>
  return pause_system(seconds);
    80002e98:	fec42503          	lw	a0,-20(s0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	7bc080e7          	jalr	1980(ra) # 80002658 <pause_system>
}
    80002ea4:	60e2                	ld	ra,24(sp)
    80002ea6:	6442                	ld	s0,16(sp)
    80002ea8:	6105                	addi	sp,sp,32
    80002eaa:	8082                	ret

0000000080002eac <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eac:	7179                	addi	sp,sp,-48
    80002eae:	f406                	sd	ra,40(sp)
    80002eb0:	f022                	sd	s0,32(sp)
    80002eb2:	ec26                	sd	s1,24(sp)
    80002eb4:	e84a                	sd	s2,16(sp)
    80002eb6:	e44e                	sd	s3,8(sp)
    80002eb8:	e052                	sd	s4,0(sp)
    80002eba:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ebc:	00005597          	auipc	a1,0x5
    80002ec0:	64c58593          	addi	a1,a1,1612 # 80008508 <syscalls+0xc0>
    80002ec4:	0000d517          	auipc	a0,0xd
    80002ec8:	d9450513          	addi	a0,a0,-620 # 8000fc58 <bcache>
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	c88080e7          	jalr	-888(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed4:	00015797          	auipc	a5,0x15
    80002ed8:	d8478793          	addi	a5,a5,-636 # 80017c58 <bcache+0x8000>
    80002edc:	00015717          	auipc	a4,0x15
    80002ee0:	fe470713          	addi	a4,a4,-28 # 80017ec0 <bcache+0x8268>
    80002ee4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eec:	0000d497          	auipc	s1,0xd
    80002ef0:	d8448493          	addi	s1,s1,-636 # 8000fc70 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef8:	00005a17          	auipc	s4,0x5
    80002efc:	618a0a13          	addi	s4,s4,1560 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f00:	2b893783          	ld	a5,696(s2)
    80002f04:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f06:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f0a:	85d2                	mv	a1,s4
    80002f0c:	01048513          	addi	a0,s1,16
    80002f10:	00001097          	auipc	ra,0x1
    80002f14:	4bc080e7          	jalr	1212(ra) # 800043cc <initsleeplock>
    bcache.head.next->prev = b;
    80002f18:	2b893783          	ld	a5,696(s2)
    80002f1c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f22:	45848493          	addi	s1,s1,1112
    80002f26:	fd349de3          	bne	s1,s3,80002f00 <binit+0x54>
  }
}
    80002f2a:	70a2                	ld	ra,40(sp)
    80002f2c:	7402                	ld	s0,32(sp)
    80002f2e:	64e2                	ld	s1,24(sp)
    80002f30:	6942                	ld	s2,16(sp)
    80002f32:	69a2                	ld	s3,8(sp)
    80002f34:	6a02                	ld	s4,0(sp)
    80002f36:	6145                	addi	sp,sp,48
    80002f38:	8082                	ret

0000000080002f3a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f3a:	7179                	addi	sp,sp,-48
    80002f3c:	f406                	sd	ra,40(sp)
    80002f3e:	f022                	sd	s0,32(sp)
    80002f40:	ec26                	sd	s1,24(sp)
    80002f42:	e84a                	sd	s2,16(sp)
    80002f44:	e44e                	sd	s3,8(sp)
    80002f46:	1800                	addi	s0,sp,48
    80002f48:	89aa                	mv	s3,a0
    80002f4a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f4c:	0000d517          	auipc	a0,0xd
    80002f50:	d0c50513          	addi	a0,a0,-756 # 8000fc58 <bcache>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	c90080e7          	jalr	-880(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f5c:	00015497          	auipc	s1,0x15
    80002f60:	fb44b483          	ld	s1,-76(s1) # 80017f10 <bcache+0x82b8>
    80002f64:	00015797          	auipc	a5,0x15
    80002f68:	f5c78793          	addi	a5,a5,-164 # 80017ec0 <bcache+0x8268>
    80002f6c:	02f48f63          	beq	s1,a5,80002faa <bread+0x70>
    80002f70:	873e                	mv	a4,a5
    80002f72:	a021                	j	80002f7a <bread+0x40>
    80002f74:	68a4                	ld	s1,80(s1)
    80002f76:	02e48a63          	beq	s1,a4,80002faa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f7a:	449c                	lw	a5,8(s1)
    80002f7c:	ff379ce3          	bne	a5,s3,80002f74 <bread+0x3a>
    80002f80:	44dc                	lw	a5,12(s1)
    80002f82:	ff2799e3          	bne	a5,s2,80002f74 <bread+0x3a>
      b->refcnt++;
    80002f86:	40bc                	lw	a5,64(s1)
    80002f88:	2785                	addiw	a5,a5,1
    80002f8a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f8c:	0000d517          	auipc	a0,0xd
    80002f90:	ccc50513          	addi	a0,a0,-820 # 8000fc58 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	d04080e7          	jalr	-764(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f9c:	01048513          	addi	a0,s1,16
    80002fa0:	00001097          	auipc	ra,0x1
    80002fa4:	466080e7          	jalr	1126(ra) # 80004406 <acquiresleep>
      return b;
    80002fa8:	a8b9                	j	80003006 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002faa:	00015497          	auipc	s1,0x15
    80002fae:	f5e4b483          	ld	s1,-162(s1) # 80017f08 <bcache+0x82b0>
    80002fb2:	00015797          	auipc	a5,0x15
    80002fb6:	f0e78793          	addi	a5,a5,-242 # 80017ec0 <bcache+0x8268>
    80002fba:	00f48863          	beq	s1,a5,80002fca <bread+0x90>
    80002fbe:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fc0:	40bc                	lw	a5,64(s1)
    80002fc2:	cf81                	beqz	a5,80002fda <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc4:	64a4                	ld	s1,72(s1)
    80002fc6:	fee49de3          	bne	s1,a4,80002fc0 <bread+0x86>
  panic("bget: no buffers");
    80002fca:	00005517          	auipc	a0,0x5
    80002fce:	54e50513          	addi	a0,a0,1358 # 80008518 <syscalls+0xd0>
    80002fd2:	ffffd097          	auipc	ra,0xffffd
    80002fd6:	56c080e7          	jalr	1388(ra) # 8000053e <panic>
      b->dev = dev;
    80002fda:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fde:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fe2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe6:	4785                	li	a5,1
    80002fe8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fea:	0000d517          	auipc	a0,0xd
    80002fee:	c6e50513          	addi	a0,a0,-914 # 8000fc58 <bcache>
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ffa:	01048513          	addi	a0,s1,16
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	408080e7          	jalr	1032(ra) # 80004406 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003006:	409c                	lw	a5,0(s1)
    80003008:	cb89                	beqz	a5,8000301a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000300a:	8526                	mv	a0,s1
    8000300c:	70a2                	ld	ra,40(sp)
    8000300e:	7402                	ld	s0,32(sp)
    80003010:	64e2                	ld	s1,24(sp)
    80003012:	6942                	ld	s2,16(sp)
    80003014:	69a2                	ld	s3,8(sp)
    80003016:	6145                	addi	sp,sp,48
    80003018:	8082                	ret
    virtio_disk_rw(b, 0);
    8000301a:	4581                	li	a1,0
    8000301c:	8526                	mv	a0,s1
    8000301e:	00003097          	auipc	ra,0x3
    80003022:	f08080e7          	jalr	-248(ra) # 80005f26 <virtio_disk_rw>
    b->valid = 1;
    80003026:	4785                	li	a5,1
    80003028:	c09c                	sw	a5,0(s1)
  return b;
    8000302a:	b7c5                	j	8000300a <bread+0xd0>

000000008000302c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	e426                	sd	s1,8(sp)
    80003034:	1000                	addi	s0,sp,32
    80003036:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003038:	0541                	addi	a0,a0,16
    8000303a:	00001097          	auipc	ra,0x1
    8000303e:	466080e7          	jalr	1126(ra) # 800044a0 <holdingsleep>
    80003042:	cd01                	beqz	a0,8000305a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003044:	4585                	li	a1,1
    80003046:	8526                	mv	a0,s1
    80003048:	00003097          	auipc	ra,0x3
    8000304c:	ede080e7          	jalr	-290(ra) # 80005f26 <virtio_disk_rw>
}
    80003050:	60e2                	ld	ra,24(sp)
    80003052:	6442                	ld	s0,16(sp)
    80003054:	64a2                	ld	s1,8(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret
    panic("bwrite");
    8000305a:	00005517          	auipc	a0,0x5
    8000305e:	4d650513          	addi	a0,a0,1238 # 80008530 <syscalls+0xe8>
    80003062:	ffffd097          	auipc	ra,0xffffd
    80003066:	4dc080e7          	jalr	1244(ra) # 8000053e <panic>

000000008000306a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	e04a                	sd	s2,0(sp)
    80003074:	1000                	addi	s0,sp,32
    80003076:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003078:	01050913          	addi	s2,a0,16
    8000307c:	854a                	mv	a0,s2
    8000307e:	00001097          	auipc	ra,0x1
    80003082:	422080e7          	jalr	1058(ra) # 800044a0 <holdingsleep>
    80003086:	c92d                	beqz	a0,800030f8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003088:	854a                	mv	a0,s2
    8000308a:	00001097          	auipc	ra,0x1
    8000308e:	3d2080e7          	jalr	978(ra) # 8000445c <releasesleep>

  acquire(&bcache.lock);
    80003092:	0000d517          	auipc	a0,0xd
    80003096:	bc650513          	addi	a0,a0,-1082 # 8000fc58 <bcache>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	b4a080e7          	jalr	-1206(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030a2:	40bc                	lw	a5,64(s1)
    800030a4:	37fd                	addiw	a5,a5,-1
    800030a6:	0007871b          	sext.w	a4,a5
    800030aa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ac:	eb05                	bnez	a4,800030dc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ae:	68bc                	ld	a5,80(s1)
    800030b0:	64b8                	ld	a4,72(s1)
    800030b2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b4:	64bc                	ld	a5,72(s1)
    800030b6:	68b8                	ld	a4,80(s1)
    800030b8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030ba:	00015797          	auipc	a5,0x15
    800030be:	b9e78793          	addi	a5,a5,-1122 # 80017c58 <bcache+0x8000>
    800030c2:	2b87b703          	ld	a4,696(a5)
    800030c6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c8:	00015717          	auipc	a4,0x15
    800030cc:	df870713          	addi	a4,a4,-520 # 80017ec0 <bcache+0x8268>
    800030d0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030d2:	2b87b703          	ld	a4,696(a5)
    800030d6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030dc:	0000d517          	auipc	a0,0xd
    800030e0:	b7c50513          	addi	a0,a0,-1156 # 8000fc58 <bcache>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	bb4080e7          	jalr	-1100(ra) # 80000c98 <release>
}
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6902                	ld	s2,0(sp)
    800030f4:	6105                	addi	sp,sp,32
    800030f6:	8082                	ret
    panic("brelse");
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	44050513          	addi	a0,a0,1088 # 80008538 <syscalls+0xf0>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>

0000000080003108 <bpin>:

void
bpin(struct buf *b) {
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	1000                	addi	s0,sp,32
    80003112:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003114:	0000d517          	auipc	a0,0xd
    80003118:	b4450513          	addi	a0,a0,-1212 # 8000fc58 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	ac8080e7          	jalr	-1336(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003124:	40bc                	lw	a5,64(s1)
    80003126:	2785                	addiw	a5,a5,1
    80003128:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000312a:	0000d517          	auipc	a0,0xd
    8000312e:	b2e50513          	addi	a0,a0,-1234 # 8000fc58 <bcache>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
}
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <bunpin>:

void
bunpin(struct buf *b) {
    80003144:	1101                	addi	sp,sp,-32
    80003146:	ec06                	sd	ra,24(sp)
    80003148:	e822                	sd	s0,16(sp)
    8000314a:	e426                	sd	s1,8(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003150:	0000d517          	auipc	a0,0xd
    80003154:	b0850513          	addi	a0,a0,-1272 # 8000fc58 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	a8c080e7          	jalr	-1396(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003160:	40bc                	lw	a5,64(s1)
    80003162:	37fd                	addiw	a5,a5,-1
    80003164:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003166:	0000d517          	auipc	a0,0xd
    8000316a:	af250513          	addi	a0,a0,-1294 # 8000fc58 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>
}
    80003176:	60e2                	ld	ra,24(sp)
    80003178:	6442                	ld	s0,16(sp)
    8000317a:	64a2                	ld	s1,8(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	e04a                	sd	s2,0(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000318e:	00d5d59b          	srliw	a1,a1,0xd
    80003192:	00015797          	auipc	a5,0x15
    80003196:	1a27a783          	lw	a5,418(a5) # 80018334 <sb+0x1c>
    8000319a:	9dbd                	addw	a1,a1,a5
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	d9e080e7          	jalr	-610(ra) # 80002f3a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a4:	0074f713          	andi	a4,s1,7
    800031a8:	4785                	li	a5,1
    800031aa:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ae:	14ce                	slli	s1,s1,0x33
    800031b0:	90d9                	srli	s1,s1,0x36
    800031b2:	00950733          	add	a4,a0,s1
    800031b6:	05874703          	lbu	a4,88(a4)
    800031ba:	00e7f6b3          	and	a3,a5,a4
    800031be:	c69d                	beqz	a3,800031ec <bfree+0x6c>
    800031c0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031c2:	94aa                	add	s1,s1,a0
    800031c4:	fff7c793          	not	a5,a5
    800031c8:	8ff9                	and	a5,a5,a4
    800031ca:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	118080e7          	jalr	280(ra) # 800042e6 <log_write>
  brelse(bp);
    800031d6:	854a                	mv	a0,s2
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	e92080e7          	jalr	-366(ra) # 8000306a <brelse>
}
    800031e0:	60e2                	ld	ra,24(sp)
    800031e2:	6442                	ld	s0,16(sp)
    800031e4:	64a2                	ld	s1,8(sp)
    800031e6:	6902                	ld	s2,0(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret
    panic("freeing free block");
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	35450513          	addi	a0,a0,852 # 80008540 <syscalls+0xf8>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	34a080e7          	jalr	842(ra) # 8000053e <panic>

00000000800031fc <balloc>:
{
    800031fc:	711d                	addi	sp,sp,-96
    800031fe:	ec86                	sd	ra,88(sp)
    80003200:	e8a2                	sd	s0,80(sp)
    80003202:	e4a6                	sd	s1,72(sp)
    80003204:	e0ca                	sd	s2,64(sp)
    80003206:	fc4e                	sd	s3,56(sp)
    80003208:	f852                	sd	s4,48(sp)
    8000320a:	f456                	sd	s5,40(sp)
    8000320c:	f05a                	sd	s6,32(sp)
    8000320e:	ec5e                	sd	s7,24(sp)
    80003210:	e862                	sd	s8,16(sp)
    80003212:	e466                	sd	s9,8(sp)
    80003214:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003216:	00015797          	auipc	a5,0x15
    8000321a:	1067a783          	lw	a5,262(a5) # 8001831c <sb+0x4>
    8000321e:	cbd1                	beqz	a5,800032b2 <balloc+0xb6>
    80003220:	8baa                	mv	s7,a0
    80003222:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003224:	00015b17          	auipc	s6,0x15
    80003228:	0f4b0b13          	addi	s6,s6,244 # 80018318 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000322e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003230:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003232:	6c89                	lui	s9,0x2
    80003234:	a831                	j	80003250 <balloc+0x54>
    brelse(bp);
    80003236:	854a                	mv	a0,s2
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	e32080e7          	jalr	-462(ra) # 8000306a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003240:	015c87bb          	addw	a5,s9,s5
    80003244:	00078a9b          	sext.w	s5,a5
    80003248:	004b2703          	lw	a4,4(s6)
    8000324c:	06eaf363          	bgeu	s5,a4,800032b2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003250:	41fad79b          	sraiw	a5,s5,0x1f
    80003254:	0137d79b          	srliw	a5,a5,0x13
    80003258:	015787bb          	addw	a5,a5,s5
    8000325c:	40d7d79b          	sraiw	a5,a5,0xd
    80003260:	01cb2583          	lw	a1,28(s6)
    80003264:	9dbd                	addw	a1,a1,a5
    80003266:	855e                	mv	a0,s7
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	cd2080e7          	jalr	-814(ra) # 80002f3a <bread>
    80003270:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003272:	004b2503          	lw	a0,4(s6)
    80003276:	000a849b          	sext.w	s1,s5
    8000327a:	8662                	mv	a2,s8
    8000327c:	faa4fde3          	bgeu	s1,a0,80003236 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003280:	41f6579b          	sraiw	a5,a2,0x1f
    80003284:	01d7d69b          	srliw	a3,a5,0x1d
    80003288:	00c6873b          	addw	a4,a3,a2
    8000328c:	00777793          	andi	a5,a4,7
    80003290:	9f95                	subw	a5,a5,a3
    80003292:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003296:	4037571b          	sraiw	a4,a4,0x3
    8000329a:	00e906b3          	add	a3,s2,a4
    8000329e:	0586c683          	lbu	a3,88(a3)
    800032a2:	00d7f5b3          	and	a1,a5,a3
    800032a6:	cd91                	beqz	a1,800032c2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a8:	2605                	addiw	a2,a2,1
    800032aa:	2485                	addiw	s1,s1,1
    800032ac:	fd4618e3          	bne	a2,s4,8000327c <balloc+0x80>
    800032b0:	b759                	j	80003236 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032b2:	00005517          	auipc	a0,0x5
    800032b6:	2a650513          	addi	a0,a0,678 # 80008558 <syscalls+0x110>
    800032ba:	ffffd097          	auipc	ra,0xffffd
    800032be:	284080e7          	jalr	644(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032c2:	974a                	add	a4,a4,s2
    800032c4:	8fd5                	or	a5,a5,a3
    800032c6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032ca:	854a                	mv	a0,s2
    800032cc:	00001097          	auipc	ra,0x1
    800032d0:	01a080e7          	jalr	26(ra) # 800042e6 <log_write>
        brelse(bp);
    800032d4:	854a                	mv	a0,s2
    800032d6:	00000097          	auipc	ra,0x0
    800032da:	d94080e7          	jalr	-620(ra) # 8000306a <brelse>
  bp = bread(dev, bno);
    800032de:	85a6                	mv	a1,s1
    800032e0:	855e                	mv	a0,s7
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	c58080e7          	jalr	-936(ra) # 80002f3a <bread>
    800032ea:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ec:	40000613          	li	a2,1024
    800032f0:	4581                	li	a1,0
    800032f2:	05850513          	addi	a0,a0,88
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	9ea080e7          	jalr	-1558(ra) # 80000ce0 <memset>
  log_write(bp);
    800032fe:	854a                	mv	a0,s2
    80003300:	00001097          	auipc	ra,0x1
    80003304:	fe6080e7          	jalr	-26(ra) # 800042e6 <log_write>
  brelse(bp);
    80003308:	854a                	mv	a0,s2
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	d60080e7          	jalr	-672(ra) # 8000306a <brelse>
}
    80003312:	8526                	mv	a0,s1
    80003314:	60e6                	ld	ra,88(sp)
    80003316:	6446                	ld	s0,80(sp)
    80003318:	64a6                	ld	s1,72(sp)
    8000331a:	6906                	ld	s2,64(sp)
    8000331c:	79e2                	ld	s3,56(sp)
    8000331e:	7a42                	ld	s4,48(sp)
    80003320:	7aa2                	ld	s5,40(sp)
    80003322:	7b02                	ld	s6,32(sp)
    80003324:	6be2                	ld	s7,24(sp)
    80003326:	6c42                	ld	s8,16(sp)
    80003328:	6ca2                	ld	s9,8(sp)
    8000332a:	6125                	addi	sp,sp,96
    8000332c:	8082                	ret

000000008000332e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000332e:	7179                	addi	sp,sp,-48
    80003330:	f406                	sd	ra,40(sp)
    80003332:	f022                	sd	s0,32(sp)
    80003334:	ec26                	sd	s1,24(sp)
    80003336:	e84a                	sd	s2,16(sp)
    80003338:	e44e                	sd	s3,8(sp)
    8000333a:	e052                	sd	s4,0(sp)
    8000333c:	1800                	addi	s0,sp,48
    8000333e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003340:	47ad                	li	a5,11
    80003342:	04b7fe63          	bgeu	a5,a1,8000339e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003346:	ff45849b          	addiw	s1,a1,-12
    8000334a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000334e:	0ff00793          	li	a5,255
    80003352:	0ae7e363          	bltu	a5,a4,800033f8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003356:	08052583          	lw	a1,128(a0)
    8000335a:	c5ad                	beqz	a1,800033c4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000335c:	00092503          	lw	a0,0(s2)
    80003360:	00000097          	auipc	ra,0x0
    80003364:	bda080e7          	jalr	-1062(ra) # 80002f3a <bread>
    80003368:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000336a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000336e:	02049593          	slli	a1,s1,0x20
    80003372:	9181                	srli	a1,a1,0x20
    80003374:	058a                	slli	a1,a1,0x2
    80003376:	00b784b3          	add	s1,a5,a1
    8000337a:	0004a983          	lw	s3,0(s1)
    8000337e:	04098d63          	beqz	s3,800033d8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003382:	8552                	mv	a0,s4
    80003384:	00000097          	auipc	ra,0x0
    80003388:	ce6080e7          	jalr	-794(ra) # 8000306a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000338c:	854e                	mv	a0,s3
    8000338e:	70a2                	ld	ra,40(sp)
    80003390:	7402                	ld	s0,32(sp)
    80003392:	64e2                	ld	s1,24(sp)
    80003394:	6942                	ld	s2,16(sp)
    80003396:	69a2                	ld	s3,8(sp)
    80003398:	6a02                	ld	s4,0(sp)
    8000339a:	6145                	addi	sp,sp,48
    8000339c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000339e:	02059493          	slli	s1,a1,0x20
    800033a2:	9081                	srli	s1,s1,0x20
    800033a4:	048a                	slli	s1,s1,0x2
    800033a6:	94aa                	add	s1,s1,a0
    800033a8:	0504a983          	lw	s3,80(s1)
    800033ac:	fe0990e3          	bnez	s3,8000338c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033b0:	4108                	lw	a0,0(a0)
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	e4a080e7          	jalr	-438(ra) # 800031fc <balloc>
    800033ba:	0005099b          	sext.w	s3,a0
    800033be:	0534a823          	sw	s3,80(s1)
    800033c2:	b7e9                	j	8000338c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033c4:	4108                	lw	a0,0(a0)
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	e36080e7          	jalr	-458(ra) # 800031fc <balloc>
    800033ce:	0005059b          	sext.w	a1,a0
    800033d2:	08b92023          	sw	a1,128(s2)
    800033d6:	b759                	j	8000335c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033d8:	00092503          	lw	a0,0(s2)
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	e20080e7          	jalr	-480(ra) # 800031fc <balloc>
    800033e4:	0005099b          	sext.w	s3,a0
    800033e8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ec:	8552                	mv	a0,s4
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	ef8080e7          	jalr	-264(ra) # 800042e6 <log_write>
    800033f6:	b771                	j	80003382 <bmap+0x54>
  panic("bmap: out of range");
    800033f8:	00005517          	auipc	a0,0x5
    800033fc:	17850513          	addi	a0,a0,376 # 80008570 <syscalls+0x128>
    80003400:	ffffd097          	auipc	ra,0xffffd
    80003404:	13e080e7          	jalr	318(ra) # 8000053e <panic>

0000000080003408 <iget>:
{
    80003408:	7179                	addi	sp,sp,-48
    8000340a:	f406                	sd	ra,40(sp)
    8000340c:	f022                	sd	s0,32(sp)
    8000340e:	ec26                	sd	s1,24(sp)
    80003410:	e84a                	sd	s2,16(sp)
    80003412:	e44e                	sd	s3,8(sp)
    80003414:	e052                	sd	s4,0(sp)
    80003416:	1800                	addi	s0,sp,48
    80003418:	89aa                	mv	s3,a0
    8000341a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000341c:	00015517          	auipc	a0,0x15
    80003420:	f1c50513          	addi	a0,a0,-228 # 80018338 <itable>
    80003424:	ffffd097          	auipc	ra,0xffffd
    80003428:	7c0080e7          	jalr	1984(ra) # 80000be4 <acquire>
  empty = 0;
    8000342c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000342e:	00015497          	auipc	s1,0x15
    80003432:	f2248493          	addi	s1,s1,-222 # 80018350 <itable+0x18>
    80003436:	00017697          	auipc	a3,0x17
    8000343a:	9aa68693          	addi	a3,a3,-1622 # 80019de0 <log>
    8000343e:	a039                	j	8000344c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003440:	02090b63          	beqz	s2,80003476 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003444:	08848493          	addi	s1,s1,136
    80003448:	02d48a63          	beq	s1,a3,8000347c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000344c:	449c                	lw	a5,8(s1)
    8000344e:	fef059e3          	blez	a5,80003440 <iget+0x38>
    80003452:	4098                	lw	a4,0(s1)
    80003454:	ff3716e3          	bne	a4,s3,80003440 <iget+0x38>
    80003458:	40d8                	lw	a4,4(s1)
    8000345a:	ff4713e3          	bne	a4,s4,80003440 <iget+0x38>
      ip->ref++;
    8000345e:	2785                	addiw	a5,a5,1
    80003460:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003462:	00015517          	auipc	a0,0x15
    80003466:	ed650513          	addi	a0,a0,-298 # 80018338 <itable>
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	82e080e7          	jalr	-2002(ra) # 80000c98 <release>
      return ip;
    80003472:	8926                	mv	s2,s1
    80003474:	a03d                	j	800034a2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003476:	f7f9                	bnez	a5,80003444 <iget+0x3c>
    80003478:	8926                	mv	s2,s1
    8000347a:	b7e9                	j	80003444 <iget+0x3c>
  if(empty == 0)
    8000347c:	02090c63          	beqz	s2,800034b4 <iget+0xac>
  ip->dev = dev;
    80003480:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003484:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003488:	4785                	li	a5,1
    8000348a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000348e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003492:	00015517          	auipc	a0,0x15
    80003496:	ea650513          	addi	a0,a0,-346 # 80018338 <itable>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	7fe080e7          	jalr	2046(ra) # 80000c98 <release>
}
    800034a2:	854a                	mv	a0,s2
    800034a4:	70a2                	ld	ra,40(sp)
    800034a6:	7402                	ld	s0,32(sp)
    800034a8:	64e2                	ld	s1,24(sp)
    800034aa:	6942                	ld	s2,16(sp)
    800034ac:	69a2                	ld	s3,8(sp)
    800034ae:	6a02                	ld	s4,0(sp)
    800034b0:	6145                	addi	sp,sp,48
    800034b2:	8082                	ret
    panic("iget: no inodes");
    800034b4:	00005517          	auipc	a0,0x5
    800034b8:	0d450513          	addi	a0,a0,212 # 80008588 <syscalls+0x140>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	082080e7          	jalr	130(ra) # 8000053e <panic>

00000000800034c4 <fsinit>:
fsinit(int dev) {
    800034c4:	7179                	addi	sp,sp,-48
    800034c6:	f406                	sd	ra,40(sp)
    800034c8:	f022                	sd	s0,32(sp)
    800034ca:	ec26                	sd	s1,24(sp)
    800034cc:	e84a                	sd	s2,16(sp)
    800034ce:	e44e                	sd	s3,8(sp)
    800034d0:	1800                	addi	s0,sp,48
    800034d2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d4:	4585                	li	a1,1
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	a64080e7          	jalr	-1436(ra) # 80002f3a <bread>
    800034de:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034e0:	00015997          	auipc	s3,0x15
    800034e4:	e3898993          	addi	s3,s3,-456 # 80018318 <sb>
    800034e8:	02000613          	li	a2,32
    800034ec:	05850593          	addi	a1,a0,88
    800034f0:	854e                	mv	a0,s3
    800034f2:	ffffe097          	auipc	ra,0xffffe
    800034f6:	84e080e7          	jalr	-1970(ra) # 80000d40 <memmove>
  brelse(bp);
    800034fa:	8526                	mv	a0,s1
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	b6e080e7          	jalr	-1170(ra) # 8000306a <brelse>
  if(sb.magic != FSMAGIC)
    80003504:	0009a703          	lw	a4,0(s3)
    80003508:	102037b7          	lui	a5,0x10203
    8000350c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003510:	02f71263          	bne	a4,a5,80003534 <fsinit+0x70>
  initlog(dev, &sb);
    80003514:	00015597          	auipc	a1,0x15
    80003518:	e0458593          	addi	a1,a1,-508 # 80018318 <sb>
    8000351c:	854a                	mv	a0,s2
    8000351e:	00001097          	auipc	ra,0x1
    80003522:	b4c080e7          	jalr	-1204(ra) # 8000406a <initlog>
}
    80003526:	70a2                	ld	ra,40(sp)
    80003528:	7402                	ld	s0,32(sp)
    8000352a:	64e2                	ld	s1,24(sp)
    8000352c:	6942                	ld	s2,16(sp)
    8000352e:	69a2                	ld	s3,8(sp)
    80003530:	6145                	addi	sp,sp,48
    80003532:	8082                	ret
    panic("invalid file system");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	06450513          	addi	a0,a0,100 # 80008598 <syscalls+0x150>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	002080e7          	jalr	2(ra) # 8000053e <panic>

0000000080003544 <iinit>:
{
    80003544:	7179                	addi	sp,sp,-48
    80003546:	f406                	sd	ra,40(sp)
    80003548:	f022                	sd	s0,32(sp)
    8000354a:	ec26                	sd	s1,24(sp)
    8000354c:	e84a                	sd	s2,16(sp)
    8000354e:	e44e                	sd	s3,8(sp)
    80003550:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003552:	00005597          	auipc	a1,0x5
    80003556:	05e58593          	addi	a1,a1,94 # 800085b0 <syscalls+0x168>
    8000355a:	00015517          	auipc	a0,0x15
    8000355e:	dde50513          	addi	a0,a0,-546 # 80018338 <itable>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	5f2080e7          	jalr	1522(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000356a:	00015497          	auipc	s1,0x15
    8000356e:	df648493          	addi	s1,s1,-522 # 80018360 <itable+0x28>
    80003572:	00017997          	auipc	s3,0x17
    80003576:	87e98993          	addi	s3,s3,-1922 # 80019df0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000357a:	00005917          	auipc	s2,0x5
    8000357e:	03e90913          	addi	s2,s2,62 # 800085b8 <syscalls+0x170>
    80003582:	85ca                	mv	a1,s2
    80003584:	8526                	mv	a0,s1
    80003586:	00001097          	auipc	ra,0x1
    8000358a:	e46080e7          	jalr	-442(ra) # 800043cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000358e:	08848493          	addi	s1,s1,136
    80003592:	ff3498e3          	bne	s1,s3,80003582 <iinit+0x3e>
}
    80003596:	70a2                	ld	ra,40(sp)
    80003598:	7402                	ld	s0,32(sp)
    8000359a:	64e2                	ld	s1,24(sp)
    8000359c:	6942                	ld	s2,16(sp)
    8000359e:	69a2                	ld	s3,8(sp)
    800035a0:	6145                	addi	sp,sp,48
    800035a2:	8082                	ret

00000000800035a4 <ialloc>:
{
    800035a4:	715d                	addi	sp,sp,-80
    800035a6:	e486                	sd	ra,72(sp)
    800035a8:	e0a2                	sd	s0,64(sp)
    800035aa:	fc26                	sd	s1,56(sp)
    800035ac:	f84a                	sd	s2,48(sp)
    800035ae:	f44e                	sd	s3,40(sp)
    800035b0:	f052                	sd	s4,32(sp)
    800035b2:	ec56                	sd	s5,24(sp)
    800035b4:	e85a                	sd	s6,16(sp)
    800035b6:	e45e                	sd	s7,8(sp)
    800035b8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ba:	00015717          	auipc	a4,0x15
    800035be:	d6a72703          	lw	a4,-662(a4) # 80018324 <sb+0xc>
    800035c2:	4785                	li	a5,1
    800035c4:	04e7fa63          	bgeu	a5,a4,80003618 <ialloc+0x74>
    800035c8:	8aaa                	mv	s5,a0
    800035ca:	8bae                	mv	s7,a1
    800035cc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035ce:	00015a17          	auipc	s4,0x15
    800035d2:	d4aa0a13          	addi	s4,s4,-694 # 80018318 <sb>
    800035d6:	00048b1b          	sext.w	s6,s1
    800035da:	0044d593          	srli	a1,s1,0x4
    800035de:	018a2783          	lw	a5,24(s4)
    800035e2:	9dbd                	addw	a1,a1,a5
    800035e4:	8556                	mv	a0,s5
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	954080e7          	jalr	-1708(ra) # 80002f3a <bread>
    800035ee:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035f0:	05850993          	addi	s3,a0,88
    800035f4:	00f4f793          	andi	a5,s1,15
    800035f8:	079a                	slli	a5,a5,0x6
    800035fa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035fc:	00099783          	lh	a5,0(s3)
    80003600:	c785                	beqz	a5,80003628 <ialloc+0x84>
    brelse(bp);
    80003602:	00000097          	auipc	ra,0x0
    80003606:	a68080e7          	jalr	-1432(ra) # 8000306a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360a:	0485                	addi	s1,s1,1
    8000360c:	00ca2703          	lw	a4,12(s4)
    80003610:	0004879b          	sext.w	a5,s1
    80003614:	fce7e1e3          	bltu	a5,a4,800035d6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	fa850513          	addi	a0,a0,-88 # 800085c0 <syscalls+0x178>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003628:	04000613          	li	a2,64
    8000362c:	4581                	li	a1,0
    8000362e:	854e                	mv	a0,s3
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	6b0080e7          	jalr	1712(ra) # 80000ce0 <memset>
      dip->type = type;
    80003638:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000363c:	854a                	mv	a0,s2
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	ca8080e7          	jalr	-856(ra) # 800042e6 <log_write>
      brelse(bp);
    80003646:	854a                	mv	a0,s2
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	a22080e7          	jalr	-1502(ra) # 8000306a <brelse>
      return iget(dev, inum);
    80003650:	85da                	mv	a1,s6
    80003652:	8556                	mv	a0,s5
    80003654:	00000097          	auipc	ra,0x0
    80003658:	db4080e7          	jalr	-588(ra) # 80003408 <iget>
}
    8000365c:	60a6                	ld	ra,72(sp)
    8000365e:	6406                	ld	s0,64(sp)
    80003660:	74e2                	ld	s1,56(sp)
    80003662:	7942                	ld	s2,48(sp)
    80003664:	79a2                	ld	s3,40(sp)
    80003666:	7a02                	ld	s4,32(sp)
    80003668:	6ae2                	ld	s5,24(sp)
    8000366a:	6b42                	ld	s6,16(sp)
    8000366c:	6ba2                	ld	s7,8(sp)
    8000366e:	6161                	addi	sp,sp,80
    80003670:	8082                	ret

0000000080003672 <iupdate>:
{
    80003672:	1101                	addi	sp,sp,-32
    80003674:	ec06                	sd	ra,24(sp)
    80003676:	e822                	sd	s0,16(sp)
    80003678:	e426                	sd	s1,8(sp)
    8000367a:	e04a                	sd	s2,0(sp)
    8000367c:	1000                	addi	s0,sp,32
    8000367e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003680:	415c                	lw	a5,4(a0)
    80003682:	0047d79b          	srliw	a5,a5,0x4
    80003686:	00015597          	auipc	a1,0x15
    8000368a:	caa5a583          	lw	a1,-854(a1) # 80018330 <sb+0x18>
    8000368e:	9dbd                	addw	a1,a1,a5
    80003690:	4108                	lw	a0,0(a0)
    80003692:	00000097          	auipc	ra,0x0
    80003696:	8a8080e7          	jalr	-1880(ra) # 80002f3a <bread>
    8000369a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000369c:	05850793          	addi	a5,a0,88
    800036a0:	40c8                	lw	a0,4(s1)
    800036a2:	893d                	andi	a0,a0,15
    800036a4:	051a                	slli	a0,a0,0x6
    800036a6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036a8:	04449703          	lh	a4,68(s1)
    800036ac:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036b0:	04649703          	lh	a4,70(s1)
    800036b4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036b8:	04849703          	lh	a4,72(s1)
    800036bc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036c0:	04a49703          	lh	a4,74(s1)
    800036c4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036c8:	44f8                	lw	a4,76(s1)
    800036ca:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036cc:	03400613          	li	a2,52
    800036d0:	05048593          	addi	a1,s1,80
    800036d4:	0531                	addi	a0,a0,12
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	66a080e7          	jalr	1642(ra) # 80000d40 <memmove>
  log_write(bp);
    800036de:	854a                	mv	a0,s2
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	c06080e7          	jalr	-1018(ra) # 800042e6 <log_write>
  brelse(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	980080e7          	jalr	-1664(ra) # 8000306a <brelse>
}
    800036f2:	60e2                	ld	ra,24(sp)
    800036f4:	6442                	ld	s0,16(sp)
    800036f6:	64a2                	ld	s1,8(sp)
    800036f8:	6902                	ld	s2,0(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret

00000000800036fe <idup>:
{
    800036fe:	1101                	addi	sp,sp,-32
    80003700:	ec06                	sd	ra,24(sp)
    80003702:	e822                	sd	s0,16(sp)
    80003704:	e426                	sd	s1,8(sp)
    80003706:	1000                	addi	s0,sp,32
    80003708:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000370a:	00015517          	auipc	a0,0x15
    8000370e:	c2e50513          	addi	a0,a0,-978 # 80018338 <itable>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	4d2080e7          	jalr	1234(ra) # 80000be4 <acquire>
  ip->ref++;
    8000371a:	449c                	lw	a5,8(s1)
    8000371c:	2785                	addiw	a5,a5,1
    8000371e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003720:	00015517          	auipc	a0,0x15
    80003724:	c1850513          	addi	a0,a0,-1000 # 80018338 <itable>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
}
    80003730:	8526                	mv	a0,s1
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	64a2                	ld	s1,8(sp)
    80003738:	6105                	addi	sp,sp,32
    8000373a:	8082                	ret

000000008000373c <ilock>:
{
    8000373c:	1101                	addi	sp,sp,-32
    8000373e:	ec06                	sd	ra,24(sp)
    80003740:	e822                	sd	s0,16(sp)
    80003742:	e426                	sd	s1,8(sp)
    80003744:	e04a                	sd	s2,0(sp)
    80003746:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003748:	c115                	beqz	a0,8000376c <ilock+0x30>
    8000374a:	84aa                	mv	s1,a0
    8000374c:	451c                	lw	a5,8(a0)
    8000374e:	00f05f63          	blez	a5,8000376c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003752:	0541                	addi	a0,a0,16
    80003754:	00001097          	auipc	ra,0x1
    80003758:	cb2080e7          	jalr	-846(ra) # 80004406 <acquiresleep>
  if(ip->valid == 0){
    8000375c:	40bc                	lw	a5,64(s1)
    8000375e:	cf99                	beqz	a5,8000377c <ilock+0x40>
}
    80003760:	60e2                	ld	ra,24(sp)
    80003762:	6442                	ld	s0,16(sp)
    80003764:	64a2                	ld	s1,8(sp)
    80003766:	6902                	ld	s2,0(sp)
    80003768:	6105                	addi	sp,sp,32
    8000376a:	8082                	ret
    panic("ilock");
    8000376c:	00005517          	auipc	a0,0x5
    80003770:	e6c50513          	addi	a0,a0,-404 # 800085d8 <syscalls+0x190>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377c:	40dc                	lw	a5,4(s1)
    8000377e:	0047d79b          	srliw	a5,a5,0x4
    80003782:	00015597          	auipc	a1,0x15
    80003786:	bae5a583          	lw	a1,-1106(a1) # 80018330 <sb+0x18>
    8000378a:	9dbd                	addw	a1,a1,a5
    8000378c:	4088                	lw	a0,0(s1)
    8000378e:	fffff097          	auipc	ra,0xfffff
    80003792:	7ac080e7          	jalr	1964(ra) # 80002f3a <bread>
    80003796:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003798:	05850593          	addi	a1,a0,88
    8000379c:	40dc                	lw	a5,4(s1)
    8000379e:	8bbd                	andi	a5,a5,15
    800037a0:	079a                	slli	a5,a5,0x6
    800037a2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a4:	00059783          	lh	a5,0(a1)
    800037a8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ac:	00259783          	lh	a5,2(a1)
    800037b0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b4:	00459783          	lh	a5,4(a1)
    800037b8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037bc:	00659783          	lh	a5,6(a1)
    800037c0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c4:	459c                	lw	a5,8(a1)
    800037c6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037c8:	03400613          	li	a2,52
    800037cc:	05b1                	addi	a1,a1,12
    800037ce:	05048513          	addi	a0,s1,80
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	56e080e7          	jalr	1390(ra) # 80000d40 <memmove>
    brelse(bp);
    800037da:	854a                	mv	a0,s2
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	88e080e7          	jalr	-1906(ra) # 8000306a <brelse>
    ip->valid = 1;
    800037e4:	4785                	li	a5,1
    800037e6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037e8:	04449783          	lh	a5,68(s1)
    800037ec:	fbb5                	bnez	a5,80003760 <ilock+0x24>
      panic("ilock: no type");
    800037ee:	00005517          	auipc	a0,0x5
    800037f2:	df250513          	addi	a0,a0,-526 # 800085e0 <syscalls+0x198>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>

00000000800037fe <iunlock>:
{
    800037fe:	1101                	addi	sp,sp,-32
    80003800:	ec06                	sd	ra,24(sp)
    80003802:	e822                	sd	s0,16(sp)
    80003804:	e426                	sd	s1,8(sp)
    80003806:	e04a                	sd	s2,0(sp)
    80003808:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000380a:	c905                	beqz	a0,8000383a <iunlock+0x3c>
    8000380c:	84aa                	mv	s1,a0
    8000380e:	01050913          	addi	s2,a0,16
    80003812:	854a                	mv	a0,s2
    80003814:	00001097          	auipc	ra,0x1
    80003818:	c8c080e7          	jalr	-884(ra) # 800044a0 <holdingsleep>
    8000381c:	cd19                	beqz	a0,8000383a <iunlock+0x3c>
    8000381e:	449c                	lw	a5,8(s1)
    80003820:	00f05d63          	blez	a5,8000383a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003824:	854a                	mv	a0,s2
    80003826:	00001097          	auipc	ra,0x1
    8000382a:	c36080e7          	jalr	-970(ra) # 8000445c <releasesleep>
}
    8000382e:	60e2                	ld	ra,24(sp)
    80003830:	6442                	ld	s0,16(sp)
    80003832:	64a2                	ld	s1,8(sp)
    80003834:	6902                	ld	s2,0(sp)
    80003836:	6105                	addi	sp,sp,32
    80003838:	8082                	ret
    panic("iunlock");
    8000383a:	00005517          	auipc	a0,0x5
    8000383e:	db650513          	addi	a0,a0,-586 # 800085f0 <syscalls+0x1a8>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	cfc080e7          	jalr	-772(ra) # 8000053e <panic>

000000008000384a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000384a:	7179                	addi	sp,sp,-48
    8000384c:	f406                	sd	ra,40(sp)
    8000384e:	f022                	sd	s0,32(sp)
    80003850:	ec26                	sd	s1,24(sp)
    80003852:	e84a                	sd	s2,16(sp)
    80003854:	e44e                	sd	s3,8(sp)
    80003856:	e052                	sd	s4,0(sp)
    80003858:	1800                	addi	s0,sp,48
    8000385a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000385c:	05050493          	addi	s1,a0,80
    80003860:	08050913          	addi	s2,a0,128
    80003864:	a021                	j	8000386c <itrunc+0x22>
    80003866:	0491                	addi	s1,s1,4
    80003868:	01248d63          	beq	s1,s2,80003882 <itrunc+0x38>
    if(ip->addrs[i]){
    8000386c:	408c                	lw	a1,0(s1)
    8000386e:	dde5                	beqz	a1,80003866 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003870:	0009a503          	lw	a0,0(s3)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	90c080e7          	jalr	-1780(ra) # 80003180 <bfree>
      ip->addrs[i] = 0;
    8000387c:	0004a023          	sw	zero,0(s1)
    80003880:	b7dd                	j	80003866 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003882:	0809a583          	lw	a1,128(s3)
    80003886:	e185                	bnez	a1,800038a6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003888:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000388c:	854e                	mv	a0,s3
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	de4080e7          	jalr	-540(ra) # 80003672 <iupdate>
}
    80003896:	70a2                	ld	ra,40(sp)
    80003898:	7402                	ld	s0,32(sp)
    8000389a:	64e2                	ld	s1,24(sp)
    8000389c:	6942                	ld	s2,16(sp)
    8000389e:	69a2                	ld	s3,8(sp)
    800038a0:	6a02                	ld	s4,0(sp)
    800038a2:	6145                	addi	sp,sp,48
    800038a4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a6:	0009a503          	lw	a0,0(s3)
    800038aa:	fffff097          	auipc	ra,0xfffff
    800038ae:	690080e7          	jalr	1680(ra) # 80002f3a <bread>
    800038b2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b4:	05850493          	addi	s1,a0,88
    800038b8:	45850913          	addi	s2,a0,1112
    800038bc:	a811                	j	800038d0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038be:	0009a503          	lw	a0,0(s3)
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	8be080e7          	jalr	-1858(ra) # 80003180 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038ca:	0491                	addi	s1,s1,4
    800038cc:	01248563          	beq	s1,s2,800038d6 <itrunc+0x8c>
      if(a[j])
    800038d0:	408c                	lw	a1,0(s1)
    800038d2:	dde5                	beqz	a1,800038ca <itrunc+0x80>
    800038d4:	b7ed                	j	800038be <itrunc+0x74>
    brelse(bp);
    800038d6:	8552                	mv	a0,s4
    800038d8:	fffff097          	auipc	ra,0xfffff
    800038dc:	792080e7          	jalr	1938(ra) # 8000306a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038e0:	0809a583          	lw	a1,128(s3)
    800038e4:	0009a503          	lw	a0,0(s3)
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	898080e7          	jalr	-1896(ra) # 80003180 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038f0:	0809a023          	sw	zero,128(s3)
    800038f4:	bf51                	j	80003888 <itrunc+0x3e>

00000000800038f6 <iput>:
{
    800038f6:	1101                	addi	sp,sp,-32
    800038f8:	ec06                	sd	ra,24(sp)
    800038fa:	e822                	sd	s0,16(sp)
    800038fc:	e426                	sd	s1,8(sp)
    800038fe:	e04a                	sd	s2,0(sp)
    80003900:	1000                	addi	s0,sp,32
    80003902:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003904:	00015517          	auipc	a0,0x15
    80003908:	a3450513          	addi	a0,a0,-1484 # 80018338 <itable>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	2d8080e7          	jalr	728(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003914:	4498                	lw	a4,8(s1)
    80003916:	4785                	li	a5,1
    80003918:	02f70363          	beq	a4,a5,8000393e <iput+0x48>
  ip->ref--;
    8000391c:	449c                	lw	a5,8(s1)
    8000391e:	37fd                	addiw	a5,a5,-1
    80003920:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003922:	00015517          	auipc	a0,0x15
    80003926:	a1650513          	addi	a0,a0,-1514 # 80018338 <itable>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	36e080e7          	jalr	878(ra) # 80000c98 <release>
}
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6902                	ld	s2,0(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393e:	40bc                	lw	a5,64(s1)
    80003940:	dff1                	beqz	a5,8000391c <iput+0x26>
    80003942:	04a49783          	lh	a5,74(s1)
    80003946:	fbf9                	bnez	a5,8000391c <iput+0x26>
    acquiresleep(&ip->lock);
    80003948:	01048913          	addi	s2,s1,16
    8000394c:	854a                	mv	a0,s2
    8000394e:	00001097          	auipc	ra,0x1
    80003952:	ab8080e7          	jalr	-1352(ra) # 80004406 <acquiresleep>
    release(&itable.lock);
    80003956:	00015517          	auipc	a0,0x15
    8000395a:	9e250513          	addi	a0,a0,-1566 # 80018338 <itable>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	33a080e7          	jalr	826(ra) # 80000c98 <release>
    itrunc(ip);
    80003966:	8526                	mv	a0,s1
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	ee2080e7          	jalr	-286(ra) # 8000384a <itrunc>
    ip->type = 0;
    80003970:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003974:	8526                	mv	a0,s1
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	cfc080e7          	jalr	-772(ra) # 80003672 <iupdate>
    ip->valid = 0;
    8000397e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003982:	854a                	mv	a0,s2
    80003984:	00001097          	auipc	ra,0x1
    80003988:	ad8080e7          	jalr	-1320(ra) # 8000445c <releasesleep>
    acquire(&itable.lock);
    8000398c:	00015517          	auipc	a0,0x15
    80003990:	9ac50513          	addi	a0,a0,-1620 # 80018338 <itable>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	250080e7          	jalr	592(ra) # 80000be4 <acquire>
    8000399c:	b741                	j	8000391c <iput+0x26>

000000008000399e <iunlockput>:
{
    8000399e:	1101                	addi	sp,sp,-32
    800039a0:	ec06                	sd	ra,24(sp)
    800039a2:	e822                	sd	s0,16(sp)
    800039a4:	e426                	sd	s1,8(sp)
    800039a6:	1000                	addi	s0,sp,32
    800039a8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	e54080e7          	jalr	-428(ra) # 800037fe <iunlock>
  iput(ip);
    800039b2:	8526                	mv	a0,s1
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	f42080e7          	jalr	-190(ra) # 800038f6 <iput>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6105                	addi	sp,sp,32
    800039c4:	8082                	ret

00000000800039c6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c6:	1141                	addi	sp,sp,-16
    800039c8:	e422                	sd	s0,8(sp)
    800039ca:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039cc:	411c                	lw	a5,0(a0)
    800039ce:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039d0:	415c                	lw	a5,4(a0)
    800039d2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d4:	04451783          	lh	a5,68(a0)
    800039d8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039dc:	04a51783          	lh	a5,74(a0)
    800039e0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e4:	04c56783          	lwu	a5,76(a0)
    800039e8:	e99c                	sd	a5,16(a1)
}
    800039ea:	6422                	ld	s0,8(sp)
    800039ec:	0141                	addi	sp,sp,16
    800039ee:	8082                	ret

00000000800039f0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f0:	457c                	lw	a5,76(a0)
    800039f2:	0ed7e963          	bltu	a5,a3,80003ae4 <readi+0xf4>
{
    800039f6:	7159                	addi	sp,sp,-112
    800039f8:	f486                	sd	ra,104(sp)
    800039fa:	f0a2                	sd	s0,96(sp)
    800039fc:	eca6                	sd	s1,88(sp)
    800039fe:	e8ca                	sd	s2,80(sp)
    80003a00:	e4ce                	sd	s3,72(sp)
    80003a02:	e0d2                	sd	s4,64(sp)
    80003a04:	fc56                	sd	s5,56(sp)
    80003a06:	f85a                	sd	s6,48(sp)
    80003a08:	f45e                	sd	s7,40(sp)
    80003a0a:	f062                	sd	s8,32(sp)
    80003a0c:	ec66                	sd	s9,24(sp)
    80003a0e:	e86a                	sd	s10,16(sp)
    80003a10:	e46e                	sd	s11,8(sp)
    80003a12:	1880                	addi	s0,sp,112
    80003a14:	8baa                	mv	s7,a0
    80003a16:	8c2e                	mv	s8,a1
    80003a18:	8ab2                	mv	s5,a2
    80003a1a:	84b6                	mv	s1,a3
    80003a1c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a1e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a20:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a22:	0ad76063          	bltu	a4,a3,80003ac2 <readi+0xd2>
  if(off + n > ip->size)
    80003a26:	00e7f463          	bgeu	a5,a4,80003a2e <readi+0x3e>
    n = ip->size - off;
    80003a2a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2e:	0a0b0963          	beqz	s6,80003ae0 <readi+0xf0>
    80003a32:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a34:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a38:	5cfd                	li	s9,-1
    80003a3a:	a82d                	j	80003a74 <readi+0x84>
    80003a3c:	020a1d93          	slli	s11,s4,0x20
    80003a40:	020ddd93          	srli	s11,s11,0x20
    80003a44:	05890613          	addi	a2,s2,88
    80003a48:	86ee                	mv	a3,s11
    80003a4a:	963a                	add	a2,a2,a4
    80003a4c:	85d6                	mv	a1,s5
    80003a4e:	8562                	mv	a0,s8
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	aae080e7          	jalr	-1362(ra) # 800024fe <either_copyout>
    80003a58:	05950d63          	beq	a0,s9,80003ab2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	60c080e7          	jalr	1548(ra) # 8000306a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a66:	013a09bb          	addw	s3,s4,s3
    80003a6a:	009a04bb          	addw	s1,s4,s1
    80003a6e:	9aee                	add	s5,s5,s11
    80003a70:	0569f763          	bgeu	s3,s6,80003abe <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a74:	000ba903          	lw	s2,0(s7)
    80003a78:	00a4d59b          	srliw	a1,s1,0xa
    80003a7c:	855e                	mv	a0,s7
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	8b0080e7          	jalr	-1872(ra) # 8000332e <bmap>
    80003a86:	0005059b          	sext.w	a1,a0
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	4ae080e7          	jalr	1198(ra) # 80002f3a <bread>
    80003a94:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a96:	3ff4f713          	andi	a4,s1,1023
    80003a9a:	40ed07bb          	subw	a5,s10,a4
    80003a9e:	413b06bb          	subw	a3,s6,s3
    80003aa2:	8a3e                	mv	s4,a5
    80003aa4:	2781                	sext.w	a5,a5
    80003aa6:	0006861b          	sext.w	a2,a3
    80003aaa:	f8f679e3          	bgeu	a2,a5,80003a3c <readi+0x4c>
    80003aae:	8a36                	mv	s4,a3
    80003ab0:	b771                	j	80003a3c <readi+0x4c>
      brelse(bp);
    80003ab2:	854a                	mv	a0,s2
    80003ab4:	fffff097          	auipc	ra,0xfffff
    80003ab8:	5b6080e7          	jalr	1462(ra) # 8000306a <brelse>
      tot = -1;
    80003abc:	59fd                	li	s3,-1
  }
  return tot;
    80003abe:	0009851b          	sext.w	a0,s3
}
    80003ac2:	70a6                	ld	ra,104(sp)
    80003ac4:	7406                	ld	s0,96(sp)
    80003ac6:	64e6                	ld	s1,88(sp)
    80003ac8:	6946                	ld	s2,80(sp)
    80003aca:	69a6                	ld	s3,72(sp)
    80003acc:	6a06                	ld	s4,64(sp)
    80003ace:	7ae2                	ld	s5,56(sp)
    80003ad0:	7b42                	ld	s6,48(sp)
    80003ad2:	7ba2                	ld	s7,40(sp)
    80003ad4:	7c02                	ld	s8,32(sp)
    80003ad6:	6ce2                	ld	s9,24(sp)
    80003ad8:	6d42                	ld	s10,16(sp)
    80003ada:	6da2                	ld	s11,8(sp)
    80003adc:	6165                	addi	sp,sp,112
    80003ade:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae0:	89da                	mv	s3,s6
    80003ae2:	bff1                	j	80003abe <readi+0xce>
    return 0;
    80003ae4:	4501                	li	a0,0
}
    80003ae6:	8082                	ret

0000000080003ae8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae8:	457c                	lw	a5,76(a0)
    80003aea:	10d7e863          	bltu	a5,a3,80003bfa <writei+0x112>
{
    80003aee:	7159                	addi	sp,sp,-112
    80003af0:	f486                	sd	ra,104(sp)
    80003af2:	f0a2                	sd	s0,96(sp)
    80003af4:	eca6                	sd	s1,88(sp)
    80003af6:	e8ca                	sd	s2,80(sp)
    80003af8:	e4ce                	sd	s3,72(sp)
    80003afa:	e0d2                	sd	s4,64(sp)
    80003afc:	fc56                	sd	s5,56(sp)
    80003afe:	f85a                	sd	s6,48(sp)
    80003b00:	f45e                	sd	s7,40(sp)
    80003b02:	f062                	sd	s8,32(sp)
    80003b04:	ec66                	sd	s9,24(sp)
    80003b06:	e86a                	sd	s10,16(sp)
    80003b08:	e46e                	sd	s11,8(sp)
    80003b0a:	1880                	addi	s0,sp,112
    80003b0c:	8b2a                	mv	s6,a0
    80003b0e:	8c2e                	mv	s8,a1
    80003b10:	8ab2                	mv	s5,a2
    80003b12:	8936                	mv	s2,a3
    80003b14:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b16:	00e687bb          	addw	a5,a3,a4
    80003b1a:	0ed7e263          	bltu	a5,a3,80003bfe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1e:	00043737          	lui	a4,0x43
    80003b22:	0ef76063          	bltu	a4,a5,80003c02 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b26:	0c0b8863          	beqz	s7,80003bf6 <writei+0x10e>
    80003b2a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b30:	5cfd                	li	s9,-1
    80003b32:	a091                	j	80003b76 <writei+0x8e>
    80003b34:	02099d93          	slli	s11,s3,0x20
    80003b38:	020ddd93          	srli	s11,s11,0x20
    80003b3c:	05848513          	addi	a0,s1,88
    80003b40:	86ee                	mv	a3,s11
    80003b42:	8656                	mv	a2,s5
    80003b44:	85e2                	mv	a1,s8
    80003b46:	953a                	add	a0,a0,a4
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	a0c080e7          	jalr	-1524(ra) # 80002554 <either_copyin>
    80003b50:	07950263          	beq	a0,s9,80003bb4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b54:	8526                	mv	a0,s1
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	790080e7          	jalr	1936(ra) # 800042e6 <log_write>
    brelse(bp);
    80003b5e:	8526                	mv	a0,s1
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	50a080e7          	jalr	1290(ra) # 8000306a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b68:	01498a3b          	addw	s4,s3,s4
    80003b6c:	0129893b          	addw	s2,s3,s2
    80003b70:	9aee                	add	s5,s5,s11
    80003b72:	057a7663          	bgeu	s4,s7,80003bbe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b76:	000b2483          	lw	s1,0(s6)
    80003b7a:	00a9559b          	srliw	a1,s2,0xa
    80003b7e:	855a                	mv	a0,s6
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	7ae080e7          	jalr	1966(ra) # 8000332e <bmap>
    80003b88:	0005059b          	sext.w	a1,a0
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	fffff097          	auipc	ra,0xfffff
    80003b92:	3ac080e7          	jalr	940(ra) # 80002f3a <bread>
    80003b96:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b98:	3ff97713          	andi	a4,s2,1023
    80003b9c:	40ed07bb          	subw	a5,s10,a4
    80003ba0:	414b86bb          	subw	a3,s7,s4
    80003ba4:	89be                	mv	s3,a5
    80003ba6:	2781                	sext.w	a5,a5
    80003ba8:	0006861b          	sext.w	a2,a3
    80003bac:	f8f674e3          	bgeu	a2,a5,80003b34 <writei+0x4c>
    80003bb0:	89b6                	mv	s3,a3
    80003bb2:	b749                	j	80003b34 <writei+0x4c>
      brelse(bp);
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	4b4080e7          	jalr	1204(ra) # 8000306a <brelse>
  }

  if(off > ip->size)
    80003bbe:	04cb2783          	lw	a5,76(s6)
    80003bc2:	0127f463          	bgeu	a5,s2,80003bca <writei+0xe2>
    ip->size = off;
    80003bc6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bca:	855a                	mv	a0,s6
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	aa6080e7          	jalr	-1370(ra) # 80003672 <iupdate>

  return tot;
    80003bd4:	000a051b          	sext.w	a0,s4
}
    80003bd8:	70a6                	ld	ra,104(sp)
    80003bda:	7406                	ld	s0,96(sp)
    80003bdc:	64e6                	ld	s1,88(sp)
    80003bde:	6946                	ld	s2,80(sp)
    80003be0:	69a6                	ld	s3,72(sp)
    80003be2:	6a06                	ld	s4,64(sp)
    80003be4:	7ae2                	ld	s5,56(sp)
    80003be6:	7b42                	ld	s6,48(sp)
    80003be8:	7ba2                	ld	s7,40(sp)
    80003bea:	7c02                	ld	s8,32(sp)
    80003bec:	6ce2                	ld	s9,24(sp)
    80003bee:	6d42                	ld	s10,16(sp)
    80003bf0:	6da2                	ld	s11,8(sp)
    80003bf2:	6165                	addi	sp,sp,112
    80003bf4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf6:	8a5e                	mv	s4,s7
    80003bf8:	bfc9                	j	80003bca <writei+0xe2>
    return -1;
    80003bfa:	557d                	li	a0,-1
}
    80003bfc:	8082                	ret
    return -1;
    80003bfe:	557d                	li	a0,-1
    80003c00:	bfe1                	j	80003bd8 <writei+0xf0>
    return -1;
    80003c02:	557d                	li	a0,-1
    80003c04:	bfd1                	j	80003bd8 <writei+0xf0>

0000000080003c06 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c06:	1141                	addi	sp,sp,-16
    80003c08:	e406                	sd	ra,8(sp)
    80003c0a:	e022                	sd	s0,0(sp)
    80003c0c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c0e:	4639                	li	a2,14
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	1a8080e7          	jalr	424(ra) # 80000db8 <strncmp>
}
    80003c18:	60a2                	ld	ra,8(sp)
    80003c1a:	6402                	ld	s0,0(sp)
    80003c1c:	0141                	addi	sp,sp,16
    80003c1e:	8082                	ret

0000000080003c20 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c20:	7139                	addi	sp,sp,-64
    80003c22:	fc06                	sd	ra,56(sp)
    80003c24:	f822                	sd	s0,48(sp)
    80003c26:	f426                	sd	s1,40(sp)
    80003c28:	f04a                	sd	s2,32(sp)
    80003c2a:	ec4e                	sd	s3,24(sp)
    80003c2c:	e852                	sd	s4,16(sp)
    80003c2e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c30:	04451703          	lh	a4,68(a0)
    80003c34:	4785                	li	a5,1
    80003c36:	00f71a63          	bne	a4,a5,80003c4a <dirlookup+0x2a>
    80003c3a:	892a                	mv	s2,a0
    80003c3c:	89ae                	mv	s3,a1
    80003c3e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c40:	457c                	lw	a5,76(a0)
    80003c42:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c44:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c46:	e79d                	bnez	a5,80003c74 <dirlookup+0x54>
    80003c48:	a8a5                	j	80003cc0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c4a:	00005517          	auipc	a0,0x5
    80003c4e:	9ae50513          	addi	a0,a0,-1618 # 800085f8 <syscalls+0x1b0>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c5a:	00005517          	auipc	a0,0x5
    80003c5e:	9b650513          	addi	a0,a0,-1610 # 80008610 <syscalls+0x1c8>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	8dc080e7          	jalr	-1828(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c6a:	24c1                	addiw	s1,s1,16
    80003c6c:	04c92783          	lw	a5,76(s2)
    80003c70:	04f4f763          	bgeu	s1,a5,80003cbe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c74:	4741                	li	a4,16
    80003c76:	86a6                	mv	a3,s1
    80003c78:	fc040613          	addi	a2,s0,-64
    80003c7c:	4581                	li	a1,0
    80003c7e:	854a                	mv	a0,s2
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	d70080e7          	jalr	-656(ra) # 800039f0 <readi>
    80003c88:	47c1                	li	a5,16
    80003c8a:	fcf518e3          	bne	a0,a5,80003c5a <dirlookup+0x3a>
    if(de.inum == 0)
    80003c8e:	fc045783          	lhu	a5,-64(s0)
    80003c92:	dfe1                	beqz	a5,80003c6a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c94:	fc240593          	addi	a1,s0,-62
    80003c98:	854e                	mv	a0,s3
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	f6c080e7          	jalr	-148(ra) # 80003c06 <namecmp>
    80003ca2:	f561                	bnez	a0,80003c6a <dirlookup+0x4a>
      if(poff)
    80003ca4:	000a0463          	beqz	s4,80003cac <dirlookup+0x8c>
        *poff = off;
    80003ca8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cac:	fc045583          	lhu	a1,-64(s0)
    80003cb0:	00092503          	lw	a0,0(s2)
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	754080e7          	jalr	1876(ra) # 80003408 <iget>
    80003cbc:	a011                	j	80003cc0 <dirlookup+0xa0>
  return 0;
    80003cbe:	4501                	li	a0,0
}
    80003cc0:	70e2                	ld	ra,56(sp)
    80003cc2:	7442                	ld	s0,48(sp)
    80003cc4:	74a2                	ld	s1,40(sp)
    80003cc6:	7902                	ld	s2,32(sp)
    80003cc8:	69e2                	ld	s3,24(sp)
    80003cca:	6a42                	ld	s4,16(sp)
    80003ccc:	6121                	addi	sp,sp,64
    80003cce:	8082                	ret

0000000080003cd0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cd0:	711d                	addi	sp,sp,-96
    80003cd2:	ec86                	sd	ra,88(sp)
    80003cd4:	e8a2                	sd	s0,80(sp)
    80003cd6:	e4a6                	sd	s1,72(sp)
    80003cd8:	e0ca                	sd	s2,64(sp)
    80003cda:	fc4e                	sd	s3,56(sp)
    80003cdc:	f852                	sd	s4,48(sp)
    80003cde:	f456                	sd	s5,40(sp)
    80003ce0:	f05a                	sd	s6,32(sp)
    80003ce2:	ec5e                	sd	s7,24(sp)
    80003ce4:	e862                	sd	s8,16(sp)
    80003ce6:	e466                	sd	s9,8(sp)
    80003ce8:	1080                	addi	s0,sp,96
    80003cea:	84aa                	mv	s1,a0
    80003cec:	8b2e                	mv	s6,a1
    80003cee:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cf0:	00054703          	lbu	a4,0(a0)
    80003cf4:	02f00793          	li	a5,47
    80003cf8:	02f70363          	beq	a4,a5,80003d1e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cfc:	ffffe097          	auipc	ra,0xffffe
    80003d00:	cb4080e7          	jalr	-844(ra) # 800019b0 <myproc>
    80003d04:	15053503          	ld	a0,336(a0)
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	9f6080e7          	jalr	-1546(ra) # 800036fe <idup>
    80003d10:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d12:	02f00913          	li	s2,47
  len = path - s;
    80003d16:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d18:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d1a:	4c05                	li	s8,1
    80003d1c:	a865                	j	80003dd4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d1e:	4585                	li	a1,1
    80003d20:	4505                	li	a0,1
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	6e6080e7          	jalr	1766(ra) # 80003408 <iget>
    80003d2a:	89aa                	mv	s3,a0
    80003d2c:	b7dd                	j	80003d12 <namex+0x42>
      iunlockput(ip);
    80003d2e:	854e                	mv	a0,s3
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	c6e080e7          	jalr	-914(ra) # 8000399e <iunlockput>
      return 0;
    80003d38:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d3a:	854e                	mv	a0,s3
    80003d3c:	60e6                	ld	ra,88(sp)
    80003d3e:	6446                	ld	s0,80(sp)
    80003d40:	64a6                	ld	s1,72(sp)
    80003d42:	6906                	ld	s2,64(sp)
    80003d44:	79e2                	ld	s3,56(sp)
    80003d46:	7a42                	ld	s4,48(sp)
    80003d48:	7aa2                	ld	s5,40(sp)
    80003d4a:	7b02                	ld	s6,32(sp)
    80003d4c:	6be2                	ld	s7,24(sp)
    80003d4e:	6c42                	ld	s8,16(sp)
    80003d50:	6ca2                	ld	s9,8(sp)
    80003d52:	6125                	addi	sp,sp,96
    80003d54:	8082                	ret
      iunlock(ip);
    80003d56:	854e                	mv	a0,s3
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	aa6080e7          	jalr	-1370(ra) # 800037fe <iunlock>
      return ip;
    80003d60:	bfe9                	j	80003d3a <namex+0x6a>
      iunlockput(ip);
    80003d62:	854e                	mv	a0,s3
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	c3a080e7          	jalr	-966(ra) # 8000399e <iunlockput>
      return 0;
    80003d6c:	89d2                	mv	s3,s4
    80003d6e:	b7f1                	j	80003d3a <namex+0x6a>
  len = path - s;
    80003d70:	40b48633          	sub	a2,s1,a1
    80003d74:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d78:	094cd463          	bge	s9,s4,80003e00 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d7c:	4639                	li	a2,14
    80003d7e:	8556                	mv	a0,s5
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	fc0080e7          	jalr	-64(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d88:	0004c783          	lbu	a5,0(s1)
    80003d8c:	01279763          	bne	a5,s2,80003d9a <namex+0xca>
    path++;
    80003d90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d92:	0004c783          	lbu	a5,0(s1)
    80003d96:	ff278de3          	beq	a5,s2,80003d90 <namex+0xc0>
    ilock(ip);
    80003d9a:	854e                	mv	a0,s3
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	9a0080e7          	jalr	-1632(ra) # 8000373c <ilock>
    if(ip->type != T_DIR){
    80003da4:	04499783          	lh	a5,68(s3)
    80003da8:	f98793e3          	bne	a5,s8,80003d2e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dac:	000b0563          	beqz	s6,80003db6 <namex+0xe6>
    80003db0:	0004c783          	lbu	a5,0(s1)
    80003db4:	d3cd                	beqz	a5,80003d56 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003db6:	865e                	mv	a2,s7
    80003db8:	85d6                	mv	a1,s5
    80003dba:	854e                	mv	a0,s3
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	e64080e7          	jalr	-412(ra) # 80003c20 <dirlookup>
    80003dc4:	8a2a                	mv	s4,a0
    80003dc6:	dd51                	beqz	a0,80003d62 <namex+0x92>
    iunlockput(ip);
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	bd4080e7          	jalr	-1068(ra) # 8000399e <iunlockput>
    ip = next;
    80003dd2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dd4:	0004c783          	lbu	a5,0(s1)
    80003dd8:	05279763          	bne	a5,s2,80003e26 <namex+0x156>
    path++;
    80003ddc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dde:	0004c783          	lbu	a5,0(s1)
    80003de2:	ff278de3          	beq	a5,s2,80003ddc <namex+0x10c>
  if(*path == 0)
    80003de6:	c79d                	beqz	a5,80003e14 <namex+0x144>
    path++;
    80003de8:	85a6                	mv	a1,s1
  len = path - s;
    80003dea:	8a5e                	mv	s4,s7
    80003dec:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dee:	01278963          	beq	a5,s2,80003e00 <namex+0x130>
    80003df2:	dfbd                	beqz	a5,80003d70 <namex+0xa0>
    path++;
    80003df4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003df6:	0004c783          	lbu	a5,0(s1)
    80003dfa:	ff279ce3          	bne	a5,s2,80003df2 <namex+0x122>
    80003dfe:	bf8d                	j	80003d70 <namex+0xa0>
    memmove(name, s, len);
    80003e00:	2601                	sext.w	a2,a2
    80003e02:	8556                	mv	a0,s5
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	f3c080e7          	jalr	-196(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e0c:	9a56                	add	s4,s4,s5
    80003e0e:	000a0023          	sb	zero,0(s4)
    80003e12:	bf9d                	j	80003d88 <namex+0xb8>
  if(nameiparent){
    80003e14:	f20b03e3          	beqz	s6,80003d3a <namex+0x6a>
    iput(ip);
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	adc080e7          	jalr	-1316(ra) # 800038f6 <iput>
    return 0;
    80003e22:	4981                	li	s3,0
    80003e24:	bf19                	j	80003d3a <namex+0x6a>
  if(*path == 0)
    80003e26:	d7fd                	beqz	a5,80003e14 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e28:	0004c783          	lbu	a5,0(s1)
    80003e2c:	85a6                	mv	a1,s1
    80003e2e:	b7d1                	j	80003df2 <namex+0x122>

0000000080003e30 <dirlink>:
{
    80003e30:	7139                	addi	sp,sp,-64
    80003e32:	fc06                	sd	ra,56(sp)
    80003e34:	f822                	sd	s0,48(sp)
    80003e36:	f426                	sd	s1,40(sp)
    80003e38:	f04a                	sd	s2,32(sp)
    80003e3a:	ec4e                	sd	s3,24(sp)
    80003e3c:	e852                	sd	s4,16(sp)
    80003e3e:	0080                	addi	s0,sp,64
    80003e40:	892a                	mv	s2,a0
    80003e42:	8a2e                	mv	s4,a1
    80003e44:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e46:	4601                	li	a2,0
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	dd8080e7          	jalr	-552(ra) # 80003c20 <dirlookup>
    80003e50:	e93d                	bnez	a0,80003ec6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e52:	04c92483          	lw	s1,76(s2)
    80003e56:	c49d                	beqz	s1,80003e84 <dirlink+0x54>
    80003e58:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5a:	4741                	li	a4,16
    80003e5c:	86a6                	mv	a3,s1
    80003e5e:	fc040613          	addi	a2,s0,-64
    80003e62:	4581                	li	a1,0
    80003e64:	854a                	mv	a0,s2
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	b8a080e7          	jalr	-1142(ra) # 800039f0 <readi>
    80003e6e:	47c1                	li	a5,16
    80003e70:	06f51163          	bne	a0,a5,80003ed2 <dirlink+0xa2>
    if(de.inum == 0)
    80003e74:	fc045783          	lhu	a5,-64(s0)
    80003e78:	c791                	beqz	a5,80003e84 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7a:	24c1                	addiw	s1,s1,16
    80003e7c:	04c92783          	lw	a5,76(s2)
    80003e80:	fcf4ede3          	bltu	s1,a5,80003e5a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e84:	4639                	li	a2,14
    80003e86:	85d2                	mv	a1,s4
    80003e88:	fc240513          	addi	a0,s0,-62
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	f68080e7          	jalr	-152(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e94:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e98:	4741                	li	a4,16
    80003e9a:	86a6                	mv	a3,s1
    80003e9c:	fc040613          	addi	a2,s0,-64
    80003ea0:	4581                	li	a1,0
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	c44080e7          	jalr	-956(ra) # 80003ae8 <writei>
    80003eac:	872a                	mv	a4,a0
    80003eae:	47c1                	li	a5,16
  return 0;
    80003eb0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb2:	02f71863          	bne	a4,a5,80003ee2 <dirlink+0xb2>
}
    80003eb6:	70e2                	ld	ra,56(sp)
    80003eb8:	7442                	ld	s0,48(sp)
    80003eba:	74a2                	ld	s1,40(sp)
    80003ebc:	7902                	ld	s2,32(sp)
    80003ebe:	69e2                	ld	s3,24(sp)
    80003ec0:	6a42                	ld	s4,16(sp)
    80003ec2:	6121                	addi	sp,sp,64
    80003ec4:	8082                	ret
    iput(ip);
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	a30080e7          	jalr	-1488(ra) # 800038f6 <iput>
    return -1;
    80003ece:	557d                	li	a0,-1
    80003ed0:	b7dd                	j	80003eb6 <dirlink+0x86>
      panic("dirlink read");
    80003ed2:	00004517          	auipc	a0,0x4
    80003ed6:	74e50513          	addi	a0,a0,1870 # 80008620 <syscalls+0x1d8>
    80003eda:	ffffc097          	auipc	ra,0xffffc
    80003ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    panic("dirlink");
    80003ee2:	00005517          	auipc	a0,0x5
    80003ee6:	84e50513          	addi	a0,a0,-1970 # 80008730 <syscalls+0x2e8>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>

0000000080003ef2 <namei>:

struct inode*
namei(char *path)
{
    80003ef2:	1101                	addi	sp,sp,-32
    80003ef4:	ec06                	sd	ra,24(sp)
    80003ef6:	e822                	sd	s0,16(sp)
    80003ef8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003efa:	fe040613          	addi	a2,s0,-32
    80003efe:	4581                	li	a1,0
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	dd0080e7          	jalr	-560(ra) # 80003cd0 <namex>
}
    80003f08:	60e2                	ld	ra,24(sp)
    80003f0a:	6442                	ld	s0,16(sp)
    80003f0c:	6105                	addi	sp,sp,32
    80003f0e:	8082                	ret

0000000080003f10 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f10:	1141                	addi	sp,sp,-16
    80003f12:	e406                	sd	ra,8(sp)
    80003f14:	e022                	sd	s0,0(sp)
    80003f16:	0800                	addi	s0,sp,16
    80003f18:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f1a:	4585                	li	a1,1
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	db4080e7          	jalr	-588(ra) # 80003cd0 <namex>
}
    80003f24:	60a2                	ld	ra,8(sp)
    80003f26:	6402                	ld	s0,0(sp)
    80003f28:	0141                	addi	sp,sp,16
    80003f2a:	8082                	ret

0000000080003f2c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f2c:	1101                	addi	sp,sp,-32
    80003f2e:	ec06                	sd	ra,24(sp)
    80003f30:	e822                	sd	s0,16(sp)
    80003f32:	e426                	sd	s1,8(sp)
    80003f34:	e04a                	sd	s2,0(sp)
    80003f36:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f38:	00016917          	auipc	s2,0x16
    80003f3c:	ea890913          	addi	s2,s2,-344 # 80019de0 <log>
    80003f40:	01892583          	lw	a1,24(s2)
    80003f44:	02892503          	lw	a0,40(s2)
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	ff2080e7          	jalr	-14(ra) # 80002f3a <bread>
    80003f50:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f52:	02c92683          	lw	a3,44(s2)
    80003f56:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f58:	02d05763          	blez	a3,80003f86 <write_head+0x5a>
    80003f5c:	00016797          	auipc	a5,0x16
    80003f60:	eb478793          	addi	a5,a5,-332 # 80019e10 <log+0x30>
    80003f64:	05c50713          	addi	a4,a0,92
    80003f68:	36fd                	addiw	a3,a3,-1
    80003f6a:	1682                	slli	a3,a3,0x20
    80003f6c:	9281                	srli	a3,a3,0x20
    80003f6e:	068a                	slli	a3,a3,0x2
    80003f70:	00016617          	auipc	a2,0x16
    80003f74:	ea460613          	addi	a2,a2,-348 # 80019e14 <log+0x34>
    80003f78:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f7a:	4390                	lw	a2,0(a5)
    80003f7c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7e:	0791                	addi	a5,a5,4
    80003f80:	0711                	addi	a4,a4,4
    80003f82:	fed79ce3          	bne	a5,a3,80003f7a <write_head+0x4e>
  }
  bwrite(buf);
    80003f86:	8526                	mv	a0,s1
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	0a4080e7          	jalr	164(ra) # 8000302c <bwrite>
  brelse(buf);
    80003f90:	8526                	mv	a0,s1
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	0d8080e7          	jalr	216(ra) # 8000306a <brelse>
}
    80003f9a:	60e2                	ld	ra,24(sp)
    80003f9c:	6442                	ld	s0,16(sp)
    80003f9e:	64a2                	ld	s1,8(sp)
    80003fa0:	6902                	ld	s2,0(sp)
    80003fa2:	6105                	addi	sp,sp,32
    80003fa4:	8082                	ret

0000000080003fa6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa6:	00016797          	auipc	a5,0x16
    80003faa:	e667a783          	lw	a5,-410(a5) # 80019e0c <log+0x2c>
    80003fae:	0af05d63          	blez	a5,80004068 <install_trans+0xc2>
{
    80003fb2:	7139                	addi	sp,sp,-64
    80003fb4:	fc06                	sd	ra,56(sp)
    80003fb6:	f822                	sd	s0,48(sp)
    80003fb8:	f426                	sd	s1,40(sp)
    80003fba:	f04a                	sd	s2,32(sp)
    80003fbc:	ec4e                	sd	s3,24(sp)
    80003fbe:	e852                	sd	s4,16(sp)
    80003fc0:	e456                	sd	s5,8(sp)
    80003fc2:	e05a                	sd	s6,0(sp)
    80003fc4:	0080                	addi	s0,sp,64
    80003fc6:	8b2a                	mv	s6,a0
    80003fc8:	00016a97          	auipc	s5,0x16
    80003fcc:	e48a8a93          	addi	s5,s5,-440 # 80019e10 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd2:	00016997          	auipc	s3,0x16
    80003fd6:	e0e98993          	addi	s3,s3,-498 # 80019de0 <log>
    80003fda:	a035                	j	80004006 <install_trans+0x60>
      bunpin(dbuf);
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	166080e7          	jalr	358(ra) # 80003144 <bunpin>
    brelse(lbuf);
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	082080e7          	jalr	130(ra) # 8000306a <brelse>
    brelse(dbuf);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	078080e7          	jalr	120(ra) # 8000306a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffa:	2a05                	addiw	s4,s4,1
    80003ffc:	0a91                	addi	s5,s5,4
    80003ffe:	02c9a783          	lw	a5,44(s3)
    80004002:	04fa5963          	bge	s4,a5,80004054 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004006:	0189a583          	lw	a1,24(s3)
    8000400a:	014585bb          	addw	a1,a1,s4
    8000400e:	2585                	addiw	a1,a1,1
    80004010:	0289a503          	lw	a0,40(s3)
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	f26080e7          	jalr	-218(ra) # 80002f3a <bread>
    8000401c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401e:	000aa583          	lw	a1,0(s5)
    80004022:	0289a503          	lw	a0,40(s3)
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	f14080e7          	jalr	-236(ra) # 80002f3a <bread>
    8000402e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004030:	40000613          	li	a2,1024
    80004034:	05890593          	addi	a1,s2,88
    80004038:	05850513          	addi	a0,a0,88
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	d04080e7          	jalr	-764(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004044:	8526                	mv	a0,s1
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	fe6080e7          	jalr	-26(ra) # 8000302c <bwrite>
    if(recovering == 0)
    8000404e:	f80b1ce3          	bnez	s6,80003fe6 <install_trans+0x40>
    80004052:	b769                	j	80003fdc <install_trans+0x36>
}
    80004054:	70e2                	ld	ra,56(sp)
    80004056:	7442                	ld	s0,48(sp)
    80004058:	74a2                	ld	s1,40(sp)
    8000405a:	7902                	ld	s2,32(sp)
    8000405c:	69e2                	ld	s3,24(sp)
    8000405e:	6a42                	ld	s4,16(sp)
    80004060:	6aa2                	ld	s5,8(sp)
    80004062:	6b02                	ld	s6,0(sp)
    80004064:	6121                	addi	sp,sp,64
    80004066:	8082                	ret
    80004068:	8082                	ret

000000008000406a <initlog>:
{
    8000406a:	7179                	addi	sp,sp,-48
    8000406c:	f406                	sd	ra,40(sp)
    8000406e:	f022                	sd	s0,32(sp)
    80004070:	ec26                	sd	s1,24(sp)
    80004072:	e84a                	sd	s2,16(sp)
    80004074:	e44e                	sd	s3,8(sp)
    80004076:	1800                	addi	s0,sp,48
    80004078:	892a                	mv	s2,a0
    8000407a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407c:	00016497          	auipc	s1,0x16
    80004080:	d6448493          	addi	s1,s1,-668 # 80019de0 <log>
    80004084:	00004597          	auipc	a1,0x4
    80004088:	5ac58593          	addi	a1,a1,1452 # 80008630 <syscalls+0x1e8>
    8000408c:	8526                	mv	a0,s1
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	ac6080e7          	jalr	-1338(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004096:	0149a583          	lw	a1,20(s3)
    8000409a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409c:	0109a783          	lw	a5,16(s3)
    800040a0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a6:	854a                	mv	a0,s2
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	e92080e7          	jalr	-366(ra) # 80002f3a <bread>
  log.lh.n = lh->n;
    800040b0:	4d3c                	lw	a5,88(a0)
    800040b2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b4:	02f05563          	blez	a5,800040de <initlog+0x74>
    800040b8:	05c50713          	addi	a4,a0,92
    800040bc:	00016697          	auipc	a3,0x16
    800040c0:	d5468693          	addi	a3,a3,-684 # 80019e10 <log+0x30>
    800040c4:	37fd                	addiw	a5,a5,-1
    800040c6:	1782                	slli	a5,a5,0x20
    800040c8:	9381                	srli	a5,a5,0x20
    800040ca:	078a                	slli	a5,a5,0x2
    800040cc:	06050613          	addi	a2,a0,96
    800040d0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d2:	4310                	lw	a2,0(a4)
    800040d4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d6:	0711                	addi	a4,a4,4
    800040d8:	0691                	addi	a3,a3,4
    800040da:	fef71ce3          	bne	a4,a5,800040d2 <initlog+0x68>
  brelse(buf);
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	f8c080e7          	jalr	-116(ra) # 8000306a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040e6:	4505                	li	a0,1
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	ebe080e7          	jalr	-322(ra) # 80003fa6 <install_trans>
  log.lh.n = 0;
    800040f0:	00016797          	auipc	a5,0x16
    800040f4:	d007ae23          	sw	zero,-740(a5) # 80019e0c <log+0x2c>
  write_head(); // clear the log
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	e34080e7          	jalr	-460(ra) # 80003f2c <write_head>
}
    80004100:	70a2                	ld	ra,40(sp)
    80004102:	7402                	ld	s0,32(sp)
    80004104:	64e2                	ld	s1,24(sp)
    80004106:	6942                	ld	s2,16(sp)
    80004108:	69a2                	ld	s3,8(sp)
    8000410a:	6145                	addi	sp,sp,48
    8000410c:	8082                	ret

000000008000410e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	e426                	sd	s1,8(sp)
    80004116:	e04a                	sd	s2,0(sp)
    80004118:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000411a:	00016517          	auipc	a0,0x16
    8000411e:	cc650513          	addi	a0,a0,-826 # 80019de0 <log>
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	ac2080e7          	jalr	-1342(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000412a:	00016497          	auipc	s1,0x16
    8000412e:	cb648493          	addi	s1,s1,-842 # 80019de0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004132:	4979                	li	s2,30
    80004134:	a039                	j	80004142 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004136:	85a6                	mv	a1,s1
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffe097          	auipc	ra,0xffffe
    8000413e:	f74080e7          	jalr	-140(ra) # 800020ae <sleep>
    if(log.committing){
    80004142:	50dc                	lw	a5,36(s1)
    80004144:	fbed                	bnez	a5,80004136 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004146:	509c                	lw	a5,32(s1)
    80004148:	0017871b          	addiw	a4,a5,1
    8000414c:	0007069b          	sext.w	a3,a4
    80004150:	0027179b          	slliw	a5,a4,0x2
    80004154:	9fb9                	addw	a5,a5,a4
    80004156:	0017979b          	slliw	a5,a5,0x1
    8000415a:	54d8                	lw	a4,44(s1)
    8000415c:	9fb9                	addw	a5,a5,a4
    8000415e:	00f95963          	bge	s2,a5,80004170 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004162:	85a6                	mv	a1,s1
    80004164:	8526                	mv	a0,s1
    80004166:	ffffe097          	auipc	ra,0xffffe
    8000416a:	f48080e7          	jalr	-184(ra) # 800020ae <sleep>
    8000416e:	bfd1                	j	80004142 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004170:	00016517          	auipc	a0,0x16
    80004174:	c7050513          	addi	a0,a0,-912 # 80019de0 <log>
    80004178:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	b1e080e7          	jalr	-1250(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004182:	60e2                	ld	ra,24(sp)
    80004184:	6442                	ld	s0,16(sp)
    80004186:	64a2                	ld	s1,8(sp)
    80004188:	6902                	ld	s2,0(sp)
    8000418a:	6105                	addi	sp,sp,32
    8000418c:	8082                	ret

000000008000418e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418e:	7139                	addi	sp,sp,-64
    80004190:	fc06                	sd	ra,56(sp)
    80004192:	f822                	sd	s0,48(sp)
    80004194:	f426                	sd	s1,40(sp)
    80004196:	f04a                	sd	s2,32(sp)
    80004198:	ec4e                	sd	s3,24(sp)
    8000419a:	e852                	sd	s4,16(sp)
    8000419c:	e456                	sd	s5,8(sp)
    8000419e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041a0:	00016497          	auipc	s1,0x16
    800041a4:	c4048493          	addi	s1,s1,-960 # 80019de0 <log>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	a3a080e7          	jalr	-1478(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800041b2:	509c                	lw	a5,32(s1)
    800041b4:	37fd                	addiw	a5,a5,-1
    800041b6:	0007891b          	sext.w	s2,a5
    800041ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041bc:	50dc                	lw	a5,36(s1)
    800041be:	efb9                	bnez	a5,8000421c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041c0:	06091663          	bnez	s2,8000422c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c4:	00016497          	auipc	s1,0x16
    800041c8:	c1c48493          	addi	s1,s1,-996 # 80019de0 <log>
    800041cc:	4785                	li	a5,1
    800041ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041da:	54dc                	lw	a5,44(s1)
    800041dc:	06f04763          	bgtz	a5,8000424a <end_op+0xbc>
    acquire(&log.lock);
    800041e0:	00016497          	auipc	s1,0x16
    800041e4:	c0048493          	addi	s1,s1,-1024 # 80019de0 <log>
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	9fa080e7          	jalr	-1542(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	042080e7          	jalr	66(ra) # 8000223a <wakeup>
    release(&log.lock);
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	a96080e7          	jalr	-1386(ra) # 80000c98 <release>
}
    8000420a:	70e2                	ld	ra,56(sp)
    8000420c:	7442                	ld	s0,48(sp)
    8000420e:	74a2                	ld	s1,40(sp)
    80004210:	7902                	ld	s2,32(sp)
    80004212:	69e2                	ld	s3,24(sp)
    80004214:	6a42                	ld	s4,16(sp)
    80004216:	6aa2                	ld	s5,8(sp)
    80004218:	6121                	addi	sp,sp,64
    8000421a:	8082                	ret
    panic("log.committing");
    8000421c:	00004517          	auipc	a0,0x4
    80004220:	41c50513          	addi	a0,a0,1052 # 80008638 <syscalls+0x1f0>
    80004224:	ffffc097          	auipc	ra,0xffffc
    80004228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
    wakeup(&log);
    8000422c:	00016497          	auipc	s1,0x16
    80004230:	bb448493          	addi	s1,s1,-1100 # 80019de0 <log>
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	004080e7          	jalr	4(ra) # 8000223a <wakeup>
  release(&log.lock);
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
  if(do_commit){
    80004248:	b7c9                	j	8000420a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424a:	00016a97          	auipc	s5,0x16
    8000424e:	bc6a8a93          	addi	s5,s5,-1082 # 80019e10 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004252:	00016a17          	auipc	s4,0x16
    80004256:	b8ea0a13          	addi	s4,s4,-1138 # 80019de0 <log>
    8000425a:	018a2583          	lw	a1,24(s4)
    8000425e:	012585bb          	addw	a1,a1,s2
    80004262:	2585                	addiw	a1,a1,1
    80004264:	028a2503          	lw	a0,40(s4)
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	cd2080e7          	jalr	-814(ra) # 80002f3a <bread>
    80004270:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004272:	000aa583          	lw	a1,0(s5)
    80004276:	028a2503          	lw	a0,40(s4)
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	cc0080e7          	jalr	-832(ra) # 80002f3a <bread>
    80004282:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004284:	40000613          	li	a2,1024
    80004288:	05850593          	addi	a1,a0,88
    8000428c:	05848513          	addi	a0,s1,88
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	ab0080e7          	jalr	-1360(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	d92080e7          	jalr	-622(ra) # 8000302c <bwrite>
    brelse(from);
    800042a2:	854e                	mv	a0,s3
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	dc6080e7          	jalr	-570(ra) # 8000306a <brelse>
    brelse(to);
    800042ac:	8526                	mv	a0,s1
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	dbc080e7          	jalr	-580(ra) # 8000306a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b6:	2905                	addiw	s2,s2,1
    800042b8:	0a91                	addi	s5,s5,4
    800042ba:	02ca2783          	lw	a5,44(s4)
    800042be:	f8f94ee3          	blt	s2,a5,8000425a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	c6a080e7          	jalr	-918(ra) # 80003f2c <write_head>
    install_trans(0); // Now install writes to home locations
    800042ca:	4501                	li	a0,0
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	cda080e7          	jalr	-806(ra) # 80003fa6 <install_trans>
    log.lh.n = 0;
    800042d4:	00016797          	auipc	a5,0x16
    800042d8:	b207ac23          	sw	zero,-1224(a5) # 80019e0c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	c50080e7          	jalr	-944(ra) # 80003f2c <write_head>
    800042e4:	bdf5                	j	800041e0 <end_op+0x52>

00000000800042e6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	e426                	sd	s1,8(sp)
    800042ee:	e04a                	sd	s2,0(sp)
    800042f0:	1000                	addi	s0,sp,32
    800042f2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042f4:	00016917          	auipc	s2,0x16
    800042f8:	aec90913          	addi	s2,s2,-1300 # 80019de0 <log>
    800042fc:	854a                	mv	a0,s2
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	8e6080e7          	jalr	-1818(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004306:	02c92603          	lw	a2,44(s2)
    8000430a:	47f5                	li	a5,29
    8000430c:	06c7c563          	blt	a5,a2,80004376 <log_write+0x90>
    80004310:	00016797          	auipc	a5,0x16
    80004314:	aec7a783          	lw	a5,-1300(a5) # 80019dfc <log+0x1c>
    80004318:	37fd                	addiw	a5,a5,-1
    8000431a:	04f65e63          	bge	a2,a5,80004376 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000431e:	00016797          	auipc	a5,0x16
    80004322:	ae27a783          	lw	a5,-1310(a5) # 80019e00 <log+0x20>
    80004326:	06f05063          	blez	a5,80004386 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000432a:	4781                	li	a5,0
    8000432c:	06c05563          	blez	a2,80004396 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004330:	44cc                	lw	a1,12(s1)
    80004332:	00016717          	auipc	a4,0x16
    80004336:	ade70713          	addi	a4,a4,-1314 # 80019e10 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000433a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000433c:	4314                	lw	a3,0(a4)
    8000433e:	04b68c63          	beq	a3,a1,80004396 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004342:	2785                	addiw	a5,a5,1
    80004344:	0711                	addi	a4,a4,4
    80004346:	fef61be3          	bne	a2,a5,8000433c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000434a:	0621                	addi	a2,a2,8
    8000434c:	060a                	slli	a2,a2,0x2
    8000434e:	00016797          	auipc	a5,0x16
    80004352:	a9278793          	addi	a5,a5,-1390 # 80019de0 <log>
    80004356:	963e                	add	a2,a2,a5
    80004358:	44dc                	lw	a5,12(s1)
    8000435a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000435c:	8526                	mv	a0,s1
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	daa080e7          	jalr	-598(ra) # 80003108 <bpin>
    log.lh.n++;
    80004366:	00016717          	auipc	a4,0x16
    8000436a:	a7a70713          	addi	a4,a4,-1414 # 80019de0 <log>
    8000436e:	575c                	lw	a5,44(a4)
    80004370:	2785                	addiw	a5,a5,1
    80004372:	d75c                	sw	a5,44(a4)
    80004374:	a835                	j	800043b0 <log_write+0xca>
    panic("too big a transaction");
    80004376:	00004517          	auipc	a0,0x4
    8000437a:	2d250513          	addi	a0,a0,722 # 80008648 <syscalls+0x200>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	2da50513          	addi	a0,a0,730 # 80008660 <syscalls+0x218>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004396:	00878713          	addi	a4,a5,8
    8000439a:	00271693          	slli	a3,a4,0x2
    8000439e:	00016717          	auipc	a4,0x16
    800043a2:	a4270713          	addi	a4,a4,-1470 # 80019de0 <log>
    800043a6:	9736                	add	a4,a4,a3
    800043a8:	44d4                	lw	a3,12(s1)
    800043aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043ac:	faf608e3          	beq	a2,a5,8000435c <log_write+0x76>
  }
  release(&log.lock);
    800043b0:	00016517          	auipc	a0,0x16
    800043b4:	a3050513          	addi	a0,a0,-1488 # 80019de0 <log>
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	64a2                	ld	s1,8(sp)
    800043c6:	6902                	ld	s2,0(sp)
    800043c8:	6105                	addi	sp,sp,32
    800043ca:	8082                	ret

00000000800043cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	e04a                	sd	s2,0(sp)
    800043d6:	1000                	addi	s0,sp,32
    800043d8:	84aa                	mv	s1,a0
    800043da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043dc:	00004597          	auipc	a1,0x4
    800043e0:	2a458593          	addi	a1,a1,676 # 80008680 <syscalls+0x238>
    800043e4:	0521                	addi	a0,a0,8
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	76e080e7          	jalr	1902(ra) # 80000b54 <initlock>
  lk->name = name;
    800043ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f6:	0204a423          	sw	zero,40(s1)
}
    800043fa:	60e2                	ld	ra,24(sp)
    800043fc:	6442                	ld	s0,16(sp)
    800043fe:	64a2                	ld	s1,8(sp)
    80004400:	6902                	ld	s2,0(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret

0000000080004406 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004406:	1101                	addi	sp,sp,-32
    80004408:	ec06                	sd	ra,24(sp)
    8000440a:	e822                	sd	s0,16(sp)
    8000440c:	e426                	sd	s1,8(sp)
    8000440e:	e04a                	sd	s2,0(sp)
    80004410:	1000                	addi	s0,sp,32
    80004412:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004414:	00850913          	addi	s2,a0,8
    80004418:	854a                	mv	a0,s2
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	7ca080e7          	jalr	1994(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004422:	409c                	lw	a5,0(s1)
    80004424:	cb89                	beqz	a5,80004436 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004426:	85ca                	mv	a1,s2
    80004428:	8526                	mv	a0,s1
    8000442a:	ffffe097          	auipc	ra,0xffffe
    8000442e:	c84080e7          	jalr	-892(ra) # 800020ae <sleep>
  while (lk->locked) {
    80004432:	409c                	lw	a5,0(s1)
    80004434:	fbed                	bnez	a5,80004426 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004436:	4785                	li	a5,1
    80004438:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	576080e7          	jalr	1398(ra) # 800019b0 <myproc>
    80004442:	591c                	lw	a5,48(a0)
    80004444:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004446:	854a                	mv	a0,s2
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	850080e7          	jalr	-1968(ra) # 80000c98 <release>
}
    80004450:	60e2                	ld	ra,24(sp)
    80004452:	6442                	ld	s0,16(sp)
    80004454:	64a2                	ld	s1,8(sp)
    80004456:	6902                	ld	s2,0(sp)
    80004458:	6105                	addi	sp,sp,32
    8000445a:	8082                	ret

000000008000445c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000445c:	1101                	addi	sp,sp,-32
    8000445e:	ec06                	sd	ra,24(sp)
    80004460:	e822                	sd	s0,16(sp)
    80004462:	e426                	sd	s1,8(sp)
    80004464:	e04a                	sd	s2,0(sp)
    80004466:	1000                	addi	s0,sp,32
    80004468:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000446a:	00850913          	addi	s2,a0,8
    8000446e:	854a                	mv	a0,s2
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	774080e7          	jalr	1908(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004478:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000447c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004480:	8526                	mv	a0,s1
    80004482:	ffffe097          	auipc	ra,0xffffe
    80004486:	db8080e7          	jalr	-584(ra) # 8000223a <wakeup>
  release(&lk->lk);
    8000448a:	854a                	mv	a0,s2
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	80c080e7          	jalr	-2036(ra) # 80000c98 <release>
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6902                	ld	s2,0(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044a0:	7179                	addi	sp,sp,-48
    800044a2:	f406                	sd	ra,40(sp)
    800044a4:	f022                	sd	s0,32(sp)
    800044a6:	ec26                	sd	s1,24(sp)
    800044a8:	e84a                	sd	s2,16(sp)
    800044aa:	e44e                	sd	s3,8(sp)
    800044ac:	1800                	addi	s0,sp,48
    800044ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044b0:	00850913          	addi	s2,a0,8
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	72e080e7          	jalr	1838(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044be:	409c                	lw	a5,0(s1)
    800044c0:	ef99                	bnez	a5,800044de <holdingsleep+0x3e>
    800044c2:	4481                	li	s1,0
  release(&lk->lk);
    800044c4:	854a                	mv	a0,s2
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	7d2080e7          	jalr	2002(ra) # 80000c98 <release>
  return r;
}
    800044ce:	8526                	mv	a0,s1
    800044d0:	70a2                	ld	ra,40(sp)
    800044d2:	7402                	ld	s0,32(sp)
    800044d4:	64e2                	ld	s1,24(sp)
    800044d6:	6942                	ld	s2,16(sp)
    800044d8:	69a2                	ld	s3,8(sp)
    800044da:	6145                	addi	sp,sp,48
    800044dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044de:	0284a983          	lw	s3,40(s1)
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	4ce080e7          	jalr	1230(ra) # 800019b0 <myproc>
    800044ea:	5904                	lw	s1,48(a0)
    800044ec:	413484b3          	sub	s1,s1,s3
    800044f0:	0014b493          	seqz	s1,s1
    800044f4:	bfc1                	j	800044c4 <holdingsleep+0x24>

00000000800044f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044f6:	1141                	addi	sp,sp,-16
    800044f8:	e406                	sd	ra,8(sp)
    800044fa:	e022                	sd	s0,0(sp)
    800044fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044fe:	00004597          	auipc	a1,0x4
    80004502:	19258593          	addi	a1,a1,402 # 80008690 <syscalls+0x248>
    80004506:	00016517          	auipc	a0,0x16
    8000450a:	a2250513          	addi	a0,a0,-1502 # 80019f28 <ftable>
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	646080e7          	jalr	1606(ra) # 80000b54 <initlock>
}
    80004516:	60a2                	ld	ra,8(sp)
    80004518:	6402                	ld	s0,0(sp)
    8000451a:	0141                	addi	sp,sp,16
    8000451c:	8082                	ret

000000008000451e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000451e:	1101                	addi	sp,sp,-32
    80004520:	ec06                	sd	ra,24(sp)
    80004522:	e822                	sd	s0,16(sp)
    80004524:	e426                	sd	s1,8(sp)
    80004526:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004528:	00016517          	auipc	a0,0x16
    8000452c:	a0050513          	addi	a0,a0,-1536 # 80019f28 <ftable>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004538:	00016497          	auipc	s1,0x16
    8000453c:	a0848493          	addi	s1,s1,-1528 # 80019f40 <ftable+0x18>
    80004540:	00017717          	auipc	a4,0x17
    80004544:	9a070713          	addi	a4,a4,-1632 # 8001aee0 <ftable+0xfb8>
    if(f->ref == 0){
    80004548:	40dc                	lw	a5,4(s1)
    8000454a:	cf99                	beqz	a5,80004568 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000454c:	02848493          	addi	s1,s1,40
    80004550:	fee49ce3          	bne	s1,a4,80004548 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004554:	00016517          	auipc	a0,0x16
    80004558:	9d450513          	addi	a0,a0,-1580 # 80019f28 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	73c080e7          	jalr	1852(ra) # 80000c98 <release>
  return 0;
    80004564:	4481                	li	s1,0
    80004566:	a819                	j	8000457c <filealloc+0x5e>
      f->ref = 1;
    80004568:	4785                	li	a5,1
    8000456a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000456c:	00016517          	auipc	a0,0x16
    80004570:	9bc50513          	addi	a0,a0,-1604 # 80019f28 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	724080e7          	jalr	1828(ra) # 80000c98 <release>
}
    8000457c:	8526                	mv	a0,s1
    8000457e:	60e2                	ld	ra,24(sp)
    80004580:	6442                	ld	s0,16(sp)
    80004582:	64a2                	ld	s1,8(sp)
    80004584:	6105                	addi	sp,sp,32
    80004586:	8082                	ret

0000000080004588 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004588:	1101                	addi	sp,sp,-32
    8000458a:	ec06                	sd	ra,24(sp)
    8000458c:	e822                	sd	s0,16(sp)
    8000458e:	e426                	sd	s1,8(sp)
    80004590:	1000                	addi	s0,sp,32
    80004592:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004594:	00016517          	auipc	a0,0x16
    80004598:	99450513          	addi	a0,a0,-1644 # 80019f28 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045a4:	40dc                	lw	a5,4(s1)
    800045a6:	02f05263          	blez	a5,800045ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045aa:	2785                	addiw	a5,a5,1
    800045ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ae:	00016517          	auipc	a0,0x16
    800045b2:	97a50513          	addi	a0,a0,-1670 # 80019f28 <ftable>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	6e2080e7          	jalr	1762(ra) # 80000c98 <release>
  return f;
}
    800045be:	8526                	mv	a0,s1
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6105                	addi	sp,sp,32
    800045c8:	8082                	ret
    panic("filedup");
    800045ca:	00004517          	auipc	a0,0x4
    800045ce:	0ce50513          	addi	a0,a0,206 # 80008698 <syscalls+0x250>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>

00000000800045da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045da:	7139                	addi	sp,sp,-64
    800045dc:	fc06                	sd	ra,56(sp)
    800045de:	f822                	sd	s0,48(sp)
    800045e0:	f426                	sd	s1,40(sp)
    800045e2:	f04a                	sd	s2,32(sp)
    800045e4:	ec4e                	sd	s3,24(sp)
    800045e6:	e852                	sd	s4,16(sp)
    800045e8:	e456                	sd	s5,8(sp)
    800045ea:	0080                	addi	s0,sp,64
    800045ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ee:	00016517          	auipc	a0,0x16
    800045f2:	93a50513          	addi	a0,a0,-1734 # 80019f28 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	5ee080e7          	jalr	1518(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045fe:	40dc                	lw	a5,4(s1)
    80004600:	06f05163          	blez	a5,80004662 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004604:	37fd                	addiw	a5,a5,-1
    80004606:	0007871b          	sext.w	a4,a5
    8000460a:	c0dc                	sw	a5,4(s1)
    8000460c:	06e04363          	bgtz	a4,80004672 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004610:	0004a903          	lw	s2,0(s1)
    80004614:	0094ca83          	lbu	s5,9(s1)
    80004618:	0104ba03          	ld	s4,16(s1)
    8000461c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004620:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004624:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004628:	00016517          	auipc	a0,0x16
    8000462c:	90050513          	addi	a0,a0,-1792 # 80019f28 <ftable>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	668080e7          	jalr	1640(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004638:	4785                	li	a5,1
    8000463a:	04f90d63          	beq	s2,a5,80004694 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000463e:	3979                	addiw	s2,s2,-2
    80004640:	4785                	li	a5,1
    80004642:	0527e063          	bltu	a5,s2,80004682 <fileclose+0xa8>
    begin_op();
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	ac8080e7          	jalr	-1336(ra) # 8000410e <begin_op>
    iput(ff.ip);
    8000464e:	854e                	mv	a0,s3
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	2a6080e7          	jalr	678(ra) # 800038f6 <iput>
    end_op();
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	b36080e7          	jalr	-1226(ra) # 8000418e <end_op>
    80004660:	a00d                	j	80004682 <fileclose+0xa8>
    panic("fileclose");
    80004662:	00004517          	auipc	a0,0x4
    80004666:	03e50513          	addi	a0,a0,62 # 800086a0 <syscalls+0x258>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004672:	00016517          	auipc	a0,0x16
    80004676:	8b650513          	addi	a0,a0,-1866 # 80019f28 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	61e080e7          	jalr	1566(ra) # 80000c98 <release>
  }
}
    80004682:	70e2                	ld	ra,56(sp)
    80004684:	7442                	ld	s0,48(sp)
    80004686:	74a2                	ld	s1,40(sp)
    80004688:	7902                	ld	s2,32(sp)
    8000468a:	69e2                	ld	s3,24(sp)
    8000468c:	6a42                	ld	s4,16(sp)
    8000468e:	6aa2                	ld	s5,8(sp)
    80004690:	6121                	addi	sp,sp,64
    80004692:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004694:	85d6                	mv	a1,s5
    80004696:	8552                	mv	a0,s4
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	34c080e7          	jalr	844(ra) # 800049e4 <pipeclose>
    800046a0:	b7cd                	j	80004682 <fileclose+0xa8>

00000000800046a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a2:	715d                	addi	sp,sp,-80
    800046a4:	e486                	sd	ra,72(sp)
    800046a6:	e0a2                	sd	s0,64(sp)
    800046a8:	fc26                	sd	s1,56(sp)
    800046aa:	f84a                	sd	s2,48(sp)
    800046ac:	f44e                	sd	s3,40(sp)
    800046ae:	0880                	addi	s0,sp,80
    800046b0:	84aa                	mv	s1,a0
    800046b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b4:	ffffd097          	auipc	ra,0xffffd
    800046b8:	2fc080e7          	jalr	764(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046bc:	409c                	lw	a5,0(s1)
    800046be:	37f9                	addiw	a5,a5,-2
    800046c0:	4705                	li	a4,1
    800046c2:	04f76763          	bltu	a4,a5,80004710 <filestat+0x6e>
    800046c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800046c8:	6c88                	ld	a0,24(s1)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	072080e7          	jalr	114(ra) # 8000373c <ilock>
    stati(f->ip, &st);
    800046d2:	fb840593          	addi	a1,s0,-72
    800046d6:	6c88                	ld	a0,24(s1)
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	2ee080e7          	jalr	750(ra) # 800039c6 <stati>
    iunlock(f->ip);
    800046e0:	6c88                	ld	a0,24(s1)
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	11c080e7          	jalr	284(ra) # 800037fe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046ea:	46e1                	li	a3,24
    800046ec:	fb840613          	addi	a2,s0,-72
    800046f0:	85ce                	mv	a1,s3
    800046f2:	05093503          	ld	a0,80(s2)
    800046f6:	ffffd097          	auipc	ra,0xffffd
    800046fa:	f7c080e7          	jalr	-132(ra) # 80001672 <copyout>
    800046fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004702:	60a6                	ld	ra,72(sp)
    80004704:	6406                	ld	s0,64(sp)
    80004706:	74e2                	ld	s1,56(sp)
    80004708:	7942                	ld	s2,48(sp)
    8000470a:	79a2                	ld	s3,40(sp)
    8000470c:	6161                	addi	sp,sp,80
    8000470e:	8082                	ret
  return -1;
    80004710:	557d                	li	a0,-1
    80004712:	bfc5                	j	80004702 <filestat+0x60>

0000000080004714 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004714:	7179                	addi	sp,sp,-48
    80004716:	f406                	sd	ra,40(sp)
    80004718:	f022                	sd	s0,32(sp)
    8000471a:	ec26                	sd	s1,24(sp)
    8000471c:	e84a                	sd	s2,16(sp)
    8000471e:	e44e                	sd	s3,8(sp)
    80004720:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004722:	00854783          	lbu	a5,8(a0)
    80004726:	c3d5                	beqz	a5,800047ca <fileread+0xb6>
    80004728:	84aa                	mv	s1,a0
    8000472a:	89ae                	mv	s3,a1
    8000472c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000472e:	411c                	lw	a5,0(a0)
    80004730:	4705                	li	a4,1
    80004732:	04e78963          	beq	a5,a4,80004784 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004736:	470d                	li	a4,3
    80004738:	04e78d63          	beq	a5,a4,80004792 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000473c:	4709                	li	a4,2
    8000473e:	06e79e63          	bne	a5,a4,800047ba <fileread+0xa6>
    ilock(f->ip);
    80004742:	6d08                	ld	a0,24(a0)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	ff8080e7          	jalr	-8(ra) # 8000373c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000474c:	874a                	mv	a4,s2
    8000474e:	5094                	lw	a3,32(s1)
    80004750:	864e                	mv	a2,s3
    80004752:	4585                	li	a1,1
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	29a080e7          	jalr	666(ra) # 800039f0 <readi>
    8000475e:	892a                	mv	s2,a0
    80004760:	00a05563          	blez	a0,8000476a <fileread+0x56>
      f->off += r;
    80004764:	509c                	lw	a5,32(s1)
    80004766:	9fa9                	addw	a5,a5,a0
    80004768:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000476a:	6c88                	ld	a0,24(s1)
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	092080e7          	jalr	146(ra) # 800037fe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004774:	854a                	mv	a0,s2
    80004776:	70a2                	ld	ra,40(sp)
    80004778:	7402                	ld	s0,32(sp)
    8000477a:	64e2                	ld	s1,24(sp)
    8000477c:	6942                	ld	s2,16(sp)
    8000477e:	69a2                	ld	s3,8(sp)
    80004780:	6145                	addi	sp,sp,48
    80004782:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004784:	6908                	ld	a0,16(a0)
    80004786:	00000097          	auipc	ra,0x0
    8000478a:	3c8080e7          	jalr	968(ra) # 80004b4e <piperead>
    8000478e:	892a                	mv	s2,a0
    80004790:	b7d5                	j	80004774 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004792:	02451783          	lh	a5,36(a0)
    80004796:	03079693          	slli	a3,a5,0x30
    8000479a:	92c1                	srli	a3,a3,0x30
    8000479c:	4725                	li	a4,9
    8000479e:	02d76863          	bltu	a4,a3,800047ce <fileread+0xba>
    800047a2:	0792                	slli	a5,a5,0x4
    800047a4:	00015717          	auipc	a4,0x15
    800047a8:	6e470713          	addi	a4,a4,1764 # 80019e88 <devsw>
    800047ac:	97ba                	add	a5,a5,a4
    800047ae:	639c                	ld	a5,0(a5)
    800047b0:	c38d                	beqz	a5,800047d2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b2:	4505                	li	a0,1
    800047b4:	9782                	jalr	a5
    800047b6:	892a                	mv	s2,a0
    800047b8:	bf75                	j	80004774 <fileread+0x60>
    panic("fileread");
    800047ba:	00004517          	auipc	a0,0x4
    800047be:	ef650513          	addi	a0,a0,-266 # 800086b0 <syscalls+0x268>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
    return -1;
    800047ca:	597d                	li	s2,-1
    800047cc:	b765                	j	80004774 <fileread+0x60>
      return -1;
    800047ce:	597d                	li	s2,-1
    800047d0:	b755                	j	80004774 <fileread+0x60>
    800047d2:	597d                	li	s2,-1
    800047d4:	b745                	j	80004774 <fileread+0x60>

00000000800047d6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047d6:	715d                	addi	sp,sp,-80
    800047d8:	e486                	sd	ra,72(sp)
    800047da:	e0a2                	sd	s0,64(sp)
    800047dc:	fc26                	sd	s1,56(sp)
    800047de:	f84a                	sd	s2,48(sp)
    800047e0:	f44e                	sd	s3,40(sp)
    800047e2:	f052                	sd	s4,32(sp)
    800047e4:	ec56                	sd	s5,24(sp)
    800047e6:	e85a                	sd	s6,16(sp)
    800047e8:	e45e                	sd	s7,8(sp)
    800047ea:	e062                	sd	s8,0(sp)
    800047ec:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047ee:	00954783          	lbu	a5,9(a0)
    800047f2:	10078663          	beqz	a5,800048fe <filewrite+0x128>
    800047f6:	892a                	mv	s2,a0
    800047f8:	8aae                	mv	s5,a1
    800047fa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047fc:	411c                	lw	a5,0(a0)
    800047fe:	4705                	li	a4,1
    80004800:	02e78263          	beq	a5,a4,80004824 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004804:	470d                	li	a4,3
    80004806:	02e78663          	beq	a5,a4,80004832 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000480a:	4709                	li	a4,2
    8000480c:	0ee79163          	bne	a5,a4,800048ee <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004810:	0ac05d63          	blez	a2,800048ca <filewrite+0xf4>
    int i = 0;
    80004814:	4981                	li	s3,0
    80004816:	6b05                	lui	s6,0x1
    80004818:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000481c:	6b85                	lui	s7,0x1
    8000481e:	c00b8b9b          	addiw	s7,s7,-1024
    80004822:	a861                	j	800048ba <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004824:	6908                	ld	a0,16(a0)
    80004826:	00000097          	auipc	ra,0x0
    8000482a:	22e080e7          	jalr	558(ra) # 80004a54 <pipewrite>
    8000482e:	8a2a                	mv	s4,a0
    80004830:	a045                	j	800048d0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004832:	02451783          	lh	a5,36(a0)
    80004836:	03079693          	slli	a3,a5,0x30
    8000483a:	92c1                	srli	a3,a3,0x30
    8000483c:	4725                	li	a4,9
    8000483e:	0cd76263          	bltu	a4,a3,80004902 <filewrite+0x12c>
    80004842:	0792                	slli	a5,a5,0x4
    80004844:	00015717          	auipc	a4,0x15
    80004848:	64470713          	addi	a4,a4,1604 # 80019e88 <devsw>
    8000484c:	97ba                	add	a5,a5,a4
    8000484e:	679c                	ld	a5,8(a5)
    80004850:	cbdd                	beqz	a5,80004906 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004852:	4505                	li	a0,1
    80004854:	9782                	jalr	a5
    80004856:	8a2a                	mv	s4,a0
    80004858:	a8a5                	j	800048d0 <filewrite+0xfa>
    8000485a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	8b0080e7          	jalr	-1872(ra) # 8000410e <begin_op>
      ilock(f->ip);
    80004866:	01893503          	ld	a0,24(s2)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	ed2080e7          	jalr	-302(ra) # 8000373c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004872:	8762                	mv	a4,s8
    80004874:	02092683          	lw	a3,32(s2)
    80004878:	01598633          	add	a2,s3,s5
    8000487c:	4585                	li	a1,1
    8000487e:	01893503          	ld	a0,24(s2)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	266080e7          	jalr	614(ra) # 80003ae8 <writei>
    8000488a:	84aa                	mv	s1,a0
    8000488c:	00a05763          	blez	a0,8000489a <filewrite+0xc4>
        f->off += r;
    80004890:	02092783          	lw	a5,32(s2)
    80004894:	9fa9                	addw	a5,a5,a0
    80004896:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000489a:	01893503          	ld	a0,24(s2)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	f60080e7          	jalr	-160(ra) # 800037fe <iunlock>
      end_op();
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	8e8080e7          	jalr	-1816(ra) # 8000418e <end_op>

      if(r != n1){
    800048ae:	009c1f63          	bne	s8,s1,800048cc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048b2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b6:	0149db63          	bge	s3,s4,800048cc <filewrite+0xf6>
      int n1 = n - i;
    800048ba:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048be:	84be                	mv	s1,a5
    800048c0:	2781                	sext.w	a5,a5
    800048c2:	f8fb5ce3          	bge	s6,a5,8000485a <filewrite+0x84>
    800048c6:	84de                	mv	s1,s7
    800048c8:	bf49                	j	8000485a <filewrite+0x84>
    int i = 0;
    800048ca:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048cc:	013a1f63          	bne	s4,s3,800048ea <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048d0:	8552                	mv	a0,s4
    800048d2:	60a6                	ld	ra,72(sp)
    800048d4:	6406                	ld	s0,64(sp)
    800048d6:	74e2                	ld	s1,56(sp)
    800048d8:	7942                	ld	s2,48(sp)
    800048da:	79a2                	ld	s3,40(sp)
    800048dc:	7a02                	ld	s4,32(sp)
    800048de:	6ae2                	ld	s5,24(sp)
    800048e0:	6b42                	ld	s6,16(sp)
    800048e2:	6ba2                	ld	s7,8(sp)
    800048e4:	6c02                	ld	s8,0(sp)
    800048e6:	6161                	addi	sp,sp,80
    800048e8:	8082                	ret
    ret = (i == n ? n : -1);
    800048ea:	5a7d                	li	s4,-1
    800048ec:	b7d5                	j	800048d0 <filewrite+0xfa>
    panic("filewrite");
    800048ee:	00004517          	auipc	a0,0x4
    800048f2:	dd250513          	addi	a0,a0,-558 # 800086c0 <syscalls+0x278>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	c48080e7          	jalr	-952(ra) # 8000053e <panic>
    return -1;
    800048fe:	5a7d                	li	s4,-1
    80004900:	bfc1                	j	800048d0 <filewrite+0xfa>
      return -1;
    80004902:	5a7d                	li	s4,-1
    80004904:	b7f1                	j	800048d0 <filewrite+0xfa>
    80004906:	5a7d                	li	s4,-1
    80004908:	b7e1                	j	800048d0 <filewrite+0xfa>

000000008000490a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000490a:	7179                	addi	sp,sp,-48
    8000490c:	f406                	sd	ra,40(sp)
    8000490e:	f022                	sd	s0,32(sp)
    80004910:	ec26                	sd	s1,24(sp)
    80004912:	e84a                	sd	s2,16(sp)
    80004914:	e44e                	sd	s3,8(sp)
    80004916:	e052                	sd	s4,0(sp)
    80004918:	1800                	addi	s0,sp,48
    8000491a:	84aa                	mv	s1,a0
    8000491c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000491e:	0005b023          	sd	zero,0(a1)
    80004922:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004926:	00000097          	auipc	ra,0x0
    8000492a:	bf8080e7          	jalr	-1032(ra) # 8000451e <filealloc>
    8000492e:	e088                	sd	a0,0(s1)
    80004930:	c551                	beqz	a0,800049bc <pipealloc+0xb2>
    80004932:	00000097          	auipc	ra,0x0
    80004936:	bec080e7          	jalr	-1044(ra) # 8000451e <filealloc>
    8000493a:	00aa3023          	sd	a0,0(s4)
    8000493e:	c92d                	beqz	a0,800049b0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	1b4080e7          	jalr	436(ra) # 80000af4 <kalloc>
    80004948:	892a                	mv	s2,a0
    8000494a:	c125                	beqz	a0,800049aa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000494c:	4985                	li	s3,1
    8000494e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004952:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004956:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000495a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000495e:	00004597          	auipc	a1,0x4
    80004962:	d7258593          	addi	a1,a1,-654 # 800086d0 <syscalls+0x288>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	1ee080e7          	jalr	494(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000496e:	609c                	ld	a5,0(s1)
    80004970:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004974:	609c                	ld	a5,0(s1)
    80004976:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000497a:	609c                	ld	a5,0(s1)
    8000497c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004980:	609c                	ld	a5,0(s1)
    80004982:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004986:	000a3783          	ld	a5,0(s4)
    8000498a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000498e:	000a3783          	ld	a5,0(s4)
    80004992:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004996:	000a3783          	ld	a5,0(s4)
    8000499a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000499e:	000a3783          	ld	a5,0(s4)
    800049a2:	0127b823          	sd	s2,16(a5)
  return 0;
    800049a6:	4501                	li	a0,0
    800049a8:	a025                	j	800049d0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049aa:	6088                	ld	a0,0(s1)
    800049ac:	e501                	bnez	a0,800049b4 <pipealloc+0xaa>
    800049ae:	a039                	j	800049bc <pipealloc+0xb2>
    800049b0:	6088                	ld	a0,0(s1)
    800049b2:	c51d                	beqz	a0,800049e0 <pipealloc+0xd6>
    fileclose(*f0);
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	c26080e7          	jalr	-986(ra) # 800045da <fileclose>
  if(*f1)
    800049bc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049c0:	557d                	li	a0,-1
  if(*f1)
    800049c2:	c799                	beqz	a5,800049d0 <pipealloc+0xc6>
    fileclose(*f1);
    800049c4:	853e                	mv	a0,a5
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	c14080e7          	jalr	-1004(ra) # 800045da <fileclose>
  return -1;
    800049ce:	557d                	li	a0,-1
}
    800049d0:	70a2                	ld	ra,40(sp)
    800049d2:	7402                	ld	s0,32(sp)
    800049d4:	64e2                	ld	s1,24(sp)
    800049d6:	6942                	ld	s2,16(sp)
    800049d8:	69a2                	ld	s3,8(sp)
    800049da:	6a02                	ld	s4,0(sp)
    800049dc:	6145                	addi	sp,sp,48
    800049de:	8082                	ret
  return -1;
    800049e0:	557d                	li	a0,-1
    800049e2:	b7fd                	j	800049d0 <pipealloc+0xc6>

00000000800049e4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	e04a                	sd	s2,0(sp)
    800049ee:	1000                	addi	s0,sp,32
    800049f0:	84aa                	mv	s1,a0
    800049f2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	1f0080e7          	jalr	496(ra) # 80000be4 <acquire>
  if(writable){
    800049fc:	02090d63          	beqz	s2,80004a36 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a00:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a04:	21848513          	addi	a0,s1,536
    80004a08:	ffffe097          	auipc	ra,0xffffe
    80004a0c:	832080e7          	jalr	-1998(ra) # 8000223a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a10:	2204b783          	ld	a5,544(s1)
    80004a14:	eb95                	bnez	a5,80004a48 <pipeclose+0x64>
    release(&pi->lock);
    80004a16:	8526                	mv	a0,s1
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a20:	8526                	mv	a0,s1
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	fd6080e7          	jalr	-42(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a2a:	60e2                	ld	ra,24(sp)
    80004a2c:	6442                	ld	s0,16(sp)
    80004a2e:	64a2                	ld	s1,8(sp)
    80004a30:	6902                	ld	s2,0(sp)
    80004a32:	6105                	addi	sp,sp,32
    80004a34:	8082                	ret
    pi->readopen = 0;
    80004a36:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a3a:	21c48513          	addi	a0,s1,540
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	7fc080e7          	jalr	2044(ra) # 8000223a <wakeup>
    80004a46:	b7e9                	j	80004a10 <pipeclose+0x2c>
    release(&pi->lock);
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80004a52:	bfe1                	j	80004a2a <pipeclose+0x46>

0000000080004a54 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a54:	7159                	addi	sp,sp,-112
    80004a56:	f486                	sd	ra,104(sp)
    80004a58:	f0a2                	sd	s0,96(sp)
    80004a5a:	eca6                	sd	s1,88(sp)
    80004a5c:	e8ca                	sd	s2,80(sp)
    80004a5e:	e4ce                	sd	s3,72(sp)
    80004a60:	e0d2                	sd	s4,64(sp)
    80004a62:	fc56                	sd	s5,56(sp)
    80004a64:	f85a                	sd	s6,48(sp)
    80004a66:	f45e                	sd	s7,40(sp)
    80004a68:	f062                	sd	s8,32(sp)
    80004a6a:	ec66                	sd	s9,24(sp)
    80004a6c:	1880                	addi	s0,sp,112
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	8aae                	mv	s5,a1
    80004a72:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a74:	ffffd097          	auipc	ra,0xffffd
    80004a78:	f3c080e7          	jalr	-196(ra) # 800019b0 <myproc>
    80004a7c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a7e:	8526                	mv	a0,s1
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	164080e7          	jalr	356(ra) # 80000be4 <acquire>
  while(i < n){
    80004a88:	0d405163          	blez	s4,80004b4a <pipewrite+0xf6>
    80004a8c:	8ba6                	mv	s7,s1
  int i = 0;
    80004a8e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a90:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a92:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a96:	21c48c13          	addi	s8,s1,540
    80004a9a:	a08d                	j	80004afc <pipewrite+0xa8>
      release(&pi->lock);
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	1fa080e7          	jalr	506(ra) # 80000c98 <release>
      return -1;
    80004aa6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004aa8:	854a                	mv	a0,s2
    80004aaa:	70a6                	ld	ra,104(sp)
    80004aac:	7406                	ld	s0,96(sp)
    80004aae:	64e6                	ld	s1,88(sp)
    80004ab0:	6946                	ld	s2,80(sp)
    80004ab2:	69a6                	ld	s3,72(sp)
    80004ab4:	6a06                	ld	s4,64(sp)
    80004ab6:	7ae2                	ld	s5,56(sp)
    80004ab8:	7b42                	ld	s6,48(sp)
    80004aba:	7ba2                	ld	s7,40(sp)
    80004abc:	7c02                	ld	s8,32(sp)
    80004abe:	6ce2                	ld	s9,24(sp)
    80004ac0:	6165                	addi	sp,sp,112
    80004ac2:	8082                	ret
      wakeup(&pi->nread);
    80004ac4:	8566                	mv	a0,s9
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	774080e7          	jalr	1908(ra) # 8000223a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ace:	85de                	mv	a1,s7
    80004ad0:	8562                	mv	a0,s8
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	5dc080e7          	jalr	1500(ra) # 800020ae <sleep>
    80004ada:	a839                	j	80004af8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004adc:	21c4a783          	lw	a5,540(s1)
    80004ae0:	0017871b          	addiw	a4,a5,1
    80004ae4:	20e4ae23          	sw	a4,540(s1)
    80004ae8:	1ff7f793          	andi	a5,a5,511
    80004aec:	97a6                	add	a5,a5,s1
    80004aee:	f9f44703          	lbu	a4,-97(s0)
    80004af2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004af6:	2905                	addiw	s2,s2,1
  while(i < n){
    80004af8:	03495d63          	bge	s2,s4,80004b32 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004afc:	2204a783          	lw	a5,544(s1)
    80004b00:	dfd1                	beqz	a5,80004a9c <pipewrite+0x48>
    80004b02:	0289a783          	lw	a5,40(s3)
    80004b06:	fbd9                	bnez	a5,80004a9c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b08:	2184a783          	lw	a5,536(s1)
    80004b0c:	21c4a703          	lw	a4,540(s1)
    80004b10:	2007879b          	addiw	a5,a5,512
    80004b14:	faf708e3          	beq	a4,a5,80004ac4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b18:	4685                	li	a3,1
    80004b1a:	01590633          	add	a2,s2,s5
    80004b1e:	f9f40593          	addi	a1,s0,-97
    80004b22:	0509b503          	ld	a0,80(s3)
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	bd8080e7          	jalr	-1064(ra) # 800016fe <copyin>
    80004b2e:	fb6517e3          	bne	a0,s6,80004adc <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b32:	21848513          	addi	a0,s1,536
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	704080e7          	jalr	1796(ra) # 8000223a <wakeup>
  release(&pi->lock);
    80004b3e:	8526                	mv	a0,s1
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	158080e7          	jalr	344(ra) # 80000c98 <release>
  return i;
    80004b48:	b785                	j	80004aa8 <pipewrite+0x54>
  int i = 0;
    80004b4a:	4901                	li	s2,0
    80004b4c:	b7dd                	j	80004b32 <pipewrite+0xde>

0000000080004b4e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b4e:	715d                	addi	sp,sp,-80
    80004b50:	e486                	sd	ra,72(sp)
    80004b52:	e0a2                	sd	s0,64(sp)
    80004b54:	fc26                	sd	s1,56(sp)
    80004b56:	f84a                	sd	s2,48(sp)
    80004b58:	f44e                	sd	s3,40(sp)
    80004b5a:	f052                	sd	s4,32(sp)
    80004b5c:	ec56                	sd	s5,24(sp)
    80004b5e:	e85a                	sd	s6,16(sp)
    80004b60:	0880                	addi	s0,sp,80
    80004b62:	84aa                	mv	s1,a0
    80004b64:	892e                	mv	s2,a1
    80004b66:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b68:	ffffd097          	auipc	ra,0xffffd
    80004b6c:	e48080e7          	jalr	-440(ra) # 800019b0 <myproc>
    80004b70:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b72:	8b26                	mv	s6,s1
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	06e080e7          	jalr	110(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b7e:	2184a703          	lw	a4,536(s1)
    80004b82:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b86:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8a:	02f71463          	bne	a4,a5,80004bb2 <piperead+0x64>
    80004b8e:	2244a783          	lw	a5,548(s1)
    80004b92:	c385                	beqz	a5,80004bb2 <piperead+0x64>
    if(pr->killed){
    80004b94:	028a2783          	lw	a5,40(s4)
    80004b98:	ebc1                	bnez	a5,80004c28 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b9a:	85da                	mv	a1,s6
    80004b9c:	854e                	mv	a0,s3
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	510080e7          	jalr	1296(ra) # 800020ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba6:	2184a703          	lw	a4,536(s1)
    80004baa:	21c4a783          	lw	a5,540(s1)
    80004bae:	fef700e3          	beq	a4,a5,80004b8e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb2:	09505263          	blez	s5,80004c36 <piperead+0xe8>
    80004bb6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bb8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bba:	2184a783          	lw	a5,536(s1)
    80004bbe:	21c4a703          	lw	a4,540(s1)
    80004bc2:	02f70d63          	beq	a4,a5,80004bfc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bc6:	0017871b          	addiw	a4,a5,1
    80004bca:	20e4ac23          	sw	a4,536(s1)
    80004bce:	1ff7f793          	andi	a5,a5,511
    80004bd2:	97a6                	add	a5,a5,s1
    80004bd4:	0187c783          	lbu	a5,24(a5)
    80004bd8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bdc:	4685                	li	a3,1
    80004bde:	fbf40613          	addi	a2,s0,-65
    80004be2:	85ca                	mv	a1,s2
    80004be4:	050a3503          	ld	a0,80(s4)
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	a8a080e7          	jalr	-1398(ra) # 80001672 <copyout>
    80004bf0:	01650663          	beq	a0,s6,80004bfc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf4:	2985                	addiw	s3,s3,1
    80004bf6:	0905                	addi	s2,s2,1
    80004bf8:	fd3a91e3          	bne	s5,s3,80004bba <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bfc:	21c48513          	addi	a0,s1,540
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	63a080e7          	jalr	1594(ra) # 8000223a <wakeup>
  release(&pi->lock);
    80004c08:	8526                	mv	a0,s1
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>
  return i;
}
    80004c12:	854e                	mv	a0,s3
    80004c14:	60a6                	ld	ra,72(sp)
    80004c16:	6406                	ld	s0,64(sp)
    80004c18:	74e2                	ld	s1,56(sp)
    80004c1a:	7942                	ld	s2,48(sp)
    80004c1c:	79a2                	ld	s3,40(sp)
    80004c1e:	7a02                	ld	s4,32(sp)
    80004c20:	6ae2                	ld	s5,24(sp)
    80004c22:	6b42                	ld	s6,16(sp)
    80004c24:	6161                	addi	sp,sp,80
    80004c26:	8082                	ret
      release(&pi->lock);
    80004c28:	8526                	mv	a0,s1
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	06e080e7          	jalr	110(ra) # 80000c98 <release>
      return -1;
    80004c32:	59fd                	li	s3,-1
    80004c34:	bff9                	j	80004c12 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c36:	4981                	li	s3,0
    80004c38:	b7d1                	j	80004bfc <piperead+0xae>

0000000080004c3a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c3a:	df010113          	addi	sp,sp,-528
    80004c3e:	20113423          	sd	ra,520(sp)
    80004c42:	20813023          	sd	s0,512(sp)
    80004c46:	ffa6                	sd	s1,504(sp)
    80004c48:	fbca                	sd	s2,496(sp)
    80004c4a:	f7ce                	sd	s3,488(sp)
    80004c4c:	f3d2                	sd	s4,480(sp)
    80004c4e:	efd6                	sd	s5,472(sp)
    80004c50:	ebda                	sd	s6,464(sp)
    80004c52:	e7de                	sd	s7,456(sp)
    80004c54:	e3e2                	sd	s8,448(sp)
    80004c56:	ff66                	sd	s9,440(sp)
    80004c58:	fb6a                	sd	s10,432(sp)
    80004c5a:	f76e                	sd	s11,424(sp)
    80004c5c:	0c00                	addi	s0,sp,528
    80004c5e:	84aa                	mv	s1,a0
    80004c60:	dea43c23          	sd	a0,-520(s0)
    80004c64:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	d48080e7          	jalr	-696(ra) # 800019b0 <myproc>
    80004c70:	892a                	mv	s2,a0

  begin_op();
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	49c080e7          	jalr	1180(ra) # 8000410e <begin_op>

  if((ip = namei(path)) == 0){
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	276080e7          	jalr	630(ra) # 80003ef2 <namei>
    80004c84:	c92d                	beqz	a0,80004cf6 <exec+0xbc>
    80004c86:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	ab4080e7          	jalr	-1356(ra) # 8000373c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c90:	04000713          	li	a4,64
    80004c94:	4681                	li	a3,0
    80004c96:	e5040613          	addi	a2,s0,-432
    80004c9a:	4581                	li	a1,0
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	d52080e7          	jalr	-686(ra) # 800039f0 <readi>
    80004ca6:	04000793          	li	a5,64
    80004caa:	00f51a63          	bne	a0,a5,80004cbe <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cae:	e5042703          	lw	a4,-432(s0)
    80004cb2:	464c47b7          	lui	a5,0x464c4
    80004cb6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cba:	04f70463          	beq	a4,a5,80004d02 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	cde080e7          	jalr	-802(ra) # 8000399e <iunlockput>
    end_op();
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	4c6080e7          	jalr	1222(ra) # 8000418e <end_op>
  }
  return -1;
    80004cd0:	557d                	li	a0,-1
}
    80004cd2:	20813083          	ld	ra,520(sp)
    80004cd6:	20013403          	ld	s0,512(sp)
    80004cda:	74fe                	ld	s1,504(sp)
    80004cdc:	795e                	ld	s2,496(sp)
    80004cde:	79be                	ld	s3,488(sp)
    80004ce0:	7a1e                	ld	s4,480(sp)
    80004ce2:	6afe                	ld	s5,472(sp)
    80004ce4:	6b5e                	ld	s6,464(sp)
    80004ce6:	6bbe                	ld	s7,456(sp)
    80004ce8:	6c1e                	ld	s8,448(sp)
    80004cea:	7cfa                	ld	s9,440(sp)
    80004cec:	7d5a                	ld	s10,432(sp)
    80004cee:	7dba                	ld	s11,424(sp)
    80004cf0:	21010113          	addi	sp,sp,528
    80004cf4:	8082                	ret
    end_op();
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	498080e7          	jalr	1176(ra) # 8000418e <end_op>
    return -1;
    80004cfe:	557d                	li	a0,-1
    80004d00:	bfc9                	j	80004cd2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d02:	854a                	mv	a0,s2
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	d70080e7          	jalr	-656(ra) # 80001a74 <proc_pagetable>
    80004d0c:	8baa                	mv	s7,a0
    80004d0e:	d945                	beqz	a0,80004cbe <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d10:	e7042983          	lw	s3,-400(s0)
    80004d14:	e8845783          	lhu	a5,-376(s0)
    80004d18:	c7ad                	beqz	a5,80004d82 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d1a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d1e:	6c85                	lui	s9,0x1
    80004d20:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d24:	def43823          	sd	a5,-528(s0)
    80004d28:	a42d                	j	80004f52 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d2a:	00004517          	auipc	a0,0x4
    80004d2e:	9ae50513          	addi	a0,a0,-1618 # 800086d8 <syscalls+0x290>
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	80c080e7          	jalr	-2036(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d3a:	8756                	mv	a4,s5
    80004d3c:	012d86bb          	addw	a3,s11,s2
    80004d40:	4581                	li	a1,0
    80004d42:	8526                	mv	a0,s1
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	cac080e7          	jalr	-852(ra) # 800039f0 <readi>
    80004d4c:	2501                	sext.w	a0,a0
    80004d4e:	1aaa9963          	bne	s5,a0,80004f00 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d52:	6785                	lui	a5,0x1
    80004d54:	0127893b          	addw	s2,a5,s2
    80004d58:	77fd                	lui	a5,0xfffff
    80004d5a:	01478a3b          	addw	s4,a5,s4
    80004d5e:	1f897163          	bgeu	s2,s8,80004f40 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d62:	02091593          	slli	a1,s2,0x20
    80004d66:	9181                	srli	a1,a1,0x20
    80004d68:	95ea                	add	a1,a1,s10
    80004d6a:	855e                	mv	a0,s7
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	302080e7          	jalr	770(ra) # 8000106e <walkaddr>
    80004d74:	862a                	mv	a2,a0
    if(pa == 0)
    80004d76:	d955                	beqz	a0,80004d2a <exec+0xf0>
      n = PGSIZE;
    80004d78:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d7a:	fd9a70e3          	bgeu	s4,s9,80004d3a <exec+0x100>
      n = sz - i;
    80004d7e:	8ad2                	mv	s5,s4
    80004d80:	bf6d                	j	80004d3a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d82:	4901                	li	s2,0
  iunlockput(ip);
    80004d84:	8526                	mv	a0,s1
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	c18080e7          	jalr	-1000(ra) # 8000399e <iunlockput>
  end_op();
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	400080e7          	jalr	1024(ra) # 8000418e <end_op>
  p = myproc();
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	c1a080e7          	jalr	-998(ra) # 800019b0 <myproc>
    80004d9e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004da0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004da4:	6785                	lui	a5,0x1
    80004da6:	17fd                	addi	a5,a5,-1
    80004da8:	993e                	add	s2,s2,a5
    80004daa:	757d                	lui	a0,0xfffff
    80004dac:	00a977b3          	and	a5,s2,a0
    80004db0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004db4:	6609                	lui	a2,0x2
    80004db6:	963e                	add	a2,a2,a5
    80004db8:	85be                	mv	a1,a5
    80004dba:	855e                	mv	a0,s7
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	666080e7          	jalr	1638(ra) # 80001422 <uvmalloc>
    80004dc4:	8b2a                	mv	s6,a0
  ip = 0;
    80004dc6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dc8:	12050c63          	beqz	a0,80004f00 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dcc:	75f9                	lui	a1,0xffffe
    80004dce:	95aa                	add	a1,a1,a0
    80004dd0:	855e                	mv	a0,s7
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	86e080e7          	jalr	-1938(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004dda:	7c7d                	lui	s8,0xfffff
    80004ddc:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dde:	e0043783          	ld	a5,-512(s0)
    80004de2:	6388                	ld	a0,0(a5)
    80004de4:	c535                	beqz	a0,80004e50 <exec+0x216>
    80004de6:	e9040993          	addi	s3,s0,-368
    80004dea:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dee:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004df0:	ffffc097          	auipc	ra,0xffffc
    80004df4:	074080e7          	jalr	116(ra) # 80000e64 <strlen>
    80004df8:	2505                	addiw	a0,a0,1
    80004dfa:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dfe:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e02:	13896363          	bltu	s2,s8,80004f28 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e06:	e0043d83          	ld	s11,-512(s0)
    80004e0a:	000dba03          	ld	s4,0(s11)
    80004e0e:	8552                	mv	a0,s4
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	054080e7          	jalr	84(ra) # 80000e64 <strlen>
    80004e18:	0015069b          	addiw	a3,a0,1
    80004e1c:	8652                	mv	a2,s4
    80004e1e:	85ca                	mv	a1,s2
    80004e20:	855e                	mv	a0,s7
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	850080e7          	jalr	-1968(ra) # 80001672 <copyout>
    80004e2a:	10054363          	bltz	a0,80004f30 <exec+0x2f6>
    ustack[argc] = sp;
    80004e2e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e32:	0485                	addi	s1,s1,1
    80004e34:	008d8793          	addi	a5,s11,8
    80004e38:	e0f43023          	sd	a5,-512(s0)
    80004e3c:	008db503          	ld	a0,8(s11)
    80004e40:	c911                	beqz	a0,80004e54 <exec+0x21a>
    if(argc >= MAXARG)
    80004e42:	09a1                	addi	s3,s3,8
    80004e44:	fb3c96e3          	bne	s9,s3,80004df0 <exec+0x1b6>
  sz = sz1;
    80004e48:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e4c:	4481                	li	s1,0
    80004e4e:	a84d                	j	80004f00 <exec+0x2c6>
  sp = sz;
    80004e50:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e52:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e54:	00349793          	slli	a5,s1,0x3
    80004e58:	f9040713          	addi	a4,s0,-112
    80004e5c:	97ba                	add	a5,a5,a4
    80004e5e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e62:	00148693          	addi	a3,s1,1
    80004e66:	068e                	slli	a3,a3,0x3
    80004e68:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e6c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e70:	01897663          	bgeu	s2,s8,80004e7c <exec+0x242>
  sz = sz1;
    80004e74:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e78:	4481                	li	s1,0
    80004e7a:	a059                	j	80004f00 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e7c:	e9040613          	addi	a2,s0,-368
    80004e80:	85ca                	mv	a1,s2
    80004e82:	855e                	mv	a0,s7
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	7ee080e7          	jalr	2030(ra) # 80001672 <copyout>
    80004e8c:	0a054663          	bltz	a0,80004f38 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e90:	058ab783          	ld	a5,88(s5)
    80004e94:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e98:	df843783          	ld	a5,-520(s0)
    80004e9c:	0007c703          	lbu	a4,0(a5)
    80004ea0:	cf11                	beqz	a4,80004ebc <exec+0x282>
    80004ea2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ea4:	02f00693          	li	a3,47
    80004ea8:	a039                	j	80004eb6 <exec+0x27c>
      last = s+1;
    80004eaa:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004eae:	0785                	addi	a5,a5,1
    80004eb0:	fff7c703          	lbu	a4,-1(a5)
    80004eb4:	c701                	beqz	a4,80004ebc <exec+0x282>
    if(*s == '/')
    80004eb6:	fed71ce3          	bne	a4,a3,80004eae <exec+0x274>
    80004eba:	bfc5                	j	80004eaa <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ebc:	4641                	li	a2,16
    80004ebe:	df843583          	ld	a1,-520(s0)
    80004ec2:	158a8513          	addi	a0,s5,344
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	f6c080e7          	jalr	-148(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ece:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ed2:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ed6:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eda:	058ab783          	ld	a5,88(s5)
    80004ede:	e6843703          	ld	a4,-408(s0)
    80004ee2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ee4:	058ab783          	ld	a5,88(s5)
    80004ee8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eec:	85ea                	mv	a1,s10
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	c22080e7          	jalr	-990(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ef6:	0004851b          	sext.w	a0,s1
    80004efa:	bbe1                	j	80004cd2 <exec+0x98>
    80004efc:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f00:	e0843583          	ld	a1,-504(s0)
    80004f04:	855e                	mv	a0,s7
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	c0a080e7          	jalr	-1014(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004f0e:	da0498e3          	bnez	s1,80004cbe <exec+0x84>
  return -1;
    80004f12:	557d                	li	a0,-1
    80004f14:	bb7d                	j	80004cd2 <exec+0x98>
    80004f16:	e1243423          	sd	s2,-504(s0)
    80004f1a:	b7dd                	j	80004f00 <exec+0x2c6>
    80004f1c:	e1243423          	sd	s2,-504(s0)
    80004f20:	b7c5                	j	80004f00 <exec+0x2c6>
    80004f22:	e1243423          	sd	s2,-504(s0)
    80004f26:	bfe9                	j	80004f00 <exec+0x2c6>
  sz = sz1;
    80004f28:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f2c:	4481                	li	s1,0
    80004f2e:	bfc9                	j	80004f00 <exec+0x2c6>
  sz = sz1;
    80004f30:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f34:	4481                	li	s1,0
    80004f36:	b7e9                	j	80004f00 <exec+0x2c6>
  sz = sz1;
    80004f38:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f3c:	4481                	li	s1,0
    80004f3e:	b7c9                	j	80004f00 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f40:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f44:	2b05                	addiw	s6,s6,1
    80004f46:	0389899b          	addiw	s3,s3,56
    80004f4a:	e8845783          	lhu	a5,-376(s0)
    80004f4e:	e2fb5be3          	bge	s6,a5,80004d84 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f52:	2981                	sext.w	s3,s3
    80004f54:	03800713          	li	a4,56
    80004f58:	86ce                	mv	a3,s3
    80004f5a:	e1840613          	addi	a2,s0,-488
    80004f5e:	4581                	li	a1,0
    80004f60:	8526                	mv	a0,s1
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	a8e080e7          	jalr	-1394(ra) # 800039f0 <readi>
    80004f6a:	03800793          	li	a5,56
    80004f6e:	f8f517e3          	bne	a0,a5,80004efc <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f72:	e1842783          	lw	a5,-488(s0)
    80004f76:	4705                	li	a4,1
    80004f78:	fce796e3          	bne	a5,a4,80004f44 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f7c:	e4043603          	ld	a2,-448(s0)
    80004f80:	e3843783          	ld	a5,-456(s0)
    80004f84:	f8f669e3          	bltu	a2,a5,80004f16 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f88:	e2843783          	ld	a5,-472(s0)
    80004f8c:	963e                	add	a2,a2,a5
    80004f8e:	f8f667e3          	bltu	a2,a5,80004f1c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f92:	85ca                	mv	a1,s2
    80004f94:	855e                	mv	a0,s7
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	48c080e7          	jalr	1164(ra) # 80001422 <uvmalloc>
    80004f9e:	e0a43423          	sd	a0,-504(s0)
    80004fa2:	d141                	beqz	a0,80004f22 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004fa4:	e2843d03          	ld	s10,-472(s0)
    80004fa8:	df043783          	ld	a5,-528(s0)
    80004fac:	00fd77b3          	and	a5,s10,a5
    80004fb0:	fba1                	bnez	a5,80004f00 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fb2:	e2042d83          	lw	s11,-480(s0)
    80004fb6:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fba:	f80c03e3          	beqz	s8,80004f40 <exec+0x306>
    80004fbe:	8a62                	mv	s4,s8
    80004fc0:	4901                	li	s2,0
    80004fc2:	b345                	j	80004d62 <exec+0x128>

0000000080004fc4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fc4:	7179                	addi	sp,sp,-48
    80004fc6:	f406                	sd	ra,40(sp)
    80004fc8:	f022                	sd	s0,32(sp)
    80004fca:	ec26                	sd	s1,24(sp)
    80004fcc:	e84a                	sd	s2,16(sp)
    80004fce:	1800                	addi	s0,sp,48
    80004fd0:	892e                	mv	s2,a1
    80004fd2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fd4:	fdc40593          	addi	a1,s0,-36
    80004fd8:	ffffe097          	auipc	ra,0xffffe
    80004fdc:	ba8080e7          	jalr	-1112(ra) # 80002b80 <argint>
    80004fe0:	04054063          	bltz	a0,80005020 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fe4:	fdc42703          	lw	a4,-36(s0)
    80004fe8:	47bd                	li	a5,15
    80004fea:	02e7ed63          	bltu	a5,a4,80005024 <argfd+0x60>
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	9c2080e7          	jalr	-1598(ra) # 800019b0 <myproc>
    80004ff6:	fdc42703          	lw	a4,-36(s0)
    80004ffa:	01a70793          	addi	a5,a4,26
    80004ffe:	078e                	slli	a5,a5,0x3
    80005000:	953e                	add	a0,a0,a5
    80005002:	611c                	ld	a5,0(a0)
    80005004:	c395                	beqz	a5,80005028 <argfd+0x64>
    return -1;
  if(pfd)
    80005006:	00090463          	beqz	s2,8000500e <argfd+0x4a>
    *pfd = fd;
    8000500a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000500e:	4501                	li	a0,0
  if(pf)
    80005010:	c091                	beqz	s1,80005014 <argfd+0x50>
    *pf = f;
    80005012:	e09c                	sd	a5,0(s1)
}
    80005014:	70a2                	ld	ra,40(sp)
    80005016:	7402                	ld	s0,32(sp)
    80005018:	64e2                	ld	s1,24(sp)
    8000501a:	6942                	ld	s2,16(sp)
    8000501c:	6145                	addi	sp,sp,48
    8000501e:	8082                	ret
    return -1;
    80005020:	557d                	li	a0,-1
    80005022:	bfcd                	j	80005014 <argfd+0x50>
    return -1;
    80005024:	557d                	li	a0,-1
    80005026:	b7fd                	j	80005014 <argfd+0x50>
    80005028:	557d                	li	a0,-1
    8000502a:	b7ed                	j	80005014 <argfd+0x50>

000000008000502c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000502c:	1101                	addi	sp,sp,-32
    8000502e:	ec06                	sd	ra,24(sp)
    80005030:	e822                	sd	s0,16(sp)
    80005032:	e426                	sd	s1,8(sp)
    80005034:	1000                	addi	s0,sp,32
    80005036:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005038:	ffffd097          	auipc	ra,0xffffd
    8000503c:	978080e7          	jalr	-1672(ra) # 800019b0 <myproc>
    80005040:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005042:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe10d0>
    80005046:	4501                	li	a0,0
    80005048:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000504a:	6398                	ld	a4,0(a5)
    8000504c:	cb19                	beqz	a4,80005062 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000504e:	2505                	addiw	a0,a0,1
    80005050:	07a1                	addi	a5,a5,8
    80005052:	fed51ce3          	bne	a0,a3,8000504a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005056:	557d                	li	a0,-1
}
    80005058:	60e2                	ld	ra,24(sp)
    8000505a:	6442                	ld	s0,16(sp)
    8000505c:	64a2                	ld	s1,8(sp)
    8000505e:	6105                	addi	sp,sp,32
    80005060:	8082                	ret
      p->ofile[fd] = f;
    80005062:	01a50793          	addi	a5,a0,26
    80005066:	078e                	slli	a5,a5,0x3
    80005068:	963e                	add	a2,a2,a5
    8000506a:	e204                	sd	s1,0(a2)
      return fd;
    8000506c:	b7f5                	j	80005058 <fdalloc+0x2c>

000000008000506e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000506e:	715d                	addi	sp,sp,-80
    80005070:	e486                	sd	ra,72(sp)
    80005072:	e0a2                	sd	s0,64(sp)
    80005074:	fc26                	sd	s1,56(sp)
    80005076:	f84a                	sd	s2,48(sp)
    80005078:	f44e                	sd	s3,40(sp)
    8000507a:	f052                	sd	s4,32(sp)
    8000507c:	ec56                	sd	s5,24(sp)
    8000507e:	0880                	addi	s0,sp,80
    80005080:	89ae                	mv	s3,a1
    80005082:	8ab2                	mv	s5,a2
    80005084:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005086:	fb040593          	addi	a1,s0,-80
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	e86080e7          	jalr	-378(ra) # 80003f10 <nameiparent>
    80005092:	892a                	mv	s2,a0
    80005094:	12050f63          	beqz	a0,800051d2 <create+0x164>
    return 0;

  ilock(dp);
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	6a4080e7          	jalr	1700(ra) # 8000373c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050a0:	4601                	li	a2,0
    800050a2:	fb040593          	addi	a1,s0,-80
    800050a6:	854a                	mv	a0,s2
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	b78080e7          	jalr	-1160(ra) # 80003c20 <dirlookup>
    800050b0:	84aa                	mv	s1,a0
    800050b2:	c921                	beqz	a0,80005102 <create+0x94>
    iunlockput(dp);
    800050b4:	854a                	mv	a0,s2
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	8e8080e7          	jalr	-1816(ra) # 8000399e <iunlockput>
    ilock(ip);
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	67c080e7          	jalr	1660(ra) # 8000373c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050c8:	2981                	sext.w	s3,s3
    800050ca:	4789                	li	a5,2
    800050cc:	02f99463          	bne	s3,a5,800050f4 <create+0x86>
    800050d0:	0444d783          	lhu	a5,68(s1)
    800050d4:	37f9                	addiw	a5,a5,-2
    800050d6:	17c2                	slli	a5,a5,0x30
    800050d8:	93c1                	srli	a5,a5,0x30
    800050da:	4705                	li	a4,1
    800050dc:	00f76c63          	bltu	a4,a5,800050f4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050e0:	8526                	mv	a0,s1
    800050e2:	60a6                	ld	ra,72(sp)
    800050e4:	6406                	ld	s0,64(sp)
    800050e6:	74e2                	ld	s1,56(sp)
    800050e8:	7942                	ld	s2,48(sp)
    800050ea:	79a2                	ld	s3,40(sp)
    800050ec:	7a02                	ld	s4,32(sp)
    800050ee:	6ae2                	ld	s5,24(sp)
    800050f0:	6161                	addi	sp,sp,80
    800050f2:	8082                	ret
    iunlockput(ip);
    800050f4:	8526                	mv	a0,s1
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	8a8080e7          	jalr	-1880(ra) # 8000399e <iunlockput>
    return 0;
    800050fe:	4481                	li	s1,0
    80005100:	b7c5                	j	800050e0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005102:	85ce                	mv	a1,s3
    80005104:	00092503          	lw	a0,0(s2)
    80005108:	ffffe097          	auipc	ra,0xffffe
    8000510c:	49c080e7          	jalr	1180(ra) # 800035a4 <ialloc>
    80005110:	84aa                	mv	s1,a0
    80005112:	c529                	beqz	a0,8000515c <create+0xee>
  ilock(ip);
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	628080e7          	jalr	1576(ra) # 8000373c <ilock>
  ip->major = major;
    8000511c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005120:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005124:	4785                	li	a5,1
    80005126:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	546080e7          	jalr	1350(ra) # 80003672 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005134:	2981                	sext.w	s3,s3
    80005136:	4785                	li	a5,1
    80005138:	02f98a63          	beq	s3,a5,8000516c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000513c:	40d0                	lw	a2,4(s1)
    8000513e:	fb040593          	addi	a1,s0,-80
    80005142:	854a                	mv	a0,s2
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	cec080e7          	jalr	-788(ra) # 80003e30 <dirlink>
    8000514c:	06054b63          	bltz	a0,800051c2 <create+0x154>
  iunlockput(dp);
    80005150:	854a                	mv	a0,s2
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	84c080e7          	jalr	-1972(ra) # 8000399e <iunlockput>
  return ip;
    8000515a:	b759                	j	800050e0 <create+0x72>
    panic("create: ialloc");
    8000515c:	00003517          	auipc	a0,0x3
    80005160:	59c50513          	addi	a0,a0,1436 # 800086f8 <syscalls+0x2b0>
    80005164:	ffffb097          	auipc	ra,0xffffb
    80005168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000516c:	04a95783          	lhu	a5,74(s2)
    80005170:	2785                	addiw	a5,a5,1
    80005172:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005176:	854a                	mv	a0,s2
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	4fa080e7          	jalr	1274(ra) # 80003672 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005180:	40d0                	lw	a2,4(s1)
    80005182:	00003597          	auipc	a1,0x3
    80005186:	58658593          	addi	a1,a1,1414 # 80008708 <syscalls+0x2c0>
    8000518a:	8526                	mv	a0,s1
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	ca4080e7          	jalr	-860(ra) # 80003e30 <dirlink>
    80005194:	00054f63          	bltz	a0,800051b2 <create+0x144>
    80005198:	00492603          	lw	a2,4(s2)
    8000519c:	00003597          	auipc	a1,0x3
    800051a0:	57458593          	addi	a1,a1,1396 # 80008710 <syscalls+0x2c8>
    800051a4:	8526                	mv	a0,s1
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	c8a080e7          	jalr	-886(ra) # 80003e30 <dirlink>
    800051ae:	f80557e3          	bgez	a0,8000513c <create+0xce>
      panic("create dots");
    800051b2:	00003517          	auipc	a0,0x3
    800051b6:	56650513          	addi	a0,a0,1382 # 80008718 <syscalls+0x2d0>
    800051ba:	ffffb097          	auipc	ra,0xffffb
    800051be:	384080e7          	jalr	900(ra) # 8000053e <panic>
    panic("create: dirlink");
    800051c2:	00003517          	auipc	a0,0x3
    800051c6:	56650513          	addi	a0,a0,1382 # 80008728 <syscalls+0x2e0>
    800051ca:	ffffb097          	auipc	ra,0xffffb
    800051ce:	374080e7          	jalr	884(ra) # 8000053e <panic>
    return 0;
    800051d2:	84aa                	mv	s1,a0
    800051d4:	b731                	j	800050e0 <create+0x72>

00000000800051d6 <sys_dup>:
{
    800051d6:	7179                	addi	sp,sp,-48
    800051d8:	f406                	sd	ra,40(sp)
    800051da:	f022                	sd	s0,32(sp)
    800051dc:	ec26                	sd	s1,24(sp)
    800051de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051e0:	fd840613          	addi	a2,s0,-40
    800051e4:	4581                	li	a1,0
    800051e6:	4501                	li	a0,0
    800051e8:	00000097          	auipc	ra,0x0
    800051ec:	ddc080e7          	jalr	-548(ra) # 80004fc4 <argfd>
    return -1;
    800051f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051f2:	02054363          	bltz	a0,80005218 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051f6:	fd843503          	ld	a0,-40(s0)
    800051fa:	00000097          	auipc	ra,0x0
    800051fe:	e32080e7          	jalr	-462(ra) # 8000502c <fdalloc>
    80005202:	84aa                	mv	s1,a0
    return -1;
    80005204:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005206:	00054963          	bltz	a0,80005218 <sys_dup+0x42>
  filedup(f);
    8000520a:	fd843503          	ld	a0,-40(s0)
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	37a080e7          	jalr	890(ra) # 80004588 <filedup>
  return fd;
    80005216:	87a6                	mv	a5,s1
}
    80005218:	853e                	mv	a0,a5
    8000521a:	70a2                	ld	ra,40(sp)
    8000521c:	7402                	ld	s0,32(sp)
    8000521e:	64e2                	ld	s1,24(sp)
    80005220:	6145                	addi	sp,sp,48
    80005222:	8082                	ret

0000000080005224 <sys_read>:
{
    80005224:	7179                	addi	sp,sp,-48
    80005226:	f406                	sd	ra,40(sp)
    80005228:	f022                	sd	s0,32(sp)
    8000522a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522c:	fe840613          	addi	a2,s0,-24
    80005230:	4581                	li	a1,0
    80005232:	4501                	li	a0,0
    80005234:	00000097          	auipc	ra,0x0
    80005238:	d90080e7          	jalr	-624(ra) # 80004fc4 <argfd>
    return -1;
    8000523c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523e:	04054163          	bltz	a0,80005280 <sys_read+0x5c>
    80005242:	fe440593          	addi	a1,s0,-28
    80005246:	4509                	li	a0,2
    80005248:	ffffe097          	auipc	ra,0xffffe
    8000524c:	938080e7          	jalr	-1736(ra) # 80002b80 <argint>
    return -1;
    80005250:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005252:	02054763          	bltz	a0,80005280 <sys_read+0x5c>
    80005256:	fd840593          	addi	a1,s0,-40
    8000525a:	4505                	li	a0,1
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	946080e7          	jalr	-1722(ra) # 80002ba2 <argaddr>
    return -1;
    80005264:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005266:	00054d63          	bltz	a0,80005280 <sys_read+0x5c>
  return fileread(f, p, n);
    8000526a:	fe442603          	lw	a2,-28(s0)
    8000526e:	fd843583          	ld	a1,-40(s0)
    80005272:	fe843503          	ld	a0,-24(s0)
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	49e080e7          	jalr	1182(ra) # 80004714 <fileread>
    8000527e:	87aa                	mv	a5,a0
}
    80005280:	853e                	mv	a0,a5
    80005282:	70a2                	ld	ra,40(sp)
    80005284:	7402                	ld	s0,32(sp)
    80005286:	6145                	addi	sp,sp,48
    80005288:	8082                	ret

000000008000528a <sys_write>:
{
    8000528a:	7179                	addi	sp,sp,-48
    8000528c:	f406                	sd	ra,40(sp)
    8000528e:	f022                	sd	s0,32(sp)
    80005290:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005292:	fe840613          	addi	a2,s0,-24
    80005296:	4581                	li	a1,0
    80005298:	4501                	li	a0,0
    8000529a:	00000097          	auipc	ra,0x0
    8000529e:	d2a080e7          	jalr	-726(ra) # 80004fc4 <argfd>
    return -1;
    800052a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a4:	04054163          	bltz	a0,800052e6 <sys_write+0x5c>
    800052a8:	fe440593          	addi	a1,s0,-28
    800052ac:	4509                	li	a0,2
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	8d2080e7          	jalr	-1838(ra) # 80002b80 <argint>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b8:	02054763          	bltz	a0,800052e6 <sys_write+0x5c>
    800052bc:	fd840593          	addi	a1,s0,-40
    800052c0:	4505                	li	a0,1
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	8e0080e7          	jalr	-1824(ra) # 80002ba2 <argaddr>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052cc:	00054d63          	bltz	a0,800052e6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052d0:	fe442603          	lw	a2,-28(s0)
    800052d4:	fd843583          	ld	a1,-40(s0)
    800052d8:	fe843503          	ld	a0,-24(s0)
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	4fa080e7          	jalr	1274(ra) # 800047d6 <filewrite>
    800052e4:	87aa                	mv	a5,a0
}
    800052e6:	853e                	mv	a0,a5
    800052e8:	70a2                	ld	ra,40(sp)
    800052ea:	7402                	ld	s0,32(sp)
    800052ec:	6145                	addi	sp,sp,48
    800052ee:	8082                	ret

00000000800052f0 <sys_close>:
{
    800052f0:	1101                	addi	sp,sp,-32
    800052f2:	ec06                	sd	ra,24(sp)
    800052f4:	e822                	sd	s0,16(sp)
    800052f6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052f8:	fe040613          	addi	a2,s0,-32
    800052fc:	fec40593          	addi	a1,s0,-20
    80005300:	4501                	li	a0,0
    80005302:	00000097          	auipc	ra,0x0
    80005306:	cc2080e7          	jalr	-830(ra) # 80004fc4 <argfd>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000530c:	02054463          	bltz	a0,80005334 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	6a0080e7          	jalr	1696(ra) # 800019b0 <myproc>
    80005318:	fec42783          	lw	a5,-20(s0)
    8000531c:	07e9                	addi	a5,a5,26
    8000531e:	078e                	slli	a5,a5,0x3
    80005320:	97aa                	add	a5,a5,a0
    80005322:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005326:	fe043503          	ld	a0,-32(s0)
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	2b0080e7          	jalr	688(ra) # 800045da <fileclose>
  return 0;
    80005332:	4781                	li	a5,0
}
    80005334:	853e                	mv	a0,a5
    80005336:	60e2                	ld	ra,24(sp)
    80005338:	6442                	ld	s0,16(sp)
    8000533a:	6105                	addi	sp,sp,32
    8000533c:	8082                	ret

000000008000533e <sys_fstat>:
{
    8000533e:	1101                	addi	sp,sp,-32
    80005340:	ec06                	sd	ra,24(sp)
    80005342:	e822                	sd	s0,16(sp)
    80005344:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005346:	fe840613          	addi	a2,s0,-24
    8000534a:	4581                	li	a1,0
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	c76080e7          	jalr	-906(ra) # 80004fc4 <argfd>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005358:	02054563          	bltz	a0,80005382 <sys_fstat+0x44>
    8000535c:	fe040593          	addi	a1,s0,-32
    80005360:	4505                	li	a0,1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	840080e7          	jalr	-1984(ra) # 80002ba2 <argaddr>
    return -1;
    8000536a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000536c:	00054b63          	bltz	a0,80005382 <sys_fstat+0x44>
  return filestat(f, st);
    80005370:	fe043583          	ld	a1,-32(s0)
    80005374:	fe843503          	ld	a0,-24(s0)
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	32a080e7          	jalr	810(ra) # 800046a2 <filestat>
    80005380:	87aa                	mv	a5,a0
}
    80005382:	853e                	mv	a0,a5
    80005384:	60e2                	ld	ra,24(sp)
    80005386:	6442                	ld	s0,16(sp)
    80005388:	6105                	addi	sp,sp,32
    8000538a:	8082                	ret

000000008000538c <sys_link>:
{
    8000538c:	7169                	addi	sp,sp,-304
    8000538e:	f606                	sd	ra,296(sp)
    80005390:	f222                	sd	s0,288(sp)
    80005392:	ee26                	sd	s1,280(sp)
    80005394:	ea4a                	sd	s2,272(sp)
    80005396:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005398:	08000613          	li	a2,128
    8000539c:	ed040593          	addi	a1,s0,-304
    800053a0:	4501                	li	a0,0
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	822080e7          	jalr	-2014(ra) # 80002bc4 <argstr>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ac:	10054e63          	bltz	a0,800054c8 <sys_link+0x13c>
    800053b0:	08000613          	li	a2,128
    800053b4:	f5040593          	addi	a1,s0,-176
    800053b8:	4505                	li	a0,1
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	80a080e7          	jalr	-2038(ra) # 80002bc4 <argstr>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c4:	10054263          	bltz	a0,800054c8 <sys_link+0x13c>
  begin_op();
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	d46080e7          	jalr	-698(ra) # 8000410e <begin_op>
  if((ip = namei(old)) == 0){
    800053d0:	ed040513          	addi	a0,s0,-304
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	b1e080e7          	jalr	-1250(ra) # 80003ef2 <namei>
    800053dc:	84aa                	mv	s1,a0
    800053de:	c551                	beqz	a0,8000546a <sys_link+0xde>
  ilock(ip);
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	35c080e7          	jalr	860(ra) # 8000373c <ilock>
  if(ip->type == T_DIR){
    800053e8:	04449703          	lh	a4,68(s1)
    800053ec:	4785                	li	a5,1
    800053ee:	08f70463          	beq	a4,a5,80005476 <sys_link+0xea>
  ip->nlink++;
    800053f2:	04a4d783          	lhu	a5,74(s1)
    800053f6:	2785                	addiw	a5,a5,1
    800053f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053fc:	8526                	mv	a0,s1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	274080e7          	jalr	628(ra) # 80003672 <iupdate>
  iunlock(ip);
    80005406:	8526                	mv	a0,s1
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	3f6080e7          	jalr	1014(ra) # 800037fe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005410:	fd040593          	addi	a1,s0,-48
    80005414:	f5040513          	addi	a0,s0,-176
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	af8080e7          	jalr	-1288(ra) # 80003f10 <nameiparent>
    80005420:	892a                	mv	s2,a0
    80005422:	c935                	beqz	a0,80005496 <sys_link+0x10a>
  ilock(dp);
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	318080e7          	jalr	792(ra) # 8000373c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000542c:	00092703          	lw	a4,0(s2)
    80005430:	409c                	lw	a5,0(s1)
    80005432:	04f71d63          	bne	a4,a5,8000548c <sys_link+0x100>
    80005436:	40d0                	lw	a2,4(s1)
    80005438:	fd040593          	addi	a1,s0,-48
    8000543c:	854a                	mv	a0,s2
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	9f2080e7          	jalr	-1550(ra) # 80003e30 <dirlink>
    80005446:	04054363          	bltz	a0,8000548c <sys_link+0x100>
  iunlockput(dp);
    8000544a:	854a                	mv	a0,s2
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	552080e7          	jalr	1362(ra) # 8000399e <iunlockput>
  iput(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	4a0080e7          	jalr	1184(ra) # 800038f6 <iput>
  end_op();
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	d30080e7          	jalr	-720(ra) # 8000418e <end_op>
  return 0;
    80005466:	4781                	li	a5,0
    80005468:	a085                	j	800054c8 <sys_link+0x13c>
    end_op();
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	d24080e7          	jalr	-732(ra) # 8000418e <end_op>
    return -1;
    80005472:	57fd                	li	a5,-1
    80005474:	a891                	j	800054c8 <sys_link+0x13c>
    iunlockput(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	526080e7          	jalr	1318(ra) # 8000399e <iunlockput>
    end_op();
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	d0e080e7          	jalr	-754(ra) # 8000418e <end_op>
    return -1;
    80005488:	57fd                	li	a5,-1
    8000548a:	a83d                	j	800054c8 <sys_link+0x13c>
    iunlockput(dp);
    8000548c:	854a                	mv	a0,s2
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	510080e7          	jalr	1296(ra) # 8000399e <iunlockput>
  ilock(ip);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	2a4080e7          	jalr	676(ra) # 8000373c <ilock>
  ip->nlink--;
    800054a0:	04a4d783          	lhu	a5,74(s1)
    800054a4:	37fd                	addiw	a5,a5,-1
    800054a6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	1c6080e7          	jalr	454(ra) # 80003672 <iupdate>
  iunlockput(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	4e8080e7          	jalr	1256(ra) # 8000399e <iunlockput>
  end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	cd0080e7          	jalr	-816(ra) # 8000418e <end_op>
  return -1;
    800054c6:	57fd                	li	a5,-1
}
    800054c8:	853e                	mv	a0,a5
    800054ca:	70b2                	ld	ra,296(sp)
    800054cc:	7412                	ld	s0,288(sp)
    800054ce:	64f2                	ld	s1,280(sp)
    800054d0:	6952                	ld	s2,272(sp)
    800054d2:	6155                	addi	sp,sp,304
    800054d4:	8082                	ret

00000000800054d6 <sys_unlink>:
{
    800054d6:	7151                	addi	sp,sp,-240
    800054d8:	f586                	sd	ra,232(sp)
    800054da:	f1a2                	sd	s0,224(sp)
    800054dc:	eda6                	sd	s1,216(sp)
    800054de:	e9ca                	sd	s2,208(sp)
    800054e0:	e5ce                	sd	s3,200(sp)
    800054e2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054e4:	08000613          	li	a2,128
    800054e8:	f3040593          	addi	a1,s0,-208
    800054ec:	4501                	li	a0,0
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	6d6080e7          	jalr	1750(ra) # 80002bc4 <argstr>
    800054f6:	18054163          	bltz	a0,80005678 <sys_unlink+0x1a2>
  begin_op();
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	c14080e7          	jalr	-1004(ra) # 8000410e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005502:	fb040593          	addi	a1,s0,-80
    80005506:	f3040513          	addi	a0,s0,-208
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	a06080e7          	jalr	-1530(ra) # 80003f10 <nameiparent>
    80005512:	84aa                	mv	s1,a0
    80005514:	c979                	beqz	a0,800055ea <sys_unlink+0x114>
  ilock(dp);
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	226080e7          	jalr	550(ra) # 8000373c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000551e:	00003597          	auipc	a1,0x3
    80005522:	1ea58593          	addi	a1,a1,490 # 80008708 <syscalls+0x2c0>
    80005526:	fb040513          	addi	a0,s0,-80
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	6dc080e7          	jalr	1756(ra) # 80003c06 <namecmp>
    80005532:	14050a63          	beqz	a0,80005686 <sys_unlink+0x1b0>
    80005536:	00003597          	auipc	a1,0x3
    8000553a:	1da58593          	addi	a1,a1,474 # 80008710 <syscalls+0x2c8>
    8000553e:	fb040513          	addi	a0,s0,-80
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	6c4080e7          	jalr	1732(ra) # 80003c06 <namecmp>
    8000554a:	12050e63          	beqz	a0,80005686 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000554e:	f2c40613          	addi	a2,s0,-212
    80005552:	fb040593          	addi	a1,s0,-80
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	6c8080e7          	jalr	1736(ra) # 80003c20 <dirlookup>
    80005560:	892a                	mv	s2,a0
    80005562:	12050263          	beqz	a0,80005686 <sys_unlink+0x1b0>
  ilock(ip);
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	1d6080e7          	jalr	470(ra) # 8000373c <ilock>
  if(ip->nlink < 1)
    8000556e:	04a91783          	lh	a5,74(s2)
    80005572:	08f05263          	blez	a5,800055f6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005576:	04491703          	lh	a4,68(s2)
    8000557a:	4785                	li	a5,1
    8000557c:	08f70563          	beq	a4,a5,80005606 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005580:	4641                	li	a2,16
    80005582:	4581                	li	a1,0
    80005584:	fc040513          	addi	a0,s0,-64
    80005588:	ffffb097          	auipc	ra,0xffffb
    8000558c:	758080e7          	jalr	1880(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005590:	4741                	li	a4,16
    80005592:	f2c42683          	lw	a3,-212(s0)
    80005596:	fc040613          	addi	a2,s0,-64
    8000559a:	4581                	li	a1,0
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	54a080e7          	jalr	1354(ra) # 80003ae8 <writei>
    800055a6:	47c1                	li	a5,16
    800055a8:	0af51563          	bne	a0,a5,80005652 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ac:	04491703          	lh	a4,68(s2)
    800055b0:	4785                	li	a5,1
    800055b2:	0af70863          	beq	a4,a5,80005662 <sys_unlink+0x18c>
  iunlockput(dp);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	3e6080e7          	jalr	998(ra) # 8000399e <iunlockput>
  ip->nlink--;
    800055c0:	04a95783          	lhu	a5,74(s2)
    800055c4:	37fd                	addiw	a5,a5,-1
    800055c6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055ca:	854a                	mv	a0,s2
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	0a6080e7          	jalr	166(ra) # 80003672 <iupdate>
  iunlockput(ip);
    800055d4:	854a                	mv	a0,s2
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	3c8080e7          	jalr	968(ra) # 8000399e <iunlockput>
  end_op();
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	bb0080e7          	jalr	-1104(ra) # 8000418e <end_op>
  return 0;
    800055e6:	4501                	li	a0,0
    800055e8:	a84d                	j	8000569a <sys_unlink+0x1c4>
    end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	ba4080e7          	jalr	-1116(ra) # 8000418e <end_op>
    return -1;
    800055f2:	557d                	li	a0,-1
    800055f4:	a05d                	j	8000569a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055f6:	00003517          	auipc	a0,0x3
    800055fa:	14250513          	addi	a0,a0,322 # 80008738 <syscalls+0x2f0>
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005606:	04c92703          	lw	a4,76(s2)
    8000560a:	02000793          	li	a5,32
    8000560e:	f6e7f9e3          	bgeu	a5,a4,80005580 <sys_unlink+0xaa>
    80005612:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005616:	4741                	li	a4,16
    80005618:	86ce                	mv	a3,s3
    8000561a:	f1840613          	addi	a2,s0,-232
    8000561e:	4581                	li	a1,0
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	3ce080e7          	jalr	974(ra) # 800039f0 <readi>
    8000562a:	47c1                	li	a5,16
    8000562c:	00f51b63          	bne	a0,a5,80005642 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005630:	f1845783          	lhu	a5,-232(s0)
    80005634:	e7a1                	bnez	a5,8000567c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005636:	29c1                	addiw	s3,s3,16
    80005638:	04c92783          	lw	a5,76(s2)
    8000563c:	fcf9ede3          	bltu	s3,a5,80005616 <sys_unlink+0x140>
    80005640:	b781                	j	80005580 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005642:	00003517          	auipc	a0,0x3
    80005646:	10e50513          	addi	a0,a0,270 # 80008750 <syscalls+0x308>
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	ef4080e7          	jalr	-268(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005652:	00003517          	auipc	a0,0x3
    80005656:	11650513          	addi	a0,a0,278 # 80008768 <syscalls+0x320>
    8000565a:	ffffb097          	auipc	ra,0xffffb
    8000565e:	ee4080e7          	jalr	-284(ra) # 8000053e <panic>
    dp->nlink--;
    80005662:	04a4d783          	lhu	a5,74(s1)
    80005666:	37fd                	addiw	a5,a5,-1
    80005668:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	004080e7          	jalr	4(ra) # 80003672 <iupdate>
    80005676:	b781                	j	800055b6 <sys_unlink+0xe0>
    return -1;
    80005678:	557d                	li	a0,-1
    8000567a:	a005                	j	8000569a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000567c:	854a                	mv	a0,s2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	320080e7          	jalr	800(ra) # 8000399e <iunlockput>
  iunlockput(dp);
    80005686:	8526                	mv	a0,s1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	316080e7          	jalr	790(ra) # 8000399e <iunlockput>
  end_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	afe080e7          	jalr	-1282(ra) # 8000418e <end_op>
  return -1;
    80005698:	557d                	li	a0,-1
}
    8000569a:	70ae                	ld	ra,232(sp)
    8000569c:	740e                	ld	s0,224(sp)
    8000569e:	64ee                	ld	s1,216(sp)
    800056a0:	694e                	ld	s2,208(sp)
    800056a2:	69ae                	ld	s3,200(sp)
    800056a4:	616d                	addi	sp,sp,240
    800056a6:	8082                	ret

00000000800056a8 <sys_open>:

uint64
sys_open(void)
{
    800056a8:	7131                	addi	sp,sp,-192
    800056aa:	fd06                	sd	ra,184(sp)
    800056ac:	f922                	sd	s0,176(sp)
    800056ae:	f526                	sd	s1,168(sp)
    800056b0:	f14a                	sd	s2,160(sp)
    800056b2:	ed4e                	sd	s3,152(sp)
    800056b4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056b6:	08000613          	li	a2,128
    800056ba:	f5040593          	addi	a1,s0,-176
    800056be:	4501                	li	a0,0
    800056c0:	ffffd097          	auipc	ra,0xffffd
    800056c4:	504080e7          	jalr	1284(ra) # 80002bc4 <argstr>
    return -1;
    800056c8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ca:	0c054163          	bltz	a0,8000578c <sys_open+0xe4>
    800056ce:	f4c40593          	addi	a1,s0,-180
    800056d2:	4505                	li	a0,1
    800056d4:	ffffd097          	auipc	ra,0xffffd
    800056d8:	4ac080e7          	jalr	1196(ra) # 80002b80 <argint>
    800056dc:	0a054863          	bltz	a0,8000578c <sys_open+0xe4>

  begin_op();
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	a2e080e7          	jalr	-1490(ra) # 8000410e <begin_op>

  if(omode & O_CREATE){
    800056e8:	f4c42783          	lw	a5,-180(s0)
    800056ec:	2007f793          	andi	a5,a5,512
    800056f0:	cbdd                	beqz	a5,800057a6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056f2:	4681                	li	a3,0
    800056f4:	4601                	li	a2,0
    800056f6:	4589                	li	a1,2
    800056f8:	f5040513          	addi	a0,s0,-176
    800056fc:	00000097          	auipc	ra,0x0
    80005700:	972080e7          	jalr	-1678(ra) # 8000506e <create>
    80005704:	892a                	mv	s2,a0
    if(ip == 0){
    80005706:	c959                	beqz	a0,8000579c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005708:	04491703          	lh	a4,68(s2)
    8000570c:	478d                	li	a5,3
    8000570e:	00f71763          	bne	a4,a5,8000571c <sys_open+0x74>
    80005712:	04695703          	lhu	a4,70(s2)
    80005716:	47a5                	li	a5,9
    80005718:	0ce7ec63          	bltu	a5,a4,800057f0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	e02080e7          	jalr	-510(ra) # 8000451e <filealloc>
    80005724:	89aa                	mv	s3,a0
    80005726:	10050263          	beqz	a0,8000582a <sys_open+0x182>
    8000572a:	00000097          	auipc	ra,0x0
    8000572e:	902080e7          	jalr	-1790(ra) # 8000502c <fdalloc>
    80005732:	84aa                	mv	s1,a0
    80005734:	0e054663          	bltz	a0,80005820 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005738:	04491703          	lh	a4,68(s2)
    8000573c:	478d                	li	a5,3
    8000573e:	0cf70463          	beq	a4,a5,80005806 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005742:	4789                	li	a5,2
    80005744:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005748:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000574c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005750:	f4c42783          	lw	a5,-180(s0)
    80005754:	0017c713          	xori	a4,a5,1
    80005758:	8b05                	andi	a4,a4,1
    8000575a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000575e:	0037f713          	andi	a4,a5,3
    80005762:	00e03733          	snez	a4,a4
    80005766:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000576a:	4007f793          	andi	a5,a5,1024
    8000576e:	c791                	beqz	a5,8000577a <sys_open+0xd2>
    80005770:	04491703          	lh	a4,68(s2)
    80005774:	4789                	li	a5,2
    80005776:	08f70f63          	beq	a4,a5,80005814 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000577a:	854a                	mv	a0,s2
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	082080e7          	jalr	130(ra) # 800037fe <iunlock>
  end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	a0a080e7          	jalr	-1526(ra) # 8000418e <end_op>

  return fd;
}
    8000578c:	8526                	mv	a0,s1
    8000578e:	70ea                	ld	ra,184(sp)
    80005790:	744a                	ld	s0,176(sp)
    80005792:	74aa                	ld	s1,168(sp)
    80005794:	790a                	ld	s2,160(sp)
    80005796:	69ea                	ld	s3,152(sp)
    80005798:	6129                	addi	sp,sp,192
    8000579a:	8082                	ret
      end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	9f2080e7          	jalr	-1550(ra) # 8000418e <end_op>
      return -1;
    800057a4:	b7e5                	j	8000578c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057a6:	f5040513          	addi	a0,s0,-176
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	748080e7          	jalr	1864(ra) # 80003ef2 <namei>
    800057b2:	892a                	mv	s2,a0
    800057b4:	c905                	beqz	a0,800057e4 <sys_open+0x13c>
    ilock(ip);
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	f86080e7          	jalr	-122(ra) # 8000373c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057be:	04491703          	lh	a4,68(s2)
    800057c2:	4785                	li	a5,1
    800057c4:	f4f712e3          	bne	a4,a5,80005708 <sys_open+0x60>
    800057c8:	f4c42783          	lw	a5,-180(s0)
    800057cc:	dba1                	beqz	a5,8000571c <sys_open+0x74>
      iunlockput(ip);
    800057ce:	854a                	mv	a0,s2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	1ce080e7          	jalr	462(ra) # 8000399e <iunlockput>
      end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	9b6080e7          	jalr	-1610(ra) # 8000418e <end_op>
      return -1;
    800057e0:	54fd                	li	s1,-1
    800057e2:	b76d                	j	8000578c <sys_open+0xe4>
      end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	9aa080e7          	jalr	-1622(ra) # 8000418e <end_op>
      return -1;
    800057ec:	54fd                	li	s1,-1
    800057ee:	bf79                	j	8000578c <sys_open+0xe4>
    iunlockput(ip);
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	1ac080e7          	jalr	428(ra) # 8000399e <iunlockput>
    end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	994080e7          	jalr	-1644(ra) # 8000418e <end_op>
    return -1;
    80005802:	54fd                	li	s1,-1
    80005804:	b761                	j	8000578c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005806:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000580a:	04691783          	lh	a5,70(s2)
    8000580e:	02f99223          	sh	a5,36(s3)
    80005812:	bf2d                	j	8000574c <sys_open+0xa4>
    itrunc(ip);
    80005814:	854a                	mv	a0,s2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	034080e7          	jalr	52(ra) # 8000384a <itrunc>
    8000581e:	bfb1                	j	8000577a <sys_open+0xd2>
      fileclose(f);
    80005820:	854e                	mv	a0,s3
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	db8080e7          	jalr	-584(ra) # 800045da <fileclose>
    iunlockput(ip);
    8000582a:	854a                	mv	a0,s2
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	172080e7          	jalr	370(ra) # 8000399e <iunlockput>
    end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	95a080e7          	jalr	-1702(ra) # 8000418e <end_op>
    return -1;
    8000583c:	54fd                	li	s1,-1
    8000583e:	b7b9                	j	8000578c <sys_open+0xe4>

0000000080005840 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005840:	7175                	addi	sp,sp,-144
    80005842:	e506                	sd	ra,136(sp)
    80005844:	e122                	sd	s0,128(sp)
    80005846:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	8c6080e7          	jalr	-1850(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005850:	08000613          	li	a2,128
    80005854:	f7040593          	addi	a1,s0,-144
    80005858:	4501                	li	a0,0
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	36a080e7          	jalr	874(ra) # 80002bc4 <argstr>
    80005862:	02054963          	bltz	a0,80005894 <sys_mkdir+0x54>
    80005866:	4681                	li	a3,0
    80005868:	4601                	li	a2,0
    8000586a:	4585                	li	a1,1
    8000586c:	f7040513          	addi	a0,s0,-144
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	7fe080e7          	jalr	2046(ra) # 8000506e <create>
    80005878:	cd11                	beqz	a0,80005894 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	124080e7          	jalr	292(ra) # 8000399e <iunlockput>
  end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	90c080e7          	jalr	-1780(ra) # 8000418e <end_op>
  return 0;
    8000588a:	4501                	li	a0,0
}
    8000588c:	60aa                	ld	ra,136(sp)
    8000588e:	640a                	ld	s0,128(sp)
    80005890:	6149                	addi	sp,sp,144
    80005892:	8082                	ret
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	8fa080e7          	jalr	-1798(ra) # 8000418e <end_op>
    return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	b7fd                	j	8000588c <sys_mkdir+0x4c>

00000000800058a0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058a0:	7135                	addi	sp,sp,-160
    800058a2:	ed06                	sd	ra,152(sp)
    800058a4:	e922                	sd	s0,144(sp)
    800058a6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	866080e7          	jalr	-1946(ra) # 8000410e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058b0:	08000613          	li	a2,128
    800058b4:	f7040593          	addi	a1,s0,-144
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	30a080e7          	jalr	778(ra) # 80002bc4 <argstr>
    800058c2:	04054a63          	bltz	a0,80005916 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058c6:	f6c40593          	addi	a1,s0,-148
    800058ca:	4505                	li	a0,1
    800058cc:	ffffd097          	auipc	ra,0xffffd
    800058d0:	2b4080e7          	jalr	692(ra) # 80002b80 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058d4:	04054163          	bltz	a0,80005916 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058d8:	f6840593          	addi	a1,s0,-152
    800058dc:	4509                	li	a0,2
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	2a2080e7          	jalr	674(ra) # 80002b80 <argint>
     argint(1, &major) < 0 ||
    800058e6:	02054863          	bltz	a0,80005916 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058ea:	f6841683          	lh	a3,-152(s0)
    800058ee:	f6c41603          	lh	a2,-148(s0)
    800058f2:	458d                	li	a1,3
    800058f4:	f7040513          	addi	a0,s0,-144
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	776080e7          	jalr	1910(ra) # 8000506e <create>
     argint(2, &minor) < 0 ||
    80005900:	c919                	beqz	a0,80005916 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	09c080e7          	jalr	156(ra) # 8000399e <iunlockput>
  end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	884080e7          	jalr	-1916(ra) # 8000418e <end_op>
  return 0;
    80005912:	4501                	li	a0,0
    80005914:	a031                	j	80005920 <sys_mknod+0x80>
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	878080e7          	jalr	-1928(ra) # 8000418e <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
}
    80005920:	60ea                	ld	ra,152(sp)
    80005922:	644a                	ld	s0,144(sp)
    80005924:	610d                	addi	sp,sp,160
    80005926:	8082                	ret

0000000080005928 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005928:	7135                	addi	sp,sp,-160
    8000592a:	ed06                	sd	ra,152(sp)
    8000592c:	e922                	sd	s0,144(sp)
    8000592e:	e526                	sd	s1,136(sp)
    80005930:	e14a                	sd	s2,128(sp)
    80005932:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005934:	ffffc097          	auipc	ra,0xffffc
    80005938:	07c080e7          	jalr	124(ra) # 800019b0 <myproc>
    8000593c:	892a                	mv	s2,a0
  
  begin_op();
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	7d0080e7          	jalr	2000(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005946:	08000613          	li	a2,128
    8000594a:	f6040593          	addi	a1,s0,-160
    8000594e:	4501                	li	a0,0
    80005950:	ffffd097          	auipc	ra,0xffffd
    80005954:	274080e7          	jalr	628(ra) # 80002bc4 <argstr>
    80005958:	04054b63          	bltz	a0,800059ae <sys_chdir+0x86>
    8000595c:	f6040513          	addi	a0,s0,-160
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	592080e7          	jalr	1426(ra) # 80003ef2 <namei>
    80005968:	84aa                	mv	s1,a0
    8000596a:	c131                	beqz	a0,800059ae <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	dd0080e7          	jalr	-560(ra) # 8000373c <ilock>
  if(ip->type != T_DIR){
    80005974:	04449703          	lh	a4,68(s1)
    80005978:	4785                	li	a5,1
    8000597a:	04f71063          	bne	a4,a5,800059ba <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000597e:	8526                	mv	a0,s1
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	e7e080e7          	jalr	-386(ra) # 800037fe <iunlock>
  iput(p->cwd);
    80005988:	15093503          	ld	a0,336(s2)
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	f6a080e7          	jalr	-150(ra) # 800038f6 <iput>
  end_op();
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	7fa080e7          	jalr	2042(ra) # 8000418e <end_op>
  p->cwd = ip;
    8000599c:	14993823          	sd	s1,336(s2)
  return 0;
    800059a0:	4501                	li	a0,0
}
    800059a2:	60ea                	ld	ra,152(sp)
    800059a4:	644a                	ld	s0,144(sp)
    800059a6:	64aa                	ld	s1,136(sp)
    800059a8:	690a                	ld	s2,128(sp)
    800059aa:	610d                	addi	sp,sp,160
    800059ac:	8082                	ret
    end_op();
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	7e0080e7          	jalr	2016(ra) # 8000418e <end_op>
    return -1;
    800059b6:	557d                	li	a0,-1
    800059b8:	b7ed                	j	800059a2 <sys_chdir+0x7a>
    iunlockput(ip);
    800059ba:	8526                	mv	a0,s1
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	fe2080e7          	jalr	-30(ra) # 8000399e <iunlockput>
    end_op();
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	7ca080e7          	jalr	1994(ra) # 8000418e <end_op>
    return -1;
    800059cc:	557d                	li	a0,-1
    800059ce:	bfd1                	j	800059a2 <sys_chdir+0x7a>

00000000800059d0 <sys_exec>:

uint64
sys_exec(void)
{
    800059d0:	7145                	addi	sp,sp,-464
    800059d2:	e786                	sd	ra,456(sp)
    800059d4:	e3a2                	sd	s0,448(sp)
    800059d6:	ff26                	sd	s1,440(sp)
    800059d8:	fb4a                	sd	s2,432(sp)
    800059da:	f74e                	sd	s3,424(sp)
    800059dc:	f352                	sd	s4,416(sp)
    800059de:	ef56                	sd	s5,408(sp)
    800059e0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059e2:	08000613          	li	a2,128
    800059e6:	f4040593          	addi	a1,s0,-192
    800059ea:	4501                	li	a0,0
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	1d8080e7          	jalr	472(ra) # 80002bc4 <argstr>
    return -1;
    800059f4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059f6:	0c054a63          	bltz	a0,80005aca <sys_exec+0xfa>
    800059fa:	e3840593          	addi	a1,s0,-456
    800059fe:	4505                	li	a0,1
    80005a00:	ffffd097          	auipc	ra,0xffffd
    80005a04:	1a2080e7          	jalr	418(ra) # 80002ba2 <argaddr>
    80005a08:	0c054163          	bltz	a0,80005aca <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a0c:	10000613          	li	a2,256
    80005a10:	4581                	li	a1,0
    80005a12:	e4040513          	addi	a0,s0,-448
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	2ca080e7          	jalr	714(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a1e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a22:	89a6                	mv	s3,s1
    80005a24:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a26:	02000a13          	li	s4,32
    80005a2a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a2e:	00391513          	slli	a0,s2,0x3
    80005a32:	e3040593          	addi	a1,s0,-464
    80005a36:	e3843783          	ld	a5,-456(s0)
    80005a3a:	953e                	add	a0,a0,a5
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	0aa080e7          	jalr	170(ra) # 80002ae6 <fetchaddr>
    80005a44:	02054a63          	bltz	a0,80005a78 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a48:	e3043783          	ld	a5,-464(s0)
    80005a4c:	c3b9                	beqz	a5,80005a92 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	0a6080e7          	jalr	166(ra) # 80000af4 <kalloc>
    80005a56:	85aa                	mv	a1,a0
    80005a58:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a5c:	cd11                	beqz	a0,80005a78 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a5e:	6605                	lui	a2,0x1
    80005a60:	e3043503          	ld	a0,-464(s0)
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	0d4080e7          	jalr	212(ra) # 80002b38 <fetchstr>
    80005a6c:	00054663          	bltz	a0,80005a78 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a70:	0905                	addi	s2,s2,1
    80005a72:	09a1                	addi	s3,s3,8
    80005a74:	fb491be3          	bne	s2,s4,80005a2a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a78:	10048913          	addi	s2,s1,256
    80005a7c:	6088                	ld	a0,0(s1)
    80005a7e:	c529                	beqz	a0,80005ac8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a80:	ffffb097          	auipc	ra,0xffffb
    80005a84:	f78080e7          	jalr	-136(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a88:	04a1                	addi	s1,s1,8
    80005a8a:	ff2499e3          	bne	s1,s2,80005a7c <sys_exec+0xac>
  return -1;
    80005a8e:	597d                	li	s2,-1
    80005a90:	a82d                	j	80005aca <sys_exec+0xfa>
      argv[i] = 0;
    80005a92:	0a8e                	slli	s5,s5,0x3
    80005a94:	fc040793          	addi	a5,s0,-64
    80005a98:	9abe                	add	s5,s5,a5
    80005a9a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a9e:	e4040593          	addi	a1,s0,-448
    80005aa2:	f4040513          	addi	a0,s0,-192
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	194080e7          	jalr	404(ra) # 80004c3a <exec>
    80005aae:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab0:	10048993          	addi	s3,s1,256
    80005ab4:	6088                	ld	a0,0(s1)
    80005ab6:	c911                	beqz	a0,80005aca <sys_exec+0xfa>
    kfree(argv[i]);
    80005ab8:	ffffb097          	auipc	ra,0xffffb
    80005abc:	f40080e7          	jalr	-192(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac0:	04a1                	addi	s1,s1,8
    80005ac2:	ff3499e3          	bne	s1,s3,80005ab4 <sys_exec+0xe4>
    80005ac6:	a011                	j	80005aca <sys_exec+0xfa>
  return -1;
    80005ac8:	597d                	li	s2,-1
}
    80005aca:	854a                	mv	a0,s2
    80005acc:	60be                	ld	ra,456(sp)
    80005ace:	641e                	ld	s0,448(sp)
    80005ad0:	74fa                	ld	s1,440(sp)
    80005ad2:	795a                	ld	s2,432(sp)
    80005ad4:	79ba                	ld	s3,424(sp)
    80005ad6:	7a1a                	ld	s4,416(sp)
    80005ad8:	6afa                	ld	s5,408(sp)
    80005ada:	6179                	addi	sp,sp,464
    80005adc:	8082                	ret

0000000080005ade <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ade:	7139                	addi	sp,sp,-64
    80005ae0:	fc06                	sd	ra,56(sp)
    80005ae2:	f822                	sd	s0,48(sp)
    80005ae4:	f426                	sd	s1,40(sp)
    80005ae6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ae8:	ffffc097          	auipc	ra,0xffffc
    80005aec:	ec8080e7          	jalr	-312(ra) # 800019b0 <myproc>
    80005af0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005af2:	fd840593          	addi	a1,s0,-40
    80005af6:	4501                	li	a0,0
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	0aa080e7          	jalr	170(ra) # 80002ba2 <argaddr>
    return -1;
    80005b00:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b02:	0e054063          	bltz	a0,80005be2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b06:	fc840593          	addi	a1,s0,-56
    80005b0a:	fd040513          	addi	a0,s0,-48
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	dfc080e7          	jalr	-516(ra) # 8000490a <pipealloc>
    return -1;
    80005b16:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b18:	0c054563          	bltz	a0,80005be2 <sys_pipe+0x104>
  fd0 = -1;
    80005b1c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b20:	fd043503          	ld	a0,-48(s0)
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	508080e7          	jalr	1288(ra) # 8000502c <fdalloc>
    80005b2c:	fca42223          	sw	a0,-60(s0)
    80005b30:	08054c63          	bltz	a0,80005bc8 <sys_pipe+0xea>
    80005b34:	fc843503          	ld	a0,-56(s0)
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	4f4080e7          	jalr	1268(ra) # 8000502c <fdalloc>
    80005b40:	fca42023          	sw	a0,-64(s0)
    80005b44:	06054863          	bltz	a0,80005bb4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b48:	4691                	li	a3,4
    80005b4a:	fc440613          	addi	a2,s0,-60
    80005b4e:	fd843583          	ld	a1,-40(s0)
    80005b52:	68a8                	ld	a0,80(s1)
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	b1e080e7          	jalr	-1250(ra) # 80001672 <copyout>
    80005b5c:	02054063          	bltz	a0,80005b7c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b60:	4691                	li	a3,4
    80005b62:	fc040613          	addi	a2,s0,-64
    80005b66:	fd843583          	ld	a1,-40(s0)
    80005b6a:	0591                	addi	a1,a1,4
    80005b6c:	68a8                	ld	a0,80(s1)
    80005b6e:	ffffc097          	auipc	ra,0xffffc
    80005b72:	b04080e7          	jalr	-1276(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b76:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b78:	06055563          	bgez	a0,80005be2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b7c:	fc442783          	lw	a5,-60(s0)
    80005b80:	07e9                	addi	a5,a5,26
    80005b82:	078e                	slli	a5,a5,0x3
    80005b84:	97a6                	add	a5,a5,s1
    80005b86:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b8a:	fc042503          	lw	a0,-64(s0)
    80005b8e:	0569                	addi	a0,a0,26
    80005b90:	050e                	slli	a0,a0,0x3
    80005b92:	9526                	add	a0,a0,s1
    80005b94:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b98:	fd043503          	ld	a0,-48(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	a3e080e7          	jalr	-1474(ra) # 800045da <fileclose>
    fileclose(wf);
    80005ba4:	fc843503          	ld	a0,-56(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	a32080e7          	jalr	-1486(ra) # 800045da <fileclose>
    return -1;
    80005bb0:	57fd                	li	a5,-1
    80005bb2:	a805                	j	80005be2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bb4:	fc442783          	lw	a5,-60(s0)
    80005bb8:	0007c863          	bltz	a5,80005bc8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bbc:	01a78513          	addi	a0,a5,26
    80005bc0:	050e                	slli	a0,a0,0x3
    80005bc2:	9526                	add	a0,a0,s1
    80005bc4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bc8:	fd043503          	ld	a0,-48(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	a0e080e7          	jalr	-1522(ra) # 800045da <fileclose>
    fileclose(wf);
    80005bd4:	fc843503          	ld	a0,-56(s0)
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	a02080e7          	jalr	-1534(ra) # 800045da <fileclose>
    return -1;
    80005be0:	57fd                	li	a5,-1
}
    80005be2:	853e                	mv	a0,a5
    80005be4:	70e2                	ld	ra,56(sp)
    80005be6:	7442                	ld	s0,48(sp)
    80005be8:	74a2                	ld	s1,40(sp)
    80005bea:	6121                	addi	sp,sp,64
    80005bec:	8082                	ret
	...

0000000080005bf0 <kernelvec>:
    80005bf0:	7111                	addi	sp,sp,-256
    80005bf2:	e006                	sd	ra,0(sp)
    80005bf4:	e40a                	sd	sp,8(sp)
    80005bf6:	e80e                	sd	gp,16(sp)
    80005bf8:	ec12                	sd	tp,24(sp)
    80005bfa:	f016                	sd	t0,32(sp)
    80005bfc:	f41a                	sd	t1,40(sp)
    80005bfe:	f81e                	sd	t2,48(sp)
    80005c00:	fc22                	sd	s0,56(sp)
    80005c02:	e0a6                	sd	s1,64(sp)
    80005c04:	e4aa                	sd	a0,72(sp)
    80005c06:	e8ae                	sd	a1,80(sp)
    80005c08:	ecb2                	sd	a2,88(sp)
    80005c0a:	f0b6                	sd	a3,96(sp)
    80005c0c:	f4ba                	sd	a4,104(sp)
    80005c0e:	f8be                	sd	a5,112(sp)
    80005c10:	fcc2                	sd	a6,120(sp)
    80005c12:	e146                	sd	a7,128(sp)
    80005c14:	e54a                	sd	s2,136(sp)
    80005c16:	e94e                	sd	s3,144(sp)
    80005c18:	ed52                	sd	s4,152(sp)
    80005c1a:	f156                	sd	s5,160(sp)
    80005c1c:	f55a                	sd	s6,168(sp)
    80005c1e:	f95e                	sd	s7,176(sp)
    80005c20:	fd62                	sd	s8,184(sp)
    80005c22:	e1e6                	sd	s9,192(sp)
    80005c24:	e5ea                	sd	s10,200(sp)
    80005c26:	e9ee                	sd	s11,208(sp)
    80005c28:	edf2                	sd	t3,216(sp)
    80005c2a:	f1f6                	sd	t4,224(sp)
    80005c2c:	f5fa                	sd	t5,232(sp)
    80005c2e:	f9fe                	sd	t6,240(sp)
    80005c30:	d83fc0ef          	jal	ra,800029b2 <kerneltrap>
    80005c34:	6082                	ld	ra,0(sp)
    80005c36:	6122                	ld	sp,8(sp)
    80005c38:	61c2                	ld	gp,16(sp)
    80005c3a:	7282                	ld	t0,32(sp)
    80005c3c:	7322                	ld	t1,40(sp)
    80005c3e:	73c2                	ld	t2,48(sp)
    80005c40:	7462                	ld	s0,56(sp)
    80005c42:	6486                	ld	s1,64(sp)
    80005c44:	6526                	ld	a0,72(sp)
    80005c46:	65c6                	ld	a1,80(sp)
    80005c48:	6666                	ld	a2,88(sp)
    80005c4a:	7686                	ld	a3,96(sp)
    80005c4c:	7726                	ld	a4,104(sp)
    80005c4e:	77c6                	ld	a5,112(sp)
    80005c50:	7866                	ld	a6,120(sp)
    80005c52:	688a                	ld	a7,128(sp)
    80005c54:	692a                	ld	s2,136(sp)
    80005c56:	69ca                	ld	s3,144(sp)
    80005c58:	6a6a                	ld	s4,152(sp)
    80005c5a:	7a8a                	ld	s5,160(sp)
    80005c5c:	7b2a                	ld	s6,168(sp)
    80005c5e:	7bca                	ld	s7,176(sp)
    80005c60:	7c6a                	ld	s8,184(sp)
    80005c62:	6c8e                	ld	s9,192(sp)
    80005c64:	6d2e                	ld	s10,200(sp)
    80005c66:	6dce                	ld	s11,208(sp)
    80005c68:	6e6e                	ld	t3,216(sp)
    80005c6a:	7e8e                	ld	t4,224(sp)
    80005c6c:	7f2e                	ld	t5,232(sp)
    80005c6e:	7fce                	ld	t6,240(sp)
    80005c70:	6111                	addi	sp,sp,256
    80005c72:	10200073          	sret
    80005c76:	00000013          	nop
    80005c7a:	00000013          	nop
    80005c7e:	0001                	nop

0000000080005c80 <timervec>:
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	e10c                	sd	a1,0(a0)
    80005c86:	e510                	sd	a2,8(a0)
    80005c88:	e914                	sd	a3,16(a0)
    80005c8a:	6d0c                	ld	a1,24(a0)
    80005c8c:	7110                	ld	a2,32(a0)
    80005c8e:	6194                	ld	a3,0(a1)
    80005c90:	96b2                	add	a3,a3,a2
    80005c92:	e194                	sd	a3,0(a1)
    80005c94:	4589                	li	a1,2
    80005c96:	14459073          	csrw	sip,a1
    80005c9a:	6914                	ld	a3,16(a0)
    80005c9c:	6510                	ld	a2,8(a0)
    80005c9e:	610c                	ld	a1,0(a0)
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	30200073          	mret
	...

0000000080005caa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005caa:	1141                	addi	sp,sp,-16
    80005cac:	e422                	sd	s0,8(sp)
    80005cae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cb0:	0c0007b7          	lui	a5,0xc000
    80005cb4:	4705                	li	a4,1
    80005cb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cb8:	c3d8                	sw	a4,4(a5)
}
    80005cba:	6422                	ld	s0,8(sp)
    80005cbc:	0141                	addi	sp,sp,16
    80005cbe:	8082                	ret

0000000080005cc0 <plicinithart>:

void
plicinithart(void)
{
    80005cc0:	1141                	addi	sp,sp,-16
    80005cc2:	e406                	sd	ra,8(sp)
    80005cc4:	e022                	sd	s0,0(sp)
    80005cc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	cbc080e7          	jalr	-836(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cd0:	0085171b          	slliw	a4,a0,0x8
    80005cd4:	0c0027b7          	lui	a5,0xc002
    80005cd8:	97ba                	add	a5,a5,a4
    80005cda:	40200713          	li	a4,1026
    80005cde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ce2:	00d5151b          	slliw	a0,a0,0xd
    80005ce6:	0c2017b7          	lui	a5,0xc201
    80005cea:	953e                	add	a0,a0,a5
    80005cec:	00052023          	sw	zero,0(a0)
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret

0000000080005cf8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cf8:	1141                	addi	sp,sp,-16
    80005cfa:	e406                	sd	ra,8(sp)
    80005cfc:	e022                	sd	s0,0(sp)
    80005cfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	c84080e7          	jalr	-892(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d08:	00d5179b          	slliw	a5,a0,0xd
    80005d0c:	0c201537          	lui	a0,0xc201
    80005d10:	953e                	add	a0,a0,a5
  return irq;
}
    80005d12:	4148                	lw	a0,4(a0)
    80005d14:	60a2                	ld	ra,8(sp)
    80005d16:	6402                	ld	s0,0(sp)
    80005d18:	0141                	addi	sp,sp,16
    80005d1a:	8082                	ret

0000000080005d1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	e426                	sd	s1,8(sp)
    80005d24:	1000                	addi	s0,sp,32
    80005d26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	c5c080e7          	jalr	-932(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d30:	00d5151b          	slliw	a0,a0,0xd
    80005d34:	0c2017b7          	lui	a5,0xc201
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	c3c4                	sw	s1,4(a5)
}
    80005d3c:	60e2                	ld	ra,24(sp)
    80005d3e:	6442                	ld	s0,16(sp)
    80005d40:	64a2                	ld	s1,8(sp)
    80005d42:	6105                	addi	sp,sp,32
    80005d44:	8082                	ret

0000000080005d46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d46:	1141                	addi	sp,sp,-16
    80005d48:	e406                	sd	ra,8(sp)
    80005d4a:	e022                	sd	s0,0(sp)
    80005d4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d4e:	479d                	li	a5,7
    80005d50:	06a7c963          	blt	a5,a0,80005dc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d54:	00015797          	auipc	a5,0x15
    80005d58:	2ac78793          	addi	a5,a5,684 # 8001b000 <disk>
    80005d5c:	00a78733          	add	a4,a5,a0
    80005d60:	6789                	lui	a5,0x2
    80005d62:	97ba                	add	a5,a5,a4
    80005d64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d68:	e7ad                	bnez	a5,80005dd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d6a:	00451793          	slli	a5,a0,0x4
    80005d6e:	00017717          	auipc	a4,0x17
    80005d72:	29270713          	addi	a4,a4,658 # 8001d000 <disk+0x2000>
    80005d76:	6314                	ld	a3,0(a4)
    80005d78:	96be                	add	a3,a3,a5
    80005d7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d7e:	6314                	ld	a3,0(a4)
    80005d80:	96be                	add	a3,a3,a5
    80005d82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d86:	6314                	ld	a3,0(a4)
    80005d88:	96be                	add	a3,a3,a5
    80005d8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d8e:	6318                	ld	a4,0(a4)
    80005d90:	97ba                	add	a5,a5,a4
    80005d92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d96:	00015797          	auipc	a5,0x15
    80005d9a:	26a78793          	addi	a5,a5,618 # 8001b000 <disk>
    80005d9e:	97aa                	add	a5,a5,a0
    80005da0:	6509                	lui	a0,0x2
    80005da2:	953e                	add	a0,a0,a5
    80005da4:	4785                	li	a5,1
    80005da6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005daa:	00017517          	auipc	a0,0x17
    80005dae:	26e50513          	addi	a0,a0,622 # 8001d018 <disk+0x2018>
    80005db2:	ffffc097          	auipc	ra,0xffffc
    80005db6:	488080e7          	jalr	1160(ra) # 8000223a <wakeup>
}
    80005dba:	60a2                	ld	ra,8(sp)
    80005dbc:	6402                	ld	s0,0(sp)
    80005dbe:	0141                	addi	sp,sp,16
    80005dc0:	8082                	ret
    panic("free_desc 1");
    80005dc2:	00003517          	auipc	a0,0x3
    80005dc6:	9b650513          	addi	a0,a0,-1610 # 80008778 <syscalls+0x330>
    80005dca:	ffffa097          	auipc	ra,0xffffa
    80005dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	9b650513          	addi	a0,a0,-1610 # 80008788 <syscalls+0x340>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>

0000000080005de2 <virtio_disk_init>:
{
    80005de2:	1101                	addi	sp,sp,-32
    80005de4:	ec06                	sd	ra,24(sp)
    80005de6:	e822                	sd	s0,16(sp)
    80005de8:	e426                	sd	s1,8(sp)
    80005dea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dec:	00003597          	auipc	a1,0x3
    80005df0:	9ac58593          	addi	a1,a1,-1620 # 80008798 <syscalls+0x350>
    80005df4:	00017517          	auipc	a0,0x17
    80005df8:	33450513          	addi	a0,a0,820 # 8001d128 <disk+0x2128>
    80005dfc:	ffffb097          	auipc	ra,0xffffb
    80005e00:	d58080e7          	jalr	-680(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	4398                	lw	a4,0(a5)
    80005e0a:	2701                	sext.w	a4,a4
    80005e0c:	747277b7          	lui	a5,0x74727
    80005e10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e14:	0ef71163          	bne	a4,a5,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e18:	100017b7          	lui	a5,0x10001
    80005e1c:	43dc                	lw	a5,4(a5)
    80005e1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e20:	4705                	li	a4,1
    80005e22:	0ce79a63          	bne	a5,a4,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e26:	100017b7          	lui	a5,0x10001
    80005e2a:	479c                	lw	a5,8(a5)
    80005e2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e2e:	4709                	li	a4,2
    80005e30:	0ce79363          	bne	a5,a4,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e34:	100017b7          	lui	a5,0x10001
    80005e38:	47d8                	lw	a4,12(a5)
    80005e3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3c:	554d47b7          	lui	a5,0x554d4
    80005e40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e44:	0af71963          	bne	a4,a5,80005ef6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e48:	100017b7          	lui	a5,0x10001
    80005e4c:	4705                	li	a4,1
    80005e4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e50:	470d                	li	a4,3
    80005e52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e56:	c7ffe737          	lui	a4,0xc7ffe
    80005e5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fe075f>
    80005e5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e60:	2701                	sext.w	a4,a4
    80005e62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e64:	472d                	li	a4,11
    80005e66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e68:	473d                	li	a4,15
    80005e6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e6c:	6705                	lui	a4,0x1
    80005e6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e74:	5bdc                	lw	a5,52(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e78:	c7d9                	beqz	a5,80005f06 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e7a:	471d                	li	a4,7
    80005e7c:	08f77d63          	bgeu	a4,a5,80005f16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e80:	100014b7          	lui	s1,0x10001
    80005e84:	47a1                	li	a5,8
    80005e86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e88:	6609                	lui	a2,0x2
    80005e8a:	4581                	li	a1,0
    80005e8c:	00015517          	auipc	a0,0x15
    80005e90:	17450513          	addi	a0,a0,372 # 8001b000 <disk>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	e4c080e7          	jalr	-436(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e9c:	00015717          	auipc	a4,0x15
    80005ea0:	16470713          	addi	a4,a4,356 # 8001b000 <disk>
    80005ea4:	00c75793          	srli	a5,a4,0xc
    80005ea8:	2781                	sext.w	a5,a5
    80005eaa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005eac:	00017797          	auipc	a5,0x17
    80005eb0:	15478793          	addi	a5,a5,340 # 8001d000 <disk+0x2000>
    80005eb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005eb6:	00015717          	auipc	a4,0x15
    80005eba:	1ca70713          	addi	a4,a4,458 # 8001b080 <disk+0x80>
    80005ebe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ec0:	00016717          	auipc	a4,0x16
    80005ec4:	14070713          	addi	a4,a4,320 # 8001c000 <disk+0x1000>
    80005ec8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eca:	4705                	li	a4,1
    80005ecc:	00e78c23          	sb	a4,24(a5)
    80005ed0:	00e78ca3          	sb	a4,25(a5)
    80005ed4:	00e78d23          	sb	a4,26(a5)
    80005ed8:	00e78da3          	sb	a4,27(a5)
    80005edc:	00e78e23          	sb	a4,28(a5)
    80005ee0:	00e78ea3          	sb	a4,29(a5)
    80005ee4:	00e78f23          	sb	a4,30(a5)
    80005ee8:	00e78fa3          	sb	a4,31(a5)
}
    80005eec:	60e2                	ld	ra,24(sp)
    80005eee:	6442                	ld	s0,16(sp)
    80005ef0:	64a2                	ld	s1,8(sp)
    80005ef2:	6105                	addi	sp,sp,32
    80005ef4:	8082                	ret
    panic("could not find virtio disk");
    80005ef6:	00003517          	auipc	a0,0x3
    80005efa:	8b250513          	addi	a0,a0,-1870 # 800087a8 <syscalls+0x360>
    80005efe:	ffffa097          	auipc	ra,0xffffa
    80005f02:	640080e7          	jalr	1600(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f06:	00003517          	auipc	a0,0x3
    80005f0a:	8c250513          	addi	a0,a0,-1854 # 800087c8 <syscalls+0x380>
    80005f0e:	ffffa097          	auipc	ra,0xffffa
    80005f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f16:	00003517          	auipc	a0,0x3
    80005f1a:	8d250513          	addi	a0,a0,-1838 # 800087e8 <syscalls+0x3a0>
    80005f1e:	ffffa097          	auipc	ra,0xffffa
    80005f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>

0000000080005f26 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f26:	7159                	addi	sp,sp,-112
    80005f28:	f486                	sd	ra,104(sp)
    80005f2a:	f0a2                	sd	s0,96(sp)
    80005f2c:	eca6                	sd	s1,88(sp)
    80005f2e:	e8ca                	sd	s2,80(sp)
    80005f30:	e4ce                	sd	s3,72(sp)
    80005f32:	e0d2                	sd	s4,64(sp)
    80005f34:	fc56                	sd	s5,56(sp)
    80005f36:	f85a                	sd	s6,48(sp)
    80005f38:	f45e                	sd	s7,40(sp)
    80005f3a:	f062                	sd	s8,32(sp)
    80005f3c:	ec66                	sd	s9,24(sp)
    80005f3e:	e86a                	sd	s10,16(sp)
    80005f40:	1880                	addi	s0,sp,112
    80005f42:	892a                	mv	s2,a0
    80005f44:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f46:	00c52c83          	lw	s9,12(a0)
    80005f4a:	001c9c9b          	slliw	s9,s9,0x1
    80005f4e:	1c82                	slli	s9,s9,0x20
    80005f50:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f54:	00017517          	auipc	a0,0x17
    80005f58:	1d450513          	addi	a0,a0,468 # 8001d128 <disk+0x2128>
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	c88080e7          	jalr	-888(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f64:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f66:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f68:	00015b97          	auipc	s7,0x15
    80005f6c:	098b8b93          	addi	s7,s7,152 # 8001b000 <disk>
    80005f70:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f72:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f74:	8a4e                	mv	s4,s3
    80005f76:	a051                	j	80005ffa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f78:	00fb86b3          	add	a3,s7,a5
    80005f7c:	96da                	add	a3,a3,s6
    80005f7e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f82:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f84:	0207c563          	bltz	a5,80005fae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f88:	2485                	addiw	s1,s1,1
    80005f8a:	0711                	addi	a4,a4,4
    80005f8c:	25548063          	beq	s1,s5,800061cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f90:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f92:	00017697          	auipc	a3,0x17
    80005f96:	08668693          	addi	a3,a3,134 # 8001d018 <disk+0x2018>
    80005f9a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f9c:	0006c583          	lbu	a1,0(a3)
    80005fa0:	fde1                	bnez	a1,80005f78 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fa2:	2785                	addiw	a5,a5,1
    80005fa4:	0685                	addi	a3,a3,1
    80005fa6:	ff879be3          	bne	a5,s8,80005f9c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005faa:	57fd                	li	a5,-1
    80005fac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fae:	02905a63          	blez	s1,80005fe2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fb2:	f9042503          	lw	a0,-112(s0)
    80005fb6:	00000097          	auipc	ra,0x0
    80005fba:	d90080e7          	jalr	-624(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fbe:	4785                	li	a5,1
    80005fc0:	0297d163          	bge	a5,s1,80005fe2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fc4:	f9442503          	lw	a0,-108(s0)
    80005fc8:	00000097          	auipc	ra,0x0
    80005fcc:	d7e080e7          	jalr	-642(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fd0:	4789                	li	a5,2
    80005fd2:	0097d863          	bge	a5,s1,80005fe2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd6:	f9842503          	lw	a0,-104(s0)
    80005fda:	00000097          	auipc	ra,0x0
    80005fde:	d6c080e7          	jalr	-660(ra) # 80005d46 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fe2:	00017597          	auipc	a1,0x17
    80005fe6:	14658593          	addi	a1,a1,326 # 8001d128 <disk+0x2128>
    80005fea:	00017517          	auipc	a0,0x17
    80005fee:	02e50513          	addi	a0,a0,46 # 8001d018 <disk+0x2018>
    80005ff2:	ffffc097          	auipc	ra,0xffffc
    80005ff6:	0bc080e7          	jalr	188(ra) # 800020ae <sleep>
  for(int i = 0; i < 3; i++){
    80005ffa:	f9040713          	addi	a4,s0,-112
    80005ffe:	84ce                	mv	s1,s3
    80006000:	bf41                	j	80005f90 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006002:	20058713          	addi	a4,a1,512
    80006006:	00471693          	slli	a3,a4,0x4
    8000600a:	00015717          	auipc	a4,0x15
    8000600e:	ff670713          	addi	a4,a4,-10 # 8001b000 <disk>
    80006012:	9736                	add	a4,a4,a3
    80006014:	4685                	li	a3,1
    80006016:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000601a:	20058713          	addi	a4,a1,512
    8000601e:	00471693          	slli	a3,a4,0x4
    80006022:	00015717          	auipc	a4,0x15
    80006026:	fde70713          	addi	a4,a4,-34 # 8001b000 <disk>
    8000602a:	9736                	add	a4,a4,a3
    8000602c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006030:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006034:	7679                	lui	a2,0xffffe
    80006036:	963e                	add	a2,a2,a5
    80006038:	00017697          	auipc	a3,0x17
    8000603c:	fc868693          	addi	a3,a3,-56 # 8001d000 <disk+0x2000>
    80006040:	6298                	ld	a4,0(a3)
    80006042:	9732                	add	a4,a4,a2
    80006044:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006046:	6298                	ld	a4,0(a3)
    80006048:	9732                	add	a4,a4,a2
    8000604a:	4541                	li	a0,16
    8000604c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000604e:	6298                	ld	a4,0(a3)
    80006050:	9732                	add	a4,a4,a2
    80006052:	4505                	li	a0,1
    80006054:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006058:	f9442703          	lw	a4,-108(s0)
    8000605c:	6288                	ld	a0,0(a3)
    8000605e:	962a                	add	a2,a2,a0
    80006060:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffe000e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006064:	0712                	slli	a4,a4,0x4
    80006066:	6290                	ld	a2,0(a3)
    80006068:	963a                	add	a2,a2,a4
    8000606a:	05890513          	addi	a0,s2,88
    8000606e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006070:	6294                	ld	a3,0(a3)
    80006072:	96ba                	add	a3,a3,a4
    80006074:	40000613          	li	a2,1024
    80006078:	c690                	sw	a2,8(a3)
  if(write)
    8000607a:	140d0063          	beqz	s10,800061ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000607e:	00017697          	auipc	a3,0x17
    80006082:	f826b683          	ld	a3,-126(a3) # 8001d000 <disk+0x2000>
    80006086:	96ba                	add	a3,a3,a4
    80006088:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000608c:	00015817          	auipc	a6,0x15
    80006090:	f7480813          	addi	a6,a6,-140 # 8001b000 <disk>
    80006094:	00017517          	auipc	a0,0x17
    80006098:	f6c50513          	addi	a0,a0,-148 # 8001d000 <disk+0x2000>
    8000609c:	6114                	ld	a3,0(a0)
    8000609e:	96ba                	add	a3,a3,a4
    800060a0:	00c6d603          	lhu	a2,12(a3)
    800060a4:	00166613          	ori	a2,a2,1
    800060a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ac:	f9842683          	lw	a3,-104(s0)
    800060b0:	6110                	ld	a2,0(a0)
    800060b2:	9732                	add	a4,a4,a2
    800060b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060b8:	20058613          	addi	a2,a1,512
    800060bc:	0612                	slli	a2,a2,0x4
    800060be:	9642                	add	a2,a2,a6
    800060c0:	577d                	li	a4,-1
    800060c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060c6:	00469713          	slli	a4,a3,0x4
    800060ca:	6114                	ld	a3,0(a0)
    800060cc:	96ba                	add	a3,a3,a4
    800060ce:	03078793          	addi	a5,a5,48
    800060d2:	97c2                	add	a5,a5,a6
    800060d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800060d6:	611c                	ld	a5,0(a0)
    800060d8:	97ba                	add	a5,a5,a4
    800060da:	4685                	li	a3,1
    800060dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060de:	611c                	ld	a5,0(a0)
    800060e0:	97ba                	add	a5,a5,a4
    800060e2:	4809                	li	a6,2
    800060e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060e8:	611c                	ld	a5,0(a0)
    800060ea:	973e                	add	a4,a4,a5
    800060ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800060f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060f8:	6518                	ld	a4,8(a0)
    800060fa:	00275783          	lhu	a5,2(a4)
    800060fe:	8b9d                	andi	a5,a5,7
    80006100:	0786                	slli	a5,a5,0x1
    80006102:	97ba                	add	a5,a5,a4
    80006104:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006108:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000610c:	6518                	ld	a4,8(a0)
    8000610e:	00275783          	lhu	a5,2(a4)
    80006112:	2785                	addiw	a5,a5,1
    80006114:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006118:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006124:	00492703          	lw	a4,4(s2)
    80006128:	4785                	li	a5,1
    8000612a:	02f71163          	bne	a4,a5,8000614c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000612e:	00017997          	auipc	s3,0x17
    80006132:	ffa98993          	addi	s3,s3,-6 # 8001d128 <disk+0x2128>
  while(b->disk == 1) {
    80006136:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006138:	85ce                	mv	a1,s3
    8000613a:	854a                	mv	a0,s2
    8000613c:	ffffc097          	auipc	ra,0xffffc
    80006140:	f72080e7          	jalr	-142(ra) # 800020ae <sleep>
  while(b->disk == 1) {
    80006144:	00492783          	lw	a5,4(s2)
    80006148:	fe9788e3          	beq	a5,s1,80006138 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000614c:	f9042903          	lw	s2,-112(s0)
    80006150:	20090793          	addi	a5,s2,512
    80006154:	00479713          	slli	a4,a5,0x4
    80006158:	00015797          	auipc	a5,0x15
    8000615c:	ea878793          	addi	a5,a5,-344 # 8001b000 <disk>
    80006160:	97ba                	add	a5,a5,a4
    80006162:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006166:	00017997          	auipc	s3,0x17
    8000616a:	e9a98993          	addi	s3,s3,-358 # 8001d000 <disk+0x2000>
    8000616e:	00491713          	slli	a4,s2,0x4
    80006172:	0009b783          	ld	a5,0(s3)
    80006176:	97ba                	add	a5,a5,a4
    80006178:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000617c:	854a                	mv	a0,s2
    8000617e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006182:	00000097          	auipc	ra,0x0
    80006186:	bc4080e7          	jalr	-1084(ra) # 80005d46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000618a:	8885                	andi	s1,s1,1
    8000618c:	f0ed                	bnez	s1,8000616e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000618e:	00017517          	auipc	a0,0x17
    80006192:	f9a50513          	addi	a0,a0,-102 # 8001d128 <disk+0x2128>
    80006196:	ffffb097          	auipc	ra,0xffffb
    8000619a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
}
    8000619e:	70a6                	ld	ra,104(sp)
    800061a0:	7406                	ld	s0,96(sp)
    800061a2:	64e6                	ld	s1,88(sp)
    800061a4:	6946                	ld	s2,80(sp)
    800061a6:	69a6                	ld	s3,72(sp)
    800061a8:	6a06                	ld	s4,64(sp)
    800061aa:	7ae2                	ld	s5,56(sp)
    800061ac:	7b42                	ld	s6,48(sp)
    800061ae:	7ba2                	ld	s7,40(sp)
    800061b0:	7c02                	ld	s8,32(sp)
    800061b2:	6ce2                	ld	s9,24(sp)
    800061b4:	6d42                	ld	s10,16(sp)
    800061b6:	6165                	addi	sp,sp,112
    800061b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ba:	00017697          	auipc	a3,0x17
    800061be:	e466b683          	ld	a3,-442(a3) # 8001d000 <disk+0x2000>
    800061c2:	96ba                	add	a3,a3,a4
    800061c4:	4609                	li	a2,2
    800061c6:	00c69623          	sh	a2,12(a3)
    800061ca:	b5c9                	j	8000608c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061cc:	f9042583          	lw	a1,-112(s0)
    800061d0:	20058793          	addi	a5,a1,512
    800061d4:	0792                	slli	a5,a5,0x4
    800061d6:	00015517          	auipc	a0,0x15
    800061da:	ed250513          	addi	a0,a0,-302 # 8001b0a8 <disk+0xa8>
    800061de:	953e                	add	a0,a0,a5
  if(write)
    800061e0:	e20d11e3          	bnez	s10,80006002 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061e4:	20058713          	addi	a4,a1,512
    800061e8:	00471693          	slli	a3,a4,0x4
    800061ec:	00015717          	auipc	a4,0x15
    800061f0:	e1470713          	addi	a4,a4,-492 # 8001b000 <disk>
    800061f4:	9736                	add	a4,a4,a3
    800061f6:	0a072423          	sw	zero,168(a4)
    800061fa:	b505                	j	8000601a <virtio_disk_rw+0xf4>

00000000800061fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	e04a                	sd	s2,0(sp)
    80006206:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006208:	00017517          	auipc	a0,0x17
    8000620c:	f2050513          	addi	a0,a0,-224 # 8001d128 <disk+0x2128>
    80006210:	ffffb097          	auipc	ra,0xffffb
    80006214:	9d4080e7          	jalr	-1580(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006218:	10001737          	lui	a4,0x10001
    8000621c:	533c                	lw	a5,96(a4)
    8000621e:	8b8d                	andi	a5,a5,3
    80006220:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006222:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006226:	00017797          	auipc	a5,0x17
    8000622a:	dda78793          	addi	a5,a5,-550 # 8001d000 <disk+0x2000>
    8000622e:	6b94                	ld	a3,16(a5)
    80006230:	0207d703          	lhu	a4,32(a5)
    80006234:	0026d783          	lhu	a5,2(a3)
    80006238:	06f70163          	beq	a4,a5,8000629a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000623c:	00015917          	auipc	s2,0x15
    80006240:	dc490913          	addi	s2,s2,-572 # 8001b000 <disk>
    80006244:	00017497          	auipc	s1,0x17
    80006248:	dbc48493          	addi	s1,s1,-580 # 8001d000 <disk+0x2000>
    __sync_synchronize();
    8000624c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006250:	6898                	ld	a4,16(s1)
    80006252:	0204d783          	lhu	a5,32(s1)
    80006256:	8b9d                	andi	a5,a5,7
    80006258:	078e                	slli	a5,a5,0x3
    8000625a:	97ba                	add	a5,a5,a4
    8000625c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000625e:	20078713          	addi	a4,a5,512
    80006262:	0712                	slli	a4,a4,0x4
    80006264:	974a                	add	a4,a4,s2
    80006266:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000626a:	e731                	bnez	a4,800062b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000626c:	20078793          	addi	a5,a5,512
    80006270:	0792                	slli	a5,a5,0x4
    80006272:	97ca                	add	a5,a5,s2
    80006274:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006276:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000627a:	ffffc097          	auipc	ra,0xffffc
    8000627e:	fc0080e7          	jalr	-64(ra) # 8000223a <wakeup>

    disk.used_idx += 1;
    80006282:	0204d783          	lhu	a5,32(s1)
    80006286:	2785                	addiw	a5,a5,1
    80006288:	17c2                	slli	a5,a5,0x30
    8000628a:	93c1                	srli	a5,a5,0x30
    8000628c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006290:	6898                	ld	a4,16(s1)
    80006292:	00275703          	lhu	a4,2(a4)
    80006296:	faf71be3          	bne	a4,a5,8000624c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000629a:	00017517          	auipc	a0,0x17
    8000629e:	e8e50513          	addi	a0,a0,-370 # 8001d128 <disk+0x2128>
    800062a2:	ffffb097          	auipc	ra,0xffffb
    800062a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
}
    800062aa:	60e2                	ld	ra,24(sp)
    800062ac:	6442                	ld	s0,16(sp)
    800062ae:	64a2                	ld	s1,8(sp)
    800062b0:	6902                	ld	s2,0(sp)
    800062b2:	6105                	addi	sp,sp,32
    800062b4:	8082                	ret
      panic("virtio_disk_intr status");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	55250513          	addi	a0,a0,1362 # 80008808 <syscalls+0x3c0>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
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
