
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	d8c78793          	addi	a5,a5,-628 # 80005df0 <timervec>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	5c0080e7          	jalr	1472(ra) # 800026ec <either_copyin>
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
    800001c8:	7f4080e7          	jalr	2036(ra) # 800019b8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	072080e7          	jalr	114(ra) # 80002246 <sleep>
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
    80000214:	486080e7          	jalr	1158(ra) # 80002696 <either_copyout>
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
    800002f6:	450080e7          	jalr	1104(ra) # 80002742 <procdump>
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
    8000044a:	f8c080e7          	jalr	-116(ra) # 800023d2 <wakeup>
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
    8000047c:	01078793          	addi	a5,a5,16 # 8001a488 <devsw>
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
    800008a4:	b32080e7          	jalr	-1230(ra) # 800023d2 <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	91a080e7          	jalr	-1766(ra) # 80002246 <sleep>
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
    80000b82:	e1e080e7          	jalr	-482(ra) # 8000199c <mycpu>
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
    80000bb4:	dec080e7          	jalr	-532(ra) # 8000199c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	de0080e7          	jalr	-544(ra) # 8000199c <mycpu>
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
    80000bd8:	dc8080e7          	jalr	-568(ra) # 8000199c <mycpu>
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
    80000c18:	d88080e7          	jalr	-632(ra) # 8000199c <mycpu>
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
    80000c44:	d5c080e7          	jalr	-676(ra) # 8000199c <mycpu>
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
    80000e9a:	af6080e7          	jalr	-1290(ra) # 8000198c <cpuid>
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
    80000eb6:	ada080e7          	jalr	-1318(ra) # 8000198c <cpuid>
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
    80000ed8:	9e4080e7          	jalr	-1564(ra) # 800028b8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f54080e7          	jalr	-172(ra) # 80005e30 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	240080e7          	jalr	576(ra) # 80002124 <scheduler>
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
    80000f08:	1c450513          	addi	a0,a0,452 # 800080c8 <digits+0x88>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
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
    80000f58:	93c080e7          	jalr	-1732(ra) # 80002890 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	95c080e7          	jalr	-1700(ra) # 800028b8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	eb6080e7          	jalr	-330(ra) # 80005e1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	ec4080e7          	jalr	-316(ra) # 80005e30 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	0a2080e7          	jalr	162(ra) # 80003016 <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	732080e7          	jalr	1842(ra) # 800036ae <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	6dc080e7          	jalr	1756(ra) # 80004660 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	fc6080e7          	jalr	-58(ra) # 80005f52 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d08080e7          	jalr	-760(ra) # 80001c9c <userinit>
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
    80001860:	9e448493          	addi	s1,s1,-1564 # 8000a240 <proc>
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
    8000187a:	9caa0a13          	addi	s4,s4,-1590 # 80010240 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	859d                	srai	a1,a1,0x7
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
    800018b0:	18048493          	addi	s1,s1,384
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
    800018fc:	89850513          	addi	a0,a0,-1896 # 8000a190 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	254080e7          	jalr	596(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e058593          	addi	a1,a1,-1824 # 800081e8 <digits+0x1a8>
    80001910:	00009517          	auipc	a0,0x9
    80001914:	89850513          	addi	a0,a0,-1896 # 8000a1a8 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00009497          	auipc	s1,0x9
    80001924:	92048493          	addi	s1,s1,-1760 # 8000a240 <proc>
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
    80001946:	8fe98993          	addi	s3,s3,-1794 # 80010240 <tickslock>
      initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	879d                	srai	a5,a5,0x7
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	18048493          	addi	s1,s1,384
    80001974:	fd349be3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
}
    80001978:	70e2                	ld	ra,56(sp)
    8000197a:	7442                	ld	s0,48(sp)
    8000197c:	74a2                	ld	s1,40(sp)
    8000197e:	7902                	ld	s2,32(sp)
    80001980:	69e2                	ld	s3,24(sp)
    80001982:	6a42                	ld	s4,16(sp)
    80001984:	6aa2                	ld	s5,8(sp)
    80001986:	6b02                	ld	s6,0(sp)
    80001988:	6121                	addi	sp,sp,64
    8000198a:	8082                	ret

000000008000198c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000198c:	1141                	addi	sp,sp,-16
    8000198e:	e422                	sd	s0,8(sp)
    80001990:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001992:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001994:	2501                	sext.w	a0,a0
    80001996:	6422                	ld	s0,8(sp)
    80001998:	0141                	addi	sp,sp,16
    8000199a:	8082                	ret

000000008000199c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
    800019a2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a4:	2781                	sext.w	a5,a5
    800019a6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a8:	00009517          	auipc	a0,0x9
    800019ac:	81850513          	addi	a0,a0,-2024 # 8000a1c0 <cpus>
    800019b0:	953e                	add	a0,a0,a5
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b8:	1101                	addi	sp,sp,-32
    800019ba:	ec06                	sd	ra,24(sp)
    800019bc:	e822                	sd	s0,16(sp)
    800019be:	e426                	sd	s1,8(sp)
    800019c0:	1000                	addi	s0,sp,32
  push_off();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1d6080e7          	jalr	470(ra) # 80000b98 <push_off>
    800019ca:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	079e                	slli	a5,a5,0x7
    800019d0:	00008717          	auipc	a4,0x8
    800019d4:	7c070713          	addi	a4,a4,1984 # 8000a190 <pid_lock>
    800019d8:	97ba                	add	a5,a5,a4
    800019da:	7b84                	ld	s1,48(a5)
  pop_off();
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	25c080e7          	jalr	604(ra) # 80000c38 <pop_off>
  return p;
}
    800019e4:	8526                	mv	a0,s1
    800019e6:	60e2                	ld	ra,24(sp)
    800019e8:	6442                	ld	s0,16(sp)
    800019ea:	64a2                	ld	s1,8(sp)
    800019ec:	6105                	addi	sp,sp,32
    800019ee:	8082                	ret

00000000800019f0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e406                	sd	ra,8(sp)
    800019f4:	e022                	sd	s0,0(sp)
    800019f6:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f8:	00000097          	auipc	ra,0x0
    800019fc:	fc0080e7          	jalr	-64(ra) # 800019b8 <myproc>
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	298080e7          	jalr	664(ra) # 80000c98 <release>

  if (first) {
    80001a08:	00007797          	auipc	a5,0x7
    80001a0c:	e487a783          	lw	a5,-440(a5) # 80008850 <first.1797>
    80001a10:	eb89                	bnez	a5,80001a22 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a12:	00001097          	auipc	ra,0x1
    80001a16:	ebe080e7          	jalr	-322(ra) # 800028d0 <usertrapret>
}
    80001a1a:	60a2                	ld	ra,8(sp)
    80001a1c:	6402                	ld	s0,0(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret
    first = 0;
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	e207a723          	sw	zero,-466(a5) # 80008850 <first.1797>
    fsinit(ROOTDEV);
    80001a2a:	4505                	li	a0,1
    80001a2c:	00002097          	auipc	ra,0x2
    80001a30:	c02080e7          	jalr	-1022(ra) # 8000362e <fsinit>
    80001a34:	bff9                	j	80001a12 <forkret+0x22>

0000000080001a36 <allocpid>:
allocpid() {
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	e04a                	sd	s2,0(sp)
    80001a40:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a42:	00008917          	auipc	s2,0x8
    80001a46:	74e90913          	addi	s2,s2,1870 # 8000a190 <pid_lock>
    80001a4a:	854a                	mv	a0,s2
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	198080e7          	jalr	408(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a54:	00007797          	auipc	a5,0x7
    80001a58:	e0478793          	addi	a5,a5,-508 # 80008858 <nextpid>
    80001a5c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5e:	0014871b          	addiw	a4,s1,1
    80001a62:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a64:	854a                	mv	a0,s2
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6902                	ld	s2,0(sp)
    80001a78:	6105                	addi	sp,sp,32
    80001a7a:	8082                	ret

0000000080001a7c <proc_pagetable>:
{
    80001a7c:	1101                	addi	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	e04a                	sd	s2,0(sp)
    80001a86:	1000                	addi	s0,sp,32
    80001a88:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	8b8080e7          	jalr	-1864(ra) # 80001342 <uvmcreate>
    80001a92:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a94:	c121                	beqz	a0,80001ad4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a96:	4729                	li	a4,10
    80001a98:	00005697          	auipc	a3,0x5
    80001a9c:	56868693          	addi	a3,a3,1384 # 80007000 <_trampoline>
    80001aa0:	6605                	lui	a2,0x1
    80001aa2:	040005b7          	lui	a1,0x4000
    80001aa6:	15fd                	addi	a1,a1,-1
    80001aa8:	05b2                	slli	a1,a1,0xc
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	60e080e7          	jalr	1550(ra) # 800010b8 <mappages>
    80001ab2:	02054863          	bltz	a0,80001ae2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab6:	4719                	li	a4,6
    80001ab8:	05893683          	ld	a3,88(s2)
    80001abc:	6605                	lui	a2,0x1
    80001abe:	020005b7          	lui	a1,0x2000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b6                	slli	a1,a1,0xd
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	5f0080e7          	jalr	1520(ra) # 800010b8 <mappages>
    80001ad0:	02054163          	bltz	a0,80001af2 <proc_pagetable+0x76>
}
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	60e2                	ld	ra,24(sp)
    80001ad8:	6442                	ld	s0,16(sp)
    80001ada:	64a2                	ld	s1,8(sp)
    80001adc:	6902                	ld	s2,0(sp)
    80001ade:	6105                	addi	sp,sp,32
    80001ae0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae2:	4581                	li	a1,0
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	a58080e7          	jalr	-1448(ra) # 8000153e <uvmfree>
    return 0;
    80001aee:	4481                	li	s1,0
    80001af0:	b7d5                	j	80001ad4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af2:	4681                	li	a3,0
    80001af4:	4605                	li	a2,1
    80001af6:	040005b7          	lui	a1,0x4000
    80001afa:	15fd                	addi	a1,a1,-1
    80001afc:	05b2                	slli	a1,a1,0xc
    80001afe:	8526                	mv	a0,s1
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	77e080e7          	jalr	1918(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a32080e7          	jalr	-1486(ra) # 8000153e <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	bf7d                	j	80001ad4 <proc_pagetable+0x58>

0000000080001b18 <proc_freepagetable>:
{
    80001b18:	1101                	addi	sp,sp,-32
    80001b1a:	ec06                	sd	ra,24(sp)
    80001b1c:	e822                	sd	s0,16(sp)
    80001b1e:	e426                	sd	s1,8(sp)
    80001b20:	e04a                	sd	s2,0(sp)
    80001b22:	1000                	addi	s0,sp,32
    80001b24:	84aa                	mv	s1,a0
    80001b26:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	74a080e7          	jalr	1866(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	020005b7          	lui	a1,0x2000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b6                	slli	a1,a1,0xd
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b52:	85ca                	mv	a1,s2
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	9e8080e7          	jalr	-1560(ra) # 8000153e <uvmfree>
}
    80001b5e:	60e2                	ld	ra,24(sp)
    80001b60:	6442                	ld	s0,16(sp)
    80001b62:	64a2                	ld	s1,8(sp)
    80001b64:	6902                	ld	s2,0(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret

0000000080001b6a <freeproc>:
{
    80001b6a:	1101                	addi	sp,sp,-32
    80001b6c:	ec06                	sd	ra,24(sp)
    80001b6e:	e822                	sd	s0,16(sp)
    80001b70:	e426                	sd	s1,8(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b76:	6d28                	ld	a0,88(a0)
    80001b78:	c509                	beqz	a0,80001b82 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	e7e080e7          	jalr	-386(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b82:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b86:	68a8                	ld	a0,80(s1)
    80001b88:	c511                	beqz	a0,80001b94 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b8a:	64ac                	ld	a1,72(s1)
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	f8c080e7          	jalr	-116(ra) # 80001b18 <proc_freepagetable>
  p->pagetable = 0;
    80001b94:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b98:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b9c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bac:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb4:	0004ac23          	sw	zero,24(s1)
}
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <allocproc>:
{
    80001bc2:	1101                	addi	sp,sp,-32
    80001bc4:	ec06                	sd	ra,24(sp)
    80001bc6:	e822                	sd	s0,16(sp)
    80001bc8:	e426                	sd	s1,8(sp)
    80001bca:	e04a                	sd	s2,0(sp)
    80001bcc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bce:	00008497          	auipc	s1,0x8
    80001bd2:	67248493          	addi	s1,s1,1650 # 8000a240 <proc>
    80001bd6:	0000e917          	auipc	s2,0xe
    80001bda:	66a90913          	addi	s2,s2,1642 # 80010240 <tickslock>
    acquire(&p->lock);
    80001bde:	8526                	mv	a0,s1
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be8:	4c9c                	lw	a5,24(s1)
    80001bea:	cf81                	beqz	a5,80001c02 <allocproc+0x40>
      release(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf6:	18048493          	addi	s1,s1,384
    80001bfa:	ff2492e3          	bne	s1,s2,80001bde <allocproc+0x1c>
  return 0;
    80001bfe:	4481                	li	s1,0
    80001c00:	a8b9                	j	80001c5e <allocproc+0x9c>
  p->pid = allocpid();
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	e34080e7          	jalr	-460(ra) # 80001a36 <allocpid>
    80001c0a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c0c:	4785                	li	a5,1
    80001c0e:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c10:	1604b423          	sd	zero,360(s1)
  p->last_ticks = 0;
    80001c14:	1604b823          	sd	zero,368(s1)
  p->start_cpu_burst = 0;
    80001c18:	1604bc23          	sd	zero,376(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	ed8080e7          	jalr	-296(ra) # 80000af4 <kalloc>
    80001c24:	892a                	mv	s2,a0
    80001c26:	eca8                	sd	a0,88(s1)
    80001c28:	c131                	beqz	a0,80001c6c <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e50080e7          	jalr	-432(ra) # 80001a7c <proc_pagetable>
    80001c34:	892a                	mv	s2,a0
    80001c36:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c38:	c531                	beqz	a0,80001c84 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c3a:	07000613          	li	a2,112
    80001c3e:	4581                	li	a1,0
    80001c40:	06048513          	addi	a0,s1,96
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	09c080e7          	jalr	156(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c4c:	00000797          	auipc	a5,0x0
    80001c50:	da478793          	addi	a5,a5,-604 # 800019f0 <forkret>
    80001c54:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c56:	60bc                	ld	a5,64(s1)
    80001c58:	6705                	lui	a4,0x1
    80001c5a:	97ba                	add	a5,a5,a4
    80001c5c:	f4bc                	sd	a5,104(s1)
}
    80001c5e:	8526                	mv	a0,s1
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	efc080e7          	jalr	-260(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	bff1                	j	80001c5e <allocproc+0x9c>
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ee4080e7          	jalr	-284(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	b7d1                	j	80001c5e <allocproc+0x9c>

0000000080001c9c <userinit>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	f1c080e7          	jalr	-228(ra) # 80001bc2 <allocproc>
    80001cae:	84aa                	mv	s1,a0
  initproc = p;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	38a7b023          	sd	a0,896(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb8:	03400613          	li	a2,52
    80001cbc:	00007597          	auipc	a1,0x7
    80001cc0:	ba458593          	addi	a1,a1,-1116 # 80008860 <initcode>
    80001cc4:	6928                	ld	a0,80(a0)
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	6aa080e7          	jalr	1706(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cce:	6785                	lui	a5,0x1
    80001cd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd8:	6cb8                	ld	a4,88(s1)
    80001cda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cdc:	4641                	li	a2,16
    80001cde:	00006597          	auipc	a1,0x6
    80001ce2:	52258593          	addi	a1,a1,1314 # 80008200 <digits+0x1c0>
    80001ce6:	15848513          	addi	a0,s1,344
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	148080e7          	jalr	328(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	51e50513          	addi	a0,a0,1310 # 80008210 <digits+0x1d0>
    80001cfa:	00002097          	auipc	ra,0x2
    80001cfe:	362080e7          	jalr	866(ra) # 8000405c <namei>
    80001d02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d06:	478d                	li	a5,3
    80001d08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c8c080e7          	jalr	-884(ra) # 800019b8 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  } else if(n < 0){
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6c4080e7          	jalr	1732(ra) # 8000142a <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	65e080e7          	jalr	1630(ra) # 800013e2 <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7179                	addi	sp,sp,-48
    80001d94:	f406                	sd	ra,40(sp)
    80001d96:	f022                	sd	s0,32(sp)
    80001d98:	ec26                	sd	s1,24(sp)
    80001d9a:	e84a                	sd	s2,16(sp)
    80001d9c:	e44e                	sd	s3,8(sp)
    80001d9e:	e052                	sd	s4,0(sp)
    80001da0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	c16080e7          	jalr	-1002(ra) # 800019b8 <myproc>
    80001daa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e16080e7          	jalr	-490(ra) # 80001bc2 <allocproc>
    80001db4:	10050b63          	beqz	a0,80001eca <fork+0x138>
    80001db8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dba:	04893603          	ld	a2,72(s2)
    80001dbe:	692c                	ld	a1,80(a0)
    80001dc0:	05093503          	ld	a0,80(s2)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	7b2080e7          	jalr	1970(ra) # 80001576 <uvmcopy>
    80001dcc:	04054663          	bltz	a0,80001e18 <fork+0x86>
  np->sz = p->sz;
    80001dd0:	04893783          	ld	a5,72(s2)
    80001dd4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd8:	05893683          	ld	a3,88(s2)
    80001ddc:	87b6                	mv	a5,a3
    80001dde:	0589b703          	ld	a4,88(s3)
    80001de2:	12068693          	addi	a3,a3,288
    80001de6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dea:	6788                	ld	a0,8(a5)
    80001dec:	6b8c                	ld	a1,16(a5)
    80001dee:	6f90                	ld	a2,24(a5)
    80001df0:	01073023          	sd	a6,0(a4)
    80001df4:	e708                	sd	a0,8(a4)
    80001df6:	eb0c                	sd	a1,16(a4)
    80001df8:	ef10                	sd	a2,24(a4)
    80001dfa:	02078793          	addi	a5,a5,32
    80001dfe:	02070713          	addi	a4,a4,32
    80001e02:	fed792e3          	bne	a5,a3,80001de6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e06:	0589b783          	ld	a5,88(s3)
    80001e0a:	0607b823          	sd	zero,112(a5)
    80001e0e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e12:	15000a13          	li	s4,336
    80001e16:	a03d                	j	80001e44 <fork+0xb2>
    freeproc(np);
    80001e18:	854e                	mv	a0,s3
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	d50080e7          	jalr	-688(ra) # 80001b6a <freeproc>
    release(&np->lock);
    80001e22:	854e                	mv	a0,s3
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
    return -1;
    80001e2c:	5a7d                	li	s4,-1
    80001e2e:	a069                	j	80001eb8 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e30:	00003097          	auipc	ra,0x3
    80001e34:	8c2080e7          	jalr	-1854(ra) # 800046f2 <filedup>
    80001e38:	009987b3          	add	a5,s3,s1
    80001e3c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3e:	04a1                	addi	s1,s1,8
    80001e40:	01448763          	beq	s1,s4,80001e4e <fork+0xbc>
    if(p->ofile[i])
    80001e44:	009907b3          	add	a5,s2,s1
    80001e48:	6388                	ld	a0,0(a5)
    80001e4a:	f17d                	bnez	a0,80001e30 <fork+0x9e>
    80001e4c:	bfcd                	j	80001e3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4e:	15093503          	ld	a0,336(s2)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	a16080e7          	jalr	-1514(ra) # 80003868 <idup>
    80001e5a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5e:	4641                	li	a2,16
    80001e60:	15890593          	addi	a1,s2,344
    80001e64:	15898513          	addi	a0,s3,344
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	fca080e7          	jalr	-54(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e70:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e7e:	00008497          	auipc	s1,0x8
    80001e82:	32a48493          	addi	s1,s1,810 # 8000a1a8 <wait_lock>
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	d5c080e7          	jalr	-676(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e90:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e9e:	854e                	mv	a0,s3
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d44080e7          	jalr	-700(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	de8080e7          	jalr	-536(ra) # 80000c98 <release>
}
    80001eb8:	8552                	mv	a0,s4
    80001eba:	70a2                	ld	ra,40(sp)
    80001ebc:	7402                	ld	s0,32(sp)
    80001ebe:	64e2                	ld	s1,24(sp)
    80001ec0:	6942                	ld	s2,16(sp)
    80001ec2:	69a2                	ld	s3,8(sp)
    80001ec4:	6a02                	ld	s4,0(sp)
    80001ec6:	6145                	addi	sp,sp,48
    80001ec8:	8082                	ret
    return -1;
    80001eca:	5a7d                	li	s4,-1
    80001ecc:	b7f5                	j	80001eb8 <fork+0x126>

0000000080001ece <round_robin>:
round_robin(){
    80001ece:	711d                	addi	sp,sp,-96
    80001ed0:	ec86                	sd	ra,88(sp)
    80001ed2:	e8a2                	sd	s0,80(sp)
    80001ed4:	e4a6                	sd	s1,72(sp)
    80001ed6:	e0ca                	sd	s2,64(sp)
    80001ed8:	fc4e                	sd	s3,56(sp)
    80001eda:	f852                	sd	s4,48(sp)
    80001edc:	f456                	sd	s5,40(sp)
    80001ede:	f05a                	sd	s6,32(sp)
    80001ee0:	ec5e                	sd	s7,24(sp)
    80001ee2:	e862                	sd	s8,16(sp)
    80001ee4:	e466                	sd	s9,8(sp)
    80001ee6:	1080                	addi	s0,sp,96
    printf("Round Robin Policy \n");
    80001ee8:	00006517          	auipc	a0,0x6
    80001eec:	33050513          	addi	a0,a0,816 # 80008218 <digits+0x1d8>
    80001ef0:	ffffe097          	auipc	ra,0xffffe
    80001ef4:	698080e7          	jalr	1688(ra) # 80000588 <printf>
    80001ef8:	8792                	mv	a5,tp
  int id = r_tp();
    80001efa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efc:	00779c13          	slli	s8,a5,0x7
    80001f00:	00008717          	auipc	a4,0x8
    80001f04:	29070713          	addi	a4,a4,656 # 8000a190 <pid_lock>
    80001f08:	9762                	add	a4,a4,s8
    80001f0a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f0e:	00008717          	auipc	a4,0x8
    80001f12:	2ba70713          	addi	a4,a4,698 # 8000a1c8 <cpus+0x8>
    80001f16:	9c3a                	add	s8,s8,a4
          c->proc = p;
    80001f18:	079e                	slli	a5,a5,0x7
    80001f1a:	00008a97          	auipc	s5,0x8
    80001f1e:	276a8a93          	addi	s5,s5,630 # 8000a190 <pid_lock>
    80001f22:	9abe                	add	s5,s5,a5
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f24:	00007b17          	auipc	s6,0x7
    80001f28:	104b0b13          	addi	s6,s6,260 # 80009028 <pause_time>
            if(ticks >= pause_time){
    80001f2c:	00007c97          	auipc	s9,0x7
    80001f30:	10cc8c93          	addi	s9,s9,268 # 80009038 <ticks>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f3c:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	00008497          	auipc	s1,0x8
    80001f44:	30048493          	addi	s1,s1,768 # 8000a240 <proc>
        if(p->state == RUNNABLE) {
    80001f48:	4a0d                	li	s4,3
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f4a:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4c:	0000e997          	auipc	s3,0xe
    80001f50:	2f498993          	addi	s3,s3,756 # 80010240 <tickslock>
    80001f54:	a80d                	j	80001f86 <round_robin+0xb8>
              pause_time = 0;
    80001f56:	000b2023          	sw	zero,0(s6)
          p->state = RUNNING;
    80001f5a:	4791                	li	a5,4
    80001f5c:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001f5e:	029ab823          	sd	s1,48(s5)
          swtch(&c->context, &p->context);
    80001f62:	06090593          	addi	a1,s2,96
    80001f66:	8562                	mv	a0,s8
    80001f68:	00001097          	auipc	ra,0x1
    80001f6c:	8be080e7          	jalr	-1858(ra) # 80002826 <swtch>
          c->proc = 0;
    80001f70:	020ab823          	sd	zero,48(s5)
        release(&p->lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7e:	18048493          	addi	s1,s1,384
    80001f82:	fb3489e3          	beq	s1,s3,80001f34 <round_robin+0x66>
        acquire(&p->lock);
    80001f86:	8926                	mv	s2,s1
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	c5a080e7          	jalr	-934(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f92:	4c9c                	lw	a5,24(s1)
    80001f94:	ff4790e3          	bne	a5,s4,80001f74 <round_robin+0xa6>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f98:	589c                	lw	a5,48(s1)
    80001f9a:	37fd                	addiw	a5,a5,-1
    80001f9c:	fafbffe3          	bgeu	s7,a5,80001f5a <round_robin+0x8c>
    80001fa0:	000b2783          	lw	a5,0(s6)
    80001fa4:	dbdd                	beqz	a5,80001f5a <round_robin+0x8c>
            if(ticks >= pause_time){
    80001fa6:	000ca703          	lw	a4,0(s9)
    80001faa:	faf776e3          	bgeu	a4,a5,80001f56 <round_robin+0x88>
              release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	ce8080e7          	jalr	-792(ra) # 80000c98 <release>
              continue;
    80001fb8:	b7d9                	j	80001f7e <round_robin+0xb0>

0000000080001fba <sjf>:
sjf(void){
    80001fba:	711d                	addi	sp,sp,-96
    80001fbc:	ec86                	sd	ra,88(sp)
    80001fbe:	e8a2                	sd	s0,80(sp)
    80001fc0:	e4a6                	sd	s1,72(sp)
    80001fc2:	e0ca                	sd	s2,64(sp)
    80001fc4:	fc4e                	sd	s3,56(sp)
    80001fc6:	f852                	sd	s4,48(sp)
    80001fc8:	f456                	sd	s5,40(sp)
    80001fca:	f05a                	sd	s6,32(sp)
    80001fcc:	ec5e                	sd	s7,24(sp)
    80001fce:	e862                	sd	s8,16(sp)
    80001fd0:	e466                	sd	s9,8(sp)
    80001fd2:	e06a                	sd	s10,0(sp)
    80001fd4:	1080                	addi	s0,sp,96
  printf("SJF Policy \n");
    80001fd6:	00006517          	auipc	a0,0x6
    80001fda:	25a50513          	addi	a0,a0,602 # 80008230 <digits+0x1f0>
    80001fde:	ffffe097          	auipc	ra,0xffffe
    80001fe2:	5aa080e7          	jalr	1450(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fea:	00779693          	slli	a3,a5,0x7
    80001fee:	00008717          	auipc	a4,0x8
    80001ff2:	1a270713          	addi	a4,a4,418 # 8000a190 <pid_lock>
    80001ff6:	9736                	add	a4,a4,a3
    80001ff8:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &min_proc->context);
    80001ffc:	00008717          	auipc	a4,0x8
    80002000:	1cc70713          	addi	a4,a4,460 # 8000a1c8 <cpus+0x8>
    80002004:	00e68d33          	add	s10,a3,a4
    int min = -1;
    80002008:	5b7d                	li	s6,-1
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    8000200a:	00007a97          	auipc	s5,0x7
    8000200e:	01ea8a93          	addi	s5,s5,30 # 80009028 <pause_time>
          if(ticks >= pause_time){
    80002012:	00007c17          	auipc	s8,0x7
    80002016:	026c0c13          	addi	s8,s8,38 # 80009038 <ticks>
          c->proc = min_proc;
    8000201a:	00008c97          	auipc	s9,0x8
    8000201e:	176c8c93          	addi	s9,s9,374 # 8000a190 <pid_lock>
    80002022:	9cb6                	add	s9,s9,a3
    80002024:	a8b1                	j	80002080 <sjf+0xc6>
           release(&p->lock);
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	c70080e7          	jalr	-912(ra) # 80000c98 <release>
           continue;
    80002030:	a839                	j	8000204e <sjf+0x94>
      else if(min == -1 || p->mean_ticks < min){
    80002032:	01690663          	beq	s2,s6,8000203e <sjf+0x84>
    80002036:	1684b783          	ld	a5,360(s1)
    8000203a:	0127f563          	bgeu	a5,s2,80002044 <sjf+0x8a>
              min = p->mean_ticks;
    8000203e:	1684a903          	lw	s2,360(s1)
    80002042:	8ba6                	mv	s7,s1
        release(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c52080e7          	jalr	-942(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    8000204e:	18048493          	addi	s1,s1,384
    80002052:	03348563          	beq	s1,s3,8000207c <sjf+0xc2>
      acquire(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b8c080e7          	jalr	-1140(ra) # 80000be4 <acquire>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002060:	589c                	lw	a5,48(s1)
    80002062:	37fd                	addiw	a5,a5,-1
    80002064:	fcfa77e3          	bgeu	s4,a5,80002032 <sjf+0x78>
    80002068:	000aa783          	lw	a5,0(s5)
    8000206c:	d3f9                	beqz	a5,80002032 <sjf+0x78>
          if(ticks >= pause_time){
    8000206e:	000c2703          	lw	a4,0(s8)
    80002072:	faf76ae3          	bltu	a4,a5,80002026 <sjf+0x6c>
            pause_time = 0;
    80002076:	000aa023          	sw	zero,0(s5)
          if(ticks >= pause_time){
    8000207a:	b7e9                	j	80002044 <sjf+0x8a>
    if(min == -1){
    8000207c:	03691363          	bne	s2,s6,800020a2 <sjf+0xe8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002080:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002084:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002088:	10079073          	csrw	sstatus,a5
    int min = -1;
    8000208c:	895a                	mv	s2,s6
    for(p = proc; p < &proc[NPROC]; p++) { 
    8000208e:	00008497          	auipc	s1,0x8
    80002092:	1b248493          	addi	s1,s1,434 # 8000a240 <proc>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002096:	4a05                	li	s4,1
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002098:	0000e997          	auipc	s3,0xe
    8000209c:	1a898993          	addi	s3,s3,424 # 80010240 <tickslock>
    800020a0:	bf5d                	j	80002056 <sjf+0x9c>
      acquire(&min_proc->lock);
    800020a2:	84de                	mv	s1,s7
    800020a4:	855e                	mv	a0,s7
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	b3e080e7          	jalr	-1218(ra) # 80000be4 <acquire>
        if(min_proc->state == RUNNABLE) {
    800020ae:	018ba703          	lw	a4,24(s7) # fffffffffffff018 <end+0xffffffff7ffe0018>
    800020b2:	478d                	li	a5,3
    800020b4:	00f70863          	beq	a4,a5,800020c4 <sjf+0x10a>
        release(&min_proc->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bde080e7          	jalr	-1058(ra) # 80000c98 <release>
    800020c2:	bf7d                	j	80002080 <sjf+0xc6>
          min_proc->state = RUNNING;
    800020c4:	4791                	li	a5,4
    800020c6:	00fbac23          	sw	a5,24(s7)
          c->proc = min_proc;
    800020ca:	037cb823          	sd	s7,48(s9)
          min_proc->start_cpu_burst = ticks;
    800020ce:	000c6783          	lwu	a5,0(s8)
    800020d2:	16fbbc23          	sd	a5,376(s7)
          swtch(&c->context, &min_proc->context);
    800020d6:	060b8593          	addi	a1,s7,96
    800020da:	856a                	mv	a0,s10
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	74a080e7          	jalr	1866(ra) # 80002826 <swtch>
          min_proc->last_ticks = ticks - min_proc->start_cpu_burst;
    800020e4:	000c6703          	lwu	a4,0(s8)
    800020e8:	178bb683          	ld	a3,376(s7)
    800020ec:	40d706b3          	sub	a3,a4,a3
    800020f0:	16dbb823          	sd	a3,368(s7)
          min_proc->mean_ticks = ((10*rate)* min_proc->mean_ticks + min_proc->last_ticks*(rate)) / 10;
    800020f4:	00006717          	auipc	a4,0x6
    800020f8:	76072703          	lw	a4,1888(a4) # 80008854 <rate>
    800020fc:	0027179b          	slliw	a5,a4,0x2
    80002100:	9fb9                	addw	a5,a5,a4
    80002102:	0017979b          	slliw	a5,a5,0x1
    80002106:	168bb603          	ld	a2,360(s7)
    8000210a:	02c787b3          	mul	a5,a5,a2
    8000210e:	02d70733          	mul	a4,a4,a3
    80002112:	97ba                	add	a5,a5,a4
    80002114:	4729                	li	a4,10
    80002116:	02e7d7b3          	divu	a5,a5,a4
    8000211a:	16fbb423          	sd	a5,360(s7)
          c->proc = 0;
    8000211e:	020cb823          	sd	zero,48(s9)
    80002122:	bf59                	j	800020b8 <sjf+0xfe>

0000000080002124 <scheduler>:
{
    80002124:	1141                	addi	sp,sp,-16
    80002126:	e406                	sd	ra,8(sp)
    80002128:	e022                	sd	s0,0(sp)
    8000212a:	0800                	addi	s0,sp,16
    sjf();
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	e8e080e7          	jalr	-370(ra) # 80001fba <sjf>

0000000080002134 <sched>:
{
    80002134:	7179                	addi	sp,sp,-48
    80002136:	f406                	sd	ra,40(sp)
    80002138:	f022                	sd	s0,32(sp)
    8000213a:	ec26                	sd	s1,24(sp)
    8000213c:	e84a                	sd	s2,16(sp)
    8000213e:	e44e                	sd	s3,8(sp)
    80002140:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002142:	00000097          	auipc	ra,0x0
    80002146:	876080e7          	jalr	-1930(ra) # 800019b8 <myproc>
    8000214a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a1e080e7          	jalr	-1506(ra) # 80000b6a <holding>
    80002154:	c93d                	beqz	a0,800021ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002156:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002158:	2781                	sext.w	a5,a5
    8000215a:	079e                	slli	a5,a5,0x7
    8000215c:	00008717          	auipc	a4,0x8
    80002160:	03470713          	addi	a4,a4,52 # 8000a190 <pid_lock>
    80002164:	97ba                	add	a5,a5,a4
    80002166:	0a87a703          	lw	a4,168(a5)
    8000216a:	4785                	li	a5,1
    8000216c:	06f71763          	bne	a4,a5,800021da <sched+0xa6>
  if(p->state == RUNNING)
    80002170:	4c98                	lw	a4,24(s1)
    80002172:	4791                	li	a5,4
    80002174:	06f70b63          	beq	a4,a5,800021ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002178:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000217c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000217e:	efb5                	bnez	a5,800021fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002180:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002182:	00008917          	auipc	s2,0x8
    80002186:	00e90913          	addi	s2,s2,14 # 8000a190 <pid_lock>
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	97ca                	add	a5,a5,s2
    80002190:	0ac7a983          	lw	s3,172(a5)
    80002194:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	00008597          	auipc	a1,0x8
    8000219e:	02e58593          	addi	a1,a1,46 # 8000a1c8 <cpus+0x8>
    800021a2:	95be                	add	a1,a1,a5
    800021a4:	06048513          	addi	a0,s1,96
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	67e080e7          	jalr	1662(ra) # 80002826 <swtch>
    800021b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021b2:	2781                	sext.w	a5,a5
    800021b4:	079e                	slli	a5,a5,0x7
    800021b6:	97ca                	add	a5,a5,s2
    800021b8:	0b37a623          	sw	s3,172(a5)
}
    800021bc:	70a2                	ld	ra,40(sp)
    800021be:	7402                	ld	s0,32(sp)
    800021c0:	64e2                	ld	s1,24(sp)
    800021c2:	6942                	ld	s2,16(sp)
    800021c4:	69a2                	ld	s3,8(sp)
    800021c6:	6145                	addi	sp,sp,48
    800021c8:	8082                	ret
    panic("sched p->lock");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	07650513          	addi	a0,a0,118 # 80008240 <digits+0x200>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	36c080e7          	jalr	876(ra) # 8000053e <panic>
    panic("sched locks");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	07650513          	addi	a0,a0,118 # 80008250 <digits+0x210>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	35c080e7          	jalr	860(ra) # 8000053e <panic>
    panic("sched running");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	07650513          	addi	a0,a0,118 # 80008260 <digits+0x220>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	07650513          	addi	a0,a0,118 # 80008270 <digits+0x230>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	33c080e7          	jalr	828(ra) # 8000053e <panic>

000000008000220a <yield>:
{
    8000220a:	1101                	addi	sp,sp,-32
    8000220c:	ec06                	sd	ra,24(sp)
    8000220e:	e822                	sd	s0,16(sp)
    80002210:	e426                	sd	s1,8(sp)
    80002212:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	7a4080e7          	jalr	1956(ra) # 800019b8 <myproc>
    8000221c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002226:	478d                	li	a5,3
    80002228:	cc9c                	sw	a5,24(s1)
  sched();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f0a080e7          	jalr	-246(ra) # 80002134 <sched>
  release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
}
    8000223c:	60e2                	ld	ra,24(sp)
    8000223e:	6442                	ld	s0,16(sp)
    80002240:	64a2                	ld	s1,8(sp)
    80002242:	6105                	addi	sp,sp,32
    80002244:	8082                	ret

0000000080002246 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	1800                	addi	s0,sp,48
    80002254:	89aa                	mv	s3,a0
    80002256:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	760080e7          	jalr	1888(ra) # 800019b8 <myproc>
    80002260:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	982080e7          	jalr	-1662(ra) # 80000be4 <acquire>
  release(lk);
    8000226a:	854a                	mv	a0,s2
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002274:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002278:	4789                	li	a5,2
    8000227a:	cc9c                	sw	a5,24(s1)

  sched();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	eb8080e7          	jalr	-328(ra) # 80002134 <sched>

  // Tidy up.
  p->chan = 0;
    80002284:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a0e080e7          	jalr	-1522(ra) # 80000c98 <release>
  acquire(lk);
    80002292:	854a                	mv	a0,s2
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
}
    8000229c:	70a2                	ld	ra,40(sp)
    8000229e:	7402                	ld	s0,32(sp)
    800022a0:	64e2                	ld	s1,24(sp)
    800022a2:	6942                	ld	s2,16(sp)
    800022a4:	69a2                	ld	s3,8(sp)
    800022a6:	6145                	addi	sp,sp,48
    800022a8:	8082                	ret

00000000800022aa <wait>:
{
    800022aa:	715d                	addi	sp,sp,-80
    800022ac:	e486                	sd	ra,72(sp)
    800022ae:	e0a2                	sd	s0,64(sp)
    800022b0:	fc26                	sd	s1,56(sp)
    800022b2:	f84a                	sd	s2,48(sp)
    800022b4:	f44e                	sd	s3,40(sp)
    800022b6:	f052                	sd	s4,32(sp)
    800022b8:	ec56                	sd	s5,24(sp)
    800022ba:	e85a                	sd	s6,16(sp)
    800022bc:	e45e                	sd	s7,8(sp)
    800022be:	e062                	sd	s8,0(sp)
    800022c0:	0880                	addi	s0,sp,80
    800022c2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	6f4080e7          	jalr	1780(ra) # 800019b8 <myproc>
    800022cc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022ce:	00008517          	auipc	a0,0x8
    800022d2:	eda50513          	addi	a0,a0,-294 # 8000a1a8 <wait_lock>
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	90e080e7          	jalr	-1778(ra) # 80000be4 <acquire>
    havekids = 0;
    800022de:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022e0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022e2:	0000e997          	auipc	s3,0xe
    800022e6:	f5e98993          	addi	s3,s3,-162 # 80010240 <tickslock>
        havekids = 1;
    800022ea:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022ec:	00008c17          	auipc	s8,0x8
    800022f0:	ebcc0c13          	addi	s8,s8,-324 # 8000a1a8 <wait_lock>
    havekids = 0;
    800022f4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022f6:	00008497          	auipc	s1,0x8
    800022fa:	f4a48493          	addi	s1,s1,-182 # 8000a240 <proc>
    800022fe:	a0bd                	j	8000236c <wait+0xc2>
          pid = np->pid;
    80002300:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002304:	000b0e63          	beqz	s6,80002320 <wait+0x76>
    80002308:	4691                	li	a3,4
    8000230a:	02c48613          	addi	a2,s1,44
    8000230e:	85da                	mv	a1,s6
    80002310:	05093503          	ld	a0,80(s2)
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	366080e7          	jalr	870(ra) # 8000167a <copyout>
    8000231c:	02054563          	bltz	a0,80002346 <wait+0x9c>
          freeproc(np);
    80002320:	8526                	mv	a0,s1
    80002322:	00000097          	auipc	ra,0x0
    80002326:	848080e7          	jalr	-1976(ra) # 80001b6a <freeproc>
          release(&np->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	96c080e7          	jalr	-1684(ra) # 80000c98 <release>
          release(&wait_lock);
    80002334:	00008517          	auipc	a0,0x8
    80002338:	e7450513          	addi	a0,a0,-396 # 8000a1a8 <wait_lock>
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	95c080e7          	jalr	-1700(ra) # 80000c98 <release>
          return pid;
    80002344:	a09d                	j	800023aa <wait+0x100>
            release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	950080e7          	jalr	-1712(ra) # 80000c98 <release>
            release(&wait_lock);
    80002350:	00008517          	auipc	a0,0x8
    80002354:	e5850513          	addi	a0,a0,-424 # 8000a1a8 <wait_lock>
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	940080e7          	jalr	-1728(ra) # 80000c98 <release>
            return -1;
    80002360:	59fd                	li	s3,-1
    80002362:	a0a1                	j	800023aa <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002364:	18048493          	addi	s1,s1,384
    80002368:	03348463          	beq	s1,s3,80002390 <wait+0xe6>
      if(np->parent == p){
    8000236c:	7c9c                	ld	a5,56(s1)
    8000236e:	ff279be3          	bne	a5,s2,80002364 <wait+0xba>
        acquire(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	870080e7          	jalr	-1936(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000237c:	4c9c                	lw	a5,24(s1)
    8000237e:	f94781e3          	beq	a5,s4,80002300 <wait+0x56>
        release(&np->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	914080e7          	jalr	-1772(ra) # 80000c98 <release>
        havekids = 1;
    8000238c:	8756                	mv	a4,s5
    8000238e:	bfd9                	j	80002364 <wait+0xba>
    if(!havekids || p->killed){
    80002390:	c701                	beqz	a4,80002398 <wait+0xee>
    80002392:	02892783          	lw	a5,40(s2)
    80002396:	c79d                	beqz	a5,800023c4 <wait+0x11a>
      release(&wait_lock);
    80002398:	00008517          	auipc	a0,0x8
    8000239c:	e1050513          	addi	a0,a0,-496 # 8000a1a8 <wait_lock>
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8f8080e7          	jalr	-1800(ra) # 80000c98 <release>
      return -1;
    800023a8:	59fd                	li	s3,-1
}
    800023aa:	854e                	mv	a0,s3
    800023ac:	60a6                	ld	ra,72(sp)
    800023ae:	6406                	ld	s0,64(sp)
    800023b0:	74e2                	ld	s1,56(sp)
    800023b2:	7942                	ld	s2,48(sp)
    800023b4:	79a2                	ld	s3,40(sp)
    800023b6:	7a02                	ld	s4,32(sp)
    800023b8:	6ae2                	ld	s5,24(sp)
    800023ba:	6b42                	ld	s6,16(sp)
    800023bc:	6ba2                	ld	s7,8(sp)
    800023be:	6c02                	ld	s8,0(sp)
    800023c0:	6161                	addi	sp,sp,80
    800023c2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c4:	85e2                	mv	a1,s8
    800023c6:	854a                	mv	a0,s2
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	e7e080e7          	jalr	-386(ra) # 80002246 <sleep>
    havekids = 0;
    800023d0:	b715                	j	800022f4 <wait+0x4a>

00000000800023d2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023d2:	7139                	addi	sp,sp,-64
    800023d4:	fc06                	sd	ra,56(sp)
    800023d6:	f822                	sd	s0,48(sp)
    800023d8:	f426                	sd	s1,40(sp)
    800023da:	f04a                	sd	s2,32(sp)
    800023dc:	ec4e                	sd	s3,24(sp)
    800023de:	e852                	sd	s4,16(sp)
    800023e0:	e456                	sd	s5,8(sp)
    800023e2:	0080                	addi	s0,sp,64
    800023e4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023e6:	00008497          	auipc	s1,0x8
    800023ea:	e5a48493          	addi	s1,s1,-422 # 8000a240 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023ee:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023f0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f2:	0000e917          	auipc	s2,0xe
    800023f6:	e4e90913          	addi	s2,s2,-434 # 80010240 <tickslock>
    800023fa:	a821                	j	80002412 <wakeup+0x40>
        p->state = RUNNABLE;
    800023fc:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240a:	18048493          	addi	s1,s1,384
    8000240e:	03248463          	beq	s1,s2,80002436 <wakeup+0x64>
    if(p != myproc()){
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	5a6080e7          	jalr	1446(ra) # 800019b8 <myproc>
    8000241a:	fea488e3          	beq	s1,a0,8000240a <wakeup+0x38>
      acquire(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002428:	4c9c                	lw	a5,24(s1)
    8000242a:	fd379be3          	bne	a5,s3,80002400 <wakeup+0x2e>
    8000242e:	709c                	ld	a5,32(s1)
    80002430:	fd4798e3          	bne	a5,s4,80002400 <wakeup+0x2e>
    80002434:	b7e1                	j	800023fc <wakeup+0x2a>
    }
  }
}
    80002436:	70e2                	ld	ra,56(sp)
    80002438:	7442                	ld	s0,48(sp)
    8000243a:	74a2                	ld	s1,40(sp)
    8000243c:	7902                	ld	s2,32(sp)
    8000243e:	69e2                	ld	s3,24(sp)
    80002440:	6a42                	ld	s4,16(sp)
    80002442:	6aa2                	ld	s5,8(sp)
    80002444:	6121                	addi	sp,sp,64
    80002446:	8082                	ret

0000000080002448 <reparent>:
{
    80002448:	7179                	addi	sp,sp,-48
    8000244a:	f406                	sd	ra,40(sp)
    8000244c:	f022                	sd	s0,32(sp)
    8000244e:	ec26                	sd	s1,24(sp)
    80002450:	e84a                	sd	s2,16(sp)
    80002452:	e44e                	sd	s3,8(sp)
    80002454:	e052                	sd	s4,0(sp)
    80002456:	1800                	addi	s0,sp,48
    80002458:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000245a:	00008497          	auipc	s1,0x8
    8000245e:	de648493          	addi	s1,s1,-538 # 8000a240 <proc>
      pp->parent = initproc;
    80002462:	00007a17          	auipc	s4,0x7
    80002466:	bcea0a13          	addi	s4,s4,-1074 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246a:	0000e997          	auipc	s3,0xe
    8000246e:	dd698993          	addi	s3,s3,-554 # 80010240 <tickslock>
    80002472:	a029                	j	8000247c <reparent+0x34>
    80002474:	18048493          	addi	s1,s1,384
    80002478:	01348d63          	beq	s1,s3,80002492 <reparent+0x4a>
    if(pp->parent == p){
    8000247c:	7c9c                	ld	a5,56(s1)
    8000247e:	ff279be3          	bne	a5,s2,80002474 <reparent+0x2c>
      pp->parent = initproc;
    80002482:	000a3503          	ld	a0,0(s4)
    80002486:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	f4a080e7          	jalr	-182(ra) # 800023d2 <wakeup>
    80002490:	b7d5                	j	80002474 <reparent+0x2c>
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6a02                	ld	s4,0(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret

00000000800024a2 <exit>:
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	e052                	sd	s4,0(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	504080e7          	jalr	1284(ra) # 800019b8 <myproc>
    800024bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800024be:	00007797          	auipc	a5,0x7
    800024c2:	b727b783          	ld	a5,-1166(a5) # 80009030 <initproc>
    800024c6:	0d050493          	addi	s1,a0,208
    800024ca:	15050913          	addi	s2,a0,336
    800024ce:	02a79363          	bne	a5,a0,800024f4 <exit+0x52>
    panic("init exiting");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	db650513          	addi	a0,a0,-586 # 80008288 <digits+0x248>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	064080e7          	jalr	100(ra) # 8000053e <panic>
      fileclose(f);
    800024e2:	00002097          	auipc	ra,0x2
    800024e6:	262080e7          	jalr	610(ra) # 80004744 <fileclose>
      p->ofile[fd] = 0;
    800024ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024ee:	04a1                	addi	s1,s1,8
    800024f0:	01248563          	beq	s1,s2,800024fa <exit+0x58>
    if(p->ofile[fd]){
    800024f4:	6088                	ld	a0,0(s1)
    800024f6:	f575                	bnez	a0,800024e2 <exit+0x40>
    800024f8:	bfdd                	j	800024ee <exit+0x4c>
  begin_op();
    800024fa:	00002097          	auipc	ra,0x2
    800024fe:	d7e080e7          	jalr	-642(ra) # 80004278 <begin_op>
  iput(p->cwd);
    80002502:	1509b503          	ld	a0,336(s3)
    80002506:	00001097          	auipc	ra,0x1
    8000250a:	55a080e7          	jalr	1370(ra) # 80003a60 <iput>
  end_op();
    8000250e:	00002097          	auipc	ra,0x2
    80002512:	dea080e7          	jalr	-534(ra) # 800042f8 <end_op>
  p->cwd = 0;
    80002516:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000251a:	00008497          	auipc	s1,0x8
    8000251e:	c8e48493          	addi	s1,s1,-882 # 8000a1a8 <wait_lock>
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	6c0080e7          	jalr	1728(ra) # 80000be4 <acquire>
  reparent(p);
    8000252c:	854e                	mv	a0,s3
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	f1a080e7          	jalr	-230(ra) # 80002448 <reparent>
  wakeup(p->parent);
    80002536:	0389b503          	ld	a0,56(s3)
    8000253a:	00000097          	auipc	ra,0x0
    8000253e:	e98080e7          	jalr	-360(ra) # 800023d2 <wakeup>
  acquire(&p->lock);
    80002542:	854e                	mv	a0,s3
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000254c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002550:	4795                	li	a5,5
    80002552:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002556:	8526                	mv	a0,s1
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	740080e7          	jalr	1856(ra) # 80000c98 <release>
  sched();
    80002560:	00000097          	auipc	ra,0x0
    80002564:	bd4080e7          	jalr	-1068(ra) # 80002134 <sched>
  panic("zombie exit");
    80002568:	00006517          	auipc	a0,0x6
    8000256c:	d3050513          	addi	a0,a0,-720 # 80008298 <digits+0x258>
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	fce080e7          	jalr	-50(ra) # 8000053e <panic>

0000000080002578 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002578:	7179                	addi	sp,sp,-48
    8000257a:	f406                	sd	ra,40(sp)
    8000257c:	f022                	sd	s0,32(sp)
    8000257e:	ec26                	sd	s1,24(sp)
    80002580:	e84a                	sd	s2,16(sp)
    80002582:	e44e                	sd	s3,8(sp)
    80002584:	1800                	addi	s0,sp,48
    80002586:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002588:	00008497          	auipc	s1,0x8
    8000258c:	cb848493          	addi	s1,s1,-840 # 8000a240 <proc>
    80002590:	0000e997          	auipc	s3,0xe
    80002594:	cb098993          	addi	s3,s3,-848 # 80010240 <tickslock>
    acquire(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	64a080e7          	jalr	1610(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025a2:	589c                	lw	a5,48(s1)
    800025a4:	01278d63          	beq	a5,s2,800025be <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6ee080e7          	jalr	1774(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b2:	18048493          	addi	s1,s1,384
    800025b6:	ff3491e3          	bne	s1,s3,80002598 <kill+0x20>
  }
  return -1;
    800025ba:	557d                	li	a0,-1
    800025bc:	a829                	j	800025d6 <kill+0x5e>
      p->killed = 1;
    800025be:	4785                	li	a5,1
    800025c0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025c2:	4c98                	lw	a4,24(s1)
    800025c4:	4789                	li	a5,2
    800025c6:	00f70f63          	beq	a4,a5,800025e4 <kill+0x6c>
      release(&p->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	6cc080e7          	jalr	1740(ra) # 80000c98 <release>
      return 0;
    800025d4:	4501                	li	a0,0
}
    800025d6:	70a2                	ld	ra,40(sp)
    800025d8:	7402                	ld	s0,32(sp)
    800025da:	64e2                	ld	s1,24(sp)
    800025dc:	6942                	ld	s2,16(sp)
    800025de:	69a2                	ld	s3,8(sp)
    800025e0:	6145                	addi	sp,sp,48
    800025e2:	8082                	ret
        p->state = RUNNABLE;
    800025e4:	478d                	li	a5,3
    800025e6:	cc9c                	sw	a5,24(s1)
    800025e8:	b7cd                	j	800025ca <kill+0x52>

00000000800025ea <kill_system>:

int
kill_system()
{
    800025ea:	715d                	addi	sp,sp,-80
    800025ec:	e486                	sd	ra,72(sp)
    800025ee:	e0a2                	sd	s0,64(sp)
    800025f0:	fc26                	sd	s1,56(sp)
    800025f2:	f84a                	sd	s2,48(sp)
    800025f4:	f44e                	sd	s3,40(sp)
    800025f6:	f052                	sd	s4,32(sp)
    800025f8:	ec56                	sd	s5,24(sp)
    800025fa:	e85a                	sd	s6,16(sp)
    800025fc:	e45e                	sd	s7,8(sp)
    800025fe:	e062                	sd	s8,0(sp)
    80002600:	0880                	addi	s0,sp,80
  struct proc *myp = myproc();
    80002602:	fffff097          	auipc	ra,0xfffff
    80002606:	3b6080e7          	jalr	950(ra) # 800019b8 <myproc>
    8000260a:	8c2a                	mv	s8,a0
  int mypid = myp->pid;
    8000260c:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5d4080e7          	jalr	1492(ra) # 80000be4 <acquire>
  struct proc *p;

  for(p = proc;p < &proc[NPROC]; p++){
    80002618:	00008497          	auipc	s1,0x8
    8000261c:	c2848493          	addi	s1,s1,-984 # 8000a240 <proc>
    if(p->pid != mypid){
      acquire(&p->lock);
      if(p->pid != 1 && p->pid != 2){
    80002620:	4a05                	li	s4,1
        p->killed = 1;
    80002622:	4b05                	li	s6,1
        if(p->state == SLEEPING){
    80002624:	4a89                	li	s5,2
          // Wake process from sleep().
          p->state = RUNNABLE;
    80002626:	4b8d                	li	s7,3
  for(p = proc;p < &proc[NPROC]; p++){
    80002628:	0000e917          	auipc	s2,0xe
    8000262c:	c1890913          	addi	s2,s2,-1000 # 80010240 <tickslock>
    80002630:	a811                	j	80002644 <kill_system+0x5a>
        }
      }
      release(&p->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	664080e7          	jalr	1636(ra) # 80000c98 <release>
  for(p = proc;p < &proc[NPROC]; p++){
    8000263c:	18048493          	addi	s1,s1,384
    80002640:	03248663          	beq	s1,s2,8000266c <kill_system+0x82>
    if(p->pid != mypid){
    80002644:	589c                	lw	a5,48(s1)
    80002646:	ff378be3          	beq	a5,s3,8000263c <kill_system+0x52>
      acquire(&p->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	598080e7          	jalr	1432(ra) # 80000be4 <acquire>
      if(p->pid != 1 && p->pid != 2){
    80002654:	589c                	lw	a5,48(s1)
    80002656:	37fd                	addiw	a5,a5,-1
    80002658:	fcfa7de3          	bgeu	s4,a5,80002632 <kill_system+0x48>
        p->killed = 1;
    8000265c:	0364a423          	sw	s6,40(s1)
        if(p->state == SLEEPING){
    80002660:	4c9c                	lw	a5,24(s1)
    80002662:	fd5798e3          	bne	a5,s5,80002632 <kill_system+0x48>
          p->state = RUNNABLE;
    80002666:	0174ac23          	sw	s7,24(s1)
    8000266a:	b7e1                	j	80002632 <kill_system+0x48>
    }
  }

  myp->killed = 1;
    8000266c:	4785                	li	a5,1
    8000266e:	02fc2423          	sw	a5,40(s8)
  release(&myp->lock);
    80002672:	8562                	mv	a0,s8
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	624080e7          	jalr	1572(ra) # 80000c98 <release>
  return 0;
}
    8000267c:	4501                	li	a0,0
    8000267e:	60a6                	ld	ra,72(sp)
    80002680:	6406                	ld	s0,64(sp)
    80002682:	74e2                	ld	s1,56(sp)
    80002684:	7942                	ld	s2,48(sp)
    80002686:	79a2                	ld	s3,40(sp)
    80002688:	7a02                	ld	s4,32(sp)
    8000268a:	6ae2                	ld	s5,24(sp)
    8000268c:	6b42                	ld	s6,16(sp)
    8000268e:	6ba2                	ld	s7,8(sp)
    80002690:	6c02                	ld	s8,0(sp)
    80002692:	6161                	addi	sp,sp,80
    80002694:	8082                	ret

0000000080002696 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002696:	7179                	addi	sp,sp,-48
    80002698:	f406                	sd	ra,40(sp)
    8000269a:	f022                	sd	s0,32(sp)
    8000269c:	ec26                	sd	s1,24(sp)
    8000269e:	e84a                	sd	s2,16(sp)
    800026a0:	e44e                	sd	s3,8(sp)
    800026a2:	e052                	sd	s4,0(sp)
    800026a4:	1800                	addi	s0,sp,48
    800026a6:	84aa                	mv	s1,a0
    800026a8:	892e                	mv	s2,a1
    800026aa:	89b2                	mv	s3,a2
    800026ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	30a080e7          	jalr	778(ra) # 800019b8 <myproc>
  if(user_dst){
    800026b6:	c08d                	beqz	s1,800026d8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026b8:	86d2                	mv	a3,s4
    800026ba:	864e                	mv	a2,s3
    800026bc:	85ca                	mv	a1,s2
    800026be:	6928                	ld	a0,80(a0)
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	fba080e7          	jalr	-70(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026c8:	70a2                	ld	ra,40(sp)
    800026ca:	7402                	ld	s0,32(sp)
    800026cc:	64e2                	ld	s1,24(sp)
    800026ce:	6942                	ld	s2,16(sp)
    800026d0:	69a2                	ld	s3,8(sp)
    800026d2:	6a02                	ld	s4,0(sp)
    800026d4:	6145                	addi	sp,sp,48
    800026d6:	8082                	ret
    memmove((char *)dst, src, len);
    800026d8:	000a061b          	sext.w	a2,s4
    800026dc:	85ce                	mv	a1,s3
    800026de:	854a                	mv	a0,s2
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	660080e7          	jalr	1632(ra) # 80000d40 <memmove>
    return 0;
    800026e8:	8526                	mv	a0,s1
    800026ea:	bff9                	j	800026c8 <either_copyout+0x32>

00000000800026ec <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026ec:	7179                	addi	sp,sp,-48
    800026ee:	f406                	sd	ra,40(sp)
    800026f0:	f022                	sd	s0,32(sp)
    800026f2:	ec26                	sd	s1,24(sp)
    800026f4:	e84a                	sd	s2,16(sp)
    800026f6:	e44e                	sd	s3,8(sp)
    800026f8:	e052                	sd	s4,0(sp)
    800026fa:	1800                	addi	s0,sp,48
    800026fc:	892a                	mv	s2,a0
    800026fe:	84ae                	mv	s1,a1
    80002700:	89b2                	mv	s3,a2
    80002702:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	2b4080e7          	jalr	692(ra) # 800019b8 <myproc>
  if(user_src){
    8000270c:	c08d                	beqz	s1,8000272e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000270e:	86d2                	mv	a3,s4
    80002710:	864e                	mv	a2,s3
    80002712:	85ca                	mv	a1,s2
    80002714:	6928                	ld	a0,80(a0)
    80002716:	fffff097          	auipc	ra,0xfffff
    8000271a:	ff0080e7          	jalr	-16(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000271e:	70a2                	ld	ra,40(sp)
    80002720:	7402                	ld	s0,32(sp)
    80002722:	64e2                	ld	s1,24(sp)
    80002724:	6942                	ld	s2,16(sp)
    80002726:	69a2                	ld	s3,8(sp)
    80002728:	6a02                	ld	s4,0(sp)
    8000272a:	6145                	addi	sp,sp,48
    8000272c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000272e:	000a061b          	sext.w	a2,s4
    80002732:	85ce                	mv	a1,s3
    80002734:	854a                	mv	a0,s2
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	60a080e7          	jalr	1546(ra) # 80000d40 <memmove>
    return 0;
    8000273e:	8526                	mv	a0,s1
    80002740:	bff9                	j	8000271e <either_copyin+0x32>

0000000080002742 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002742:	715d                	addi	sp,sp,-80
    80002744:	e486                	sd	ra,72(sp)
    80002746:	e0a2                	sd	s0,64(sp)
    80002748:	fc26                	sd	s1,56(sp)
    8000274a:	f84a                	sd	s2,48(sp)
    8000274c:	f44e                	sd	s3,40(sp)
    8000274e:	f052                	sd	s4,32(sp)
    80002750:	ec56                	sd	s5,24(sp)
    80002752:	e85a                	sd	s6,16(sp)
    80002754:	e45e                	sd	s7,8(sp)
    80002756:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002758:	00006517          	auipc	a0,0x6
    8000275c:	97050513          	addi	a0,a0,-1680 # 800080c8 <digits+0x88>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	e28080e7          	jalr	-472(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002768:	00008497          	auipc	s1,0x8
    8000276c:	c3048493          	addi	s1,s1,-976 # 8000a398 <proc+0x158>
    80002770:	0000e917          	auipc	s2,0xe
    80002774:	c2890913          	addi	s2,s2,-984 # 80010398 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002778:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000277a:	00006997          	auipc	s3,0x6
    8000277e:	b2e98993          	addi	s3,s3,-1234 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002782:	00006a97          	auipc	s5,0x6
    80002786:	b2ea8a93          	addi	s5,s5,-1234 # 800082b0 <digits+0x270>
    printf("\n");
    8000278a:	00006a17          	auipc	s4,0x6
    8000278e:	93ea0a13          	addi	s4,s4,-1730 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002792:	00006b97          	auipc	s7,0x6
    80002796:	b56b8b93          	addi	s7,s7,-1194 # 800082e8 <states.1842>
    8000279a:	a00d                	j	800027bc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000279c:	ed86a583          	lw	a1,-296(a3)
    800027a0:	8556                	mv	a0,s5
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	de6080e7          	jalr	-538(ra) # 80000588 <printf>
    printf("\n");
    800027aa:	8552                	mv	a0,s4
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	ddc080e7          	jalr	-548(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b4:	18048493          	addi	s1,s1,384
    800027b8:	03248163          	beq	s1,s2,800027da <procdump+0x98>
    if(p->state == UNUSED)
    800027bc:	86a6                	mv	a3,s1
    800027be:	ec04a783          	lw	a5,-320(s1)
    800027c2:	dbed                	beqz	a5,800027b4 <procdump+0x72>
      state = "???";
    800027c4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c6:	fcfb6be3          	bltu	s6,a5,8000279c <procdump+0x5a>
    800027ca:	1782                	slli	a5,a5,0x20
    800027cc:	9381                	srli	a5,a5,0x20
    800027ce:	078e                	slli	a5,a5,0x3
    800027d0:	97de                	add	a5,a5,s7
    800027d2:	6390                	ld	a2,0(a5)
    800027d4:	f661                	bnez	a2,8000279c <procdump+0x5a>
      state = "???";
    800027d6:	864e                	mv	a2,s3
    800027d8:	b7d1                	j	8000279c <procdump+0x5a>
  }
}
    800027da:	60a6                	ld	ra,72(sp)
    800027dc:	6406                	ld	s0,64(sp)
    800027de:	74e2                	ld	s1,56(sp)
    800027e0:	7942                	ld	s2,48(sp)
    800027e2:	79a2                	ld	s3,40(sp)
    800027e4:	7a02                	ld	s4,32(sp)
    800027e6:	6ae2                	ld	s5,24(sp)
    800027e8:	6b42                	ld	s6,16(sp)
    800027ea:	6ba2                	ld	s7,8(sp)
    800027ec:	6161                	addi	sp,sp,80
    800027ee:	8082                	ret

00000000800027f0 <pause_system>:

int
pause_system(int seconds)
{
    800027f0:	1141                	addi	sp,sp,-16
    800027f2:	e406                	sd	ra,8(sp)
    800027f4:	e022                	sd	s0,0(sp)
    800027f6:	0800                	addi	s0,sp,16
  pause_time = ticks + seconds*10;  
    800027f8:	0025179b          	slliw	a5,a0,0x2
    800027fc:	9fa9                	addw	a5,a5,a0
    800027fe:	0017979b          	slliw	a5,a5,0x1
    80002802:	00007517          	auipc	a0,0x7
    80002806:	83652503          	lw	a0,-1994(a0) # 80009038 <ticks>
    8000280a:	9fa9                	addw	a5,a5,a0
    8000280c:	00007717          	auipc	a4,0x7
    80002810:	80f72e23          	sw	a5,-2020(a4) # 80009028 <pause_time>
  yield();
    80002814:	00000097          	auipc	ra,0x0
    80002818:	9f6080e7          	jalr	-1546(ra) # 8000220a <yield>
  return 0;
}
    8000281c:	4501                	li	a0,0
    8000281e:	60a2                	ld	ra,8(sp)
    80002820:	6402                	ld	s0,0(sp)
    80002822:	0141                	addi	sp,sp,16
    80002824:	8082                	ret

0000000080002826 <swtch>:
    80002826:	00153023          	sd	ra,0(a0)
    8000282a:	00253423          	sd	sp,8(a0)
    8000282e:	e900                	sd	s0,16(a0)
    80002830:	ed04                	sd	s1,24(a0)
    80002832:	03253023          	sd	s2,32(a0)
    80002836:	03353423          	sd	s3,40(a0)
    8000283a:	03453823          	sd	s4,48(a0)
    8000283e:	03553c23          	sd	s5,56(a0)
    80002842:	05653023          	sd	s6,64(a0)
    80002846:	05753423          	sd	s7,72(a0)
    8000284a:	05853823          	sd	s8,80(a0)
    8000284e:	05953c23          	sd	s9,88(a0)
    80002852:	07a53023          	sd	s10,96(a0)
    80002856:	07b53423          	sd	s11,104(a0)
    8000285a:	0005b083          	ld	ra,0(a1)
    8000285e:	0085b103          	ld	sp,8(a1)
    80002862:	6980                	ld	s0,16(a1)
    80002864:	6d84                	ld	s1,24(a1)
    80002866:	0205b903          	ld	s2,32(a1)
    8000286a:	0285b983          	ld	s3,40(a1)
    8000286e:	0305ba03          	ld	s4,48(a1)
    80002872:	0385ba83          	ld	s5,56(a1)
    80002876:	0405bb03          	ld	s6,64(a1)
    8000287a:	0485bb83          	ld	s7,72(a1)
    8000287e:	0505bc03          	ld	s8,80(a1)
    80002882:	0585bc83          	ld	s9,88(a1)
    80002886:	0605bd03          	ld	s10,96(a1)
    8000288a:	0685bd83          	ld	s11,104(a1)
    8000288e:	8082                	ret

0000000080002890 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002890:	1141                	addi	sp,sp,-16
    80002892:	e406                	sd	ra,8(sp)
    80002894:	e022                	sd	s0,0(sp)
    80002896:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002898:	00006597          	auipc	a1,0x6
    8000289c:	a8058593          	addi	a1,a1,-1408 # 80008318 <states.1842+0x30>
    800028a0:	0000e517          	auipc	a0,0xe
    800028a4:	9a050513          	addi	a0,a0,-1632 # 80010240 <tickslock>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	2ac080e7          	jalr	684(ra) # 80000b54 <initlock>
}
    800028b0:	60a2                	ld	ra,8(sp)
    800028b2:	6402                	ld	s0,0(sp)
    800028b4:	0141                	addi	sp,sp,16
    800028b6:	8082                	ret

00000000800028b8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028b8:	1141                	addi	sp,sp,-16
    800028ba:	e422                	sd	s0,8(sp)
    800028bc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028be:	00003797          	auipc	a5,0x3
    800028c2:	4a278793          	addi	a5,a5,1186 # 80005d60 <kernelvec>
    800028c6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028ca:	6422                	ld	s0,8(sp)
    800028cc:	0141                	addi	sp,sp,16
    800028ce:	8082                	ret

00000000800028d0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028d0:	1141                	addi	sp,sp,-16
    800028d2:	e406                	sd	ra,8(sp)
    800028d4:	e022                	sd	s0,0(sp)
    800028d6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028d8:	fffff097          	auipc	ra,0xfffff
    800028dc:	0e0080e7          	jalr	224(ra) # 800019b8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028ea:	00004617          	auipc	a2,0x4
    800028ee:	71660613          	addi	a2,a2,1814 # 80007000 <_trampoline>
    800028f2:	00004697          	auipc	a3,0x4
    800028f6:	70e68693          	addi	a3,a3,1806 # 80007000 <_trampoline>
    800028fa:	8e91                	sub	a3,a3,a2
    800028fc:	040007b7          	lui	a5,0x4000
    80002900:	17fd                	addi	a5,a5,-1
    80002902:	07b2                	slli	a5,a5,0xc
    80002904:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002906:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000290a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000290c:	180026f3          	csrr	a3,satp
    80002910:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002912:	6d38                	ld	a4,88(a0)
    80002914:	6134                	ld	a3,64(a0)
    80002916:	6585                	lui	a1,0x1
    80002918:	96ae                	add	a3,a3,a1
    8000291a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000291c:	6d38                	ld	a4,88(a0)
    8000291e:	00000697          	auipc	a3,0x0
    80002922:	13868693          	addi	a3,a3,312 # 80002a56 <usertrap>
    80002926:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002928:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000292a:	8692                	mv	a3,tp
    8000292c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002932:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002936:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000293a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000293e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002940:	6f18                	ld	a4,24(a4)
    80002942:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002946:	692c                	ld	a1,80(a0)
    80002948:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000294a:	00004717          	auipc	a4,0x4
    8000294e:	74670713          	addi	a4,a4,1862 # 80007090 <userret>
    80002952:	8f11                	sub	a4,a4,a2
    80002954:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002956:	577d                	li	a4,-1
    80002958:	177e                	slli	a4,a4,0x3f
    8000295a:	8dd9                	or	a1,a1,a4
    8000295c:	02000537          	lui	a0,0x2000
    80002960:	157d                	addi	a0,a0,-1
    80002962:	0536                	slli	a0,a0,0xd
    80002964:	9782                	jalr	a5
}
    80002966:	60a2                	ld	ra,8(sp)
    80002968:	6402                	ld	s0,0(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000296e:	1101                	addi	sp,sp,-32
    80002970:	ec06                	sd	ra,24(sp)
    80002972:	e822                	sd	s0,16(sp)
    80002974:	e426                	sd	s1,8(sp)
    80002976:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002978:	0000e497          	auipc	s1,0xe
    8000297c:	8c848493          	addi	s1,s1,-1848 # 80010240 <tickslock>
    80002980:	8526                	mv	a0,s1
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	262080e7          	jalr	610(ra) # 80000be4 <acquire>
  ticks++;
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	6ae50513          	addi	a0,a0,1710 # 80009038 <ticks>
    80002992:	411c                	lw	a5,0(a0)
    80002994:	2785                	addiw	a5,a5,1
    80002996:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	a3a080e7          	jalr	-1478(ra) # 800023d2 <wakeup>
  release(&tickslock);
    800029a0:	8526                	mv	a0,s1
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	2f6080e7          	jalr	758(ra) # 80000c98 <release>
}
    800029aa:	60e2                	ld	ra,24(sp)
    800029ac:	6442                	ld	s0,16(sp)
    800029ae:	64a2                	ld	s1,8(sp)
    800029b0:	6105                	addi	sp,sp,32
    800029b2:	8082                	ret

00000000800029b4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029c2:	00074d63          	bltz	a4,800029dc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029c6:	57fd                	li	a5,-1
    800029c8:	17fe                	slli	a5,a5,0x3f
    800029ca:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029cc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029ce:	06f70363          	beq	a4,a5,80002a34 <devintr+0x80>
  }
}
    800029d2:	60e2                	ld	ra,24(sp)
    800029d4:	6442                	ld	s0,16(sp)
    800029d6:	64a2                	ld	s1,8(sp)
    800029d8:	6105                	addi	sp,sp,32
    800029da:	8082                	ret
     (scause & 0xff) == 9){
    800029dc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029e0:	46a5                	li	a3,9
    800029e2:	fed792e3          	bne	a5,a3,800029c6 <devintr+0x12>
    int irq = plic_claim();
    800029e6:	00003097          	auipc	ra,0x3
    800029ea:	482080e7          	jalr	1154(ra) # 80005e68 <plic_claim>
    800029ee:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029f0:	47a9                	li	a5,10
    800029f2:	02f50763          	beq	a0,a5,80002a20 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029f6:	4785                	li	a5,1
    800029f8:	02f50963          	beq	a0,a5,80002a2a <devintr+0x76>
    return 1;
    800029fc:	4505                	li	a0,1
    } else if(irq){
    800029fe:	d8f1                	beqz	s1,800029d2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a00:	85a6                	mv	a1,s1
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	91e50513          	addi	a0,a0,-1762 # 80008320 <states.1842+0x38>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a12:	8526                	mv	a0,s1
    80002a14:	00003097          	auipc	ra,0x3
    80002a18:	478080e7          	jalr	1144(ra) # 80005e8c <plic_complete>
    return 1;
    80002a1c:	4505                	li	a0,1
    80002a1e:	bf55                	j	800029d2 <devintr+0x1e>
      uartintr();
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	f88080e7          	jalr	-120(ra) # 800009a8 <uartintr>
    80002a28:	b7ed                	j	80002a12 <devintr+0x5e>
      virtio_disk_intr();
    80002a2a:	00004097          	auipc	ra,0x4
    80002a2e:	942080e7          	jalr	-1726(ra) # 8000636c <virtio_disk_intr>
    80002a32:	b7c5                	j	80002a12 <devintr+0x5e>
    if(cpuid() == 0){
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	f58080e7          	jalr	-168(ra) # 8000198c <cpuid>
    80002a3c:	c901                	beqz	a0,80002a4c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a3e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a44:	14479073          	csrw	sip,a5
    return 2;
    80002a48:	4509                	li	a0,2
    80002a4a:	b761                	j	800029d2 <devintr+0x1e>
      clockintr();
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	f22080e7          	jalr	-222(ra) # 8000296e <clockintr>
    80002a54:	b7ed                	j	80002a3e <devintr+0x8a>

0000000080002a56 <usertrap>:
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a64:	1007f793          	andi	a5,a5,256
    80002a68:	e3a5                	bnez	a5,80002ac8 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a6a:	00003797          	auipc	a5,0x3
    80002a6e:	2f678793          	addi	a5,a5,758 # 80005d60 <kernelvec>
    80002a72:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f42080e7          	jalr	-190(ra) # 800019b8 <myproc>
    80002a7e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a80:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a82:	14102773          	csrr	a4,sepc
    80002a86:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a88:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a8c:	47a1                	li	a5,8
    80002a8e:	04f71b63          	bne	a4,a5,80002ae4 <usertrap+0x8e>
    if(p->killed)
    80002a92:	551c                	lw	a5,40(a0)
    80002a94:	e3b1                	bnez	a5,80002ad8 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002a96:	6cb8                	ld	a4,88(s1)
    80002a98:	6f1c                	ld	a5,24(a4)
    80002a9a:	0791                	addi	a5,a5,4
    80002a9c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aa2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa6:	10079073          	csrw	sstatus,a5
    syscall();
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	2b4080e7          	jalr	692(ra) # 80002d5e <syscall>
  if(p->killed)
    80002ab2:	549c                	lw	a5,40(s1)
    80002ab4:	e7b5                	bnez	a5,80002b20 <usertrap+0xca>
  usertrapret();
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	e1a080e7          	jalr	-486(ra) # 800028d0 <usertrapret>
}
    80002abe:	60e2                	ld	ra,24(sp)
    80002ac0:	6442                	ld	s0,16(sp)
    80002ac2:	64a2                	ld	s1,8(sp)
    80002ac4:	6105                	addi	sp,sp,32
    80002ac6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	87850513          	addi	a0,a0,-1928 # 80008340 <states.1842+0x58>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	a6e080e7          	jalr	-1426(ra) # 8000053e <panic>
      exit(-1);
    80002ad8:	557d                	li	a0,-1
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	9c8080e7          	jalr	-1592(ra) # 800024a2 <exit>
    80002ae2:	bf55                	j	80002a96 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	ed0080e7          	jalr	-304(ra) # 800029b4 <devintr>
    80002aec:	f179                	bnez	a0,80002ab2 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aee:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002af2:	5890                	lw	a2,48(s1)
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	86c50513          	addi	a0,a0,-1940 # 80008360 <states.1842+0x78>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a8c080e7          	jalr	-1396(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b08:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	88450513          	addi	a0,a0,-1916 # 80008390 <states.1842+0xa8>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a74080e7          	jalr	-1420(ra) # 80000588 <printf>
    p->killed = 1;
    80002b1c:	4785                	li	a5,1
    80002b1e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b20:	557d                	li	a0,-1
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	980080e7          	jalr	-1664(ra) # 800024a2 <exit>
    80002b2a:	b771                	j	80002ab6 <usertrap+0x60>

0000000080002b2c <kerneltrap>:
{
    80002b2c:	7179                	addi	sp,sp,-48
    80002b2e:	f406                	sd	ra,40(sp)
    80002b30:	f022                	sd	s0,32(sp)
    80002b32:	ec26                	sd	s1,24(sp)
    80002b34:	e84a                	sd	s2,16(sp)
    80002b36:	e44e                	sd	s3,8(sp)
    80002b38:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b42:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b46:	1004f793          	andi	a5,s1,256
    80002b4a:	cb85                	beqz	a5,80002b7a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b50:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b52:	ef85                	bnez	a5,80002b8a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	e60080e7          	jalr	-416(ra) # 800029b4 <devintr>
    80002b5c:	cd1d                	beqz	a0,80002b9a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002b5e:	4789                	li	a5,2
    80002b60:	06f50a63          	beq	a0,a5,80002bd4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b64:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b68:	10049073          	csrw	sstatus,s1
}
    80002b6c:	70a2                	ld	ra,40(sp)
    80002b6e:	7402                	ld	s0,32(sp)
    80002b70:	64e2                	ld	s1,24(sp)
    80002b72:	6942                	ld	s2,16(sp)
    80002b74:	69a2                	ld	s3,8(sp)
    80002b76:	6145                	addi	sp,sp,48
    80002b78:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	83650513          	addi	a0,a0,-1994 # 800083b0 <states.1842+0xc8>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	84e50513          	addi	a0,a0,-1970 # 800083d8 <states.1842+0xf0>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9ac080e7          	jalr	-1620(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b9a:	85ce                	mv	a1,s3
    80002b9c:	00006517          	auipc	a0,0x6
    80002ba0:	85c50513          	addi	a0,a0,-1956 # 800083f8 <states.1842+0x110>
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	9e4080e7          	jalr	-1564(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	85450513          	addi	a0,a0,-1964 # 80008408 <states.1842+0x120>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	9cc080e7          	jalr	-1588(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bc4:	00006517          	auipc	a0,0x6
    80002bc8:	85c50513          	addi	a0,a0,-1956 # 80008420 <states.1842+0x138>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	de4080e7          	jalr	-540(ra) # 800019b8 <myproc>
    80002bdc:	d541                	beqz	a0,80002b64 <kerneltrap+0x38>
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	dda080e7          	jalr	-550(ra) # 800019b8 <myproc>
    80002be6:	bfbd                	j	80002b64 <kerneltrap+0x38>

0000000080002be8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002be8:	1101                	addi	sp,sp,-32
    80002bea:	ec06                	sd	ra,24(sp)
    80002bec:	e822                	sd	s0,16(sp)
    80002bee:	e426                	sd	s1,8(sp)
    80002bf0:	1000                	addi	s0,sp,32
    80002bf2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	dc4080e7          	jalr	-572(ra) # 800019b8 <myproc>
  switch (n) {
    80002bfc:	4795                	li	a5,5
    80002bfe:	0497e163          	bltu	a5,s1,80002c40 <argraw+0x58>
    80002c02:	048a                	slli	s1,s1,0x2
    80002c04:	00006717          	auipc	a4,0x6
    80002c08:	85470713          	addi	a4,a4,-1964 # 80008458 <states.1842+0x170>
    80002c0c:	94ba                	add	s1,s1,a4
    80002c0e:	409c                	lw	a5,0(s1)
    80002c10:	97ba                	add	a5,a5,a4
    80002c12:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c14:	6d3c                	ld	a5,88(a0)
    80002c16:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret
    return p->trapframe->a1;
    80002c22:	6d3c                	ld	a5,88(a0)
    80002c24:	7fa8                	ld	a0,120(a5)
    80002c26:	bfcd                	j	80002c18 <argraw+0x30>
    return p->trapframe->a2;
    80002c28:	6d3c                	ld	a5,88(a0)
    80002c2a:	63c8                	ld	a0,128(a5)
    80002c2c:	b7f5                	j	80002c18 <argraw+0x30>
    return p->trapframe->a3;
    80002c2e:	6d3c                	ld	a5,88(a0)
    80002c30:	67c8                	ld	a0,136(a5)
    80002c32:	b7dd                	j	80002c18 <argraw+0x30>
    return p->trapframe->a4;
    80002c34:	6d3c                	ld	a5,88(a0)
    80002c36:	6bc8                	ld	a0,144(a5)
    80002c38:	b7c5                	j	80002c18 <argraw+0x30>
    return p->trapframe->a5;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	6fc8                	ld	a0,152(a5)
    80002c3e:	bfe9                	j	80002c18 <argraw+0x30>
  panic("argraw");
    80002c40:	00005517          	auipc	a0,0x5
    80002c44:	7f050513          	addi	a0,a0,2032 # 80008430 <states.1842+0x148>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	8f6080e7          	jalr	-1802(ra) # 8000053e <panic>

0000000080002c50 <fetchaddr>:
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	e04a                	sd	s2,0(sp)
    80002c5a:	1000                	addi	s0,sp,32
    80002c5c:	84aa                	mv	s1,a0
    80002c5e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	d58080e7          	jalr	-680(ra) # 800019b8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c68:	653c                	ld	a5,72(a0)
    80002c6a:	02f4f863          	bgeu	s1,a5,80002c9a <fetchaddr+0x4a>
    80002c6e:	00848713          	addi	a4,s1,8
    80002c72:	02e7e663          	bltu	a5,a4,80002c9e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c76:	46a1                	li	a3,8
    80002c78:	8626                	mv	a2,s1
    80002c7a:	85ca                	mv	a1,s2
    80002c7c:	6928                	ld	a0,80(a0)
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	a88080e7          	jalr	-1400(ra) # 80001706 <copyin>
    80002c86:	00a03533          	snez	a0,a0
    80002c8a:	40a00533          	neg	a0,a0
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6902                	ld	s2,0(sp)
    80002c96:	6105                	addi	sp,sp,32
    80002c98:	8082                	ret
    return -1;
    80002c9a:	557d                	li	a0,-1
    80002c9c:	bfcd                	j	80002c8e <fetchaddr+0x3e>
    80002c9e:	557d                	li	a0,-1
    80002ca0:	b7fd                	j	80002c8e <fetchaddr+0x3e>

0000000080002ca2 <fetchstr>:
{
    80002ca2:	7179                	addi	sp,sp,-48
    80002ca4:	f406                	sd	ra,40(sp)
    80002ca6:	f022                	sd	s0,32(sp)
    80002ca8:	ec26                	sd	s1,24(sp)
    80002caa:	e84a                	sd	s2,16(sp)
    80002cac:	e44e                	sd	s3,8(sp)
    80002cae:	1800                	addi	s0,sp,48
    80002cb0:	892a                	mv	s2,a0
    80002cb2:	84ae                	mv	s1,a1
    80002cb4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	d02080e7          	jalr	-766(ra) # 800019b8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cbe:	86ce                	mv	a3,s3
    80002cc0:	864a                	mv	a2,s2
    80002cc2:	85a6                	mv	a1,s1
    80002cc4:	6928                	ld	a0,80(a0)
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	acc080e7          	jalr	-1332(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002cce:	00054763          	bltz	a0,80002cdc <fetchstr+0x3a>
  return strlen(buf);
    80002cd2:	8526                	mv	a0,s1
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	190080e7          	jalr	400(ra) # 80000e64 <strlen>
}
    80002cdc:	70a2                	ld	ra,40(sp)
    80002cde:	7402                	ld	s0,32(sp)
    80002ce0:	64e2                	ld	s1,24(sp)
    80002ce2:	6942                	ld	s2,16(sp)
    80002ce4:	69a2                	ld	s3,8(sp)
    80002ce6:	6145                	addi	sp,sp,48
    80002ce8:	8082                	ret

0000000080002cea <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	1000                	addi	s0,sp,32
    80002cf4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	ef2080e7          	jalr	-270(ra) # 80002be8 <argraw>
    80002cfe:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d00:	4501                	li	a0,0
    80002d02:	60e2                	ld	ra,24(sp)
    80002d04:	6442                	ld	s0,16(sp)
    80002d06:	64a2                	ld	s1,8(sp)
    80002d08:	6105                	addi	sp,sp,32
    80002d0a:	8082                	ret

0000000080002d0c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	e426                	sd	s1,8(sp)
    80002d14:	1000                	addi	s0,sp,32
    80002d16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	ed0080e7          	jalr	-304(ra) # 80002be8 <argraw>
    80002d20:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d22:	4501                	li	a0,0
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	64a2                	ld	s1,8(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d2e:	1101                	addi	sp,sp,-32
    80002d30:	ec06                	sd	ra,24(sp)
    80002d32:	e822                	sd	s0,16(sp)
    80002d34:	e426                	sd	s1,8(sp)
    80002d36:	e04a                	sd	s2,0(sp)
    80002d38:	1000                	addi	s0,sp,32
    80002d3a:	84ae                	mv	s1,a1
    80002d3c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	eaa080e7          	jalr	-342(ra) # 80002be8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d46:	864a                	mv	a2,s2
    80002d48:	85a6                	mv	a1,s1
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	f58080e7          	jalr	-168(ra) # 80002ca2 <fetchstr>
}
    80002d52:	60e2                	ld	ra,24(sp)
    80002d54:	6442                	ld	s0,16(sp)
    80002d56:	64a2                	ld	s1,8(sp)
    80002d58:	6902                	ld	s2,0(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret

0000000080002d5e <syscall>:
[SYS_pause_system] sys_pause_system,
};

void
syscall(void)
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	e04a                	sd	s2,0(sp)
    80002d68:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	c4e080e7          	jalr	-946(ra) # 800019b8 <myproc>
    80002d72:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d74:	05853903          	ld	s2,88(a0)
    80002d78:	0a893783          	ld	a5,168(s2)
    80002d7c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d80:	37fd                	addiw	a5,a5,-1
    80002d82:	4759                	li	a4,22
    80002d84:	00f76f63          	bltu	a4,a5,80002da2 <syscall+0x44>
    80002d88:	00369713          	slli	a4,a3,0x3
    80002d8c:	00005797          	auipc	a5,0x5
    80002d90:	6e478793          	addi	a5,a5,1764 # 80008470 <syscalls>
    80002d94:	97ba                	add	a5,a5,a4
    80002d96:	639c                	ld	a5,0(a5)
    80002d98:	c789                	beqz	a5,80002da2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d9a:	9782                	jalr	a5
    80002d9c:	06a93823          	sd	a0,112(s2)
    80002da0:	a839                	j	80002dbe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002da2:	15848613          	addi	a2,s1,344
    80002da6:	588c                	lw	a1,48(s1)
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	69050513          	addi	a0,a0,1680 # 80008438 <states.1842+0x150>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	7d8080e7          	jalr	2008(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002db8:	6cbc                	ld	a5,88(s1)
    80002dba:	577d                	li	a4,-1
    80002dbc:	fbb8                	sd	a4,112(a5)
  }
}
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	64a2                	ld	s1,8(sp)
    80002dc4:	6902                	ld	s2,0(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dca:	1101                	addi	sp,sp,-32
    80002dcc:	ec06                	sd	ra,24(sp)
    80002dce:	e822                	sd	s0,16(sp)
    80002dd0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dd2:	fec40593          	addi	a1,s0,-20
    80002dd6:	4501                	li	a0,0
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	f12080e7          	jalr	-238(ra) # 80002cea <argint>
    return -1;
    80002de0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002de2:	00054963          	bltz	a0,80002df4 <sys_exit+0x2a>
  exit(n);
    80002de6:	fec42503          	lw	a0,-20(s0)
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	6b8080e7          	jalr	1720(ra) # 800024a2 <exit>
  return 0;  // not reached
    80002df2:	4781                	li	a5,0
}
    80002df4:	853e                	mv	a0,a5
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dfe:	1141                	addi	sp,sp,-16
    80002e00:	e406                	sd	ra,8(sp)
    80002e02:	e022                	sd	s0,0(sp)
    80002e04:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	bb2080e7          	jalr	-1102(ra) # 800019b8 <myproc>
}
    80002e0e:	5908                	lw	a0,48(a0)
    80002e10:	60a2                	ld	ra,8(sp)
    80002e12:	6402                	ld	s0,0(sp)
    80002e14:	0141                	addi	sp,sp,16
    80002e16:	8082                	ret

0000000080002e18 <sys_fork>:

uint64
sys_fork(void)
{
    80002e18:	1141                	addi	sp,sp,-16
    80002e1a:	e406                	sd	ra,8(sp)
    80002e1c:	e022                	sd	s0,0(sp)
    80002e1e:	0800                	addi	s0,sp,16
  return fork();
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	f72080e7          	jalr	-142(ra) # 80001d92 <fork>
}
    80002e28:	60a2                	ld	ra,8(sp)
    80002e2a:	6402                	ld	s0,0(sp)
    80002e2c:	0141                	addi	sp,sp,16
    80002e2e:	8082                	ret

0000000080002e30 <sys_wait>:

uint64
sys_wait(void)
{
    80002e30:	1101                	addi	sp,sp,-32
    80002e32:	ec06                	sd	ra,24(sp)
    80002e34:	e822                	sd	s0,16(sp)
    80002e36:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e38:	fe840593          	addi	a1,s0,-24
    80002e3c:	4501                	li	a0,0
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	ece080e7          	jalr	-306(ra) # 80002d0c <argaddr>
    80002e46:	87aa                	mv	a5,a0
    return -1;
    80002e48:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e4a:	0007c863          	bltz	a5,80002e5a <sys_wait+0x2a>
  return wait(p);
    80002e4e:	fe843503          	ld	a0,-24(s0)
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	458080e7          	jalr	1112(ra) # 800022aa <wait>
}
    80002e5a:	60e2                	ld	ra,24(sp)
    80002e5c:	6442                	ld	s0,16(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret

0000000080002e62 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e62:	7179                	addi	sp,sp,-48
    80002e64:	f406                	sd	ra,40(sp)
    80002e66:	f022                	sd	s0,32(sp)
    80002e68:	ec26                	sd	s1,24(sp)
    80002e6a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e6c:	fdc40593          	addi	a1,s0,-36
    80002e70:	4501                	li	a0,0
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	e78080e7          	jalr	-392(ra) # 80002cea <argint>
    80002e7a:	87aa                	mv	a5,a0
    return -1;
    80002e7c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e7e:	0207c063          	bltz	a5,80002e9e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	b36080e7          	jalr	-1226(ra) # 800019b8 <myproc>
    80002e8a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e8c:	fdc42503          	lw	a0,-36(s0)
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	e8e080e7          	jalr	-370(ra) # 80001d1e <growproc>
    80002e98:	00054863          	bltz	a0,80002ea8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e9c:	8526                	mv	a0,s1
}
    80002e9e:	70a2                	ld	ra,40(sp)
    80002ea0:	7402                	ld	s0,32(sp)
    80002ea2:	64e2                	ld	s1,24(sp)
    80002ea4:	6145                	addi	sp,sp,48
    80002ea6:	8082                	ret
    return -1;
    80002ea8:	557d                	li	a0,-1
    80002eaa:	bfd5                	j	80002e9e <sys_sbrk+0x3c>

0000000080002eac <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eac:	7139                	addi	sp,sp,-64
    80002eae:	fc06                	sd	ra,56(sp)
    80002eb0:	f822                	sd	s0,48(sp)
    80002eb2:	f426                	sd	s1,40(sp)
    80002eb4:	f04a                	sd	s2,32(sp)
    80002eb6:	ec4e                	sd	s3,24(sp)
    80002eb8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eba:	fcc40593          	addi	a1,s0,-52
    80002ebe:	4501                	li	a0,0
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	e2a080e7          	jalr	-470(ra) # 80002cea <argint>
    return -1;
    80002ec8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eca:	06054563          	bltz	a0,80002f34 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ece:	0000d517          	auipc	a0,0xd
    80002ed2:	37250513          	addi	a0,a0,882 # 80010240 <tickslock>
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	d0e080e7          	jalr	-754(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002ede:	00006917          	auipc	s2,0x6
    80002ee2:	15a92903          	lw	s2,346(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002ee6:	fcc42783          	lw	a5,-52(s0)
    80002eea:	cf85                	beqz	a5,80002f22 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eec:	0000d997          	auipc	s3,0xd
    80002ef0:	35498993          	addi	s3,s3,852 # 80010240 <tickslock>
    80002ef4:	00006497          	auipc	s1,0x6
    80002ef8:	14448493          	addi	s1,s1,324 # 80009038 <ticks>
    if(myproc()->killed){
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	abc080e7          	jalr	-1348(ra) # 800019b8 <myproc>
    80002f04:	551c                	lw	a5,40(a0)
    80002f06:	ef9d                	bnez	a5,80002f44 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f08:	85ce                	mv	a1,s3
    80002f0a:	8526                	mv	a0,s1
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	33a080e7          	jalr	826(ra) # 80002246 <sleep>
  while(ticks - ticks0 < n){
    80002f14:	409c                	lw	a5,0(s1)
    80002f16:	412787bb          	subw	a5,a5,s2
    80002f1a:	fcc42703          	lw	a4,-52(s0)
    80002f1e:	fce7efe3          	bltu	a5,a4,80002efc <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f22:	0000d517          	auipc	a0,0xd
    80002f26:	31e50513          	addi	a0,a0,798 # 80010240 <tickslock>
    80002f2a:	ffffe097          	auipc	ra,0xffffe
    80002f2e:	d6e080e7          	jalr	-658(ra) # 80000c98 <release>
  return 0;
    80002f32:	4781                	li	a5,0
}
    80002f34:	853e                	mv	a0,a5
    80002f36:	70e2                	ld	ra,56(sp)
    80002f38:	7442                	ld	s0,48(sp)
    80002f3a:	74a2                	ld	s1,40(sp)
    80002f3c:	7902                	ld	s2,32(sp)
    80002f3e:	69e2                	ld	s3,24(sp)
    80002f40:	6121                	addi	sp,sp,64
    80002f42:	8082                	ret
      release(&tickslock);
    80002f44:	0000d517          	auipc	a0,0xd
    80002f48:	2fc50513          	addi	a0,a0,764 # 80010240 <tickslock>
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	d4c080e7          	jalr	-692(ra) # 80000c98 <release>
      return -1;
    80002f54:	57fd                	li	a5,-1
    80002f56:	bff9                	j	80002f34 <sys_sleep+0x88>

0000000080002f58 <sys_kill>:

uint64
sys_kill(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f60:	fec40593          	addi	a1,s0,-20
    80002f64:	4501                	li	a0,0
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	d84080e7          	jalr	-636(ra) # 80002cea <argint>
    80002f6e:	87aa                	mv	a5,a0
    return -1;
    80002f70:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f72:	0007c863          	bltz	a5,80002f82 <sys_kill+0x2a>
  return kill(pid);
    80002f76:	fec42503          	lw	a0,-20(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	5fe080e7          	jalr	1534(ra) # 80002578 <kill>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	e426                	sd	s1,8(sp)
    80002f92:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f94:	0000d517          	auipc	a0,0xd
    80002f98:	2ac50513          	addi	a0,a0,684 # 80010240 <tickslock>
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	c48080e7          	jalr	-952(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fa4:	00006497          	auipc	s1,0x6
    80002fa8:	0944a483          	lw	s1,148(s1) # 80009038 <ticks>
  release(&tickslock);
    80002fac:	0000d517          	auipc	a0,0xd
    80002fb0:	29450513          	addi	a0,a0,660 # 80010240 <tickslock>
    80002fb4:	ffffe097          	auipc	ra,0xffffe
    80002fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
  return xticks;
}
    80002fbc:	02049513          	slli	a0,s1,0x20
    80002fc0:	9101                	srli	a0,a0,0x20
    80002fc2:	60e2                	ld	ra,24(sp)
    80002fc4:	6442                	ld	s0,16(sp)
    80002fc6:	64a2                	ld	s1,8(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret

0000000080002fcc <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002fcc:	1141                	addi	sp,sp,-16
    80002fce:	e406                	sd	ra,8(sp)
    80002fd0:	e022                	sd	s0,0(sp)
    80002fd2:	0800                	addi	s0,sp,16
  return kill_system();
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	616080e7          	jalr	1558(ra) # 800025ea <kill_system>
}
    80002fdc:	60a2                	ld	ra,8(sp)
    80002fde:	6402                	ld	s0,0(sp)
    80002fe0:	0141                	addi	sp,sp,16
    80002fe2:	8082                	ret

0000000080002fe4 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002fe4:	1101                	addi	sp,sp,-32
    80002fe6:	ec06                	sd	ra,24(sp)
    80002fe8:	e822                	sd	s0,16(sp)
    80002fea:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80002fec:	fec40593          	addi	a1,s0,-20
    80002ff0:	4501                	li	a0,0
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	cf8080e7          	jalr	-776(ra) # 80002cea <argint>
    80002ffa:	87aa                	mv	a5,a0
    return -1;
    80002ffc:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80002ffe:	0007c863          	bltz	a5,8000300e <sys_pause_system+0x2a>
  return pause_system(seconds);
    80003002:	fec42503          	lw	a0,-20(s0)
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	7ea080e7          	jalr	2026(ra) # 800027f0 <pause_system>
}
    8000300e:	60e2                	ld	ra,24(sp)
    80003010:	6442                	ld	s0,16(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003016:	7179                	addi	sp,sp,-48
    80003018:	f406                	sd	ra,40(sp)
    8000301a:	f022                	sd	s0,32(sp)
    8000301c:	ec26                	sd	s1,24(sp)
    8000301e:	e84a                	sd	s2,16(sp)
    80003020:	e44e                	sd	s3,8(sp)
    80003022:	e052                	sd	s4,0(sp)
    80003024:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003026:	00005597          	auipc	a1,0x5
    8000302a:	50a58593          	addi	a1,a1,1290 # 80008530 <syscalls+0xc0>
    8000302e:	0000d517          	auipc	a0,0xd
    80003032:	22a50513          	addi	a0,a0,554 # 80010258 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	b1e080e7          	jalr	-1250(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000303e:	00015797          	auipc	a5,0x15
    80003042:	21a78793          	addi	a5,a5,538 # 80018258 <bcache+0x8000>
    80003046:	00015717          	auipc	a4,0x15
    8000304a:	47a70713          	addi	a4,a4,1146 # 800184c0 <bcache+0x8268>
    8000304e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003052:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003056:	0000d497          	auipc	s1,0xd
    8000305a:	21a48493          	addi	s1,s1,538 # 80010270 <bcache+0x18>
    b->next = bcache.head.next;
    8000305e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003060:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003062:	00005a17          	auipc	s4,0x5
    80003066:	4d6a0a13          	addi	s4,s4,1238 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000306a:	2b893783          	ld	a5,696(s2)
    8000306e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003070:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003074:	85d2                	mv	a1,s4
    80003076:	01048513          	addi	a0,s1,16
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	4bc080e7          	jalr	1212(ra) # 80004536 <initsleeplock>
    bcache.head.next->prev = b;
    80003082:	2b893783          	ld	a5,696(s2)
    80003086:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003088:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000308c:	45848493          	addi	s1,s1,1112
    80003090:	fd349de3          	bne	s1,s3,8000306a <binit+0x54>
  }
}
    80003094:	70a2                	ld	ra,40(sp)
    80003096:	7402                	ld	s0,32(sp)
    80003098:	64e2                	ld	s1,24(sp)
    8000309a:	6942                	ld	s2,16(sp)
    8000309c:	69a2                	ld	s3,8(sp)
    8000309e:	6a02                	ld	s4,0(sp)
    800030a0:	6145                	addi	sp,sp,48
    800030a2:	8082                	ret

00000000800030a4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030a4:	7179                	addi	sp,sp,-48
    800030a6:	f406                	sd	ra,40(sp)
    800030a8:	f022                	sd	s0,32(sp)
    800030aa:	ec26                	sd	s1,24(sp)
    800030ac:	e84a                	sd	s2,16(sp)
    800030ae:	e44e                	sd	s3,8(sp)
    800030b0:	1800                	addi	s0,sp,48
    800030b2:	89aa                	mv	s3,a0
    800030b4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030b6:	0000d517          	auipc	a0,0xd
    800030ba:	1a250513          	addi	a0,a0,418 # 80010258 <bcache>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030c6:	00015497          	auipc	s1,0x15
    800030ca:	44a4b483          	ld	s1,1098(s1) # 80018510 <bcache+0x82b8>
    800030ce:	00015797          	auipc	a5,0x15
    800030d2:	3f278793          	addi	a5,a5,1010 # 800184c0 <bcache+0x8268>
    800030d6:	02f48f63          	beq	s1,a5,80003114 <bread+0x70>
    800030da:	873e                	mv	a4,a5
    800030dc:	a021                	j	800030e4 <bread+0x40>
    800030de:	68a4                	ld	s1,80(s1)
    800030e0:	02e48a63          	beq	s1,a4,80003114 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030e4:	449c                	lw	a5,8(s1)
    800030e6:	ff379ce3          	bne	a5,s3,800030de <bread+0x3a>
    800030ea:	44dc                	lw	a5,12(s1)
    800030ec:	ff2799e3          	bne	a5,s2,800030de <bread+0x3a>
      b->refcnt++;
    800030f0:	40bc                	lw	a5,64(s1)
    800030f2:	2785                	addiw	a5,a5,1
    800030f4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f6:	0000d517          	auipc	a0,0xd
    800030fa:	16250513          	addi	a0,a0,354 # 80010258 <bcache>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003106:	01048513          	addi	a0,s1,16
    8000310a:	00001097          	auipc	ra,0x1
    8000310e:	466080e7          	jalr	1126(ra) # 80004570 <acquiresleep>
      return b;
    80003112:	a8b9                	j	80003170 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003114:	00015497          	auipc	s1,0x15
    80003118:	3f44b483          	ld	s1,1012(s1) # 80018508 <bcache+0x82b0>
    8000311c:	00015797          	auipc	a5,0x15
    80003120:	3a478793          	addi	a5,a5,932 # 800184c0 <bcache+0x8268>
    80003124:	00f48863          	beq	s1,a5,80003134 <bread+0x90>
    80003128:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000312a:	40bc                	lw	a5,64(s1)
    8000312c:	cf81                	beqz	a5,80003144 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000312e:	64a4                	ld	s1,72(s1)
    80003130:	fee49de3          	bne	s1,a4,8000312a <bread+0x86>
  panic("bget: no buffers");
    80003134:	00005517          	auipc	a0,0x5
    80003138:	40c50513          	addi	a0,a0,1036 # 80008540 <syscalls+0xd0>
    8000313c:	ffffd097          	auipc	ra,0xffffd
    80003140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
      b->dev = dev;
    80003144:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003148:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000314c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003150:	4785                	li	a5,1
    80003152:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003154:	0000d517          	auipc	a0,0xd
    80003158:	10450513          	addi	a0,a0,260 # 80010258 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b3c080e7          	jalr	-1220(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003164:	01048513          	addi	a0,s1,16
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	408080e7          	jalr	1032(ra) # 80004570 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003170:	409c                	lw	a5,0(s1)
    80003172:	cb89                	beqz	a5,80003184 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003174:	8526                	mv	a0,s1
    80003176:	70a2                	ld	ra,40(sp)
    80003178:	7402                	ld	s0,32(sp)
    8000317a:	64e2                	ld	s1,24(sp)
    8000317c:	6942                	ld	s2,16(sp)
    8000317e:	69a2                	ld	s3,8(sp)
    80003180:	6145                	addi	sp,sp,48
    80003182:	8082                	ret
    virtio_disk_rw(b, 0);
    80003184:	4581                	li	a1,0
    80003186:	8526                	mv	a0,s1
    80003188:	00003097          	auipc	ra,0x3
    8000318c:	f0e080e7          	jalr	-242(ra) # 80006096 <virtio_disk_rw>
    b->valid = 1;
    80003190:	4785                	li	a5,1
    80003192:	c09c                	sw	a5,0(s1)
  return b;
    80003194:	b7c5                	j	80003174 <bread+0xd0>

0000000080003196 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	1000                	addi	s0,sp,32
    800031a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031a2:	0541                	addi	a0,a0,16
    800031a4:	00001097          	auipc	ra,0x1
    800031a8:	466080e7          	jalr	1126(ra) # 8000460a <holdingsleep>
    800031ac:	cd01                	beqz	a0,800031c4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031ae:	4585                	li	a1,1
    800031b0:	8526                	mv	a0,s1
    800031b2:	00003097          	auipc	ra,0x3
    800031b6:	ee4080e7          	jalr	-284(ra) # 80006096 <virtio_disk_rw>
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret
    panic("bwrite");
    800031c4:	00005517          	auipc	a0,0x5
    800031c8:	39450513          	addi	a0,a0,916 # 80008558 <syscalls+0xe8>
    800031cc:	ffffd097          	auipc	ra,0xffffd
    800031d0:	372080e7          	jalr	882(ra) # 8000053e <panic>

00000000800031d4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	e04a                	sd	s2,0(sp)
    800031de:	1000                	addi	s0,sp,32
    800031e0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031e2:	01050913          	addi	s2,a0,16
    800031e6:	854a                	mv	a0,s2
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	422080e7          	jalr	1058(ra) # 8000460a <holdingsleep>
    800031f0:	c92d                	beqz	a0,80003262 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031f2:	854a                	mv	a0,s2
    800031f4:	00001097          	auipc	ra,0x1
    800031f8:	3d2080e7          	jalr	978(ra) # 800045c6 <releasesleep>

  acquire(&bcache.lock);
    800031fc:	0000d517          	auipc	a0,0xd
    80003200:	05c50513          	addi	a0,a0,92 # 80010258 <bcache>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	9e0080e7          	jalr	-1568(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000320c:	40bc                	lw	a5,64(s1)
    8000320e:	37fd                	addiw	a5,a5,-1
    80003210:	0007871b          	sext.w	a4,a5
    80003214:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003216:	eb05                	bnez	a4,80003246 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003218:	68bc                	ld	a5,80(s1)
    8000321a:	64b8                	ld	a4,72(s1)
    8000321c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000321e:	64bc                	ld	a5,72(s1)
    80003220:	68b8                	ld	a4,80(s1)
    80003222:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003224:	00015797          	auipc	a5,0x15
    80003228:	03478793          	addi	a5,a5,52 # 80018258 <bcache+0x8000>
    8000322c:	2b87b703          	ld	a4,696(a5)
    80003230:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003232:	00015717          	auipc	a4,0x15
    80003236:	28e70713          	addi	a4,a4,654 # 800184c0 <bcache+0x8268>
    8000323a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000323c:	2b87b703          	ld	a4,696(a5)
    80003240:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003242:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003246:	0000d517          	auipc	a0,0xd
    8000324a:	01250513          	addi	a0,a0,18 # 80010258 <bcache>
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	a4a080e7          	jalr	-1462(ra) # 80000c98 <release>
}
    80003256:	60e2                	ld	ra,24(sp)
    80003258:	6442                	ld	s0,16(sp)
    8000325a:	64a2                	ld	s1,8(sp)
    8000325c:	6902                	ld	s2,0(sp)
    8000325e:	6105                	addi	sp,sp,32
    80003260:	8082                	ret
    panic("brelse");
    80003262:	00005517          	auipc	a0,0x5
    80003266:	2fe50513          	addi	a0,a0,766 # 80008560 <syscalls+0xf0>
    8000326a:	ffffd097          	auipc	ra,0xffffd
    8000326e:	2d4080e7          	jalr	724(ra) # 8000053e <panic>

0000000080003272 <bpin>:

void
bpin(struct buf *b) {
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000327e:	0000d517          	auipc	a0,0xd
    80003282:	fda50513          	addi	a0,a0,-38 # 80010258 <bcache>
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	95e080e7          	jalr	-1698(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000328e:	40bc                	lw	a5,64(s1)
    80003290:	2785                	addiw	a5,a5,1
    80003292:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003294:	0000d517          	auipc	a0,0xd
    80003298:	fc450513          	addi	a0,a0,-60 # 80010258 <bcache>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	9fc080e7          	jalr	-1540(ra) # 80000c98 <release>
}
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	64a2                	ld	s1,8(sp)
    800032aa:	6105                	addi	sp,sp,32
    800032ac:	8082                	ret

00000000800032ae <bunpin>:

void
bunpin(struct buf *b) {
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	e426                	sd	s1,8(sp)
    800032b6:	1000                	addi	s0,sp,32
    800032b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ba:	0000d517          	auipc	a0,0xd
    800032be:	f9e50513          	addi	a0,a0,-98 # 80010258 <bcache>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	922080e7          	jalr	-1758(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032ca:	40bc                	lw	a5,64(s1)
    800032cc:	37fd                	addiw	a5,a5,-1
    800032ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032d0:	0000d517          	auipc	a0,0xd
    800032d4:	f8850513          	addi	a0,a0,-120 # 80010258 <bcache>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
}
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	e04a                	sd	s2,0(sp)
    800032f4:	1000                	addi	s0,sp,32
    800032f6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032f8:	00d5d59b          	srliw	a1,a1,0xd
    800032fc:	00015797          	auipc	a5,0x15
    80003300:	6387a783          	lw	a5,1592(a5) # 80018934 <sb+0x1c>
    80003304:	9dbd                	addw	a1,a1,a5
    80003306:	00000097          	auipc	ra,0x0
    8000330a:	d9e080e7          	jalr	-610(ra) # 800030a4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000330e:	0074f713          	andi	a4,s1,7
    80003312:	4785                	li	a5,1
    80003314:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003318:	14ce                	slli	s1,s1,0x33
    8000331a:	90d9                	srli	s1,s1,0x36
    8000331c:	00950733          	add	a4,a0,s1
    80003320:	05874703          	lbu	a4,88(a4)
    80003324:	00e7f6b3          	and	a3,a5,a4
    80003328:	c69d                	beqz	a3,80003356 <bfree+0x6c>
    8000332a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000332c:	94aa                	add	s1,s1,a0
    8000332e:	fff7c793          	not	a5,a5
    80003332:	8ff9                	and	a5,a5,a4
    80003334:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003338:	00001097          	auipc	ra,0x1
    8000333c:	118080e7          	jalr	280(ra) # 80004450 <log_write>
  brelse(bp);
    80003340:	854a                	mv	a0,s2
    80003342:	00000097          	auipc	ra,0x0
    80003346:	e92080e7          	jalr	-366(ra) # 800031d4 <brelse>
}
    8000334a:	60e2                	ld	ra,24(sp)
    8000334c:	6442                	ld	s0,16(sp)
    8000334e:	64a2                	ld	s1,8(sp)
    80003350:	6902                	ld	s2,0(sp)
    80003352:	6105                	addi	sp,sp,32
    80003354:	8082                	ret
    panic("freeing free block");
    80003356:	00005517          	auipc	a0,0x5
    8000335a:	21250513          	addi	a0,a0,530 # 80008568 <syscalls+0xf8>
    8000335e:	ffffd097          	auipc	ra,0xffffd
    80003362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>

0000000080003366 <balloc>:
{
    80003366:	711d                	addi	sp,sp,-96
    80003368:	ec86                	sd	ra,88(sp)
    8000336a:	e8a2                	sd	s0,80(sp)
    8000336c:	e4a6                	sd	s1,72(sp)
    8000336e:	e0ca                	sd	s2,64(sp)
    80003370:	fc4e                	sd	s3,56(sp)
    80003372:	f852                	sd	s4,48(sp)
    80003374:	f456                	sd	s5,40(sp)
    80003376:	f05a                	sd	s6,32(sp)
    80003378:	ec5e                	sd	s7,24(sp)
    8000337a:	e862                	sd	s8,16(sp)
    8000337c:	e466                	sd	s9,8(sp)
    8000337e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003380:	00015797          	auipc	a5,0x15
    80003384:	59c7a783          	lw	a5,1436(a5) # 8001891c <sb+0x4>
    80003388:	cbd1                	beqz	a5,8000341c <balloc+0xb6>
    8000338a:	8baa                	mv	s7,a0
    8000338c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000338e:	00015b17          	auipc	s6,0x15
    80003392:	58ab0b13          	addi	s6,s6,1418 # 80018918 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003396:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003398:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000339a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000339c:	6c89                	lui	s9,0x2
    8000339e:	a831                	j	800033ba <balloc+0x54>
    brelse(bp);
    800033a0:	854a                	mv	a0,s2
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	e32080e7          	jalr	-462(ra) # 800031d4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033aa:	015c87bb          	addw	a5,s9,s5
    800033ae:	00078a9b          	sext.w	s5,a5
    800033b2:	004b2703          	lw	a4,4(s6)
    800033b6:	06eaf363          	bgeu	s5,a4,8000341c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033ba:	41fad79b          	sraiw	a5,s5,0x1f
    800033be:	0137d79b          	srliw	a5,a5,0x13
    800033c2:	015787bb          	addw	a5,a5,s5
    800033c6:	40d7d79b          	sraiw	a5,a5,0xd
    800033ca:	01cb2583          	lw	a1,28(s6)
    800033ce:	9dbd                	addw	a1,a1,a5
    800033d0:	855e                	mv	a0,s7
    800033d2:	00000097          	auipc	ra,0x0
    800033d6:	cd2080e7          	jalr	-814(ra) # 800030a4 <bread>
    800033da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033dc:	004b2503          	lw	a0,4(s6)
    800033e0:	000a849b          	sext.w	s1,s5
    800033e4:	8662                	mv	a2,s8
    800033e6:	faa4fde3          	bgeu	s1,a0,800033a0 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033ea:	41f6579b          	sraiw	a5,a2,0x1f
    800033ee:	01d7d69b          	srliw	a3,a5,0x1d
    800033f2:	00c6873b          	addw	a4,a3,a2
    800033f6:	00777793          	andi	a5,a4,7
    800033fa:	9f95                	subw	a5,a5,a3
    800033fc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003400:	4037571b          	sraiw	a4,a4,0x3
    80003404:	00e906b3          	add	a3,s2,a4
    80003408:	0586c683          	lbu	a3,88(a3)
    8000340c:	00d7f5b3          	and	a1,a5,a3
    80003410:	cd91                	beqz	a1,8000342c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003412:	2605                	addiw	a2,a2,1
    80003414:	2485                	addiw	s1,s1,1
    80003416:	fd4618e3          	bne	a2,s4,800033e6 <balloc+0x80>
    8000341a:	b759                	j	800033a0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000341c:	00005517          	auipc	a0,0x5
    80003420:	16450513          	addi	a0,a0,356 # 80008580 <syscalls+0x110>
    80003424:	ffffd097          	auipc	ra,0xffffd
    80003428:	11a080e7          	jalr	282(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000342c:	974a                	add	a4,a4,s2
    8000342e:	8fd5                	or	a5,a5,a3
    80003430:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003434:	854a                	mv	a0,s2
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	01a080e7          	jalr	26(ra) # 80004450 <log_write>
        brelse(bp);
    8000343e:	854a                	mv	a0,s2
    80003440:	00000097          	auipc	ra,0x0
    80003444:	d94080e7          	jalr	-620(ra) # 800031d4 <brelse>
  bp = bread(dev, bno);
    80003448:	85a6                	mv	a1,s1
    8000344a:	855e                	mv	a0,s7
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	c58080e7          	jalr	-936(ra) # 800030a4 <bread>
    80003454:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003456:	40000613          	li	a2,1024
    8000345a:	4581                	li	a1,0
    8000345c:	05850513          	addi	a0,a0,88
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	880080e7          	jalr	-1920(ra) # 80000ce0 <memset>
  log_write(bp);
    80003468:	854a                	mv	a0,s2
    8000346a:	00001097          	auipc	ra,0x1
    8000346e:	fe6080e7          	jalr	-26(ra) # 80004450 <log_write>
  brelse(bp);
    80003472:	854a                	mv	a0,s2
    80003474:	00000097          	auipc	ra,0x0
    80003478:	d60080e7          	jalr	-672(ra) # 800031d4 <brelse>
}
    8000347c:	8526                	mv	a0,s1
    8000347e:	60e6                	ld	ra,88(sp)
    80003480:	6446                	ld	s0,80(sp)
    80003482:	64a6                	ld	s1,72(sp)
    80003484:	6906                	ld	s2,64(sp)
    80003486:	79e2                	ld	s3,56(sp)
    80003488:	7a42                	ld	s4,48(sp)
    8000348a:	7aa2                	ld	s5,40(sp)
    8000348c:	7b02                	ld	s6,32(sp)
    8000348e:	6be2                	ld	s7,24(sp)
    80003490:	6c42                	ld	s8,16(sp)
    80003492:	6ca2                	ld	s9,8(sp)
    80003494:	6125                	addi	sp,sp,96
    80003496:	8082                	ret

0000000080003498 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003498:	7179                	addi	sp,sp,-48
    8000349a:	f406                	sd	ra,40(sp)
    8000349c:	f022                	sd	s0,32(sp)
    8000349e:	ec26                	sd	s1,24(sp)
    800034a0:	e84a                	sd	s2,16(sp)
    800034a2:	e44e                	sd	s3,8(sp)
    800034a4:	e052                	sd	s4,0(sp)
    800034a6:	1800                	addi	s0,sp,48
    800034a8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034aa:	47ad                	li	a5,11
    800034ac:	04b7fe63          	bgeu	a5,a1,80003508 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034b0:	ff45849b          	addiw	s1,a1,-12
    800034b4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034b8:	0ff00793          	li	a5,255
    800034bc:	0ae7e363          	bltu	a5,a4,80003562 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034c0:	08052583          	lw	a1,128(a0)
    800034c4:	c5ad                	beqz	a1,8000352e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034c6:	00092503          	lw	a0,0(s2)
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	bda080e7          	jalr	-1062(ra) # 800030a4 <bread>
    800034d2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034d4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034d8:	02049593          	slli	a1,s1,0x20
    800034dc:	9181                	srli	a1,a1,0x20
    800034de:	058a                	slli	a1,a1,0x2
    800034e0:	00b784b3          	add	s1,a5,a1
    800034e4:	0004a983          	lw	s3,0(s1)
    800034e8:	04098d63          	beqz	s3,80003542 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034ec:	8552                	mv	a0,s4
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	ce6080e7          	jalr	-794(ra) # 800031d4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034f6:	854e                	mv	a0,s3
    800034f8:	70a2                	ld	ra,40(sp)
    800034fa:	7402                	ld	s0,32(sp)
    800034fc:	64e2                	ld	s1,24(sp)
    800034fe:	6942                	ld	s2,16(sp)
    80003500:	69a2                	ld	s3,8(sp)
    80003502:	6a02                	ld	s4,0(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003508:	02059493          	slli	s1,a1,0x20
    8000350c:	9081                	srli	s1,s1,0x20
    8000350e:	048a                	slli	s1,s1,0x2
    80003510:	94aa                	add	s1,s1,a0
    80003512:	0504a983          	lw	s3,80(s1)
    80003516:	fe0990e3          	bnez	s3,800034f6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000351a:	4108                	lw	a0,0(a0)
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	e4a080e7          	jalr	-438(ra) # 80003366 <balloc>
    80003524:	0005099b          	sext.w	s3,a0
    80003528:	0534a823          	sw	s3,80(s1)
    8000352c:	b7e9                	j	800034f6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000352e:	4108                	lw	a0,0(a0)
    80003530:	00000097          	auipc	ra,0x0
    80003534:	e36080e7          	jalr	-458(ra) # 80003366 <balloc>
    80003538:	0005059b          	sext.w	a1,a0
    8000353c:	08b92023          	sw	a1,128(s2)
    80003540:	b759                	j	800034c6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003542:	00092503          	lw	a0,0(s2)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e20080e7          	jalr	-480(ra) # 80003366 <balloc>
    8000354e:	0005099b          	sext.w	s3,a0
    80003552:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003556:	8552                	mv	a0,s4
    80003558:	00001097          	auipc	ra,0x1
    8000355c:	ef8080e7          	jalr	-264(ra) # 80004450 <log_write>
    80003560:	b771                	j	800034ec <bmap+0x54>
  panic("bmap: out of range");
    80003562:	00005517          	auipc	a0,0x5
    80003566:	03650513          	addi	a0,a0,54 # 80008598 <syscalls+0x128>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>

0000000080003572 <iget>:
{
    80003572:	7179                	addi	sp,sp,-48
    80003574:	f406                	sd	ra,40(sp)
    80003576:	f022                	sd	s0,32(sp)
    80003578:	ec26                	sd	s1,24(sp)
    8000357a:	e84a                	sd	s2,16(sp)
    8000357c:	e44e                	sd	s3,8(sp)
    8000357e:	e052                	sd	s4,0(sp)
    80003580:	1800                	addi	s0,sp,48
    80003582:	89aa                	mv	s3,a0
    80003584:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003586:	00015517          	auipc	a0,0x15
    8000358a:	3b250513          	addi	a0,a0,946 # 80018938 <itable>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	656080e7          	jalr	1622(ra) # 80000be4 <acquire>
  empty = 0;
    80003596:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003598:	00015497          	auipc	s1,0x15
    8000359c:	3b848493          	addi	s1,s1,952 # 80018950 <itable+0x18>
    800035a0:	00017697          	auipc	a3,0x17
    800035a4:	e4068693          	addi	a3,a3,-448 # 8001a3e0 <log>
    800035a8:	a039                	j	800035b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035aa:	02090b63          	beqz	s2,800035e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ae:	08848493          	addi	s1,s1,136
    800035b2:	02d48a63          	beq	s1,a3,800035e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035b6:	449c                	lw	a5,8(s1)
    800035b8:	fef059e3          	blez	a5,800035aa <iget+0x38>
    800035bc:	4098                	lw	a4,0(s1)
    800035be:	ff3716e3          	bne	a4,s3,800035aa <iget+0x38>
    800035c2:	40d8                	lw	a4,4(s1)
    800035c4:	ff4713e3          	bne	a4,s4,800035aa <iget+0x38>
      ip->ref++;
    800035c8:	2785                	addiw	a5,a5,1
    800035ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035cc:	00015517          	auipc	a0,0x15
    800035d0:	36c50513          	addi	a0,a0,876 # 80018938 <itable>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
      return ip;
    800035dc:	8926                	mv	s2,s1
    800035de:	a03d                	j	8000360c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e0:	f7f9                	bnez	a5,800035ae <iget+0x3c>
    800035e2:	8926                	mv	s2,s1
    800035e4:	b7e9                	j	800035ae <iget+0x3c>
  if(empty == 0)
    800035e6:	02090c63          	beqz	s2,8000361e <iget+0xac>
  ip->dev = dev;
    800035ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035f2:	4785                	li	a5,1
    800035f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035fc:	00015517          	auipc	a0,0x15
    80003600:	33c50513          	addi	a0,a0,828 # 80018938 <itable>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
}
    8000360c:	854a                	mv	a0,s2
    8000360e:	70a2                	ld	ra,40(sp)
    80003610:	7402                	ld	s0,32(sp)
    80003612:	64e2                	ld	s1,24(sp)
    80003614:	6942                	ld	s2,16(sp)
    80003616:	69a2                	ld	s3,8(sp)
    80003618:	6a02                	ld	s4,0(sp)
    8000361a:	6145                	addi	sp,sp,48
    8000361c:	8082                	ret
    panic("iget: no inodes");
    8000361e:	00005517          	auipc	a0,0x5
    80003622:	f9250513          	addi	a0,a0,-110 # 800085b0 <syscalls+0x140>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	f18080e7          	jalr	-232(ra) # 8000053e <panic>

000000008000362e <fsinit>:
fsinit(int dev) {
    8000362e:	7179                	addi	sp,sp,-48
    80003630:	f406                	sd	ra,40(sp)
    80003632:	f022                	sd	s0,32(sp)
    80003634:	ec26                	sd	s1,24(sp)
    80003636:	e84a                	sd	s2,16(sp)
    80003638:	e44e                	sd	s3,8(sp)
    8000363a:	1800                	addi	s0,sp,48
    8000363c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000363e:	4585                	li	a1,1
    80003640:	00000097          	auipc	ra,0x0
    80003644:	a64080e7          	jalr	-1436(ra) # 800030a4 <bread>
    80003648:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000364a:	00015997          	auipc	s3,0x15
    8000364e:	2ce98993          	addi	s3,s3,718 # 80018918 <sb>
    80003652:	02000613          	li	a2,32
    80003656:	05850593          	addi	a1,a0,88
    8000365a:	854e                	mv	a0,s3
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	6e4080e7          	jalr	1764(ra) # 80000d40 <memmove>
  brelse(bp);
    80003664:	8526                	mv	a0,s1
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	b6e080e7          	jalr	-1170(ra) # 800031d4 <brelse>
  if(sb.magic != FSMAGIC)
    8000366e:	0009a703          	lw	a4,0(s3)
    80003672:	102037b7          	lui	a5,0x10203
    80003676:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000367a:	02f71263          	bne	a4,a5,8000369e <fsinit+0x70>
  initlog(dev, &sb);
    8000367e:	00015597          	auipc	a1,0x15
    80003682:	29a58593          	addi	a1,a1,666 # 80018918 <sb>
    80003686:	854a                	mv	a0,s2
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	b4c080e7          	jalr	-1204(ra) # 800041d4 <initlog>
}
    80003690:	70a2                	ld	ra,40(sp)
    80003692:	7402                	ld	s0,32(sp)
    80003694:	64e2                	ld	s1,24(sp)
    80003696:	6942                	ld	s2,16(sp)
    80003698:	69a2                	ld	s3,8(sp)
    8000369a:	6145                	addi	sp,sp,48
    8000369c:	8082                	ret
    panic("invalid file system");
    8000369e:	00005517          	auipc	a0,0x5
    800036a2:	f2250513          	addi	a0,a0,-222 # 800085c0 <syscalls+0x150>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	e98080e7          	jalr	-360(ra) # 8000053e <panic>

00000000800036ae <iinit>:
{
    800036ae:	7179                	addi	sp,sp,-48
    800036b0:	f406                	sd	ra,40(sp)
    800036b2:	f022                	sd	s0,32(sp)
    800036b4:	ec26                	sd	s1,24(sp)
    800036b6:	e84a                	sd	s2,16(sp)
    800036b8:	e44e                	sd	s3,8(sp)
    800036ba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036bc:	00005597          	auipc	a1,0x5
    800036c0:	f1c58593          	addi	a1,a1,-228 # 800085d8 <syscalls+0x168>
    800036c4:	00015517          	auipc	a0,0x15
    800036c8:	27450513          	addi	a0,a0,628 # 80018938 <itable>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	488080e7          	jalr	1160(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036d4:	00015497          	auipc	s1,0x15
    800036d8:	28c48493          	addi	s1,s1,652 # 80018960 <itable+0x28>
    800036dc:	00017997          	auipc	s3,0x17
    800036e0:	d1498993          	addi	s3,s3,-748 # 8001a3f0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036e4:	00005917          	auipc	s2,0x5
    800036e8:	efc90913          	addi	s2,s2,-260 # 800085e0 <syscalls+0x170>
    800036ec:	85ca                	mv	a1,s2
    800036ee:	8526                	mv	a0,s1
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	e46080e7          	jalr	-442(ra) # 80004536 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036f8:	08848493          	addi	s1,s1,136
    800036fc:	ff3498e3          	bne	s1,s3,800036ec <iinit+0x3e>
}
    80003700:	70a2                	ld	ra,40(sp)
    80003702:	7402                	ld	s0,32(sp)
    80003704:	64e2                	ld	s1,24(sp)
    80003706:	6942                	ld	s2,16(sp)
    80003708:	69a2                	ld	s3,8(sp)
    8000370a:	6145                	addi	sp,sp,48
    8000370c:	8082                	ret

000000008000370e <ialloc>:
{
    8000370e:	715d                	addi	sp,sp,-80
    80003710:	e486                	sd	ra,72(sp)
    80003712:	e0a2                	sd	s0,64(sp)
    80003714:	fc26                	sd	s1,56(sp)
    80003716:	f84a                	sd	s2,48(sp)
    80003718:	f44e                	sd	s3,40(sp)
    8000371a:	f052                	sd	s4,32(sp)
    8000371c:	ec56                	sd	s5,24(sp)
    8000371e:	e85a                	sd	s6,16(sp)
    80003720:	e45e                	sd	s7,8(sp)
    80003722:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003724:	00015717          	auipc	a4,0x15
    80003728:	20072703          	lw	a4,512(a4) # 80018924 <sb+0xc>
    8000372c:	4785                	li	a5,1
    8000372e:	04e7fa63          	bgeu	a5,a4,80003782 <ialloc+0x74>
    80003732:	8aaa                	mv	s5,a0
    80003734:	8bae                	mv	s7,a1
    80003736:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003738:	00015a17          	auipc	s4,0x15
    8000373c:	1e0a0a13          	addi	s4,s4,480 # 80018918 <sb>
    80003740:	00048b1b          	sext.w	s6,s1
    80003744:	0044d593          	srli	a1,s1,0x4
    80003748:	018a2783          	lw	a5,24(s4)
    8000374c:	9dbd                	addw	a1,a1,a5
    8000374e:	8556                	mv	a0,s5
    80003750:	00000097          	auipc	ra,0x0
    80003754:	954080e7          	jalr	-1708(ra) # 800030a4 <bread>
    80003758:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000375a:	05850993          	addi	s3,a0,88
    8000375e:	00f4f793          	andi	a5,s1,15
    80003762:	079a                	slli	a5,a5,0x6
    80003764:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003766:	00099783          	lh	a5,0(s3)
    8000376a:	c785                	beqz	a5,80003792 <ialloc+0x84>
    brelse(bp);
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	a68080e7          	jalr	-1432(ra) # 800031d4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003774:	0485                	addi	s1,s1,1
    80003776:	00ca2703          	lw	a4,12(s4)
    8000377a:	0004879b          	sext.w	a5,s1
    8000377e:	fce7e1e3          	bltu	a5,a4,80003740 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003782:	00005517          	auipc	a0,0x5
    80003786:	e6650513          	addi	a0,a0,-410 # 800085e8 <syscalls+0x178>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	db4080e7          	jalr	-588(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003792:	04000613          	li	a2,64
    80003796:	4581                	li	a1,0
    80003798:	854e                	mv	a0,s3
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	546080e7          	jalr	1350(ra) # 80000ce0 <memset>
      dip->type = type;
    800037a2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037a6:	854a                	mv	a0,s2
    800037a8:	00001097          	auipc	ra,0x1
    800037ac:	ca8080e7          	jalr	-856(ra) # 80004450 <log_write>
      brelse(bp);
    800037b0:	854a                	mv	a0,s2
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	a22080e7          	jalr	-1502(ra) # 800031d4 <brelse>
      return iget(dev, inum);
    800037ba:	85da                	mv	a1,s6
    800037bc:	8556                	mv	a0,s5
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	db4080e7          	jalr	-588(ra) # 80003572 <iget>
}
    800037c6:	60a6                	ld	ra,72(sp)
    800037c8:	6406                	ld	s0,64(sp)
    800037ca:	74e2                	ld	s1,56(sp)
    800037cc:	7942                	ld	s2,48(sp)
    800037ce:	79a2                	ld	s3,40(sp)
    800037d0:	7a02                	ld	s4,32(sp)
    800037d2:	6ae2                	ld	s5,24(sp)
    800037d4:	6b42                	ld	s6,16(sp)
    800037d6:	6ba2                	ld	s7,8(sp)
    800037d8:	6161                	addi	sp,sp,80
    800037da:	8082                	ret

00000000800037dc <iupdate>:
{
    800037dc:	1101                	addi	sp,sp,-32
    800037de:	ec06                	sd	ra,24(sp)
    800037e0:	e822                	sd	s0,16(sp)
    800037e2:	e426                	sd	s1,8(sp)
    800037e4:	e04a                	sd	s2,0(sp)
    800037e6:	1000                	addi	s0,sp,32
    800037e8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ea:	415c                	lw	a5,4(a0)
    800037ec:	0047d79b          	srliw	a5,a5,0x4
    800037f0:	00015597          	auipc	a1,0x15
    800037f4:	1405a583          	lw	a1,320(a1) # 80018930 <sb+0x18>
    800037f8:	9dbd                	addw	a1,a1,a5
    800037fa:	4108                	lw	a0,0(a0)
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	8a8080e7          	jalr	-1880(ra) # 800030a4 <bread>
    80003804:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003806:	05850793          	addi	a5,a0,88
    8000380a:	40c8                	lw	a0,4(s1)
    8000380c:	893d                	andi	a0,a0,15
    8000380e:	051a                	slli	a0,a0,0x6
    80003810:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003812:	04449703          	lh	a4,68(s1)
    80003816:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000381a:	04649703          	lh	a4,70(s1)
    8000381e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003822:	04849703          	lh	a4,72(s1)
    80003826:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000382a:	04a49703          	lh	a4,74(s1)
    8000382e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003832:	44f8                	lw	a4,76(s1)
    80003834:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003836:	03400613          	li	a2,52
    8000383a:	05048593          	addi	a1,s1,80
    8000383e:	0531                	addi	a0,a0,12
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	500080e7          	jalr	1280(ra) # 80000d40 <memmove>
  log_write(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00001097          	auipc	ra,0x1
    8000384e:	c06080e7          	jalr	-1018(ra) # 80004450 <log_write>
  brelse(bp);
    80003852:	854a                	mv	a0,s2
    80003854:	00000097          	auipc	ra,0x0
    80003858:	980080e7          	jalr	-1664(ra) # 800031d4 <brelse>
}
    8000385c:	60e2                	ld	ra,24(sp)
    8000385e:	6442                	ld	s0,16(sp)
    80003860:	64a2                	ld	s1,8(sp)
    80003862:	6902                	ld	s2,0(sp)
    80003864:	6105                	addi	sp,sp,32
    80003866:	8082                	ret

0000000080003868 <idup>:
{
    80003868:	1101                	addi	sp,sp,-32
    8000386a:	ec06                	sd	ra,24(sp)
    8000386c:	e822                	sd	s0,16(sp)
    8000386e:	e426                	sd	s1,8(sp)
    80003870:	1000                	addi	s0,sp,32
    80003872:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003874:	00015517          	auipc	a0,0x15
    80003878:	0c450513          	addi	a0,a0,196 # 80018938 <itable>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	368080e7          	jalr	872(ra) # 80000be4 <acquire>
  ip->ref++;
    80003884:	449c                	lw	a5,8(s1)
    80003886:	2785                	addiw	a5,a5,1
    80003888:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000388a:	00015517          	auipc	a0,0x15
    8000388e:	0ae50513          	addi	a0,a0,174 # 80018938 <itable>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000389a:	8526                	mv	a0,s1
    8000389c:	60e2                	ld	ra,24(sp)
    8000389e:	6442                	ld	s0,16(sp)
    800038a0:	64a2                	ld	s1,8(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret

00000000800038a6 <ilock>:
{
    800038a6:	1101                	addi	sp,sp,-32
    800038a8:	ec06                	sd	ra,24(sp)
    800038aa:	e822                	sd	s0,16(sp)
    800038ac:	e426                	sd	s1,8(sp)
    800038ae:	e04a                	sd	s2,0(sp)
    800038b0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038b2:	c115                	beqz	a0,800038d6 <ilock+0x30>
    800038b4:	84aa                	mv	s1,a0
    800038b6:	451c                	lw	a5,8(a0)
    800038b8:	00f05f63          	blez	a5,800038d6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038bc:	0541                	addi	a0,a0,16
    800038be:	00001097          	auipc	ra,0x1
    800038c2:	cb2080e7          	jalr	-846(ra) # 80004570 <acquiresleep>
  if(ip->valid == 0){
    800038c6:	40bc                	lw	a5,64(s1)
    800038c8:	cf99                	beqz	a5,800038e6 <ilock+0x40>
}
    800038ca:	60e2                	ld	ra,24(sp)
    800038cc:	6442                	ld	s0,16(sp)
    800038ce:	64a2                	ld	s1,8(sp)
    800038d0:	6902                	ld	s2,0(sp)
    800038d2:	6105                	addi	sp,sp,32
    800038d4:	8082                	ret
    panic("ilock");
    800038d6:	00005517          	auipc	a0,0x5
    800038da:	d2a50513          	addi	a0,a0,-726 # 80008600 <syscalls+0x190>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	c60080e7          	jalr	-928(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038e6:	40dc                	lw	a5,4(s1)
    800038e8:	0047d79b          	srliw	a5,a5,0x4
    800038ec:	00015597          	auipc	a1,0x15
    800038f0:	0445a583          	lw	a1,68(a1) # 80018930 <sb+0x18>
    800038f4:	9dbd                	addw	a1,a1,a5
    800038f6:	4088                	lw	a0,0(s1)
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	7ac080e7          	jalr	1964(ra) # 800030a4 <bread>
    80003900:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003902:	05850593          	addi	a1,a0,88
    80003906:	40dc                	lw	a5,4(s1)
    80003908:	8bbd                	andi	a5,a5,15
    8000390a:	079a                	slli	a5,a5,0x6
    8000390c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000390e:	00059783          	lh	a5,0(a1)
    80003912:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003916:	00259783          	lh	a5,2(a1)
    8000391a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000391e:	00459783          	lh	a5,4(a1)
    80003922:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003926:	00659783          	lh	a5,6(a1)
    8000392a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000392e:	459c                	lw	a5,8(a1)
    80003930:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003932:	03400613          	li	a2,52
    80003936:	05b1                	addi	a1,a1,12
    80003938:	05048513          	addi	a0,s1,80
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	404080e7          	jalr	1028(ra) # 80000d40 <memmove>
    brelse(bp);
    80003944:	854a                	mv	a0,s2
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	88e080e7          	jalr	-1906(ra) # 800031d4 <brelse>
    ip->valid = 1;
    8000394e:	4785                	li	a5,1
    80003950:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003952:	04449783          	lh	a5,68(s1)
    80003956:	fbb5                	bnez	a5,800038ca <ilock+0x24>
      panic("ilock: no type");
    80003958:	00005517          	auipc	a0,0x5
    8000395c:	cb050513          	addi	a0,a0,-848 # 80008608 <syscalls+0x198>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>

0000000080003968 <iunlock>:
{
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	e04a                	sd	s2,0(sp)
    80003972:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003974:	c905                	beqz	a0,800039a4 <iunlock+0x3c>
    80003976:	84aa                	mv	s1,a0
    80003978:	01050913          	addi	s2,a0,16
    8000397c:	854a                	mv	a0,s2
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	c8c080e7          	jalr	-884(ra) # 8000460a <holdingsleep>
    80003986:	cd19                	beqz	a0,800039a4 <iunlock+0x3c>
    80003988:	449c                	lw	a5,8(s1)
    8000398a:	00f05d63          	blez	a5,800039a4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000398e:	854a                	mv	a0,s2
    80003990:	00001097          	auipc	ra,0x1
    80003994:	c36080e7          	jalr	-970(ra) # 800045c6 <releasesleep>
}
    80003998:	60e2                	ld	ra,24(sp)
    8000399a:	6442                	ld	s0,16(sp)
    8000399c:	64a2                	ld	s1,8(sp)
    8000399e:	6902                	ld	s2,0(sp)
    800039a0:	6105                	addi	sp,sp,32
    800039a2:	8082                	ret
    panic("iunlock");
    800039a4:	00005517          	auipc	a0,0x5
    800039a8:	c7450513          	addi	a0,a0,-908 # 80008618 <syscalls+0x1a8>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>

00000000800039b4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039b4:	7179                	addi	sp,sp,-48
    800039b6:	f406                	sd	ra,40(sp)
    800039b8:	f022                	sd	s0,32(sp)
    800039ba:	ec26                	sd	s1,24(sp)
    800039bc:	e84a                	sd	s2,16(sp)
    800039be:	e44e                	sd	s3,8(sp)
    800039c0:	e052                	sd	s4,0(sp)
    800039c2:	1800                	addi	s0,sp,48
    800039c4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039c6:	05050493          	addi	s1,a0,80
    800039ca:	08050913          	addi	s2,a0,128
    800039ce:	a021                	j	800039d6 <itrunc+0x22>
    800039d0:	0491                	addi	s1,s1,4
    800039d2:	01248d63          	beq	s1,s2,800039ec <itrunc+0x38>
    if(ip->addrs[i]){
    800039d6:	408c                	lw	a1,0(s1)
    800039d8:	dde5                	beqz	a1,800039d0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039da:	0009a503          	lw	a0,0(s3)
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	90c080e7          	jalr	-1780(ra) # 800032ea <bfree>
      ip->addrs[i] = 0;
    800039e6:	0004a023          	sw	zero,0(s1)
    800039ea:	b7dd                	j	800039d0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039ec:	0809a583          	lw	a1,128(s3)
    800039f0:	e185                	bnez	a1,80003a10 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039f2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039f6:	854e                	mv	a0,s3
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	de4080e7          	jalr	-540(ra) # 800037dc <iupdate>
}
    80003a00:	70a2                	ld	ra,40(sp)
    80003a02:	7402                	ld	s0,32(sp)
    80003a04:	64e2                	ld	s1,24(sp)
    80003a06:	6942                	ld	s2,16(sp)
    80003a08:	69a2                	ld	s3,8(sp)
    80003a0a:	6a02                	ld	s4,0(sp)
    80003a0c:	6145                	addi	sp,sp,48
    80003a0e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a10:	0009a503          	lw	a0,0(s3)
    80003a14:	fffff097          	auipc	ra,0xfffff
    80003a18:	690080e7          	jalr	1680(ra) # 800030a4 <bread>
    80003a1c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a1e:	05850493          	addi	s1,a0,88
    80003a22:	45850913          	addi	s2,a0,1112
    80003a26:	a811                	j	80003a3a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a28:	0009a503          	lw	a0,0(s3)
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	8be080e7          	jalr	-1858(ra) # 800032ea <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a34:	0491                	addi	s1,s1,4
    80003a36:	01248563          	beq	s1,s2,80003a40 <itrunc+0x8c>
      if(a[j])
    80003a3a:	408c                	lw	a1,0(s1)
    80003a3c:	dde5                	beqz	a1,80003a34 <itrunc+0x80>
    80003a3e:	b7ed                	j	80003a28 <itrunc+0x74>
    brelse(bp);
    80003a40:	8552                	mv	a0,s4
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	792080e7          	jalr	1938(ra) # 800031d4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a4a:	0809a583          	lw	a1,128(s3)
    80003a4e:	0009a503          	lw	a0,0(s3)
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	898080e7          	jalr	-1896(ra) # 800032ea <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a5a:	0809a023          	sw	zero,128(s3)
    80003a5e:	bf51                	j	800039f2 <itrunc+0x3e>

0000000080003a60 <iput>:
{
    80003a60:	1101                	addi	sp,sp,-32
    80003a62:	ec06                	sd	ra,24(sp)
    80003a64:	e822                	sd	s0,16(sp)
    80003a66:	e426                	sd	s1,8(sp)
    80003a68:	e04a                	sd	s2,0(sp)
    80003a6a:	1000                	addi	s0,sp,32
    80003a6c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a6e:	00015517          	auipc	a0,0x15
    80003a72:	eca50513          	addi	a0,a0,-310 # 80018938 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	16e080e7          	jalr	366(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a7e:	4498                	lw	a4,8(s1)
    80003a80:	4785                	li	a5,1
    80003a82:	02f70363          	beq	a4,a5,80003aa8 <iput+0x48>
  ip->ref--;
    80003a86:	449c                	lw	a5,8(s1)
    80003a88:	37fd                	addiw	a5,a5,-1
    80003a8a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a8c:	00015517          	auipc	a0,0x15
    80003a90:	eac50513          	addi	a0,a0,-340 # 80018938 <itable>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
}
    80003a9c:	60e2                	ld	ra,24(sp)
    80003a9e:	6442                	ld	s0,16(sp)
    80003aa0:	64a2                	ld	s1,8(sp)
    80003aa2:	6902                	ld	s2,0(sp)
    80003aa4:	6105                	addi	sp,sp,32
    80003aa6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa8:	40bc                	lw	a5,64(s1)
    80003aaa:	dff1                	beqz	a5,80003a86 <iput+0x26>
    80003aac:	04a49783          	lh	a5,74(s1)
    80003ab0:	fbf9                	bnez	a5,80003a86 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ab2:	01048913          	addi	s2,s1,16
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	00001097          	auipc	ra,0x1
    80003abc:	ab8080e7          	jalr	-1352(ra) # 80004570 <acquiresleep>
    release(&itable.lock);
    80003ac0:	00015517          	auipc	a0,0x15
    80003ac4:	e7850513          	addi	a0,a0,-392 # 80018938 <itable>
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	1d0080e7          	jalr	464(ra) # 80000c98 <release>
    itrunc(ip);
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	ee2080e7          	jalr	-286(ra) # 800039b4 <itrunc>
    ip->type = 0;
    80003ada:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	cfc080e7          	jalr	-772(ra) # 800037dc <iupdate>
    ip->valid = 0;
    80003ae8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003aec:	854a                	mv	a0,s2
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	ad8080e7          	jalr	-1320(ra) # 800045c6 <releasesleep>
    acquire(&itable.lock);
    80003af6:	00015517          	auipc	a0,0x15
    80003afa:	e4250513          	addi	a0,a0,-446 # 80018938 <itable>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	0e6080e7          	jalr	230(ra) # 80000be4 <acquire>
    80003b06:	b741                	j	80003a86 <iput+0x26>

0000000080003b08 <iunlockput>:
{
    80003b08:	1101                	addi	sp,sp,-32
    80003b0a:	ec06                	sd	ra,24(sp)
    80003b0c:	e822                	sd	s0,16(sp)
    80003b0e:	e426                	sd	s1,8(sp)
    80003b10:	1000                	addi	s0,sp,32
    80003b12:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	e54080e7          	jalr	-428(ra) # 80003968 <iunlock>
  iput(ip);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	f42080e7          	jalr	-190(ra) # 80003a60 <iput>
}
    80003b26:	60e2                	ld	ra,24(sp)
    80003b28:	6442                	ld	s0,16(sp)
    80003b2a:	64a2                	ld	s1,8(sp)
    80003b2c:	6105                	addi	sp,sp,32
    80003b2e:	8082                	ret

0000000080003b30 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b30:	1141                	addi	sp,sp,-16
    80003b32:	e422                	sd	s0,8(sp)
    80003b34:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b36:	411c                	lw	a5,0(a0)
    80003b38:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b3a:	415c                	lw	a5,4(a0)
    80003b3c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b3e:	04451783          	lh	a5,68(a0)
    80003b42:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b46:	04a51783          	lh	a5,74(a0)
    80003b4a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b4e:	04c56783          	lwu	a5,76(a0)
    80003b52:	e99c                	sd	a5,16(a1)
}
    80003b54:	6422                	ld	s0,8(sp)
    80003b56:	0141                	addi	sp,sp,16
    80003b58:	8082                	ret

0000000080003b5a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b5a:	457c                	lw	a5,76(a0)
    80003b5c:	0ed7e963          	bltu	a5,a3,80003c4e <readi+0xf4>
{
    80003b60:	7159                	addi	sp,sp,-112
    80003b62:	f486                	sd	ra,104(sp)
    80003b64:	f0a2                	sd	s0,96(sp)
    80003b66:	eca6                	sd	s1,88(sp)
    80003b68:	e8ca                	sd	s2,80(sp)
    80003b6a:	e4ce                	sd	s3,72(sp)
    80003b6c:	e0d2                	sd	s4,64(sp)
    80003b6e:	fc56                	sd	s5,56(sp)
    80003b70:	f85a                	sd	s6,48(sp)
    80003b72:	f45e                	sd	s7,40(sp)
    80003b74:	f062                	sd	s8,32(sp)
    80003b76:	ec66                	sd	s9,24(sp)
    80003b78:	e86a                	sd	s10,16(sp)
    80003b7a:	e46e                	sd	s11,8(sp)
    80003b7c:	1880                	addi	s0,sp,112
    80003b7e:	8baa                	mv	s7,a0
    80003b80:	8c2e                	mv	s8,a1
    80003b82:	8ab2                	mv	s5,a2
    80003b84:	84b6                	mv	s1,a3
    80003b86:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b88:	9f35                	addw	a4,a4,a3
    return 0;
    80003b8a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b8c:	0ad76063          	bltu	a4,a3,80003c2c <readi+0xd2>
  if(off + n > ip->size)
    80003b90:	00e7f463          	bgeu	a5,a4,80003b98 <readi+0x3e>
    n = ip->size - off;
    80003b94:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b98:	0a0b0963          	beqz	s6,80003c4a <readi+0xf0>
    80003b9c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ba2:	5cfd                	li	s9,-1
    80003ba4:	a82d                	j	80003bde <readi+0x84>
    80003ba6:	020a1d93          	slli	s11,s4,0x20
    80003baa:	020ddd93          	srli	s11,s11,0x20
    80003bae:	05890613          	addi	a2,s2,88
    80003bb2:	86ee                	mv	a3,s11
    80003bb4:	963a                	add	a2,a2,a4
    80003bb6:	85d6                	mv	a1,s5
    80003bb8:	8562                	mv	a0,s8
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	adc080e7          	jalr	-1316(ra) # 80002696 <either_copyout>
    80003bc2:	05950d63          	beq	a0,s9,80003c1c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	60c080e7          	jalr	1548(ra) # 800031d4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd0:	013a09bb          	addw	s3,s4,s3
    80003bd4:	009a04bb          	addw	s1,s4,s1
    80003bd8:	9aee                	add	s5,s5,s11
    80003bda:	0569f763          	bgeu	s3,s6,80003c28 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bde:	000ba903          	lw	s2,0(s7)
    80003be2:	00a4d59b          	srliw	a1,s1,0xa
    80003be6:	855e                	mv	a0,s7
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	8b0080e7          	jalr	-1872(ra) # 80003498 <bmap>
    80003bf0:	0005059b          	sext.w	a1,a0
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	4ae080e7          	jalr	1198(ra) # 800030a4 <bread>
    80003bfe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c00:	3ff4f713          	andi	a4,s1,1023
    80003c04:	40ed07bb          	subw	a5,s10,a4
    80003c08:	413b06bb          	subw	a3,s6,s3
    80003c0c:	8a3e                	mv	s4,a5
    80003c0e:	2781                	sext.w	a5,a5
    80003c10:	0006861b          	sext.w	a2,a3
    80003c14:	f8f679e3          	bgeu	a2,a5,80003ba6 <readi+0x4c>
    80003c18:	8a36                	mv	s4,a3
    80003c1a:	b771                	j	80003ba6 <readi+0x4c>
      brelse(bp);
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	5b6080e7          	jalr	1462(ra) # 800031d4 <brelse>
      tot = -1;
    80003c26:	59fd                	li	s3,-1
  }
  return tot;
    80003c28:	0009851b          	sext.w	a0,s3
}
    80003c2c:	70a6                	ld	ra,104(sp)
    80003c2e:	7406                	ld	s0,96(sp)
    80003c30:	64e6                	ld	s1,88(sp)
    80003c32:	6946                	ld	s2,80(sp)
    80003c34:	69a6                	ld	s3,72(sp)
    80003c36:	6a06                	ld	s4,64(sp)
    80003c38:	7ae2                	ld	s5,56(sp)
    80003c3a:	7b42                	ld	s6,48(sp)
    80003c3c:	7ba2                	ld	s7,40(sp)
    80003c3e:	7c02                	ld	s8,32(sp)
    80003c40:	6ce2                	ld	s9,24(sp)
    80003c42:	6d42                	ld	s10,16(sp)
    80003c44:	6da2                	ld	s11,8(sp)
    80003c46:	6165                	addi	sp,sp,112
    80003c48:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c4a:	89da                	mv	s3,s6
    80003c4c:	bff1                	j	80003c28 <readi+0xce>
    return 0;
    80003c4e:	4501                	li	a0,0
}
    80003c50:	8082                	ret

0000000080003c52 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c52:	457c                	lw	a5,76(a0)
    80003c54:	10d7e863          	bltu	a5,a3,80003d64 <writei+0x112>
{
    80003c58:	7159                	addi	sp,sp,-112
    80003c5a:	f486                	sd	ra,104(sp)
    80003c5c:	f0a2                	sd	s0,96(sp)
    80003c5e:	eca6                	sd	s1,88(sp)
    80003c60:	e8ca                	sd	s2,80(sp)
    80003c62:	e4ce                	sd	s3,72(sp)
    80003c64:	e0d2                	sd	s4,64(sp)
    80003c66:	fc56                	sd	s5,56(sp)
    80003c68:	f85a                	sd	s6,48(sp)
    80003c6a:	f45e                	sd	s7,40(sp)
    80003c6c:	f062                	sd	s8,32(sp)
    80003c6e:	ec66                	sd	s9,24(sp)
    80003c70:	e86a                	sd	s10,16(sp)
    80003c72:	e46e                	sd	s11,8(sp)
    80003c74:	1880                	addi	s0,sp,112
    80003c76:	8b2a                	mv	s6,a0
    80003c78:	8c2e                	mv	s8,a1
    80003c7a:	8ab2                	mv	s5,a2
    80003c7c:	8936                	mv	s2,a3
    80003c7e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c80:	00e687bb          	addw	a5,a3,a4
    80003c84:	0ed7e263          	bltu	a5,a3,80003d68 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c88:	00043737          	lui	a4,0x43
    80003c8c:	0ef76063          	bltu	a4,a5,80003d6c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c90:	0c0b8863          	beqz	s7,80003d60 <writei+0x10e>
    80003c94:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c96:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c9a:	5cfd                	li	s9,-1
    80003c9c:	a091                	j	80003ce0 <writei+0x8e>
    80003c9e:	02099d93          	slli	s11,s3,0x20
    80003ca2:	020ddd93          	srli	s11,s11,0x20
    80003ca6:	05848513          	addi	a0,s1,88
    80003caa:	86ee                	mv	a3,s11
    80003cac:	8656                	mv	a2,s5
    80003cae:	85e2                	mv	a1,s8
    80003cb0:	953a                	add	a0,a0,a4
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	a3a080e7          	jalr	-1478(ra) # 800026ec <either_copyin>
    80003cba:	07950263          	beq	a0,s9,80003d1e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	790080e7          	jalr	1936(ra) # 80004450 <log_write>
    brelse(bp);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	50a080e7          	jalr	1290(ra) # 800031d4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd2:	01498a3b          	addw	s4,s3,s4
    80003cd6:	0129893b          	addw	s2,s3,s2
    80003cda:	9aee                	add	s5,s5,s11
    80003cdc:	057a7663          	bgeu	s4,s7,80003d28 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ce0:	000b2483          	lw	s1,0(s6)
    80003ce4:	00a9559b          	srliw	a1,s2,0xa
    80003ce8:	855a                	mv	a0,s6
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	7ae080e7          	jalr	1966(ra) # 80003498 <bmap>
    80003cf2:	0005059b          	sext.w	a1,a0
    80003cf6:	8526                	mv	a0,s1
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	3ac080e7          	jalr	940(ra) # 800030a4 <bread>
    80003d00:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d02:	3ff97713          	andi	a4,s2,1023
    80003d06:	40ed07bb          	subw	a5,s10,a4
    80003d0a:	414b86bb          	subw	a3,s7,s4
    80003d0e:	89be                	mv	s3,a5
    80003d10:	2781                	sext.w	a5,a5
    80003d12:	0006861b          	sext.w	a2,a3
    80003d16:	f8f674e3          	bgeu	a2,a5,80003c9e <writei+0x4c>
    80003d1a:	89b6                	mv	s3,a3
    80003d1c:	b749                	j	80003c9e <writei+0x4c>
      brelse(bp);
    80003d1e:	8526                	mv	a0,s1
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	4b4080e7          	jalr	1204(ra) # 800031d4 <brelse>
  }

  if(off > ip->size)
    80003d28:	04cb2783          	lw	a5,76(s6)
    80003d2c:	0127f463          	bgeu	a5,s2,80003d34 <writei+0xe2>
    ip->size = off;
    80003d30:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d34:	855a                	mv	a0,s6
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	aa6080e7          	jalr	-1370(ra) # 800037dc <iupdate>

  return tot;
    80003d3e:	000a051b          	sext.w	a0,s4
}
    80003d42:	70a6                	ld	ra,104(sp)
    80003d44:	7406                	ld	s0,96(sp)
    80003d46:	64e6                	ld	s1,88(sp)
    80003d48:	6946                	ld	s2,80(sp)
    80003d4a:	69a6                	ld	s3,72(sp)
    80003d4c:	6a06                	ld	s4,64(sp)
    80003d4e:	7ae2                	ld	s5,56(sp)
    80003d50:	7b42                	ld	s6,48(sp)
    80003d52:	7ba2                	ld	s7,40(sp)
    80003d54:	7c02                	ld	s8,32(sp)
    80003d56:	6ce2                	ld	s9,24(sp)
    80003d58:	6d42                	ld	s10,16(sp)
    80003d5a:	6da2                	ld	s11,8(sp)
    80003d5c:	6165                	addi	sp,sp,112
    80003d5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d60:	8a5e                	mv	s4,s7
    80003d62:	bfc9                	j	80003d34 <writei+0xe2>
    return -1;
    80003d64:	557d                	li	a0,-1
}
    80003d66:	8082                	ret
    return -1;
    80003d68:	557d                	li	a0,-1
    80003d6a:	bfe1                	j	80003d42 <writei+0xf0>
    return -1;
    80003d6c:	557d                	li	a0,-1
    80003d6e:	bfd1                	j	80003d42 <writei+0xf0>

0000000080003d70 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d70:	1141                	addi	sp,sp,-16
    80003d72:	e406                	sd	ra,8(sp)
    80003d74:	e022                	sd	s0,0(sp)
    80003d76:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d78:	4639                	li	a2,14
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	03e080e7          	jalr	62(ra) # 80000db8 <strncmp>
}
    80003d82:	60a2                	ld	ra,8(sp)
    80003d84:	6402                	ld	s0,0(sp)
    80003d86:	0141                	addi	sp,sp,16
    80003d88:	8082                	ret

0000000080003d8a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d8a:	7139                	addi	sp,sp,-64
    80003d8c:	fc06                	sd	ra,56(sp)
    80003d8e:	f822                	sd	s0,48(sp)
    80003d90:	f426                	sd	s1,40(sp)
    80003d92:	f04a                	sd	s2,32(sp)
    80003d94:	ec4e                	sd	s3,24(sp)
    80003d96:	e852                	sd	s4,16(sp)
    80003d98:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d9a:	04451703          	lh	a4,68(a0)
    80003d9e:	4785                	li	a5,1
    80003da0:	00f71a63          	bne	a4,a5,80003db4 <dirlookup+0x2a>
    80003da4:	892a                	mv	s2,a0
    80003da6:	89ae                	mv	s3,a1
    80003da8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003daa:	457c                	lw	a5,76(a0)
    80003dac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db0:	e79d                	bnez	a5,80003dde <dirlookup+0x54>
    80003db2:	a8a5                	j	80003e2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003db4:	00005517          	auipc	a0,0x5
    80003db8:	86c50513          	addi	a0,a0,-1940 # 80008620 <syscalls+0x1b0>
    80003dbc:	ffffc097          	auipc	ra,0xffffc
    80003dc0:	782080e7          	jalr	1922(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dc4:	00005517          	auipc	a0,0x5
    80003dc8:	87450513          	addi	a0,a0,-1932 # 80008638 <syscalls+0x1c8>
    80003dcc:	ffffc097          	auipc	ra,0xffffc
    80003dd0:	772080e7          	jalr	1906(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd4:	24c1                	addiw	s1,s1,16
    80003dd6:	04c92783          	lw	a5,76(s2)
    80003dda:	04f4f763          	bgeu	s1,a5,80003e28 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dde:	4741                	li	a4,16
    80003de0:	86a6                	mv	a3,s1
    80003de2:	fc040613          	addi	a2,s0,-64
    80003de6:	4581                	li	a1,0
    80003de8:	854a                	mv	a0,s2
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	d70080e7          	jalr	-656(ra) # 80003b5a <readi>
    80003df2:	47c1                	li	a5,16
    80003df4:	fcf518e3          	bne	a0,a5,80003dc4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003df8:	fc045783          	lhu	a5,-64(s0)
    80003dfc:	dfe1                	beqz	a5,80003dd4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dfe:	fc240593          	addi	a1,s0,-62
    80003e02:	854e                	mv	a0,s3
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	f6c080e7          	jalr	-148(ra) # 80003d70 <namecmp>
    80003e0c:	f561                	bnez	a0,80003dd4 <dirlookup+0x4a>
      if(poff)
    80003e0e:	000a0463          	beqz	s4,80003e16 <dirlookup+0x8c>
        *poff = off;
    80003e12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e16:	fc045583          	lhu	a1,-64(s0)
    80003e1a:	00092503          	lw	a0,0(s2)
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	754080e7          	jalr	1876(ra) # 80003572 <iget>
    80003e26:	a011                	j	80003e2a <dirlookup+0xa0>
  return 0;
    80003e28:	4501                	li	a0,0
}
    80003e2a:	70e2                	ld	ra,56(sp)
    80003e2c:	7442                	ld	s0,48(sp)
    80003e2e:	74a2                	ld	s1,40(sp)
    80003e30:	7902                	ld	s2,32(sp)
    80003e32:	69e2                	ld	s3,24(sp)
    80003e34:	6a42                	ld	s4,16(sp)
    80003e36:	6121                	addi	sp,sp,64
    80003e38:	8082                	ret

0000000080003e3a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e3a:	711d                	addi	sp,sp,-96
    80003e3c:	ec86                	sd	ra,88(sp)
    80003e3e:	e8a2                	sd	s0,80(sp)
    80003e40:	e4a6                	sd	s1,72(sp)
    80003e42:	e0ca                	sd	s2,64(sp)
    80003e44:	fc4e                	sd	s3,56(sp)
    80003e46:	f852                	sd	s4,48(sp)
    80003e48:	f456                	sd	s5,40(sp)
    80003e4a:	f05a                	sd	s6,32(sp)
    80003e4c:	ec5e                	sd	s7,24(sp)
    80003e4e:	e862                	sd	s8,16(sp)
    80003e50:	e466                	sd	s9,8(sp)
    80003e52:	1080                	addi	s0,sp,96
    80003e54:	84aa                	mv	s1,a0
    80003e56:	8b2e                	mv	s6,a1
    80003e58:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e5a:	00054703          	lbu	a4,0(a0)
    80003e5e:	02f00793          	li	a5,47
    80003e62:	02f70363          	beq	a4,a5,80003e88 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e66:	ffffe097          	auipc	ra,0xffffe
    80003e6a:	b52080e7          	jalr	-1198(ra) # 800019b8 <myproc>
    80003e6e:	15053503          	ld	a0,336(a0)
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	9f6080e7          	jalr	-1546(ra) # 80003868 <idup>
    80003e7a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e7c:	02f00913          	li	s2,47
  len = path - s;
    80003e80:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e82:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e84:	4c05                	li	s8,1
    80003e86:	a865                	j	80003f3e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e88:	4585                	li	a1,1
    80003e8a:	4505                	li	a0,1
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	6e6080e7          	jalr	1766(ra) # 80003572 <iget>
    80003e94:	89aa                	mv	s3,a0
    80003e96:	b7dd                	j	80003e7c <namex+0x42>
      iunlockput(ip);
    80003e98:	854e                	mv	a0,s3
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	c6e080e7          	jalr	-914(ra) # 80003b08 <iunlockput>
      return 0;
    80003ea2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	60e6                	ld	ra,88(sp)
    80003ea8:	6446                	ld	s0,80(sp)
    80003eaa:	64a6                	ld	s1,72(sp)
    80003eac:	6906                	ld	s2,64(sp)
    80003eae:	79e2                	ld	s3,56(sp)
    80003eb0:	7a42                	ld	s4,48(sp)
    80003eb2:	7aa2                	ld	s5,40(sp)
    80003eb4:	7b02                	ld	s6,32(sp)
    80003eb6:	6be2                	ld	s7,24(sp)
    80003eb8:	6c42                	ld	s8,16(sp)
    80003eba:	6ca2                	ld	s9,8(sp)
    80003ebc:	6125                	addi	sp,sp,96
    80003ebe:	8082                	ret
      iunlock(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	aa6080e7          	jalr	-1370(ra) # 80003968 <iunlock>
      return ip;
    80003eca:	bfe9                	j	80003ea4 <namex+0x6a>
      iunlockput(ip);
    80003ecc:	854e                	mv	a0,s3
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	c3a080e7          	jalr	-966(ra) # 80003b08 <iunlockput>
      return 0;
    80003ed6:	89d2                	mv	s3,s4
    80003ed8:	b7f1                	j	80003ea4 <namex+0x6a>
  len = path - s;
    80003eda:	40b48633          	sub	a2,s1,a1
    80003ede:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ee2:	094cd463          	bge	s9,s4,80003f6a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ee6:	4639                	li	a2,14
    80003ee8:	8556                	mv	a0,s5
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	e56080e7          	jalr	-426(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ef2:	0004c783          	lbu	a5,0(s1)
    80003ef6:	01279763          	bne	a5,s2,80003f04 <namex+0xca>
    path++;
    80003efa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003efc:	0004c783          	lbu	a5,0(s1)
    80003f00:	ff278de3          	beq	a5,s2,80003efa <namex+0xc0>
    ilock(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	9a0080e7          	jalr	-1632(ra) # 800038a6 <ilock>
    if(ip->type != T_DIR){
    80003f0e:	04499783          	lh	a5,68(s3)
    80003f12:	f98793e3          	bne	a5,s8,80003e98 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f16:	000b0563          	beqz	s6,80003f20 <namex+0xe6>
    80003f1a:	0004c783          	lbu	a5,0(s1)
    80003f1e:	d3cd                	beqz	a5,80003ec0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f20:	865e                	mv	a2,s7
    80003f22:	85d6                	mv	a1,s5
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	e64080e7          	jalr	-412(ra) # 80003d8a <dirlookup>
    80003f2e:	8a2a                	mv	s4,a0
    80003f30:	dd51                	beqz	a0,80003ecc <namex+0x92>
    iunlockput(ip);
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	bd4080e7          	jalr	-1068(ra) # 80003b08 <iunlockput>
    ip = next;
    80003f3c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f3e:	0004c783          	lbu	a5,0(s1)
    80003f42:	05279763          	bne	a5,s2,80003f90 <namex+0x156>
    path++;
    80003f46:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f48:	0004c783          	lbu	a5,0(s1)
    80003f4c:	ff278de3          	beq	a5,s2,80003f46 <namex+0x10c>
  if(*path == 0)
    80003f50:	c79d                	beqz	a5,80003f7e <namex+0x144>
    path++;
    80003f52:	85a6                	mv	a1,s1
  len = path - s;
    80003f54:	8a5e                	mv	s4,s7
    80003f56:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f58:	01278963          	beq	a5,s2,80003f6a <namex+0x130>
    80003f5c:	dfbd                	beqz	a5,80003eda <namex+0xa0>
    path++;
    80003f5e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f60:	0004c783          	lbu	a5,0(s1)
    80003f64:	ff279ce3          	bne	a5,s2,80003f5c <namex+0x122>
    80003f68:	bf8d                	j	80003eda <namex+0xa0>
    memmove(name, s, len);
    80003f6a:	2601                	sext.w	a2,a2
    80003f6c:	8556                	mv	a0,s5
    80003f6e:	ffffd097          	auipc	ra,0xffffd
    80003f72:	dd2080e7          	jalr	-558(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f76:	9a56                	add	s4,s4,s5
    80003f78:	000a0023          	sb	zero,0(s4)
    80003f7c:	bf9d                	j	80003ef2 <namex+0xb8>
  if(nameiparent){
    80003f7e:	f20b03e3          	beqz	s6,80003ea4 <namex+0x6a>
    iput(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	adc080e7          	jalr	-1316(ra) # 80003a60 <iput>
    return 0;
    80003f8c:	4981                	li	s3,0
    80003f8e:	bf19                	j	80003ea4 <namex+0x6a>
  if(*path == 0)
    80003f90:	d7fd                	beqz	a5,80003f7e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f92:	0004c783          	lbu	a5,0(s1)
    80003f96:	85a6                	mv	a1,s1
    80003f98:	b7d1                	j	80003f5c <namex+0x122>

0000000080003f9a <dirlink>:
{
    80003f9a:	7139                	addi	sp,sp,-64
    80003f9c:	fc06                	sd	ra,56(sp)
    80003f9e:	f822                	sd	s0,48(sp)
    80003fa0:	f426                	sd	s1,40(sp)
    80003fa2:	f04a                	sd	s2,32(sp)
    80003fa4:	ec4e                	sd	s3,24(sp)
    80003fa6:	e852                	sd	s4,16(sp)
    80003fa8:	0080                	addi	s0,sp,64
    80003faa:	892a                	mv	s2,a0
    80003fac:	8a2e                	mv	s4,a1
    80003fae:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fb0:	4601                	li	a2,0
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	dd8080e7          	jalr	-552(ra) # 80003d8a <dirlookup>
    80003fba:	e93d                	bnez	a0,80004030 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fbc:	04c92483          	lw	s1,76(s2)
    80003fc0:	c49d                	beqz	s1,80003fee <dirlink+0x54>
    80003fc2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc4:	4741                	li	a4,16
    80003fc6:	86a6                	mv	a3,s1
    80003fc8:	fc040613          	addi	a2,s0,-64
    80003fcc:	4581                	li	a1,0
    80003fce:	854a                	mv	a0,s2
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	b8a080e7          	jalr	-1142(ra) # 80003b5a <readi>
    80003fd8:	47c1                	li	a5,16
    80003fda:	06f51163          	bne	a0,a5,8000403c <dirlink+0xa2>
    if(de.inum == 0)
    80003fde:	fc045783          	lhu	a5,-64(s0)
    80003fe2:	c791                	beqz	a5,80003fee <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe4:	24c1                	addiw	s1,s1,16
    80003fe6:	04c92783          	lw	a5,76(s2)
    80003fea:	fcf4ede3          	bltu	s1,a5,80003fc4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fee:	4639                	li	a2,14
    80003ff0:	85d2                	mv	a1,s4
    80003ff2:	fc240513          	addi	a0,s0,-62
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	dfe080e7          	jalr	-514(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003ffe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004002:	4741                	li	a4,16
    80004004:	86a6                	mv	a3,s1
    80004006:	fc040613          	addi	a2,s0,-64
    8000400a:	4581                	li	a1,0
    8000400c:	854a                	mv	a0,s2
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	c44080e7          	jalr	-956(ra) # 80003c52 <writei>
    80004016:	872a                	mv	a4,a0
    80004018:	47c1                	li	a5,16
  return 0;
    8000401a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000401c:	02f71863          	bne	a4,a5,8000404c <dirlink+0xb2>
}
    80004020:	70e2                	ld	ra,56(sp)
    80004022:	7442                	ld	s0,48(sp)
    80004024:	74a2                	ld	s1,40(sp)
    80004026:	7902                	ld	s2,32(sp)
    80004028:	69e2                	ld	s3,24(sp)
    8000402a:	6a42                	ld	s4,16(sp)
    8000402c:	6121                	addi	sp,sp,64
    8000402e:	8082                	ret
    iput(ip);
    80004030:	00000097          	auipc	ra,0x0
    80004034:	a30080e7          	jalr	-1488(ra) # 80003a60 <iput>
    return -1;
    80004038:	557d                	li	a0,-1
    8000403a:	b7dd                	j	80004020 <dirlink+0x86>
      panic("dirlink read");
    8000403c:	00004517          	auipc	a0,0x4
    80004040:	60c50513          	addi	a0,a0,1548 # 80008648 <syscalls+0x1d8>
    80004044:	ffffc097          	auipc	ra,0xffffc
    80004048:	4fa080e7          	jalr	1274(ra) # 8000053e <panic>
    panic("dirlink");
    8000404c:	00004517          	auipc	a0,0x4
    80004050:	70c50513          	addi	a0,a0,1804 # 80008758 <syscalls+0x2e8>
    80004054:	ffffc097          	auipc	ra,0xffffc
    80004058:	4ea080e7          	jalr	1258(ra) # 8000053e <panic>

000000008000405c <namei>:

struct inode*
namei(char *path)
{
    8000405c:	1101                	addi	sp,sp,-32
    8000405e:	ec06                	sd	ra,24(sp)
    80004060:	e822                	sd	s0,16(sp)
    80004062:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004064:	fe040613          	addi	a2,s0,-32
    80004068:	4581                	li	a1,0
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	dd0080e7          	jalr	-560(ra) # 80003e3a <namex>
}
    80004072:	60e2                	ld	ra,24(sp)
    80004074:	6442                	ld	s0,16(sp)
    80004076:	6105                	addi	sp,sp,32
    80004078:	8082                	ret

000000008000407a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000407a:	1141                	addi	sp,sp,-16
    8000407c:	e406                	sd	ra,8(sp)
    8000407e:	e022                	sd	s0,0(sp)
    80004080:	0800                	addi	s0,sp,16
    80004082:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004084:	4585                	li	a1,1
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	db4080e7          	jalr	-588(ra) # 80003e3a <namex>
}
    8000408e:	60a2                	ld	ra,8(sp)
    80004090:	6402                	ld	s0,0(sp)
    80004092:	0141                	addi	sp,sp,16
    80004094:	8082                	ret

0000000080004096 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	e426                	sd	s1,8(sp)
    8000409e:	e04a                	sd	s2,0(sp)
    800040a0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040a2:	00016917          	auipc	s2,0x16
    800040a6:	33e90913          	addi	s2,s2,830 # 8001a3e0 <log>
    800040aa:	01892583          	lw	a1,24(s2)
    800040ae:	02892503          	lw	a0,40(s2)
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	ff2080e7          	jalr	-14(ra) # 800030a4 <bread>
    800040ba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040bc:	02c92683          	lw	a3,44(s2)
    800040c0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040c2:	02d05763          	blez	a3,800040f0 <write_head+0x5a>
    800040c6:	00016797          	auipc	a5,0x16
    800040ca:	34a78793          	addi	a5,a5,842 # 8001a410 <log+0x30>
    800040ce:	05c50713          	addi	a4,a0,92
    800040d2:	36fd                	addiw	a3,a3,-1
    800040d4:	1682                	slli	a3,a3,0x20
    800040d6:	9281                	srli	a3,a3,0x20
    800040d8:	068a                	slli	a3,a3,0x2
    800040da:	00016617          	auipc	a2,0x16
    800040de:	33a60613          	addi	a2,a2,826 # 8001a414 <log+0x34>
    800040e2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040e4:	4390                	lw	a2,0(a5)
    800040e6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040e8:	0791                	addi	a5,a5,4
    800040ea:	0711                	addi	a4,a4,4
    800040ec:	fed79ce3          	bne	a5,a3,800040e4 <write_head+0x4e>
  }
  bwrite(buf);
    800040f0:	8526                	mv	a0,s1
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	0a4080e7          	jalr	164(ra) # 80003196 <bwrite>
  brelse(buf);
    800040fa:	8526                	mv	a0,s1
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	0d8080e7          	jalr	216(ra) # 800031d4 <brelse>
}
    80004104:	60e2                	ld	ra,24(sp)
    80004106:	6442                	ld	s0,16(sp)
    80004108:	64a2                	ld	s1,8(sp)
    8000410a:	6902                	ld	s2,0(sp)
    8000410c:	6105                	addi	sp,sp,32
    8000410e:	8082                	ret

0000000080004110 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004110:	00016797          	auipc	a5,0x16
    80004114:	2fc7a783          	lw	a5,764(a5) # 8001a40c <log+0x2c>
    80004118:	0af05d63          	blez	a5,800041d2 <install_trans+0xc2>
{
    8000411c:	7139                	addi	sp,sp,-64
    8000411e:	fc06                	sd	ra,56(sp)
    80004120:	f822                	sd	s0,48(sp)
    80004122:	f426                	sd	s1,40(sp)
    80004124:	f04a                	sd	s2,32(sp)
    80004126:	ec4e                	sd	s3,24(sp)
    80004128:	e852                	sd	s4,16(sp)
    8000412a:	e456                	sd	s5,8(sp)
    8000412c:	e05a                	sd	s6,0(sp)
    8000412e:	0080                	addi	s0,sp,64
    80004130:	8b2a                	mv	s6,a0
    80004132:	00016a97          	auipc	s5,0x16
    80004136:	2dea8a93          	addi	s5,s5,734 # 8001a410 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000413c:	00016997          	auipc	s3,0x16
    80004140:	2a498993          	addi	s3,s3,676 # 8001a3e0 <log>
    80004144:	a035                	j	80004170 <install_trans+0x60>
      bunpin(dbuf);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	166080e7          	jalr	358(ra) # 800032ae <bunpin>
    brelse(lbuf);
    80004150:	854a                	mv	a0,s2
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	082080e7          	jalr	130(ra) # 800031d4 <brelse>
    brelse(dbuf);
    8000415a:	8526                	mv	a0,s1
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	078080e7          	jalr	120(ra) # 800031d4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004164:	2a05                	addiw	s4,s4,1
    80004166:	0a91                	addi	s5,s5,4
    80004168:	02c9a783          	lw	a5,44(s3)
    8000416c:	04fa5963          	bge	s4,a5,800041be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004170:	0189a583          	lw	a1,24(s3)
    80004174:	014585bb          	addw	a1,a1,s4
    80004178:	2585                	addiw	a1,a1,1
    8000417a:	0289a503          	lw	a0,40(s3)
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	f26080e7          	jalr	-218(ra) # 800030a4 <bread>
    80004186:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004188:	000aa583          	lw	a1,0(s5)
    8000418c:	0289a503          	lw	a0,40(s3)
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	f14080e7          	jalr	-236(ra) # 800030a4 <bread>
    80004198:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000419a:	40000613          	li	a2,1024
    8000419e:	05890593          	addi	a1,s2,88
    800041a2:	05850513          	addi	a0,a0,88
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	b9a080e7          	jalr	-1126(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041ae:	8526                	mv	a0,s1
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	fe6080e7          	jalr	-26(ra) # 80003196 <bwrite>
    if(recovering == 0)
    800041b8:	f80b1ce3          	bnez	s6,80004150 <install_trans+0x40>
    800041bc:	b769                	j	80004146 <install_trans+0x36>
}
    800041be:	70e2                	ld	ra,56(sp)
    800041c0:	7442                	ld	s0,48(sp)
    800041c2:	74a2                	ld	s1,40(sp)
    800041c4:	7902                	ld	s2,32(sp)
    800041c6:	69e2                	ld	s3,24(sp)
    800041c8:	6a42                	ld	s4,16(sp)
    800041ca:	6aa2                	ld	s5,8(sp)
    800041cc:	6b02                	ld	s6,0(sp)
    800041ce:	6121                	addi	sp,sp,64
    800041d0:	8082                	ret
    800041d2:	8082                	ret

00000000800041d4 <initlog>:
{
    800041d4:	7179                	addi	sp,sp,-48
    800041d6:	f406                	sd	ra,40(sp)
    800041d8:	f022                	sd	s0,32(sp)
    800041da:	ec26                	sd	s1,24(sp)
    800041dc:	e84a                	sd	s2,16(sp)
    800041de:	e44e                	sd	s3,8(sp)
    800041e0:	1800                	addi	s0,sp,48
    800041e2:	892a                	mv	s2,a0
    800041e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041e6:	00016497          	auipc	s1,0x16
    800041ea:	1fa48493          	addi	s1,s1,506 # 8001a3e0 <log>
    800041ee:	00004597          	auipc	a1,0x4
    800041f2:	46a58593          	addi	a1,a1,1130 # 80008658 <syscalls+0x1e8>
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	95c080e7          	jalr	-1700(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004200:	0149a583          	lw	a1,20(s3)
    80004204:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004206:	0109a783          	lw	a5,16(s3)
    8000420a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000420c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004210:	854a                	mv	a0,s2
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	e92080e7          	jalr	-366(ra) # 800030a4 <bread>
  log.lh.n = lh->n;
    8000421a:	4d3c                	lw	a5,88(a0)
    8000421c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000421e:	02f05563          	blez	a5,80004248 <initlog+0x74>
    80004222:	05c50713          	addi	a4,a0,92
    80004226:	00016697          	auipc	a3,0x16
    8000422a:	1ea68693          	addi	a3,a3,490 # 8001a410 <log+0x30>
    8000422e:	37fd                	addiw	a5,a5,-1
    80004230:	1782                	slli	a5,a5,0x20
    80004232:	9381                	srli	a5,a5,0x20
    80004234:	078a                	slli	a5,a5,0x2
    80004236:	06050613          	addi	a2,a0,96
    8000423a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000423c:	4310                	lw	a2,0(a4)
    8000423e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004240:	0711                	addi	a4,a4,4
    80004242:	0691                	addi	a3,a3,4
    80004244:	fef71ce3          	bne	a4,a5,8000423c <initlog+0x68>
  brelse(buf);
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	f8c080e7          	jalr	-116(ra) # 800031d4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004250:	4505                	li	a0,1
    80004252:	00000097          	auipc	ra,0x0
    80004256:	ebe080e7          	jalr	-322(ra) # 80004110 <install_trans>
  log.lh.n = 0;
    8000425a:	00016797          	auipc	a5,0x16
    8000425e:	1a07a923          	sw	zero,434(a5) # 8001a40c <log+0x2c>
  write_head(); // clear the log
    80004262:	00000097          	auipc	ra,0x0
    80004266:	e34080e7          	jalr	-460(ra) # 80004096 <write_head>
}
    8000426a:	70a2                	ld	ra,40(sp)
    8000426c:	7402                	ld	s0,32(sp)
    8000426e:	64e2                	ld	s1,24(sp)
    80004270:	6942                	ld	s2,16(sp)
    80004272:	69a2                	ld	s3,8(sp)
    80004274:	6145                	addi	sp,sp,48
    80004276:	8082                	ret

0000000080004278 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004278:	1101                	addi	sp,sp,-32
    8000427a:	ec06                	sd	ra,24(sp)
    8000427c:	e822                	sd	s0,16(sp)
    8000427e:	e426                	sd	s1,8(sp)
    80004280:	e04a                	sd	s2,0(sp)
    80004282:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004284:	00016517          	auipc	a0,0x16
    80004288:	15c50513          	addi	a0,a0,348 # 8001a3e0 <log>
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	958080e7          	jalr	-1704(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004294:	00016497          	auipc	s1,0x16
    80004298:	14c48493          	addi	s1,s1,332 # 8001a3e0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429c:	4979                	li	s2,30
    8000429e:	a039                	j	800042ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800042a0:	85a6                	mv	a1,s1
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	fa2080e7          	jalr	-94(ra) # 80002246 <sleep>
    if(log.committing){
    800042ac:	50dc                	lw	a5,36(s1)
    800042ae:	fbed                	bnez	a5,800042a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042b0:	509c                	lw	a5,32(s1)
    800042b2:	0017871b          	addiw	a4,a5,1
    800042b6:	0007069b          	sext.w	a3,a4
    800042ba:	0027179b          	slliw	a5,a4,0x2
    800042be:	9fb9                	addw	a5,a5,a4
    800042c0:	0017979b          	slliw	a5,a5,0x1
    800042c4:	54d8                	lw	a4,44(s1)
    800042c6:	9fb9                	addw	a5,a5,a4
    800042c8:	00f95963          	bge	s2,a5,800042da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042cc:	85a6                	mv	a1,s1
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	f76080e7          	jalr	-138(ra) # 80002246 <sleep>
    800042d8:	bfd1                	j	800042ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042da:	00016517          	auipc	a0,0x16
    800042de:	10650513          	addi	a0,a0,262 # 8001a3e0 <log>
    800042e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	9b4080e7          	jalr	-1612(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042ec:	60e2                	ld	ra,24(sp)
    800042ee:	6442                	ld	s0,16(sp)
    800042f0:	64a2                	ld	s1,8(sp)
    800042f2:	6902                	ld	s2,0(sp)
    800042f4:	6105                	addi	sp,sp,32
    800042f6:	8082                	ret

00000000800042f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042f8:	7139                	addi	sp,sp,-64
    800042fa:	fc06                	sd	ra,56(sp)
    800042fc:	f822                	sd	s0,48(sp)
    800042fe:	f426                	sd	s1,40(sp)
    80004300:	f04a                	sd	s2,32(sp)
    80004302:	ec4e                	sd	s3,24(sp)
    80004304:	e852                	sd	s4,16(sp)
    80004306:	e456                	sd	s5,8(sp)
    80004308:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000430a:	00016497          	auipc	s1,0x16
    8000430e:	0d648493          	addi	s1,s1,214 # 8001a3e0 <log>
    80004312:	8526                	mv	a0,s1
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	8d0080e7          	jalr	-1840(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000431c:	509c                	lw	a5,32(s1)
    8000431e:	37fd                	addiw	a5,a5,-1
    80004320:	0007891b          	sext.w	s2,a5
    80004324:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004326:	50dc                	lw	a5,36(s1)
    80004328:	efb9                	bnez	a5,80004386 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000432a:	06091663          	bnez	s2,80004396 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000432e:	00016497          	auipc	s1,0x16
    80004332:	0b248493          	addi	s1,s1,178 # 8001a3e0 <log>
    80004336:	4785                	li	a5,1
    80004338:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	95c080e7          	jalr	-1700(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004344:	54dc                	lw	a5,44(s1)
    80004346:	06f04763          	bgtz	a5,800043b4 <end_op+0xbc>
    acquire(&log.lock);
    8000434a:	00016497          	auipc	s1,0x16
    8000434e:	09648493          	addi	s1,s1,150 # 8001a3e0 <log>
    80004352:	8526                	mv	a0,s1
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	890080e7          	jalr	-1904(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000435c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	070080e7          	jalr	112(ra) # 800023d2 <wakeup>
    release(&log.lock);
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
}
    80004374:	70e2                	ld	ra,56(sp)
    80004376:	7442                	ld	s0,48(sp)
    80004378:	74a2                	ld	s1,40(sp)
    8000437a:	7902                	ld	s2,32(sp)
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6aa2                	ld	s5,8(sp)
    80004382:	6121                	addi	sp,sp,64
    80004384:	8082                	ret
    panic("log.committing");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	2da50513          	addi	a0,a0,730 # 80008660 <syscalls+0x1f0>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>
    wakeup(&log);
    80004396:	00016497          	auipc	s1,0x16
    8000439a:	04a48493          	addi	s1,s1,74 # 8001a3e0 <log>
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	032080e7          	jalr	50(ra) # 800023d2 <wakeup>
  release(&log.lock);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	8ee080e7          	jalr	-1810(ra) # 80000c98 <release>
  if(do_commit){
    800043b2:	b7c9                	j	80004374 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b4:	00016a97          	auipc	s5,0x16
    800043b8:	05ca8a93          	addi	s5,s5,92 # 8001a410 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043bc:	00016a17          	auipc	s4,0x16
    800043c0:	024a0a13          	addi	s4,s4,36 # 8001a3e0 <log>
    800043c4:	018a2583          	lw	a1,24(s4)
    800043c8:	012585bb          	addw	a1,a1,s2
    800043cc:	2585                	addiw	a1,a1,1
    800043ce:	028a2503          	lw	a0,40(s4)
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	cd2080e7          	jalr	-814(ra) # 800030a4 <bread>
    800043da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043dc:	000aa583          	lw	a1,0(s5)
    800043e0:	028a2503          	lw	a0,40(s4)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	cc0080e7          	jalr	-832(ra) # 800030a4 <bread>
    800043ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043ee:	40000613          	li	a2,1024
    800043f2:	05850593          	addi	a1,a0,88
    800043f6:	05848513          	addi	a0,s1,88
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	946080e7          	jalr	-1722(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	d92080e7          	jalr	-622(ra) # 80003196 <bwrite>
    brelse(from);
    8000440c:	854e                	mv	a0,s3
    8000440e:	fffff097          	auipc	ra,0xfffff
    80004412:	dc6080e7          	jalr	-570(ra) # 800031d4 <brelse>
    brelse(to);
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	dbc080e7          	jalr	-580(ra) # 800031d4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004420:	2905                	addiw	s2,s2,1
    80004422:	0a91                	addi	s5,s5,4
    80004424:	02ca2783          	lw	a5,44(s4)
    80004428:	f8f94ee3          	blt	s2,a5,800043c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	c6a080e7          	jalr	-918(ra) # 80004096 <write_head>
    install_trans(0); // Now install writes to home locations
    80004434:	4501                	li	a0,0
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	cda080e7          	jalr	-806(ra) # 80004110 <install_trans>
    log.lh.n = 0;
    8000443e:	00016797          	auipc	a5,0x16
    80004442:	fc07a723          	sw	zero,-50(a5) # 8001a40c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	c50080e7          	jalr	-944(ra) # 80004096 <write_head>
    8000444e:	bdf5                	j	8000434a <end_op+0x52>

0000000080004450 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004450:	1101                	addi	sp,sp,-32
    80004452:	ec06                	sd	ra,24(sp)
    80004454:	e822                	sd	s0,16(sp)
    80004456:	e426                	sd	s1,8(sp)
    80004458:	e04a                	sd	s2,0(sp)
    8000445a:	1000                	addi	s0,sp,32
    8000445c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000445e:	00016917          	auipc	s2,0x16
    80004462:	f8290913          	addi	s2,s2,-126 # 8001a3e0 <log>
    80004466:	854a                	mv	a0,s2
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	77c080e7          	jalr	1916(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004470:	02c92603          	lw	a2,44(s2)
    80004474:	47f5                	li	a5,29
    80004476:	06c7c563          	blt	a5,a2,800044e0 <log_write+0x90>
    8000447a:	00016797          	auipc	a5,0x16
    8000447e:	f827a783          	lw	a5,-126(a5) # 8001a3fc <log+0x1c>
    80004482:	37fd                	addiw	a5,a5,-1
    80004484:	04f65e63          	bge	a2,a5,800044e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004488:	00016797          	auipc	a5,0x16
    8000448c:	f787a783          	lw	a5,-136(a5) # 8001a400 <log+0x20>
    80004490:	06f05063          	blez	a5,800044f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004494:	4781                	li	a5,0
    80004496:	06c05563          	blez	a2,80004500 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000449a:	44cc                	lw	a1,12(s1)
    8000449c:	00016717          	auipc	a4,0x16
    800044a0:	f7470713          	addi	a4,a4,-140 # 8001a410 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044a6:	4314                	lw	a3,0(a4)
    800044a8:	04b68c63          	beq	a3,a1,80004500 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044ac:	2785                	addiw	a5,a5,1
    800044ae:	0711                	addi	a4,a4,4
    800044b0:	fef61be3          	bne	a2,a5,800044a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044b4:	0621                	addi	a2,a2,8
    800044b6:	060a                	slli	a2,a2,0x2
    800044b8:	00016797          	auipc	a5,0x16
    800044bc:	f2878793          	addi	a5,a5,-216 # 8001a3e0 <log>
    800044c0:	963e                	add	a2,a2,a5
    800044c2:	44dc                	lw	a5,12(s1)
    800044c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	daa080e7          	jalr	-598(ra) # 80003272 <bpin>
    log.lh.n++;
    800044d0:	00016717          	auipc	a4,0x16
    800044d4:	f1070713          	addi	a4,a4,-240 # 8001a3e0 <log>
    800044d8:	575c                	lw	a5,44(a4)
    800044da:	2785                	addiw	a5,a5,1
    800044dc:	d75c                	sw	a5,44(a4)
    800044de:	a835                	j	8000451a <log_write+0xca>
    panic("too big a transaction");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	19050513          	addi	a0,a0,400 # 80008670 <syscalls+0x200>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	056080e7          	jalr	86(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044f0:	00004517          	auipc	a0,0x4
    800044f4:	19850513          	addi	a0,a0,408 # 80008688 <syscalls+0x218>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	046080e7          	jalr	70(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004500:	00878713          	addi	a4,a5,8
    80004504:	00271693          	slli	a3,a4,0x2
    80004508:	00016717          	auipc	a4,0x16
    8000450c:	ed870713          	addi	a4,a4,-296 # 8001a3e0 <log>
    80004510:	9736                	add	a4,a4,a3
    80004512:	44d4                	lw	a3,12(s1)
    80004514:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004516:	faf608e3          	beq	a2,a5,800044c6 <log_write+0x76>
  }
  release(&log.lock);
    8000451a:	00016517          	auipc	a0,0x16
    8000451e:	ec650513          	addi	a0,a0,-314 # 8001a3e0 <log>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	776080e7          	jalr	1910(ra) # 80000c98 <release>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6902                	ld	s2,0(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004536:	1101                	addi	sp,sp,-32
    80004538:	ec06                	sd	ra,24(sp)
    8000453a:	e822                	sd	s0,16(sp)
    8000453c:	e426                	sd	s1,8(sp)
    8000453e:	e04a                	sd	s2,0(sp)
    80004540:	1000                	addi	s0,sp,32
    80004542:	84aa                	mv	s1,a0
    80004544:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004546:	00004597          	auipc	a1,0x4
    8000454a:	16258593          	addi	a1,a1,354 # 800086a8 <syscalls+0x238>
    8000454e:	0521                	addi	a0,a0,8
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	604080e7          	jalr	1540(ra) # 80000b54 <initlock>
  lk->name = name;
    80004558:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000455c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004560:	0204a423          	sw	zero,40(s1)
}
    80004564:	60e2                	ld	ra,24(sp)
    80004566:	6442                	ld	s0,16(sp)
    80004568:	64a2                	ld	s1,8(sp)
    8000456a:	6902                	ld	s2,0(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret

0000000080004570 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004570:	1101                	addi	sp,sp,-32
    80004572:	ec06                	sd	ra,24(sp)
    80004574:	e822                	sd	s0,16(sp)
    80004576:	e426                	sd	s1,8(sp)
    80004578:	e04a                	sd	s2,0(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000457e:	00850913          	addi	s2,a0,8
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000458c:	409c                	lw	a5,0(s1)
    8000458e:	cb89                	beqz	a5,800045a0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004590:	85ca                	mv	a1,s2
    80004592:	8526                	mv	a0,s1
    80004594:	ffffe097          	auipc	ra,0xffffe
    80004598:	cb2080e7          	jalr	-846(ra) # 80002246 <sleep>
  while (lk->locked) {
    8000459c:	409c                	lw	a5,0(s1)
    8000459e:	fbed                	bnez	a5,80004590 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045a0:	4785                	li	a5,1
    800045a2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045a4:	ffffd097          	auipc	ra,0xffffd
    800045a8:	414080e7          	jalr	1044(ra) # 800019b8 <myproc>
    800045ac:	591c                	lw	a5,48(a0)
    800045ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045b0:	854a                	mv	a0,s2
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
}
    800045ba:	60e2                	ld	ra,24(sp)
    800045bc:	6442                	ld	s0,16(sp)
    800045be:	64a2                	ld	s1,8(sp)
    800045c0:	6902                	ld	s2,0(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret

00000000800045c6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045c6:	1101                	addi	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	e426                	sd	s1,8(sp)
    800045ce:	e04a                	sd	s2,0(sp)
    800045d0:	1000                	addi	s0,sp,32
    800045d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d4:	00850913          	addi	s2,a0,8
    800045d8:	854a                	mv	a0,s2
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	60a080e7          	jalr	1546(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffe097          	auipc	ra,0xffffe
    800045f0:	de6080e7          	jalr	-538(ra) # 800023d2 <wakeup>
  release(&lk->lk);
    800045f4:	854a                	mv	a0,s2
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
}
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6902                	ld	s2,0(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000460a:	7179                	addi	sp,sp,-48
    8000460c:	f406                	sd	ra,40(sp)
    8000460e:	f022                	sd	s0,32(sp)
    80004610:	ec26                	sd	s1,24(sp)
    80004612:	e84a                	sd	s2,16(sp)
    80004614:	e44e                	sd	s3,8(sp)
    80004616:	1800                	addi	s0,sp,48
    80004618:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000461a:	00850913          	addi	s2,a0,8
    8000461e:	854a                	mv	a0,s2
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	5c4080e7          	jalr	1476(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004628:	409c                	lw	a5,0(s1)
    8000462a:	ef99                	bnez	a5,80004648 <holdingsleep+0x3e>
    8000462c:	4481                	li	s1,0
  release(&lk->lk);
    8000462e:	854a                	mv	a0,s2
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	668080e7          	jalr	1640(ra) # 80000c98 <release>
  return r;
}
    80004638:	8526                	mv	a0,s1
    8000463a:	70a2                	ld	ra,40(sp)
    8000463c:	7402                	ld	s0,32(sp)
    8000463e:	64e2                	ld	s1,24(sp)
    80004640:	6942                	ld	s2,16(sp)
    80004642:	69a2                	ld	s3,8(sp)
    80004644:	6145                	addi	sp,sp,48
    80004646:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004648:	0284a983          	lw	s3,40(s1)
    8000464c:	ffffd097          	auipc	ra,0xffffd
    80004650:	36c080e7          	jalr	876(ra) # 800019b8 <myproc>
    80004654:	5904                	lw	s1,48(a0)
    80004656:	413484b3          	sub	s1,s1,s3
    8000465a:	0014b493          	seqz	s1,s1
    8000465e:	bfc1                	j	8000462e <holdingsleep+0x24>

0000000080004660 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004660:	1141                	addi	sp,sp,-16
    80004662:	e406                	sd	ra,8(sp)
    80004664:	e022                	sd	s0,0(sp)
    80004666:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004668:	00004597          	auipc	a1,0x4
    8000466c:	05058593          	addi	a1,a1,80 # 800086b8 <syscalls+0x248>
    80004670:	00016517          	auipc	a0,0x16
    80004674:	eb850513          	addi	a0,a0,-328 # 8001a528 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	4dc080e7          	jalr	1244(ra) # 80000b54 <initlock>
}
    80004680:	60a2                	ld	ra,8(sp)
    80004682:	6402                	ld	s0,0(sp)
    80004684:	0141                	addi	sp,sp,16
    80004686:	8082                	ret

0000000080004688 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004688:	1101                	addi	sp,sp,-32
    8000468a:	ec06                	sd	ra,24(sp)
    8000468c:	e822                	sd	s0,16(sp)
    8000468e:	e426                	sd	s1,8(sp)
    80004690:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004692:	00016517          	auipc	a0,0x16
    80004696:	e9650513          	addi	a0,a0,-362 # 8001a528 <ftable>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	54a080e7          	jalr	1354(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a2:	00016497          	auipc	s1,0x16
    800046a6:	e9e48493          	addi	s1,s1,-354 # 8001a540 <ftable+0x18>
    800046aa:	00017717          	auipc	a4,0x17
    800046ae:	e3670713          	addi	a4,a4,-458 # 8001b4e0 <ftable+0xfb8>
    if(f->ref == 0){
    800046b2:	40dc                	lw	a5,4(s1)
    800046b4:	cf99                	beqz	a5,800046d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b6:	02848493          	addi	s1,s1,40
    800046ba:	fee49ce3          	bne	s1,a4,800046b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046be:	00016517          	auipc	a0,0x16
    800046c2:	e6a50513          	addi	a0,a0,-406 # 8001a528 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5d2080e7          	jalr	1490(ra) # 80000c98 <release>
  return 0;
    800046ce:	4481                	li	s1,0
    800046d0:	a819                	j	800046e6 <filealloc+0x5e>
      f->ref = 1;
    800046d2:	4785                	li	a5,1
    800046d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046d6:	00016517          	auipc	a0,0x16
    800046da:	e5250513          	addi	a0,a0,-430 # 8001a528 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5ba080e7          	jalr	1466(ra) # 80000c98 <release>
}
    800046e6:	8526                	mv	a0,s1
    800046e8:	60e2                	ld	ra,24(sp)
    800046ea:	6442                	ld	s0,16(sp)
    800046ec:	64a2                	ld	s1,8(sp)
    800046ee:	6105                	addi	sp,sp,32
    800046f0:	8082                	ret

00000000800046f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046f2:	1101                	addi	sp,sp,-32
    800046f4:	ec06                	sd	ra,24(sp)
    800046f6:	e822                	sd	s0,16(sp)
    800046f8:	e426                	sd	s1,8(sp)
    800046fa:	1000                	addi	s0,sp,32
    800046fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046fe:	00016517          	auipc	a0,0x16
    80004702:	e2a50513          	addi	a0,a0,-470 # 8001a528 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	4de080e7          	jalr	1246(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000470e:	40dc                	lw	a5,4(s1)
    80004710:	02f05263          	blez	a5,80004734 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004714:	2785                	addiw	a5,a5,1
    80004716:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004718:	00016517          	auipc	a0,0x16
    8000471c:	e1050513          	addi	a0,a0,-496 # 8001a528 <ftable>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	578080e7          	jalr	1400(ra) # 80000c98 <release>
  return f;
}
    80004728:	8526                	mv	a0,s1
    8000472a:	60e2                	ld	ra,24(sp)
    8000472c:	6442                	ld	s0,16(sp)
    8000472e:	64a2                	ld	s1,8(sp)
    80004730:	6105                	addi	sp,sp,32
    80004732:	8082                	ret
    panic("filedup");
    80004734:	00004517          	auipc	a0,0x4
    80004738:	f8c50513          	addi	a0,a0,-116 # 800086c0 <syscalls+0x250>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	e02080e7          	jalr	-510(ra) # 8000053e <panic>

0000000080004744 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004744:	7139                	addi	sp,sp,-64
    80004746:	fc06                	sd	ra,56(sp)
    80004748:	f822                	sd	s0,48(sp)
    8000474a:	f426                	sd	s1,40(sp)
    8000474c:	f04a                	sd	s2,32(sp)
    8000474e:	ec4e                	sd	s3,24(sp)
    80004750:	e852                	sd	s4,16(sp)
    80004752:	e456                	sd	s5,8(sp)
    80004754:	0080                	addi	s0,sp,64
    80004756:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004758:	00016517          	auipc	a0,0x16
    8000475c:	dd050513          	addi	a0,a0,-560 # 8001a528 <ftable>
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	484080e7          	jalr	1156(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004768:	40dc                	lw	a5,4(s1)
    8000476a:	06f05163          	blez	a5,800047cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000476e:	37fd                	addiw	a5,a5,-1
    80004770:	0007871b          	sext.w	a4,a5
    80004774:	c0dc                	sw	a5,4(s1)
    80004776:	06e04363          	bgtz	a4,800047dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000477a:	0004a903          	lw	s2,0(s1)
    8000477e:	0094ca83          	lbu	s5,9(s1)
    80004782:	0104ba03          	ld	s4,16(s1)
    80004786:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000478a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000478e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004792:	00016517          	auipc	a0,0x16
    80004796:	d9650513          	addi	a0,a0,-618 # 8001a528 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	4fe080e7          	jalr	1278(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047a2:	4785                	li	a5,1
    800047a4:	04f90d63          	beq	s2,a5,800047fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047a8:	3979                	addiw	s2,s2,-2
    800047aa:	4785                	li	a5,1
    800047ac:	0527e063          	bltu	a5,s2,800047ec <fileclose+0xa8>
    begin_op();
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	ac8080e7          	jalr	-1336(ra) # 80004278 <begin_op>
    iput(ff.ip);
    800047b8:	854e                	mv	a0,s3
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	2a6080e7          	jalr	678(ra) # 80003a60 <iput>
    end_op();
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	b36080e7          	jalr	-1226(ra) # 800042f8 <end_op>
    800047ca:	a00d                	j	800047ec <fileclose+0xa8>
    panic("fileclose");
    800047cc:	00004517          	auipc	a0,0x4
    800047d0:	efc50513          	addi	a0,a0,-260 # 800086c8 <syscalls+0x258>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	d6a080e7          	jalr	-662(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047dc:	00016517          	auipc	a0,0x16
    800047e0:	d4c50513          	addi	a0,a0,-692 # 8001a528 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4b4080e7          	jalr	1204(ra) # 80000c98 <release>
  }
}
    800047ec:	70e2                	ld	ra,56(sp)
    800047ee:	7442                	ld	s0,48(sp)
    800047f0:	74a2                	ld	s1,40(sp)
    800047f2:	7902                	ld	s2,32(sp)
    800047f4:	69e2                	ld	s3,24(sp)
    800047f6:	6a42                	ld	s4,16(sp)
    800047f8:	6aa2                	ld	s5,8(sp)
    800047fa:	6121                	addi	sp,sp,64
    800047fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047fe:	85d6                	mv	a1,s5
    80004800:	8552                	mv	a0,s4
    80004802:	00000097          	auipc	ra,0x0
    80004806:	34c080e7          	jalr	844(ra) # 80004b4e <pipeclose>
    8000480a:	b7cd                	j	800047ec <fileclose+0xa8>

000000008000480c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000480c:	715d                	addi	sp,sp,-80
    8000480e:	e486                	sd	ra,72(sp)
    80004810:	e0a2                	sd	s0,64(sp)
    80004812:	fc26                	sd	s1,56(sp)
    80004814:	f84a                	sd	s2,48(sp)
    80004816:	f44e                	sd	s3,40(sp)
    80004818:	0880                	addi	s0,sp,80
    8000481a:	84aa                	mv	s1,a0
    8000481c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000481e:	ffffd097          	auipc	ra,0xffffd
    80004822:	19a080e7          	jalr	410(ra) # 800019b8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004826:	409c                	lw	a5,0(s1)
    80004828:	37f9                	addiw	a5,a5,-2
    8000482a:	4705                	li	a4,1
    8000482c:	04f76763          	bltu	a4,a5,8000487a <filestat+0x6e>
    80004830:	892a                	mv	s2,a0
    ilock(f->ip);
    80004832:	6c88                	ld	a0,24(s1)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	072080e7          	jalr	114(ra) # 800038a6 <ilock>
    stati(f->ip, &st);
    8000483c:	fb840593          	addi	a1,s0,-72
    80004840:	6c88                	ld	a0,24(s1)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	2ee080e7          	jalr	750(ra) # 80003b30 <stati>
    iunlock(f->ip);
    8000484a:	6c88                	ld	a0,24(s1)
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	11c080e7          	jalr	284(ra) # 80003968 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004854:	46e1                	li	a3,24
    80004856:	fb840613          	addi	a2,s0,-72
    8000485a:	85ce                	mv	a1,s3
    8000485c:	05093503          	ld	a0,80(s2)
    80004860:	ffffd097          	auipc	ra,0xffffd
    80004864:	e1a080e7          	jalr	-486(ra) # 8000167a <copyout>
    80004868:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000486c:	60a6                	ld	ra,72(sp)
    8000486e:	6406                	ld	s0,64(sp)
    80004870:	74e2                	ld	s1,56(sp)
    80004872:	7942                	ld	s2,48(sp)
    80004874:	79a2                	ld	s3,40(sp)
    80004876:	6161                	addi	sp,sp,80
    80004878:	8082                	ret
  return -1;
    8000487a:	557d                	li	a0,-1
    8000487c:	bfc5                	j	8000486c <filestat+0x60>

000000008000487e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000487e:	7179                	addi	sp,sp,-48
    80004880:	f406                	sd	ra,40(sp)
    80004882:	f022                	sd	s0,32(sp)
    80004884:	ec26                	sd	s1,24(sp)
    80004886:	e84a                	sd	s2,16(sp)
    80004888:	e44e                	sd	s3,8(sp)
    8000488a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000488c:	00854783          	lbu	a5,8(a0)
    80004890:	c3d5                	beqz	a5,80004934 <fileread+0xb6>
    80004892:	84aa                	mv	s1,a0
    80004894:	89ae                	mv	s3,a1
    80004896:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004898:	411c                	lw	a5,0(a0)
    8000489a:	4705                	li	a4,1
    8000489c:	04e78963          	beq	a5,a4,800048ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048a0:	470d                	li	a4,3
    800048a2:	04e78d63          	beq	a5,a4,800048fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a6:	4709                	li	a4,2
    800048a8:	06e79e63          	bne	a5,a4,80004924 <fileread+0xa6>
    ilock(f->ip);
    800048ac:	6d08                	ld	a0,24(a0)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	ff8080e7          	jalr	-8(ra) # 800038a6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048b6:	874a                	mv	a4,s2
    800048b8:	5094                	lw	a3,32(s1)
    800048ba:	864e                	mv	a2,s3
    800048bc:	4585                	li	a1,1
    800048be:	6c88                	ld	a0,24(s1)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	29a080e7          	jalr	666(ra) # 80003b5a <readi>
    800048c8:	892a                	mv	s2,a0
    800048ca:	00a05563          	blez	a0,800048d4 <fileread+0x56>
      f->off += r;
    800048ce:	509c                	lw	a5,32(s1)
    800048d0:	9fa9                	addw	a5,a5,a0
    800048d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048d4:	6c88                	ld	a0,24(s1)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	092080e7          	jalr	146(ra) # 80003968 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048de:	854a                	mv	a0,s2
    800048e0:	70a2                	ld	ra,40(sp)
    800048e2:	7402                	ld	s0,32(sp)
    800048e4:	64e2                	ld	s1,24(sp)
    800048e6:	6942                	ld	s2,16(sp)
    800048e8:	69a2                	ld	s3,8(sp)
    800048ea:	6145                	addi	sp,sp,48
    800048ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048ee:	6908                	ld	a0,16(a0)
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	3c8080e7          	jalr	968(ra) # 80004cb8 <piperead>
    800048f8:	892a                	mv	s2,a0
    800048fa:	b7d5                	j	800048de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048fc:	02451783          	lh	a5,36(a0)
    80004900:	03079693          	slli	a3,a5,0x30
    80004904:	92c1                	srli	a3,a3,0x30
    80004906:	4725                	li	a4,9
    80004908:	02d76863          	bltu	a4,a3,80004938 <fileread+0xba>
    8000490c:	0792                	slli	a5,a5,0x4
    8000490e:	00016717          	auipc	a4,0x16
    80004912:	b7a70713          	addi	a4,a4,-1158 # 8001a488 <devsw>
    80004916:	97ba                	add	a5,a5,a4
    80004918:	639c                	ld	a5,0(a5)
    8000491a:	c38d                	beqz	a5,8000493c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000491c:	4505                	li	a0,1
    8000491e:	9782                	jalr	a5
    80004920:	892a                	mv	s2,a0
    80004922:	bf75                	j	800048de <fileread+0x60>
    panic("fileread");
    80004924:	00004517          	auipc	a0,0x4
    80004928:	db450513          	addi	a0,a0,-588 # 800086d8 <syscalls+0x268>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	c12080e7          	jalr	-1006(ra) # 8000053e <panic>
    return -1;
    80004934:	597d                	li	s2,-1
    80004936:	b765                	j	800048de <fileread+0x60>
      return -1;
    80004938:	597d                	li	s2,-1
    8000493a:	b755                	j	800048de <fileread+0x60>
    8000493c:	597d                	li	s2,-1
    8000493e:	b745                	j	800048de <fileread+0x60>

0000000080004940 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004940:	715d                	addi	sp,sp,-80
    80004942:	e486                	sd	ra,72(sp)
    80004944:	e0a2                	sd	s0,64(sp)
    80004946:	fc26                	sd	s1,56(sp)
    80004948:	f84a                	sd	s2,48(sp)
    8000494a:	f44e                	sd	s3,40(sp)
    8000494c:	f052                	sd	s4,32(sp)
    8000494e:	ec56                	sd	s5,24(sp)
    80004950:	e85a                	sd	s6,16(sp)
    80004952:	e45e                	sd	s7,8(sp)
    80004954:	e062                	sd	s8,0(sp)
    80004956:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004958:	00954783          	lbu	a5,9(a0)
    8000495c:	10078663          	beqz	a5,80004a68 <filewrite+0x128>
    80004960:	892a                	mv	s2,a0
    80004962:	8aae                	mv	s5,a1
    80004964:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004966:	411c                	lw	a5,0(a0)
    80004968:	4705                	li	a4,1
    8000496a:	02e78263          	beq	a5,a4,8000498e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000496e:	470d                	li	a4,3
    80004970:	02e78663          	beq	a5,a4,8000499c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004974:	4709                	li	a4,2
    80004976:	0ee79163          	bne	a5,a4,80004a58 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000497a:	0ac05d63          	blez	a2,80004a34 <filewrite+0xf4>
    int i = 0;
    8000497e:	4981                	li	s3,0
    80004980:	6b05                	lui	s6,0x1
    80004982:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004986:	6b85                	lui	s7,0x1
    80004988:	c00b8b9b          	addiw	s7,s7,-1024
    8000498c:	a861                	j	80004a24 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000498e:	6908                	ld	a0,16(a0)
    80004990:	00000097          	auipc	ra,0x0
    80004994:	22e080e7          	jalr	558(ra) # 80004bbe <pipewrite>
    80004998:	8a2a                	mv	s4,a0
    8000499a:	a045                	j	80004a3a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000499c:	02451783          	lh	a5,36(a0)
    800049a0:	03079693          	slli	a3,a5,0x30
    800049a4:	92c1                	srli	a3,a3,0x30
    800049a6:	4725                	li	a4,9
    800049a8:	0cd76263          	bltu	a4,a3,80004a6c <filewrite+0x12c>
    800049ac:	0792                	slli	a5,a5,0x4
    800049ae:	00016717          	auipc	a4,0x16
    800049b2:	ada70713          	addi	a4,a4,-1318 # 8001a488 <devsw>
    800049b6:	97ba                	add	a5,a5,a4
    800049b8:	679c                	ld	a5,8(a5)
    800049ba:	cbdd                	beqz	a5,80004a70 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049bc:	4505                	li	a0,1
    800049be:	9782                	jalr	a5
    800049c0:	8a2a                	mv	s4,a0
    800049c2:	a8a5                	j	80004a3a <filewrite+0xfa>
    800049c4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	8b0080e7          	jalr	-1872(ra) # 80004278 <begin_op>
      ilock(f->ip);
    800049d0:	01893503          	ld	a0,24(s2)
    800049d4:	fffff097          	auipc	ra,0xfffff
    800049d8:	ed2080e7          	jalr	-302(ra) # 800038a6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049dc:	8762                	mv	a4,s8
    800049de:	02092683          	lw	a3,32(s2)
    800049e2:	01598633          	add	a2,s3,s5
    800049e6:	4585                	li	a1,1
    800049e8:	01893503          	ld	a0,24(s2)
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	266080e7          	jalr	614(ra) # 80003c52 <writei>
    800049f4:	84aa                	mv	s1,a0
    800049f6:	00a05763          	blez	a0,80004a04 <filewrite+0xc4>
        f->off += r;
    800049fa:	02092783          	lw	a5,32(s2)
    800049fe:	9fa9                	addw	a5,a5,a0
    80004a00:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a04:	01893503          	ld	a0,24(s2)
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	f60080e7          	jalr	-160(ra) # 80003968 <iunlock>
      end_op();
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	8e8080e7          	jalr	-1816(ra) # 800042f8 <end_op>

      if(r != n1){
    80004a18:	009c1f63          	bne	s8,s1,80004a36 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a1c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a20:	0149db63          	bge	s3,s4,80004a36 <filewrite+0xf6>
      int n1 = n - i;
    80004a24:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a28:	84be                	mv	s1,a5
    80004a2a:	2781                	sext.w	a5,a5
    80004a2c:	f8fb5ce3          	bge	s6,a5,800049c4 <filewrite+0x84>
    80004a30:	84de                	mv	s1,s7
    80004a32:	bf49                	j	800049c4 <filewrite+0x84>
    int i = 0;
    80004a34:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a36:	013a1f63          	bne	s4,s3,80004a54 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a3a:	8552                	mv	a0,s4
    80004a3c:	60a6                	ld	ra,72(sp)
    80004a3e:	6406                	ld	s0,64(sp)
    80004a40:	74e2                	ld	s1,56(sp)
    80004a42:	7942                	ld	s2,48(sp)
    80004a44:	79a2                	ld	s3,40(sp)
    80004a46:	7a02                	ld	s4,32(sp)
    80004a48:	6ae2                	ld	s5,24(sp)
    80004a4a:	6b42                	ld	s6,16(sp)
    80004a4c:	6ba2                	ld	s7,8(sp)
    80004a4e:	6c02                	ld	s8,0(sp)
    80004a50:	6161                	addi	sp,sp,80
    80004a52:	8082                	ret
    ret = (i == n ? n : -1);
    80004a54:	5a7d                	li	s4,-1
    80004a56:	b7d5                	j	80004a3a <filewrite+0xfa>
    panic("filewrite");
    80004a58:	00004517          	auipc	a0,0x4
    80004a5c:	c9050513          	addi	a0,a0,-880 # 800086e8 <syscalls+0x278>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	ade080e7          	jalr	-1314(ra) # 8000053e <panic>
    return -1;
    80004a68:	5a7d                	li	s4,-1
    80004a6a:	bfc1                	j	80004a3a <filewrite+0xfa>
      return -1;
    80004a6c:	5a7d                	li	s4,-1
    80004a6e:	b7f1                	j	80004a3a <filewrite+0xfa>
    80004a70:	5a7d                	li	s4,-1
    80004a72:	b7e1                	j	80004a3a <filewrite+0xfa>

0000000080004a74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a74:	7179                	addi	sp,sp,-48
    80004a76:	f406                	sd	ra,40(sp)
    80004a78:	f022                	sd	s0,32(sp)
    80004a7a:	ec26                	sd	s1,24(sp)
    80004a7c:	e84a                	sd	s2,16(sp)
    80004a7e:	e44e                	sd	s3,8(sp)
    80004a80:	e052                	sd	s4,0(sp)
    80004a82:	1800                	addi	s0,sp,48
    80004a84:	84aa                	mv	s1,a0
    80004a86:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a88:	0005b023          	sd	zero,0(a1)
    80004a8c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	bf8080e7          	jalr	-1032(ra) # 80004688 <filealloc>
    80004a98:	e088                	sd	a0,0(s1)
    80004a9a:	c551                	beqz	a0,80004b26 <pipealloc+0xb2>
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	bec080e7          	jalr	-1044(ra) # 80004688 <filealloc>
    80004aa4:	00aa3023          	sd	a0,0(s4)
    80004aa8:	c92d                	beqz	a0,80004b1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	04a080e7          	jalr	74(ra) # 80000af4 <kalloc>
    80004ab2:	892a                	mv	s2,a0
    80004ab4:	c125                	beqz	a0,80004b14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ab6:	4985                	li	s3,1
    80004ab8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004abc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ac0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ac4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ac8:	00004597          	auipc	a1,0x4
    80004acc:	c3058593          	addi	a1,a1,-976 # 800086f8 <syscalls+0x288>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ad8:	609c                	ld	a5,0(s1)
    80004ada:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ade:	609c                	ld	a5,0(s1)
    80004ae0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ae4:	609c                	ld	a5,0(s1)
    80004ae6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aea:	609c                	ld	a5,0(s1)
    80004aec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004af0:	000a3783          	ld	a5,0(s4)
    80004af4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004af8:	000a3783          	ld	a5,0(s4)
    80004afc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b00:	000a3783          	ld	a5,0(s4)
    80004b04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b08:	000a3783          	ld	a5,0(s4)
    80004b0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b10:	4501                	li	a0,0
    80004b12:	a025                	j	80004b3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b14:	6088                	ld	a0,0(s1)
    80004b16:	e501                	bnez	a0,80004b1e <pipealloc+0xaa>
    80004b18:	a039                	j	80004b26 <pipealloc+0xb2>
    80004b1a:	6088                	ld	a0,0(s1)
    80004b1c:	c51d                	beqz	a0,80004b4a <pipealloc+0xd6>
    fileclose(*f0);
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	c26080e7          	jalr	-986(ra) # 80004744 <fileclose>
  if(*f1)
    80004b26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b2a:	557d                	li	a0,-1
  if(*f1)
    80004b2c:	c799                	beqz	a5,80004b3a <pipealloc+0xc6>
    fileclose(*f1);
    80004b2e:	853e                	mv	a0,a5
    80004b30:	00000097          	auipc	ra,0x0
    80004b34:	c14080e7          	jalr	-1004(ra) # 80004744 <fileclose>
  return -1;
    80004b38:	557d                	li	a0,-1
}
    80004b3a:	70a2                	ld	ra,40(sp)
    80004b3c:	7402                	ld	s0,32(sp)
    80004b3e:	64e2                	ld	s1,24(sp)
    80004b40:	6942                	ld	s2,16(sp)
    80004b42:	69a2                	ld	s3,8(sp)
    80004b44:	6a02                	ld	s4,0(sp)
    80004b46:	6145                	addi	sp,sp,48
    80004b48:	8082                	ret
  return -1;
    80004b4a:	557d                	li	a0,-1
    80004b4c:	b7fd                	j	80004b3a <pipealloc+0xc6>

0000000080004b4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b4e:	1101                	addi	sp,sp,-32
    80004b50:	ec06                	sd	ra,24(sp)
    80004b52:	e822                	sd	s0,16(sp)
    80004b54:	e426                	sd	s1,8(sp)
    80004b56:	e04a                	sd	s2,0(sp)
    80004b58:	1000                	addi	s0,sp,32
    80004b5a:	84aa                	mv	s1,a0
    80004b5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	086080e7          	jalr	134(ra) # 80000be4 <acquire>
  if(writable){
    80004b66:	02090d63          	beqz	s2,80004ba0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b6e:	21848513          	addi	a0,s1,536
    80004b72:	ffffe097          	auipc	ra,0xffffe
    80004b76:	860080e7          	jalr	-1952(ra) # 800023d2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b7a:	2204b783          	ld	a5,544(s1)
    80004b7e:	eb95                	bnez	a5,80004bb2 <pipeclose+0x64>
    release(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	116080e7          	jalr	278(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b8a:	8526                	mv	a0,s1
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	e6c080e7          	jalr	-404(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b94:	60e2                	ld	ra,24(sp)
    80004b96:	6442                	ld	s0,16(sp)
    80004b98:	64a2                	ld	s1,8(sp)
    80004b9a:	6902                	ld	s2,0(sp)
    80004b9c:	6105                	addi	sp,sp,32
    80004b9e:	8082                	ret
    pi->readopen = 0;
    80004ba0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ba4:	21c48513          	addi	a0,s1,540
    80004ba8:	ffffe097          	auipc	ra,0xffffe
    80004bac:	82a080e7          	jalr	-2006(ra) # 800023d2 <wakeup>
    80004bb0:	b7e9                	j	80004b7a <pipeclose+0x2c>
    release(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0e4080e7          	jalr	228(ra) # 80000c98 <release>
}
    80004bbc:	bfe1                	j	80004b94 <pipeclose+0x46>

0000000080004bbe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bbe:	7159                	addi	sp,sp,-112
    80004bc0:	f486                	sd	ra,104(sp)
    80004bc2:	f0a2                	sd	s0,96(sp)
    80004bc4:	eca6                	sd	s1,88(sp)
    80004bc6:	e8ca                	sd	s2,80(sp)
    80004bc8:	e4ce                	sd	s3,72(sp)
    80004bca:	e0d2                	sd	s4,64(sp)
    80004bcc:	fc56                	sd	s5,56(sp)
    80004bce:	f85a                	sd	s6,48(sp)
    80004bd0:	f45e                	sd	s7,40(sp)
    80004bd2:	f062                	sd	s8,32(sp)
    80004bd4:	ec66                	sd	s9,24(sp)
    80004bd6:	1880                	addi	s0,sp,112
    80004bd8:	84aa                	mv	s1,a0
    80004bda:	8aae                	mv	s5,a1
    80004bdc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	dda080e7          	jalr	-550(ra) # 800019b8 <myproc>
    80004be6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	ffa080e7          	jalr	-6(ra) # 80000be4 <acquire>
  while(i < n){
    80004bf2:	0d405163          	blez	s4,80004cb4 <pipewrite+0xf6>
    80004bf6:	8ba6                	mv	s7,s1
  int i = 0;
    80004bf8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bfa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bfc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c00:	21c48c13          	addi	s8,s1,540
    80004c04:	a08d                	j	80004c66 <pipewrite+0xa8>
      release(&pi->lock);
    80004c06:	8526                	mv	a0,s1
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	090080e7          	jalr	144(ra) # 80000c98 <release>
      return -1;
    80004c10:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c12:	854a                	mv	a0,s2
    80004c14:	70a6                	ld	ra,104(sp)
    80004c16:	7406                	ld	s0,96(sp)
    80004c18:	64e6                	ld	s1,88(sp)
    80004c1a:	6946                	ld	s2,80(sp)
    80004c1c:	69a6                	ld	s3,72(sp)
    80004c1e:	6a06                	ld	s4,64(sp)
    80004c20:	7ae2                	ld	s5,56(sp)
    80004c22:	7b42                	ld	s6,48(sp)
    80004c24:	7ba2                	ld	s7,40(sp)
    80004c26:	7c02                	ld	s8,32(sp)
    80004c28:	6ce2                	ld	s9,24(sp)
    80004c2a:	6165                	addi	sp,sp,112
    80004c2c:	8082                	ret
      wakeup(&pi->nread);
    80004c2e:	8566                	mv	a0,s9
    80004c30:	ffffd097          	auipc	ra,0xffffd
    80004c34:	7a2080e7          	jalr	1954(ra) # 800023d2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c38:	85de                	mv	a1,s7
    80004c3a:	8562                	mv	a0,s8
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	60a080e7          	jalr	1546(ra) # 80002246 <sleep>
    80004c44:	a839                	j	80004c62 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c46:	21c4a783          	lw	a5,540(s1)
    80004c4a:	0017871b          	addiw	a4,a5,1
    80004c4e:	20e4ae23          	sw	a4,540(s1)
    80004c52:	1ff7f793          	andi	a5,a5,511
    80004c56:	97a6                	add	a5,a5,s1
    80004c58:	f9f44703          	lbu	a4,-97(s0)
    80004c5c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c60:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c62:	03495d63          	bge	s2,s4,80004c9c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c66:	2204a783          	lw	a5,544(s1)
    80004c6a:	dfd1                	beqz	a5,80004c06 <pipewrite+0x48>
    80004c6c:	0289a783          	lw	a5,40(s3)
    80004c70:	fbd9                	bnez	a5,80004c06 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c72:	2184a783          	lw	a5,536(s1)
    80004c76:	21c4a703          	lw	a4,540(s1)
    80004c7a:	2007879b          	addiw	a5,a5,512
    80004c7e:	faf708e3          	beq	a4,a5,80004c2e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c82:	4685                	li	a3,1
    80004c84:	01590633          	add	a2,s2,s5
    80004c88:	f9f40593          	addi	a1,s0,-97
    80004c8c:	0509b503          	ld	a0,80(s3)
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	a76080e7          	jalr	-1418(ra) # 80001706 <copyin>
    80004c98:	fb6517e3          	bne	a0,s6,80004c46 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c9c:	21848513          	addi	a0,s1,536
    80004ca0:	ffffd097          	auipc	ra,0xffffd
    80004ca4:	732080e7          	jalr	1842(ra) # 800023d2 <wakeup>
  release(&pi->lock);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	fee080e7          	jalr	-18(ra) # 80000c98 <release>
  return i;
    80004cb2:	b785                	j	80004c12 <pipewrite+0x54>
  int i = 0;
    80004cb4:	4901                	li	s2,0
    80004cb6:	b7dd                	j	80004c9c <pipewrite+0xde>

0000000080004cb8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cb8:	715d                	addi	sp,sp,-80
    80004cba:	e486                	sd	ra,72(sp)
    80004cbc:	e0a2                	sd	s0,64(sp)
    80004cbe:	fc26                	sd	s1,56(sp)
    80004cc0:	f84a                	sd	s2,48(sp)
    80004cc2:	f44e                	sd	s3,40(sp)
    80004cc4:	f052                	sd	s4,32(sp)
    80004cc6:	ec56                	sd	s5,24(sp)
    80004cc8:	e85a                	sd	s6,16(sp)
    80004cca:	0880                	addi	s0,sp,80
    80004ccc:	84aa                	mv	s1,a0
    80004cce:	892e                	mv	s2,a1
    80004cd0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	ce6080e7          	jalr	-794(ra) # 800019b8 <myproc>
    80004cda:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cdc:	8b26                	mv	s6,s1
    80004cde:	8526                	mv	a0,s1
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	f04080e7          	jalr	-252(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce8:	2184a703          	lw	a4,536(s1)
    80004cec:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf4:	02f71463          	bne	a4,a5,80004d1c <piperead+0x64>
    80004cf8:	2244a783          	lw	a5,548(s1)
    80004cfc:	c385                	beqz	a5,80004d1c <piperead+0x64>
    if(pr->killed){
    80004cfe:	028a2783          	lw	a5,40(s4)
    80004d02:	ebc1                	bnez	a5,80004d92 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d04:	85da                	mv	a1,s6
    80004d06:	854e                	mv	a0,s3
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	53e080e7          	jalr	1342(ra) # 80002246 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d10:	2184a703          	lw	a4,536(s1)
    80004d14:	21c4a783          	lw	a5,540(s1)
    80004d18:	fef700e3          	beq	a4,a5,80004cf8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d1c:	09505263          	blez	s5,80004da0 <piperead+0xe8>
    80004d20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d22:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d24:	2184a783          	lw	a5,536(s1)
    80004d28:	21c4a703          	lw	a4,540(s1)
    80004d2c:	02f70d63          	beq	a4,a5,80004d66 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d30:	0017871b          	addiw	a4,a5,1
    80004d34:	20e4ac23          	sw	a4,536(s1)
    80004d38:	1ff7f793          	andi	a5,a5,511
    80004d3c:	97a6                	add	a5,a5,s1
    80004d3e:	0187c783          	lbu	a5,24(a5)
    80004d42:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d46:	4685                	li	a3,1
    80004d48:	fbf40613          	addi	a2,s0,-65
    80004d4c:	85ca                	mv	a1,s2
    80004d4e:	050a3503          	ld	a0,80(s4)
    80004d52:	ffffd097          	auipc	ra,0xffffd
    80004d56:	928080e7          	jalr	-1752(ra) # 8000167a <copyout>
    80004d5a:	01650663          	beq	a0,s6,80004d66 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d5e:	2985                	addiw	s3,s3,1
    80004d60:	0905                	addi	s2,s2,1
    80004d62:	fd3a91e3          	bne	s5,s3,80004d24 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d66:	21c48513          	addi	a0,s1,540
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	668080e7          	jalr	1640(ra) # 800023d2 <wakeup>
  release(&pi->lock);
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
  return i;
}
    80004d7c:	854e                	mv	a0,s3
    80004d7e:	60a6                	ld	ra,72(sp)
    80004d80:	6406                	ld	s0,64(sp)
    80004d82:	74e2                	ld	s1,56(sp)
    80004d84:	7942                	ld	s2,48(sp)
    80004d86:	79a2                	ld	s3,40(sp)
    80004d88:	7a02                	ld	s4,32(sp)
    80004d8a:	6ae2                	ld	s5,24(sp)
    80004d8c:	6b42                	ld	s6,16(sp)
    80004d8e:	6161                	addi	sp,sp,80
    80004d90:	8082                	ret
      release(&pi->lock);
    80004d92:	8526                	mv	a0,s1
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	f04080e7          	jalr	-252(ra) # 80000c98 <release>
      return -1;
    80004d9c:	59fd                	li	s3,-1
    80004d9e:	bff9                	j	80004d7c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004da0:	4981                	li	s3,0
    80004da2:	b7d1                	j	80004d66 <piperead+0xae>

0000000080004da4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004da4:	df010113          	addi	sp,sp,-528
    80004da8:	20113423          	sd	ra,520(sp)
    80004dac:	20813023          	sd	s0,512(sp)
    80004db0:	ffa6                	sd	s1,504(sp)
    80004db2:	fbca                	sd	s2,496(sp)
    80004db4:	f7ce                	sd	s3,488(sp)
    80004db6:	f3d2                	sd	s4,480(sp)
    80004db8:	efd6                	sd	s5,472(sp)
    80004dba:	ebda                	sd	s6,464(sp)
    80004dbc:	e7de                	sd	s7,456(sp)
    80004dbe:	e3e2                	sd	s8,448(sp)
    80004dc0:	ff66                	sd	s9,440(sp)
    80004dc2:	fb6a                	sd	s10,432(sp)
    80004dc4:	f76e                	sd	s11,424(sp)
    80004dc6:	0c00                	addi	s0,sp,528
    80004dc8:	84aa                	mv	s1,a0
    80004dca:	dea43c23          	sd	a0,-520(s0)
    80004dce:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	be6080e7          	jalr	-1050(ra) # 800019b8 <myproc>
    80004dda:	892a                	mv	s2,a0

  begin_op();
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	49c080e7          	jalr	1180(ra) # 80004278 <begin_op>

  if((ip = namei(path)) == 0){
    80004de4:	8526                	mv	a0,s1
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	276080e7          	jalr	630(ra) # 8000405c <namei>
    80004dee:	c92d                	beqz	a0,80004e60 <exec+0xbc>
    80004df0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	ab4080e7          	jalr	-1356(ra) # 800038a6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dfa:	04000713          	li	a4,64
    80004dfe:	4681                	li	a3,0
    80004e00:	e5040613          	addi	a2,s0,-432
    80004e04:	4581                	li	a1,0
    80004e06:	8526                	mv	a0,s1
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	d52080e7          	jalr	-686(ra) # 80003b5a <readi>
    80004e10:	04000793          	li	a5,64
    80004e14:	00f51a63          	bne	a0,a5,80004e28 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e18:	e5042703          	lw	a4,-432(s0)
    80004e1c:	464c47b7          	lui	a5,0x464c4
    80004e20:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e24:	04f70463          	beq	a4,a5,80004e6c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	cde080e7          	jalr	-802(ra) # 80003b08 <iunlockput>
    end_op();
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	4c6080e7          	jalr	1222(ra) # 800042f8 <end_op>
  }
  return -1;
    80004e3a:	557d                	li	a0,-1
}
    80004e3c:	20813083          	ld	ra,520(sp)
    80004e40:	20013403          	ld	s0,512(sp)
    80004e44:	74fe                	ld	s1,504(sp)
    80004e46:	795e                	ld	s2,496(sp)
    80004e48:	79be                	ld	s3,488(sp)
    80004e4a:	7a1e                	ld	s4,480(sp)
    80004e4c:	6afe                	ld	s5,472(sp)
    80004e4e:	6b5e                	ld	s6,464(sp)
    80004e50:	6bbe                	ld	s7,456(sp)
    80004e52:	6c1e                	ld	s8,448(sp)
    80004e54:	7cfa                	ld	s9,440(sp)
    80004e56:	7d5a                	ld	s10,432(sp)
    80004e58:	7dba                	ld	s11,424(sp)
    80004e5a:	21010113          	addi	sp,sp,528
    80004e5e:	8082                	ret
    end_op();
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	498080e7          	jalr	1176(ra) # 800042f8 <end_op>
    return -1;
    80004e68:	557d                	li	a0,-1
    80004e6a:	bfc9                	j	80004e3c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e6c:	854a                	mv	a0,s2
    80004e6e:	ffffd097          	auipc	ra,0xffffd
    80004e72:	c0e080e7          	jalr	-1010(ra) # 80001a7c <proc_pagetable>
    80004e76:	8baa                	mv	s7,a0
    80004e78:	d945                	beqz	a0,80004e28 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e7a:	e7042983          	lw	s3,-400(s0)
    80004e7e:	e8845783          	lhu	a5,-376(s0)
    80004e82:	c7ad                	beqz	a5,80004eec <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e84:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e86:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e88:	6c85                	lui	s9,0x1
    80004e8a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e8e:	def43823          	sd	a5,-528(s0)
    80004e92:	a42d                	j	800050bc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e94:	00004517          	auipc	a0,0x4
    80004e98:	86c50513          	addi	a0,a0,-1940 # 80008700 <syscalls+0x290>
    80004e9c:	ffffb097          	auipc	ra,0xffffb
    80004ea0:	6a2080e7          	jalr	1698(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ea4:	8756                	mv	a4,s5
    80004ea6:	012d86bb          	addw	a3,s11,s2
    80004eaa:	4581                	li	a1,0
    80004eac:	8526                	mv	a0,s1
    80004eae:	fffff097          	auipc	ra,0xfffff
    80004eb2:	cac080e7          	jalr	-852(ra) # 80003b5a <readi>
    80004eb6:	2501                	sext.w	a0,a0
    80004eb8:	1aaa9963          	bne	s5,a0,8000506a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ebc:	6785                	lui	a5,0x1
    80004ebe:	0127893b          	addw	s2,a5,s2
    80004ec2:	77fd                	lui	a5,0xfffff
    80004ec4:	01478a3b          	addw	s4,a5,s4
    80004ec8:	1f897163          	bgeu	s2,s8,800050aa <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ecc:	02091593          	slli	a1,s2,0x20
    80004ed0:	9181                	srli	a1,a1,0x20
    80004ed2:	95ea                	add	a1,a1,s10
    80004ed4:	855e                	mv	a0,s7
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	1a0080e7          	jalr	416(ra) # 80001076 <walkaddr>
    80004ede:	862a                	mv	a2,a0
    if(pa == 0)
    80004ee0:	d955                	beqz	a0,80004e94 <exec+0xf0>
      n = PGSIZE;
    80004ee2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ee4:	fd9a70e3          	bgeu	s4,s9,80004ea4 <exec+0x100>
      n = sz - i;
    80004ee8:	8ad2                	mv	s5,s4
    80004eea:	bf6d                	j	80004ea4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eec:	4901                	li	s2,0
  iunlockput(ip);
    80004eee:	8526                	mv	a0,s1
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	c18080e7          	jalr	-1000(ra) # 80003b08 <iunlockput>
  end_op();
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	400080e7          	jalr	1024(ra) # 800042f8 <end_op>
  p = myproc();
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	ab8080e7          	jalr	-1352(ra) # 800019b8 <myproc>
    80004f08:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f0a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f0e:	6785                	lui	a5,0x1
    80004f10:	17fd                	addi	a5,a5,-1
    80004f12:	993e                	add	s2,s2,a5
    80004f14:	757d                	lui	a0,0xfffff
    80004f16:	00a977b3          	and	a5,s2,a0
    80004f1a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f1e:	6609                	lui	a2,0x2
    80004f20:	963e                	add	a2,a2,a5
    80004f22:	85be                	mv	a1,a5
    80004f24:	855e                	mv	a0,s7
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	504080e7          	jalr	1284(ra) # 8000142a <uvmalloc>
    80004f2e:	8b2a                	mv	s6,a0
  ip = 0;
    80004f30:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f32:	12050c63          	beqz	a0,8000506a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f36:	75f9                	lui	a1,0xffffe
    80004f38:	95aa                	add	a1,a1,a0
    80004f3a:	855e                	mv	a0,s7
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	70c080e7          	jalr	1804(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f44:	7c7d                	lui	s8,0xfffff
    80004f46:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f48:	e0043783          	ld	a5,-512(s0)
    80004f4c:	6388                	ld	a0,0(a5)
    80004f4e:	c535                	beqz	a0,80004fba <exec+0x216>
    80004f50:	e9040993          	addi	s3,s0,-368
    80004f54:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f58:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	f0a080e7          	jalr	-246(ra) # 80000e64 <strlen>
    80004f62:	2505                	addiw	a0,a0,1
    80004f64:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f68:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f6c:	13896363          	bltu	s2,s8,80005092 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f70:	e0043d83          	ld	s11,-512(s0)
    80004f74:	000dba03          	ld	s4,0(s11)
    80004f78:	8552                	mv	a0,s4
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	eea080e7          	jalr	-278(ra) # 80000e64 <strlen>
    80004f82:	0015069b          	addiw	a3,a0,1
    80004f86:	8652                	mv	a2,s4
    80004f88:	85ca                	mv	a1,s2
    80004f8a:	855e                	mv	a0,s7
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	6ee080e7          	jalr	1774(ra) # 8000167a <copyout>
    80004f94:	10054363          	bltz	a0,8000509a <exec+0x2f6>
    ustack[argc] = sp;
    80004f98:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f9c:	0485                	addi	s1,s1,1
    80004f9e:	008d8793          	addi	a5,s11,8
    80004fa2:	e0f43023          	sd	a5,-512(s0)
    80004fa6:	008db503          	ld	a0,8(s11)
    80004faa:	c911                	beqz	a0,80004fbe <exec+0x21a>
    if(argc >= MAXARG)
    80004fac:	09a1                	addi	s3,s3,8
    80004fae:	fb3c96e3          	bne	s9,s3,80004f5a <exec+0x1b6>
  sz = sz1;
    80004fb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb6:	4481                	li	s1,0
    80004fb8:	a84d                	j	8000506a <exec+0x2c6>
  sp = sz;
    80004fba:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fbc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fbe:	00349793          	slli	a5,s1,0x3
    80004fc2:	f9040713          	addi	a4,s0,-112
    80004fc6:	97ba                	add	a5,a5,a4
    80004fc8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fcc:	00148693          	addi	a3,s1,1
    80004fd0:	068e                	slli	a3,a3,0x3
    80004fd2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fd6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fda:	01897663          	bgeu	s2,s8,80004fe6 <exec+0x242>
  sz = sz1;
    80004fde:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe2:	4481                	li	s1,0
    80004fe4:	a059                	j	8000506a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fe6:	e9040613          	addi	a2,s0,-368
    80004fea:	85ca                	mv	a1,s2
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	68c080e7          	jalr	1676(ra) # 8000167a <copyout>
    80004ff6:	0a054663          	bltz	a0,800050a2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ffa:	058ab783          	ld	a5,88(s5)
    80004ffe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005002:	df843783          	ld	a5,-520(s0)
    80005006:	0007c703          	lbu	a4,0(a5)
    8000500a:	cf11                	beqz	a4,80005026 <exec+0x282>
    8000500c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000500e:	02f00693          	li	a3,47
    80005012:	a039                	j	80005020 <exec+0x27c>
      last = s+1;
    80005014:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005018:	0785                	addi	a5,a5,1
    8000501a:	fff7c703          	lbu	a4,-1(a5)
    8000501e:	c701                	beqz	a4,80005026 <exec+0x282>
    if(*s == '/')
    80005020:	fed71ce3          	bne	a4,a3,80005018 <exec+0x274>
    80005024:	bfc5                	j	80005014 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005026:	4641                	li	a2,16
    80005028:	df843583          	ld	a1,-520(s0)
    8000502c:	158a8513          	addi	a0,s5,344
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	e02080e7          	jalr	-510(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005038:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000503c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005040:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005044:	058ab783          	ld	a5,88(s5)
    80005048:	e6843703          	ld	a4,-408(s0)
    8000504c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000504e:	058ab783          	ld	a5,88(s5)
    80005052:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005056:	85ea                	mv	a1,s10
    80005058:	ffffd097          	auipc	ra,0xffffd
    8000505c:	ac0080e7          	jalr	-1344(ra) # 80001b18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005060:	0004851b          	sext.w	a0,s1
    80005064:	bbe1                	j	80004e3c <exec+0x98>
    80005066:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000506a:	e0843583          	ld	a1,-504(s0)
    8000506e:	855e                	mv	a0,s7
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	aa8080e7          	jalr	-1368(ra) # 80001b18 <proc_freepagetable>
  if(ip){
    80005078:	da0498e3          	bnez	s1,80004e28 <exec+0x84>
  return -1;
    8000507c:	557d                	li	a0,-1
    8000507e:	bb7d                	j	80004e3c <exec+0x98>
    80005080:	e1243423          	sd	s2,-504(s0)
    80005084:	b7dd                	j	8000506a <exec+0x2c6>
    80005086:	e1243423          	sd	s2,-504(s0)
    8000508a:	b7c5                	j	8000506a <exec+0x2c6>
    8000508c:	e1243423          	sd	s2,-504(s0)
    80005090:	bfe9                	j	8000506a <exec+0x2c6>
  sz = sz1;
    80005092:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005096:	4481                	li	s1,0
    80005098:	bfc9                	j	8000506a <exec+0x2c6>
  sz = sz1;
    8000509a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000509e:	4481                	li	s1,0
    800050a0:	b7e9                	j	8000506a <exec+0x2c6>
  sz = sz1;
    800050a2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a6:	4481                	li	s1,0
    800050a8:	b7c9                	j	8000506a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050aa:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ae:	2b05                	addiw	s6,s6,1
    800050b0:	0389899b          	addiw	s3,s3,56
    800050b4:	e8845783          	lhu	a5,-376(s0)
    800050b8:	e2fb5be3          	bge	s6,a5,80004eee <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050bc:	2981                	sext.w	s3,s3
    800050be:	03800713          	li	a4,56
    800050c2:	86ce                	mv	a3,s3
    800050c4:	e1840613          	addi	a2,s0,-488
    800050c8:	4581                	li	a1,0
    800050ca:	8526                	mv	a0,s1
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	a8e080e7          	jalr	-1394(ra) # 80003b5a <readi>
    800050d4:	03800793          	li	a5,56
    800050d8:	f8f517e3          	bne	a0,a5,80005066 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050dc:	e1842783          	lw	a5,-488(s0)
    800050e0:	4705                	li	a4,1
    800050e2:	fce796e3          	bne	a5,a4,800050ae <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050e6:	e4043603          	ld	a2,-448(s0)
    800050ea:	e3843783          	ld	a5,-456(s0)
    800050ee:	f8f669e3          	bltu	a2,a5,80005080 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050f2:	e2843783          	ld	a5,-472(s0)
    800050f6:	963e                	add	a2,a2,a5
    800050f8:	f8f667e3          	bltu	a2,a5,80005086 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050fc:	85ca                	mv	a1,s2
    800050fe:	855e                	mv	a0,s7
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	32a080e7          	jalr	810(ra) # 8000142a <uvmalloc>
    80005108:	e0a43423          	sd	a0,-504(s0)
    8000510c:	d141                	beqz	a0,8000508c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000510e:	e2843d03          	ld	s10,-472(s0)
    80005112:	df043783          	ld	a5,-528(s0)
    80005116:	00fd77b3          	and	a5,s10,a5
    8000511a:	fba1                	bnez	a5,8000506a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000511c:	e2042d83          	lw	s11,-480(s0)
    80005120:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005124:	f80c03e3          	beqz	s8,800050aa <exec+0x306>
    80005128:	8a62                	mv	s4,s8
    8000512a:	4901                	li	s2,0
    8000512c:	b345                	j	80004ecc <exec+0x128>

000000008000512e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000512e:	7179                	addi	sp,sp,-48
    80005130:	f406                	sd	ra,40(sp)
    80005132:	f022                	sd	s0,32(sp)
    80005134:	ec26                	sd	s1,24(sp)
    80005136:	e84a                	sd	s2,16(sp)
    80005138:	1800                	addi	s0,sp,48
    8000513a:	892e                	mv	s2,a1
    8000513c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000513e:	fdc40593          	addi	a1,s0,-36
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	ba8080e7          	jalr	-1112(ra) # 80002cea <argint>
    8000514a:	04054063          	bltz	a0,8000518a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000514e:	fdc42703          	lw	a4,-36(s0)
    80005152:	47bd                	li	a5,15
    80005154:	02e7ed63          	bltu	a5,a4,8000518e <argfd+0x60>
    80005158:	ffffd097          	auipc	ra,0xffffd
    8000515c:	860080e7          	jalr	-1952(ra) # 800019b8 <myproc>
    80005160:	fdc42703          	lw	a4,-36(s0)
    80005164:	01a70793          	addi	a5,a4,26
    80005168:	078e                	slli	a5,a5,0x3
    8000516a:	953e                	add	a0,a0,a5
    8000516c:	611c                	ld	a5,0(a0)
    8000516e:	c395                	beqz	a5,80005192 <argfd+0x64>
    return -1;
  if(pfd)
    80005170:	00090463          	beqz	s2,80005178 <argfd+0x4a>
    *pfd = fd;
    80005174:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005178:	4501                	li	a0,0
  if(pf)
    8000517a:	c091                	beqz	s1,8000517e <argfd+0x50>
    *pf = f;
    8000517c:	e09c                	sd	a5,0(s1)
}
    8000517e:	70a2                	ld	ra,40(sp)
    80005180:	7402                	ld	s0,32(sp)
    80005182:	64e2                	ld	s1,24(sp)
    80005184:	6942                	ld	s2,16(sp)
    80005186:	6145                	addi	sp,sp,48
    80005188:	8082                	ret
    return -1;
    8000518a:	557d                	li	a0,-1
    8000518c:	bfcd                	j	8000517e <argfd+0x50>
    return -1;
    8000518e:	557d                	li	a0,-1
    80005190:	b7fd                	j	8000517e <argfd+0x50>
    80005192:	557d                	li	a0,-1
    80005194:	b7ed                	j	8000517e <argfd+0x50>

0000000080005196 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005196:	1101                	addi	sp,sp,-32
    80005198:	ec06                	sd	ra,24(sp)
    8000519a:	e822                	sd	s0,16(sp)
    8000519c:	e426                	sd	s1,8(sp)
    8000519e:	1000                	addi	s0,sp,32
    800051a0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	816080e7          	jalr	-2026(ra) # 800019b8 <myproc>
    800051aa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051ac:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    800051b0:	4501                	li	a0,0
    800051b2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051b4:	6398                	ld	a4,0(a5)
    800051b6:	cb19                	beqz	a4,800051cc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051b8:	2505                	addiw	a0,a0,1
    800051ba:	07a1                	addi	a5,a5,8
    800051bc:	fed51ce3          	bne	a0,a3,800051b4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051c0:	557d                	li	a0,-1
}
    800051c2:	60e2                	ld	ra,24(sp)
    800051c4:	6442                	ld	s0,16(sp)
    800051c6:	64a2                	ld	s1,8(sp)
    800051c8:	6105                	addi	sp,sp,32
    800051ca:	8082                	ret
      p->ofile[fd] = f;
    800051cc:	01a50793          	addi	a5,a0,26
    800051d0:	078e                	slli	a5,a5,0x3
    800051d2:	963e                	add	a2,a2,a5
    800051d4:	e204                	sd	s1,0(a2)
      return fd;
    800051d6:	b7f5                	j	800051c2 <fdalloc+0x2c>

00000000800051d8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051d8:	715d                	addi	sp,sp,-80
    800051da:	e486                	sd	ra,72(sp)
    800051dc:	e0a2                	sd	s0,64(sp)
    800051de:	fc26                	sd	s1,56(sp)
    800051e0:	f84a                	sd	s2,48(sp)
    800051e2:	f44e                	sd	s3,40(sp)
    800051e4:	f052                	sd	s4,32(sp)
    800051e6:	ec56                	sd	s5,24(sp)
    800051e8:	0880                	addi	s0,sp,80
    800051ea:	89ae                	mv	s3,a1
    800051ec:	8ab2                	mv	s5,a2
    800051ee:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051f0:	fb040593          	addi	a1,s0,-80
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	e86080e7          	jalr	-378(ra) # 8000407a <nameiparent>
    800051fc:	892a                	mv	s2,a0
    800051fe:	12050f63          	beqz	a0,8000533c <create+0x164>
    return 0;

  ilock(dp);
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	6a4080e7          	jalr	1700(ra) # 800038a6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000520a:	4601                	li	a2,0
    8000520c:	fb040593          	addi	a1,s0,-80
    80005210:	854a                	mv	a0,s2
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	b78080e7          	jalr	-1160(ra) # 80003d8a <dirlookup>
    8000521a:	84aa                	mv	s1,a0
    8000521c:	c921                	beqz	a0,8000526c <create+0x94>
    iunlockput(dp);
    8000521e:	854a                	mv	a0,s2
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	8e8080e7          	jalr	-1816(ra) # 80003b08 <iunlockput>
    ilock(ip);
    80005228:	8526                	mv	a0,s1
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	67c080e7          	jalr	1660(ra) # 800038a6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005232:	2981                	sext.w	s3,s3
    80005234:	4789                	li	a5,2
    80005236:	02f99463          	bne	s3,a5,8000525e <create+0x86>
    8000523a:	0444d783          	lhu	a5,68(s1)
    8000523e:	37f9                	addiw	a5,a5,-2
    80005240:	17c2                	slli	a5,a5,0x30
    80005242:	93c1                	srli	a5,a5,0x30
    80005244:	4705                	li	a4,1
    80005246:	00f76c63          	bltu	a4,a5,8000525e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000524a:	8526                	mv	a0,s1
    8000524c:	60a6                	ld	ra,72(sp)
    8000524e:	6406                	ld	s0,64(sp)
    80005250:	74e2                	ld	s1,56(sp)
    80005252:	7942                	ld	s2,48(sp)
    80005254:	79a2                	ld	s3,40(sp)
    80005256:	7a02                	ld	s4,32(sp)
    80005258:	6ae2                	ld	s5,24(sp)
    8000525a:	6161                	addi	sp,sp,80
    8000525c:	8082                	ret
    iunlockput(ip);
    8000525e:	8526                	mv	a0,s1
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	8a8080e7          	jalr	-1880(ra) # 80003b08 <iunlockput>
    return 0;
    80005268:	4481                	li	s1,0
    8000526a:	b7c5                	j	8000524a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000526c:	85ce                	mv	a1,s3
    8000526e:	00092503          	lw	a0,0(s2)
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	49c080e7          	jalr	1180(ra) # 8000370e <ialloc>
    8000527a:	84aa                	mv	s1,a0
    8000527c:	c529                	beqz	a0,800052c6 <create+0xee>
  ilock(ip);
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	628080e7          	jalr	1576(ra) # 800038a6 <ilock>
  ip->major = major;
    80005286:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000528a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000528e:	4785                	li	a5,1
    80005290:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005294:	8526                	mv	a0,s1
    80005296:	ffffe097          	auipc	ra,0xffffe
    8000529a:	546080e7          	jalr	1350(ra) # 800037dc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000529e:	2981                	sext.w	s3,s3
    800052a0:	4785                	li	a5,1
    800052a2:	02f98a63          	beq	s3,a5,800052d6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052a6:	40d0                	lw	a2,4(s1)
    800052a8:	fb040593          	addi	a1,s0,-80
    800052ac:	854a                	mv	a0,s2
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	cec080e7          	jalr	-788(ra) # 80003f9a <dirlink>
    800052b6:	06054b63          	bltz	a0,8000532c <create+0x154>
  iunlockput(dp);
    800052ba:	854a                	mv	a0,s2
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	84c080e7          	jalr	-1972(ra) # 80003b08 <iunlockput>
  return ip;
    800052c4:	b759                	j	8000524a <create+0x72>
    panic("create: ialloc");
    800052c6:	00003517          	auipc	a0,0x3
    800052ca:	45a50513          	addi	a0,a0,1114 # 80008720 <syscalls+0x2b0>
    800052ce:	ffffb097          	auipc	ra,0xffffb
    800052d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052d6:	04a95783          	lhu	a5,74(s2)
    800052da:	2785                	addiw	a5,a5,1
    800052dc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052e0:	854a                	mv	a0,s2
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	4fa080e7          	jalr	1274(ra) # 800037dc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052ea:	40d0                	lw	a2,4(s1)
    800052ec:	00003597          	auipc	a1,0x3
    800052f0:	44458593          	addi	a1,a1,1092 # 80008730 <syscalls+0x2c0>
    800052f4:	8526                	mv	a0,s1
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	ca4080e7          	jalr	-860(ra) # 80003f9a <dirlink>
    800052fe:	00054f63          	bltz	a0,8000531c <create+0x144>
    80005302:	00492603          	lw	a2,4(s2)
    80005306:	00003597          	auipc	a1,0x3
    8000530a:	43258593          	addi	a1,a1,1074 # 80008738 <syscalls+0x2c8>
    8000530e:	8526                	mv	a0,s1
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	c8a080e7          	jalr	-886(ra) # 80003f9a <dirlink>
    80005318:	f80557e3          	bgez	a0,800052a6 <create+0xce>
      panic("create dots");
    8000531c:	00003517          	auipc	a0,0x3
    80005320:	42450513          	addi	a0,a0,1060 # 80008740 <syscalls+0x2d0>
    80005324:	ffffb097          	auipc	ra,0xffffb
    80005328:	21a080e7          	jalr	538(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000532c:	00003517          	auipc	a0,0x3
    80005330:	42450513          	addi	a0,a0,1060 # 80008750 <syscalls+0x2e0>
    80005334:	ffffb097          	auipc	ra,0xffffb
    80005338:	20a080e7          	jalr	522(ra) # 8000053e <panic>
    return 0;
    8000533c:	84aa                	mv	s1,a0
    8000533e:	b731                	j	8000524a <create+0x72>

0000000080005340 <sys_dup>:
{
    80005340:	7179                	addi	sp,sp,-48
    80005342:	f406                	sd	ra,40(sp)
    80005344:	f022                	sd	s0,32(sp)
    80005346:	ec26                	sd	s1,24(sp)
    80005348:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000534a:	fd840613          	addi	a2,s0,-40
    8000534e:	4581                	li	a1,0
    80005350:	4501                	li	a0,0
    80005352:	00000097          	auipc	ra,0x0
    80005356:	ddc080e7          	jalr	-548(ra) # 8000512e <argfd>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000535c:	02054363          	bltz	a0,80005382 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005360:	fd843503          	ld	a0,-40(s0)
    80005364:	00000097          	auipc	ra,0x0
    80005368:	e32080e7          	jalr	-462(ra) # 80005196 <fdalloc>
    8000536c:	84aa                	mv	s1,a0
    return -1;
    8000536e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005370:	00054963          	bltz	a0,80005382 <sys_dup+0x42>
  filedup(f);
    80005374:	fd843503          	ld	a0,-40(s0)
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	37a080e7          	jalr	890(ra) # 800046f2 <filedup>
  return fd;
    80005380:	87a6                	mv	a5,s1
}
    80005382:	853e                	mv	a0,a5
    80005384:	70a2                	ld	ra,40(sp)
    80005386:	7402                	ld	s0,32(sp)
    80005388:	64e2                	ld	s1,24(sp)
    8000538a:	6145                	addi	sp,sp,48
    8000538c:	8082                	ret

000000008000538e <sys_read>:
{
    8000538e:	7179                	addi	sp,sp,-48
    80005390:	f406                	sd	ra,40(sp)
    80005392:	f022                	sd	s0,32(sp)
    80005394:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005396:	fe840613          	addi	a2,s0,-24
    8000539a:	4581                	li	a1,0
    8000539c:	4501                	li	a0,0
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	d90080e7          	jalr	-624(ra) # 8000512e <argfd>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a8:	04054163          	bltz	a0,800053ea <sys_read+0x5c>
    800053ac:	fe440593          	addi	a1,s0,-28
    800053b0:	4509                	li	a0,2
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	938080e7          	jalr	-1736(ra) # 80002cea <argint>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	02054763          	bltz	a0,800053ea <sys_read+0x5c>
    800053c0:	fd840593          	addi	a1,s0,-40
    800053c4:	4505                	li	a0,1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	946080e7          	jalr	-1722(ra) # 80002d0c <argaddr>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d0:	00054d63          	bltz	a0,800053ea <sys_read+0x5c>
  return fileread(f, p, n);
    800053d4:	fe442603          	lw	a2,-28(s0)
    800053d8:	fd843583          	ld	a1,-40(s0)
    800053dc:	fe843503          	ld	a0,-24(s0)
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	49e080e7          	jalr	1182(ra) # 8000487e <fileread>
    800053e8:	87aa                	mv	a5,a0
}
    800053ea:	853e                	mv	a0,a5
    800053ec:	70a2                	ld	ra,40(sp)
    800053ee:	7402                	ld	s0,32(sp)
    800053f0:	6145                	addi	sp,sp,48
    800053f2:	8082                	ret

00000000800053f4 <sys_write>:
{
    800053f4:	7179                	addi	sp,sp,-48
    800053f6:	f406                	sd	ra,40(sp)
    800053f8:	f022                	sd	s0,32(sp)
    800053fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fc:	fe840613          	addi	a2,s0,-24
    80005400:	4581                	li	a1,0
    80005402:	4501                	li	a0,0
    80005404:	00000097          	auipc	ra,0x0
    80005408:	d2a080e7          	jalr	-726(ra) # 8000512e <argfd>
    return -1;
    8000540c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540e:	04054163          	bltz	a0,80005450 <sys_write+0x5c>
    80005412:	fe440593          	addi	a1,s0,-28
    80005416:	4509                	li	a0,2
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	8d2080e7          	jalr	-1838(ra) # 80002cea <argint>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005422:	02054763          	bltz	a0,80005450 <sys_write+0x5c>
    80005426:	fd840593          	addi	a1,s0,-40
    8000542a:	4505                	li	a0,1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	8e0080e7          	jalr	-1824(ra) # 80002d0c <argaddr>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005436:	00054d63          	bltz	a0,80005450 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000543a:	fe442603          	lw	a2,-28(s0)
    8000543e:	fd843583          	ld	a1,-40(s0)
    80005442:	fe843503          	ld	a0,-24(s0)
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	4fa080e7          	jalr	1274(ra) # 80004940 <filewrite>
    8000544e:	87aa                	mv	a5,a0
}
    80005450:	853e                	mv	a0,a5
    80005452:	70a2                	ld	ra,40(sp)
    80005454:	7402                	ld	s0,32(sp)
    80005456:	6145                	addi	sp,sp,48
    80005458:	8082                	ret

000000008000545a <sys_close>:
{
    8000545a:	1101                	addi	sp,sp,-32
    8000545c:	ec06                	sd	ra,24(sp)
    8000545e:	e822                	sd	s0,16(sp)
    80005460:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005462:	fe040613          	addi	a2,s0,-32
    80005466:	fec40593          	addi	a1,s0,-20
    8000546a:	4501                	li	a0,0
    8000546c:	00000097          	auipc	ra,0x0
    80005470:	cc2080e7          	jalr	-830(ra) # 8000512e <argfd>
    return -1;
    80005474:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005476:	02054463          	bltz	a0,8000549e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	53e080e7          	jalr	1342(ra) # 800019b8 <myproc>
    80005482:	fec42783          	lw	a5,-20(s0)
    80005486:	07e9                	addi	a5,a5,26
    80005488:	078e                	slli	a5,a5,0x3
    8000548a:	97aa                	add	a5,a5,a0
    8000548c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005490:	fe043503          	ld	a0,-32(s0)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	2b0080e7          	jalr	688(ra) # 80004744 <fileclose>
  return 0;
    8000549c:	4781                	li	a5,0
}
    8000549e:	853e                	mv	a0,a5
    800054a0:	60e2                	ld	ra,24(sp)
    800054a2:	6442                	ld	s0,16(sp)
    800054a4:	6105                	addi	sp,sp,32
    800054a6:	8082                	ret

00000000800054a8 <sys_fstat>:
{
    800054a8:	1101                	addi	sp,sp,-32
    800054aa:	ec06                	sd	ra,24(sp)
    800054ac:	e822                	sd	s0,16(sp)
    800054ae:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b0:	fe840613          	addi	a2,s0,-24
    800054b4:	4581                	li	a1,0
    800054b6:	4501                	li	a0,0
    800054b8:	00000097          	auipc	ra,0x0
    800054bc:	c76080e7          	jalr	-906(ra) # 8000512e <argfd>
    return -1;
    800054c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054c2:	02054563          	bltz	a0,800054ec <sys_fstat+0x44>
    800054c6:	fe040593          	addi	a1,s0,-32
    800054ca:	4505                	li	a0,1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	840080e7          	jalr	-1984(ra) # 80002d0c <argaddr>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054d6:	00054b63          	bltz	a0,800054ec <sys_fstat+0x44>
  return filestat(f, st);
    800054da:	fe043583          	ld	a1,-32(s0)
    800054de:	fe843503          	ld	a0,-24(s0)
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	32a080e7          	jalr	810(ra) # 8000480c <filestat>
    800054ea:	87aa                	mv	a5,a0
}
    800054ec:	853e                	mv	a0,a5
    800054ee:	60e2                	ld	ra,24(sp)
    800054f0:	6442                	ld	s0,16(sp)
    800054f2:	6105                	addi	sp,sp,32
    800054f4:	8082                	ret

00000000800054f6 <sys_link>:
{
    800054f6:	7169                	addi	sp,sp,-304
    800054f8:	f606                	sd	ra,296(sp)
    800054fa:	f222                	sd	s0,288(sp)
    800054fc:	ee26                	sd	s1,280(sp)
    800054fe:	ea4a                	sd	s2,272(sp)
    80005500:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005502:	08000613          	li	a2,128
    80005506:	ed040593          	addi	a1,s0,-304
    8000550a:	4501                	li	a0,0
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	822080e7          	jalr	-2014(ra) # 80002d2e <argstr>
    return -1;
    80005514:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005516:	10054e63          	bltz	a0,80005632 <sys_link+0x13c>
    8000551a:	08000613          	li	a2,128
    8000551e:	f5040593          	addi	a1,s0,-176
    80005522:	4505                	li	a0,1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	80a080e7          	jalr	-2038(ra) # 80002d2e <argstr>
    return -1;
    8000552c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552e:	10054263          	bltz	a0,80005632 <sys_link+0x13c>
  begin_op();
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	d46080e7          	jalr	-698(ra) # 80004278 <begin_op>
  if((ip = namei(old)) == 0){
    8000553a:	ed040513          	addi	a0,s0,-304
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	b1e080e7          	jalr	-1250(ra) # 8000405c <namei>
    80005546:	84aa                	mv	s1,a0
    80005548:	c551                	beqz	a0,800055d4 <sys_link+0xde>
  ilock(ip);
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	35c080e7          	jalr	860(ra) # 800038a6 <ilock>
  if(ip->type == T_DIR){
    80005552:	04449703          	lh	a4,68(s1)
    80005556:	4785                	li	a5,1
    80005558:	08f70463          	beq	a4,a5,800055e0 <sys_link+0xea>
  ip->nlink++;
    8000555c:	04a4d783          	lhu	a5,74(s1)
    80005560:	2785                	addiw	a5,a5,1
    80005562:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	274080e7          	jalr	628(ra) # 800037dc <iupdate>
  iunlock(ip);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	3f6080e7          	jalr	1014(ra) # 80003968 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000557a:	fd040593          	addi	a1,s0,-48
    8000557e:	f5040513          	addi	a0,s0,-176
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	af8080e7          	jalr	-1288(ra) # 8000407a <nameiparent>
    8000558a:	892a                	mv	s2,a0
    8000558c:	c935                	beqz	a0,80005600 <sys_link+0x10a>
  ilock(dp);
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	318080e7          	jalr	792(ra) # 800038a6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005596:	00092703          	lw	a4,0(s2)
    8000559a:	409c                	lw	a5,0(s1)
    8000559c:	04f71d63          	bne	a4,a5,800055f6 <sys_link+0x100>
    800055a0:	40d0                	lw	a2,4(s1)
    800055a2:	fd040593          	addi	a1,s0,-48
    800055a6:	854a                	mv	a0,s2
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	9f2080e7          	jalr	-1550(ra) # 80003f9a <dirlink>
    800055b0:	04054363          	bltz	a0,800055f6 <sys_link+0x100>
  iunlockput(dp);
    800055b4:	854a                	mv	a0,s2
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	552080e7          	jalr	1362(ra) # 80003b08 <iunlockput>
  iput(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	4a0080e7          	jalr	1184(ra) # 80003a60 <iput>
  end_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	d30080e7          	jalr	-720(ra) # 800042f8 <end_op>
  return 0;
    800055d0:	4781                	li	a5,0
    800055d2:	a085                	j	80005632 <sys_link+0x13c>
    end_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	d24080e7          	jalr	-732(ra) # 800042f8 <end_op>
    return -1;
    800055dc:	57fd                	li	a5,-1
    800055de:	a891                	j	80005632 <sys_link+0x13c>
    iunlockput(ip);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	526080e7          	jalr	1318(ra) # 80003b08 <iunlockput>
    end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	d0e080e7          	jalr	-754(ra) # 800042f8 <end_op>
    return -1;
    800055f2:	57fd                	li	a5,-1
    800055f4:	a83d                	j	80005632 <sys_link+0x13c>
    iunlockput(dp);
    800055f6:	854a                	mv	a0,s2
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	510080e7          	jalr	1296(ra) # 80003b08 <iunlockput>
  ilock(ip);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	2a4080e7          	jalr	676(ra) # 800038a6 <ilock>
  ip->nlink--;
    8000560a:	04a4d783          	lhu	a5,74(s1)
    8000560e:	37fd                	addiw	a5,a5,-1
    80005610:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	1c6080e7          	jalr	454(ra) # 800037dc <iupdate>
  iunlockput(ip);
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	4e8080e7          	jalr	1256(ra) # 80003b08 <iunlockput>
  end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	cd0080e7          	jalr	-816(ra) # 800042f8 <end_op>
  return -1;
    80005630:	57fd                	li	a5,-1
}
    80005632:	853e                	mv	a0,a5
    80005634:	70b2                	ld	ra,296(sp)
    80005636:	7412                	ld	s0,288(sp)
    80005638:	64f2                	ld	s1,280(sp)
    8000563a:	6952                	ld	s2,272(sp)
    8000563c:	6155                	addi	sp,sp,304
    8000563e:	8082                	ret

0000000080005640 <sys_unlink>:
{
    80005640:	7151                	addi	sp,sp,-240
    80005642:	f586                	sd	ra,232(sp)
    80005644:	f1a2                	sd	s0,224(sp)
    80005646:	eda6                	sd	s1,216(sp)
    80005648:	e9ca                	sd	s2,208(sp)
    8000564a:	e5ce                	sd	s3,200(sp)
    8000564c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000564e:	08000613          	li	a2,128
    80005652:	f3040593          	addi	a1,s0,-208
    80005656:	4501                	li	a0,0
    80005658:	ffffd097          	auipc	ra,0xffffd
    8000565c:	6d6080e7          	jalr	1750(ra) # 80002d2e <argstr>
    80005660:	18054163          	bltz	a0,800057e2 <sys_unlink+0x1a2>
  begin_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	c14080e7          	jalr	-1004(ra) # 80004278 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000566c:	fb040593          	addi	a1,s0,-80
    80005670:	f3040513          	addi	a0,s0,-208
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	a06080e7          	jalr	-1530(ra) # 8000407a <nameiparent>
    8000567c:	84aa                	mv	s1,a0
    8000567e:	c979                	beqz	a0,80005754 <sys_unlink+0x114>
  ilock(dp);
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	226080e7          	jalr	550(ra) # 800038a6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005688:	00003597          	auipc	a1,0x3
    8000568c:	0a858593          	addi	a1,a1,168 # 80008730 <syscalls+0x2c0>
    80005690:	fb040513          	addi	a0,s0,-80
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	6dc080e7          	jalr	1756(ra) # 80003d70 <namecmp>
    8000569c:	14050a63          	beqz	a0,800057f0 <sys_unlink+0x1b0>
    800056a0:	00003597          	auipc	a1,0x3
    800056a4:	09858593          	addi	a1,a1,152 # 80008738 <syscalls+0x2c8>
    800056a8:	fb040513          	addi	a0,s0,-80
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	6c4080e7          	jalr	1732(ra) # 80003d70 <namecmp>
    800056b4:	12050e63          	beqz	a0,800057f0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056b8:	f2c40613          	addi	a2,s0,-212
    800056bc:	fb040593          	addi	a1,s0,-80
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	6c8080e7          	jalr	1736(ra) # 80003d8a <dirlookup>
    800056ca:	892a                	mv	s2,a0
    800056cc:	12050263          	beqz	a0,800057f0 <sys_unlink+0x1b0>
  ilock(ip);
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	1d6080e7          	jalr	470(ra) # 800038a6 <ilock>
  if(ip->nlink < 1)
    800056d8:	04a91783          	lh	a5,74(s2)
    800056dc:	08f05263          	blez	a5,80005760 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056e0:	04491703          	lh	a4,68(s2)
    800056e4:	4785                	li	a5,1
    800056e6:	08f70563          	beq	a4,a5,80005770 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056ea:	4641                	li	a2,16
    800056ec:	4581                	li	a1,0
    800056ee:	fc040513          	addi	a0,s0,-64
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	5ee080e7          	jalr	1518(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056fa:	4741                	li	a4,16
    800056fc:	f2c42683          	lw	a3,-212(s0)
    80005700:	fc040613          	addi	a2,s0,-64
    80005704:	4581                	li	a1,0
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	54a080e7          	jalr	1354(ra) # 80003c52 <writei>
    80005710:	47c1                	li	a5,16
    80005712:	0af51563          	bne	a0,a5,800057bc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005716:	04491703          	lh	a4,68(s2)
    8000571a:	4785                	li	a5,1
    8000571c:	0af70863          	beq	a4,a5,800057cc <sys_unlink+0x18c>
  iunlockput(dp);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	3e6080e7          	jalr	998(ra) # 80003b08 <iunlockput>
  ip->nlink--;
    8000572a:	04a95783          	lhu	a5,74(s2)
    8000572e:	37fd                	addiw	a5,a5,-1
    80005730:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005734:	854a                	mv	a0,s2
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	0a6080e7          	jalr	166(ra) # 800037dc <iupdate>
  iunlockput(ip);
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	3c8080e7          	jalr	968(ra) # 80003b08 <iunlockput>
  end_op();
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	bb0080e7          	jalr	-1104(ra) # 800042f8 <end_op>
  return 0;
    80005750:	4501                	li	a0,0
    80005752:	a84d                	j	80005804 <sys_unlink+0x1c4>
    end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	ba4080e7          	jalr	-1116(ra) # 800042f8 <end_op>
    return -1;
    8000575c:	557d                	li	a0,-1
    8000575e:	a05d                	j	80005804 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005760:	00003517          	auipc	a0,0x3
    80005764:	00050513          	mv	a0,a0
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	dd6080e7          	jalr	-554(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005770:	04c92703          	lw	a4,76(s2)
    80005774:	02000793          	li	a5,32
    80005778:	f6e7f9e3          	bgeu	a5,a4,800056ea <sys_unlink+0xaa>
    8000577c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005780:	4741                	li	a4,16
    80005782:	86ce                	mv	a3,s3
    80005784:	f1840613          	addi	a2,s0,-232
    80005788:	4581                	li	a1,0
    8000578a:	854a                	mv	a0,s2
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	3ce080e7          	jalr	974(ra) # 80003b5a <readi>
    80005794:	47c1                	li	a5,16
    80005796:	00f51b63          	bne	a0,a5,800057ac <sys_unlink+0x16c>
    if(de.inum != 0)
    8000579a:	f1845783          	lhu	a5,-232(s0)
    8000579e:	e7a1                	bnez	a5,800057e6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a0:	29c1                	addiw	s3,s3,16
    800057a2:	04c92783          	lw	a5,76(s2)
    800057a6:	fcf9ede3          	bltu	s3,a5,80005780 <sys_unlink+0x140>
    800057aa:	b781                	j	800056ea <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057ac:	00003517          	auipc	a0,0x3
    800057b0:	fcc50513          	addi	a0,a0,-52 # 80008778 <syscalls+0x308>
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057bc:	00003517          	auipc	a0,0x3
    800057c0:	fd450513          	addi	a0,a0,-44 # 80008790 <syscalls+0x320>
    800057c4:	ffffb097          	auipc	ra,0xffffb
    800057c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>
    dp->nlink--;
    800057cc:	04a4d783          	lhu	a5,74(s1)
    800057d0:	37fd                	addiw	a5,a5,-1
    800057d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	004080e7          	jalr	4(ra) # 800037dc <iupdate>
    800057e0:	b781                	j	80005720 <sys_unlink+0xe0>
    return -1;
    800057e2:	557d                	li	a0,-1
    800057e4:	a005                	j	80005804 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057e6:	854a                	mv	a0,s2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	320080e7          	jalr	800(ra) # 80003b08 <iunlockput>
  iunlockput(dp);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	316080e7          	jalr	790(ra) # 80003b08 <iunlockput>
  end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	afe080e7          	jalr	-1282(ra) # 800042f8 <end_op>
  return -1;
    80005802:	557d                	li	a0,-1
}
    80005804:	70ae                	ld	ra,232(sp)
    80005806:	740e                	ld	s0,224(sp)
    80005808:	64ee                	ld	s1,216(sp)
    8000580a:	694e                	ld	s2,208(sp)
    8000580c:	69ae                	ld	s3,200(sp)
    8000580e:	616d                	addi	sp,sp,240
    80005810:	8082                	ret

0000000080005812 <sys_open>:

uint64
sys_open(void)
{
    80005812:	7131                	addi	sp,sp,-192
    80005814:	fd06                	sd	ra,184(sp)
    80005816:	f922                	sd	s0,176(sp)
    80005818:	f526                	sd	s1,168(sp)
    8000581a:	f14a                	sd	s2,160(sp)
    8000581c:	ed4e                	sd	s3,152(sp)
    8000581e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005820:	08000613          	li	a2,128
    80005824:	f5040593          	addi	a1,s0,-176
    80005828:	4501                	li	a0,0
    8000582a:	ffffd097          	auipc	ra,0xffffd
    8000582e:	504080e7          	jalr	1284(ra) # 80002d2e <argstr>
    return -1;
    80005832:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005834:	0c054163          	bltz	a0,800058f6 <sys_open+0xe4>
    80005838:	f4c40593          	addi	a1,s0,-180
    8000583c:	4505                	li	a0,1
    8000583e:	ffffd097          	auipc	ra,0xffffd
    80005842:	4ac080e7          	jalr	1196(ra) # 80002cea <argint>
    80005846:	0a054863          	bltz	a0,800058f6 <sys_open+0xe4>

  begin_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	a2e080e7          	jalr	-1490(ra) # 80004278 <begin_op>

  if(omode & O_CREATE){
    80005852:	f4c42783          	lw	a5,-180(s0)
    80005856:	2007f793          	andi	a5,a5,512
    8000585a:	cbdd                	beqz	a5,80005910 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000585c:	4681                	li	a3,0
    8000585e:	4601                	li	a2,0
    80005860:	4589                	li	a1,2
    80005862:	f5040513          	addi	a0,s0,-176
    80005866:	00000097          	auipc	ra,0x0
    8000586a:	972080e7          	jalr	-1678(ra) # 800051d8 <create>
    8000586e:	892a                	mv	s2,a0
    if(ip == 0){
    80005870:	c959                	beqz	a0,80005906 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005872:	04491703          	lh	a4,68(s2)
    80005876:	478d                	li	a5,3
    80005878:	00f71763          	bne	a4,a5,80005886 <sys_open+0x74>
    8000587c:	04695703          	lhu	a4,70(s2)
    80005880:	47a5                	li	a5,9
    80005882:	0ce7ec63          	bltu	a5,a4,8000595a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	e02080e7          	jalr	-510(ra) # 80004688 <filealloc>
    8000588e:	89aa                	mv	s3,a0
    80005890:	10050263          	beqz	a0,80005994 <sys_open+0x182>
    80005894:	00000097          	auipc	ra,0x0
    80005898:	902080e7          	jalr	-1790(ra) # 80005196 <fdalloc>
    8000589c:	84aa                	mv	s1,a0
    8000589e:	0e054663          	bltz	a0,8000598a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058a2:	04491703          	lh	a4,68(s2)
    800058a6:	478d                	li	a5,3
    800058a8:	0cf70463          	beq	a4,a5,80005970 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058ac:	4789                	li	a5,2
    800058ae:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058b2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058b6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058ba:	f4c42783          	lw	a5,-180(s0)
    800058be:	0017c713          	xori	a4,a5,1
    800058c2:	8b05                	andi	a4,a4,1
    800058c4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058c8:	0037f713          	andi	a4,a5,3
    800058cc:	00e03733          	snez	a4,a4
    800058d0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058d4:	4007f793          	andi	a5,a5,1024
    800058d8:	c791                	beqz	a5,800058e4 <sys_open+0xd2>
    800058da:	04491703          	lh	a4,68(s2)
    800058de:	4789                	li	a5,2
    800058e0:	08f70f63          	beq	a4,a5,8000597e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058e4:	854a                	mv	a0,s2
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	082080e7          	jalr	130(ra) # 80003968 <iunlock>
  end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	a0a080e7          	jalr	-1526(ra) # 800042f8 <end_op>

  return fd;
}
    800058f6:	8526                	mv	a0,s1
    800058f8:	70ea                	ld	ra,184(sp)
    800058fa:	744a                	ld	s0,176(sp)
    800058fc:	74aa                	ld	s1,168(sp)
    800058fe:	790a                	ld	s2,160(sp)
    80005900:	69ea                	ld	s3,152(sp)
    80005902:	6129                	addi	sp,sp,192
    80005904:	8082                	ret
      end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	9f2080e7          	jalr	-1550(ra) # 800042f8 <end_op>
      return -1;
    8000590e:	b7e5                	j	800058f6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005910:	f5040513          	addi	a0,s0,-176
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	748080e7          	jalr	1864(ra) # 8000405c <namei>
    8000591c:	892a                	mv	s2,a0
    8000591e:	c905                	beqz	a0,8000594e <sys_open+0x13c>
    ilock(ip);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	f86080e7          	jalr	-122(ra) # 800038a6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005928:	04491703          	lh	a4,68(s2)
    8000592c:	4785                	li	a5,1
    8000592e:	f4f712e3          	bne	a4,a5,80005872 <sys_open+0x60>
    80005932:	f4c42783          	lw	a5,-180(s0)
    80005936:	dba1                	beqz	a5,80005886 <sys_open+0x74>
      iunlockput(ip);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	1ce080e7          	jalr	462(ra) # 80003b08 <iunlockput>
      end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	9b6080e7          	jalr	-1610(ra) # 800042f8 <end_op>
      return -1;
    8000594a:	54fd                	li	s1,-1
    8000594c:	b76d                	j	800058f6 <sys_open+0xe4>
      end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	9aa080e7          	jalr	-1622(ra) # 800042f8 <end_op>
      return -1;
    80005956:	54fd                	li	s1,-1
    80005958:	bf79                	j	800058f6 <sys_open+0xe4>
    iunlockput(ip);
    8000595a:	854a                	mv	a0,s2
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	1ac080e7          	jalr	428(ra) # 80003b08 <iunlockput>
    end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	994080e7          	jalr	-1644(ra) # 800042f8 <end_op>
    return -1;
    8000596c:	54fd                	li	s1,-1
    8000596e:	b761                	j	800058f6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005970:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005974:	04691783          	lh	a5,70(s2)
    80005978:	02f99223          	sh	a5,36(s3)
    8000597c:	bf2d                	j	800058b6 <sys_open+0xa4>
    itrunc(ip);
    8000597e:	854a                	mv	a0,s2
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	034080e7          	jalr	52(ra) # 800039b4 <itrunc>
    80005988:	bfb1                	j	800058e4 <sys_open+0xd2>
      fileclose(f);
    8000598a:	854e                	mv	a0,s3
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	db8080e7          	jalr	-584(ra) # 80004744 <fileclose>
    iunlockput(ip);
    80005994:	854a                	mv	a0,s2
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	172080e7          	jalr	370(ra) # 80003b08 <iunlockput>
    end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	95a080e7          	jalr	-1702(ra) # 800042f8 <end_op>
    return -1;
    800059a6:	54fd                	li	s1,-1
    800059a8:	b7b9                	j	800058f6 <sys_open+0xe4>

00000000800059aa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059aa:	7175                	addi	sp,sp,-144
    800059ac:	e506                	sd	ra,136(sp)
    800059ae:	e122                	sd	s0,128(sp)
    800059b0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	8c6080e7          	jalr	-1850(ra) # 80004278 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059ba:	08000613          	li	a2,128
    800059be:	f7040593          	addi	a1,s0,-144
    800059c2:	4501                	li	a0,0
    800059c4:	ffffd097          	auipc	ra,0xffffd
    800059c8:	36a080e7          	jalr	874(ra) # 80002d2e <argstr>
    800059cc:	02054963          	bltz	a0,800059fe <sys_mkdir+0x54>
    800059d0:	4681                	li	a3,0
    800059d2:	4601                	li	a2,0
    800059d4:	4585                	li	a1,1
    800059d6:	f7040513          	addi	a0,s0,-144
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	7fe080e7          	jalr	2046(ra) # 800051d8 <create>
    800059e2:	cd11                	beqz	a0,800059fe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	124080e7          	jalr	292(ra) # 80003b08 <iunlockput>
  end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	90c080e7          	jalr	-1780(ra) # 800042f8 <end_op>
  return 0;
    800059f4:	4501                	li	a0,0
}
    800059f6:	60aa                	ld	ra,136(sp)
    800059f8:	640a                	ld	s0,128(sp)
    800059fa:	6149                	addi	sp,sp,144
    800059fc:	8082                	ret
    end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	8fa080e7          	jalr	-1798(ra) # 800042f8 <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	b7fd                	j	800059f6 <sys_mkdir+0x4c>

0000000080005a0a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a0a:	7135                	addi	sp,sp,-160
    80005a0c:	ed06                	sd	ra,152(sp)
    80005a0e:	e922                	sd	s0,144(sp)
    80005a10:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	866080e7          	jalr	-1946(ra) # 80004278 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a1a:	08000613          	li	a2,128
    80005a1e:	f7040593          	addi	a1,s0,-144
    80005a22:	4501                	li	a0,0
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	30a080e7          	jalr	778(ra) # 80002d2e <argstr>
    80005a2c:	04054a63          	bltz	a0,80005a80 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a30:	f6c40593          	addi	a1,s0,-148
    80005a34:	4505                	li	a0,1
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	2b4080e7          	jalr	692(ra) # 80002cea <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a3e:	04054163          	bltz	a0,80005a80 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a42:	f6840593          	addi	a1,s0,-152
    80005a46:	4509                	li	a0,2
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	2a2080e7          	jalr	674(ra) # 80002cea <argint>
     argint(1, &major) < 0 ||
    80005a50:	02054863          	bltz	a0,80005a80 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a54:	f6841683          	lh	a3,-152(s0)
    80005a58:	f6c41603          	lh	a2,-148(s0)
    80005a5c:	458d                	li	a1,3
    80005a5e:	f7040513          	addi	a0,s0,-144
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	776080e7          	jalr	1910(ra) # 800051d8 <create>
     argint(2, &minor) < 0 ||
    80005a6a:	c919                	beqz	a0,80005a80 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	09c080e7          	jalr	156(ra) # 80003b08 <iunlockput>
  end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	884080e7          	jalr	-1916(ra) # 800042f8 <end_op>
  return 0;
    80005a7c:	4501                	li	a0,0
    80005a7e:	a031                	j	80005a8a <sys_mknod+0x80>
    end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	878080e7          	jalr	-1928(ra) # 800042f8 <end_op>
    return -1;
    80005a88:	557d                	li	a0,-1
}
    80005a8a:	60ea                	ld	ra,152(sp)
    80005a8c:	644a                	ld	s0,144(sp)
    80005a8e:	610d                	addi	sp,sp,160
    80005a90:	8082                	ret

0000000080005a92 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a92:	7135                	addi	sp,sp,-160
    80005a94:	ed06                	sd	ra,152(sp)
    80005a96:	e922                	sd	s0,144(sp)
    80005a98:	e526                	sd	s1,136(sp)
    80005a9a:	e14a                	sd	s2,128(sp)
    80005a9c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a9e:	ffffc097          	auipc	ra,0xffffc
    80005aa2:	f1a080e7          	jalr	-230(ra) # 800019b8 <myproc>
    80005aa6:	892a                	mv	s2,a0
  
  begin_op();
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	7d0080e7          	jalr	2000(ra) # 80004278 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ab0:	08000613          	li	a2,128
    80005ab4:	f6040593          	addi	a1,s0,-160
    80005ab8:	4501                	li	a0,0
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	274080e7          	jalr	628(ra) # 80002d2e <argstr>
    80005ac2:	04054b63          	bltz	a0,80005b18 <sys_chdir+0x86>
    80005ac6:	f6040513          	addi	a0,s0,-160
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	592080e7          	jalr	1426(ra) # 8000405c <namei>
    80005ad2:	84aa                	mv	s1,a0
    80005ad4:	c131                	beqz	a0,80005b18 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	dd0080e7          	jalr	-560(ra) # 800038a6 <ilock>
  if(ip->type != T_DIR){
    80005ade:	04449703          	lh	a4,68(s1)
    80005ae2:	4785                	li	a5,1
    80005ae4:	04f71063          	bne	a4,a5,80005b24 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	e7e080e7          	jalr	-386(ra) # 80003968 <iunlock>
  iput(p->cwd);
    80005af2:	15093503          	ld	a0,336(s2)
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	f6a080e7          	jalr	-150(ra) # 80003a60 <iput>
  end_op();
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	7fa080e7          	jalr	2042(ra) # 800042f8 <end_op>
  p->cwd = ip;
    80005b06:	14993823          	sd	s1,336(s2)
  return 0;
    80005b0a:	4501                	li	a0,0
}
    80005b0c:	60ea                	ld	ra,152(sp)
    80005b0e:	644a                	ld	s0,144(sp)
    80005b10:	64aa                	ld	s1,136(sp)
    80005b12:	690a                	ld	s2,128(sp)
    80005b14:	610d                	addi	sp,sp,160
    80005b16:	8082                	ret
    end_op();
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	7e0080e7          	jalr	2016(ra) # 800042f8 <end_op>
    return -1;
    80005b20:	557d                	li	a0,-1
    80005b22:	b7ed                	j	80005b0c <sys_chdir+0x7a>
    iunlockput(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	fe2080e7          	jalr	-30(ra) # 80003b08 <iunlockput>
    end_op();
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	7ca080e7          	jalr	1994(ra) # 800042f8 <end_op>
    return -1;
    80005b36:	557d                	li	a0,-1
    80005b38:	bfd1                	j	80005b0c <sys_chdir+0x7a>

0000000080005b3a <sys_exec>:

uint64
sys_exec(void)
{
    80005b3a:	7145                	addi	sp,sp,-464
    80005b3c:	e786                	sd	ra,456(sp)
    80005b3e:	e3a2                	sd	s0,448(sp)
    80005b40:	ff26                	sd	s1,440(sp)
    80005b42:	fb4a                	sd	s2,432(sp)
    80005b44:	f74e                	sd	s3,424(sp)
    80005b46:	f352                	sd	s4,416(sp)
    80005b48:	ef56                	sd	s5,408(sp)
    80005b4a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b4c:	08000613          	li	a2,128
    80005b50:	f4040593          	addi	a1,s0,-192
    80005b54:	4501                	li	a0,0
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	1d8080e7          	jalr	472(ra) # 80002d2e <argstr>
    return -1;
    80005b5e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b60:	0c054a63          	bltz	a0,80005c34 <sys_exec+0xfa>
    80005b64:	e3840593          	addi	a1,s0,-456
    80005b68:	4505                	li	a0,1
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	1a2080e7          	jalr	418(ra) # 80002d0c <argaddr>
    80005b72:	0c054163          	bltz	a0,80005c34 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b76:	10000613          	li	a2,256
    80005b7a:	4581                	li	a1,0
    80005b7c:	e4040513          	addi	a0,s0,-448
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	160080e7          	jalr	352(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b88:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b8c:	89a6                	mv	s3,s1
    80005b8e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b90:	02000a13          	li	s4,32
    80005b94:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b98:	00391513          	slli	a0,s2,0x3
    80005b9c:	e3040593          	addi	a1,s0,-464
    80005ba0:	e3843783          	ld	a5,-456(s0)
    80005ba4:	953e                	add	a0,a0,a5
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	0aa080e7          	jalr	170(ra) # 80002c50 <fetchaddr>
    80005bae:	02054a63          	bltz	a0,80005be2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bb2:	e3043783          	ld	a5,-464(s0)
    80005bb6:	c3b9                	beqz	a5,80005bfc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bb8:	ffffb097          	auipc	ra,0xffffb
    80005bbc:	f3c080e7          	jalr	-196(ra) # 80000af4 <kalloc>
    80005bc0:	85aa                	mv	a1,a0
    80005bc2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bc6:	cd11                	beqz	a0,80005be2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bc8:	6605                	lui	a2,0x1
    80005bca:	e3043503          	ld	a0,-464(s0)
    80005bce:	ffffd097          	auipc	ra,0xffffd
    80005bd2:	0d4080e7          	jalr	212(ra) # 80002ca2 <fetchstr>
    80005bd6:	00054663          	bltz	a0,80005be2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bda:	0905                	addi	s2,s2,1
    80005bdc:	09a1                	addi	s3,s3,8
    80005bde:	fb491be3          	bne	s2,s4,80005b94 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be2:	10048913          	addi	s2,s1,256
    80005be6:	6088                	ld	a0,0(s1)
    80005be8:	c529                	beqz	a0,80005c32 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bea:	ffffb097          	auipc	ra,0xffffb
    80005bee:	e0e080e7          	jalr	-498(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf2:	04a1                	addi	s1,s1,8
    80005bf4:	ff2499e3          	bne	s1,s2,80005be6 <sys_exec+0xac>
  return -1;
    80005bf8:	597d                	li	s2,-1
    80005bfa:	a82d                	j	80005c34 <sys_exec+0xfa>
      argv[i] = 0;
    80005bfc:	0a8e                	slli	s5,s5,0x3
    80005bfe:	fc040793          	addi	a5,s0,-64
    80005c02:	9abe                	add	s5,s5,a5
    80005c04:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c08:	e4040593          	addi	a1,s0,-448
    80005c0c:	f4040513          	addi	a0,s0,-192
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	194080e7          	jalr	404(ra) # 80004da4 <exec>
    80005c18:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	10048993          	addi	s3,s1,256
    80005c1e:	6088                	ld	a0,0(s1)
    80005c20:	c911                	beqz	a0,80005c34 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	dd6080e7          	jalr	-554(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2a:	04a1                	addi	s1,s1,8
    80005c2c:	ff3499e3          	bne	s1,s3,80005c1e <sys_exec+0xe4>
    80005c30:	a011                	j	80005c34 <sys_exec+0xfa>
  return -1;
    80005c32:	597d                	li	s2,-1
}
    80005c34:	854a                	mv	a0,s2
    80005c36:	60be                	ld	ra,456(sp)
    80005c38:	641e                	ld	s0,448(sp)
    80005c3a:	74fa                	ld	s1,440(sp)
    80005c3c:	795a                	ld	s2,432(sp)
    80005c3e:	79ba                	ld	s3,424(sp)
    80005c40:	7a1a                	ld	s4,416(sp)
    80005c42:	6afa                	ld	s5,408(sp)
    80005c44:	6179                	addi	sp,sp,464
    80005c46:	8082                	ret

0000000080005c48 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c48:	7139                	addi	sp,sp,-64
    80005c4a:	fc06                	sd	ra,56(sp)
    80005c4c:	f822                	sd	s0,48(sp)
    80005c4e:	f426                	sd	s1,40(sp)
    80005c50:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c52:	ffffc097          	auipc	ra,0xffffc
    80005c56:	d66080e7          	jalr	-666(ra) # 800019b8 <myproc>
    80005c5a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c5c:	fd840593          	addi	a1,s0,-40
    80005c60:	4501                	li	a0,0
    80005c62:	ffffd097          	auipc	ra,0xffffd
    80005c66:	0aa080e7          	jalr	170(ra) # 80002d0c <argaddr>
    return -1;
    80005c6a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c6c:	0e054063          	bltz	a0,80005d4c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c70:	fc840593          	addi	a1,s0,-56
    80005c74:	fd040513          	addi	a0,s0,-48
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	dfc080e7          	jalr	-516(ra) # 80004a74 <pipealloc>
    return -1;
    80005c80:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c82:	0c054563          	bltz	a0,80005d4c <sys_pipe+0x104>
  fd0 = -1;
    80005c86:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c8a:	fd043503          	ld	a0,-48(s0)
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	508080e7          	jalr	1288(ra) # 80005196 <fdalloc>
    80005c96:	fca42223          	sw	a0,-60(s0)
    80005c9a:	08054c63          	bltz	a0,80005d32 <sys_pipe+0xea>
    80005c9e:	fc843503          	ld	a0,-56(s0)
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	4f4080e7          	jalr	1268(ra) # 80005196 <fdalloc>
    80005caa:	fca42023          	sw	a0,-64(s0)
    80005cae:	06054863          	bltz	a0,80005d1e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cb2:	4691                	li	a3,4
    80005cb4:	fc440613          	addi	a2,s0,-60
    80005cb8:	fd843583          	ld	a1,-40(s0)
    80005cbc:	68a8                	ld	a0,80(s1)
    80005cbe:	ffffc097          	auipc	ra,0xffffc
    80005cc2:	9bc080e7          	jalr	-1604(ra) # 8000167a <copyout>
    80005cc6:	02054063          	bltz	a0,80005ce6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cca:	4691                	li	a3,4
    80005ccc:	fc040613          	addi	a2,s0,-64
    80005cd0:	fd843583          	ld	a1,-40(s0)
    80005cd4:	0591                	addi	a1,a1,4
    80005cd6:	68a8                	ld	a0,80(s1)
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	9a2080e7          	jalr	-1630(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ce0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ce2:	06055563          	bgez	a0,80005d4c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ce6:	fc442783          	lw	a5,-60(s0)
    80005cea:	07e9                	addi	a5,a5,26
    80005cec:	078e                	slli	a5,a5,0x3
    80005cee:	97a6                	add	a5,a5,s1
    80005cf0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cf4:	fc042503          	lw	a0,-64(s0)
    80005cf8:	0569                	addi	a0,a0,26
    80005cfa:	050e                	slli	a0,a0,0x3
    80005cfc:	9526                	add	a0,a0,s1
    80005cfe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d02:	fd043503          	ld	a0,-48(s0)
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	a3e080e7          	jalr	-1474(ra) # 80004744 <fileclose>
    fileclose(wf);
    80005d0e:	fc843503          	ld	a0,-56(s0)
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	a32080e7          	jalr	-1486(ra) # 80004744 <fileclose>
    return -1;
    80005d1a:	57fd                	li	a5,-1
    80005d1c:	a805                	j	80005d4c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d1e:	fc442783          	lw	a5,-60(s0)
    80005d22:	0007c863          	bltz	a5,80005d32 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d26:	01a78513          	addi	a0,a5,26
    80005d2a:	050e                	slli	a0,a0,0x3
    80005d2c:	9526                	add	a0,a0,s1
    80005d2e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d32:	fd043503          	ld	a0,-48(s0)
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	a0e080e7          	jalr	-1522(ra) # 80004744 <fileclose>
    fileclose(wf);
    80005d3e:	fc843503          	ld	a0,-56(s0)
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	a02080e7          	jalr	-1534(ra) # 80004744 <fileclose>
    return -1;
    80005d4a:	57fd                	li	a5,-1
}
    80005d4c:	853e                	mv	a0,a5
    80005d4e:	70e2                	ld	ra,56(sp)
    80005d50:	7442                	ld	s0,48(sp)
    80005d52:	74a2                	ld	s1,40(sp)
    80005d54:	6121                	addi	sp,sp,64
    80005d56:	8082                	ret
	...

0000000080005d60 <kernelvec>:
    80005d60:	7111                	addi	sp,sp,-256
    80005d62:	e006                	sd	ra,0(sp)
    80005d64:	e40a                	sd	sp,8(sp)
    80005d66:	e80e                	sd	gp,16(sp)
    80005d68:	ec12                	sd	tp,24(sp)
    80005d6a:	f016                	sd	t0,32(sp)
    80005d6c:	f41a                	sd	t1,40(sp)
    80005d6e:	f81e                	sd	t2,48(sp)
    80005d70:	fc22                	sd	s0,56(sp)
    80005d72:	e0a6                	sd	s1,64(sp)
    80005d74:	e4aa                	sd	a0,72(sp)
    80005d76:	e8ae                	sd	a1,80(sp)
    80005d78:	ecb2                	sd	a2,88(sp)
    80005d7a:	f0b6                	sd	a3,96(sp)
    80005d7c:	f4ba                	sd	a4,104(sp)
    80005d7e:	f8be                	sd	a5,112(sp)
    80005d80:	fcc2                	sd	a6,120(sp)
    80005d82:	e146                	sd	a7,128(sp)
    80005d84:	e54a                	sd	s2,136(sp)
    80005d86:	e94e                	sd	s3,144(sp)
    80005d88:	ed52                	sd	s4,152(sp)
    80005d8a:	f156                	sd	s5,160(sp)
    80005d8c:	f55a                	sd	s6,168(sp)
    80005d8e:	f95e                	sd	s7,176(sp)
    80005d90:	fd62                	sd	s8,184(sp)
    80005d92:	e1e6                	sd	s9,192(sp)
    80005d94:	e5ea                	sd	s10,200(sp)
    80005d96:	e9ee                	sd	s11,208(sp)
    80005d98:	edf2                	sd	t3,216(sp)
    80005d9a:	f1f6                	sd	t4,224(sp)
    80005d9c:	f5fa                	sd	t5,232(sp)
    80005d9e:	f9fe                	sd	t6,240(sp)
    80005da0:	d8dfc0ef          	jal	ra,80002b2c <kerneltrap>
    80005da4:	6082                	ld	ra,0(sp)
    80005da6:	6122                	ld	sp,8(sp)
    80005da8:	61c2                	ld	gp,16(sp)
    80005daa:	7282                	ld	t0,32(sp)
    80005dac:	7322                	ld	t1,40(sp)
    80005dae:	73c2                	ld	t2,48(sp)
    80005db0:	7462                	ld	s0,56(sp)
    80005db2:	6486                	ld	s1,64(sp)
    80005db4:	6526                	ld	a0,72(sp)
    80005db6:	65c6                	ld	a1,80(sp)
    80005db8:	6666                	ld	a2,88(sp)
    80005dba:	7686                	ld	a3,96(sp)
    80005dbc:	7726                	ld	a4,104(sp)
    80005dbe:	77c6                	ld	a5,112(sp)
    80005dc0:	7866                	ld	a6,120(sp)
    80005dc2:	688a                	ld	a7,128(sp)
    80005dc4:	692a                	ld	s2,136(sp)
    80005dc6:	69ca                	ld	s3,144(sp)
    80005dc8:	6a6a                	ld	s4,152(sp)
    80005dca:	7a8a                	ld	s5,160(sp)
    80005dcc:	7b2a                	ld	s6,168(sp)
    80005dce:	7bca                	ld	s7,176(sp)
    80005dd0:	7c6a                	ld	s8,184(sp)
    80005dd2:	6c8e                	ld	s9,192(sp)
    80005dd4:	6d2e                	ld	s10,200(sp)
    80005dd6:	6dce                	ld	s11,208(sp)
    80005dd8:	6e6e                	ld	t3,216(sp)
    80005dda:	7e8e                	ld	t4,224(sp)
    80005ddc:	7f2e                	ld	t5,232(sp)
    80005dde:	7fce                	ld	t6,240(sp)
    80005de0:	6111                	addi	sp,sp,256
    80005de2:	10200073          	sret
    80005de6:	00000013          	nop
    80005dea:	00000013          	nop
    80005dee:	0001                	nop

0000000080005df0 <timervec>:
    80005df0:	34051573          	csrrw	a0,mscratch,a0
    80005df4:	e10c                	sd	a1,0(a0)
    80005df6:	e510                	sd	a2,8(a0)
    80005df8:	e914                	sd	a3,16(a0)
    80005dfa:	6d0c                	ld	a1,24(a0)
    80005dfc:	7110                	ld	a2,32(a0)
    80005dfe:	6194                	ld	a3,0(a1)
    80005e00:	96b2                	add	a3,a3,a2
    80005e02:	e194                	sd	a3,0(a1)
    80005e04:	4589                	li	a1,2
    80005e06:	14459073          	csrw	sip,a1
    80005e0a:	6914                	ld	a3,16(a0)
    80005e0c:	6510                	ld	a2,8(a0)
    80005e0e:	610c                	ld	a1,0(a0)
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	30200073          	mret
	...

0000000080005e1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e1a:	1141                	addi	sp,sp,-16
    80005e1c:	e422                	sd	s0,8(sp)
    80005e1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e20:	0c0007b7          	lui	a5,0xc000
    80005e24:	4705                	li	a4,1
    80005e26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e28:	c3d8                	sw	a4,4(a5)
}
    80005e2a:	6422                	ld	s0,8(sp)
    80005e2c:	0141                	addi	sp,sp,16
    80005e2e:	8082                	ret

0000000080005e30 <plicinithart>:

void
plicinithart(void)
{
    80005e30:	1141                	addi	sp,sp,-16
    80005e32:	e406                	sd	ra,8(sp)
    80005e34:	e022                	sd	s0,0(sp)
    80005e36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b54080e7          	jalr	-1196(ra) # 8000198c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e40:	0085171b          	slliw	a4,a0,0x8
    80005e44:	0c0027b7          	lui	a5,0xc002
    80005e48:	97ba                	add	a5,a5,a4
    80005e4a:	40200713          	li	a4,1026
    80005e4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e52:	00d5151b          	slliw	a0,a0,0xd
    80005e56:	0c2017b7          	lui	a5,0xc201
    80005e5a:	953e                	add	a0,a0,a5
    80005e5c:	00052023          	sw	zero,0(a0)
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret

0000000080005e68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e68:	1141                	addi	sp,sp,-16
    80005e6a:	e406                	sd	ra,8(sp)
    80005e6c:	e022                	sd	s0,0(sp)
    80005e6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	b1c080e7          	jalr	-1252(ra) # 8000198c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e78:	00d5179b          	slliw	a5,a0,0xd
    80005e7c:	0c201537          	lui	a0,0xc201
    80005e80:	953e                	add	a0,a0,a5
  return irq;
}
    80005e82:	4148                	lw	a0,4(a0)
    80005e84:	60a2                	ld	ra,8(sp)
    80005e86:	6402                	ld	s0,0(sp)
    80005e88:	0141                	addi	sp,sp,16
    80005e8a:	8082                	ret

0000000080005e8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e8c:	1101                	addi	sp,sp,-32
    80005e8e:	ec06                	sd	ra,24(sp)
    80005e90:	e822                	sd	s0,16(sp)
    80005e92:	e426                	sd	s1,8(sp)
    80005e94:	1000                	addi	s0,sp,32
    80005e96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	af4080e7          	jalr	-1292(ra) # 8000198c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ea0:	00d5151b          	slliw	a0,a0,0xd
    80005ea4:	0c2017b7          	lui	a5,0xc201
    80005ea8:	97aa                	add	a5,a5,a0
    80005eaa:	c3c4                	sw	s1,4(a5)
}
    80005eac:	60e2                	ld	ra,24(sp)
    80005eae:	6442                	ld	s0,16(sp)
    80005eb0:	64a2                	ld	s1,8(sp)
    80005eb2:	6105                	addi	sp,sp,32
    80005eb4:	8082                	ret

0000000080005eb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005eb6:	1141                	addi	sp,sp,-16
    80005eb8:	e406                	sd	ra,8(sp)
    80005eba:	e022                	sd	s0,0(sp)
    80005ebc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ebe:	479d                	li	a5,7
    80005ec0:	06a7c963          	blt	a5,a0,80005f32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ec4:	00016797          	auipc	a5,0x16
    80005ec8:	13c78793          	addi	a5,a5,316 # 8001c000 <disk>
    80005ecc:	00a78733          	add	a4,a5,a0
    80005ed0:	6789                	lui	a5,0x2
    80005ed2:	97ba                	add	a5,a5,a4
    80005ed4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ed8:	e7ad                	bnez	a5,80005f42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eda:	00451793          	slli	a5,a0,0x4
    80005ede:	00018717          	auipc	a4,0x18
    80005ee2:	12270713          	addi	a4,a4,290 # 8001e000 <disk+0x2000>
    80005ee6:	6314                	ld	a3,0(a4)
    80005ee8:	96be                	add	a3,a3,a5
    80005eea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005eee:	6314                	ld	a3,0(a4)
    80005ef0:	96be                	add	a3,a3,a5
    80005ef2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ef6:	6314                	ld	a3,0(a4)
    80005ef8:	96be                	add	a3,a3,a5
    80005efa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005efe:	6318                	ld	a4,0(a4)
    80005f00:	97ba                	add	a5,a5,a4
    80005f02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f06:	00016797          	auipc	a5,0x16
    80005f0a:	0fa78793          	addi	a5,a5,250 # 8001c000 <disk>
    80005f0e:	97aa                	add	a5,a5,a0
    80005f10:	6509                	lui	a0,0x2
    80005f12:	953e                	add	a0,a0,a5
    80005f14:	4785                	li	a5,1
    80005f16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f1a:	00018517          	auipc	a0,0x18
    80005f1e:	0fe50513          	addi	a0,a0,254 # 8001e018 <disk+0x2018>
    80005f22:	ffffc097          	auipc	ra,0xffffc
    80005f26:	4b0080e7          	jalr	1200(ra) # 800023d2 <wakeup>
}
    80005f2a:	60a2                	ld	ra,8(sp)
    80005f2c:	6402                	ld	s0,0(sp)
    80005f2e:	0141                	addi	sp,sp,16
    80005f30:	8082                	ret
    panic("free_desc 1");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	86e50513          	addi	a0,a0,-1938 # 800087a0 <syscalls+0x330>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	86e50513          	addi	a0,a0,-1938 # 800087b0 <syscalls+0x340>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f4080e7          	jalr	1524(ra) # 8000053e <panic>

0000000080005f52 <virtio_disk_init>:
{
    80005f52:	1101                	addi	sp,sp,-32
    80005f54:	ec06                	sd	ra,24(sp)
    80005f56:	e822                	sd	s0,16(sp)
    80005f58:	e426                	sd	s1,8(sp)
    80005f5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f5c:	00003597          	auipc	a1,0x3
    80005f60:	86458593          	addi	a1,a1,-1948 # 800087c0 <syscalls+0x350>
    80005f64:	00018517          	auipc	a0,0x18
    80005f68:	1c450513          	addi	a0,a0,452 # 8001e128 <disk+0x2128>
    80005f6c:	ffffb097          	auipc	ra,0xffffb
    80005f70:	be8080e7          	jalr	-1048(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f74:	100017b7          	lui	a5,0x10001
    80005f78:	4398                	lw	a4,0(a5)
    80005f7a:	2701                	sext.w	a4,a4
    80005f7c:	747277b7          	lui	a5,0x74727
    80005f80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f84:	0ef71163          	bne	a4,a5,80006066 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f88:	100017b7          	lui	a5,0x10001
    80005f8c:	43dc                	lw	a5,4(a5)
    80005f8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f90:	4705                	li	a4,1
    80005f92:	0ce79a63          	bne	a5,a4,80006066 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f96:	100017b7          	lui	a5,0x10001
    80005f9a:	479c                	lw	a5,8(a5)
    80005f9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f9e:	4709                	li	a4,2
    80005fa0:	0ce79363          	bne	a5,a4,80006066 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fa4:	100017b7          	lui	a5,0x10001
    80005fa8:	47d8                	lw	a4,12(a5)
    80005faa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fac:	554d47b7          	lui	a5,0x554d4
    80005fb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fb4:	0af71963          	bne	a4,a5,80006066 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	4705                	li	a4,1
    80005fbe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc0:	470d                	li	a4,3
    80005fc2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fc4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fc6:	c7ffe737          	lui	a4,0xc7ffe
    80005fca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    80005fce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fd0:	2701                	sext.w	a4,a4
    80005fd2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd4:	472d                	li	a4,11
    80005fd6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd8:	473d                	li	a4,15
    80005fda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fdc:	6705                	lui	a4,0x1
    80005fde:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fe0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fe4:	5bdc                	lw	a5,52(a5)
    80005fe6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fe8:	c7d9                	beqz	a5,80006076 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fea:	471d                	li	a4,7
    80005fec:	08f77d63          	bgeu	a4,a5,80006086 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ff0:	100014b7          	lui	s1,0x10001
    80005ff4:	47a1                	li	a5,8
    80005ff6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ff8:	6609                	lui	a2,0x2
    80005ffa:	4581                	li	a1,0
    80005ffc:	00016517          	auipc	a0,0x16
    80006000:	00450513          	addi	a0,a0,4 # 8001c000 <disk>
    80006004:	ffffb097          	auipc	ra,0xffffb
    80006008:	cdc080e7          	jalr	-804(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000600c:	00016717          	auipc	a4,0x16
    80006010:	ff470713          	addi	a4,a4,-12 # 8001c000 <disk>
    80006014:	00c75793          	srli	a5,a4,0xc
    80006018:	2781                	sext.w	a5,a5
    8000601a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000601c:	00018797          	auipc	a5,0x18
    80006020:	fe478793          	addi	a5,a5,-28 # 8001e000 <disk+0x2000>
    80006024:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006026:	00016717          	auipc	a4,0x16
    8000602a:	05a70713          	addi	a4,a4,90 # 8001c080 <disk+0x80>
    8000602e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006030:	00017717          	auipc	a4,0x17
    80006034:	fd070713          	addi	a4,a4,-48 # 8001d000 <disk+0x1000>
    80006038:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000603a:	4705                	li	a4,1
    8000603c:	00e78c23          	sb	a4,24(a5)
    80006040:	00e78ca3          	sb	a4,25(a5)
    80006044:	00e78d23          	sb	a4,26(a5)
    80006048:	00e78da3          	sb	a4,27(a5)
    8000604c:	00e78e23          	sb	a4,28(a5)
    80006050:	00e78ea3          	sb	a4,29(a5)
    80006054:	00e78f23          	sb	a4,30(a5)
    80006058:	00e78fa3          	sb	a4,31(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6105                	addi	sp,sp,32
    80006064:	8082                	ret
    panic("could not find virtio disk");
    80006066:	00002517          	auipc	a0,0x2
    8000606a:	76a50513          	addi	a0,a0,1898 # 800087d0 <syscalls+0x360>
    8000606e:	ffffa097          	auipc	ra,0xffffa
    80006072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006076:	00002517          	auipc	a0,0x2
    8000607a:	77a50513          	addi	a0,a0,1914 # 800087f0 <syscalls+0x380>
    8000607e:	ffffa097          	auipc	ra,0xffffa
    80006082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006086:	00002517          	auipc	a0,0x2
    8000608a:	78a50513          	addi	a0,a0,1930 # 80008810 <syscalls+0x3a0>
    8000608e:	ffffa097          	auipc	ra,0xffffa
    80006092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>

0000000080006096 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006096:	7159                	addi	sp,sp,-112
    80006098:	f486                	sd	ra,104(sp)
    8000609a:	f0a2                	sd	s0,96(sp)
    8000609c:	eca6                	sd	s1,88(sp)
    8000609e:	e8ca                	sd	s2,80(sp)
    800060a0:	e4ce                	sd	s3,72(sp)
    800060a2:	e0d2                	sd	s4,64(sp)
    800060a4:	fc56                	sd	s5,56(sp)
    800060a6:	f85a                	sd	s6,48(sp)
    800060a8:	f45e                	sd	s7,40(sp)
    800060aa:	f062                	sd	s8,32(sp)
    800060ac:	ec66                	sd	s9,24(sp)
    800060ae:	e86a                	sd	s10,16(sp)
    800060b0:	1880                	addi	s0,sp,112
    800060b2:	892a                	mv	s2,a0
    800060b4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060b6:	00c52c83          	lw	s9,12(a0)
    800060ba:	001c9c9b          	slliw	s9,s9,0x1
    800060be:	1c82                	slli	s9,s9,0x20
    800060c0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060c4:	00018517          	auipc	a0,0x18
    800060c8:	06450513          	addi	a0,a0,100 # 8001e128 <disk+0x2128>
    800060cc:	ffffb097          	auipc	ra,0xffffb
    800060d0:	b18080e7          	jalr	-1256(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060d4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060d6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060d8:	00016b97          	auipc	s7,0x16
    800060dc:	f28b8b93          	addi	s7,s7,-216 # 8001c000 <disk>
    800060e0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060e2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060e4:	8a4e                	mv	s4,s3
    800060e6:	a051                	j	8000616a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060e8:	00fb86b3          	add	a3,s7,a5
    800060ec:	96da                	add	a3,a3,s6
    800060ee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060f2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060f4:	0207c563          	bltz	a5,8000611e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060f8:	2485                	addiw	s1,s1,1
    800060fa:	0711                	addi	a4,a4,4
    800060fc:	25548063          	beq	s1,s5,8000633c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006100:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006102:	00018697          	auipc	a3,0x18
    80006106:	f1668693          	addi	a3,a3,-234 # 8001e018 <disk+0x2018>
    8000610a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000610c:	0006c583          	lbu	a1,0(a3)
    80006110:	fde1                	bnez	a1,800060e8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006112:	2785                	addiw	a5,a5,1
    80006114:	0685                	addi	a3,a3,1
    80006116:	ff879be3          	bne	a5,s8,8000610c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000611a:	57fd                	li	a5,-1
    8000611c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000611e:	02905a63          	blez	s1,80006152 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006122:	f9042503          	lw	a0,-112(s0)
    80006126:	00000097          	auipc	ra,0x0
    8000612a:	d90080e7          	jalr	-624(ra) # 80005eb6 <free_desc>
      for(int j = 0; j < i; j++)
    8000612e:	4785                	li	a5,1
    80006130:	0297d163          	bge	a5,s1,80006152 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006134:	f9442503          	lw	a0,-108(s0)
    80006138:	00000097          	auipc	ra,0x0
    8000613c:	d7e080e7          	jalr	-642(ra) # 80005eb6 <free_desc>
      for(int j = 0; j < i; j++)
    80006140:	4789                	li	a5,2
    80006142:	0097d863          	bge	a5,s1,80006152 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006146:	f9842503          	lw	a0,-104(s0)
    8000614a:	00000097          	auipc	ra,0x0
    8000614e:	d6c080e7          	jalr	-660(ra) # 80005eb6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006152:	00018597          	auipc	a1,0x18
    80006156:	fd658593          	addi	a1,a1,-42 # 8001e128 <disk+0x2128>
    8000615a:	00018517          	auipc	a0,0x18
    8000615e:	ebe50513          	addi	a0,a0,-322 # 8001e018 <disk+0x2018>
    80006162:	ffffc097          	auipc	ra,0xffffc
    80006166:	0e4080e7          	jalr	228(ra) # 80002246 <sleep>
  for(int i = 0; i < 3; i++){
    8000616a:	f9040713          	addi	a4,s0,-112
    8000616e:	84ce                	mv	s1,s3
    80006170:	bf41                	j	80006100 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006172:	20058713          	addi	a4,a1,512
    80006176:	00471693          	slli	a3,a4,0x4
    8000617a:	00016717          	auipc	a4,0x16
    8000617e:	e8670713          	addi	a4,a4,-378 # 8001c000 <disk>
    80006182:	9736                	add	a4,a4,a3
    80006184:	4685                	li	a3,1
    80006186:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000618a:	20058713          	addi	a4,a1,512
    8000618e:	00471693          	slli	a3,a4,0x4
    80006192:	00016717          	auipc	a4,0x16
    80006196:	e6e70713          	addi	a4,a4,-402 # 8001c000 <disk>
    8000619a:	9736                	add	a4,a4,a3
    8000619c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061a0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061a4:	7679                	lui	a2,0xffffe
    800061a6:	963e                	add	a2,a2,a5
    800061a8:	00018697          	auipc	a3,0x18
    800061ac:	e5868693          	addi	a3,a3,-424 # 8001e000 <disk+0x2000>
    800061b0:	6298                	ld	a4,0(a3)
    800061b2:	9732                	add	a4,a4,a2
    800061b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061b6:	6298                	ld	a4,0(a3)
    800061b8:	9732                	add	a4,a4,a2
    800061ba:	4541                	li	a0,16
    800061bc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061be:	6298                	ld	a4,0(a3)
    800061c0:	9732                	add	a4,a4,a2
    800061c2:	4505                	li	a0,1
    800061c4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061c8:	f9442703          	lw	a4,-108(s0)
    800061cc:	6288                	ld	a0,0(a3)
    800061ce:	962a                	add	a2,a2,a0
    800061d0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061d4:	0712                	slli	a4,a4,0x4
    800061d6:	6290                	ld	a2,0(a3)
    800061d8:	963a                	add	a2,a2,a4
    800061da:	05890513          	addi	a0,s2,88
    800061de:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061e0:	6294                	ld	a3,0(a3)
    800061e2:	96ba                	add	a3,a3,a4
    800061e4:	40000613          	li	a2,1024
    800061e8:	c690                	sw	a2,8(a3)
  if(write)
    800061ea:	140d0063          	beqz	s10,8000632a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061ee:	00018697          	auipc	a3,0x18
    800061f2:	e126b683          	ld	a3,-494(a3) # 8001e000 <disk+0x2000>
    800061f6:	96ba                	add	a3,a3,a4
    800061f8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061fc:	00016817          	auipc	a6,0x16
    80006200:	e0480813          	addi	a6,a6,-508 # 8001c000 <disk>
    80006204:	00018517          	auipc	a0,0x18
    80006208:	dfc50513          	addi	a0,a0,-516 # 8001e000 <disk+0x2000>
    8000620c:	6114                	ld	a3,0(a0)
    8000620e:	96ba                	add	a3,a3,a4
    80006210:	00c6d603          	lhu	a2,12(a3)
    80006214:	00166613          	ori	a2,a2,1
    80006218:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000621c:	f9842683          	lw	a3,-104(s0)
    80006220:	6110                	ld	a2,0(a0)
    80006222:	9732                	add	a4,a4,a2
    80006224:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006228:	20058613          	addi	a2,a1,512
    8000622c:	0612                	slli	a2,a2,0x4
    8000622e:	9642                	add	a2,a2,a6
    80006230:	577d                	li	a4,-1
    80006232:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006236:	00469713          	slli	a4,a3,0x4
    8000623a:	6114                	ld	a3,0(a0)
    8000623c:	96ba                	add	a3,a3,a4
    8000623e:	03078793          	addi	a5,a5,48
    80006242:	97c2                	add	a5,a5,a6
    80006244:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006246:	611c                	ld	a5,0(a0)
    80006248:	97ba                	add	a5,a5,a4
    8000624a:	4685                	li	a3,1
    8000624c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000624e:	611c                	ld	a5,0(a0)
    80006250:	97ba                	add	a5,a5,a4
    80006252:	4809                	li	a6,2
    80006254:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006258:	611c                	ld	a5,0(a0)
    8000625a:	973e                	add	a4,a4,a5
    8000625c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006260:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006264:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006268:	6518                	ld	a4,8(a0)
    8000626a:	00275783          	lhu	a5,2(a4)
    8000626e:	8b9d                	andi	a5,a5,7
    80006270:	0786                	slli	a5,a5,0x1
    80006272:	97ba                	add	a5,a5,a4
    80006274:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006278:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000627c:	6518                	ld	a4,8(a0)
    8000627e:	00275783          	lhu	a5,2(a4)
    80006282:	2785                	addiw	a5,a5,1
    80006284:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006288:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000628c:	100017b7          	lui	a5,0x10001
    80006290:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006294:	00492703          	lw	a4,4(s2)
    80006298:	4785                	li	a5,1
    8000629a:	02f71163          	bne	a4,a5,800062bc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000629e:	00018997          	auipc	s3,0x18
    800062a2:	e8a98993          	addi	s3,s3,-374 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800062a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062a8:	85ce                	mv	a1,s3
    800062aa:	854a                	mv	a0,s2
    800062ac:	ffffc097          	auipc	ra,0xffffc
    800062b0:	f9a080e7          	jalr	-102(ra) # 80002246 <sleep>
  while(b->disk == 1) {
    800062b4:	00492783          	lw	a5,4(s2)
    800062b8:	fe9788e3          	beq	a5,s1,800062a8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062bc:	f9042903          	lw	s2,-112(s0)
    800062c0:	20090793          	addi	a5,s2,512
    800062c4:	00479713          	slli	a4,a5,0x4
    800062c8:	00016797          	auipc	a5,0x16
    800062cc:	d3878793          	addi	a5,a5,-712 # 8001c000 <disk>
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062d6:	00018997          	auipc	s3,0x18
    800062da:	d2a98993          	addi	s3,s3,-726 # 8001e000 <disk+0x2000>
    800062de:	00491713          	slli	a4,s2,0x4
    800062e2:	0009b783          	ld	a5,0(s3)
    800062e6:	97ba                	add	a5,a5,a4
    800062e8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062ec:	854a                	mv	a0,s2
    800062ee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062f2:	00000097          	auipc	ra,0x0
    800062f6:	bc4080e7          	jalr	-1084(ra) # 80005eb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062fa:	8885                	andi	s1,s1,1
    800062fc:	f0ed                	bnez	s1,800062de <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062fe:	00018517          	auipc	a0,0x18
    80006302:	e2a50513          	addi	a0,a0,-470 # 8001e128 <disk+0x2128>
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
}
    8000630e:	70a6                	ld	ra,104(sp)
    80006310:	7406                	ld	s0,96(sp)
    80006312:	64e6                	ld	s1,88(sp)
    80006314:	6946                	ld	s2,80(sp)
    80006316:	69a6                	ld	s3,72(sp)
    80006318:	6a06                	ld	s4,64(sp)
    8000631a:	7ae2                	ld	s5,56(sp)
    8000631c:	7b42                	ld	s6,48(sp)
    8000631e:	7ba2                	ld	s7,40(sp)
    80006320:	7c02                	ld	s8,32(sp)
    80006322:	6ce2                	ld	s9,24(sp)
    80006324:	6d42                	ld	s10,16(sp)
    80006326:	6165                	addi	sp,sp,112
    80006328:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000632a:	00018697          	auipc	a3,0x18
    8000632e:	cd66b683          	ld	a3,-810(a3) # 8001e000 <disk+0x2000>
    80006332:	96ba                	add	a3,a3,a4
    80006334:	4609                	li	a2,2
    80006336:	00c69623          	sh	a2,12(a3)
    8000633a:	b5c9                	j	800061fc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000633c:	f9042583          	lw	a1,-112(s0)
    80006340:	20058793          	addi	a5,a1,512
    80006344:	0792                	slli	a5,a5,0x4
    80006346:	00016517          	auipc	a0,0x16
    8000634a:	d6250513          	addi	a0,a0,-670 # 8001c0a8 <disk+0xa8>
    8000634e:	953e                	add	a0,a0,a5
  if(write)
    80006350:	e20d11e3          	bnez	s10,80006172 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006354:	20058713          	addi	a4,a1,512
    80006358:	00471693          	slli	a3,a4,0x4
    8000635c:	00016717          	auipc	a4,0x16
    80006360:	ca470713          	addi	a4,a4,-860 # 8001c000 <disk>
    80006364:	9736                	add	a4,a4,a3
    80006366:	0a072423          	sw	zero,168(a4)
    8000636a:	b505                	j	8000618a <virtio_disk_rw+0xf4>

000000008000636c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000636c:	1101                	addi	sp,sp,-32
    8000636e:	ec06                	sd	ra,24(sp)
    80006370:	e822                	sd	s0,16(sp)
    80006372:	e426                	sd	s1,8(sp)
    80006374:	e04a                	sd	s2,0(sp)
    80006376:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006378:	00018517          	auipc	a0,0x18
    8000637c:	db050513          	addi	a0,a0,-592 # 8001e128 <disk+0x2128>
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	864080e7          	jalr	-1948(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006388:	10001737          	lui	a4,0x10001
    8000638c:	533c                	lw	a5,96(a4)
    8000638e:	8b8d                	andi	a5,a5,3
    80006390:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006392:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006396:	00018797          	auipc	a5,0x18
    8000639a:	c6a78793          	addi	a5,a5,-918 # 8001e000 <disk+0x2000>
    8000639e:	6b94                	ld	a3,16(a5)
    800063a0:	0207d703          	lhu	a4,32(a5)
    800063a4:	0026d783          	lhu	a5,2(a3)
    800063a8:	06f70163          	beq	a4,a5,8000640a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ac:	00016917          	auipc	s2,0x16
    800063b0:	c5490913          	addi	s2,s2,-940 # 8001c000 <disk>
    800063b4:	00018497          	auipc	s1,0x18
    800063b8:	c4c48493          	addi	s1,s1,-948 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800063bc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063c0:	6898                	ld	a4,16(s1)
    800063c2:	0204d783          	lhu	a5,32(s1)
    800063c6:	8b9d                	andi	a5,a5,7
    800063c8:	078e                	slli	a5,a5,0x3
    800063ca:	97ba                	add	a5,a5,a4
    800063cc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063ce:	20078713          	addi	a4,a5,512
    800063d2:	0712                	slli	a4,a4,0x4
    800063d4:	974a                	add	a4,a4,s2
    800063d6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063da:	e731                	bnez	a4,80006426 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063dc:	20078793          	addi	a5,a5,512
    800063e0:	0792                	slli	a5,a5,0x4
    800063e2:	97ca                	add	a5,a5,s2
    800063e4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063e6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063ea:	ffffc097          	auipc	ra,0xffffc
    800063ee:	fe8080e7          	jalr	-24(ra) # 800023d2 <wakeup>

    disk.used_idx += 1;
    800063f2:	0204d783          	lhu	a5,32(s1)
    800063f6:	2785                	addiw	a5,a5,1
    800063f8:	17c2                	slli	a5,a5,0x30
    800063fa:	93c1                	srli	a5,a5,0x30
    800063fc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006400:	6898                	ld	a4,16(s1)
    80006402:	00275703          	lhu	a4,2(a4)
    80006406:	faf71be3          	bne	a4,a5,800063bc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000640a:	00018517          	auipc	a0,0x18
    8000640e:	d1e50513          	addi	a0,a0,-738 # 8001e128 <disk+0x2128>
    80006412:	ffffb097          	auipc	ra,0xffffb
    80006416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
}
    8000641a:	60e2                	ld	ra,24(sp)
    8000641c:	6442                	ld	s0,16(sp)
    8000641e:	64a2                	ld	s1,8(sp)
    80006420:	6902                	ld	s2,0(sp)
    80006422:	6105                	addi	sp,sp,32
    80006424:	8082                	ret
      panic("virtio_disk_intr status");
    80006426:	00002517          	auipc	a0,0x2
    8000642a:	40a50513          	addi	a0,a0,1034 # 80008830 <syscalls+0x3c0>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	110080e7          	jalr	272(ra) # 8000053e <panic>
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
