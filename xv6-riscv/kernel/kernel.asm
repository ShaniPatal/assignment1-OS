
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
    80000068:	dac78793          	addi	a5,a5,-596 # 80005e10 <timervec>
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
    80000130:	5ae080e7          	jalr	1454(ra) # 800026da <either_copyin>
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
    800001d8:	060080e7          	jalr	96(ra) # 80002234 <sleep>
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
    80000214:	474080e7          	jalr	1140(ra) # 80002684 <either_copyout>
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
    800002f6:	43e080e7          	jalr	1086(ra) # 80002730 <procdump>
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
    8000044a:	f7a080e7          	jalr	-134(ra) # 800023c0 <wakeup>
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
    8000047c:	e1078793          	addi	a5,a5,-496 # 8001a288 <devsw>
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
    800008a4:	b20080e7          	jalr	-1248(ra) # 800023c0 <wakeup>
    
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
    80000930:	908080e7          	jalr	-1784(ra) # 80002234 <sleep>
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
    80000ed8:	9d2080e7          	jalr	-1582(ra) # 800028a6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f74080e7          	jalr	-140(ra) # 80005e50 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	22e080e7          	jalr	558(ra) # 80002112 <scheduler>
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
    80000f58:	92a080e7          	jalr	-1750(ra) # 8000287e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	94a080e7          	jalr	-1718(ra) # 800028a6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	ed6080e7          	jalr	-298(ra) # 80005e3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	ee4080e7          	jalr	-284(ra) # 80005e50 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	0be080e7          	jalr	190(ra) # 80003032 <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	74e080e7          	jalr	1870(ra) # 800036ca <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	6f8080e7          	jalr	1784(ra) # 8000467c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	fe6080e7          	jalr	-26(ra) # 80005f72 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d04080e7          	jalr	-764(ra) # 80001c98 <userinit>
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
    80001876:	0000ea17          	auipc	s4,0xe
    8000187a:	7caa0a13          	addi	s4,s4,1994 # 80010040 <tickslock>
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
    800018b0:	17848493          	addi	s1,s1,376
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
    80001942:	0000e997          	auipc	s3,0xe
    80001946:	6fe98993          	addi	s3,s3,1790 # 80010040 <tickslock>
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
    80001970:	17848493          	addi	s1,s1,376
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
    80001a0c:	e487a783          	lw	a5,-440(a5) # 80008850 <first.1704>
    80001a10:	eb89                	bnez	a5,80001a22 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a12:	00001097          	auipc	ra,0x1
    80001a16:	eac080e7          	jalr	-340(ra) # 800028be <usertrapret>
}
    80001a1a:	60a2                	ld	ra,8(sp)
    80001a1c:	6402                	ld	s0,0(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret
    first = 0;
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	e207a723          	sw	zero,-466(a5) # 80008850 <first.1704>
    fsinit(ROOTDEV);
    80001a2a:	4505                	li	a0,1
    80001a2c:	00002097          	auipc	ra,0x2
    80001a30:	c1e080e7          	jalr	-994(ra) # 8000364a <fsinit>
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
    80001bda:	46a90913          	addi	s2,s2,1130 # 80010040 <tickslock>
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
    80001bf6:	17848493          	addi	s1,s1,376
    80001bfa:	ff2492e3          	bne	s1,s2,80001bde <allocproc+0x1c>
  return 0;
    80001bfe:	4481                	li	s1,0
    80001c00:	a8a9                	j	80001c5a <allocproc+0x98>
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
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	edc080e7          	jalr	-292(ra) # 80000af4 <kalloc>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
    80001c24:	c131                	beqz	a0,80001c68 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e54080e7          	jalr	-428(ra) # 80001a7c <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c34:	c531                	beqz	a0,80001c80 <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	06048513          	addi	a0,s1,96
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	0a0080e7          	jalr	160(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	da878793          	addi	a5,a5,-600 # 800019f0 <forkret>
    80001c50:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4bc                	sd	a5,104(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	f00080e7          	jalr	-256(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0x98>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ee8080e7          	jalr	-280(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0x98>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f20080e7          	jalr	-224(ra) # 80001bc2 <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	38a7b223          	sd	a0,900(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	ba858593          	addi	a1,a1,-1112 # 80008860 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	6ae080e7          	jalr	1710(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	14c080e7          	jalr	332(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	382080e7          	jalr	898(ra) # 80004078 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f90080e7          	jalr	-112(ra) # 80000c98 <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c90080e7          	jalr	-880(ra) # 800019b8 <myproc>
    80001d30:	892a                	mv	s2,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
    80001d34:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d38:	00904f63          	bgtz	s1,80001d56 <growproc+0x3c>
  } else if(n < 0){
    80001d3c:	0204cc63          	bltz	s1,80001d74 <growproc+0x5a>
  p->sz = sz;
    80001d40:	1602                	slli	a2,a2,0x20
    80001d42:	9201                	srli	a2,a2,0x20
    80001d44:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d48:	4501                	li	a0,0
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d56:	9e25                	addw	a2,a2,s1
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	6c8080e7          	jalr	1736(ra) # 8000142a <uvmalloc>
    80001d6a:	0005061b          	sext.w	a2,a0
    80001d6e:	fa69                	bnez	a2,80001d40 <growproc+0x26>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bfe1                	j	80001d4a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	9e25                	addw	a2,a2,s1
    80001d76:	1602                	slli	a2,a2,0x20
    80001d78:	9201                	srli	a2,a2,0x20
    80001d7a:	1582                	slli	a1,a1,0x20
    80001d7c:	9181                	srli	a1,a1,0x20
    80001d7e:	6928                	ld	a0,80(a0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	662080e7          	jalr	1634(ra) # 800013e2 <uvmdealloc>
    80001d88:	0005061b          	sext.w	a2,a0
    80001d8c:	bf55                	j	80001d40 <growproc+0x26>

0000000080001d8e <fork>:
{
    80001d8e:	7179                	addi	sp,sp,-48
    80001d90:	f406                	sd	ra,40(sp)
    80001d92:	f022                	sd	s0,32(sp)
    80001d94:	ec26                	sd	s1,24(sp)
    80001d96:	e84a                	sd	s2,16(sp)
    80001d98:	e44e                	sd	s3,8(sp)
    80001d9a:	e052                	sd	s4,0(sp)
    80001d9c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	c1a080e7          	jalr	-998(ra) # 800019b8 <myproc>
    80001da6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	e1a080e7          	jalr	-486(ra) # 80001bc2 <allocproc>
    80001db0:	10050b63          	beqz	a0,80001ec6 <fork+0x138>
    80001db4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db6:	04893603          	ld	a2,72(s2)
    80001dba:	692c                	ld	a1,80(a0)
    80001dbc:	05093503          	ld	a0,80(s2)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	7b6080e7          	jalr	1974(ra) # 80001576 <uvmcopy>
    80001dc8:	04054663          	bltz	a0,80001e14 <fork+0x86>
  np->sz = p->sz;
    80001dcc:	04893783          	ld	a5,72(s2)
    80001dd0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd4:	05893683          	ld	a3,88(s2)
    80001dd8:	87b6                	mv	a5,a3
    80001dda:	0589b703          	ld	a4,88(s3)
    80001dde:	12068693          	addi	a3,a3,288
    80001de2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de6:	6788                	ld	a0,8(a5)
    80001de8:	6b8c                	ld	a1,16(a5)
    80001dea:	6f90                	ld	a2,24(a5)
    80001dec:	01073023          	sd	a6,0(a4)
    80001df0:	e708                	sd	a0,8(a4)
    80001df2:	eb0c                	sd	a1,16(a4)
    80001df4:	ef10                	sd	a2,24(a4)
    80001df6:	02078793          	addi	a5,a5,32
    80001dfa:	02070713          	addi	a4,a4,32
    80001dfe:	fed792e3          	bne	a5,a3,80001de2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e02:	0589b783          	ld	a5,88(s3)
    80001e06:	0607b823          	sd	zero,112(a5)
    80001e0a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e0e:	15000a13          	li	s4,336
    80001e12:	a03d                	j	80001e40 <fork+0xb2>
    freeproc(np);
    80001e14:	854e                	mv	a0,s3
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	d54080e7          	jalr	-684(ra) # 80001b6a <freeproc>
    release(&np->lock);
    80001e1e:	854e                	mv	a0,s3
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	e78080e7          	jalr	-392(ra) # 80000c98 <release>
    return -1;
    80001e28:	5a7d                	li	s4,-1
    80001e2a:	a069                	j	80001eb4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2c:	00003097          	auipc	ra,0x3
    80001e30:	8e2080e7          	jalr	-1822(ra) # 8000470e <filedup>
    80001e34:	009987b3          	add	a5,s3,s1
    80001e38:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3a:	04a1                	addi	s1,s1,8
    80001e3c:	01448763          	beq	s1,s4,80001e4a <fork+0xbc>
    if(p->ofile[i])
    80001e40:	009907b3          	add	a5,s2,s1
    80001e44:	6388                	ld	a0,0(a5)
    80001e46:	f17d                	bnez	a0,80001e2c <fork+0x9e>
    80001e48:	bfcd                	j	80001e3a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4a:	15093503          	ld	a0,336(s2)
    80001e4e:	00002097          	auipc	ra,0x2
    80001e52:	a36080e7          	jalr	-1482(ra) # 80003884 <idup>
    80001e56:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5a:	4641                	li	a2,16
    80001e5c:	15890593          	addi	a1,s2,344
    80001e60:	15898513          	addi	a0,s3,344
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	fce080e7          	jalr	-50(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e6c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e70:	854e                	mv	a0,s3
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	e26080e7          	jalr	-474(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e7a:	00008497          	auipc	s1,0x8
    80001e7e:	32e48493          	addi	s1,s1,814 # 8000a1a8 <wait_lock>
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	d60080e7          	jalr	-672(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e8c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ea4:	478d                	li	a5,3
    80001ea6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eaa:	854e                	mv	a0,s3
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	dec080e7          	jalr	-532(ra) # 80000c98 <release>
}
    80001eb4:	8552                	mv	a0,s4
    80001eb6:	70a2                	ld	ra,40(sp)
    80001eb8:	7402                	ld	s0,32(sp)
    80001eba:	64e2                	ld	s1,24(sp)
    80001ebc:	6942                	ld	s2,16(sp)
    80001ebe:	69a2                	ld	s3,8(sp)
    80001ec0:	6a02                	ld	s4,0(sp)
    80001ec2:	6145                	addi	sp,sp,48
    80001ec4:	8082                	ret
    return -1;
    80001ec6:	5a7d                	li	s4,-1
    80001ec8:	b7f5                	j	80001eb4 <fork+0x126>

0000000080001eca <round_robin>:
round_robin(){
    80001eca:	711d                	addi	sp,sp,-96
    80001ecc:	ec86                	sd	ra,88(sp)
    80001ece:	e8a2                	sd	s0,80(sp)
    80001ed0:	e4a6                	sd	s1,72(sp)
    80001ed2:	e0ca                	sd	s2,64(sp)
    80001ed4:	fc4e                	sd	s3,56(sp)
    80001ed6:	f852                	sd	s4,48(sp)
    80001ed8:	f456                	sd	s5,40(sp)
    80001eda:	f05a                	sd	s6,32(sp)
    80001edc:	ec5e                	sd	s7,24(sp)
    80001ede:	e862                	sd	s8,16(sp)
    80001ee0:	e466                	sd	s9,8(sp)
    80001ee2:	1080                	addi	s0,sp,96
    printf("Round Robin Policy \n");
    80001ee4:	00006517          	auipc	a0,0x6
    80001ee8:	33450513          	addi	a0,a0,820 # 80008218 <digits+0x1d8>
    80001eec:	ffffe097          	auipc	ra,0xffffe
    80001ef0:	69c080e7          	jalr	1692(ra) # 80000588 <printf>
    80001ef4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef8:	00779c13          	slli	s8,a5,0x7
    80001efc:	00008717          	auipc	a4,0x8
    80001f00:	29470713          	addi	a4,a4,660 # 8000a190 <pid_lock>
    80001f04:	9762                	add	a4,a4,s8
    80001f06:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f0a:	00008717          	auipc	a4,0x8
    80001f0e:	2be70713          	addi	a4,a4,702 # 8000a1c8 <cpus+0x8>
    80001f12:	9c3a                	add	s8,s8,a4
          c->proc = p;
    80001f14:	079e                	slli	a5,a5,0x7
    80001f16:	00008a97          	auipc	s5,0x8
    80001f1a:	27aa8a93          	addi	s5,s5,634 # 8000a190 <pid_lock>
    80001f1e:	9abe                	add	s5,s5,a5
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f20:	00007b17          	auipc	s6,0x7
    80001f24:	108b0b13          	addi	s6,s6,264 # 80009028 <pause_time>
            if(ticks >= pause_time){
    80001f28:	00007c97          	auipc	s9,0x7
    80001f2c:	110c8c93          	addi	s9,s9,272 # 80009038 <ticks>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f38:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3c:	00008497          	auipc	s1,0x8
    80001f40:	30448493          	addi	s1,s1,772 # 8000a240 <proc>
        if(p->state == RUNNABLE) {
    80001f44:	4a0d                	li	s4,3
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f46:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	0000e997          	auipc	s3,0xe
    80001f4c:	0f898993          	addi	s3,s3,248 # 80010040 <tickslock>
    80001f50:	a80d                	j	80001f82 <round_robin+0xb8>
              pause_time = 0;
    80001f52:	000b2023          	sw	zero,0(s6)
          p->state = RUNNING;
    80001f56:	4791                	li	a5,4
    80001f58:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001f5a:	029ab823          	sd	s1,48(s5)
          swtch(&c->context, &p->context);
    80001f5e:	06090593          	addi	a1,s2,96
    80001f62:	8562                	mv	a0,s8
    80001f64:	00001097          	auipc	ra,0x1
    80001f68:	8b0080e7          	jalr	-1872(ra) # 80002814 <swtch>
          c->proc = 0;
    80001f6c:	020ab823          	sd	zero,48(s5)
        release(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d26080e7          	jalr	-730(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7a:	17848493          	addi	s1,s1,376
    80001f7e:	fb3489e3          	beq	s1,s3,80001f30 <round_robin+0x66>
        acquire(&p->lock);
    80001f82:	8926                	mv	s2,s1
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	c5e080e7          	jalr	-930(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f8e:	4c9c                	lw	a5,24(s1)
    80001f90:	ff4790e3          	bne	a5,s4,80001f70 <round_robin+0xa6>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f94:	589c                	lw	a5,48(s1)
    80001f96:	37fd                	addiw	a5,a5,-1
    80001f98:	fafbffe3          	bgeu	s7,a5,80001f56 <round_robin+0x8c>
    80001f9c:	000b2783          	lw	a5,0(s6)
    80001fa0:	dbdd                	beqz	a5,80001f56 <round_robin+0x8c>
            if(ticks >= pause_time){
    80001fa2:	000ca703          	lw	a4,0(s9)
    80001fa6:	faf776e3          	bgeu	a4,a5,80001f52 <round_robin+0x88>
              release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	cec080e7          	jalr	-788(ra) # 80000c98 <release>
              continue;
    80001fb4:	b7d9                	j	80001f7a <round_robin+0xb0>

0000000080001fb6 <sjf>:
sjf(void){
    80001fb6:	711d                	addi	sp,sp,-96
    80001fb8:	ec86                	sd	ra,88(sp)
    80001fba:	e8a2                	sd	s0,80(sp)
    80001fbc:	e4a6                	sd	s1,72(sp)
    80001fbe:	e0ca                	sd	s2,64(sp)
    80001fc0:	fc4e                	sd	s3,56(sp)
    80001fc2:	f852                	sd	s4,48(sp)
    80001fc4:	f456                	sd	s5,40(sp)
    80001fc6:	f05a                	sd	s6,32(sp)
    80001fc8:	ec5e                	sd	s7,24(sp)
    80001fca:	e862                	sd	s8,16(sp)
    80001fcc:	e466                	sd	s9,8(sp)
    80001fce:	1080                	addi	s0,sp,96
  printf("SJF Policy \n");
    80001fd0:	00006517          	auipc	a0,0x6
    80001fd4:	26050513          	addi	a0,a0,608 # 80008230 <digits+0x1f0>
    80001fd8:	ffffe097          	auipc	ra,0xffffe
    80001fdc:	5b0080e7          	jalr	1456(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe0:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe4:	00779c93          	slli	s9,a5,0x7
    80001fe8:	00008717          	auipc	a4,0x8
    80001fec:	1a870713          	addi	a4,a4,424 # 8000a190 <pid_lock>
    80001ff0:	9766                	add	a4,a4,s9
    80001ff2:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001ff6:	00008717          	auipc	a4,0x8
    80001ffa:	1d270713          	addi	a4,a4,466 # 8000a1c8 <cpus+0x8>
    80001ffe:	9cba                	add	s9,s9,a4
  struct proc *min_proc = proc;
    80002000:	00008b17          	auipc	s6,0x8
    80002004:	240b0b13          	addi	s6,s6,576 # 8000a240 <proc>
    int min = INT_MAX;
    80002008:	80000bb7          	lui	s7,0x80000
    8000200c:	fffbcb93          	not	s7,s7
      if(pause_time != 0){  
    80002010:	00007917          	auipc	s2,0x7
    80002014:	01890913          	addi	s2,s2,24 # 80009028 <pause_time>
          if(ticks >= pause_time){
    80002018:	00007a97          	auipc	s5,0x7
    8000201c:	020a8a93          	addi	s5,s5,32 # 80009038 <ticks>
          c->proc = min_proc;
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	00008c17          	auipc	s8,0x8
    80002026:	16ec0c13          	addi	s8,s8,366 # 8000a190 <pid_lock>
    8000202a:	9c3e                	add	s8,s8,a5
    8000202c:	a0d9                	j	800020f2 <sjf+0x13c>
            pause_time = 0;
    8000202e:	00092023          	sw	zero,0(s2)
        release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    8000203c:	17848493          	addi	s1,s1,376
    80002040:	03348c63          	beq	s1,s3,80002078 <sjf+0xc2>
      acquire(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	b9e080e7          	jalr	-1122(ra) # 80000be4 <acquire>
      if(pause_time != 0){  
    8000204e:	00092783          	lw	a5,0(s2)
    80002052:	cb99                	beqz	a5,80002068 <sjf+0xb2>
          if(ticks >= pause_time){
    80002054:	000aa703          	lw	a4,0(s5)
    80002058:	fcf77be3          	bgeu	a4,a5,8000202e <sjf+0x78>
           release(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c3a080e7          	jalr	-966(ra) # 80000c98 <release>
           continue;
    80002066:	bfd9                	j	8000203c <sjf+0x86>
      else if(p->mean_ticks < min){
    80002068:	1684b783          	ld	a5,360(s1)
    8000206c:	fd47f3e3          	bgeu	a5,s4,80002032 <sjf+0x7c>
              min = p->mean_ticks;
    80002070:	00078a1b          	sext.w	s4,a5
    80002074:	8b26                	mv	s6,s1
    80002076:	bf75                	j	80002032 <sjf+0x7c>
      acquire(&min_proc->lock);
    80002078:	84da                	mv	s1,s6
    8000207a:	855a                	mv	a0,s6
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
        if(min_proc->state == RUNNABLE) {
    80002084:	018b2703          	lw	a4,24(s6)
    80002088:	478d                	li	a5,3
    8000208a:	04f71f63          	bne	a4,a5,800020e8 <sjf+0x132>
          min_proc->state = RUNNING;
    8000208e:	4791                	li	a5,4
    80002090:	00fb2c23          	sw	a5,24(s6)
          c->proc = min_proc;
    80002094:	036c3823          	sd	s6,48(s8)
          start_cpu_brust = ticks;
    80002098:	000aa983          	lw	s3,0(s5)
          swtch(&c->context, &p->context);
    8000209c:	0000e597          	auipc	a1,0xe
    800020a0:	00458593          	addi	a1,a1,4 # 800100a0 <bcache+0x48>
    800020a4:	8566                	mv	a0,s9
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	76e080e7          	jalr	1902(ra) # 80002814 <swtch>
          min_proc->last_ticks = end_cpu_brust-start_cpu_brust;
    800020ae:	000aa703          	lw	a4,0(s5)
    800020b2:	413706bb          	subw	a3,a4,s3
    800020b6:	16db3823          	sd	a3,368(s6)
          min_proc->mean_ticks = ((10*rate)* min_proc->mean_ticks + min_proc->last_ticks*(rate))/10;          
    800020ba:	00006717          	auipc	a4,0x6
    800020be:	79a72703          	lw	a4,1946(a4) # 80008854 <rate>
    800020c2:	0027179b          	slliw	a5,a4,0x2
    800020c6:	9fb9                	addw	a5,a5,a4
    800020c8:	0017979b          	slliw	a5,a5,0x1
    800020cc:	168b3603          	ld	a2,360(s6)
    800020d0:	02c787b3          	mul	a5,a5,a2
    800020d4:	02d70733          	mul	a4,a4,a3
    800020d8:	97ba                	add	a5,a5,a4
    800020da:	4729                	li	a4,10
    800020dc:	02e7d7b3          	divu	a5,a5,a4
    800020e0:	16fb3423          	sd	a5,360(s6)
          c->proc = 0;
    800020e4:	020c3823          	sd	zero,48(s8)
        release(&min_proc->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	bae080e7          	jalr	-1106(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020f6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020fa:	10079073          	csrw	sstatus,a5
    int min = INT_MAX;
    800020fe:	8a5e                	mv	s4,s7
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002100:	00008497          	auipc	s1,0x8
    80002104:	14048493          	addi	s1,s1,320 # 8000a240 <proc>
    80002108:	0000e997          	auipc	s3,0xe
    8000210c:	f3898993          	addi	s3,s3,-200 # 80010040 <tickslock>
    80002110:	bf15                	j	80002044 <sjf+0x8e>

0000000080002112 <scheduler>:
{
    80002112:	1141                	addi	sp,sp,-16
    80002114:	e406                	sd	ra,8(sp)
    80002116:	e022                	sd	s0,0(sp)
    80002118:	0800                	addi	s0,sp,16
    sjf();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	e9c080e7          	jalr	-356(ra) # 80001fb6 <sjf>

0000000080002122 <sched>:
{
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	888080e7          	jalr	-1912(ra) # 800019b8 <myproc>
    80002138:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	a30080e7          	jalr	-1488(ra) # 80000b6a <holding>
    80002142:	c93d                	beqz	a0,800021b8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002144:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002146:	2781                	sext.w	a5,a5
    80002148:	079e                	slli	a5,a5,0x7
    8000214a:	00008717          	auipc	a4,0x8
    8000214e:	04670713          	addi	a4,a4,70 # 8000a190 <pid_lock>
    80002152:	97ba                	add	a5,a5,a4
    80002154:	0a87a703          	lw	a4,168(a5)
    80002158:	4785                	li	a5,1
    8000215a:	06f71763          	bne	a4,a5,800021c8 <sched+0xa6>
  if(p->state == RUNNING)
    8000215e:	4c98                	lw	a4,24(s1)
    80002160:	4791                	li	a5,4
    80002162:	06f70b63          	beq	a4,a5,800021d8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002166:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000216a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000216c:	efb5                	bnez	a5,800021e8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000216e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002170:	00008917          	auipc	s2,0x8
    80002174:	02090913          	addi	s2,s2,32 # 8000a190 <pid_lock>
    80002178:	2781                	sext.w	a5,a5
    8000217a:	079e                	slli	a5,a5,0x7
    8000217c:	97ca                	add	a5,a5,s2
    8000217e:	0ac7a983          	lw	s3,172(a5)
    80002182:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002184:	2781                	sext.w	a5,a5
    80002186:	079e                	slli	a5,a5,0x7
    80002188:	00008597          	auipc	a1,0x8
    8000218c:	04058593          	addi	a1,a1,64 # 8000a1c8 <cpus+0x8>
    80002190:	95be                	add	a1,a1,a5
    80002192:	06048513          	addi	a0,s1,96
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	67e080e7          	jalr	1662(ra) # 80002814 <swtch>
    8000219e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021a0:	2781                	sext.w	a5,a5
    800021a2:	079e                	slli	a5,a5,0x7
    800021a4:	97ca                	add	a5,a5,s2
    800021a6:	0b37a623          	sw	s3,172(a5)
}
    800021aa:	70a2                	ld	ra,40(sp)
    800021ac:	7402                	ld	s0,32(sp)
    800021ae:	64e2                	ld	s1,24(sp)
    800021b0:	6942                	ld	s2,16(sp)
    800021b2:	69a2                	ld	s3,8(sp)
    800021b4:	6145                	addi	sp,sp,48
    800021b6:	8082                	ret
    panic("sched p->lock");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	08850513          	addi	a0,a0,136 # 80008240 <digits+0x200>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	37e080e7          	jalr	894(ra) # 8000053e <panic>
    panic("sched locks");
    800021c8:	00006517          	auipc	a0,0x6
    800021cc:	08850513          	addi	a0,a0,136 # 80008250 <digits+0x210>
    800021d0:	ffffe097          	auipc	ra,0xffffe
    800021d4:	36e080e7          	jalr	878(ra) # 8000053e <panic>
    panic("sched running");
    800021d8:	00006517          	auipc	a0,0x6
    800021dc:	08850513          	addi	a0,a0,136 # 80008260 <digits+0x220>
    800021e0:	ffffe097          	auipc	ra,0xffffe
    800021e4:	35e080e7          	jalr	862(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021e8:	00006517          	auipc	a0,0x6
    800021ec:	08850513          	addi	a0,a0,136 # 80008270 <digits+0x230>
    800021f0:	ffffe097          	auipc	ra,0xffffe
    800021f4:	34e080e7          	jalr	846(ra) # 8000053e <panic>

00000000800021f8 <yield>:
{
    800021f8:	1101                	addi	sp,sp,-32
    800021fa:	ec06                	sd	ra,24(sp)
    800021fc:	e822                	sd	s0,16(sp)
    800021fe:	e426                	sd	s1,8(sp)
    80002200:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	7b6080e7          	jalr	1974(ra) # 800019b8 <myproc>
    8000220a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	9d8080e7          	jalr	-1576(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002214:	478d                	li	a5,3
    80002216:	cc9c                	sw	a5,24(s1)
  sched();
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	f0a080e7          	jalr	-246(ra) # 80002122 <sched>
  release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
}
    8000222a:	60e2                	ld	ra,24(sp)
    8000222c:	6442                	ld	s0,16(sp)
    8000222e:	64a2                	ld	s1,8(sp)
    80002230:	6105                	addi	sp,sp,32
    80002232:	8082                	ret

0000000080002234 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002234:	7179                	addi	sp,sp,-48
    80002236:	f406                	sd	ra,40(sp)
    80002238:	f022                	sd	s0,32(sp)
    8000223a:	ec26                	sd	s1,24(sp)
    8000223c:	e84a                	sd	s2,16(sp)
    8000223e:	e44e                	sd	s3,8(sp)
    80002240:	1800                	addi	s0,sp,48
    80002242:	89aa                	mv	s3,a0
    80002244:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	772080e7          	jalr	1906(ra) # 800019b8 <myproc>
    8000224e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	994080e7          	jalr	-1644(ra) # 80000be4 <acquire>
  release(lk);
    80002258:	854a                	mv	a0,s2
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a3e080e7          	jalr	-1474(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002262:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002266:	4789                	li	a5,2
    80002268:	cc9c                	sw	a5,24(s1)

  sched();
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	eb8080e7          	jalr	-328(ra) # 80002122 <sched>

  // Tidy up.
  p->chan = 0;
    80002272:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a20080e7          	jalr	-1504(ra) # 80000c98 <release>
  acquire(lk);
    80002280:	854a                	mv	a0,s2
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	962080e7          	jalr	-1694(ra) # 80000be4 <acquire>
}
    8000228a:	70a2                	ld	ra,40(sp)
    8000228c:	7402                	ld	s0,32(sp)
    8000228e:	64e2                	ld	s1,24(sp)
    80002290:	6942                	ld	s2,16(sp)
    80002292:	69a2                	ld	s3,8(sp)
    80002294:	6145                	addi	sp,sp,48
    80002296:	8082                	ret

0000000080002298 <wait>:
{
    80002298:	715d                	addi	sp,sp,-80
    8000229a:	e486                	sd	ra,72(sp)
    8000229c:	e0a2                	sd	s0,64(sp)
    8000229e:	fc26                	sd	s1,56(sp)
    800022a0:	f84a                	sd	s2,48(sp)
    800022a2:	f44e                	sd	s3,40(sp)
    800022a4:	f052                	sd	s4,32(sp)
    800022a6:	ec56                	sd	s5,24(sp)
    800022a8:	e85a                	sd	s6,16(sp)
    800022aa:	e45e                	sd	s7,8(sp)
    800022ac:	e062                	sd	s8,0(sp)
    800022ae:	0880                	addi	s0,sp,80
    800022b0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	706080e7          	jalr	1798(ra) # 800019b8 <myproc>
    800022ba:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022bc:	00008517          	auipc	a0,0x8
    800022c0:	eec50513          	addi	a0,a0,-276 # 8000a1a8 <wait_lock>
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	920080e7          	jalr	-1760(ra) # 80000be4 <acquire>
    havekids = 0;
    800022cc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ce:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022d0:	0000e997          	auipc	s3,0xe
    800022d4:	d7098993          	addi	s3,s3,-656 # 80010040 <tickslock>
        havekids = 1;
    800022d8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022da:	00008c17          	auipc	s8,0x8
    800022de:	ecec0c13          	addi	s8,s8,-306 # 8000a1a8 <wait_lock>
    havekids = 0;
    800022e2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022e4:	00008497          	auipc	s1,0x8
    800022e8:	f5c48493          	addi	s1,s1,-164 # 8000a240 <proc>
    800022ec:	a0bd                	j	8000235a <wait+0xc2>
          pid = np->pid;
    800022ee:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022f2:	000b0e63          	beqz	s6,8000230e <wait+0x76>
    800022f6:	4691                	li	a3,4
    800022f8:	02c48613          	addi	a2,s1,44
    800022fc:	85da                	mv	a1,s6
    800022fe:	05093503          	ld	a0,80(s2)
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	378080e7          	jalr	888(ra) # 8000167a <copyout>
    8000230a:	02054563          	bltz	a0,80002334 <wait+0x9c>
          freeproc(np);
    8000230e:	8526                	mv	a0,s1
    80002310:	00000097          	auipc	ra,0x0
    80002314:	85a080e7          	jalr	-1958(ra) # 80001b6a <freeproc>
          release(&np->lock);
    80002318:	8526                	mv	a0,s1
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
          release(&wait_lock);
    80002322:	00008517          	auipc	a0,0x8
    80002326:	e8650513          	addi	a0,a0,-378 # 8000a1a8 <wait_lock>
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	96e080e7          	jalr	-1682(ra) # 80000c98 <release>
          return pid;
    80002332:	a09d                	j	80002398 <wait+0x100>
            release(&np->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
            release(&wait_lock);
    8000233e:	00008517          	auipc	a0,0x8
    80002342:	e6a50513          	addi	a0,a0,-406 # 8000a1a8 <wait_lock>
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
            return -1;
    8000234e:	59fd                	li	s3,-1
    80002350:	a0a1                	j	80002398 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002352:	17848493          	addi	s1,s1,376
    80002356:	03348463          	beq	s1,s3,8000237e <wait+0xe6>
      if(np->parent == p){
    8000235a:	7c9c                	ld	a5,56(s1)
    8000235c:	ff279be3          	bne	a5,s2,80002352 <wait+0xba>
        acquire(&np->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	882080e7          	jalr	-1918(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000236a:	4c9c                	lw	a5,24(s1)
    8000236c:	f94781e3          	beq	a5,s4,800022ee <wait+0x56>
        release(&np->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	926080e7          	jalr	-1754(ra) # 80000c98 <release>
        havekids = 1;
    8000237a:	8756                	mv	a4,s5
    8000237c:	bfd9                	j	80002352 <wait+0xba>
    if(!havekids || p->killed){
    8000237e:	c701                	beqz	a4,80002386 <wait+0xee>
    80002380:	02892783          	lw	a5,40(s2)
    80002384:	c79d                	beqz	a5,800023b2 <wait+0x11a>
      release(&wait_lock);
    80002386:	00008517          	auipc	a0,0x8
    8000238a:	e2250513          	addi	a0,a0,-478 # 8000a1a8 <wait_lock>
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	90a080e7          	jalr	-1782(ra) # 80000c98 <release>
      return -1;
    80002396:	59fd                	li	s3,-1
}
    80002398:	854e                	mv	a0,s3
    8000239a:	60a6                	ld	ra,72(sp)
    8000239c:	6406                	ld	s0,64(sp)
    8000239e:	74e2                	ld	s1,56(sp)
    800023a0:	7942                	ld	s2,48(sp)
    800023a2:	79a2                	ld	s3,40(sp)
    800023a4:	7a02                	ld	s4,32(sp)
    800023a6:	6ae2                	ld	s5,24(sp)
    800023a8:	6b42                	ld	s6,16(sp)
    800023aa:	6ba2                	ld	s7,8(sp)
    800023ac:	6c02                	ld	s8,0(sp)
    800023ae:	6161                	addi	sp,sp,80
    800023b0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023b2:	85e2                	mv	a1,s8
    800023b4:	854a                	mv	a0,s2
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	e7e080e7          	jalr	-386(ra) # 80002234 <sleep>
    havekids = 0;
    800023be:	b715                	j	800022e2 <wait+0x4a>

00000000800023c0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023c0:	7139                	addi	sp,sp,-64
    800023c2:	fc06                	sd	ra,56(sp)
    800023c4:	f822                	sd	s0,48(sp)
    800023c6:	f426                	sd	s1,40(sp)
    800023c8:	f04a                	sd	s2,32(sp)
    800023ca:	ec4e                	sd	s3,24(sp)
    800023cc:	e852                	sd	s4,16(sp)
    800023ce:	e456                	sd	s5,8(sp)
    800023d0:	0080                	addi	s0,sp,64
    800023d2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023d4:	00008497          	auipc	s1,0x8
    800023d8:	e6c48493          	addi	s1,s1,-404 # 8000a240 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023dc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023de:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e0:	0000e917          	auipc	s2,0xe
    800023e4:	c6090913          	addi	s2,s2,-928 # 80010040 <tickslock>
    800023e8:	a821                	j	80002400 <wakeup+0x40>
        p->state = RUNNABLE;
    800023ea:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800023ee:	8526                	mv	a0,s1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	8a8080e7          	jalr	-1880(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f8:	17848493          	addi	s1,s1,376
    800023fc:	03248463          	beq	s1,s2,80002424 <wakeup+0x64>
    if(p != myproc()){
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	5b8080e7          	jalr	1464(ra) # 800019b8 <myproc>
    80002408:	fea488e3          	beq	s1,a0,800023f8 <wakeup+0x38>
      acquire(&p->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7d6080e7          	jalr	2006(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002416:	4c9c                	lw	a5,24(s1)
    80002418:	fd379be3          	bne	a5,s3,800023ee <wakeup+0x2e>
    8000241c:	709c                	ld	a5,32(s1)
    8000241e:	fd4798e3          	bne	a5,s4,800023ee <wakeup+0x2e>
    80002422:	b7e1                	j	800023ea <wakeup+0x2a>
    }
  }
}
    80002424:	70e2                	ld	ra,56(sp)
    80002426:	7442                	ld	s0,48(sp)
    80002428:	74a2                	ld	s1,40(sp)
    8000242a:	7902                	ld	s2,32(sp)
    8000242c:	69e2                	ld	s3,24(sp)
    8000242e:	6a42                	ld	s4,16(sp)
    80002430:	6aa2                	ld	s5,8(sp)
    80002432:	6121                	addi	sp,sp,64
    80002434:	8082                	ret

0000000080002436 <reparent>:
{
    80002436:	7179                	addi	sp,sp,-48
    80002438:	f406                	sd	ra,40(sp)
    8000243a:	f022                	sd	s0,32(sp)
    8000243c:	ec26                	sd	s1,24(sp)
    8000243e:	e84a                	sd	s2,16(sp)
    80002440:	e44e                	sd	s3,8(sp)
    80002442:	e052                	sd	s4,0(sp)
    80002444:	1800                	addi	s0,sp,48
    80002446:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002448:	00008497          	auipc	s1,0x8
    8000244c:	df848493          	addi	s1,s1,-520 # 8000a240 <proc>
      pp->parent = initproc;
    80002450:	00007a17          	auipc	s4,0x7
    80002454:	be0a0a13          	addi	s4,s4,-1056 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002458:	0000e997          	auipc	s3,0xe
    8000245c:	be898993          	addi	s3,s3,-1048 # 80010040 <tickslock>
    80002460:	a029                	j	8000246a <reparent+0x34>
    80002462:	17848493          	addi	s1,s1,376
    80002466:	01348d63          	beq	s1,s3,80002480 <reparent+0x4a>
    if(pp->parent == p){
    8000246a:	7c9c                	ld	a5,56(s1)
    8000246c:	ff279be3          	bne	a5,s2,80002462 <reparent+0x2c>
      pp->parent = initproc;
    80002470:	000a3503          	ld	a0,0(s4)
    80002474:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002476:	00000097          	auipc	ra,0x0
    8000247a:	f4a080e7          	jalr	-182(ra) # 800023c0 <wakeup>
    8000247e:	b7d5                	j	80002462 <reparent+0x2c>
}
    80002480:	70a2                	ld	ra,40(sp)
    80002482:	7402                	ld	s0,32(sp)
    80002484:	64e2                	ld	s1,24(sp)
    80002486:	6942                	ld	s2,16(sp)
    80002488:	69a2                	ld	s3,8(sp)
    8000248a:	6a02                	ld	s4,0(sp)
    8000248c:	6145                	addi	sp,sp,48
    8000248e:	8082                	ret

0000000080002490 <exit>:
{
    80002490:	7179                	addi	sp,sp,-48
    80002492:	f406                	sd	ra,40(sp)
    80002494:	f022                	sd	s0,32(sp)
    80002496:	ec26                	sd	s1,24(sp)
    80002498:	e84a                	sd	s2,16(sp)
    8000249a:	e44e                	sd	s3,8(sp)
    8000249c:	e052                	sd	s4,0(sp)
    8000249e:	1800                	addi	s0,sp,48
    800024a0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	516080e7          	jalr	1302(ra) # 800019b8 <myproc>
    800024aa:	89aa                	mv	s3,a0
  if(p == initproc)
    800024ac:	00007797          	auipc	a5,0x7
    800024b0:	b847b783          	ld	a5,-1148(a5) # 80009030 <initproc>
    800024b4:	0d050493          	addi	s1,a0,208
    800024b8:	15050913          	addi	s2,a0,336
    800024bc:	02a79363          	bne	a5,a0,800024e2 <exit+0x52>
    panic("init exiting");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	dc850513          	addi	a0,a0,-568 # 80008288 <digits+0x248>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	076080e7          	jalr	118(ra) # 8000053e <panic>
      fileclose(f);
    800024d0:	00002097          	auipc	ra,0x2
    800024d4:	290080e7          	jalr	656(ra) # 80004760 <fileclose>
      p->ofile[fd] = 0;
    800024d8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024dc:	04a1                	addi	s1,s1,8
    800024de:	01248563          	beq	s1,s2,800024e8 <exit+0x58>
    if(p->ofile[fd]){
    800024e2:	6088                	ld	a0,0(s1)
    800024e4:	f575                	bnez	a0,800024d0 <exit+0x40>
    800024e6:	bfdd                	j	800024dc <exit+0x4c>
  begin_op();
    800024e8:	00002097          	auipc	ra,0x2
    800024ec:	dac080e7          	jalr	-596(ra) # 80004294 <begin_op>
  iput(p->cwd);
    800024f0:	1509b503          	ld	a0,336(s3)
    800024f4:	00001097          	auipc	ra,0x1
    800024f8:	588080e7          	jalr	1416(ra) # 80003a7c <iput>
  end_op();
    800024fc:	00002097          	auipc	ra,0x2
    80002500:	e18080e7          	jalr	-488(ra) # 80004314 <end_op>
  p->cwd = 0;
    80002504:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002508:	00008497          	auipc	s1,0x8
    8000250c:	ca048493          	addi	s1,s1,-864 # 8000a1a8 <wait_lock>
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	6d2080e7          	jalr	1746(ra) # 80000be4 <acquire>
  reparent(p);
    8000251a:	854e                	mv	a0,s3
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	f1a080e7          	jalr	-230(ra) # 80002436 <reparent>
  wakeup(p->parent);
    80002524:	0389b503          	ld	a0,56(s3)
    80002528:	00000097          	auipc	ra,0x0
    8000252c:	e98080e7          	jalr	-360(ra) # 800023c0 <wakeup>
  acquire(&p->lock);
    80002530:	854e                	mv	a0,s3
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	6b2080e7          	jalr	1714(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000253a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000253e:	4795                	li	a5,5
    80002540:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
  sched();
    8000254e:	00000097          	auipc	ra,0x0
    80002552:	bd4080e7          	jalr	-1068(ra) # 80002122 <sched>
  panic("zombie exit");
    80002556:	00006517          	auipc	a0,0x6
    8000255a:	d4250513          	addi	a0,a0,-702 # 80008298 <digits+0x258>
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>

0000000080002566 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002566:	7179                	addi	sp,sp,-48
    80002568:	f406                	sd	ra,40(sp)
    8000256a:	f022                	sd	s0,32(sp)
    8000256c:	ec26                	sd	s1,24(sp)
    8000256e:	e84a                	sd	s2,16(sp)
    80002570:	e44e                	sd	s3,8(sp)
    80002572:	1800                	addi	s0,sp,48
    80002574:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002576:	00008497          	auipc	s1,0x8
    8000257a:	cca48493          	addi	s1,s1,-822 # 8000a240 <proc>
    8000257e:	0000e997          	auipc	s3,0xe
    80002582:	ac298993          	addi	s3,s3,-1342 # 80010040 <tickslock>
    acquire(&p->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	65c080e7          	jalr	1628(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002590:	589c                	lw	a5,48(s1)
    80002592:	01278d63          	beq	a5,s2,800025ac <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a0:	17848493          	addi	s1,s1,376
    800025a4:	ff3491e3          	bne	s1,s3,80002586 <kill+0x20>
  }
  return -1;
    800025a8:	557d                	li	a0,-1
    800025aa:	a829                	j	800025c4 <kill+0x5e>
      p->killed = 1;
    800025ac:	4785                	li	a5,1
    800025ae:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025b0:	4c98                	lw	a4,24(s1)
    800025b2:	4789                	li	a5,2
    800025b4:	00f70f63          	beq	a4,a5,800025d2 <kill+0x6c>
      release(&p->lock);
    800025b8:	8526                	mv	a0,s1
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	6de080e7          	jalr	1758(ra) # 80000c98 <release>
      return 0;
    800025c2:	4501                	li	a0,0
}
    800025c4:	70a2                	ld	ra,40(sp)
    800025c6:	7402                	ld	s0,32(sp)
    800025c8:	64e2                	ld	s1,24(sp)
    800025ca:	6942                	ld	s2,16(sp)
    800025cc:	69a2                	ld	s3,8(sp)
    800025ce:	6145                	addi	sp,sp,48
    800025d0:	8082                	ret
        p->state = RUNNABLE;
    800025d2:	478d                	li	a5,3
    800025d4:	cc9c                	sw	a5,24(s1)
    800025d6:	b7cd                	j	800025b8 <kill+0x52>

00000000800025d8 <kill_system>:

int
kill_system()
{
    800025d8:	715d                	addi	sp,sp,-80
    800025da:	e486                	sd	ra,72(sp)
    800025dc:	e0a2                	sd	s0,64(sp)
    800025de:	fc26                	sd	s1,56(sp)
    800025e0:	f84a                	sd	s2,48(sp)
    800025e2:	f44e                	sd	s3,40(sp)
    800025e4:	f052                	sd	s4,32(sp)
    800025e6:	ec56                	sd	s5,24(sp)
    800025e8:	e85a                	sd	s6,16(sp)
    800025ea:	e45e                	sd	s7,8(sp)
    800025ec:	e062                	sd	s8,0(sp)
    800025ee:	0880                	addi	s0,sp,80
  struct proc *myp = myproc();
    800025f0:	fffff097          	auipc	ra,0xfffff
    800025f4:	3c8080e7          	jalr	968(ra) # 800019b8 <myproc>
    800025f8:	8c2a                	mv	s8,a0
  int mypid = myp->pid;
    800025fa:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	5e6080e7          	jalr	1510(ra) # 80000be4 <acquire>
  struct proc *p;

  for(p = proc;p < &proc[NPROC]; p++){
    80002606:	00008497          	auipc	s1,0x8
    8000260a:	c3a48493          	addi	s1,s1,-966 # 8000a240 <proc>
    if(p->pid != mypid){
      acquire(&p->lock);
      if(p->pid != 1 && p->pid != 2){
    8000260e:	4a05                	li	s4,1
        p->killed = 1;
    80002610:	4b05                	li	s6,1
        if(p->state == SLEEPING){
    80002612:	4a89                	li	s5,2
          // Wake process from sleep().
          p->state = RUNNABLE;
    80002614:	4b8d                	li	s7,3
  for(p = proc;p < &proc[NPROC]; p++){
    80002616:	0000e917          	auipc	s2,0xe
    8000261a:	a2a90913          	addi	s2,s2,-1494 # 80010040 <tickslock>
    8000261e:	a811                	j	80002632 <kill_system+0x5a>
        }
      }
      release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	676080e7          	jalr	1654(ra) # 80000c98 <release>
  for(p = proc;p < &proc[NPROC]; p++){
    8000262a:	17848493          	addi	s1,s1,376
    8000262e:	03248663          	beq	s1,s2,8000265a <kill_system+0x82>
    if(p->pid != mypid){
    80002632:	589c                	lw	a5,48(s1)
    80002634:	ff378be3          	beq	a5,s3,8000262a <kill_system+0x52>
      acquire(&p->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	5aa080e7          	jalr	1450(ra) # 80000be4 <acquire>
      if(p->pid != 1 && p->pid != 2){
    80002642:	589c                	lw	a5,48(s1)
    80002644:	37fd                	addiw	a5,a5,-1
    80002646:	fcfa7de3          	bgeu	s4,a5,80002620 <kill_system+0x48>
        p->killed = 1;
    8000264a:	0364a423          	sw	s6,40(s1)
        if(p->state == SLEEPING){
    8000264e:	4c9c                	lw	a5,24(s1)
    80002650:	fd5798e3          	bne	a5,s5,80002620 <kill_system+0x48>
          p->state = RUNNABLE;
    80002654:	0174ac23          	sw	s7,24(s1)
    80002658:	b7e1                	j	80002620 <kill_system+0x48>
    }
  }

  myp->killed = 1;
    8000265a:	4785                	li	a5,1
    8000265c:	02fc2423          	sw	a5,40(s8)
  release(&myp->lock);
    80002660:	8562                	mv	a0,s8
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	636080e7          	jalr	1590(ra) # 80000c98 <release>
  return 0;
}
    8000266a:	4501                	li	a0,0
    8000266c:	60a6                	ld	ra,72(sp)
    8000266e:	6406                	ld	s0,64(sp)
    80002670:	74e2                	ld	s1,56(sp)
    80002672:	7942                	ld	s2,48(sp)
    80002674:	79a2                	ld	s3,40(sp)
    80002676:	7a02                	ld	s4,32(sp)
    80002678:	6ae2                	ld	s5,24(sp)
    8000267a:	6b42                	ld	s6,16(sp)
    8000267c:	6ba2                	ld	s7,8(sp)
    8000267e:	6c02                	ld	s8,0(sp)
    80002680:	6161                	addi	sp,sp,80
    80002682:	8082                	ret

0000000080002684 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002684:	7179                	addi	sp,sp,-48
    80002686:	f406                	sd	ra,40(sp)
    80002688:	f022                	sd	s0,32(sp)
    8000268a:	ec26                	sd	s1,24(sp)
    8000268c:	e84a                	sd	s2,16(sp)
    8000268e:	e44e                	sd	s3,8(sp)
    80002690:	e052                	sd	s4,0(sp)
    80002692:	1800                	addi	s0,sp,48
    80002694:	84aa                	mv	s1,a0
    80002696:	892e                	mv	s2,a1
    80002698:	89b2                	mv	s3,a2
    8000269a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	31c080e7          	jalr	796(ra) # 800019b8 <myproc>
  if(user_dst){
    800026a4:	c08d                	beqz	s1,800026c6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026a6:	86d2                	mv	a3,s4
    800026a8:	864e                	mv	a2,s3
    800026aa:	85ca                	mv	a1,s2
    800026ac:	6928                	ld	a0,80(a0)
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	fcc080e7          	jalr	-52(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026b6:	70a2                	ld	ra,40(sp)
    800026b8:	7402                	ld	s0,32(sp)
    800026ba:	64e2                	ld	s1,24(sp)
    800026bc:	6942                	ld	s2,16(sp)
    800026be:	69a2                	ld	s3,8(sp)
    800026c0:	6a02                	ld	s4,0(sp)
    800026c2:	6145                	addi	sp,sp,48
    800026c4:	8082                	ret
    memmove((char *)dst, src, len);
    800026c6:	000a061b          	sext.w	a2,s4
    800026ca:	85ce                	mv	a1,s3
    800026cc:	854a                	mv	a0,s2
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	672080e7          	jalr	1650(ra) # 80000d40 <memmove>
    return 0;
    800026d6:	8526                	mv	a0,s1
    800026d8:	bff9                	j	800026b6 <either_copyout+0x32>

00000000800026da <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026da:	7179                	addi	sp,sp,-48
    800026dc:	f406                	sd	ra,40(sp)
    800026de:	f022                	sd	s0,32(sp)
    800026e0:	ec26                	sd	s1,24(sp)
    800026e2:	e84a                	sd	s2,16(sp)
    800026e4:	e44e                	sd	s3,8(sp)
    800026e6:	e052                	sd	s4,0(sp)
    800026e8:	1800                	addi	s0,sp,48
    800026ea:	892a                	mv	s2,a0
    800026ec:	84ae                	mv	s1,a1
    800026ee:	89b2                	mv	s3,a2
    800026f0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	2c6080e7          	jalr	710(ra) # 800019b8 <myproc>
  if(user_src){
    800026fa:	c08d                	beqz	s1,8000271c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026fc:	86d2                	mv	a3,s4
    800026fe:	864e                	mv	a2,s3
    80002700:	85ca                	mv	a1,s2
    80002702:	6928                	ld	a0,80(a0)
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	002080e7          	jalr	2(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000270c:	70a2                	ld	ra,40(sp)
    8000270e:	7402                	ld	s0,32(sp)
    80002710:	64e2                	ld	s1,24(sp)
    80002712:	6942                	ld	s2,16(sp)
    80002714:	69a2                	ld	s3,8(sp)
    80002716:	6a02                	ld	s4,0(sp)
    80002718:	6145                	addi	sp,sp,48
    8000271a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000271c:	000a061b          	sext.w	a2,s4
    80002720:	85ce                	mv	a1,s3
    80002722:	854a                	mv	a0,s2
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	61c080e7          	jalr	1564(ra) # 80000d40 <memmove>
    return 0;
    8000272c:	8526                	mv	a0,s1
    8000272e:	bff9                	j	8000270c <either_copyin+0x32>

0000000080002730 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002730:	715d                	addi	sp,sp,-80
    80002732:	e486                	sd	ra,72(sp)
    80002734:	e0a2                	sd	s0,64(sp)
    80002736:	fc26                	sd	s1,56(sp)
    80002738:	f84a                	sd	s2,48(sp)
    8000273a:	f44e                	sd	s3,40(sp)
    8000273c:	f052                	sd	s4,32(sp)
    8000273e:	ec56                	sd	s5,24(sp)
    80002740:	e85a                	sd	s6,16(sp)
    80002742:	e45e                	sd	s7,8(sp)
    80002744:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002746:	00006517          	auipc	a0,0x6
    8000274a:	98250513          	addi	a0,a0,-1662 # 800080c8 <digits+0x88>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	e3a080e7          	jalr	-454(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002756:	00008497          	auipc	s1,0x8
    8000275a:	c4248493          	addi	s1,s1,-958 # 8000a398 <proc+0x158>
    8000275e:	0000e917          	auipc	s2,0xe
    80002762:	a3a90913          	addi	s2,s2,-1478 # 80010198 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002766:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002768:	00006997          	auipc	s3,0x6
    8000276c:	b4098993          	addi	s3,s3,-1216 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002770:	00006a97          	auipc	s5,0x6
    80002774:	b40a8a93          	addi	s5,s5,-1216 # 800082b0 <digits+0x270>
    printf("\n");
    80002778:	00006a17          	auipc	s4,0x6
    8000277c:	950a0a13          	addi	s4,s4,-1712 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002780:	00006b97          	auipc	s7,0x6
    80002784:	b68b8b93          	addi	s7,s7,-1176 # 800082e8 <states.1749>
    80002788:	a00d                	j	800027aa <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000278a:	ed86a583          	lw	a1,-296(a3)
    8000278e:	8556                	mv	a0,s5
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	df8080e7          	jalr	-520(ra) # 80000588 <printf>
    printf("\n");
    80002798:	8552                	mv	a0,s4
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	dee080e7          	jalr	-530(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027a2:	17848493          	addi	s1,s1,376
    800027a6:	03248163          	beq	s1,s2,800027c8 <procdump+0x98>
    if(p->state == UNUSED)
    800027aa:	86a6                	mv	a3,s1
    800027ac:	ec04a783          	lw	a5,-320(s1)
    800027b0:	dbed                	beqz	a5,800027a2 <procdump+0x72>
      state = "???";
    800027b2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027b4:	fcfb6be3          	bltu	s6,a5,8000278a <procdump+0x5a>
    800027b8:	1782                	slli	a5,a5,0x20
    800027ba:	9381                	srli	a5,a5,0x20
    800027bc:	078e                	slli	a5,a5,0x3
    800027be:	97de                	add	a5,a5,s7
    800027c0:	6390                	ld	a2,0(a5)
    800027c2:	f661                	bnez	a2,8000278a <procdump+0x5a>
      state = "???";
    800027c4:	864e                	mv	a2,s3
    800027c6:	b7d1                	j	8000278a <procdump+0x5a>
  }
}
    800027c8:	60a6                	ld	ra,72(sp)
    800027ca:	6406                	ld	s0,64(sp)
    800027cc:	74e2                	ld	s1,56(sp)
    800027ce:	7942                	ld	s2,48(sp)
    800027d0:	79a2                	ld	s3,40(sp)
    800027d2:	7a02                	ld	s4,32(sp)
    800027d4:	6ae2                	ld	s5,24(sp)
    800027d6:	6b42                	ld	s6,16(sp)
    800027d8:	6ba2                	ld	s7,8(sp)
    800027da:	6161                	addi	sp,sp,80
    800027dc:	8082                	ret

00000000800027de <pause_system>:

int
pause_system(int seconds)
{
    800027de:	1141                	addi	sp,sp,-16
    800027e0:	e406                	sd	ra,8(sp)
    800027e2:	e022                	sd	s0,0(sp)
    800027e4:	0800                	addi	s0,sp,16
  pause_time = ticks + seconds*10;  
    800027e6:	0025179b          	slliw	a5,a0,0x2
    800027ea:	9fa9                	addw	a5,a5,a0
    800027ec:	0017979b          	slliw	a5,a5,0x1
    800027f0:	00007517          	auipc	a0,0x7
    800027f4:	84852503          	lw	a0,-1976(a0) # 80009038 <ticks>
    800027f8:	9fa9                	addw	a5,a5,a0
    800027fa:	00007717          	auipc	a4,0x7
    800027fe:	82f72723          	sw	a5,-2002(a4) # 80009028 <pause_time>
  yield();
    80002802:	00000097          	auipc	ra,0x0
    80002806:	9f6080e7          	jalr	-1546(ra) # 800021f8 <yield>
  return 0;
}
    8000280a:	4501                	li	a0,0
    8000280c:	60a2                	ld	ra,8(sp)
    8000280e:	6402                	ld	s0,0(sp)
    80002810:	0141                	addi	sp,sp,16
    80002812:	8082                	ret

0000000080002814 <swtch>:
    80002814:	00153023          	sd	ra,0(a0)
    80002818:	00253423          	sd	sp,8(a0)
    8000281c:	e900                	sd	s0,16(a0)
    8000281e:	ed04                	sd	s1,24(a0)
    80002820:	03253023          	sd	s2,32(a0)
    80002824:	03353423          	sd	s3,40(a0)
    80002828:	03453823          	sd	s4,48(a0)
    8000282c:	03553c23          	sd	s5,56(a0)
    80002830:	05653023          	sd	s6,64(a0)
    80002834:	05753423          	sd	s7,72(a0)
    80002838:	05853823          	sd	s8,80(a0)
    8000283c:	05953c23          	sd	s9,88(a0)
    80002840:	07a53023          	sd	s10,96(a0)
    80002844:	07b53423          	sd	s11,104(a0)
    80002848:	0005b083          	ld	ra,0(a1)
    8000284c:	0085b103          	ld	sp,8(a1)
    80002850:	6980                	ld	s0,16(a1)
    80002852:	6d84                	ld	s1,24(a1)
    80002854:	0205b903          	ld	s2,32(a1)
    80002858:	0285b983          	ld	s3,40(a1)
    8000285c:	0305ba03          	ld	s4,48(a1)
    80002860:	0385ba83          	ld	s5,56(a1)
    80002864:	0405bb03          	ld	s6,64(a1)
    80002868:	0485bb83          	ld	s7,72(a1)
    8000286c:	0505bc03          	ld	s8,80(a1)
    80002870:	0585bc83          	ld	s9,88(a1)
    80002874:	0605bd03          	ld	s10,96(a1)
    80002878:	0685bd83          	ld	s11,104(a1)
    8000287c:	8082                	ret

000000008000287e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000287e:	1141                	addi	sp,sp,-16
    80002880:	e406                	sd	ra,8(sp)
    80002882:	e022                	sd	s0,0(sp)
    80002884:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002886:	00006597          	auipc	a1,0x6
    8000288a:	a9258593          	addi	a1,a1,-1390 # 80008318 <states.1749+0x30>
    8000288e:	0000d517          	auipc	a0,0xd
    80002892:	7b250513          	addi	a0,a0,1970 # 80010040 <tickslock>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	2be080e7          	jalr	702(ra) # 80000b54 <initlock>
}
    8000289e:	60a2                	ld	ra,8(sp)
    800028a0:	6402                	ld	s0,0(sp)
    800028a2:	0141                	addi	sp,sp,16
    800028a4:	8082                	ret

00000000800028a6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028a6:	1141                	addi	sp,sp,-16
    800028a8:	e422                	sd	s0,8(sp)
    800028aa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ac:	00003797          	auipc	a5,0x3
    800028b0:	4d478793          	addi	a5,a5,1236 # 80005d80 <kernelvec>
    800028b4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028b8:	6422                	ld	s0,8(sp)
    800028ba:	0141                	addi	sp,sp,16
    800028bc:	8082                	ret

00000000800028be <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028be:	1141                	addi	sp,sp,-16
    800028c0:	e406                	sd	ra,8(sp)
    800028c2:	e022                	sd	s0,0(sp)
    800028c4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	0f2080e7          	jalr	242(ra) # 800019b8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028d8:	00004617          	auipc	a2,0x4
    800028dc:	72860613          	addi	a2,a2,1832 # 80007000 <_trampoline>
    800028e0:	00004697          	auipc	a3,0x4
    800028e4:	72068693          	addi	a3,a3,1824 # 80007000 <_trampoline>
    800028e8:	8e91                	sub	a3,a3,a2
    800028ea:	040007b7          	lui	a5,0x4000
    800028ee:	17fd                	addi	a5,a5,-1
    800028f0:	07b2                	slli	a5,a5,0xc
    800028f2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028f8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028fa:	180026f3          	csrr	a3,satp
    800028fe:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002900:	6d38                	ld	a4,88(a0)
    80002902:	6134                	ld	a3,64(a0)
    80002904:	6585                	lui	a1,0x1
    80002906:	96ae                	add	a3,a3,a1
    80002908:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000290a:	6d38                	ld	a4,88(a0)
    8000290c:	00000697          	auipc	a3,0x0
    80002910:	13868693          	addi	a3,a3,312 # 80002a44 <usertrap>
    80002914:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002916:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002918:	8692                	mv	a3,tp
    8000291a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002920:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002924:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000292c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000292e:	6f18                	ld	a4,24(a4)
    80002930:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002934:	692c                	ld	a1,80(a0)
    80002936:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002938:	00004717          	auipc	a4,0x4
    8000293c:	75870713          	addi	a4,a4,1880 # 80007090 <userret>
    80002940:	8f11                	sub	a4,a4,a2
    80002942:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002944:	577d                	li	a4,-1
    80002946:	177e                	slli	a4,a4,0x3f
    80002948:	8dd9                	or	a1,a1,a4
    8000294a:	02000537          	lui	a0,0x2000
    8000294e:	157d                	addi	a0,a0,-1
    80002950:	0536                	slli	a0,a0,0xd
    80002952:	9782                	jalr	a5
}
    80002954:	60a2                	ld	ra,8(sp)
    80002956:	6402                	ld	s0,0(sp)
    80002958:	0141                	addi	sp,sp,16
    8000295a:	8082                	ret

000000008000295c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000295c:	1101                	addi	sp,sp,-32
    8000295e:	ec06                	sd	ra,24(sp)
    80002960:	e822                	sd	s0,16(sp)
    80002962:	e426                	sd	s1,8(sp)
    80002964:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002966:	0000d497          	auipc	s1,0xd
    8000296a:	6da48493          	addi	s1,s1,1754 # 80010040 <tickslock>
    8000296e:	8526                	mv	a0,s1
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
  ticks++;
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	6c050513          	addi	a0,a0,1728 # 80009038 <ticks>
    80002980:	411c                	lw	a5,0(a0)
    80002982:	2785                	addiw	a5,a5,1
    80002984:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	a3a080e7          	jalr	-1478(ra) # 800023c0 <wakeup>
  release(&tickslock);
    8000298e:	8526                	mv	a0,s1
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	308080e7          	jalr	776(ra) # 80000c98 <release>
}
    80002998:	60e2                	ld	ra,24(sp)
    8000299a:	6442                	ld	s0,16(sp)
    8000299c:	64a2                	ld	s1,8(sp)
    8000299e:	6105                	addi	sp,sp,32
    800029a0:	8082                	ret

00000000800029a2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029a2:	1101                	addi	sp,sp,-32
    800029a4:	ec06                	sd	ra,24(sp)
    800029a6:	e822                	sd	s0,16(sp)
    800029a8:	e426                	sd	s1,8(sp)
    800029aa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ac:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029b0:	00074d63          	bltz	a4,800029ca <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029b4:	57fd                	li	a5,-1
    800029b6:	17fe                	slli	a5,a5,0x3f
    800029b8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029ba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029bc:	06f70363          	beq	a4,a5,80002a22 <devintr+0x80>
  }
}
    800029c0:	60e2                	ld	ra,24(sp)
    800029c2:	6442                	ld	s0,16(sp)
    800029c4:	64a2                	ld	s1,8(sp)
    800029c6:	6105                	addi	sp,sp,32
    800029c8:	8082                	ret
     (scause & 0xff) == 9){
    800029ca:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029ce:	46a5                	li	a3,9
    800029d0:	fed792e3          	bne	a5,a3,800029b4 <devintr+0x12>
    int irq = plic_claim();
    800029d4:	00003097          	auipc	ra,0x3
    800029d8:	4b4080e7          	jalr	1204(ra) # 80005e88 <plic_claim>
    800029dc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029de:	47a9                	li	a5,10
    800029e0:	02f50763          	beq	a0,a5,80002a0e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029e4:	4785                	li	a5,1
    800029e6:	02f50963          	beq	a0,a5,80002a18 <devintr+0x76>
    return 1;
    800029ea:	4505                	li	a0,1
    } else if(irq){
    800029ec:	d8f1                	beqz	s1,800029c0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029ee:	85a6                	mv	a1,s1
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	93050513          	addi	a0,a0,-1744 # 80008320 <states.1749+0x38>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b90080e7          	jalr	-1136(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a00:	8526                	mv	a0,s1
    80002a02:	00003097          	auipc	ra,0x3
    80002a06:	4aa080e7          	jalr	1194(ra) # 80005eac <plic_complete>
    return 1;
    80002a0a:	4505                	li	a0,1
    80002a0c:	bf55                	j	800029c0 <devintr+0x1e>
      uartintr();
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	f9a080e7          	jalr	-102(ra) # 800009a8 <uartintr>
    80002a16:	b7ed                	j	80002a00 <devintr+0x5e>
      virtio_disk_intr();
    80002a18:	00004097          	auipc	ra,0x4
    80002a1c:	974080e7          	jalr	-1676(ra) # 8000638c <virtio_disk_intr>
    80002a20:	b7c5                	j	80002a00 <devintr+0x5e>
    if(cpuid() == 0){
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	f6a080e7          	jalr	-150(ra) # 8000198c <cpuid>
    80002a2a:	c901                	beqz	a0,80002a3a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a2c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a30:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a32:	14479073          	csrw	sip,a5
    return 2;
    80002a36:	4509                	li	a0,2
    80002a38:	b761                	j	800029c0 <devintr+0x1e>
      clockintr();
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	f22080e7          	jalr	-222(ra) # 8000295c <clockintr>
    80002a42:	b7ed                	j	80002a2c <devintr+0x8a>

0000000080002a44 <usertrap>:
{
    80002a44:	1101                	addi	sp,sp,-32
    80002a46:	ec06                	sd	ra,24(sp)
    80002a48:	e822                	sd	s0,16(sp)
    80002a4a:	e426                	sd	s1,8(sp)
    80002a4c:	e04a                	sd	s2,0(sp)
    80002a4e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a50:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a54:	1007f793          	andi	a5,a5,256
    80002a58:	e3ad                	bnez	a5,80002aba <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a5a:	00003797          	auipc	a5,0x3
    80002a5e:	32678793          	addi	a5,a5,806 # 80005d80 <kernelvec>
    80002a62:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	f52080e7          	jalr	-174(ra) # 800019b8 <myproc>
    80002a6e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a70:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a72:	14102773          	csrr	a4,sepc
    80002a76:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a78:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a7c:	47a1                	li	a5,8
    80002a7e:	04f71c63          	bne	a4,a5,80002ad6 <usertrap+0x92>
    if(p->killed)
    80002a82:	551c                	lw	a5,40(a0)
    80002a84:	e3b9                	bnez	a5,80002aca <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a86:	6cb8                	ld	a4,88(s1)
    80002a88:	6f1c                	ld	a5,24(a4)
    80002a8a:	0791                	addi	a5,a5,4
    80002a8c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a96:	10079073          	csrw	sstatus,a5
    syscall();
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	2e0080e7          	jalr	736(ra) # 80002d7a <syscall>
  if(p->killed)
    80002aa2:	549c                	lw	a5,40(s1)
    80002aa4:	ebc1                	bnez	a5,80002b34 <usertrap+0xf0>
  usertrapret();
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	e18080e7          	jalr	-488(ra) # 800028be <usertrapret>
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6902                	ld	s2,0(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
    panic("usertrap: not from user mode");
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	88650513          	addi	a0,a0,-1914 # 80008340 <states.1749+0x58>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	a7c080e7          	jalr	-1412(ra) # 8000053e <panic>
      exit(-1);
    80002aca:	557d                	li	a0,-1
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	9c4080e7          	jalr	-1596(ra) # 80002490 <exit>
    80002ad4:	bf4d                	j	80002a86 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	ecc080e7          	jalr	-308(ra) # 800029a2 <devintr>
    80002ade:	892a                	mv	s2,a0
    80002ae0:	c501                	beqz	a0,80002ae8 <usertrap+0xa4>
  if(p->killed)
    80002ae2:	549c                	lw	a5,40(s1)
    80002ae4:	c3a1                	beqz	a5,80002b24 <usertrap+0xe0>
    80002ae6:	a815                	j	80002b1a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002aec:	5890                	lw	a2,48(s1)
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	87250513          	addi	a0,a0,-1934 # 80008360 <states.1749+0x78>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a92080e7          	jalr	-1390(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b02:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	88a50513          	addi	a0,a0,-1910 # 80008390 <states.1749+0xa8>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a7a080e7          	jalr	-1414(ra) # 80000588 <printf>
    p->killed = 1;
    80002b16:	4785                	li	a5,1
    80002b18:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b1a:	557d                	li	a0,-1
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	974080e7          	jalr	-1676(ra) # 80002490 <exit>
  if(which_dev == 2)
    80002b24:	4789                	li	a5,2
    80002b26:	f8f910e3          	bne	s2,a5,80002aa6 <usertrap+0x62>
    yield();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	6ce080e7          	jalr	1742(ra) # 800021f8 <yield>
    80002b32:	bf95                	j	80002aa6 <usertrap+0x62>
  int which_dev = 0;
    80002b34:	4901                	li	s2,0
    80002b36:	b7d5                	j	80002b1a <usertrap+0xd6>

0000000080002b38 <kerneltrap>:
{
    80002b38:	7179                	addi	sp,sp,-48
    80002b3a:	f406                	sd	ra,40(sp)
    80002b3c:	f022                	sd	s0,32(sp)
    80002b3e:	ec26                	sd	s1,24(sp)
    80002b40:	e84a                	sd	s2,16(sp)
    80002b42:	e44e                	sd	s3,8(sp)
    80002b44:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b46:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b52:	1004f793          	andi	a5,s1,256
    80002b56:	cb85                	beqz	a5,80002b86 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b58:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b5c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b5e:	ef85                	bnez	a5,80002b96 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	e42080e7          	jalr	-446(ra) # 800029a2 <devintr>
    80002b68:	cd1d                	beqz	a0,80002ba6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b6a:	4789                	li	a5,2
    80002b6c:	06f50a63          	beq	a0,a5,80002be0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b70:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b74:	10049073          	csrw	sstatus,s1
}
    80002b78:	70a2                	ld	ra,40(sp)
    80002b7a:	7402                	ld	s0,32(sp)
    80002b7c:	64e2                	ld	s1,24(sp)
    80002b7e:	6942                	ld	s2,16(sp)
    80002b80:	69a2                	ld	s3,8(sp)
    80002b82:	6145                	addi	sp,sp,48
    80002b84:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b86:	00006517          	auipc	a0,0x6
    80002b8a:	82a50513          	addi	a0,a0,-2006 # 800083b0 <states.1749+0xc8>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b96:	00006517          	auipc	a0,0x6
    80002b9a:	84250513          	addi	a0,a0,-1982 # 800083d8 <states.1749+0xf0>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ba6:	85ce                	mv	a1,s3
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	85050513          	addi	a0,a0,-1968 # 800083f8 <states.1749+0x110>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	9d8080e7          	jalr	-1576(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bbc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	84850513          	addi	a0,a0,-1976 # 80008408 <states.1749+0x120>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	9c0080e7          	jalr	-1600(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bd0:	00006517          	auipc	a0,0x6
    80002bd4:	85050513          	addi	a0,a0,-1968 # 80008420 <states.1749+0x138>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	966080e7          	jalr	-1690(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	dd8080e7          	jalr	-552(ra) # 800019b8 <myproc>
    80002be8:	d541                	beqz	a0,80002b70 <kerneltrap+0x38>
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	dce080e7          	jalr	-562(ra) # 800019b8 <myproc>
    80002bf2:	4d18                	lw	a4,24(a0)
    80002bf4:	4791                	li	a5,4
    80002bf6:	f6f71de3          	bne	a4,a5,80002b70 <kerneltrap+0x38>
    yield();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	5fe080e7          	jalr	1534(ra) # 800021f8 <yield>
    80002c02:	b7bd                	j	80002b70 <kerneltrap+0x38>

0000000080002c04 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	1000                	addi	s0,sp,32
    80002c0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	da8080e7          	jalr	-600(ra) # 800019b8 <myproc>
  switch (n) {
    80002c18:	4795                	li	a5,5
    80002c1a:	0497e163          	bltu	a5,s1,80002c5c <argraw+0x58>
    80002c1e:	048a                	slli	s1,s1,0x2
    80002c20:	00006717          	auipc	a4,0x6
    80002c24:	83870713          	addi	a4,a4,-1992 # 80008458 <states.1749+0x170>
    80002c28:	94ba                	add	s1,s1,a4
    80002c2a:	409c                	lw	a5,0(s1)
    80002c2c:	97ba                	add	a5,a5,a4
    80002c2e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c30:	6d3c                	ld	a5,88(a0)
    80002c32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c34:	60e2                	ld	ra,24(sp)
    80002c36:	6442                	ld	s0,16(sp)
    80002c38:	64a2                	ld	s1,8(sp)
    80002c3a:	6105                	addi	sp,sp,32
    80002c3c:	8082                	ret
    return p->trapframe->a1;
    80002c3e:	6d3c                	ld	a5,88(a0)
    80002c40:	7fa8                	ld	a0,120(a5)
    80002c42:	bfcd                	j	80002c34 <argraw+0x30>
    return p->trapframe->a2;
    80002c44:	6d3c                	ld	a5,88(a0)
    80002c46:	63c8                	ld	a0,128(a5)
    80002c48:	b7f5                	j	80002c34 <argraw+0x30>
    return p->trapframe->a3;
    80002c4a:	6d3c                	ld	a5,88(a0)
    80002c4c:	67c8                	ld	a0,136(a5)
    80002c4e:	b7dd                	j	80002c34 <argraw+0x30>
    return p->trapframe->a4;
    80002c50:	6d3c                	ld	a5,88(a0)
    80002c52:	6bc8                	ld	a0,144(a5)
    80002c54:	b7c5                	j	80002c34 <argraw+0x30>
    return p->trapframe->a5;
    80002c56:	6d3c                	ld	a5,88(a0)
    80002c58:	6fc8                	ld	a0,152(a5)
    80002c5a:	bfe9                	j	80002c34 <argraw+0x30>
  panic("argraw");
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7d450513          	addi	a0,a0,2004 # 80008430 <states.1749+0x148>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8da080e7          	jalr	-1830(ra) # 8000053e <panic>

0000000080002c6c <fetchaddr>:
{
    80002c6c:	1101                	addi	sp,sp,-32
    80002c6e:	ec06                	sd	ra,24(sp)
    80002c70:	e822                	sd	s0,16(sp)
    80002c72:	e426                	sd	s1,8(sp)
    80002c74:	e04a                	sd	s2,0(sp)
    80002c76:	1000                	addi	s0,sp,32
    80002c78:	84aa                	mv	s1,a0
    80002c7a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	d3c080e7          	jalr	-708(ra) # 800019b8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c84:	653c                	ld	a5,72(a0)
    80002c86:	02f4f863          	bgeu	s1,a5,80002cb6 <fetchaddr+0x4a>
    80002c8a:	00848713          	addi	a4,s1,8
    80002c8e:	02e7e663          	bltu	a5,a4,80002cba <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c92:	46a1                	li	a3,8
    80002c94:	8626                	mv	a2,s1
    80002c96:	85ca                	mv	a1,s2
    80002c98:	6928                	ld	a0,80(a0)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	a6c080e7          	jalr	-1428(ra) # 80001706 <copyin>
    80002ca2:	00a03533          	snez	a0,a0
    80002ca6:	40a00533          	neg	a0,a0
}
    80002caa:	60e2                	ld	ra,24(sp)
    80002cac:	6442                	ld	s0,16(sp)
    80002cae:	64a2                	ld	s1,8(sp)
    80002cb0:	6902                	ld	s2,0(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret
    return -1;
    80002cb6:	557d                	li	a0,-1
    80002cb8:	bfcd                	j	80002caa <fetchaddr+0x3e>
    80002cba:	557d                	li	a0,-1
    80002cbc:	b7fd                	j	80002caa <fetchaddr+0x3e>

0000000080002cbe <fetchstr>:
{
    80002cbe:	7179                	addi	sp,sp,-48
    80002cc0:	f406                	sd	ra,40(sp)
    80002cc2:	f022                	sd	s0,32(sp)
    80002cc4:	ec26                	sd	s1,24(sp)
    80002cc6:	e84a                	sd	s2,16(sp)
    80002cc8:	e44e                	sd	s3,8(sp)
    80002cca:	1800                	addi	s0,sp,48
    80002ccc:	892a                	mv	s2,a0
    80002cce:	84ae                	mv	s1,a1
    80002cd0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	ce6080e7          	jalr	-794(ra) # 800019b8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cda:	86ce                	mv	a3,s3
    80002cdc:	864a                	mv	a2,s2
    80002cde:	85a6                	mv	a1,s1
    80002ce0:	6928                	ld	a0,80(a0)
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	ab0080e7          	jalr	-1360(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002cea:	00054763          	bltz	a0,80002cf8 <fetchstr+0x3a>
  return strlen(buf);
    80002cee:	8526                	mv	a0,s1
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	174080e7          	jalr	372(ra) # 80000e64 <strlen>
}
    80002cf8:	70a2                	ld	ra,40(sp)
    80002cfa:	7402                	ld	s0,32(sp)
    80002cfc:	64e2                	ld	s1,24(sp)
    80002cfe:	6942                	ld	s2,16(sp)
    80002d00:	69a2                	ld	s3,8(sp)
    80002d02:	6145                	addi	sp,sp,48
    80002d04:	8082                	ret

0000000080002d06 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	e426                	sd	s1,8(sp)
    80002d0e:	1000                	addi	s0,sp,32
    80002d10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	ef2080e7          	jalr	-270(ra) # 80002c04 <argraw>
    80002d1a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d1c:	4501                	li	a0,0
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	64a2                	ld	s1,8(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	1000                	addi	s0,sp,32
    80002d32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	ed0080e7          	jalr	-304(ra) # 80002c04 <argraw>
    80002d3c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d3e:	4501                	li	a0,0
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret

0000000080002d4a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	e04a                	sd	s2,0(sp)
    80002d54:	1000                	addi	s0,sp,32
    80002d56:	84ae                	mv	s1,a1
    80002d58:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	eaa080e7          	jalr	-342(ra) # 80002c04 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d62:	864a                	mv	a2,s2
    80002d64:	85a6                	mv	a1,s1
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	f58080e7          	jalr	-168(ra) # 80002cbe <fetchstr>
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6902                	ld	s2,0(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret

0000000080002d7a <syscall>:
[SYS_pause_system] sys_pause_system,
};

void
syscall(void)
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	e426                	sd	s1,8(sp)
    80002d82:	e04a                	sd	s2,0(sp)
    80002d84:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	c32080e7          	jalr	-974(ra) # 800019b8 <myproc>
    80002d8e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d90:	05853903          	ld	s2,88(a0)
    80002d94:	0a893783          	ld	a5,168(s2)
    80002d98:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d9c:	37fd                	addiw	a5,a5,-1
    80002d9e:	4759                	li	a4,22
    80002da0:	00f76f63          	bltu	a4,a5,80002dbe <syscall+0x44>
    80002da4:	00369713          	slli	a4,a3,0x3
    80002da8:	00005797          	auipc	a5,0x5
    80002dac:	6c878793          	addi	a5,a5,1736 # 80008470 <syscalls>
    80002db0:	97ba                	add	a5,a5,a4
    80002db2:	639c                	ld	a5,0(a5)
    80002db4:	c789                	beqz	a5,80002dbe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002db6:	9782                	jalr	a5
    80002db8:	06a93823          	sd	a0,112(s2)
    80002dbc:	a839                	j	80002dda <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dbe:	15848613          	addi	a2,s1,344
    80002dc2:	588c                	lw	a1,48(s1)
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	67450513          	addi	a0,a0,1652 # 80008438 <states.1749+0x150>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	7bc080e7          	jalr	1980(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dd4:	6cbc                	ld	a5,88(s1)
    80002dd6:	577d                	li	a4,-1
    80002dd8:	fbb8                	sd	a4,112(a5)
  }
}
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6902                	ld	s2,0(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dee:	fec40593          	addi	a1,s0,-20
    80002df2:	4501                	li	a0,0
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	f12080e7          	jalr	-238(ra) # 80002d06 <argint>
    return -1;
    80002dfc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dfe:	00054963          	bltz	a0,80002e10 <sys_exit+0x2a>
  exit(n);
    80002e02:	fec42503          	lw	a0,-20(s0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	68a080e7          	jalr	1674(ra) # 80002490 <exit>
  return 0;  // not reached
    80002e0e:	4781                	li	a5,0
}
    80002e10:	853e                	mv	a0,a5
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e1a:	1141                	addi	sp,sp,-16
    80002e1c:	e406                	sd	ra,8(sp)
    80002e1e:	e022                	sd	s0,0(sp)
    80002e20:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	b96080e7          	jalr	-1130(ra) # 800019b8 <myproc>
}
    80002e2a:	5908                	lw	a0,48(a0)
    80002e2c:	60a2                	ld	ra,8(sp)
    80002e2e:	6402                	ld	s0,0(sp)
    80002e30:	0141                	addi	sp,sp,16
    80002e32:	8082                	ret

0000000080002e34 <sys_fork>:

uint64
sys_fork(void)
{
    80002e34:	1141                	addi	sp,sp,-16
    80002e36:	e406                	sd	ra,8(sp)
    80002e38:	e022                	sd	s0,0(sp)
    80002e3a:	0800                	addi	s0,sp,16
  return fork();
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	f52080e7          	jalr	-174(ra) # 80001d8e <fork>
}
    80002e44:	60a2                	ld	ra,8(sp)
    80002e46:	6402                	ld	s0,0(sp)
    80002e48:	0141                	addi	sp,sp,16
    80002e4a:	8082                	ret

0000000080002e4c <sys_wait>:

uint64
sys_wait(void)
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e54:	fe840593          	addi	a1,s0,-24
    80002e58:	4501                	li	a0,0
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	ece080e7          	jalr	-306(ra) # 80002d28 <argaddr>
    80002e62:	87aa                	mv	a5,a0
    return -1;
    80002e64:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e66:	0007c863          	bltz	a5,80002e76 <sys_wait+0x2a>
  return wait(p);
    80002e6a:	fe843503          	ld	a0,-24(s0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	42a080e7          	jalr	1066(ra) # 80002298 <wait>
}
    80002e76:	60e2                	ld	ra,24(sp)
    80002e78:	6442                	ld	s0,16(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret

0000000080002e7e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e7e:	7179                	addi	sp,sp,-48
    80002e80:	f406                	sd	ra,40(sp)
    80002e82:	f022                	sd	s0,32(sp)
    80002e84:	ec26                	sd	s1,24(sp)
    80002e86:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e88:	fdc40593          	addi	a1,s0,-36
    80002e8c:	4501                	li	a0,0
    80002e8e:	00000097          	auipc	ra,0x0
    80002e92:	e78080e7          	jalr	-392(ra) # 80002d06 <argint>
    80002e96:	87aa                	mv	a5,a0
    return -1;
    80002e98:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e9a:	0207c063          	bltz	a5,80002eba <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	b1a080e7          	jalr	-1254(ra) # 800019b8 <myproc>
    80002ea6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ea8:	fdc42503          	lw	a0,-36(s0)
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	e6e080e7          	jalr	-402(ra) # 80001d1a <growproc>
    80002eb4:	00054863          	bltz	a0,80002ec4 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002eb8:	8526                	mv	a0,s1
}
    80002eba:	70a2                	ld	ra,40(sp)
    80002ebc:	7402                	ld	s0,32(sp)
    80002ebe:	64e2                	ld	s1,24(sp)
    80002ec0:	6145                	addi	sp,sp,48
    80002ec2:	8082                	ret
    return -1;
    80002ec4:	557d                	li	a0,-1
    80002ec6:	bfd5                	j	80002eba <sys_sbrk+0x3c>

0000000080002ec8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ec8:	7139                	addi	sp,sp,-64
    80002eca:	fc06                	sd	ra,56(sp)
    80002ecc:	f822                	sd	s0,48(sp)
    80002ece:	f426                	sd	s1,40(sp)
    80002ed0:	f04a                	sd	s2,32(sp)
    80002ed2:	ec4e                	sd	s3,24(sp)
    80002ed4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ed6:	fcc40593          	addi	a1,s0,-52
    80002eda:	4501                	li	a0,0
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	e2a080e7          	jalr	-470(ra) # 80002d06 <argint>
    return -1;
    80002ee4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee6:	06054563          	bltz	a0,80002f50 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eea:	0000d517          	auipc	a0,0xd
    80002eee:	15650513          	addi	a0,a0,342 # 80010040 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	cf2080e7          	jalr	-782(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002efa:	00006917          	auipc	s2,0x6
    80002efe:	13e92903          	lw	s2,318(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002f02:	fcc42783          	lw	a5,-52(s0)
    80002f06:	cf85                	beqz	a5,80002f3e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f08:	0000d997          	auipc	s3,0xd
    80002f0c:	13898993          	addi	s3,s3,312 # 80010040 <tickslock>
    80002f10:	00006497          	auipc	s1,0x6
    80002f14:	12848493          	addi	s1,s1,296 # 80009038 <ticks>
    if(myproc()->killed){
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	aa0080e7          	jalr	-1376(ra) # 800019b8 <myproc>
    80002f20:	551c                	lw	a5,40(a0)
    80002f22:	ef9d                	bnez	a5,80002f60 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f24:	85ce                	mv	a1,s3
    80002f26:	8526                	mv	a0,s1
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	30c080e7          	jalr	780(ra) # 80002234 <sleep>
  while(ticks - ticks0 < n){
    80002f30:	409c                	lw	a5,0(s1)
    80002f32:	412787bb          	subw	a5,a5,s2
    80002f36:	fcc42703          	lw	a4,-52(s0)
    80002f3a:	fce7efe3          	bltu	a5,a4,80002f18 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f3e:	0000d517          	auipc	a0,0xd
    80002f42:	10250513          	addi	a0,a0,258 # 80010040 <tickslock>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	d52080e7          	jalr	-686(ra) # 80000c98 <release>
  return 0;
    80002f4e:	4781                	li	a5,0
}
    80002f50:	853e                	mv	a0,a5
    80002f52:	70e2                	ld	ra,56(sp)
    80002f54:	7442                	ld	s0,48(sp)
    80002f56:	74a2                	ld	s1,40(sp)
    80002f58:	7902                	ld	s2,32(sp)
    80002f5a:	69e2                	ld	s3,24(sp)
    80002f5c:	6121                	addi	sp,sp,64
    80002f5e:	8082                	ret
      release(&tickslock);
    80002f60:	0000d517          	auipc	a0,0xd
    80002f64:	0e050513          	addi	a0,a0,224 # 80010040 <tickslock>
    80002f68:	ffffe097          	auipc	ra,0xffffe
    80002f6c:	d30080e7          	jalr	-720(ra) # 80000c98 <release>
      return -1;
    80002f70:	57fd                	li	a5,-1
    80002f72:	bff9                	j	80002f50 <sys_sleep+0x88>

0000000080002f74 <sys_kill>:

uint64
sys_kill(void)
{
    80002f74:	1101                	addi	sp,sp,-32
    80002f76:	ec06                	sd	ra,24(sp)
    80002f78:	e822                	sd	s0,16(sp)
    80002f7a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f7c:	fec40593          	addi	a1,s0,-20
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	d84080e7          	jalr	-636(ra) # 80002d06 <argint>
    80002f8a:	87aa                	mv	a5,a0
    return -1;
    80002f8c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f8e:	0007c863          	bltz	a5,80002f9e <sys_kill+0x2a>
  return kill(pid);
    80002f92:	fec42503          	lw	a0,-20(s0)
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	5d0080e7          	jalr	1488(ra) # 80002566 <kill>
}
    80002f9e:	60e2                	ld	ra,24(sp)
    80002fa0:	6442                	ld	s0,16(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret

0000000080002fa6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fb0:	0000d517          	auipc	a0,0xd
    80002fb4:	09050513          	addi	a0,a0,144 # 80010040 <tickslock>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	c2c080e7          	jalr	-980(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fc0:	00006497          	auipc	s1,0x6
    80002fc4:	0784a483          	lw	s1,120(s1) # 80009038 <ticks>
  release(&tickslock);
    80002fc8:	0000d517          	auipc	a0,0xd
    80002fcc:	07850513          	addi	a0,a0,120 # 80010040 <tickslock>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	cc8080e7          	jalr	-824(ra) # 80000c98 <release>
  return xticks;
}
    80002fd8:	02049513          	slli	a0,s1,0x20
    80002fdc:	9101                	srli	a0,a0,0x20
    80002fde:	60e2                	ld	ra,24(sp)
    80002fe0:	6442                	ld	s0,16(sp)
    80002fe2:	64a2                	ld	s1,8(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret

0000000080002fe8 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002fe8:	1141                	addi	sp,sp,-16
    80002fea:	e406                	sd	ra,8(sp)
    80002fec:	e022                	sd	s0,0(sp)
    80002fee:	0800                	addi	s0,sp,16
  return kill_system();
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	5e8080e7          	jalr	1512(ra) # 800025d8 <kill_system>
}
    80002ff8:	60a2                	ld	ra,8(sp)
    80002ffa:	6402                	ld	s0,0(sp)
    80002ffc:	0141                	addi	sp,sp,16
    80002ffe:	8082                	ret

0000000080003000 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80003008:	fec40593          	addi	a1,s0,-20
    8000300c:	4501                	li	a0,0
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	cf8080e7          	jalr	-776(ra) # 80002d06 <argint>
    80003016:	87aa                	mv	a5,a0
    return -1;
    80003018:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    8000301a:	0007c863          	bltz	a5,8000302a <sys_pause_system+0x2a>
  return pause_system(seconds);
    8000301e:	fec42503          	lw	a0,-20(s0)
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	7bc080e7          	jalr	1980(ra) # 800027de <pause_system>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	6105                	addi	sp,sp,32
    80003030:	8082                	ret

0000000080003032 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003032:	7179                	addi	sp,sp,-48
    80003034:	f406                	sd	ra,40(sp)
    80003036:	f022                	sd	s0,32(sp)
    80003038:	ec26                	sd	s1,24(sp)
    8000303a:	e84a                	sd	s2,16(sp)
    8000303c:	e44e                	sd	s3,8(sp)
    8000303e:	e052                	sd	s4,0(sp)
    80003040:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003042:	00005597          	auipc	a1,0x5
    80003046:	4ee58593          	addi	a1,a1,1262 # 80008530 <syscalls+0xc0>
    8000304a:	0000d517          	auipc	a0,0xd
    8000304e:	00e50513          	addi	a0,a0,14 # 80010058 <bcache>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	b02080e7          	jalr	-1278(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000305a:	00015797          	auipc	a5,0x15
    8000305e:	ffe78793          	addi	a5,a5,-2 # 80018058 <bcache+0x8000>
    80003062:	00015717          	auipc	a4,0x15
    80003066:	25e70713          	addi	a4,a4,606 # 800182c0 <bcache+0x8268>
    8000306a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000306e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003072:	0000d497          	auipc	s1,0xd
    80003076:	ffe48493          	addi	s1,s1,-2 # 80010070 <bcache+0x18>
    b->next = bcache.head.next;
    8000307a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000307c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000307e:	00005a17          	auipc	s4,0x5
    80003082:	4baa0a13          	addi	s4,s4,1210 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003086:	2b893783          	ld	a5,696(s2)
    8000308a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000308c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003090:	85d2                	mv	a1,s4
    80003092:	01048513          	addi	a0,s1,16
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	4bc080e7          	jalr	1212(ra) # 80004552 <initsleeplock>
    bcache.head.next->prev = b;
    8000309e:	2b893783          	ld	a5,696(s2)
    800030a2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030a4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a8:	45848493          	addi	s1,s1,1112
    800030ac:	fd349de3          	bne	s1,s3,80003086 <binit+0x54>
  }
}
    800030b0:	70a2                	ld	ra,40(sp)
    800030b2:	7402                	ld	s0,32(sp)
    800030b4:	64e2                	ld	s1,24(sp)
    800030b6:	6942                	ld	s2,16(sp)
    800030b8:	69a2                	ld	s3,8(sp)
    800030ba:	6a02                	ld	s4,0(sp)
    800030bc:	6145                	addi	sp,sp,48
    800030be:	8082                	ret

00000000800030c0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030c0:	7179                	addi	sp,sp,-48
    800030c2:	f406                	sd	ra,40(sp)
    800030c4:	f022                	sd	s0,32(sp)
    800030c6:	ec26                	sd	s1,24(sp)
    800030c8:	e84a                	sd	s2,16(sp)
    800030ca:	e44e                	sd	s3,8(sp)
    800030cc:	1800                	addi	s0,sp,48
    800030ce:	89aa                	mv	s3,a0
    800030d0:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030d2:	0000d517          	auipc	a0,0xd
    800030d6:	f8650513          	addi	a0,a0,-122 # 80010058 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	b0a080e7          	jalr	-1270(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030e2:	00015497          	auipc	s1,0x15
    800030e6:	22e4b483          	ld	s1,558(s1) # 80018310 <bcache+0x82b8>
    800030ea:	00015797          	auipc	a5,0x15
    800030ee:	1d678793          	addi	a5,a5,470 # 800182c0 <bcache+0x8268>
    800030f2:	02f48f63          	beq	s1,a5,80003130 <bread+0x70>
    800030f6:	873e                	mv	a4,a5
    800030f8:	a021                	j	80003100 <bread+0x40>
    800030fa:	68a4                	ld	s1,80(s1)
    800030fc:	02e48a63          	beq	s1,a4,80003130 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003100:	449c                	lw	a5,8(s1)
    80003102:	ff379ce3          	bne	a5,s3,800030fa <bread+0x3a>
    80003106:	44dc                	lw	a5,12(s1)
    80003108:	ff2799e3          	bne	a5,s2,800030fa <bread+0x3a>
      b->refcnt++;
    8000310c:	40bc                	lw	a5,64(s1)
    8000310e:	2785                	addiw	a5,a5,1
    80003110:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003112:	0000d517          	auipc	a0,0xd
    80003116:	f4650513          	addi	a0,a0,-186 # 80010058 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	b7e080e7          	jalr	-1154(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003122:	01048513          	addi	a0,s1,16
    80003126:	00001097          	auipc	ra,0x1
    8000312a:	466080e7          	jalr	1126(ra) # 8000458c <acquiresleep>
      return b;
    8000312e:	a8b9                	j	8000318c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003130:	00015497          	auipc	s1,0x15
    80003134:	1d84b483          	ld	s1,472(s1) # 80018308 <bcache+0x82b0>
    80003138:	00015797          	auipc	a5,0x15
    8000313c:	18878793          	addi	a5,a5,392 # 800182c0 <bcache+0x8268>
    80003140:	00f48863          	beq	s1,a5,80003150 <bread+0x90>
    80003144:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003146:	40bc                	lw	a5,64(s1)
    80003148:	cf81                	beqz	a5,80003160 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000314a:	64a4                	ld	s1,72(s1)
    8000314c:	fee49de3          	bne	s1,a4,80003146 <bread+0x86>
  panic("bget: no buffers");
    80003150:	00005517          	auipc	a0,0x5
    80003154:	3f050513          	addi	a0,a0,1008 # 80008540 <syscalls+0xd0>
    80003158:	ffffd097          	auipc	ra,0xffffd
    8000315c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>
      b->dev = dev;
    80003160:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003164:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003168:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000316c:	4785                	li	a5,1
    8000316e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003170:	0000d517          	auipc	a0,0xd
    80003174:	ee850513          	addi	a0,a0,-280 # 80010058 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	b20080e7          	jalr	-1248(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003180:	01048513          	addi	a0,s1,16
    80003184:	00001097          	auipc	ra,0x1
    80003188:	408080e7          	jalr	1032(ra) # 8000458c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000318c:	409c                	lw	a5,0(s1)
    8000318e:	cb89                	beqz	a5,800031a0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003190:	8526                	mv	a0,s1
    80003192:	70a2                	ld	ra,40(sp)
    80003194:	7402                	ld	s0,32(sp)
    80003196:	64e2                	ld	s1,24(sp)
    80003198:	6942                	ld	s2,16(sp)
    8000319a:	69a2                	ld	s3,8(sp)
    8000319c:	6145                	addi	sp,sp,48
    8000319e:	8082                	ret
    virtio_disk_rw(b, 0);
    800031a0:	4581                	li	a1,0
    800031a2:	8526                	mv	a0,s1
    800031a4:	00003097          	auipc	ra,0x3
    800031a8:	f12080e7          	jalr	-238(ra) # 800060b6 <virtio_disk_rw>
    b->valid = 1;
    800031ac:	4785                	li	a5,1
    800031ae:	c09c                	sw	a5,0(s1)
  return b;
    800031b0:	b7c5                	j	80003190 <bread+0xd0>

00000000800031b2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	1000                	addi	s0,sp,32
    800031bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031be:	0541                	addi	a0,a0,16
    800031c0:	00001097          	auipc	ra,0x1
    800031c4:	466080e7          	jalr	1126(ra) # 80004626 <holdingsleep>
    800031c8:	cd01                	beqz	a0,800031e0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031ca:	4585                	li	a1,1
    800031cc:	8526                	mv	a0,s1
    800031ce:	00003097          	auipc	ra,0x3
    800031d2:	ee8080e7          	jalr	-280(ra) # 800060b6 <virtio_disk_rw>
}
    800031d6:	60e2                	ld	ra,24(sp)
    800031d8:	6442                	ld	s0,16(sp)
    800031da:	64a2                	ld	s1,8(sp)
    800031dc:	6105                	addi	sp,sp,32
    800031de:	8082                	ret
    panic("bwrite");
    800031e0:	00005517          	auipc	a0,0x5
    800031e4:	37850513          	addi	a0,a0,888 # 80008558 <syscalls+0xe8>
    800031e8:	ffffd097          	auipc	ra,0xffffd
    800031ec:	356080e7          	jalr	854(ra) # 8000053e <panic>

00000000800031f0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	e426                	sd	s1,8(sp)
    800031f8:	e04a                	sd	s2,0(sp)
    800031fa:	1000                	addi	s0,sp,32
    800031fc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031fe:	01050913          	addi	s2,a0,16
    80003202:	854a                	mv	a0,s2
    80003204:	00001097          	auipc	ra,0x1
    80003208:	422080e7          	jalr	1058(ra) # 80004626 <holdingsleep>
    8000320c:	c92d                	beqz	a0,8000327e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000320e:	854a                	mv	a0,s2
    80003210:	00001097          	auipc	ra,0x1
    80003214:	3d2080e7          	jalr	978(ra) # 800045e2 <releasesleep>

  acquire(&bcache.lock);
    80003218:	0000d517          	auipc	a0,0xd
    8000321c:	e4050513          	addi	a0,a0,-448 # 80010058 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003228:	40bc                	lw	a5,64(s1)
    8000322a:	37fd                	addiw	a5,a5,-1
    8000322c:	0007871b          	sext.w	a4,a5
    80003230:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003232:	eb05                	bnez	a4,80003262 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003234:	68bc                	ld	a5,80(s1)
    80003236:	64b8                	ld	a4,72(s1)
    80003238:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000323a:	64bc                	ld	a5,72(s1)
    8000323c:	68b8                	ld	a4,80(s1)
    8000323e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003240:	00015797          	auipc	a5,0x15
    80003244:	e1878793          	addi	a5,a5,-488 # 80018058 <bcache+0x8000>
    80003248:	2b87b703          	ld	a4,696(a5)
    8000324c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000324e:	00015717          	auipc	a4,0x15
    80003252:	07270713          	addi	a4,a4,114 # 800182c0 <bcache+0x8268>
    80003256:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003258:	2b87b703          	ld	a4,696(a5)
    8000325c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000325e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003262:	0000d517          	auipc	a0,0xd
    80003266:	df650513          	addi	a0,a0,-522 # 80010058 <bcache>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	64a2                	ld	s1,8(sp)
    80003278:	6902                	ld	s2,0(sp)
    8000327a:	6105                	addi	sp,sp,32
    8000327c:	8082                	ret
    panic("brelse");
    8000327e:	00005517          	auipc	a0,0x5
    80003282:	2e250513          	addi	a0,a0,738 # 80008560 <syscalls+0xf0>
    80003286:	ffffd097          	auipc	ra,0xffffd
    8000328a:	2b8080e7          	jalr	696(ra) # 8000053e <panic>

000000008000328e <bpin>:

void
bpin(struct buf *b) {
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	1000                	addi	s0,sp,32
    80003298:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000329a:	0000d517          	auipc	a0,0xd
    8000329e:	dbe50513          	addi	a0,a0,-578 # 80010058 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032aa:	40bc                	lw	a5,64(s1)
    800032ac:	2785                	addiw	a5,a5,1
    800032ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032b0:	0000d517          	auipc	a0,0xd
    800032b4:	da850513          	addi	a0,a0,-600 # 80010058 <bcache>
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	64a2                	ld	s1,8(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret

00000000800032ca <bunpin>:

void
bunpin(struct buf *b) {
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	1000                	addi	s0,sp,32
    800032d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d6:	0000d517          	auipc	a0,0xd
    800032da:	d8250513          	addi	a0,a0,-638 # 80010058 <bcache>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	906080e7          	jalr	-1786(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032e6:	40bc                	lw	a5,64(s1)
    800032e8:	37fd                	addiw	a5,a5,-1
    800032ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ec:	0000d517          	auipc	a0,0xd
    800032f0:	d6c50513          	addi	a0,a0,-660 # 80010058 <bcache>
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	9a4080e7          	jalr	-1628(ra) # 80000c98 <release>
}
    800032fc:	60e2                	ld	ra,24(sp)
    800032fe:	6442                	ld	s0,16(sp)
    80003300:	64a2                	ld	s1,8(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret

0000000080003306 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	e426                	sd	s1,8(sp)
    8000330e:	e04a                	sd	s2,0(sp)
    80003310:	1000                	addi	s0,sp,32
    80003312:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003314:	00d5d59b          	srliw	a1,a1,0xd
    80003318:	00015797          	auipc	a5,0x15
    8000331c:	41c7a783          	lw	a5,1052(a5) # 80018734 <sb+0x1c>
    80003320:	9dbd                	addw	a1,a1,a5
    80003322:	00000097          	auipc	ra,0x0
    80003326:	d9e080e7          	jalr	-610(ra) # 800030c0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000332a:	0074f713          	andi	a4,s1,7
    8000332e:	4785                	li	a5,1
    80003330:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003334:	14ce                	slli	s1,s1,0x33
    80003336:	90d9                	srli	s1,s1,0x36
    80003338:	00950733          	add	a4,a0,s1
    8000333c:	05874703          	lbu	a4,88(a4)
    80003340:	00e7f6b3          	and	a3,a5,a4
    80003344:	c69d                	beqz	a3,80003372 <bfree+0x6c>
    80003346:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003348:	94aa                	add	s1,s1,a0
    8000334a:	fff7c793          	not	a5,a5
    8000334e:	8ff9                	and	a5,a5,a4
    80003350:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003354:	00001097          	auipc	ra,0x1
    80003358:	118080e7          	jalr	280(ra) # 8000446c <log_write>
  brelse(bp);
    8000335c:	854a                	mv	a0,s2
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	e92080e7          	jalr	-366(ra) # 800031f0 <brelse>
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6902                	ld	s2,0(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret
    panic("freeing free block");
    80003372:	00005517          	auipc	a0,0x5
    80003376:	1f650513          	addi	a0,a0,502 # 80008568 <syscalls+0xf8>
    8000337a:	ffffd097          	auipc	ra,0xffffd
    8000337e:	1c4080e7          	jalr	452(ra) # 8000053e <panic>

0000000080003382 <balloc>:
{
    80003382:	711d                	addi	sp,sp,-96
    80003384:	ec86                	sd	ra,88(sp)
    80003386:	e8a2                	sd	s0,80(sp)
    80003388:	e4a6                	sd	s1,72(sp)
    8000338a:	e0ca                	sd	s2,64(sp)
    8000338c:	fc4e                	sd	s3,56(sp)
    8000338e:	f852                	sd	s4,48(sp)
    80003390:	f456                	sd	s5,40(sp)
    80003392:	f05a                	sd	s6,32(sp)
    80003394:	ec5e                	sd	s7,24(sp)
    80003396:	e862                	sd	s8,16(sp)
    80003398:	e466                	sd	s9,8(sp)
    8000339a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000339c:	00015797          	auipc	a5,0x15
    800033a0:	3807a783          	lw	a5,896(a5) # 8001871c <sb+0x4>
    800033a4:	cbd1                	beqz	a5,80003438 <balloc+0xb6>
    800033a6:	8baa                	mv	s7,a0
    800033a8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033aa:	00015b17          	auipc	s6,0x15
    800033ae:	36eb0b13          	addi	s6,s6,878 # 80018718 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033b4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033b8:	6c89                	lui	s9,0x2
    800033ba:	a831                	j	800033d6 <balloc+0x54>
    brelse(bp);
    800033bc:	854a                	mv	a0,s2
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	e32080e7          	jalr	-462(ra) # 800031f0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033c6:	015c87bb          	addw	a5,s9,s5
    800033ca:	00078a9b          	sext.w	s5,a5
    800033ce:	004b2703          	lw	a4,4(s6)
    800033d2:	06eaf363          	bgeu	s5,a4,80003438 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033d6:	41fad79b          	sraiw	a5,s5,0x1f
    800033da:	0137d79b          	srliw	a5,a5,0x13
    800033de:	015787bb          	addw	a5,a5,s5
    800033e2:	40d7d79b          	sraiw	a5,a5,0xd
    800033e6:	01cb2583          	lw	a1,28(s6)
    800033ea:	9dbd                	addw	a1,a1,a5
    800033ec:	855e                	mv	a0,s7
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	cd2080e7          	jalr	-814(ra) # 800030c0 <bread>
    800033f6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f8:	004b2503          	lw	a0,4(s6)
    800033fc:	000a849b          	sext.w	s1,s5
    80003400:	8662                	mv	a2,s8
    80003402:	faa4fde3          	bgeu	s1,a0,800033bc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003406:	41f6579b          	sraiw	a5,a2,0x1f
    8000340a:	01d7d69b          	srliw	a3,a5,0x1d
    8000340e:	00c6873b          	addw	a4,a3,a2
    80003412:	00777793          	andi	a5,a4,7
    80003416:	9f95                	subw	a5,a5,a3
    80003418:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000341c:	4037571b          	sraiw	a4,a4,0x3
    80003420:	00e906b3          	add	a3,s2,a4
    80003424:	0586c683          	lbu	a3,88(a3)
    80003428:	00d7f5b3          	and	a1,a5,a3
    8000342c:	cd91                	beqz	a1,80003448 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342e:	2605                	addiw	a2,a2,1
    80003430:	2485                	addiw	s1,s1,1
    80003432:	fd4618e3          	bne	a2,s4,80003402 <balloc+0x80>
    80003436:	b759                	j	800033bc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003438:	00005517          	auipc	a0,0x5
    8000343c:	14850513          	addi	a0,a0,328 # 80008580 <syscalls+0x110>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	0fe080e7          	jalr	254(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003448:	974a                	add	a4,a4,s2
    8000344a:	8fd5                	or	a5,a5,a3
    8000344c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003450:	854a                	mv	a0,s2
    80003452:	00001097          	auipc	ra,0x1
    80003456:	01a080e7          	jalr	26(ra) # 8000446c <log_write>
        brelse(bp);
    8000345a:	854a                	mv	a0,s2
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	d94080e7          	jalr	-620(ra) # 800031f0 <brelse>
  bp = bread(dev, bno);
    80003464:	85a6                	mv	a1,s1
    80003466:	855e                	mv	a0,s7
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	c58080e7          	jalr	-936(ra) # 800030c0 <bread>
    80003470:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003472:	40000613          	li	a2,1024
    80003476:	4581                	li	a1,0
    80003478:	05850513          	addi	a0,a0,88
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	864080e7          	jalr	-1948(ra) # 80000ce0 <memset>
  log_write(bp);
    80003484:	854a                	mv	a0,s2
    80003486:	00001097          	auipc	ra,0x1
    8000348a:	fe6080e7          	jalr	-26(ra) # 8000446c <log_write>
  brelse(bp);
    8000348e:	854a                	mv	a0,s2
    80003490:	00000097          	auipc	ra,0x0
    80003494:	d60080e7          	jalr	-672(ra) # 800031f0 <brelse>
}
    80003498:	8526                	mv	a0,s1
    8000349a:	60e6                	ld	ra,88(sp)
    8000349c:	6446                	ld	s0,80(sp)
    8000349e:	64a6                	ld	s1,72(sp)
    800034a0:	6906                	ld	s2,64(sp)
    800034a2:	79e2                	ld	s3,56(sp)
    800034a4:	7a42                	ld	s4,48(sp)
    800034a6:	7aa2                	ld	s5,40(sp)
    800034a8:	7b02                	ld	s6,32(sp)
    800034aa:	6be2                	ld	s7,24(sp)
    800034ac:	6c42                	ld	s8,16(sp)
    800034ae:	6ca2                	ld	s9,8(sp)
    800034b0:	6125                	addi	sp,sp,96
    800034b2:	8082                	ret

00000000800034b4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034b4:	7179                	addi	sp,sp,-48
    800034b6:	f406                	sd	ra,40(sp)
    800034b8:	f022                	sd	s0,32(sp)
    800034ba:	ec26                	sd	s1,24(sp)
    800034bc:	e84a                	sd	s2,16(sp)
    800034be:	e44e                	sd	s3,8(sp)
    800034c0:	e052                	sd	s4,0(sp)
    800034c2:	1800                	addi	s0,sp,48
    800034c4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034c6:	47ad                	li	a5,11
    800034c8:	04b7fe63          	bgeu	a5,a1,80003524 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034cc:	ff45849b          	addiw	s1,a1,-12
    800034d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034d4:	0ff00793          	li	a5,255
    800034d8:	0ae7e363          	bltu	a5,a4,8000357e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034dc:	08052583          	lw	a1,128(a0)
    800034e0:	c5ad                	beqz	a1,8000354a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034e2:	00092503          	lw	a0,0(s2)
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	bda080e7          	jalr	-1062(ra) # 800030c0 <bread>
    800034ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034f4:	02049593          	slli	a1,s1,0x20
    800034f8:	9181                	srli	a1,a1,0x20
    800034fa:	058a                	slli	a1,a1,0x2
    800034fc:	00b784b3          	add	s1,a5,a1
    80003500:	0004a983          	lw	s3,0(s1)
    80003504:	04098d63          	beqz	s3,8000355e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003508:	8552                	mv	a0,s4
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	ce6080e7          	jalr	-794(ra) # 800031f0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003512:	854e                	mv	a0,s3
    80003514:	70a2                	ld	ra,40(sp)
    80003516:	7402                	ld	s0,32(sp)
    80003518:	64e2                	ld	s1,24(sp)
    8000351a:	6942                	ld	s2,16(sp)
    8000351c:	69a2                	ld	s3,8(sp)
    8000351e:	6a02                	ld	s4,0(sp)
    80003520:	6145                	addi	sp,sp,48
    80003522:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003524:	02059493          	slli	s1,a1,0x20
    80003528:	9081                	srli	s1,s1,0x20
    8000352a:	048a                	slli	s1,s1,0x2
    8000352c:	94aa                	add	s1,s1,a0
    8000352e:	0504a983          	lw	s3,80(s1)
    80003532:	fe0990e3          	bnez	s3,80003512 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003536:	4108                	lw	a0,0(a0)
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	e4a080e7          	jalr	-438(ra) # 80003382 <balloc>
    80003540:	0005099b          	sext.w	s3,a0
    80003544:	0534a823          	sw	s3,80(s1)
    80003548:	b7e9                	j	80003512 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000354a:	4108                	lw	a0,0(a0)
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	e36080e7          	jalr	-458(ra) # 80003382 <balloc>
    80003554:	0005059b          	sext.w	a1,a0
    80003558:	08b92023          	sw	a1,128(s2)
    8000355c:	b759                	j	800034e2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000355e:	00092503          	lw	a0,0(s2)
    80003562:	00000097          	auipc	ra,0x0
    80003566:	e20080e7          	jalr	-480(ra) # 80003382 <balloc>
    8000356a:	0005099b          	sext.w	s3,a0
    8000356e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003572:	8552                	mv	a0,s4
    80003574:	00001097          	auipc	ra,0x1
    80003578:	ef8080e7          	jalr	-264(ra) # 8000446c <log_write>
    8000357c:	b771                	j	80003508 <bmap+0x54>
  panic("bmap: out of range");
    8000357e:	00005517          	auipc	a0,0x5
    80003582:	01a50513          	addi	a0,a0,26 # 80008598 <syscalls+0x128>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	fb8080e7          	jalr	-72(ra) # 8000053e <panic>

000000008000358e <iget>:
{
    8000358e:	7179                	addi	sp,sp,-48
    80003590:	f406                	sd	ra,40(sp)
    80003592:	f022                	sd	s0,32(sp)
    80003594:	ec26                	sd	s1,24(sp)
    80003596:	e84a                	sd	s2,16(sp)
    80003598:	e44e                	sd	s3,8(sp)
    8000359a:	e052                	sd	s4,0(sp)
    8000359c:	1800                	addi	s0,sp,48
    8000359e:	89aa                	mv	s3,a0
    800035a0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035a2:	00015517          	auipc	a0,0x15
    800035a6:	19650513          	addi	a0,a0,406 # 80018738 <itable>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	63a080e7          	jalr	1594(ra) # 80000be4 <acquire>
  empty = 0;
    800035b2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035b4:	00015497          	auipc	s1,0x15
    800035b8:	19c48493          	addi	s1,s1,412 # 80018750 <itable+0x18>
    800035bc:	00017697          	auipc	a3,0x17
    800035c0:	c2468693          	addi	a3,a3,-988 # 8001a1e0 <log>
    800035c4:	a039                	j	800035d2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035c6:	02090b63          	beqz	s2,800035fc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ca:	08848493          	addi	s1,s1,136
    800035ce:	02d48a63          	beq	s1,a3,80003602 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035d2:	449c                	lw	a5,8(s1)
    800035d4:	fef059e3          	blez	a5,800035c6 <iget+0x38>
    800035d8:	4098                	lw	a4,0(s1)
    800035da:	ff3716e3          	bne	a4,s3,800035c6 <iget+0x38>
    800035de:	40d8                	lw	a4,4(s1)
    800035e0:	ff4713e3          	bne	a4,s4,800035c6 <iget+0x38>
      ip->ref++;
    800035e4:	2785                	addiw	a5,a5,1
    800035e6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035e8:	00015517          	auipc	a0,0x15
    800035ec:	15050513          	addi	a0,a0,336 # 80018738 <itable>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	6a8080e7          	jalr	1704(ra) # 80000c98 <release>
      return ip;
    800035f8:	8926                	mv	s2,s1
    800035fa:	a03d                	j	80003628 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035fc:	f7f9                	bnez	a5,800035ca <iget+0x3c>
    800035fe:	8926                	mv	s2,s1
    80003600:	b7e9                	j	800035ca <iget+0x3c>
  if(empty == 0)
    80003602:	02090c63          	beqz	s2,8000363a <iget+0xac>
  ip->dev = dev;
    80003606:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000360a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000360e:	4785                	li	a5,1
    80003610:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003614:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003618:	00015517          	auipc	a0,0x15
    8000361c:	12050513          	addi	a0,a0,288 # 80018738 <itable>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	678080e7          	jalr	1656(ra) # 80000c98 <release>
}
    80003628:	854a                	mv	a0,s2
    8000362a:	70a2                	ld	ra,40(sp)
    8000362c:	7402                	ld	s0,32(sp)
    8000362e:	64e2                	ld	s1,24(sp)
    80003630:	6942                	ld	s2,16(sp)
    80003632:	69a2                	ld	s3,8(sp)
    80003634:	6a02                	ld	s4,0(sp)
    80003636:	6145                	addi	sp,sp,48
    80003638:	8082                	ret
    panic("iget: no inodes");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	f7650513          	addi	a0,a0,-138 # 800085b0 <syscalls+0x140>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>

000000008000364a <fsinit>:
fsinit(int dev) {
    8000364a:	7179                	addi	sp,sp,-48
    8000364c:	f406                	sd	ra,40(sp)
    8000364e:	f022                	sd	s0,32(sp)
    80003650:	ec26                	sd	s1,24(sp)
    80003652:	e84a                	sd	s2,16(sp)
    80003654:	e44e                	sd	s3,8(sp)
    80003656:	1800                	addi	s0,sp,48
    80003658:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000365a:	4585                	li	a1,1
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	a64080e7          	jalr	-1436(ra) # 800030c0 <bread>
    80003664:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003666:	00015997          	auipc	s3,0x15
    8000366a:	0b298993          	addi	s3,s3,178 # 80018718 <sb>
    8000366e:	02000613          	li	a2,32
    80003672:	05850593          	addi	a1,a0,88
    80003676:	854e                	mv	a0,s3
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	6c8080e7          	jalr	1736(ra) # 80000d40 <memmove>
  brelse(bp);
    80003680:	8526                	mv	a0,s1
    80003682:	00000097          	auipc	ra,0x0
    80003686:	b6e080e7          	jalr	-1170(ra) # 800031f0 <brelse>
  if(sb.magic != FSMAGIC)
    8000368a:	0009a703          	lw	a4,0(s3)
    8000368e:	102037b7          	lui	a5,0x10203
    80003692:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003696:	02f71263          	bne	a4,a5,800036ba <fsinit+0x70>
  initlog(dev, &sb);
    8000369a:	00015597          	auipc	a1,0x15
    8000369e:	07e58593          	addi	a1,a1,126 # 80018718 <sb>
    800036a2:	854a                	mv	a0,s2
    800036a4:	00001097          	auipc	ra,0x1
    800036a8:	b4c080e7          	jalr	-1204(ra) # 800041f0 <initlog>
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret
    panic("invalid file system");
    800036ba:	00005517          	auipc	a0,0x5
    800036be:	f0650513          	addi	a0,a0,-250 # 800085c0 <syscalls+0x150>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	e7c080e7          	jalr	-388(ra) # 8000053e <panic>

00000000800036ca <iinit>:
{
    800036ca:	7179                	addi	sp,sp,-48
    800036cc:	f406                	sd	ra,40(sp)
    800036ce:	f022                	sd	s0,32(sp)
    800036d0:	ec26                	sd	s1,24(sp)
    800036d2:	e84a                	sd	s2,16(sp)
    800036d4:	e44e                	sd	s3,8(sp)
    800036d6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036d8:	00005597          	auipc	a1,0x5
    800036dc:	f0058593          	addi	a1,a1,-256 # 800085d8 <syscalls+0x168>
    800036e0:	00015517          	auipc	a0,0x15
    800036e4:	05850513          	addi	a0,a0,88 # 80018738 <itable>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	46c080e7          	jalr	1132(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036f0:	00015497          	auipc	s1,0x15
    800036f4:	07048493          	addi	s1,s1,112 # 80018760 <itable+0x28>
    800036f8:	00017997          	auipc	s3,0x17
    800036fc:	af898993          	addi	s3,s3,-1288 # 8001a1f0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003700:	00005917          	auipc	s2,0x5
    80003704:	ee090913          	addi	s2,s2,-288 # 800085e0 <syscalls+0x170>
    80003708:	85ca                	mv	a1,s2
    8000370a:	8526                	mv	a0,s1
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	e46080e7          	jalr	-442(ra) # 80004552 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003714:	08848493          	addi	s1,s1,136
    80003718:	ff3498e3          	bne	s1,s3,80003708 <iinit+0x3e>
}
    8000371c:	70a2                	ld	ra,40(sp)
    8000371e:	7402                	ld	s0,32(sp)
    80003720:	64e2                	ld	s1,24(sp)
    80003722:	6942                	ld	s2,16(sp)
    80003724:	69a2                	ld	s3,8(sp)
    80003726:	6145                	addi	sp,sp,48
    80003728:	8082                	ret

000000008000372a <ialloc>:
{
    8000372a:	715d                	addi	sp,sp,-80
    8000372c:	e486                	sd	ra,72(sp)
    8000372e:	e0a2                	sd	s0,64(sp)
    80003730:	fc26                	sd	s1,56(sp)
    80003732:	f84a                	sd	s2,48(sp)
    80003734:	f44e                	sd	s3,40(sp)
    80003736:	f052                	sd	s4,32(sp)
    80003738:	ec56                	sd	s5,24(sp)
    8000373a:	e85a                	sd	s6,16(sp)
    8000373c:	e45e                	sd	s7,8(sp)
    8000373e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003740:	00015717          	auipc	a4,0x15
    80003744:	fe472703          	lw	a4,-28(a4) # 80018724 <sb+0xc>
    80003748:	4785                	li	a5,1
    8000374a:	04e7fa63          	bgeu	a5,a4,8000379e <ialloc+0x74>
    8000374e:	8aaa                	mv	s5,a0
    80003750:	8bae                	mv	s7,a1
    80003752:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003754:	00015a17          	auipc	s4,0x15
    80003758:	fc4a0a13          	addi	s4,s4,-60 # 80018718 <sb>
    8000375c:	00048b1b          	sext.w	s6,s1
    80003760:	0044d593          	srli	a1,s1,0x4
    80003764:	018a2783          	lw	a5,24(s4)
    80003768:	9dbd                	addw	a1,a1,a5
    8000376a:	8556                	mv	a0,s5
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	954080e7          	jalr	-1708(ra) # 800030c0 <bread>
    80003774:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003776:	05850993          	addi	s3,a0,88
    8000377a:	00f4f793          	andi	a5,s1,15
    8000377e:	079a                	slli	a5,a5,0x6
    80003780:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003782:	00099783          	lh	a5,0(s3)
    80003786:	c785                	beqz	a5,800037ae <ialloc+0x84>
    brelse(bp);
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	a68080e7          	jalr	-1432(ra) # 800031f0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003790:	0485                	addi	s1,s1,1
    80003792:	00ca2703          	lw	a4,12(s4)
    80003796:	0004879b          	sext.w	a5,s1
    8000379a:	fce7e1e3          	bltu	a5,a4,8000375c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	e4a50513          	addi	a0,a0,-438 # 800085e8 <syscalls+0x178>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	d98080e7          	jalr	-616(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037ae:	04000613          	li	a2,64
    800037b2:	4581                	li	a1,0
    800037b4:	854e                	mv	a0,s3
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	52a080e7          	jalr	1322(ra) # 80000ce0 <memset>
      dip->type = type;
    800037be:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037c2:	854a                	mv	a0,s2
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	ca8080e7          	jalr	-856(ra) # 8000446c <log_write>
      brelse(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	a22080e7          	jalr	-1502(ra) # 800031f0 <brelse>
      return iget(dev, inum);
    800037d6:	85da                	mv	a1,s6
    800037d8:	8556                	mv	a0,s5
    800037da:	00000097          	auipc	ra,0x0
    800037de:	db4080e7          	jalr	-588(ra) # 8000358e <iget>
}
    800037e2:	60a6                	ld	ra,72(sp)
    800037e4:	6406                	ld	s0,64(sp)
    800037e6:	74e2                	ld	s1,56(sp)
    800037e8:	7942                	ld	s2,48(sp)
    800037ea:	79a2                	ld	s3,40(sp)
    800037ec:	7a02                	ld	s4,32(sp)
    800037ee:	6ae2                	ld	s5,24(sp)
    800037f0:	6b42                	ld	s6,16(sp)
    800037f2:	6ba2                	ld	s7,8(sp)
    800037f4:	6161                	addi	sp,sp,80
    800037f6:	8082                	ret

00000000800037f8 <iupdate>:
{
    800037f8:	1101                	addi	sp,sp,-32
    800037fa:	ec06                	sd	ra,24(sp)
    800037fc:	e822                	sd	s0,16(sp)
    800037fe:	e426                	sd	s1,8(sp)
    80003800:	e04a                	sd	s2,0(sp)
    80003802:	1000                	addi	s0,sp,32
    80003804:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003806:	415c                	lw	a5,4(a0)
    80003808:	0047d79b          	srliw	a5,a5,0x4
    8000380c:	00015597          	auipc	a1,0x15
    80003810:	f245a583          	lw	a1,-220(a1) # 80018730 <sb+0x18>
    80003814:	9dbd                	addw	a1,a1,a5
    80003816:	4108                	lw	a0,0(a0)
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	8a8080e7          	jalr	-1880(ra) # 800030c0 <bread>
    80003820:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003822:	05850793          	addi	a5,a0,88
    80003826:	40c8                	lw	a0,4(s1)
    80003828:	893d                	andi	a0,a0,15
    8000382a:	051a                	slli	a0,a0,0x6
    8000382c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000382e:	04449703          	lh	a4,68(s1)
    80003832:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003836:	04649703          	lh	a4,70(s1)
    8000383a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000383e:	04849703          	lh	a4,72(s1)
    80003842:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003846:	04a49703          	lh	a4,74(s1)
    8000384a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000384e:	44f8                	lw	a4,76(s1)
    80003850:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003852:	03400613          	li	a2,52
    80003856:	05048593          	addi	a1,s1,80
    8000385a:	0531                	addi	a0,a0,12
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	4e4080e7          	jalr	1252(ra) # 80000d40 <memmove>
  log_write(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	c06080e7          	jalr	-1018(ra) # 8000446c <log_write>
  brelse(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00000097          	auipc	ra,0x0
    80003874:	980080e7          	jalr	-1664(ra) # 800031f0 <brelse>
}
    80003878:	60e2                	ld	ra,24(sp)
    8000387a:	6442                	ld	s0,16(sp)
    8000387c:	64a2                	ld	s1,8(sp)
    8000387e:	6902                	ld	s2,0(sp)
    80003880:	6105                	addi	sp,sp,32
    80003882:	8082                	ret

0000000080003884 <idup>:
{
    80003884:	1101                	addi	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	1000                	addi	s0,sp,32
    8000388e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003890:	00015517          	auipc	a0,0x15
    80003894:	ea850513          	addi	a0,a0,-344 # 80018738 <itable>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	34c080e7          	jalr	844(ra) # 80000be4 <acquire>
  ip->ref++;
    800038a0:	449c                	lw	a5,8(s1)
    800038a2:	2785                	addiw	a5,a5,1
    800038a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038a6:	00015517          	auipc	a0,0x15
    800038aa:	e9250513          	addi	a0,a0,-366 # 80018738 <itable>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
}
    800038b6:	8526                	mv	a0,s1
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6105                	addi	sp,sp,32
    800038c0:	8082                	ret

00000000800038c2 <ilock>:
{
    800038c2:	1101                	addi	sp,sp,-32
    800038c4:	ec06                	sd	ra,24(sp)
    800038c6:	e822                	sd	s0,16(sp)
    800038c8:	e426                	sd	s1,8(sp)
    800038ca:	e04a                	sd	s2,0(sp)
    800038cc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ce:	c115                	beqz	a0,800038f2 <ilock+0x30>
    800038d0:	84aa                	mv	s1,a0
    800038d2:	451c                	lw	a5,8(a0)
    800038d4:	00f05f63          	blez	a5,800038f2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038d8:	0541                	addi	a0,a0,16
    800038da:	00001097          	auipc	ra,0x1
    800038de:	cb2080e7          	jalr	-846(ra) # 8000458c <acquiresleep>
  if(ip->valid == 0){
    800038e2:	40bc                	lw	a5,64(s1)
    800038e4:	cf99                	beqz	a5,80003902 <ilock+0x40>
}
    800038e6:	60e2                	ld	ra,24(sp)
    800038e8:	6442                	ld	s0,16(sp)
    800038ea:	64a2                	ld	s1,8(sp)
    800038ec:	6902                	ld	s2,0(sp)
    800038ee:	6105                	addi	sp,sp,32
    800038f0:	8082                	ret
    panic("ilock");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	d0e50513          	addi	a0,a0,-754 # 80008600 <syscalls+0x190>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003902:	40dc                	lw	a5,4(s1)
    80003904:	0047d79b          	srliw	a5,a5,0x4
    80003908:	00015597          	auipc	a1,0x15
    8000390c:	e285a583          	lw	a1,-472(a1) # 80018730 <sb+0x18>
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	4088                	lw	a0,0(s1)
    80003914:	fffff097          	auipc	ra,0xfffff
    80003918:	7ac080e7          	jalr	1964(ra) # 800030c0 <bread>
    8000391c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000391e:	05850593          	addi	a1,a0,88
    80003922:	40dc                	lw	a5,4(s1)
    80003924:	8bbd                	andi	a5,a5,15
    80003926:	079a                	slli	a5,a5,0x6
    80003928:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000392a:	00059783          	lh	a5,0(a1)
    8000392e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003932:	00259783          	lh	a5,2(a1)
    80003936:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000393a:	00459783          	lh	a5,4(a1)
    8000393e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003942:	00659783          	lh	a5,6(a1)
    80003946:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000394a:	459c                	lw	a5,8(a1)
    8000394c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000394e:	03400613          	li	a2,52
    80003952:	05b1                	addi	a1,a1,12
    80003954:	05048513          	addi	a0,s1,80
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	3e8080e7          	jalr	1000(ra) # 80000d40 <memmove>
    brelse(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	00000097          	auipc	ra,0x0
    80003966:	88e080e7          	jalr	-1906(ra) # 800031f0 <brelse>
    ip->valid = 1;
    8000396a:	4785                	li	a5,1
    8000396c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000396e:	04449783          	lh	a5,68(s1)
    80003972:	fbb5                	bnez	a5,800038e6 <ilock+0x24>
      panic("ilock: no type");
    80003974:	00005517          	auipc	a0,0x5
    80003978:	c9450513          	addi	a0,a0,-876 # 80008608 <syscalls+0x198>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	bc2080e7          	jalr	-1086(ra) # 8000053e <panic>

0000000080003984 <iunlock>:
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	e426                	sd	s1,8(sp)
    8000398c:	e04a                	sd	s2,0(sp)
    8000398e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003990:	c905                	beqz	a0,800039c0 <iunlock+0x3c>
    80003992:	84aa                	mv	s1,a0
    80003994:	01050913          	addi	s2,a0,16
    80003998:	854a                	mv	a0,s2
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	c8c080e7          	jalr	-884(ra) # 80004626 <holdingsleep>
    800039a2:	cd19                	beqz	a0,800039c0 <iunlock+0x3c>
    800039a4:	449c                	lw	a5,8(s1)
    800039a6:	00f05d63          	blez	a5,800039c0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	c36080e7          	jalr	-970(ra) # 800045e2 <releasesleep>
}
    800039b4:	60e2                	ld	ra,24(sp)
    800039b6:	6442                	ld	s0,16(sp)
    800039b8:	64a2                	ld	s1,8(sp)
    800039ba:	6902                	ld	s2,0(sp)
    800039bc:	6105                	addi	sp,sp,32
    800039be:	8082                	ret
    panic("iunlock");
    800039c0:	00005517          	auipc	a0,0x5
    800039c4:	c5850513          	addi	a0,a0,-936 # 80008618 <syscalls+0x1a8>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	b76080e7          	jalr	-1162(ra) # 8000053e <panic>

00000000800039d0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039d0:	7179                	addi	sp,sp,-48
    800039d2:	f406                	sd	ra,40(sp)
    800039d4:	f022                	sd	s0,32(sp)
    800039d6:	ec26                	sd	s1,24(sp)
    800039d8:	e84a                	sd	s2,16(sp)
    800039da:	e44e                	sd	s3,8(sp)
    800039dc:	e052                	sd	s4,0(sp)
    800039de:	1800                	addi	s0,sp,48
    800039e0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039e2:	05050493          	addi	s1,a0,80
    800039e6:	08050913          	addi	s2,a0,128
    800039ea:	a021                	j	800039f2 <itrunc+0x22>
    800039ec:	0491                	addi	s1,s1,4
    800039ee:	01248d63          	beq	s1,s2,80003a08 <itrunc+0x38>
    if(ip->addrs[i]){
    800039f2:	408c                	lw	a1,0(s1)
    800039f4:	dde5                	beqz	a1,800039ec <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039f6:	0009a503          	lw	a0,0(s3)
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	90c080e7          	jalr	-1780(ra) # 80003306 <bfree>
      ip->addrs[i] = 0;
    80003a02:	0004a023          	sw	zero,0(s1)
    80003a06:	b7dd                	j	800039ec <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a08:	0809a583          	lw	a1,128(s3)
    80003a0c:	e185                	bnez	a1,80003a2c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a0e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a12:	854e                	mv	a0,s3
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	de4080e7          	jalr	-540(ra) # 800037f8 <iupdate>
}
    80003a1c:	70a2                	ld	ra,40(sp)
    80003a1e:	7402                	ld	s0,32(sp)
    80003a20:	64e2                	ld	s1,24(sp)
    80003a22:	6942                	ld	s2,16(sp)
    80003a24:	69a2                	ld	s3,8(sp)
    80003a26:	6a02                	ld	s4,0(sp)
    80003a28:	6145                	addi	sp,sp,48
    80003a2a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a2c:	0009a503          	lw	a0,0(s3)
    80003a30:	fffff097          	auipc	ra,0xfffff
    80003a34:	690080e7          	jalr	1680(ra) # 800030c0 <bread>
    80003a38:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a3a:	05850493          	addi	s1,a0,88
    80003a3e:	45850913          	addi	s2,a0,1112
    80003a42:	a811                	j	80003a56 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a44:	0009a503          	lw	a0,0(s3)
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	8be080e7          	jalr	-1858(ra) # 80003306 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a50:	0491                	addi	s1,s1,4
    80003a52:	01248563          	beq	s1,s2,80003a5c <itrunc+0x8c>
      if(a[j])
    80003a56:	408c                	lw	a1,0(s1)
    80003a58:	dde5                	beqz	a1,80003a50 <itrunc+0x80>
    80003a5a:	b7ed                	j	80003a44 <itrunc+0x74>
    brelse(bp);
    80003a5c:	8552                	mv	a0,s4
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	792080e7          	jalr	1938(ra) # 800031f0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a66:	0809a583          	lw	a1,128(s3)
    80003a6a:	0009a503          	lw	a0,0(s3)
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	898080e7          	jalr	-1896(ra) # 80003306 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a76:	0809a023          	sw	zero,128(s3)
    80003a7a:	bf51                	j	80003a0e <itrunc+0x3e>

0000000080003a7c <iput>:
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	e04a                	sd	s2,0(sp)
    80003a86:	1000                	addi	s0,sp,32
    80003a88:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a8a:	00015517          	auipc	a0,0x15
    80003a8e:	cae50513          	addi	a0,a0,-850 # 80018738 <itable>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	152080e7          	jalr	338(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a9a:	4498                	lw	a4,8(s1)
    80003a9c:	4785                	li	a5,1
    80003a9e:	02f70363          	beq	a4,a5,80003ac4 <iput+0x48>
  ip->ref--;
    80003aa2:	449c                	lw	a5,8(s1)
    80003aa4:	37fd                	addiw	a5,a5,-1
    80003aa6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa8:	00015517          	auipc	a0,0x15
    80003aac:	c9050513          	addi	a0,a0,-880 # 80018738 <itable>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	1e8080e7          	jalr	488(ra) # 80000c98 <release>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6902                	ld	s2,0(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ac4:	40bc                	lw	a5,64(s1)
    80003ac6:	dff1                	beqz	a5,80003aa2 <iput+0x26>
    80003ac8:	04a49783          	lh	a5,74(s1)
    80003acc:	fbf9                	bnez	a5,80003aa2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ace:	01048913          	addi	s2,s1,16
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	00001097          	auipc	ra,0x1
    80003ad8:	ab8080e7          	jalr	-1352(ra) # 8000458c <acquiresleep>
    release(&itable.lock);
    80003adc:	00015517          	auipc	a0,0x15
    80003ae0:	c5c50513          	addi	a0,a0,-932 # 80018738 <itable>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	1b4080e7          	jalr	436(ra) # 80000c98 <release>
    itrunc(ip);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	ee2080e7          	jalr	-286(ra) # 800039d0 <itrunc>
    ip->type = 0;
    80003af6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	cfc080e7          	jalr	-772(ra) # 800037f8 <iupdate>
    ip->valid = 0;
    80003b04:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00001097          	auipc	ra,0x1
    80003b0e:	ad8080e7          	jalr	-1320(ra) # 800045e2 <releasesleep>
    acquire(&itable.lock);
    80003b12:	00015517          	auipc	a0,0x15
    80003b16:	c2650513          	addi	a0,a0,-986 # 80018738 <itable>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	0ca080e7          	jalr	202(ra) # 80000be4 <acquire>
    80003b22:	b741                	j	80003aa2 <iput+0x26>

0000000080003b24 <iunlockput>:
{
    80003b24:	1101                	addi	sp,sp,-32
    80003b26:	ec06                	sd	ra,24(sp)
    80003b28:	e822                	sd	s0,16(sp)
    80003b2a:	e426                	sd	s1,8(sp)
    80003b2c:	1000                	addi	s0,sp,32
    80003b2e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	e54080e7          	jalr	-428(ra) # 80003984 <iunlock>
  iput(ip);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	f42080e7          	jalr	-190(ra) # 80003a7c <iput>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6105                	addi	sp,sp,32
    80003b4a:	8082                	ret

0000000080003b4c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b4c:	1141                	addi	sp,sp,-16
    80003b4e:	e422                	sd	s0,8(sp)
    80003b50:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b52:	411c                	lw	a5,0(a0)
    80003b54:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b56:	415c                	lw	a5,4(a0)
    80003b58:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b5a:	04451783          	lh	a5,68(a0)
    80003b5e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b62:	04a51783          	lh	a5,74(a0)
    80003b66:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b6a:	04c56783          	lwu	a5,76(a0)
    80003b6e:	e99c                	sd	a5,16(a1)
}
    80003b70:	6422                	ld	s0,8(sp)
    80003b72:	0141                	addi	sp,sp,16
    80003b74:	8082                	ret

0000000080003b76 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b76:	457c                	lw	a5,76(a0)
    80003b78:	0ed7e963          	bltu	a5,a3,80003c6a <readi+0xf4>
{
    80003b7c:	7159                	addi	sp,sp,-112
    80003b7e:	f486                	sd	ra,104(sp)
    80003b80:	f0a2                	sd	s0,96(sp)
    80003b82:	eca6                	sd	s1,88(sp)
    80003b84:	e8ca                	sd	s2,80(sp)
    80003b86:	e4ce                	sd	s3,72(sp)
    80003b88:	e0d2                	sd	s4,64(sp)
    80003b8a:	fc56                	sd	s5,56(sp)
    80003b8c:	f85a                	sd	s6,48(sp)
    80003b8e:	f45e                	sd	s7,40(sp)
    80003b90:	f062                	sd	s8,32(sp)
    80003b92:	ec66                	sd	s9,24(sp)
    80003b94:	e86a                	sd	s10,16(sp)
    80003b96:	e46e                	sd	s11,8(sp)
    80003b98:	1880                	addi	s0,sp,112
    80003b9a:	8baa                	mv	s7,a0
    80003b9c:	8c2e                	mv	s8,a1
    80003b9e:	8ab2                	mv	s5,a2
    80003ba0:	84b6                	mv	s1,a3
    80003ba2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba4:	9f35                	addw	a4,a4,a3
    return 0;
    80003ba6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ba8:	0ad76063          	bltu	a4,a3,80003c48 <readi+0xd2>
  if(off + n > ip->size)
    80003bac:	00e7f463          	bgeu	a5,a4,80003bb4 <readi+0x3e>
    n = ip->size - off;
    80003bb0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb4:	0a0b0963          	beqz	s6,80003c66 <readi+0xf0>
    80003bb8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bba:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bbe:	5cfd                	li	s9,-1
    80003bc0:	a82d                	j	80003bfa <readi+0x84>
    80003bc2:	020a1d93          	slli	s11,s4,0x20
    80003bc6:	020ddd93          	srli	s11,s11,0x20
    80003bca:	05890613          	addi	a2,s2,88
    80003bce:	86ee                	mv	a3,s11
    80003bd0:	963a                	add	a2,a2,a4
    80003bd2:	85d6                	mv	a1,s5
    80003bd4:	8562                	mv	a0,s8
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	aae080e7          	jalr	-1362(ra) # 80002684 <either_copyout>
    80003bde:	05950d63          	beq	a0,s9,80003c38 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003be2:	854a                	mv	a0,s2
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	60c080e7          	jalr	1548(ra) # 800031f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bec:	013a09bb          	addw	s3,s4,s3
    80003bf0:	009a04bb          	addw	s1,s4,s1
    80003bf4:	9aee                	add	s5,s5,s11
    80003bf6:	0569f763          	bgeu	s3,s6,80003c44 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bfa:	000ba903          	lw	s2,0(s7)
    80003bfe:	00a4d59b          	srliw	a1,s1,0xa
    80003c02:	855e                	mv	a0,s7
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	8b0080e7          	jalr	-1872(ra) # 800034b4 <bmap>
    80003c0c:	0005059b          	sext.w	a1,a0
    80003c10:	854a                	mv	a0,s2
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	4ae080e7          	jalr	1198(ra) # 800030c0 <bread>
    80003c1a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1c:	3ff4f713          	andi	a4,s1,1023
    80003c20:	40ed07bb          	subw	a5,s10,a4
    80003c24:	413b06bb          	subw	a3,s6,s3
    80003c28:	8a3e                	mv	s4,a5
    80003c2a:	2781                	sext.w	a5,a5
    80003c2c:	0006861b          	sext.w	a2,a3
    80003c30:	f8f679e3          	bgeu	a2,a5,80003bc2 <readi+0x4c>
    80003c34:	8a36                	mv	s4,a3
    80003c36:	b771                	j	80003bc2 <readi+0x4c>
      brelse(bp);
    80003c38:	854a                	mv	a0,s2
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	5b6080e7          	jalr	1462(ra) # 800031f0 <brelse>
      tot = -1;
    80003c42:	59fd                	li	s3,-1
  }
  return tot;
    80003c44:	0009851b          	sext.w	a0,s3
}
    80003c48:	70a6                	ld	ra,104(sp)
    80003c4a:	7406                	ld	s0,96(sp)
    80003c4c:	64e6                	ld	s1,88(sp)
    80003c4e:	6946                	ld	s2,80(sp)
    80003c50:	69a6                	ld	s3,72(sp)
    80003c52:	6a06                	ld	s4,64(sp)
    80003c54:	7ae2                	ld	s5,56(sp)
    80003c56:	7b42                	ld	s6,48(sp)
    80003c58:	7ba2                	ld	s7,40(sp)
    80003c5a:	7c02                	ld	s8,32(sp)
    80003c5c:	6ce2                	ld	s9,24(sp)
    80003c5e:	6d42                	ld	s10,16(sp)
    80003c60:	6da2                	ld	s11,8(sp)
    80003c62:	6165                	addi	sp,sp,112
    80003c64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c66:	89da                	mv	s3,s6
    80003c68:	bff1                	j	80003c44 <readi+0xce>
    return 0;
    80003c6a:	4501                	li	a0,0
}
    80003c6c:	8082                	ret

0000000080003c6e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c6e:	457c                	lw	a5,76(a0)
    80003c70:	10d7e863          	bltu	a5,a3,80003d80 <writei+0x112>
{
    80003c74:	7159                	addi	sp,sp,-112
    80003c76:	f486                	sd	ra,104(sp)
    80003c78:	f0a2                	sd	s0,96(sp)
    80003c7a:	eca6                	sd	s1,88(sp)
    80003c7c:	e8ca                	sd	s2,80(sp)
    80003c7e:	e4ce                	sd	s3,72(sp)
    80003c80:	e0d2                	sd	s4,64(sp)
    80003c82:	fc56                	sd	s5,56(sp)
    80003c84:	f85a                	sd	s6,48(sp)
    80003c86:	f45e                	sd	s7,40(sp)
    80003c88:	f062                	sd	s8,32(sp)
    80003c8a:	ec66                	sd	s9,24(sp)
    80003c8c:	e86a                	sd	s10,16(sp)
    80003c8e:	e46e                	sd	s11,8(sp)
    80003c90:	1880                	addi	s0,sp,112
    80003c92:	8b2a                	mv	s6,a0
    80003c94:	8c2e                	mv	s8,a1
    80003c96:	8ab2                	mv	s5,a2
    80003c98:	8936                	mv	s2,a3
    80003c9a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c9c:	00e687bb          	addw	a5,a3,a4
    80003ca0:	0ed7e263          	bltu	a5,a3,80003d84 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ca4:	00043737          	lui	a4,0x43
    80003ca8:	0ef76063          	bltu	a4,a5,80003d88 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cac:	0c0b8863          	beqz	s7,80003d7c <writei+0x10e>
    80003cb0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cb6:	5cfd                	li	s9,-1
    80003cb8:	a091                	j	80003cfc <writei+0x8e>
    80003cba:	02099d93          	slli	s11,s3,0x20
    80003cbe:	020ddd93          	srli	s11,s11,0x20
    80003cc2:	05848513          	addi	a0,s1,88
    80003cc6:	86ee                	mv	a3,s11
    80003cc8:	8656                	mv	a2,s5
    80003cca:	85e2                	mv	a1,s8
    80003ccc:	953a                	add	a0,a0,a4
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	a0c080e7          	jalr	-1524(ra) # 800026da <either_copyin>
    80003cd6:	07950263          	beq	a0,s9,80003d3a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cda:	8526                	mv	a0,s1
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	790080e7          	jalr	1936(ra) # 8000446c <log_write>
    brelse(bp);
    80003ce4:	8526                	mv	a0,s1
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	50a080e7          	jalr	1290(ra) # 800031f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cee:	01498a3b          	addw	s4,s3,s4
    80003cf2:	0129893b          	addw	s2,s3,s2
    80003cf6:	9aee                	add	s5,s5,s11
    80003cf8:	057a7663          	bgeu	s4,s7,80003d44 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cfc:	000b2483          	lw	s1,0(s6)
    80003d00:	00a9559b          	srliw	a1,s2,0xa
    80003d04:	855a                	mv	a0,s6
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	7ae080e7          	jalr	1966(ra) # 800034b4 <bmap>
    80003d0e:	0005059b          	sext.w	a1,a0
    80003d12:	8526                	mv	a0,s1
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	3ac080e7          	jalr	940(ra) # 800030c0 <bread>
    80003d1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d1e:	3ff97713          	andi	a4,s2,1023
    80003d22:	40ed07bb          	subw	a5,s10,a4
    80003d26:	414b86bb          	subw	a3,s7,s4
    80003d2a:	89be                	mv	s3,a5
    80003d2c:	2781                	sext.w	a5,a5
    80003d2e:	0006861b          	sext.w	a2,a3
    80003d32:	f8f674e3          	bgeu	a2,a5,80003cba <writei+0x4c>
    80003d36:	89b6                	mv	s3,a3
    80003d38:	b749                	j	80003cba <writei+0x4c>
      brelse(bp);
    80003d3a:	8526                	mv	a0,s1
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	4b4080e7          	jalr	1204(ra) # 800031f0 <brelse>
  }

  if(off > ip->size)
    80003d44:	04cb2783          	lw	a5,76(s6)
    80003d48:	0127f463          	bgeu	a5,s2,80003d50 <writei+0xe2>
    ip->size = off;
    80003d4c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d50:	855a                	mv	a0,s6
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	aa6080e7          	jalr	-1370(ra) # 800037f8 <iupdate>

  return tot;
    80003d5a:	000a051b          	sext.w	a0,s4
}
    80003d5e:	70a6                	ld	ra,104(sp)
    80003d60:	7406                	ld	s0,96(sp)
    80003d62:	64e6                	ld	s1,88(sp)
    80003d64:	6946                	ld	s2,80(sp)
    80003d66:	69a6                	ld	s3,72(sp)
    80003d68:	6a06                	ld	s4,64(sp)
    80003d6a:	7ae2                	ld	s5,56(sp)
    80003d6c:	7b42                	ld	s6,48(sp)
    80003d6e:	7ba2                	ld	s7,40(sp)
    80003d70:	7c02                	ld	s8,32(sp)
    80003d72:	6ce2                	ld	s9,24(sp)
    80003d74:	6d42                	ld	s10,16(sp)
    80003d76:	6da2                	ld	s11,8(sp)
    80003d78:	6165                	addi	sp,sp,112
    80003d7a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d7c:	8a5e                	mv	s4,s7
    80003d7e:	bfc9                	j	80003d50 <writei+0xe2>
    return -1;
    80003d80:	557d                	li	a0,-1
}
    80003d82:	8082                	ret
    return -1;
    80003d84:	557d                	li	a0,-1
    80003d86:	bfe1                	j	80003d5e <writei+0xf0>
    return -1;
    80003d88:	557d                	li	a0,-1
    80003d8a:	bfd1                	j	80003d5e <writei+0xf0>

0000000080003d8c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d8c:	1141                	addi	sp,sp,-16
    80003d8e:	e406                	sd	ra,8(sp)
    80003d90:	e022                	sd	s0,0(sp)
    80003d92:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d94:	4639                	li	a2,14
    80003d96:	ffffd097          	auipc	ra,0xffffd
    80003d9a:	022080e7          	jalr	34(ra) # 80000db8 <strncmp>
}
    80003d9e:	60a2                	ld	ra,8(sp)
    80003da0:	6402                	ld	s0,0(sp)
    80003da2:	0141                	addi	sp,sp,16
    80003da4:	8082                	ret

0000000080003da6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003da6:	7139                	addi	sp,sp,-64
    80003da8:	fc06                	sd	ra,56(sp)
    80003daa:	f822                	sd	s0,48(sp)
    80003dac:	f426                	sd	s1,40(sp)
    80003dae:	f04a                	sd	s2,32(sp)
    80003db0:	ec4e                	sd	s3,24(sp)
    80003db2:	e852                	sd	s4,16(sp)
    80003db4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003db6:	04451703          	lh	a4,68(a0)
    80003dba:	4785                	li	a5,1
    80003dbc:	00f71a63          	bne	a4,a5,80003dd0 <dirlookup+0x2a>
    80003dc0:	892a                	mv	s2,a0
    80003dc2:	89ae                	mv	s3,a1
    80003dc4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc6:	457c                	lw	a5,76(a0)
    80003dc8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dca:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dcc:	e79d                	bnez	a5,80003dfa <dirlookup+0x54>
    80003dce:	a8a5                	j	80003e46 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dd0:	00005517          	auipc	a0,0x5
    80003dd4:	85050513          	addi	a0,a0,-1968 # 80008620 <syscalls+0x1b0>
    80003dd8:	ffffc097          	auipc	ra,0xffffc
    80003ddc:	766080e7          	jalr	1894(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003de0:	00005517          	auipc	a0,0x5
    80003de4:	85850513          	addi	a0,a0,-1960 # 80008638 <syscalls+0x1c8>
    80003de8:	ffffc097          	auipc	ra,0xffffc
    80003dec:	756080e7          	jalr	1878(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df0:	24c1                	addiw	s1,s1,16
    80003df2:	04c92783          	lw	a5,76(s2)
    80003df6:	04f4f763          	bgeu	s1,a5,80003e44 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dfa:	4741                	li	a4,16
    80003dfc:	86a6                	mv	a3,s1
    80003dfe:	fc040613          	addi	a2,s0,-64
    80003e02:	4581                	li	a1,0
    80003e04:	854a                	mv	a0,s2
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	d70080e7          	jalr	-656(ra) # 80003b76 <readi>
    80003e0e:	47c1                	li	a5,16
    80003e10:	fcf518e3          	bne	a0,a5,80003de0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e14:	fc045783          	lhu	a5,-64(s0)
    80003e18:	dfe1                	beqz	a5,80003df0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e1a:	fc240593          	addi	a1,s0,-62
    80003e1e:	854e                	mv	a0,s3
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	f6c080e7          	jalr	-148(ra) # 80003d8c <namecmp>
    80003e28:	f561                	bnez	a0,80003df0 <dirlookup+0x4a>
      if(poff)
    80003e2a:	000a0463          	beqz	s4,80003e32 <dirlookup+0x8c>
        *poff = off;
    80003e2e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e32:	fc045583          	lhu	a1,-64(s0)
    80003e36:	00092503          	lw	a0,0(s2)
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	754080e7          	jalr	1876(ra) # 8000358e <iget>
    80003e42:	a011                	j	80003e46 <dirlookup+0xa0>
  return 0;
    80003e44:	4501                	li	a0,0
}
    80003e46:	70e2                	ld	ra,56(sp)
    80003e48:	7442                	ld	s0,48(sp)
    80003e4a:	74a2                	ld	s1,40(sp)
    80003e4c:	7902                	ld	s2,32(sp)
    80003e4e:	69e2                	ld	s3,24(sp)
    80003e50:	6a42                	ld	s4,16(sp)
    80003e52:	6121                	addi	sp,sp,64
    80003e54:	8082                	ret

0000000080003e56 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e56:	711d                	addi	sp,sp,-96
    80003e58:	ec86                	sd	ra,88(sp)
    80003e5a:	e8a2                	sd	s0,80(sp)
    80003e5c:	e4a6                	sd	s1,72(sp)
    80003e5e:	e0ca                	sd	s2,64(sp)
    80003e60:	fc4e                	sd	s3,56(sp)
    80003e62:	f852                	sd	s4,48(sp)
    80003e64:	f456                	sd	s5,40(sp)
    80003e66:	f05a                	sd	s6,32(sp)
    80003e68:	ec5e                	sd	s7,24(sp)
    80003e6a:	e862                	sd	s8,16(sp)
    80003e6c:	e466                	sd	s9,8(sp)
    80003e6e:	1080                	addi	s0,sp,96
    80003e70:	84aa                	mv	s1,a0
    80003e72:	8b2e                	mv	s6,a1
    80003e74:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e76:	00054703          	lbu	a4,0(a0)
    80003e7a:	02f00793          	li	a5,47
    80003e7e:	02f70363          	beq	a4,a5,80003ea4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e82:	ffffe097          	auipc	ra,0xffffe
    80003e86:	b36080e7          	jalr	-1226(ra) # 800019b8 <myproc>
    80003e8a:	15053503          	ld	a0,336(a0)
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	9f6080e7          	jalr	-1546(ra) # 80003884 <idup>
    80003e96:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e98:	02f00913          	li	s2,47
  len = path - s;
    80003e9c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e9e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ea0:	4c05                	li	s8,1
    80003ea2:	a865                	j	80003f5a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ea4:	4585                	li	a1,1
    80003ea6:	4505                	li	a0,1
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	6e6080e7          	jalr	1766(ra) # 8000358e <iget>
    80003eb0:	89aa                	mv	s3,a0
    80003eb2:	b7dd                	j	80003e98 <namex+0x42>
      iunlockput(ip);
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	c6e080e7          	jalr	-914(ra) # 80003b24 <iunlockput>
      return 0;
    80003ebe:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	60e6                	ld	ra,88(sp)
    80003ec4:	6446                	ld	s0,80(sp)
    80003ec6:	64a6                	ld	s1,72(sp)
    80003ec8:	6906                	ld	s2,64(sp)
    80003eca:	79e2                	ld	s3,56(sp)
    80003ecc:	7a42                	ld	s4,48(sp)
    80003ece:	7aa2                	ld	s5,40(sp)
    80003ed0:	7b02                	ld	s6,32(sp)
    80003ed2:	6be2                	ld	s7,24(sp)
    80003ed4:	6c42                	ld	s8,16(sp)
    80003ed6:	6ca2                	ld	s9,8(sp)
    80003ed8:	6125                	addi	sp,sp,96
    80003eda:	8082                	ret
      iunlock(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	aa6080e7          	jalr	-1370(ra) # 80003984 <iunlock>
      return ip;
    80003ee6:	bfe9                	j	80003ec0 <namex+0x6a>
      iunlockput(ip);
    80003ee8:	854e                	mv	a0,s3
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	c3a080e7          	jalr	-966(ra) # 80003b24 <iunlockput>
      return 0;
    80003ef2:	89d2                	mv	s3,s4
    80003ef4:	b7f1                	j	80003ec0 <namex+0x6a>
  len = path - s;
    80003ef6:	40b48633          	sub	a2,s1,a1
    80003efa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003efe:	094cd463          	bge	s9,s4,80003f86 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f02:	4639                	li	a2,14
    80003f04:	8556                	mv	a0,s5
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	e3a080e7          	jalr	-454(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	01279763          	bne	a5,s2,80003f20 <namex+0xca>
    path++;
    80003f16:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f18:	0004c783          	lbu	a5,0(s1)
    80003f1c:	ff278de3          	beq	a5,s2,80003f16 <namex+0xc0>
    ilock(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	9a0080e7          	jalr	-1632(ra) # 800038c2 <ilock>
    if(ip->type != T_DIR){
    80003f2a:	04499783          	lh	a5,68(s3)
    80003f2e:	f98793e3          	bne	a5,s8,80003eb4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f32:	000b0563          	beqz	s6,80003f3c <namex+0xe6>
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	d3cd                	beqz	a5,80003edc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f3c:	865e                	mv	a2,s7
    80003f3e:	85d6                	mv	a1,s5
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	e64080e7          	jalr	-412(ra) # 80003da6 <dirlookup>
    80003f4a:	8a2a                	mv	s4,a0
    80003f4c:	dd51                	beqz	a0,80003ee8 <namex+0x92>
    iunlockput(ip);
    80003f4e:	854e                	mv	a0,s3
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	bd4080e7          	jalr	-1068(ra) # 80003b24 <iunlockput>
    ip = next;
    80003f58:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	05279763          	bne	a5,s2,80003fac <namex+0x156>
    path++;
    80003f62:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f64:	0004c783          	lbu	a5,0(s1)
    80003f68:	ff278de3          	beq	a5,s2,80003f62 <namex+0x10c>
  if(*path == 0)
    80003f6c:	c79d                	beqz	a5,80003f9a <namex+0x144>
    path++;
    80003f6e:	85a6                	mv	a1,s1
  len = path - s;
    80003f70:	8a5e                	mv	s4,s7
    80003f72:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f74:	01278963          	beq	a5,s2,80003f86 <namex+0x130>
    80003f78:	dfbd                	beqz	a5,80003ef6 <namex+0xa0>
    path++;
    80003f7a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f7c:	0004c783          	lbu	a5,0(s1)
    80003f80:	ff279ce3          	bne	a5,s2,80003f78 <namex+0x122>
    80003f84:	bf8d                	j	80003ef6 <namex+0xa0>
    memmove(name, s, len);
    80003f86:	2601                	sext.w	a2,a2
    80003f88:	8556                	mv	a0,s5
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	db6080e7          	jalr	-586(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f92:	9a56                	add	s4,s4,s5
    80003f94:	000a0023          	sb	zero,0(s4)
    80003f98:	bf9d                	j	80003f0e <namex+0xb8>
  if(nameiparent){
    80003f9a:	f20b03e3          	beqz	s6,80003ec0 <namex+0x6a>
    iput(ip);
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	adc080e7          	jalr	-1316(ra) # 80003a7c <iput>
    return 0;
    80003fa8:	4981                	li	s3,0
    80003faa:	bf19                	j	80003ec0 <namex+0x6a>
  if(*path == 0)
    80003fac:	d7fd                	beqz	a5,80003f9a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fae:	0004c783          	lbu	a5,0(s1)
    80003fb2:	85a6                	mv	a1,s1
    80003fb4:	b7d1                	j	80003f78 <namex+0x122>

0000000080003fb6 <dirlink>:
{
    80003fb6:	7139                	addi	sp,sp,-64
    80003fb8:	fc06                	sd	ra,56(sp)
    80003fba:	f822                	sd	s0,48(sp)
    80003fbc:	f426                	sd	s1,40(sp)
    80003fbe:	f04a                	sd	s2,32(sp)
    80003fc0:	ec4e                	sd	s3,24(sp)
    80003fc2:	e852                	sd	s4,16(sp)
    80003fc4:	0080                	addi	s0,sp,64
    80003fc6:	892a                	mv	s2,a0
    80003fc8:	8a2e                	mv	s4,a1
    80003fca:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fcc:	4601                	li	a2,0
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	dd8080e7          	jalr	-552(ra) # 80003da6 <dirlookup>
    80003fd6:	e93d                	bnez	a0,8000404c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd8:	04c92483          	lw	s1,76(s2)
    80003fdc:	c49d                	beqz	s1,8000400a <dirlink+0x54>
    80003fde:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe0:	4741                	li	a4,16
    80003fe2:	86a6                	mv	a3,s1
    80003fe4:	fc040613          	addi	a2,s0,-64
    80003fe8:	4581                	li	a1,0
    80003fea:	854a                	mv	a0,s2
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	b8a080e7          	jalr	-1142(ra) # 80003b76 <readi>
    80003ff4:	47c1                	li	a5,16
    80003ff6:	06f51163          	bne	a0,a5,80004058 <dirlink+0xa2>
    if(de.inum == 0)
    80003ffa:	fc045783          	lhu	a5,-64(s0)
    80003ffe:	c791                	beqz	a5,8000400a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004000:	24c1                	addiw	s1,s1,16
    80004002:	04c92783          	lw	a5,76(s2)
    80004006:	fcf4ede3          	bltu	s1,a5,80003fe0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000400a:	4639                	li	a2,14
    8000400c:	85d2                	mv	a1,s4
    8000400e:	fc240513          	addi	a0,s0,-62
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	de2080e7          	jalr	-542(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000401a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000401e:	4741                	li	a4,16
    80004020:	86a6                	mv	a3,s1
    80004022:	fc040613          	addi	a2,s0,-64
    80004026:	4581                	li	a1,0
    80004028:	854a                	mv	a0,s2
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	c44080e7          	jalr	-956(ra) # 80003c6e <writei>
    80004032:	872a                	mv	a4,a0
    80004034:	47c1                	li	a5,16
  return 0;
    80004036:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004038:	02f71863          	bne	a4,a5,80004068 <dirlink+0xb2>
}
    8000403c:	70e2                	ld	ra,56(sp)
    8000403e:	7442                	ld	s0,48(sp)
    80004040:	74a2                	ld	s1,40(sp)
    80004042:	7902                	ld	s2,32(sp)
    80004044:	69e2                	ld	s3,24(sp)
    80004046:	6a42                	ld	s4,16(sp)
    80004048:	6121                	addi	sp,sp,64
    8000404a:	8082                	ret
    iput(ip);
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	a30080e7          	jalr	-1488(ra) # 80003a7c <iput>
    return -1;
    80004054:	557d                	li	a0,-1
    80004056:	b7dd                	j	8000403c <dirlink+0x86>
      panic("dirlink read");
    80004058:	00004517          	auipc	a0,0x4
    8000405c:	5f050513          	addi	a0,a0,1520 # 80008648 <syscalls+0x1d8>
    80004060:	ffffc097          	auipc	ra,0xffffc
    80004064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>
    panic("dirlink");
    80004068:	00004517          	auipc	a0,0x4
    8000406c:	6f050513          	addi	a0,a0,1776 # 80008758 <syscalls+0x2e8>
    80004070:	ffffc097          	auipc	ra,0xffffc
    80004074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>

0000000080004078 <namei>:

struct inode*
namei(char *path)
{
    80004078:	1101                	addi	sp,sp,-32
    8000407a:	ec06                	sd	ra,24(sp)
    8000407c:	e822                	sd	s0,16(sp)
    8000407e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004080:	fe040613          	addi	a2,s0,-32
    80004084:	4581                	li	a1,0
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	dd0080e7          	jalr	-560(ra) # 80003e56 <namex>
}
    8000408e:	60e2                	ld	ra,24(sp)
    80004090:	6442                	ld	s0,16(sp)
    80004092:	6105                	addi	sp,sp,32
    80004094:	8082                	ret

0000000080004096 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004096:	1141                	addi	sp,sp,-16
    80004098:	e406                	sd	ra,8(sp)
    8000409a:	e022                	sd	s0,0(sp)
    8000409c:	0800                	addi	s0,sp,16
    8000409e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040a0:	4585                	li	a1,1
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	db4080e7          	jalr	-588(ra) # 80003e56 <namex>
}
    800040aa:	60a2                	ld	ra,8(sp)
    800040ac:	6402                	ld	s0,0(sp)
    800040ae:	0141                	addi	sp,sp,16
    800040b0:	8082                	ret

00000000800040b2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	e426                	sd	s1,8(sp)
    800040ba:	e04a                	sd	s2,0(sp)
    800040bc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040be:	00016917          	auipc	s2,0x16
    800040c2:	12290913          	addi	s2,s2,290 # 8001a1e0 <log>
    800040c6:	01892583          	lw	a1,24(s2)
    800040ca:	02892503          	lw	a0,40(s2)
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	ff2080e7          	jalr	-14(ra) # 800030c0 <bread>
    800040d6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040d8:	02c92683          	lw	a3,44(s2)
    800040dc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040de:	02d05763          	blez	a3,8000410c <write_head+0x5a>
    800040e2:	00016797          	auipc	a5,0x16
    800040e6:	12e78793          	addi	a5,a5,302 # 8001a210 <log+0x30>
    800040ea:	05c50713          	addi	a4,a0,92
    800040ee:	36fd                	addiw	a3,a3,-1
    800040f0:	1682                	slli	a3,a3,0x20
    800040f2:	9281                	srli	a3,a3,0x20
    800040f4:	068a                	slli	a3,a3,0x2
    800040f6:	00016617          	auipc	a2,0x16
    800040fa:	11e60613          	addi	a2,a2,286 # 8001a214 <log+0x34>
    800040fe:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004100:	4390                	lw	a2,0(a5)
    80004102:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004104:	0791                	addi	a5,a5,4
    80004106:	0711                	addi	a4,a4,4
    80004108:	fed79ce3          	bne	a5,a3,80004100 <write_head+0x4e>
  }
  bwrite(buf);
    8000410c:	8526                	mv	a0,s1
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	0a4080e7          	jalr	164(ra) # 800031b2 <bwrite>
  brelse(buf);
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	0d8080e7          	jalr	216(ra) # 800031f0 <brelse>
}
    80004120:	60e2                	ld	ra,24(sp)
    80004122:	6442                	ld	s0,16(sp)
    80004124:	64a2                	ld	s1,8(sp)
    80004126:	6902                	ld	s2,0(sp)
    80004128:	6105                	addi	sp,sp,32
    8000412a:	8082                	ret

000000008000412c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000412c:	00016797          	auipc	a5,0x16
    80004130:	0e07a783          	lw	a5,224(a5) # 8001a20c <log+0x2c>
    80004134:	0af05d63          	blez	a5,800041ee <install_trans+0xc2>
{
    80004138:	7139                	addi	sp,sp,-64
    8000413a:	fc06                	sd	ra,56(sp)
    8000413c:	f822                	sd	s0,48(sp)
    8000413e:	f426                	sd	s1,40(sp)
    80004140:	f04a                	sd	s2,32(sp)
    80004142:	ec4e                	sd	s3,24(sp)
    80004144:	e852                	sd	s4,16(sp)
    80004146:	e456                	sd	s5,8(sp)
    80004148:	e05a                	sd	s6,0(sp)
    8000414a:	0080                	addi	s0,sp,64
    8000414c:	8b2a                	mv	s6,a0
    8000414e:	00016a97          	auipc	s5,0x16
    80004152:	0c2a8a93          	addi	s5,s5,194 # 8001a210 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004156:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004158:	00016997          	auipc	s3,0x16
    8000415c:	08898993          	addi	s3,s3,136 # 8001a1e0 <log>
    80004160:	a035                	j	8000418c <install_trans+0x60>
      bunpin(dbuf);
    80004162:	8526                	mv	a0,s1
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	166080e7          	jalr	358(ra) # 800032ca <bunpin>
    brelse(lbuf);
    8000416c:	854a                	mv	a0,s2
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	082080e7          	jalr	130(ra) # 800031f0 <brelse>
    brelse(dbuf);
    80004176:	8526                	mv	a0,s1
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	078080e7          	jalr	120(ra) # 800031f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004180:	2a05                	addiw	s4,s4,1
    80004182:	0a91                	addi	s5,s5,4
    80004184:	02c9a783          	lw	a5,44(s3)
    80004188:	04fa5963          	bge	s4,a5,800041da <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000418c:	0189a583          	lw	a1,24(s3)
    80004190:	014585bb          	addw	a1,a1,s4
    80004194:	2585                	addiw	a1,a1,1
    80004196:	0289a503          	lw	a0,40(s3)
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	f26080e7          	jalr	-218(ra) # 800030c0 <bread>
    800041a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041a4:	000aa583          	lw	a1,0(s5)
    800041a8:	0289a503          	lw	a0,40(s3)
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	f14080e7          	jalr	-236(ra) # 800030c0 <bread>
    800041b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041b6:	40000613          	li	a2,1024
    800041ba:	05890593          	addi	a1,s2,88
    800041be:	05850513          	addi	a0,a0,88
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	b7e080e7          	jalr	-1154(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	fe6080e7          	jalr	-26(ra) # 800031b2 <bwrite>
    if(recovering == 0)
    800041d4:	f80b1ce3          	bnez	s6,8000416c <install_trans+0x40>
    800041d8:	b769                	j	80004162 <install_trans+0x36>
}
    800041da:	70e2                	ld	ra,56(sp)
    800041dc:	7442                	ld	s0,48(sp)
    800041de:	74a2                	ld	s1,40(sp)
    800041e0:	7902                	ld	s2,32(sp)
    800041e2:	69e2                	ld	s3,24(sp)
    800041e4:	6a42                	ld	s4,16(sp)
    800041e6:	6aa2                	ld	s5,8(sp)
    800041e8:	6b02                	ld	s6,0(sp)
    800041ea:	6121                	addi	sp,sp,64
    800041ec:	8082                	ret
    800041ee:	8082                	ret

00000000800041f0 <initlog>:
{
    800041f0:	7179                	addi	sp,sp,-48
    800041f2:	f406                	sd	ra,40(sp)
    800041f4:	f022                	sd	s0,32(sp)
    800041f6:	ec26                	sd	s1,24(sp)
    800041f8:	e84a                	sd	s2,16(sp)
    800041fa:	e44e                	sd	s3,8(sp)
    800041fc:	1800                	addi	s0,sp,48
    800041fe:	892a                	mv	s2,a0
    80004200:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004202:	00016497          	auipc	s1,0x16
    80004206:	fde48493          	addi	s1,s1,-34 # 8001a1e0 <log>
    8000420a:	00004597          	auipc	a1,0x4
    8000420e:	44e58593          	addi	a1,a1,1102 # 80008658 <syscalls+0x1e8>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	940080e7          	jalr	-1728(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000421c:	0149a583          	lw	a1,20(s3)
    80004220:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004222:	0109a783          	lw	a5,16(s3)
    80004226:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004228:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000422c:	854a                	mv	a0,s2
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	e92080e7          	jalr	-366(ra) # 800030c0 <bread>
  log.lh.n = lh->n;
    80004236:	4d3c                	lw	a5,88(a0)
    80004238:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000423a:	02f05563          	blez	a5,80004264 <initlog+0x74>
    8000423e:	05c50713          	addi	a4,a0,92
    80004242:	00016697          	auipc	a3,0x16
    80004246:	fce68693          	addi	a3,a3,-50 # 8001a210 <log+0x30>
    8000424a:	37fd                	addiw	a5,a5,-1
    8000424c:	1782                	slli	a5,a5,0x20
    8000424e:	9381                	srli	a5,a5,0x20
    80004250:	078a                	slli	a5,a5,0x2
    80004252:	06050613          	addi	a2,a0,96
    80004256:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004258:	4310                	lw	a2,0(a4)
    8000425a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000425c:	0711                	addi	a4,a4,4
    8000425e:	0691                	addi	a3,a3,4
    80004260:	fef71ce3          	bne	a4,a5,80004258 <initlog+0x68>
  brelse(buf);
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	f8c080e7          	jalr	-116(ra) # 800031f0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000426c:	4505                	li	a0,1
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	ebe080e7          	jalr	-322(ra) # 8000412c <install_trans>
  log.lh.n = 0;
    80004276:	00016797          	auipc	a5,0x16
    8000427a:	f807ab23          	sw	zero,-106(a5) # 8001a20c <log+0x2c>
  write_head(); // clear the log
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	e34080e7          	jalr	-460(ra) # 800040b2 <write_head>
}
    80004286:	70a2                	ld	ra,40(sp)
    80004288:	7402                	ld	s0,32(sp)
    8000428a:	64e2                	ld	s1,24(sp)
    8000428c:	6942                	ld	s2,16(sp)
    8000428e:	69a2                	ld	s3,8(sp)
    80004290:	6145                	addi	sp,sp,48
    80004292:	8082                	ret

0000000080004294 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004294:	1101                	addi	sp,sp,-32
    80004296:	ec06                	sd	ra,24(sp)
    80004298:	e822                	sd	s0,16(sp)
    8000429a:	e426                	sd	s1,8(sp)
    8000429c:	e04a                	sd	s2,0(sp)
    8000429e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042a0:	00016517          	auipc	a0,0x16
    800042a4:	f4050513          	addi	a0,a0,-192 # 8001a1e0 <log>
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	93c080e7          	jalr	-1732(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042b0:	00016497          	auipc	s1,0x16
    800042b4:	f3048493          	addi	s1,s1,-208 # 8001a1e0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042b8:	4979                	li	s2,30
    800042ba:	a039                	j	800042c8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042bc:	85a6                	mv	a1,s1
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffe097          	auipc	ra,0xffffe
    800042c4:	f74080e7          	jalr	-140(ra) # 80002234 <sleep>
    if(log.committing){
    800042c8:	50dc                	lw	a5,36(s1)
    800042ca:	fbed                	bnez	a5,800042bc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042cc:	509c                	lw	a5,32(s1)
    800042ce:	0017871b          	addiw	a4,a5,1
    800042d2:	0007069b          	sext.w	a3,a4
    800042d6:	0027179b          	slliw	a5,a4,0x2
    800042da:	9fb9                	addw	a5,a5,a4
    800042dc:	0017979b          	slliw	a5,a5,0x1
    800042e0:	54d8                	lw	a4,44(s1)
    800042e2:	9fb9                	addw	a5,a5,a4
    800042e4:	00f95963          	bge	s2,a5,800042f6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042e8:	85a6                	mv	a1,s1
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffe097          	auipc	ra,0xffffe
    800042f0:	f48080e7          	jalr	-184(ra) # 80002234 <sleep>
    800042f4:	bfd1                	j	800042c8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042f6:	00016517          	auipc	a0,0x16
    800042fa:	eea50513          	addi	a0,a0,-278 # 8001a1e0 <log>
    800042fe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	998080e7          	jalr	-1640(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004308:	60e2                	ld	ra,24(sp)
    8000430a:	6442                	ld	s0,16(sp)
    8000430c:	64a2                	ld	s1,8(sp)
    8000430e:	6902                	ld	s2,0(sp)
    80004310:	6105                	addi	sp,sp,32
    80004312:	8082                	ret

0000000080004314 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004314:	7139                	addi	sp,sp,-64
    80004316:	fc06                	sd	ra,56(sp)
    80004318:	f822                	sd	s0,48(sp)
    8000431a:	f426                	sd	s1,40(sp)
    8000431c:	f04a                	sd	s2,32(sp)
    8000431e:	ec4e                	sd	s3,24(sp)
    80004320:	e852                	sd	s4,16(sp)
    80004322:	e456                	sd	s5,8(sp)
    80004324:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004326:	00016497          	auipc	s1,0x16
    8000432a:	eba48493          	addi	s1,s1,-326 # 8001a1e0 <log>
    8000432e:	8526                	mv	a0,s1
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004338:	509c                	lw	a5,32(s1)
    8000433a:	37fd                	addiw	a5,a5,-1
    8000433c:	0007891b          	sext.w	s2,a5
    80004340:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004342:	50dc                	lw	a5,36(s1)
    80004344:	efb9                	bnez	a5,800043a2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004346:	06091663          	bnez	s2,800043b2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000434a:	00016497          	auipc	s1,0x16
    8000434e:	e9648493          	addi	s1,s1,-362 # 8001a1e0 <log>
    80004352:	4785                	li	a5,1
    80004354:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004356:	8526                	mv	a0,s1
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	940080e7          	jalr	-1728(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004360:	54dc                	lw	a5,44(s1)
    80004362:	06f04763          	bgtz	a5,800043d0 <end_op+0xbc>
    acquire(&log.lock);
    80004366:	00016497          	auipc	s1,0x16
    8000436a:	e7a48493          	addi	s1,s1,-390 # 8001a1e0 <log>
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004378:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	042080e7          	jalr	66(ra) # 800023c0 <wakeup>
    release(&log.lock);
    80004386:	8526                	mv	a0,s1
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
}
    80004390:	70e2                	ld	ra,56(sp)
    80004392:	7442                	ld	s0,48(sp)
    80004394:	74a2                	ld	s1,40(sp)
    80004396:	7902                	ld	s2,32(sp)
    80004398:	69e2                	ld	s3,24(sp)
    8000439a:	6a42                	ld	s4,16(sp)
    8000439c:	6aa2                	ld	s5,8(sp)
    8000439e:	6121                	addi	sp,sp,64
    800043a0:	8082                	ret
    panic("log.committing");
    800043a2:	00004517          	auipc	a0,0x4
    800043a6:	2be50513          	addi	a0,a0,702 # 80008660 <syscalls+0x1f0>
    800043aa:	ffffc097          	auipc	ra,0xffffc
    800043ae:	194080e7          	jalr	404(ra) # 8000053e <panic>
    wakeup(&log);
    800043b2:	00016497          	auipc	s1,0x16
    800043b6:	e2e48493          	addi	s1,s1,-466 # 8001a1e0 <log>
    800043ba:	8526                	mv	a0,s1
    800043bc:	ffffe097          	auipc	ra,0xffffe
    800043c0:	004080e7          	jalr	4(ra) # 800023c0 <wakeup>
  release(&log.lock);
    800043c4:	8526                	mv	a0,s1
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
  if(do_commit){
    800043ce:	b7c9                	j	80004390 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	00016a97          	auipc	s5,0x16
    800043d4:	e40a8a93          	addi	s5,s5,-448 # 8001a210 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043d8:	00016a17          	auipc	s4,0x16
    800043dc:	e08a0a13          	addi	s4,s4,-504 # 8001a1e0 <log>
    800043e0:	018a2583          	lw	a1,24(s4)
    800043e4:	012585bb          	addw	a1,a1,s2
    800043e8:	2585                	addiw	a1,a1,1
    800043ea:	028a2503          	lw	a0,40(s4)
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	cd2080e7          	jalr	-814(ra) # 800030c0 <bread>
    800043f6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043f8:	000aa583          	lw	a1,0(s5)
    800043fc:	028a2503          	lw	a0,40(s4)
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	cc0080e7          	jalr	-832(ra) # 800030c0 <bread>
    80004408:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000440a:	40000613          	li	a2,1024
    8000440e:	05850593          	addi	a1,a0,88
    80004412:	05848513          	addi	a0,s1,88
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	92a080e7          	jalr	-1750(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000441e:	8526                	mv	a0,s1
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	d92080e7          	jalr	-622(ra) # 800031b2 <bwrite>
    brelse(from);
    80004428:	854e                	mv	a0,s3
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	dc6080e7          	jalr	-570(ra) # 800031f0 <brelse>
    brelse(to);
    80004432:	8526                	mv	a0,s1
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	dbc080e7          	jalr	-580(ra) # 800031f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443c:	2905                	addiw	s2,s2,1
    8000443e:	0a91                	addi	s5,s5,4
    80004440:	02ca2783          	lw	a5,44(s4)
    80004444:	f8f94ee3          	blt	s2,a5,800043e0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	c6a080e7          	jalr	-918(ra) # 800040b2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004450:	4501                	li	a0,0
    80004452:	00000097          	auipc	ra,0x0
    80004456:	cda080e7          	jalr	-806(ra) # 8000412c <install_trans>
    log.lh.n = 0;
    8000445a:	00016797          	auipc	a5,0x16
    8000445e:	da07a923          	sw	zero,-590(a5) # 8001a20c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004462:	00000097          	auipc	ra,0x0
    80004466:	c50080e7          	jalr	-944(ra) # 800040b2 <write_head>
    8000446a:	bdf5                	j	80004366 <end_op+0x52>

000000008000446c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000446c:	1101                	addi	sp,sp,-32
    8000446e:	ec06                	sd	ra,24(sp)
    80004470:	e822                	sd	s0,16(sp)
    80004472:	e426                	sd	s1,8(sp)
    80004474:	e04a                	sd	s2,0(sp)
    80004476:	1000                	addi	s0,sp,32
    80004478:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000447a:	00016917          	auipc	s2,0x16
    8000447e:	d6690913          	addi	s2,s2,-666 # 8001a1e0 <log>
    80004482:	854a                	mv	a0,s2
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	760080e7          	jalr	1888(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000448c:	02c92603          	lw	a2,44(s2)
    80004490:	47f5                	li	a5,29
    80004492:	06c7c563          	blt	a5,a2,800044fc <log_write+0x90>
    80004496:	00016797          	auipc	a5,0x16
    8000449a:	d667a783          	lw	a5,-666(a5) # 8001a1fc <log+0x1c>
    8000449e:	37fd                	addiw	a5,a5,-1
    800044a0:	04f65e63          	bge	a2,a5,800044fc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044a4:	00016797          	auipc	a5,0x16
    800044a8:	d5c7a783          	lw	a5,-676(a5) # 8001a200 <log+0x20>
    800044ac:	06f05063          	blez	a5,8000450c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044b0:	4781                	li	a5,0
    800044b2:	06c05563          	blez	a2,8000451c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044b6:	44cc                	lw	a1,12(s1)
    800044b8:	00016717          	auipc	a4,0x16
    800044bc:	d5870713          	addi	a4,a4,-680 # 8001a210 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044c0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c2:	4314                	lw	a3,0(a4)
    800044c4:	04b68c63          	beq	a3,a1,8000451c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044c8:	2785                	addiw	a5,a5,1
    800044ca:	0711                	addi	a4,a4,4
    800044cc:	fef61be3          	bne	a2,a5,800044c2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044d0:	0621                	addi	a2,a2,8
    800044d2:	060a                	slli	a2,a2,0x2
    800044d4:	00016797          	auipc	a5,0x16
    800044d8:	d0c78793          	addi	a5,a5,-756 # 8001a1e0 <log>
    800044dc:	963e                	add	a2,a2,a5
    800044de:	44dc                	lw	a5,12(s1)
    800044e0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	daa080e7          	jalr	-598(ra) # 8000328e <bpin>
    log.lh.n++;
    800044ec:	00016717          	auipc	a4,0x16
    800044f0:	cf470713          	addi	a4,a4,-780 # 8001a1e0 <log>
    800044f4:	575c                	lw	a5,44(a4)
    800044f6:	2785                	addiw	a5,a5,1
    800044f8:	d75c                	sw	a5,44(a4)
    800044fa:	a835                	j	80004536 <log_write+0xca>
    panic("too big a transaction");
    800044fc:	00004517          	auipc	a0,0x4
    80004500:	17450513          	addi	a0,a0,372 # 80008670 <syscalls+0x200>
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	03a080e7          	jalr	58(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000450c:	00004517          	auipc	a0,0x4
    80004510:	17c50513          	addi	a0,a0,380 # 80008688 <syscalls+0x218>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000451c:	00878713          	addi	a4,a5,8
    80004520:	00271693          	slli	a3,a4,0x2
    80004524:	00016717          	auipc	a4,0x16
    80004528:	cbc70713          	addi	a4,a4,-836 # 8001a1e0 <log>
    8000452c:	9736                	add	a4,a4,a3
    8000452e:	44d4                	lw	a3,12(s1)
    80004530:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004532:	faf608e3          	beq	a2,a5,800044e2 <log_write+0x76>
  }
  release(&log.lock);
    80004536:	00016517          	auipc	a0,0x16
    8000453a:	caa50513          	addi	a0,a0,-854 # 8001a1e0 <log>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	75a080e7          	jalr	1882(ra) # 80000c98 <release>
}
    80004546:	60e2                	ld	ra,24(sp)
    80004548:	6442                	ld	s0,16(sp)
    8000454a:	64a2                	ld	s1,8(sp)
    8000454c:	6902                	ld	s2,0(sp)
    8000454e:	6105                	addi	sp,sp,32
    80004550:	8082                	ret

0000000080004552 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004552:	1101                	addi	sp,sp,-32
    80004554:	ec06                	sd	ra,24(sp)
    80004556:	e822                	sd	s0,16(sp)
    80004558:	e426                	sd	s1,8(sp)
    8000455a:	e04a                	sd	s2,0(sp)
    8000455c:	1000                	addi	s0,sp,32
    8000455e:	84aa                	mv	s1,a0
    80004560:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004562:	00004597          	auipc	a1,0x4
    80004566:	14658593          	addi	a1,a1,326 # 800086a8 <syscalls+0x238>
    8000456a:	0521                	addi	a0,a0,8
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	5e8080e7          	jalr	1512(ra) # 80000b54 <initlock>
  lk->name = name;
    80004574:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004578:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000457c:	0204a423          	sw	zero,40(s1)
}
    80004580:	60e2                	ld	ra,24(sp)
    80004582:	6442                	ld	s0,16(sp)
    80004584:	64a2                	ld	s1,8(sp)
    80004586:	6902                	ld	s2,0(sp)
    80004588:	6105                	addi	sp,sp,32
    8000458a:	8082                	ret

000000008000458c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000458c:	1101                	addi	sp,sp,-32
    8000458e:	ec06                	sd	ra,24(sp)
    80004590:	e822                	sd	s0,16(sp)
    80004592:	e426                	sd	s1,8(sp)
    80004594:	e04a                	sd	s2,0(sp)
    80004596:	1000                	addi	s0,sp,32
    80004598:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000459a:	00850913          	addi	s2,a0,8
    8000459e:	854a                	mv	a0,s2
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045a8:	409c                	lw	a5,0(s1)
    800045aa:	cb89                	beqz	a5,800045bc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ac:	85ca                	mv	a1,s2
    800045ae:	8526                	mv	a0,s1
    800045b0:	ffffe097          	auipc	ra,0xffffe
    800045b4:	c84080e7          	jalr	-892(ra) # 80002234 <sleep>
  while (lk->locked) {
    800045b8:	409c                	lw	a5,0(s1)
    800045ba:	fbed                	bnez	a5,800045ac <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045bc:	4785                	li	a5,1
    800045be:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045c0:	ffffd097          	auipc	ra,0xffffd
    800045c4:	3f8080e7          	jalr	1016(ra) # 800019b8 <myproc>
    800045c8:	591c                	lw	a5,48(a0)
    800045ca:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045cc:	854a                	mv	a0,s2
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	6ca080e7          	jalr	1738(ra) # 80000c98 <release>
}
    800045d6:	60e2                	ld	ra,24(sp)
    800045d8:	6442                	ld	s0,16(sp)
    800045da:	64a2                	ld	s1,8(sp)
    800045dc:	6902                	ld	s2,0(sp)
    800045de:	6105                	addi	sp,sp,32
    800045e0:	8082                	ret

00000000800045e2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045e2:	1101                	addi	sp,sp,-32
    800045e4:	ec06                	sd	ra,24(sp)
    800045e6:	e822                	sd	s0,16(sp)
    800045e8:	e426                	sd	s1,8(sp)
    800045ea:	e04a                	sd	s2,0(sp)
    800045ec:	1000                	addi	s0,sp,32
    800045ee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045f0:	00850913          	addi	s2,a0,8
    800045f4:	854a                	mv	a0,s2
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	5ee080e7          	jalr	1518(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045fe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004602:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004606:	8526                	mv	a0,s1
    80004608:	ffffe097          	auipc	ra,0xffffe
    8000460c:	db8080e7          	jalr	-584(ra) # 800023c0 <wakeup>
  release(&lk->lk);
    80004610:	854a                	mv	a0,s2
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	686080e7          	jalr	1670(ra) # 80000c98 <release>
}
    8000461a:	60e2                	ld	ra,24(sp)
    8000461c:	6442                	ld	s0,16(sp)
    8000461e:	64a2                	ld	s1,8(sp)
    80004620:	6902                	ld	s2,0(sp)
    80004622:	6105                	addi	sp,sp,32
    80004624:	8082                	ret

0000000080004626 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004626:	7179                	addi	sp,sp,-48
    80004628:	f406                	sd	ra,40(sp)
    8000462a:	f022                	sd	s0,32(sp)
    8000462c:	ec26                	sd	s1,24(sp)
    8000462e:	e84a                	sd	s2,16(sp)
    80004630:	e44e                	sd	s3,8(sp)
    80004632:	1800                	addi	s0,sp,48
    80004634:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004636:	00850913          	addi	s2,a0,8
    8000463a:	854a                	mv	a0,s2
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	5a8080e7          	jalr	1448(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004644:	409c                	lw	a5,0(s1)
    80004646:	ef99                	bnez	a5,80004664 <holdingsleep+0x3e>
    80004648:	4481                	li	s1,0
  release(&lk->lk);
    8000464a:	854a                	mv	a0,s2
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	64c080e7          	jalr	1612(ra) # 80000c98 <release>
  return r;
}
    80004654:	8526                	mv	a0,s1
    80004656:	70a2                	ld	ra,40(sp)
    80004658:	7402                	ld	s0,32(sp)
    8000465a:	64e2                	ld	s1,24(sp)
    8000465c:	6942                	ld	s2,16(sp)
    8000465e:	69a2                	ld	s3,8(sp)
    80004660:	6145                	addi	sp,sp,48
    80004662:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004664:	0284a983          	lw	s3,40(s1)
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	350080e7          	jalr	848(ra) # 800019b8 <myproc>
    80004670:	5904                	lw	s1,48(a0)
    80004672:	413484b3          	sub	s1,s1,s3
    80004676:	0014b493          	seqz	s1,s1
    8000467a:	bfc1                	j	8000464a <holdingsleep+0x24>

000000008000467c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000467c:	1141                	addi	sp,sp,-16
    8000467e:	e406                	sd	ra,8(sp)
    80004680:	e022                	sd	s0,0(sp)
    80004682:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004684:	00004597          	auipc	a1,0x4
    80004688:	03458593          	addi	a1,a1,52 # 800086b8 <syscalls+0x248>
    8000468c:	00016517          	auipc	a0,0x16
    80004690:	c9c50513          	addi	a0,a0,-868 # 8001a328 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	4c0080e7          	jalr	1216(ra) # 80000b54 <initlock>
}
    8000469c:	60a2                	ld	ra,8(sp)
    8000469e:	6402                	ld	s0,0(sp)
    800046a0:	0141                	addi	sp,sp,16
    800046a2:	8082                	ret

00000000800046a4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046a4:	1101                	addi	sp,sp,-32
    800046a6:	ec06                	sd	ra,24(sp)
    800046a8:	e822                	sd	s0,16(sp)
    800046aa:	e426                	sd	s1,8(sp)
    800046ac:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046ae:	00016517          	auipc	a0,0x16
    800046b2:	c7a50513          	addi	a0,a0,-902 # 8001a328 <ftable>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	52e080e7          	jalr	1326(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046be:	00016497          	auipc	s1,0x16
    800046c2:	c8248493          	addi	s1,s1,-894 # 8001a340 <ftable+0x18>
    800046c6:	00017717          	auipc	a4,0x17
    800046ca:	c1a70713          	addi	a4,a4,-998 # 8001b2e0 <ftable+0xfb8>
    if(f->ref == 0){
    800046ce:	40dc                	lw	a5,4(s1)
    800046d0:	cf99                	beqz	a5,800046ee <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d2:	02848493          	addi	s1,s1,40
    800046d6:	fee49ce3          	bne	s1,a4,800046ce <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046da:	00016517          	auipc	a0,0x16
    800046de:	c4e50513          	addi	a0,a0,-946 # 8001a328 <ftable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	5b6080e7          	jalr	1462(ra) # 80000c98 <release>
  return 0;
    800046ea:	4481                	li	s1,0
    800046ec:	a819                	j	80004702 <filealloc+0x5e>
      f->ref = 1;
    800046ee:	4785                	li	a5,1
    800046f0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046f2:	00016517          	auipc	a0,0x16
    800046f6:	c3650513          	addi	a0,a0,-970 # 8001a328 <ftable>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	59e080e7          	jalr	1438(ra) # 80000c98 <release>
}
    80004702:	8526                	mv	a0,s1
    80004704:	60e2                	ld	ra,24(sp)
    80004706:	6442                	ld	s0,16(sp)
    80004708:	64a2                	ld	s1,8(sp)
    8000470a:	6105                	addi	sp,sp,32
    8000470c:	8082                	ret

000000008000470e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000470e:	1101                	addi	sp,sp,-32
    80004710:	ec06                	sd	ra,24(sp)
    80004712:	e822                	sd	s0,16(sp)
    80004714:	e426                	sd	s1,8(sp)
    80004716:	1000                	addi	s0,sp,32
    80004718:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000471a:	00016517          	auipc	a0,0x16
    8000471e:	c0e50513          	addi	a0,a0,-1010 # 8001a328 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	4c2080e7          	jalr	1218(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000472a:	40dc                	lw	a5,4(s1)
    8000472c:	02f05263          	blez	a5,80004750 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004730:	2785                	addiw	a5,a5,1
    80004732:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004734:	00016517          	auipc	a0,0x16
    80004738:	bf450513          	addi	a0,a0,-1036 # 8001a328 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
  return f;
}
    80004744:	8526                	mv	a0,s1
    80004746:	60e2                	ld	ra,24(sp)
    80004748:	6442                	ld	s0,16(sp)
    8000474a:	64a2                	ld	s1,8(sp)
    8000474c:	6105                	addi	sp,sp,32
    8000474e:	8082                	ret
    panic("filedup");
    80004750:	00004517          	auipc	a0,0x4
    80004754:	f7050513          	addi	a0,a0,-144 # 800086c0 <syscalls+0x250>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	de6080e7          	jalr	-538(ra) # 8000053e <panic>

0000000080004760 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004760:	7139                	addi	sp,sp,-64
    80004762:	fc06                	sd	ra,56(sp)
    80004764:	f822                	sd	s0,48(sp)
    80004766:	f426                	sd	s1,40(sp)
    80004768:	f04a                	sd	s2,32(sp)
    8000476a:	ec4e                	sd	s3,24(sp)
    8000476c:	e852                	sd	s4,16(sp)
    8000476e:	e456                	sd	s5,8(sp)
    80004770:	0080                	addi	s0,sp,64
    80004772:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004774:	00016517          	auipc	a0,0x16
    80004778:	bb450513          	addi	a0,a0,-1100 # 8001a328 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	468080e7          	jalr	1128(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004784:	40dc                	lw	a5,4(s1)
    80004786:	06f05163          	blez	a5,800047e8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000478a:	37fd                	addiw	a5,a5,-1
    8000478c:	0007871b          	sext.w	a4,a5
    80004790:	c0dc                	sw	a5,4(s1)
    80004792:	06e04363          	bgtz	a4,800047f8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004796:	0004a903          	lw	s2,0(s1)
    8000479a:	0094ca83          	lbu	s5,9(s1)
    8000479e:	0104ba03          	ld	s4,16(s1)
    800047a2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047a6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047aa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047ae:	00016517          	auipc	a0,0x16
    800047b2:	b7a50513          	addi	a0,a0,-1158 # 8001a328 <ftable>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4e2080e7          	jalr	1250(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047be:	4785                	li	a5,1
    800047c0:	04f90d63          	beq	s2,a5,8000481a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047c4:	3979                	addiw	s2,s2,-2
    800047c6:	4785                	li	a5,1
    800047c8:	0527e063          	bltu	a5,s2,80004808 <fileclose+0xa8>
    begin_op();
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	ac8080e7          	jalr	-1336(ra) # 80004294 <begin_op>
    iput(ff.ip);
    800047d4:	854e                	mv	a0,s3
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	2a6080e7          	jalr	678(ra) # 80003a7c <iput>
    end_op();
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	b36080e7          	jalr	-1226(ra) # 80004314 <end_op>
    800047e6:	a00d                	j	80004808 <fileclose+0xa8>
    panic("fileclose");
    800047e8:	00004517          	auipc	a0,0x4
    800047ec:	ee050513          	addi	a0,a0,-288 # 800086c8 <syscalls+0x258>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	d4e080e7          	jalr	-690(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047f8:	00016517          	auipc	a0,0x16
    800047fc:	b3050513          	addi	a0,a0,-1232 # 8001a328 <ftable>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	498080e7          	jalr	1176(ra) # 80000c98 <release>
  }
}
    80004808:	70e2                	ld	ra,56(sp)
    8000480a:	7442                	ld	s0,48(sp)
    8000480c:	74a2                	ld	s1,40(sp)
    8000480e:	7902                	ld	s2,32(sp)
    80004810:	69e2                	ld	s3,24(sp)
    80004812:	6a42                	ld	s4,16(sp)
    80004814:	6aa2                	ld	s5,8(sp)
    80004816:	6121                	addi	sp,sp,64
    80004818:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000481a:	85d6                	mv	a1,s5
    8000481c:	8552                	mv	a0,s4
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	34c080e7          	jalr	844(ra) # 80004b6a <pipeclose>
    80004826:	b7cd                	j	80004808 <fileclose+0xa8>

0000000080004828 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004828:	715d                	addi	sp,sp,-80
    8000482a:	e486                	sd	ra,72(sp)
    8000482c:	e0a2                	sd	s0,64(sp)
    8000482e:	fc26                	sd	s1,56(sp)
    80004830:	f84a                	sd	s2,48(sp)
    80004832:	f44e                	sd	s3,40(sp)
    80004834:	0880                	addi	s0,sp,80
    80004836:	84aa                	mv	s1,a0
    80004838:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000483a:	ffffd097          	auipc	ra,0xffffd
    8000483e:	17e080e7          	jalr	382(ra) # 800019b8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004842:	409c                	lw	a5,0(s1)
    80004844:	37f9                	addiw	a5,a5,-2
    80004846:	4705                	li	a4,1
    80004848:	04f76763          	bltu	a4,a5,80004896 <filestat+0x6e>
    8000484c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000484e:	6c88                	ld	a0,24(s1)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	072080e7          	jalr	114(ra) # 800038c2 <ilock>
    stati(f->ip, &st);
    80004858:	fb840593          	addi	a1,s0,-72
    8000485c:	6c88                	ld	a0,24(s1)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	2ee080e7          	jalr	750(ra) # 80003b4c <stati>
    iunlock(f->ip);
    80004866:	6c88                	ld	a0,24(s1)
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	11c080e7          	jalr	284(ra) # 80003984 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004870:	46e1                	li	a3,24
    80004872:	fb840613          	addi	a2,s0,-72
    80004876:	85ce                	mv	a1,s3
    80004878:	05093503          	ld	a0,80(s2)
    8000487c:	ffffd097          	auipc	ra,0xffffd
    80004880:	dfe080e7          	jalr	-514(ra) # 8000167a <copyout>
    80004884:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004888:	60a6                	ld	ra,72(sp)
    8000488a:	6406                	ld	s0,64(sp)
    8000488c:	74e2                	ld	s1,56(sp)
    8000488e:	7942                	ld	s2,48(sp)
    80004890:	79a2                	ld	s3,40(sp)
    80004892:	6161                	addi	sp,sp,80
    80004894:	8082                	ret
  return -1;
    80004896:	557d                	li	a0,-1
    80004898:	bfc5                	j	80004888 <filestat+0x60>

000000008000489a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000489a:	7179                	addi	sp,sp,-48
    8000489c:	f406                	sd	ra,40(sp)
    8000489e:	f022                	sd	s0,32(sp)
    800048a0:	ec26                	sd	s1,24(sp)
    800048a2:	e84a                	sd	s2,16(sp)
    800048a4:	e44e                	sd	s3,8(sp)
    800048a6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048a8:	00854783          	lbu	a5,8(a0)
    800048ac:	c3d5                	beqz	a5,80004950 <fileread+0xb6>
    800048ae:	84aa                	mv	s1,a0
    800048b0:	89ae                	mv	s3,a1
    800048b2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048b4:	411c                	lw	a5,0(a0)
    800048b6:	4705                	li	a4,1
    800048b8:	04e78963          	beq	a5,a4,8000490a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048bc:	470d                	li	a4,3
    800048be:	04e78d63          	beq	a5,a4,80004918 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048c2:	4709                	li	a4,2
    800048c4:	06e79e63          	bne	a5,a4,80004940 <fileread+0xa6>
    ilock(f->ip);
    800048c8:	6d08                	ld	a0,24(a0)
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	ff8080e7          	jalr	-8(ra) # 800038c2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048d2:	874a                	mv	a4,s2
    800048d4:	5094                	lw	a3,32(s1)
    800048d6:	864e                	mv	a2,s3
    800048d8:	4585                	li	a1,1
    800048da:	6c88                	ld	a0,24(s1)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	29a080e7          	jalr	666(ra) # 80003b76 <readi>
    800048e4:	892a                	mv	s2,a0
    800048e6:	00a05563          	blez	a0,800048f0 <fileread+0x56>
      f->off += r;
    800048ea:	509c                	lw	a5,32(s1)
    800048ec:	9fa9                	addw	a5,a5,a0
    800048ee:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048f0:	6c88                	ld	a0,24(s1)
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	092080e7          	jalr	146(ra) # 80003984 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048fa:	854a                	mv	a0,s2
    800048fc:	70a2                	ld	ra,40(sp)
    800048fe:	7402                	ld	s0,32(sp)
    80004900:	64e2                	ld	s1,24(sp)
    80004902:	6942                	ld	s2,16(sp)
    80004904:	69a2                	ld	s3,8(sp)
    80004906:	6145                	addi	sp,sp,48
    80004908:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000490a:	6908                	ld	a0,16(a0)
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	3c8080e7          	jalr	968(ra) # 80004cd4 <piperead>
    80004914:	892a                	mv	s2,a0
    80004916:	b7d5                	j	800048fa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004918:	02451783          	lh	a5,36(a0)
    8000491c:	03079693          	slli	a3,a5,0x30
    80004920:	92c1                	srli	a3,a3,0x30
    80004922:	4725                	li	a4,9
    80004924:	02d76863          	bltu	a4,a3,80004954 <fileread+0xba>
    80004928:	0792                	slli	a5,a5,0x4
    8000492a:	00016717          	auipc	a4,0x16
    8000492e:	95e70713          	addi	a4,a4,-1698 # 8001a288 <devsw>
    80004932:	97ba                	add	a5,a5,a4
    80004934:	639c                	ld	a5,0(a5)
    80004936:	c38d                	beqz	a5,80004958 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004938:	4505                	li	a0,1
    8000493a:	9782                	jalr	a5
    8000493c:	892a                	mv	s2,a0
    8000493e:	bf75                	j	800048fa <fileread+0x60>
    panic("fileread");
    80004940:	00004517          	auipc	a0,0x4
    80004944:	d9850513          	addi	a0,a0,-616 # 800086d8 <syscalls+0x268>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>
    return -1;
    80004950:	597d                	li	s2,-1
    80004952:	b765                	j	800048fa <fileread+0x60>
      return -1;
    80004954:	597d                	li	s2,-1
    80004956:	b755                	j	800048fa <fileread+0x60>
    80004958:	597d                	li	s2,-1
    8000495a:	b745                	j	800048fa <fileread+0x60>

000000008000495c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000495c:	715d                	addi	sp,sp,-80
    8000495e:	e486                	sd	ra,72(sp)
    80004960:	e0a2                	sd	s0,64(sp)
    80004962:	fc26                	sd	s1,56(sp)
    80004964:	f84a                	sd	s2,48(sp)
    80004966:	f44e                	sd	s3,40(sp)
    80004968:	f052                	sd	s4,32(sp)
    8000496a:	ec56                	sd	s5,24(sp)
    8000496c:	e85a                	sd	s6,16(sp)
    8000496e:	e45e                	sd	s7,8(sp)
    80004970:	e062                	sd	s8,0(sp)
    80004972:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004974:	00954783          	lbu	a5,9(a0)
    80004978:	10078663          	beqz	a5,80004a84 <filewrite+0x128>
    8000497c:	892a                	mv	s2,a0
    8000497e:	8aae                	mv	s5,a1
    80004980:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004982:	411c                	lw	a5,0(a0)
    80004984:	4705                	li	a4,1
    80004986:	02e78263          	beq	a5,a4,800049aa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000498a:	470d                	li	a4,3
    8000498c:	02e78663          	beq	a5,a4,800049b8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004990:	4709                	li	a4,2
    80004992:	0ee79163          	bne	a5,a4,80004a74 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004996:	0ac05d63          	blez	a2,80004a50 <filewrite+0xf4>
    int i = 0;
    8000499a:	4981                	li	s3,0
    8000499c:	6b05                	lui	s6,0x1
    8000499e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049a2:	6b85                	lui	s7,0x1
    800049a4:	c00b8b9b          	addiw	s7,s7,-1024
    800049a8:	a861                	j	80004a40 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049aa:	6908                	ld	a0,16(a0)
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	22e080e7          	jalr	558(ra) # 80004bda <pipewrite>
    800049b4:	8a2a                	mv	s4,a0
    800049b6:	a045                	j	80004a56 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049b8:	02451783          	lh	a5,36(a0)
    800049bc:	03079693          	slli	a3,a5,0x30
    800049c0:	92c1                	srli	a3,a3,0x30
    800049c2:	4725                	li	a4,9
    800049c4:	0cd76263          	bltu	a4,a3,80004a88 <filewrite+0x12c>
    800049c8:	0792                	slli	a5,a5,0x4
    800049ca:	00016717          	auipc	a4,0x16
    800049ce:	8be70713          	addi	a4,a4,-1858 # 8001a288 <devsw>
    800049d2:	97ba                	add	a5,a5,a4
    800049d4:	679c                	ld	a5,8(a5)
    800049d6:	cbdd                	beqz	a5,80004a8c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049d8:	4505                	li	a0,1
    800049da:	9782                	jalr	a5
    800049dc:	8a2a                	mv	s4,a0
    800049de:	a8a5                	j	80004a56 <filewrite+0xfa>
    800049e0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	8b0080e7          	jalr	-1872(ra) # 80004294 <begin_op>
      ilock(f->ip);
    800049ec:	01893503          	ld	a0,24(s2)
    800049f0:	fffff097          	auipc	ra,0xfffff
    800049f4:	ed2080e7          	jalr	-302(ra) # 800038c2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049f8:	8762                	mv	a4,s8
    800049fa:	02092683          	lw	a3,32(s2)
    800049fe:	01598633          	add	a2,s3,s5
    80004a02:	4585                	li	a1,1
    80004a04:	01893503          	ld	a0,24(s2)
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	266080e7          	jalr	614(ra) # 80003c6e <writei>
    80004a10:	84aa                	mv	s1,a0
    80004a12:	00a05763          	blez	a0,80004a20 <filewrite+0xc4>
        f->off += r;
    80004a16:	02092783          	lw	a5,32(s2)
    80004a1a:	9fa9                	addw	a5,a5,a0
    80004a1c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a20:	01893503          	ld	a0,24(s2)
    80004a24:	fffff097          	auipc	ra,0xfffff
    80004a28:	f60080e7          	jalr	-160(ra) # 80003984 <iunlock>
      end_op();
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	8e8080e7          	jalr	-1816(ra) # 80004314 <end_op>

      if(r != n1){
    80004a34:	009c1f63          	bne	s8,s1,80004a52 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a38:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a3c:	0149db63          	bge	s3,s4,80004a52 <filewrite+0xf6>
      int n1 = n - i;
    80004a40:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a44:	84be                	mv	s1,a5
    80004a46:	2781                	sext.w	a5,a5
    80004a48:	f8fb5ce3          	bge	s6,a5,800049e0 <filewrite+0x84>
    80004a4c:	84de                	mv	s1,s7
    80004a4e:	bf49                	j	800049e0 <filewrite+0x84>
    int i = 0;
    80004a50:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a52:	013a1f63          	bne	s4,s3,80004a70 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a56:	8552                	mv	a0,s4
    80004a58:	60a6                	ld	ra,72(sp)
    80004a5a:	6406                	ld	s0,64(sp)
    80004a5c:	74e2                	ld	s1,56(sp)
    80004a5e:	7942                	ld	s2,48(sp)
    80004a60:	79a2                	ld	s3,40(sp)
    80004a62:	7a02                	ld	s4,32(sp)
    80004a64:	6ae2                	ld	s5,24(sp)
    80004a66:	6b42                	ld	s6,16(sp)
    80004a68:	6ba2                	ld	s7,8(sp)
    80004a6a:	6c02                	ld	s8,0(sp)
    80004a6c:	6161                	addi	sp,sp,80
    80004a6e:	8082                	ret
    ret = (i == n ? n : -1);
    80004a70:	5a7d                	li	s4,-1
    80004a72:	b7d5                	j	80004a56 <filewrite+0xfa>
    panic("filewrite");
    80004a74:	00004517          	auipc	a0,0x4
    80004a78:	c7450513          	addi	a0,a0,-908 # 800086e8 <syscalls+0x278>
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>
    return -1;
    80004a84:	5a7d                	li	s4,-1
    80004a86:	bfc1                	j	80004a56 <filewrite+0xfa>
      return -1;
    80004a88:	5a7d                	li	s4,-1
    80004a8a:	b7f1                	j	80004a56 <filewrite+0xfa>
    80004a8c:	5a7d                	li	s4,-1
    80004a8e:	b7e1                	j	80004a56 <filewrite+0xfa>

0000000080004a90 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a90:	7179                	addi	sp,sp,-48
    80004a92:	f406                	sd	ra,40(sp)
    80004a94:	f022                	sd	s0,32(sp)
    80004a96:	ec26                	sd	s1,24(sp)
    80004a98:	e84a                	sd	s2,16(sp)
    80004a9a:	e44e                	sd	s3,8(sp)
    80004a9c:	e052                	sd	s4,0(sp)
    80004a9e:	1800                	addi	s0,sp,48
    80004aa0:	84aa                	mv	s1,a0
    80004aa2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004aa4:	0005b023          	sd	zero,0(a1)
    80004aa8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	bf8080e7          	jalr	-1032(ra) # 800046a4 <filealloc>
    80004ab4:	e088                	sd	a0,0(s1)
    80004ab6:	c551                	beqz	a0,80004b42 <pipealloc+0xb2>
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	bec080e7          	jalr	-1044(ra) # 800046a4 <filealloc>
    80004ac0:	00aa3023          	sd	a0,0(s4)
    80004ac4:	c92d                	beqz	a0,80004b36 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	02e080e7          	jalr	46(ra) # 80000af4 <kalloc>
    80004ace:	892a                	mv	s2,a0
    80004ad0:	c125                	beqz	a0,80004b30 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ad2:	4985                	li	s3,1
    80004ad4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ad8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004adc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ae0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ae4:	00004597          	auipc	a1,0x4
    80004ae8:	c1458593          	addi	a1,a1,-1004 # 800086f8 <syscalls+0x288>
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	068080e7          	jalr	104(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004af4:	609c                	ld	a5,0(s1)
    80004af6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004afa:	609c                	ld	a5,0(s1)
    80004afc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b00:	609c                	ld	a5,0(s1)
    80004b02:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b06:	609c                	ld	a5,0(s1)
    80004b08:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b0c:	000a3783          	ld	a5,0(s4)
    80004b10:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b14:	000a3783          	ld	a5,0(s4)
    80004b18:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b1c:	000a3783          	ld	a5,0(s4)
    80004b20:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b24:	000a3783          	ld	a5,0(s4)
    80004b28:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b2c:	4501                	li	a0,0
    80004b2e:	a025                	j	80004b56 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b30:	6088                	ld	a0,0(s1)
    80004b32:	e501                	bnez	a0,80004b3a <pipealloc+0xaa>
    80004b34:	a039                	j	80004b42 <pipealloc+0xb2>
    80004b36:	6088                	ld	a0,0(s1)
    80004b38:	c51d                	beqz	a0,80004b66 <pipealloc+0xd6>
    fileclose(*f0);
    80004b3a:	00000097          	auipc	ra,0x0
    80004b3e:	c26080e7          	jalr	-986(ra) # 80004760 <fileclose>
  if(*f1)
    80004b42:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b46:	557d                	li	a0,-1
  if(*f1)
    80004b48:	c799                	beqz	a5,80004b56 <pipealloc+0xc6>
    fileclose(*f1);
    80004b4a:	853e                	mv	a0,a5
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	c14080e7          	jalr	-1004(ra) # 80004760 <fileclose>
  return -1;
    80004b54:	557d                	li	a0,-1
}
    80004b56:	70a2                	ld	ra,40(sp)
    80004b58:	7402                	ld	s0,32(sp)
    80004b5a:	64e2                	ld	s1,24(sp)
    80004b5c:	6942                	ld	s2,16(sp)
    80004b5e:	69a2                	ld	s3,8(sp)
    80004b60:	6a02                	ld	s4,0(sp)
    80004b62:	6145                	addi	sp,sp,48
    80004b64:	8082                	ret
  return -1;
    80004b66:	557d                	li	a0,-1
    80004b68:	b7fd                	j	80004b56 <pipealloc+0xc6>

0000000080004b6a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b6a:	1101                	addi	sp,sp,-32
    80004b6c:	ec06                	sd	ra,24(sp)
    80004b6e:	e822                	sd	s0,16(sp)
    80004b70:	e426                	sd	s1,8(sp)
    80004b72:	e04a                	sd	s2,0(sp)
    80004b74:	1000                	addi	s0,sp,32
    80004b76:	84aa                	mv	s1,a0
    80004b78:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	06a080e7          	jalr	106(ra) # 80000be4 <acquire>
  if(writable){
    80004b82:	02090d63          	beqz	s2,80004bbc <pipeclose+0x52>
    pi->writeopen = 0;
    80004b86:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b8a:	21848513          	addi	a0,s1,536
    80004b8e:	ffffe097          	auipc	ra,0xffffe
    80004b92:	832080e7          	jalr	-1998(ra) # 800023c0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b96:	2204b783          	ld	a5,544(s1)
    80004b9a:	eb95                	bnez	a5,80004bce <pipeclose+0x64>
    release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0fa080e7          	jalr	250(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	e50080e7          	jalr	-432(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bb0:	60e2                	ld	ra,24(sp)
    80004bb2:	6442                	ld	s0,16(sp)
    80004bb4:	64a2                	ld	s1,8(sp)
    80004bb6:	6902                	ld	s2,0(sp)
    80004bb8:	6105                	addi	sp,sp,32
    80004bba:	8082                	ret
    pi->readopen = 0;
    80004bbc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bc0:	21c48513          	addi	a0,s1,540
    80004bc4:	ffffd097          	auipc	ra,0xffffd
    80004bc8:	7fc080e7          	jalr	2044(ra) # 800023c0 <wakeup>
    80004bcc:	b7e9                	j	80004b96 <pipeclose+0x2c>
    release(&pi->lock);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0c8080e7          	jalr	200(ra) # 80000c98 <release>
}
    80004bd8:	bfe1                	j	80004bb0 <pipeclose+0x46>

0000000080004bda <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bda:	7159                	addi	sp,sp,-112
    80004bdc:	f486                	sd	ra,104(sp)
    80004bde:	f0a2                	sd	s0,96(sp)
    80004be0:	eca6                	sd	s1,88(sp)
    80004be2:	e8ca                	sd	s2,80(sp)
    80004be4:	e4ce                	sd	s3,72(sp)
    80004be6:	e0d2                	sd	s4,64(sp)
    80004be8:	fc56                	sd	s5,56(sp)
    80004bea:	f85a                	sd	s6,48(sp)
    80004bec:	f45e                	sd	s7,40(sp)
    80004bee:	f062                	sd	s8,32(sp)
    80004bf0:	ec66                	sd	s9,24(sp)
    80004bf2:	1880                	addi	s0,sp,112
    80004bf4:	84aa                	mv	s1,a0
    80004bf6:	8aae                	mv	s5,a1
    80004bf8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	dbe080e7          	jalr	-578(ra) # 800019b8 <myproc>
    80004c02:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	fde080e7          	jalr	-34(ra) # 80000be4 <acquire>
  while(i < n){
    80004c0e:	0d405163          	blez	s4,80004cd0 <pipewrite+0xf6>
    80004c12:	8ba6                	mv	s7,s1
  int i = 0;
    80004c14:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c16:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c18:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c1c:	21c48c13          	addi	s8,s1,540
    80004c20:	a08d                	j	80004c82 <pipewrite+0xa8>
      release(&pi->lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	074080e7          	jalr	116(ra) # 80000c98 <release>
      return -1;
    80004c2c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c2e:	854a                	mv	a0,s2
    80004c30:	70a6                	ld	ra,104(sp)
    80004c32:	7406                	ld	s0,96(sp)
    80004c34:	64e6                	ld	s1,88(sp)
    80004c36:	6946                	ld	s2,80(sp)
    80004c38:	69a6                	ld	s3,72(sp)
    80004c3a:	6a06                	ld	s4,64(sp)
    80004c3c:	7ae2                	ld	s5,56(sp)
    80004c3e:	7b42                	ld	s6,48(sp)
    80004c40:	7ba2                	ld	s7,40(sp)
    80004c42:	7c02                	ld	s8,32(sp)
    80004c44:	6ce2                	ld	s9,24(sp)
    80004c46:	6165                	addi	sp,sp,112
    80004c48:	8082                	ret
      wakeup(&pi->nread);
    80004c4a:	8566                	mv	a0,s9
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	774080e7          	jalr	1908(ra) # 800023c0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c54:	85de                	mv	a1,s7
    80004c56:	8562                	mv	a0,s8
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	5dc080e7          	jalr	1500(ra) # 80002234 <sleep>
    80004c60:	a839                	j	80004c7e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c62:	21c4a783          	lw	a5,540(s1)
    80004c66:	0017871b          	addiw	a4,a5,1
    80004c6a:	20e4ae23          	sw	a4,540(s1)
    80004c6e:	1ff7f793          	andi	a5,a5,511
    80004c72:	97a6                	add	a5,a5,s1
    80004c74:	f9f44703          	lbu	a4,-97(s0)
    80004c78:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c7c:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c7e:	03495d63          	bge	s2,s4,80004cb8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c82:	2204a783          	lw	a5,544(s1)
    80004c86:	dfd1                	beqz	a5,80004c22 <pipewrite+0x48>
    80004c88:	0289a783          	lw	a5,40(s3)
    80004c8c:	fbd9                	bnez	a5,80004c22 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c8e:	2184a783          	lw	a5,536(s1)
    80004c92:	21c4a703          	lw	a4,540(s1)
    80004c96:	2007879b          	addiw	a5,a5,512
    80004c9a:	faf708e3          	beq	a4,a5,80004c4a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c9e:	4685                	li	a3,1
    80004ca0:	01590633          	add	a2,s2,s5
    80004ca4:	f9f40593          	addi	a1,s0,-97
    80004ca8:	0509b503          	ld	a0,80(s3)
    80004cac:	ffffd097          	auipc	ra,0xffffd
    80004cb0:	a5a080e7          	jalr	-1446(ra) # 80001706 <copyin>
    80004cb4:	fb6517e3          	bne	a0,s6,80004c62 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cb8:	21848513          	addi	a0,s1,536
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	704080e7          	jalr	1796(ra) # 800023c0 <wakeup>
  release(&pi->lock);
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	fd2080e7          	jalr	-46(ra) # 80000c98 <release>
  return i;
    80004cce:	b785                	j	80004c2e <pipewrite+0x54>
  int i = 0;
    80004cd0:	4901                	li	s2,0
    80004cd2:	b7dd                	j	80004cb8 <pipewrite+0xde>

0000000080004cd4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cd4:	715d                	addi	sp,sp,-80
    80004cd6:	e486                	sd	ra,72(sp)
    80004cd8:	e0a2                	sd	s0,64(sp)
    80004cda:	fc26                	sd	s1,56(sp)
    80004cdc:	f84a                	sd	s2,48(sp)
    80004cde:	f44e                	sd	s3,40(sp)
    80004ce0:	f052                	sd	s4,32(sp)
    80004ce2:	ec56                	sd	s5,24(sp)
    80004ce4:	e85a                	sd	s6,16(sp)
    80004ce6:	0880                	addi	s0,sp,80
    80004ce8:	84aa                	mv	s1,a0
    80004cea:	892e                	mv	s2,a1
    80004cec:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	cca080e7          	jalr	-822(ra) # 800019b8 <myproc>
    80004cf6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cf8:	8b26                	mv	s6,s1
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	ee8080e7          	jalr	-280(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d04:	2184a703          	lw	a4,536(s1)
    80004d08:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d10:	02f71463          	bne	a4,a5,80004d38 <piperead+0x64>
    80004d14:	2244a783          	lw	a5,548(s1)
    80004d18:	c385                	beqz	a5,80004d38 <piperead+0x64>
    if(pr->killed){
    80004d1a:	028a2783          	lw	a5,40(s4)
    80004d1e:	ebc1                	bnez	a5,80004dae <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d20:	85da                	mv	a1,s6
    80004d22:	854e                	mv	a0,s3
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	510080e7          	jalr	1296(ra) # 80002234 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2c:	2184a703          	lw	a4,536(s1)
    80004d30:	21c4a783          	lw	a5,540(s1)
    80004d34:	fef700e3          	beq	a4,a5,80004d14 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d38:	09505263          	blez	s5,80004dbc <piperead+0xe8>
    80004d3c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d3e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d40:	2184a783          	lw	a5,536(s1)
    80004d44:	21c4a703          	lw	a4,540(s1)
    80004d48:	02f70d63          	beq	a4,a5,80004d82 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d4c:	0017871b          	addiw	a4,a5,1
    80004d50:	20e4ac23          	sw	a4,536(s1)
    80004d54:	1ff7f793          	andi	a5,a5,511
    80004d58:	97a6                	add	a5,a5,s1
    80004d5a:	0187c783          	lbu	a5,24(a5)
    80004d5e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d62:	4685                	li	a3,1
    80004d64:	fbf40613          	addi	a2,s0,-65
    80004d68:	85ca                	mv	a1,s2
    80004d6a:	050a3503          	ld	a0,80(s4)
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	90c080e7          	jalr	-1780(ra) # 8000167a <copyout>
    80004d76:	01650663          	beq	a0,s6,80004d82 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7a:	2985                	addiw	s3,s3,1
    80004d7c:	0905                	addi	s2,s2,1
    80004d7e:	fd3a91e3          	bne	s5,s3,80004d40 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d82:	21c48513          	addi	a0,s1,540
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	63a080e7          	jalr	1594(ra) # 800023c0 <wakeup>
  release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	f08080e7          	jalr	-248(ra) # 80000c98 <release>
  return i;
}
    80004d98:	854e                	mv	a0,s3
    80004d9a:	60a6                	ld	ra,72(sp)
    80004d9c:	6406                	ld	s0,64(sp)
    80004d9e:	74e2                	ld	s1,56(sp)
    80004da0:	7942                	ld	s2,48(sp)
    80004da2:	79a2                	ld	s3,40(sp)
    80004da4:	7a02                	ld	s4,32(sp)
    80004da6:	6ae2                	ld	s5,24(sp)
    80004da8:	6b42                	ld	s6,16(sp)
    80004daa:	6161                	addi	sp,sp,80
    80004dac:	8082                	ret
      release(&pi->lock);
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	ee8080e7          	jalr	-280(ra) # 80000c98 <release>
      return -1;
    80004db8:	59fd                	li	s3,-1
    80004dba:	bff9                	j	80004d98 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dbc:	4981                	li	s3,0
    80004dbe:	b7d1                	j	80004d82 <piperead+0xae>

0000000080004dc0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dc0:	df010113          	addi	sp,sp,-528
    80004dc4:	20113423          	sd	ra,520(sp)
    80004dc8:	20813023          	sd	s0,512(sp)
    80004dcc:	ffa6                	sd	s1,504(sp)
    80004dce:	fbca                	sd	s2,496(sp)
    80004dd0:	f7ce                	sd	s3,488(sp)
    80004dd2:	f3d2                	sd	s4,480(sp)
    80004dd4:	efd6                	sd	s5,472(sp)
    80004dd6:	ebda                	sd	s6,464(sp)
    80004dd8:	e7de                	sd	s7,456(sp)
    80004dda:	e3e2                	sd	s8,448(sp)
    80004ddc:	ff66                	sd	s9,440(sp)
    80004dde:	fb6a                	sd	s10,432(sp)
    80004de0:	f76e                	sd	s11,424(sp)
    80004de2:	0c00                	addi	s0,sp,528
    80004de4:	84aa                	mv	s1,a0
    80004de6:	dea43c23          	sd	a0,-520(s0)
    80004dea:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	bca080e7          	jalr	-1078(ra) # 800019b8 <myproc>
    80004df6:	892a                	mv	s2,a0

  begin_op();
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	49c080e7          	jalr	1180(ra) # 80004294 <begin_op>

  if((ip = namei(path)) == 0){
    80004e00:	8526                	mv	a0,s1
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	276080e7          	jalr	630(ra) # 80004078 <namei>
    80004e0a:	c92d                	beqz	a0,80004e7c <exec+0xbc>
    80004e0c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	ab4080e7          	jalr	-1356(ra) # 800038c2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e16:	04000713          	li	a4,64
    80004e1a:	4681                	li	a3,0
    80004e1c:	e5040613          	addi	a2,s0,-432
    80004e20:	4581                	li	a1,0
    80004e22:	8526                	mv	a0,s1
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	d52080e7          	jalr	-686(ra) # 80003b76 <readi>
    80004e2c:	04000793          	li	a5,64
    80004e30:	00f51a63          	bne	a0,a5,80004e44 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e34:	e5042703          	lw	a4,-432(s0)
    80004e38:	464c47b7          	lui	a5,0x464c4
    80004e3c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e40:	04f70463          	beq	a4,a5,80004e88 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e44:	8526                	mv	a0,s1
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	cde080e7          	jalr	-802(ra) # 80003b24 <iunlockput>
    end_op();
    80004e4e:	fffff097          	auipc	ra,0xfffff
    80004e52:	4c6080e7          	jalr	1222(ra) # 80004314 <end_op>
  }
  return -1;
    80004e56:	557d                	li	a0,-1
}
    80004e58:	20813083          	ld	ra,520(sp)
    80004e5c:	20013403          	ld	s0,512(sp)
    80004e60:	74fe                	ld	s1,504(sp)
    80004e62:	795e                	ld	s2,496(sp)
    80004e64:	79be                	ld	s3,488(sp)
    80004e66:	7a1e                	ld	s4,480(sp)
    80004e68:	6afe                	ld	s5,472(sp)
    80004e6a:	6b5e                	ld	s6,464(sp)
    80004e6c:	6bbe                	ld	s7,456(sp)
    80004e6e:	6c1e                	ld	s8,448(sp)
    80004e70:	7cfa                	ld	s9,440(sp)
    80004e72:	7d5a                	ld	s10,432(sp)
    80004e74:	7dba                	ld	s11,424(sp)
    80004e76:	21010113          	addi	sp,sp,528
    80004e7a:	8082                	ret
    end_op();
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	498080e7          	jalr	1176(ra) # 80004314 <end_op>
    return -1;
    80004e84:	557d                	li	a0,-1
    80004e86:	bfc9                	j	80004e58 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e88:	854a                	mv	a0,s2
    80004e8a:	ffffd097          	auipc	ra,0xffffd
    80004e8e:	bf2080e7          	jalr	-1038(ra) # 80001a7c <proc_pagetable>
    80004e92:	8baa                	mv	s7,a0
    80004e94:	d945                	beqz	a0,80004e44 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e96:	e7042983          	lw	s3,-400(s0)
    80004e9a:	e8845783          	lhu	a5,-376(s0)
    80004e9e:	c7ad                	beqz	a5,80004f08 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ea0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea2:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ea4:	6c85                	lui	s9,0x1
    80004ea6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eaa:	def43823          	sd	a5,-528(s0)
    80004eae:	a42d                	j	800050d8 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eb0:	00004517          	auipc	a0,0x4
    80004eb4:	85050513          	addi	a0,a0,-1968 # 80008700 <syscalls+0x290>
    80004eb8:	ffffb097          	auipc	ra,0xffffb
    80004ebc:	686080e7          	jalr	1670(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ec0:	8756                	mv	a4,s5
    80004ec2:	012d86bb          	addw	a3,s11,s2
    80004ec6:	4581                	li	a1,0
    80004ec8:	8526                	mv	a0,s1
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	cac080e7          	jalr	-852(ra) # 80003b76 <readi>
    80004ed2:	2501                	sext.w	a0,a0
    80004ed4:	1aaa9963          	bne	s5,a0,80005086 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ed8:	6785                	lui	a5,0x1
    80004eda:	0127893b          	addw	s2,a5,s2
    80004ede:	77fd                	lui	a5,0xfffff
    80004ee0:	01478a3b          	addw	s4,a5,s4
    80004ee4:	1f897163          	bgeu	s2,s8,800050c6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ee8:	02091593          	slli	a1,s2,0x20
    80004eec:	9181                	srli	a1,a1,0x20
    80004eee:	95ea                	add	a1,a1,s10
    80004ef0:	855e                	mv	a0,s7
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	184080e7          	jalr	388(ra) # 80001076 <walkaddr>
    80004efa:	862a                	mv	a2,a0
    if(pa == 0)
    80004efc:	d955                	beqz	a0,80004eb0 <exec+0xf0>
      n = PGSIZE;
    80004efe:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f00:	fd9a70e3          	bgeu	s4,s9,80004ec0 <exec+0x100>
      n = sz - i;
    80004f04:	8ad2                	mv	s5,s4
    80004f06:	bf6d                	j	80004ec0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f08:	4901                	li	s2,0
  iunlockput(ip);
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	c18080e7          	jalr	-1000(ra) # 80003b24 <iunlockput>
  end_op();
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	400080e7          	jalr	1024(ra) # 80004314 <end_op>
  p = myproc();
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	a9c080e7          	jalr	-1380(ra) # 800019b8 <myproc>
    80004f24:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f26:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f2a:	6785                	lui	a5,0x1
    80004f2c:	17fd                	addi	a5,a5,-1
    80004f2e:	993e                	add	s2,s2,a5
    80004f30:	757d                	lui	a0,0xfffff
    80004f32:	00a977b3          	and	a5,s2,a0
    80004f36:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f3a:	6609                	lui	a2,0x2
    80004f3c:	963e                	add	a2,a2,a5
    80004f3e:	85be                	mv	a1,a5
    80004f40:	855e                	mv	a0,s7
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	4e8080e7          	jalr	1256(ra) # 8000142a <uvmalloc>
    80004f4a:	8b2a                	mv	s6,a0
  ip = 0;
    80004f4c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f4e:	12050c63          	beqz	a0,80005086 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f52:	75f9                	lui	a1,0xffffe
    80004f54:	95aa                	add	a1,a1,a0
    80004f56:	855e                	mv	a0,s7
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	6f0080e7          	jalr	1776(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f60:	7c7d                	lui	s8,0xfffff
    80004f62:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f64:	e0043783          	ld	a5,-512(s0)
    80004f68:	6388                	ld	a0,0(a5)
    80004f6a:	c535                	beqz	a0,80004fd6 <exec+0x216>
    80004f6c:	e9040993          	addi	s3,s0,-368
    80004f70:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f74:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	eee080e7          	jalr	-274(ra) # 80000e64 <strlen>
    80004f7e:	2505                	addiw	a0,a0,1
    80004f80:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f84:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f88:	13896363          	bltu	s2,s8,800050ae <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f8c:	e0043d83          	ld	s11,-512(s0)
    80004f90:	000dba03          	ld	s4,0(s11)
    80004f94:	8552                	mv	a0,s4
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	ece080e7          	jalr	-306(ra) # 80000e64 <strlen>
    80004f9e:	0015069b          	addiw	a3,a0,1
    80004fa2:	8652                	mv	a2,s4
    80004fa4:	85ca                	mv	a1,s2
    80004fa6:	855e                	mv	a0,s7
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	6d2080e7          	jalr	1746(ra) # 8000167a <copyout>
    80004fb0:	10054363          	bltz	a0,800050b6 <exec+0x2f6>
    ustack[argc] = sp;
    80004fb4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fb8:	0485                	addi	s1,s1,1
    80004fba:	008d8793          	addi	a5,s11,8
    80004fbe:	e0f43023          	sd	a5,-512(s0)
    80004fc2:	008db503          	ld	a0,8(s11)
    80004fc6:	c911                	beqz	a0,80004fda <exec+0x21a>
    if(argc >= MAXARG)
    80004fc8:	09a1                	addi	s3,s3,8
    80004fca:	fb3c96e3          	bne	s9,s3,80004f76 <exec+0x1b6>
  sz = sz1;
    80004fce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd2:	4481                	li	s1,0
    80004fd4:	a84d                	j	80005086 <exec+0x2c6>
  sp = sz;
    80004fd6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fd8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fda:	00349793          	slli	a5,s1,0x3
    80004fde:	f9040713          	addi	a4,s0,-112
    80004fe2:	97ba                	add	a5,a5,a4
    80004fe4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fe8:	00148693          	addi	a3,s1,1
    80004fec:	068e                	slli	a3,a3,0x3
    80004fee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ff2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ff6:	01897663          	bgeu	s2,s8,80005002 <exec+0x242>
  sz = sz1;
    80004ffa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ffe:	4481                	li	s1,0
    80005000:	a059                	j	80005086 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005002:	e9040613          	addi	a2,s0,-368
    80005006:	85ca                	mv	a1,s2
    80005008:	855e                	mv	a0,s7
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	670080e7          	jalr	1648(ra) # 8000167a <copyout>
    80005012:	0a054663          	bltz	a0,800050be <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005016:	058ab783          	ld	a5,88(s5)
    8000501a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000501e:	df843783          	ld	a5,-520(s0)
    80005022:	0007c703          	lbu	a4,0(a5)
    80005026:	cf11                	beqz	a4,80005042 <exec+0x282>
    80005028:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000502a:	02f00693          	li	a3,47
    8000502e:	a039                	j	8000503c <exec+0x27c>
      last = s+1;
    80005030:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005034:	0785                	addi	a5,a5,1
    80005036:	fff7c703          	lbu	a4,-1(a5)
    8000503a:	c701                	beqz	a4,80005042 <exec+0x282>
    if(*s == '/')
    8000503c:	fed71ce3          	bne	a4,a3,80005034 <exec+0x274>
    80005040:	bfc5                	j	80005030 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005042:	4641                	li	a2,16
    80005044:	df843583          	ld	a1,-520(s0)
    80005048:	158a8513          	addi	a0,s5,344
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	de6080e7          	jalr	-538(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005054:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005058:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000505c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005060:	058ab783          	ld	a5,88(s5)
    80005064:	e6843703          	ld	a4,-408(s0)
    80005068:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000506a:	058ab783          	ld	a5,88(s5)
    8000506e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005072:	85ea                	mv	a1,s10
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	aa4080e7          	jalr	-1372(ra) # 80001b18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000507c:	0004851b          	sext.w	a0,s1
    80005080:	bbe1                	j	80004e58 <exec+0x98>
    80005082:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005086:	e0843583          	ld	a1,-504(s0)
    8000508a:	855e                	mv	a0,s7
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	a8c080e7          	jalr	-1396(ra) # 80001b18 <proc_freepagetable>
  if(ip){
    80005094:	da0498e3          	bnez	s1,80004e44 <exec+0x84>
  return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	bb7d                	j	80004e58 <exec+0x98>
    8000509c:	e1243423          	sd	s2,-504(s0)
    800050a0:	b7dd                	j	80005086 <exec+0x2c6>
    800050a2:	e1243423          	sd	s2,-504(s0)
    800050a6:	b7c5                	j	80005086 <exec+0x2c6>
    800050a8:	e1243423          	sd	s2,-504(s0)
    800050ac:	bfe9                	j	80005086 <exec+0x2c6>
  sz = sz1;
    800050ae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050b2:	4481                	li	s1,0
    800050b4:	bfc9                	j	80005086 <exec+0x2c6>
  sz = sz1;
    800050b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ba:	4481                	li	s1,0
    800050bc:	b7e9                	j	80005086 <exec+0x2c6>
  sz = sz1;
    800050be:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c2:	4481                	li	s1,0
    800050c4:	b7c9                	j	80005086 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050c6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ca:	2b05                	addiw	s6,s6,1
    800050cc:	0389899b          	addiw	s3,s3,56
    800050d0:	e8845783          	lhu	a5,-376(s0)
    800050d4:	e2fb5be3          	bge	s6,a5,80004f0a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050d8:	2981                	sext.w	s3,s3
    800050da:	03800713          	li	a4,56
    800050de:	86ce                	mv	a3,s3
    800050e0:	e1840613          	addi	a2,s0,-488
    800050e4:	4581                	li	a1,0
    800050e6:	8526                	mv	a0,s1
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	a8e080e7          	jalr	-1394(ra) # 80003b76 <readi>
    800050f0:	03800793          	li	a5,56
    800050f4:	f8f517e3          	bne	a0,a5,80005082 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050f8:	e1842783          	lw	a5,-488(s0)
    800050fc:	4705                	li	a4,1
    800050fe:	fce796e3          	bne	a5,a4,800050ca <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005102:	e4043603          	ld	a2,-448(s0)
    80005106:	e3843783          	ld	a5,-456(s0)
    8000510a:	f8f669e3          	bltu	a2,a5,8000509c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000510e:	e2843783          	ld	a5,-472(s0)
    80005112:	963e                	add	a2,a2,a5
    80005114:	f8f667e3          	bltu	a2,a5,800050a2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005118:	85ca                	mv	a1,s2
    8000511a:	855e                	mv	a0,s7
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	30e080e7          	jalr	782(ra) # 8000142a <uvmalloc>
    80005124:	e0a43423          	sd	a0,-504(s0)
    80005128:	d141                	beqz	a0,800050a8 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000512a:	e2843d03          	ld	s10,-472(s0)
    8000512e:	df043783          	ld	a5,-528(s0)
    80005132:	00fd77b3          	and	a5,s10,a5
    80005136:	fba1                	bnez	a5,80005086 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005138:	e2042d83          	lw	s11,-480(s0)
    8000513c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005140:	f80c03e3          	beqz	s8,800050c6 <exec+0x306>
    80005144:	8a62                	mv	s4,s8
    80005146:	4901                	li	s2,0
    80005148:	b345                	j	80004ee8 <exec+0x128>

000000008000514a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000514a:	7179                	addi	sp,sp,-48
    8000514c:	f406                	sd	ra,40(sp)
    8000514e:	f022                	sd	s0,32(sp)
    80005150:	ec26                	sd	s1,24(sp)
    80005152:	e84a                	sd	s2,16(sp)
    80005154:	1800                	addi	s0,sp,48
    80005156:	892e                	mv	s2,a1
    80005158:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000515a:	fdc40593          	addi	a1,s0,-36
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	ba8080e7          	jalr	-1112(ra) # 80002d06 <argint>
    80005166:	04054063          	bltz	a0,800051a6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000516a:	fdc42703          	lw	a4,-36(s0)
    8000516e:	47bd                	li	a5,15
    80005170:	02e7ed63          	bltu	a5,a4,800051aa <argfd+0x60>
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	844080e7          	jalr	-1980(ra) # 800019b8 <myproc>
    8000517c:	fdc42703          	lw	a4,-36(s0)
    80005180:	01a70793          	addi	a5,a4,26
    80005184:	078e                	slli	a5,a5,0x3
    80005186:	953e                	add	a0,a0,a5
    80005188:	611c                	ld	a5,0(a0)
    8000518a:	c395                	beqz	a5,800051ae <argfd+0x64>
    return -1;
  if(pfd)
    8000518c:	00090463          	beqz	s2,80005194 <argfd+0x4a>
    *pfd = fd;
    80005190:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005194:	4501                	li	a0,0
  if(pf)
    80005196:	c091                	beqz	s1,8000519a <argfd+0x50>
    *pf = f;
    80005198:	e09c                	sd	a5,0(s1)
}
    8000519a:	70a2                	ld	ra,40(sp)
    8000519c:	7402                	ld	s0,32(sp)
    8000519e:	64e2                	ld	s1,24(sp)
    800051a0:	6942                	ld	s2,16(sp)
    800051a2:	6145                	addi	sp,sp,48
    800051a4:	8082                	ret
    return -1;
    800051a6:	557d                	li	a0,-1
    800051a8:	bfcd                	j	8000519a <argfd+0x50>
    return -1;
    800051aa:	557d                	li	a0,-1
    800051ac:	b7fd                	j	8000519a <argfd+0x50>
    800051ae:	557d                	li	a0,-1
    800051b0:	b7ed                	j	8000519a <argfd+0x50>

00000000800051b2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051b2:	1101                	addi	sp,sp,-32
    800051b4:	ec06                	sd	ra,24(sp)
    800051b6:	e822                	sd	s0,16(sp)
    800051b8:	e426                	sd	s1,8(sp)
    800051ba:	1000                	addi	s0,sp,32
    800051bc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	7fa080e7          	jalr	2042(ra) # 800019b8 <myproc>
    800051c6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051c8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    800051cc:	4501                	li	a0,0
    800051ce:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051d0:	6398                	ld	a4,0(a5)
    800051d2:	cb19                	beqz	a4,800051e8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051d4:	2505                	addiw	a0,a0,1
    800051d6:	07a1                	addi	a5,a5,8
    800051d8:	fed51ce3          	bne	a0,a3,800051d0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051dc:	557d                	li	a0,-1
}
    800051de:	60e2                	ld	ra,24(sp)
    800051e0:	6442                	ld	s0,16(sp)
    800051e2:	64a2                	ld	s1,8(sp)
    800051e4:	6105                	addi	sp,sp,32
    800051e6:	8082                	ret
      p->ofile[fd] = f;
    800051e8:	01a50793          	addi	a5,a0,26
    800051ec:	078e                	slli	a5,a5,0x3
    800051ee:	963e                	add	a2,a2,a5
    800051f0:	e204                	sd	s1,0(a2)
      return fd;
    800051f2:	b7f5                	j	800051de <fdalloc+0x2c>

00000000800051f4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051f4:	715d                	addi	sp,sp,-80
    800051f6:	e486                	sd	ra,72(sp)
    800051f8:	e0a2                	sd	s0,64(sp)
    800051fa:	fc26                	sd	s1,56(sp)
    800051fc:	f84a                	sd	s2,48(sp)
    800051fe:	f44e                	sd	s3,40(sp)
    80005200:	f052                	sd	s4,32(sp)
    80005202:	ec56                	sd	s5,24(sp)
    80005204:	0880                	addi	s0,sp,80
    80005206:	89ae                	mv	s3,a1
    80005208:	8ab2                	mv	s5,a2
    8000520a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000520c:	fb040593          	addi	a1,s0,-80
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	e86080e7          	jalr	-378(ra) # 80004096 <nameiparent>
    80005218:	892a                	mv	s2,a0
    8000521a:	12050f63          	beqz	a0,80005358 <create+0x164>
    return 0;

  ilock(dp);
    8000521e:	ffffe097          	auipc	ra,0xffffe
    80005222:	6a4080e7          	jalr	1700(ra) # 800038c2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005226:	4601                	li	a2,0
    80005228:	fb040593          	addi	a1,s0,-80
    8000522c:	854a                	mv	a0,s2
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	b78080e7          	jalr	-1160(ra) # 80003da6 <dirlookup>
    80005236:	84aa                	mv	s1,a0
    80005238:	c921                	beqz	a0,80005288 <create+0x94>
    iunlockput(dp);
    8000523a:	854a                	mv	a0,s2
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	8e8080e7          	jalr	-1816(ra) # 80003b24 <iunlockput>
    ilock(ip);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	67c080e7          	jalr	1660(ra) # 800038c2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000524e:	2981                	sext.w	s3,s3
    80005250:	4789                	li	a5,2
    80005252:	02f99463          	bne	s3,a5,8000527a <create+0x86>
    80005256:	0444d783          	lhu	a5,68(s1)
    8000525a:	37f9                	addiw	a5,a5,-2
    8000525c:	17c2                	slli	a5,a5,0x30
    8000525e:	93c1                	srli	a5,a5,0x30
    80005260:	4705                	li	a4,1
    80005262:	00f76c63          	bltu	a4,a5,8000527a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005266:	8526                	mv	a0,s1
    80005268:	60a6                	ld	ra,72(sp)
    8000526a:	6406                	ld	s0,64(sp)
    8000526c:	74e2                	ld	s1,56(sp)
    8000526e:	7942                	ld	s2,48(sp)
    80005270:	79a2                	ld	s3,40(sp)
    80005272:	7a02                	ld	s4,32(sp)
    80005274:	6ae2                	ld	s5,24(sp)
    80005276:	6161                	addi	sp,sp,80
    80005278:	8082                	ret
    iunlockput(ip);
    8000527a:	8526                	mv	a0,s1
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	8a8080e7          	jalr	-1880(ra) # 80003b24 <iunlockput>
    return 0;
    80005284:	4481                	li	s1,0
    80005286:	b7c5                	j	80005266 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005288:	85ce                	mv	a1,s3
    8000528a:	00092503          	lw	a0,0(s2)
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	49c080e7          	jalr	1180(ra) # 8000372a <ialloc>
    80005296:	84aa                	mv	s1,a0
    80005298:	c529                	beqz	a0,800052e2 <create+0xee>
  ilock(ip);
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	628080e7          	jalr	1576(ra) # 800038c2 <ilock>
  ip->major = major;
    800052a2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052a6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052aa:	4785                	li	a5,1
    800052ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052b0:	8526                	mv	a0,s1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	546080e7          	jalr	1350(ra) # 800037f8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ba:	2981                	sext.w	s3,s3
    800052bc:	4785                	li	a5,1
    800052be:	02f98a63          	beq	s3,a5,800052f2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052c2:	40d0                	lw	a2,4(s1)
    800052c4:	fb040593          	addi	a1,s0,-80
    800052c8:	854a                	mv	a0,s2
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	cec080e7          	jalr	-788(ra) # 80003fb6 <dirlink>
    800052d2:	06054b63          	bltz	a0,80005348 <create+0x154>
  iunlockput(dp);
    800052d6:	854a                	mv	a0,s2
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	84c080e7          	jalr	-1972(ra) # 80003b24 <iunlockput>
  return ip;
    800052e0:	b759                	j	80005266 <create+0x72>
    panic("create: ialloc");
    800052e2:	00003517          	auipc	a0,0x3
    800052e6:	43e50513          	addi	a0,a0,1086 # 80008720 <syscalls+0x2b0>
    800052ea:	ffffb097          	auipc	ra,0xffffb
    800052ee:	254080e7          	jalr	596(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052f2:	04a95783          	lhu	a5,74(s2)
    800052f6:	2785                	addiw	a5,a5,1
    800052f8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052fc:	854a                	mv	a0,s2
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	4fa080e7          	jalr	1274(ra) # 800037f8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005306:	40d0                	lw	a2,4(s1)
    80005308:	00003597          	auipc	a1,0x3
    8000530c:	42858593          	addi	a1,a1,1064 # 80008730 <syscalls+0x2c0>
    80005310:	8526                	mv	a0,s1
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	ca4080e7          	jalr	-860(ra) # 80003fb6 <dirlink>
    8000531a:	00054f63          	bltz	a0,80005338 <create+0x144>
    8000531e:	00492603          	lw	a2,4(s2)
    80005322:	00003597          	auipc	a1,0x3
    80005326:	41658593          	addi	a1,a1,1046 # 80008738 <syscalls+0x2c8>
    8000532a:	8526                	mv	a0,s1
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	c8a080e7          	jalr	-886(ra) # 80003fb6 <dirlink>
    80005334:	f80557e3          	bgez	a0,800052c2 <create+0xce>
      panic("create dots");
    80005338:	00003517          	auipc	a0,0x3
    8000533c:	40850513          	addi	a0,a0,1032 # 80008740 <syscalls+0x2d0>
    80005340:	ffffb097          	auipc	ra,0xffffb
    80005344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005348:	00003517          	auipc	a0,0x3
    8000534c:	40850513          	addi	a0,a0,1032 # 80008750 <syscalls+0x2e0>
    80005350:	ffffb097          	auipc	ra,0xffffb
    80005354:	1ee080e7          	jalr	494(ra) # 8000053e <panic>
    return 0;
    80005358:	84aa                	mv	s1,a0
    8000535a:	b731                	j	80005266 <create+0x72>

000000008000535c <sys_dup>:
{
    8000535c:	7179                	addi	sp,sp,-48
    8000535e:	f406                	sd	ra,40(sp)
    80005360:	f022                	sd	s0,32(sp)
    80005362:	ec26                	sd	s1,24(sp)
    80005364:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005366:	fd840613          	addi	a2,s0,-40
    8000536a:	4581                	li	a1,0
    8000536c:	4501                	li	a0,0
    8000536e:	00000097          	auipc	ra,0x0
    80005372:	ddc080e7          	jalr	-548(ra) # 8000514a <argfd>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005378:	02054363          	bltz	a0,8000539e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000537c:	fd843503          	ld	a0,-40(s0)
    80005380:	00000097          	auipc	ra,0x0
    80005384:	e32080e7          	jalr	-462(ra) # 800051b2 <fdalloc>
    80005388:	84aa                	mv	s1,a0
    return -1;
    8000538a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000538c:	00054963          	bltz	a0,8000539e <sys_dup+0x42>
  filedup(f);
    80005390:	fd843503          	ld	a0,-40(s0)
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	37a080e7          	jalr	890(ra) # 8000470e <filedup>
  return fd;
    8000539c:	87a6                	mv	a5,s1
}
    8000539e:	853e                	mv	a0,a5
    800053a0:	70a2                	ld	ra,40(sp)
    800053a2:	7402                	ld	s0,32(sp)
    800053a4:	64e2                	ld	s1,24(sp)
    800053a6:	6145                	addi	sp,sp,48
    800053a8:	8082                	ret

00000000800053aa <sys_read>:
{
    800053aa:	7179                	addi	sp,sp,-48
    800053ac:	f406                	sd	ra,40(sp)
    800053ae:	f022                	sd	s0,32(sp)
    800053b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b2:	fe840613          	addi	a2,s0,-24
    800053b6:	4581                	li	a1,0
    800053b8:	4501                	li	a0,0
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	d90080e7          	jalr	-624(ra) # 8000514a <argfd>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c4:	04054163          	bltz	a0,80005406 <sys_read+0x5c>
    800053c8:	fe440593          	addi	a1,s0,-28
    800053cc:	4509                	li	a0,2
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	938080e7          	jalr	-1736(ra) # 80002d06 <argint>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d8:	02054763          	bltz	a0,80005406 <sys_read+0x5c>
    800053dc:	fd840593          	addi	a1,s0,-40
    800053e0:	4505                	li	a0,1
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	946080e7          	jalr	-1722(ra) # 80002d28 <argaddr>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	00054d63          	bltz	a0,80005406 <sys_read+0x5c>
  return fileread(f, p, n);
    800053f0:	fe442603          	lw	a2,-28(s0)
    800053f4:	fd843583          	ld	a1,-40(s0)
    800053f8:	fe843503          	ld	a0,-24(s0)
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	49e080e7          	jalr	1182(ra) # 8000489a <fileread>
    80005404:	87aa                	mv	a5,a0
}
    80005406:	853e                	mv	a0,a5
    80005408:	70a2                	ld	ra,40(sp)
    8000540a:	7402                	ld	s0,32(sp)
    8000540c:	6145                	addi	sp,sp,48
    8000540e:	8082                	ret

0000000080005410 <sys_write>:
{
    80005410:	7179                	addi	sp,sp,-48
    80005412:	f406                	sd	ra,40(sp)
    80005414:	f022                	sd	s0,32(sp)
    80005416:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005418:	fe840613          	addi	a2,s0,-24
    8000541c:	4581                	li	a1,0
    8000541e:	4501                	li	a0,0
    80005420:	00000097          	auipc	ra,0x0
    80005424:	d2a080e7          	jalr	-726(ra) # 8000514a <argfd>
    return -1;
    80005428:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000542a:	04054163          	bltz	a0,8000546c <sys_write+0x5c>
    8000542e:	fe440593          	addi	a1,s0,-28
    80005432:	4509                	li	a0,2
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	8d2080e7          	jalr	-1838(ra) # 80002d06 <argint>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543e:	02054763          	bltz	a0,8000546c <sys_write+0x5c>
    80005442:	fd840593          	addi	a1,s0,-40
    80005446:	4505                	li	a0,1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	8e0080e7          	jalr	-1824(ra) # 80002d28 <argaddr>
    return -1;
    80005450:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005452:	00054d63          	bltz	a0,8000546c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005456:	fe442603          	lw	a2,-28(s0)
    8000545a:	fd843583          	ld	a1,-40(s0)
    8000545e:	fe843503          	ld	a0,-24(s0)
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	4fa080e7          	jalr	1274(ra) # 8000495c <filewrite>
    8000546a:	87aa                	mv	a5,a0
}
    8000546c:	853e                	mv	a0,a5
    8000546e:	70a2                	ld	ra,40(sp)
    80005470:	7402                	ld	s0,32(sp)
    80005472:	6145                	addi	sp,sp,48
    80005474:	8082                	ret

0000000080005476 <sys_close>:
{
    80005476:	1101                	addi	sp,sp,-32
    80005478:	ec06                	sd	ra,24(sp)
    8000547a:	e822                	sd	s0,16(sp)
    8000547c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000547e:	fe040613          	addi	a2,s0,-32
    80005482:	fec40593          	addi	a1,s0,-20
    80005486:	4501                	li	a0,0
    80005488:	00000097          	auipc	ra,0x0
    8000548c:	cc2080e7          	jalr	-830(ra) # 8000514a <argfd>
    return -1;
    80005490:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005492:	02054463          	bltz	a0,800054ba <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	522080e7          	jalr	1314(ra) # 800019b8 <myproc>
    8000549e:	fec42783          	lw	a5,-20(s0)
    800054a2:	07e9                	addi	a5,a5,26
    800054a4:	078e                	slli	a5,a5,0x3
    800054a6:	97aa                	add	a5,a5,a0
    800054a8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054ac:	fe043503          	ld	a0,-32(s0)
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	2b0080e7          	jalr	688(ra) # 80004760 <fileclose>
  return 0;
    800054b8:	4781                	li	a5,0
}
    800054ba:	853e                	mv	a0,a5
    800054bc:	60e2                	ld	ra,24(sp)
    800054be:	6442                	ld	s0,16(sp)
    800054c0:	6105                	addi	sp,sp,32
    800054c2:	8082                	ret

00000000800054c4 <sys_fstat>:
{
    800054c4:	1101                	addi	sp,sp,-32
    800054c6:	ec06                	sd	ra,24(sp)
    800054c8:	e822                	sd	s0,16(sp)
    800054ca:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054cc:	fe840613          	addi	a2,s0,-24
    800054d0:	4581                	li	a1,0
    800054d2:	4501                	li	a0,0
    800054d4:	00000097          	auipc	ra,0x0
    800054d8:	c76080e7          	jalr	-906(ra) # 8000514a <argfd>
    return -1;
    800054dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054de:	02054563          	bltz	a0,80005508 <sys_fstat+0x44>
    800054e2:	fe040593          	addi	a1,s0,-32
    800054e6:	4505                	li	a0,1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	840080e7          	jalr	-1984(ra) # 80002d28 <argaddr>
    return -1;
    800054f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054f2:	00054b63          	bltz	a0,80005508 <sys_fstat+0x44>
  return filestat(f, st);
    800054f6:	fe043583          	ld	a1,-32(s0)
    800054fa:	fe843503          	ld	a0,-24(s0)
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	32a080e7          	jalr	810(ra) # 80004828 <filestat>
    80005506:	87aa                	mv	a5,a0
}
    80005508:	853e                	mv	a0,a5
    8000550a:	60e2                	ld	ra,24(sp)
    8000550c:	6442                	ld	s0,16(sp)
    8000550e:	6105                	addi	sp,sp,32
    80005510:	8082                	ret

0000000080005512 <sys_link>:
{
    80005512:	7169                	addi	sp,sp,-304
    80005514:	f606                	sd	ra,296(sp)
    80005516:	f222                	sd	s0,288(sp)
    80005518:	ee26                	sd	s1,280(sp)
    8000551a:	ea4a                	sd	s2,272(sp)
    8000551c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551e:	08000613          	li	a2,128
    80005522:	ed040593          	addi	a1,s0,-304
    80005526:	4501                	li	a0,0
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	822080e7          	jalr	-2014(ra) # 80002d4a <argstr>
    return -1;
    80005530:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005532:	10054e63          	bltz	a0,8000564e <sys_link+0x13c>
    80005536:	08000613          	li	a2,128
    8000553a:	f5040593          	addi	a1,s0,-176
    8000553e:	4505                	li	a0,1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	80a080e7          	jalr	-2038(ra) # 80002d4a <argstr>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554a:	10054263          	bltz	a0,8000564e <sys_link+0x13c>
  begin_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	d46080e7          	jalr	-698(ra) # 80004294 <begin_op>
  if((ip = namei(old)) == 0){
    80005556:	ed040513          	addi	a0,s0,-304
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	b1e080e7          	jalr	-1250(ra) # 80004078 <namei>
    80005562:	84aa                	mv	s1,a0
    80005564:	c551                	beqz	a0,800055f0 <sys_link+0xde>
  ilock(ip);
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	35c080e7          	jalr	860(ra) # 800038c2 <ilock>
  if(ip->type == T_DIR){
    8000556e:	04449703          	lh	a4,68(s1)
    80005572:	4785                	li	a5,1
    80005574:	08f70463          	beq	a4,a5,800055fc <sys_link+0xea>
  ip->nlink++;
    80005578:	04a4d783          	lhu	a5,74(s1)
    8000557c:	2785                	addiw	a5,a5,1
    8000557e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	274080e7          	jalr	628(ra) # 800037f8 <iupdate>
  iunlock(ip);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	3f6080e7          	jalr	1014(ra) # 80003984 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005596:	fd040593          	addi	a1,s0,-48
    8000559a:	f5040513          	addi	a0,s0,-176
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	af8080e7          	jalr	-1288(ra) # 80004096 <nameiparent>
    800055a6:	892a                	mv	s2,a0
    800055a8:	c935                	beqz	a0,8000561c <sys_link+0x10a>
  ilock(dp);
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	318080e7          	jalr	792(ra) # 800038c2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055b2:	00092703          	lw	a4,0(s2)
    800055b6:	409c                	lw	a5,0(s1)
    800055b8:	04f71d63          	bne	a4,a5,80005612 <sys_link+0x100>
    800055bc:	40d0                	lw	a2,4(s1)
    800055be:	fd040593          	addi	a1,s0,-48
    800055c2:	854a                	mv	a0,s2
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	9f2080e7          	jalr	-1550(ra) # 80003fb6 <dirlink>
    800055cc:	04054363          	bltz	a0,80005612 <sys_link+0x100>
  iunlockput(dp);
    800055d0:	854a                	mv	a0,s2
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	552080e7          	jalr	1362(ra) # 80003b24 <iunlockput>
  iput(ip);
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	4a0080e7          	jalr	1184(ra) # 80003a7c <iput>
  end_op();
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	d30080e7          	jalr	-720(ra) # 80004314 <end_op>
  return 0;
    800055ec:	4781                	li	a5,0
    800055ee:	a085                	j	8000564e <sys_link+0x13c>
    end_op();
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	d24080e7          	jalr	-732(ra) # 80004314 <end_op>
    return -1;
    800055f8:	57fd                	li	a5,-1
    800055fa:	a891                	j	8000564e <sys_link+0x13c>
    iunlockput(ip);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	526080e7          	jalr	1318(ra) # 80003b24 <iunlockput>
    end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	d0e080e7          	jalr	-754(ra) # 80004314 <end_op>
    return -1;
    8000560e:	57fd                	li	a5,-1
    80005610:	a83d                	j	8000564e <sys_link+0x13c>
    iunlockput(dp);
    80005612:	854a                	mv	a0,s2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	510080e7          	jalr	1296(ra) # 80003b24 <iunlockput>
  ilock(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	2a4080e7          	jalr	676(ra) # 800038c2 <ilock>
  ip->nlink--;
    80005626:	04a4d783          	lhu	a5,74(s1)
    8000562a:	37fd                	addiw	a5,a5,-1
    8000562c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	1c6080e7          	jalr	454(ra) # 800037f8 <iupdate>
  iunlockput(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	4e8080e7          	jalr	1256(ra) # 80003b24 <iunlockput>
  end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	cd0080e7          	jalr	-816(ra) # 80004314 <end_op>
  return -1;
    8000564c:	57fd                	li	a5,-1
}
    8000564e:	853e                	mv	a0,a5
    80005650:	70b2                	ld	ra,296(sp)
    80005652:	7412                	ld	s0,288(sp)
    80005654:	64f2                	ld	s1,280(sp)
    80005656:	6952                	ld	s2,272(sp)
    80005658:	6155                	addi	sp,sp,304
    8000565a:	8082                	ret

000000008000565c <sys_unlink>:
{
    8000565c:	7151                	addi	sp,sp,-240
    8000565e:	f586                	sd	ra,232(sp)
    80005660:	f1a2                	sd	s0,224(sp)
    80005662:	eda6                	sd	s1,216(sp)
    80005664:	e9ca                	sd	s2,208(sp)
    80005666:	e5ce                	sd	s3,200(sp)
    80005668:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000566a:	08000613          	li	a2,128
    8000566e:	f3040593          	addi	a1,s0,-208
    80005672:	4501                	li	a0,0
    80005674:	ffffd097          	auipc	ra,0xffffd
    80005678:	6d6080e7          	jalr	1750(ra) # 80002d4a <argstr>
    8000567c:	18054163          	bltz	a0,800057fe <sys_unlink+0x1a2>
  begin_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	c14080e7          	jalr	-1004(ra) # 80004294 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005688:	fb040593          	addi	a1,s0,-80
    8000568c:	f3040513          	addi	a0,s0,-208
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	a06080e7          	jalr	-1530(ra) # 80004096 <nameiparent>
    80005698:	84aa                	mv	s1,a0
    8000569a:	c979                	beqz	a0,80005770 <sys_unlink+0x114>
  ilock(dp);
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	226080e7          	jalr	550(ra) # 800038c2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056a4:	00003597          	auipc	a1,0x3
    800056a8:	08c58593          	addi	a1,a1,140 # 80008730 <syscalls+0x2c0>
    800056ac:	fb040513          	addi	a0,s0,-80
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	6dc080e7          	jalr	1756(ra) # 80003d8c <namecmp>
    800056b8:	14050a63          	beqz	a0,8000580c <sys_unlink+0x1b0>
    800056bc:	00003597          	auipc	a1,0x3
    800056c0:	07c58593          	addi	a1,a1,124 # 80008738 <syscalls+0x2c8>
    800056c4:	fb040513          	addi	a0,s0,-80
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	6c4080e7          	jalr	1732(ra) # 80003d8c <namecmp>
    800056d0:	12050e63          	beqz	a0,8000580c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056d4:	f2c40613          	addi	a2,s0,-212
    800056d8:	fb040593          	addi	a1,s0,-80
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	6c8080e7          	jalr	1736(ra) # 80003da6 <dirlookup>
    800056e6:	892a                	mv	s2,a0
    800056e8:	12050263          	beqz	a0,8000580c <sys_unlink+0x1b0>
  ilock(ip);
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	1d6080e7          	jalr	470(ra) # 800038c2 <ilock>
  if(ip->nlink < 1)
    800056f4:	04a91783          	lh	a5,74(s2)
    800056f8:	08f05263          	blez	a5,8000577c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056fc:	04491703          	lh	a4,68(s2)
    80005700:	4785                	li	a5,1
    80005702:	08f70563          	beq	a4,a5,8000578c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005706:	4641                	li	a2,16
    80005708:	4581                	li	a1,0
    8000570a:	fc040513          	addi	a0,s0,-64
    8000570e:	ffffb097          	auipc	ra,0xffffb
    80005712:	5d2080e7          	jalr	1490(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005716:	4741                	li	a4,16
    80005718:	f2c42683          	lw	a3,-212(s0)
    8000571c:	fc040613          	addi	a2,s0,-64
    80005720:	4581                	li	a1,0
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	54a080e7          	jalr	1354(ra) # 80003c6e <writei>
    8000572c:	47c1                	li	a5,16
    8000572e:	0af51563          	bne	a0,a5,800057d8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005732:	04491703          	lh	a4,68(s2)
    80005736:	4785                	li	a5,1
    80005738:	0af70863          	beq	a4,a5,800057e8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	3e6080e7          	jalr	998(ra) # 80003b24 <iunlockput>
  ip->nlink--;
    80005746:	04a95783          	lhu	a5,74(s2)
    8000574a:	37fd                	addiw	a5,a5,-1
    8000574c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005750:	854a                	mv	a0,s2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	0a6080e7          	jalr	166(ra) # 800037f8 <iupdate>
  iunlockput(ip);
    8000575a:	854a                	mv	a0,s2
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	3c8080e7          	jalr	968(ra) # 80003b24 <iunlockput>
  end_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	bb0080e7          	jalr	-1104(ra) # 80004314 <end_op>
  return 0;
    8000576c:	4501                	li	a0,0
    8000576e:	a84d                	j	80005820 <sys_unlink+0x1c4>
    end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	ba4080e7          	jalr	-1116(ra) # 80004314 <end_op>
    return -1;
    80005778:	557d                	li	a0,-1
    8000577a:	a05d                	j	80005820 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000577c:	00003517          	auipc	a0,0x3
    80005780:	fe450513          	addi	a0,a0,-28 # 80008760 <syscalls+0x2f0>
    80005784:	ffffb097          	auipc	ra,0xffffb
    80005788:	dba080e7          	jalr	-582(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000578c:	04c92703          	lw	a4,76(s2)
    80005790:	02000793          	li	a5,32
    80005794:	f6e7f9e3          	bgeu	a5,a4,80005706 <sys_unlink+0xaa>
    80005798:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000579c:	4741                	li	a4,16
    8000579e:	86ce                	mv	a3,s3
    800057a0:	f1840613          	addi	a2,s0,-232
    800057a4:	4581                	li	a1,0
    800057a6:	854a                	mv	a0,s2
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	3ce080e7          	jalr	974(ra) # 80003b76 <readi>
    800057b0:	47c1                	li	a5,16
    800057b2:	00f51b63          	bne	a0,a5,800057c8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057b6:	f1845783          	lhu	a5,-232(s0)
    800057ba:	e7a1                	bnez	a5,80005802 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057bc:	29c1                	addiw	s3,s3,16
    800057be:	04c92783          	lw	a5,76(s2)
    800057c2:	fcf9ede3          	bltu	s3,a5,8000579c <sys_unlink+0x140>
    800057c6:	b781                	j	80005706 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057c8:	00003517          	auipc	a0,0x3
    800057cc:	fb050513          	addi	a0,a0,-80 # 80008778 <syscalls+0x308>
    800057d0:	ffffb097          	auipc	ra,0xffffb
    800057d4:	d6e080e7          	jalr	-658(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057d8:	00003517          	auipc	a0,0x3
    800057dc:	fb850513          	addi	a0,a0,-72 # 80008790 <syscalls+0x320>
    800057e0:	ffffb097          	auipc	ra,0xffffb
    800057e4:	d5e080e7          	jalr	-674(ra) # 8000053e <panic>
    dp->nlink--;
    800057e8:	04a4d783          	lhu	a5,74(s1)
    800057ec:	37fd                	addiw	a5,a5,-1
    800057ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	004080e7          	jalr	4(ra) # 800037f8 <iupdate>
    800057fc:	b781                	j	8000573c <sys_unlink+0xe0>
    return -1;
    800057fe:	557d                	li	a0,-1
    80005800:	a005                	j	80005820 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005802:	854a                	mv	a0,s2
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	320080e7          	jalr	800(ra) # 80003b24 <iunlockput>
  iunlockput(dp);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	316080e7          	jalr	790(ra) # 80003b24 <iunlockput>
  end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	afe080e7          	jalr	-1282(ra) # 80004314 <end_op>
  return -1;
    8000581e:	557d                	li	a0,-1
}
    80005820:	70ae                	ld	ra,232(sp)
    80005822:	740e                	ld	s0,224(sp)
    80005824:	64ee                	ld	s1,216(sp)
    80005826:	694e                	ld	s2,208(sp)
    80005828:	69ae                	ld	s3,200(sp)
    8000582a:	616d                	addi	sp,sp,240
    8000582c:	8082                	ret

000000008000582e <sys_open>:

uint64
sys_open(void)
{
    8000582e:	7131                	addi	sp,sp,-192
    80005830:	fd06                	sd	ra,184(sp)
    80005832:	f922                	sd	s0,176(sp)
    80005834:	f526                	sd	s1,168(sp)
    80005836:	f14a                	sd	s2,160(sp)
    80005838:	ed4e                	sd	s3,152(sp)
    8000583a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000583c:	08000613          	li	a2,128
    80005840:	f5040593          	addi	a1,s0,-176
    80005844:	4501                	li	a0,0
    80005846:	ffffd097          	auipc	ra,0xffffd
    8000584a:	504080e7          	jalr	1284(ra) # 80002d4a <argstr>
    return -1;
    8000584e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005850:	0c054163          	bltz	a0,80005912 <sys_open+0xe4>
    80005854:	f4c40593          	addi	a1,s0,-180
    80005858:	4505                	li	a0,1
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	4ac080e7          	jalr	1196(ra) # 80002d06 <argint>
    80005862:	0a054863          	bltz	a0,80005912 <sys_open+0xe4>

  begin_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	a2e080e7          	jalr	-1490(ra) # 80004294 <begin_op>

  if(omode & O_CREATE){
    8000586e:	f4c42783          	lw	a5,-180(s0)
    80005872:	2007f793          	andi	a5,a5,512
    80005876:	cbdd                	beqz	a5,8000592c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005878:	4681                	li	a3,0
    8000587a:	4601                	li	a2,0
    8000587c:	4589                	li	a1,2
    8000587e:	f5040513          	addi	a0,s0,-176
    80005882:	00000097          	auipc	ra,0x0
    80005886:	972080e7          	jalr	-1678(ra) # 800051f4 <create>
    8000588a:	892a                	mv	s2,a0
    if(ip == 0){
    8000588c:	c959                	beqz	a0,80005922 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000588e:	04491703          	lh	a4,68(s2)
    80005892:	478d                	li	a5,3
    80005894:	00f71763          	bne	a4,a5,800058a2 <sys_open+0x74>
    80005898:	04695703          	lhu	a4,70(s2)
    8000589c:	47a5                	li	a5,9
    8000589e:	0ce7ec63          	bltu	a5,a4,80005976 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	e02080e7          	jalr	-510(ra) # 800046a4 <filealloc>
    800058aa:	89aa                	mv	s3,a0
    800058ac:	10050263          	beqz	a0,800059b0 <sys_open+0x182>
    800058b0:	00000097          	auipc	ra,0x0
    800058b4:	902080e7          	jalr	-1790(ra) # 800051b2 <fdalloc>
    800058b8:	84aa                	mv	s1,a0
    800058ba:	0e054663          	bltz	a0,800059a6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058be:	04491703          	lh	a4,68(s2)
    800058c2:	478d                	li	a5,3
    800058c4:	0cf70463          	beq	a4,a5,8000598c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058c8:	4789                	li	a5,2
    800058ca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058ce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058d2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058d6:	f4c42783          	lw	a5,-180(s0)
    800058da:	0017c713          	xori	a4,a5,1
    800058de:	8b05                	andi	a4,a4,1
    800058e0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058e4:	0037f713          	andi	a4,a5,3
    800058e8:	00e03733          	snez	a4,a4
    800058ec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058f0:	4007f793          	andi	a5,a5,1024
    800058f4:	c791                	beqz	a5,80005900 <sys_open+0xd2>
    800058f6:	04491703          	lh	a4,68(s2)
    800058fa:	4789                	li	a5,2
    800058fc:	08f70f63          	beq	a4,a5,8000599a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	082080e7          	jalr	130(ra) # 80003984 <iunlock>
  end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	a0a080e7          	jalr	-1526(ra) # 80004314 <end_op>

  return fd;
}
    80005912:	8526                	mv	a0,s1
    80005914:	70ea                	ld	ra,184(sp)
    80005916:	744a                	ld	s0,176(sp)
    80005918:	74aa                	ld	s1,168(sp)
    8000591a:	790a                	ld	s2,160(sp)
    8000591c:	69ea                	ld	s3,152(sp)
    8000591e:	6129                	addi	sp,sp,192
    80005920:	8082                	ret
      end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	9f2080e7          	jalr	-1550(ra) # 80004314 <end_op>
      return -1;
    8000592a:	b7e5                	j	80005912 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000592c:	f5040513          	addi	a0,s0,-176
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	748080e7          	jalr	1864(ra) # 80004078 <namei>
    80005938:	892a                	mv	s2,a0
    8000593a:	c905                	beqz	a0,8000596a <sys_open+0x13c>
    ilock(ip);
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	f86080e7          	jalr	-122(ra) # 800038c2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005944:	04491703          	lh	a4,68(s2)
    80005948:	4785                	li	a5,1
    8000594a:	f4f712e3          	bne	a4,a5,8000588e <sys_open+0x60>
    8000594e:	f4c42783          	lw	a5,-180(s0)
    80005952:	dba1                	beqz	a5,800058a2 <sys_open+0x74>
      iunlockput(ip);
    80005954:	854a                	mv	a0,s2
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	1ce080e7          	jalr	462(ra) # 80003b24 <iunlockput>
      end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	9b6080e7          	jalr	-1610(ra) # 80004314 <end_op>
      return -1;
    80005966:	54fd                	li	s1,-1
    80005968:	b76d                	j	80005912 <sys_open+0xe4>
      end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	9aa080e7          	jalr	-1622(ra) # 80004314 <end_op>
      return -1;
    80005972:	54fd                	li	s1,-1
    80005974:	bf79                	j	80005912 <sys_open+0xe4>
    iunlockput(ip);
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	1ac080e7          	jalr	428(ra) # 80003b24 <iunlockput>
    end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	994080e7          	jalr	-1644(ra) # 80004314 <end_op>
    return -1;
    80005988:	54fd                	li	s1,-1
    8000598a:	b761                	j	80005912 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000598c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005990:	04691783          	lh	a5,70(s2)
    80005994:	02f99223          	sh	a5,36(s3)
    80005998:	bf2d                	j	800058d2 <sys_open+0xa4>
    itrunc(ip);
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	034080e7          	jalr	52(ra) # 800039d0 <itrunc>
    800059a4:	bfb1                	j	80005900 <sys_open+0xd2>
      fileclose(f);
    800059a6:	854e                	mv	a0,s3
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	db8080e7          	jalr	-584(ra) # 80004760 <fileclose>
    iunlockput(ip);
    800059b0:	854a                	mv	a0,s2
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	172080e7          	jalr	370(ra) # 80003b24 <iunlockput>
    end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	95a080e7          	jalr	-1702(ra) # 80004314 <end_op>
    return -1;
    800059c2:	54fd                	li	s1,-1
    800059c4:	b7b9                	j	80005912 <sys_open+0xe4>

00000000800059c6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059c6:	7175                	addi	sp,sp,-144
    800059c8:	e506                	sd	ra,136(sp)
    800059ca:	e122                	sd	s0,128(sp)
    800059cc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	8c6080e7          	jalr	-1850(ra) # 80004294 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059d6:	08000613          	li	a2,128
    800059da:	f7040593          	addi	a1,s0,-144
    800059de:	4501                	li	a0,0
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	36a080e7          	jalr	874(ra) # 80002d4a <argstr>
    800059e8:	02054963          	bltz	a0,80005a1a <sys_mkdir+0x54>
    800059ec:	4681                	li	a3,0
    800059ee:	4601                	li	a2,0
    800059f0:	4585                	li	a1,1
    800059f2:	f7040513          	addi	a0,s0,-144
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	7fe080e7          	jalr	2046(ra) # 800051f4 <create>
    800059fe:	cd11                	beqz	a0,80005a1a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	124080e7          	jalr	292(ra) # 80003b24 <iunlockput>
  end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	90c080e7          	jalr	-1780(ra) # 80004314 <end_op>
  return 0;
    80005a10:	4501                	li	a0,0
}
    80005a12:	60aa                	ld	ra,136(sp)
    80005a14:	640a                	ld	s0,128(sp)
    80005a16:	6149                	addi	sp,sp,144
    80005a18:	8082                	ret
    end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	8fa080e7          	jalr	-1798(ra) # 80004314 <end_op>
    return -1;
    80005a22:	557d                	li	a0,-1
    80005a24:	b7fd                	j	80005a12 <sys_mkdir+0x4c>

0000000080005a26 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a26:	7135                	addi	sp,sp,-160
    80005a28:	ed06                	sd	ra,152(sp)
    80005a2a:	e922                	sd	s0,144(sp)
    80005a2c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	866080e7          	jalr	-1946(ra) # 80004294 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a36:	08000613          	li	a2,128
    80005a3a:	f7040593          	addi	a1,s0,-144
    80005a3e:	4501                	li	a0,0
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	30a080e7          	jalr	778(ra) # 80002d4a <argstr>
    80005a48:	04054a63          	bltz	a0,80005a9c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a4c:	f6c40593          	addi	a1,s0,-148
    80005a50:	4505                	li	a0,1
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	2b4080e7          	jalr	692(ra) # 80002d06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a5a:	04054163          	bltz	a0,80005a9c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a5e:	f6840593          	addi	a1,s0,-152
    80005a62:	4509                	li	a0,2
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	2a2080e7          	jalr	674(ra) # 80002d06 <argint>
     argint(1, &major) < 0 ||
    80005a6c:	02054863          	bltz	a0,80005a9c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a70:	f6841683          	lh	a3,-152(s0)
    80005a74:	f6c41603          	lh	a2,-148(s0)
    80005a78:	458d                	li	a1,3
    80005a7a:	f7040513          	addi	a0,s0,-144
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	776080e7          	jalr	1910(ra) # 800051f4 <create>
     argint(2, &minor) < 0 ||
    80005a86:	c919                	beqz	a0,80005a9c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	09c080e7          	jalr	156(ra) # 80003b24 <iunlockput>
  end_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	884080e7          	jalr	-1916(ra) # 80004314 <end_op>
  return 0;
    80005a98:	4501                	li	a0,0
    80005a9a:	a031                	j	80005aa6 <sys_mknod+0x80>
    end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	878080e7          	jalr	-1928(ra) # 80004314 <end_op>
    return -1;
    80005aa4:	557d                	li	a0,-1
}
    80005aa6:	60ea                	ld	ra,152(sp)
    80005aa8:	644a                	ld	s0,144(sp)
    80005aaa:	610d                	addi	sp,sp,160
    80005aac:	8082                	ret

0000000080005aae <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aae:	7135                	addi	sp,sp,-160
    80005ab0:	ed06                	sd	ra,152(sp)
    80005ab2:	e922                	sd	s0,144(sp)
    80005ab4:	e526                	sd	s1,136(sp)
    80005ab6:	e14a                	sd	s2,128(sp)
    80005ab8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aba:	ffffc097          	auipc	ra,0xffffc
    80005abe:	efe080e7          	jalr	-258(ra) # 800019b8 <myproc>
    80005ac2:	892a                	mv	s2,a0
  
  begin_op();
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	7d0080e7          	jalr	2000(ra) # 80004294 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005acc:	08000613          	li	a2,128
    80005ad0:	f6040593          	addi	a1,s0,-160
    80005ad4:	4501                	li	a0,0
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	274080e7          	jalr	628(ra) # 80002d4a <argstr>
    80005ade:	04054b63          	bltz	a0,80005b34 <sys_chdir+0x86>
    80005ae2:	f6040513          	addi	a0,s0,-160
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	592080e7          	jalr	1426(ra) # 80004078 <namei>
    80005aee:	84aa                	mv	s1,a0
    80005af0:	c131                	beqz	a0,80005b34 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	dd0080e7          	jalr	-560(ra) # 800038c2 <ilock>
  if(ip->type != T_DIR){
    80005afa:	04449703          	lh	a4,68(s1)
    80005afe:	4785                	li	a5,1
    80005b00:	04f71063          	bne	a4,a5,80005b40 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	e7e080e7          	jalr	-386(ra) # 80003984 <iunlock>
  iput(p->cwd);
    80005b0e:	15093503          	ld	a0,336(s2)
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	f6a080e7          	jalr	-150(ra) # 80003a7c <iput>
  end_op();
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	7fa080e7          	jalr	2042(ra) # 80004314 <end_op>
  p->cwd = ip;
    80005b22:	14993823          	sd	s1,336(s2)
  return 0;
    80005b26:	4501                	li	a0,0
}
    80005b28:	60ea                	ld	ra,152(sp)
    80005b2a:	644a                	ld	s0,144(sp)
    80005b2c:	64aa                	ld	s1,136(sp)
    80005b2e:	690a                	ld	s2,128(sp)
    80005b30:	610d                	addi	sp,sp,160
    80005b32:	8082                	ret
    end_op();
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	7e0080e7          	jalr	2016(ra) # 80004314 <end_op>
    return -1;
    80005b3c:	557d                	li	a0,-1
    80005b3e:	b7ed                	j	80005b28 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	fe2080e7          	jalr	-30(ra) # 80003b24 <iunlockput>
    end_op();
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	7ca080e7          	jalr	1994(ra) # 80004314 <end_op>
    return -1;
    80005b52:	557d                	li	a0,-1
    80005b54:	bfd1                	j	80005b28 <sys_chdir+0x7a>

0000000080005b56 <sys_exec>:

uint64
sys_exec(void)
{
    80005b56:	7145                	addi	sp,sp,-464
    80005b58:	e786                	sd	ra,456(sp)
    80005b5a:	e3a2                	sd	s0,448(sp)
    80005b5c:	ff26                	sd	s1,440(sp)
    80005b5e:	fb4a                	sd	s2,432(sp)
    80005b60:	f74e                	sd	s3,424(sp)
    80005b62:	f352                	sd	s4,416(sp)
    80005b64:	ef56                	sd	s5,408(sp)
    80005b66:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b68:	08000613          	li	a2,128
    80005b6c:	f4040593          	addi	a1,s0,-192
    80005b70:	4501                	li	a0,0
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	1d8080e7          	jalr	472(ra) # 80002d4a <argstr>
    return -1;
    80005b7a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b7c:	0c054a63          	bltz	a0,80005c50 <sys_exec+0xfa>
    80005b80:	e3840593          	addi	a1,s0,-456
    80005b84:	4505                	li	a0,1
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	1a2080e7          	jalr	418(ra) # 80002d28 <argaddr>
    80005b8e:	0c054163          	bltz	a0,80005c50 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b92:	10000613          	li	a2,256
    80005b96:	4581                	li	a1,0
    80005b98:	e4040513          	addi	a0,s0,-448
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	144080e7          	jalr	324(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ba4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ba8:	89a6                	mv	s3,s1
    80005baa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bac:	02000a13          	li	s4,32
    80005bb0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bb4:	00391513          	slli	a0,s2,0x3
    80005bb8:	e3040593          	addi	a1,s0,-464
    80005bbc:	e3843783          	ld	a5,-456(s0)
    80005bc0:	953e                	add	a0,a0,a5
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	0aa080e7          	jalr	170(ra) # 80002c6c <fetchaddr>
    80005bca:	02054a63          	bltz	a0,80005bfe <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bce:	e3043783          	ld	a5,-464(s0)
    80005bd2:	c3b9                	beqz	a5,80005c18 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bd4:	ffffb097          	auipc	ra,0xffffb
    80005bd8:	f20080e7          	jalr	-224(ra) # 80000af4 <kalloc>
    80005bdc:	85aa                	mv	a1,a0
    80005bde:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005be2:	cd11                	beqz	a0,80005bfe <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005be4:	6605                	lui	a2,0x1
    80005be6:	e3043503          	ld	a0,-464(s0)
    80005bea:	ffffd097          	auipc	ra,0xffffd
    80005bee:	0d4080e7          	jalr	212(ra) # 80002cbe <fetchstr>
    80005bf2:	00054663          	bltz	a0,80005bfe <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bf6:	0905                	addi	s2,s2,1
    80005bf8:	09a1                	addi	s3,s3,8
    80005bfa:	fb491be3          	bne	s2,s4,80005bb0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bfe:	10048913          	addi	s2,s1,256
    80005c02:	6088                	ld	a0,0(s1)
    80005c04:	c529                	beqz	a0,80005c4e <sys_exec+0xf8>
    kfree(argv[i]);
    80005c06:	ffffb097          	auipc	ra,0xffffb
    80005c0a:	df2080e7          	jalr	-526(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0e:	04a1                	addi	s1,s1,8
    80005c10:	ff2499e3          	bne	s1,s2,80005c02 <sys_exec+0xac>
  return -1;
    80005c14:	597d                	li	s2,-1
    80005c16:	a82d                	j	80005c50 <sys_exec+0xfa>
      argv[i] = 0;
    80005c18:	0a8e                	slli	s5,s5,0x3
    80005c1a:	fc040793          	addi	a5,s0,-64
    80005c1e:	9abe                	add	s5,s5,a5
    80005c20:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c24:	e4040593          	addi	a1,s0,-448
    80005c28:	f4040513          	addi	a0,s0,-192
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	194080e7          	jalr	404(ra) # 80004dc0 <exec>
    80005c34:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c36:	10048993          	addi	s3,s1,256
    80005c3a:	6088                	ld	a0,0(s1)
    80005c3c:	c911                	beqz	a0,80005c50 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c3e:	ffffb097          	auipc	ra,0xffffb
    80005c42:	dba080e7          	jalr	-582(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c46:	04a1                	addi	s1,s1,8
    80005c48:	ff3499e3          	bne	s1,s3,80005c3a <sys_exec+0xe4>
    80005c4c:	a011                	j	80005c50 <sys_exec+0xfa>
  return -1;
    80005c4e:	597d                	li	s2,-1
}
    80005c50:	854a                	mv	a0,s2
    80005c52:	60be                	ld	ra,456(sp)
    80005c54:	641e                	ld	s0,448(sp)
    80005c56:	74fa                	ld	s1,440(sp)
    80005c58:	795a                	ld	s2,432(sp)
    80005c5a:	79ba                	ld	s3,424(sp)
    80005c5c:	7a1a                	ld	s4,416(sp)
    80005c5e:	6afa                	ld	s5,408(sp)
    80005c60:	6179                	addi	sp,sp,464
    80005c62:	8082                	ret

0000000080005c64 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c64:	7139                	addi	sp,sp,-64
    80005c66:	fc06                	sd	ra,56(sp)
    80005c68:	f822                	sd	s0,48(sp)
    80005c6a:	f426                	sd	s1,40(sp)
    80005c6c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c6e:	ffffc097          	auipc	ra,0xffffc
    80005c72:	d4a080e7          	jalr	-694(ra) # 800019b8 <myproc>
    80005c76:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c78:	fd840593          	addi	a1,s0,-40
    80005c7c:	4501                	li	a0,0
    80005c7e:	ffffd097          	auipc	ra,0xffffd
    80005c82:	0aa080e7          	jalr	170(ra) # 80002d28 <argaddr>
    return -1;
    80005c86:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c88:	0e054063          	bltz	a0,80005d68 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c8c:	fc840593          	addi	a1,s0,-56
    80005c90:	fd040513          	addi	a0,s0,-48
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	dfc080e7          	jalr	-516(ra) # 80004a90 <pipealloc>
    return -1;
    80005c9c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c9e:	0c054563          	bltz	a0,80005d68 <sys_pipe+0x104>
  fd0 = -1;
    80005ca2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ca6:	fd043503          	ld	a0,-48(s0)
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	508080e7          	jalr	1288(ra) # 800051b2 <fdalloc>
    80005cb2:	fca42223          	sw	a0,-60(s0)
    80005cb6:	08054c63          	bltz	a0,80005d4e <sys_pipe+0xea>
    80005cba:	fc843503          	ld	a0,-56(s0)
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	4f4080e7          	jalr	1268(ra) # 800051b2 <fdalloc>
    80005cc6:	fca42023          	sw	a0,-64(s0)
    80005cca:	06054863          	bltz	a0,80005d3a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cce:	4691                	li	a3,4
    80005cd0:	fc440613          	addi	a2,s0,-60
    80005cd4:	fd843583          	ld	a1,-40(s0)
    80005cd8:	68a8                	ld	a0,80(s1)
    80005cda:	ffffc097          	auipc	ra,0xffffc
    80005cde:	9a0080e7          	jalr	-1632(ra) # 8000167a <copyout>
    80005ce2:	02054063          	bltz	a0,80005d02 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ce6:	4691                	li	a3,4
    80005ce8:	fc040613          	addi	a2,s0,-64
    80005cec:	fd843583          	ld	a1,-40(s0)
    80005cf0:	0591                	addi	a1,a1,4
    80005cf2:	68a8                	ld	a0,80(s1)
    80005cf4:	ffffc097          	auipc	ra,0xffffc
    80005cf8:	986080e7          	jalr	-1658(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cfc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cfe:	06055563          	bgez	a0,80005d68 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d02:	fc442783          	lw	a5,-60(s0)
    80005d06:	07e9                	addi	a5,a5,26
    80005d08:	078e                	slli	a5,a5,0x3
    80005d0a:	97a6                	add	a5,a5,s1
    80005d0c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d10:	fc042503          	lw	a0,-64(s0)
    80005d14:	0569                	addi	a0,a0,26
    80005d16:	050e                	slli	a0,a0,0x3
    80005d18:	9526                	add	a0,a0,s1
    80005d1a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d1e:	fd043503          	ld	a0,-48(s0)
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	a3e080e7          	jalr	-1474(ra) # 80004760 <fileclose>
    fileclose(wf);
    80005d2a:	fc843503          	ld	a0,-56(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	a32080e7          	jalr	-1486(ra) # 80004760 <fileclose>
    return -1;
    80005d36:	57fd                	li	a5,-1
    80005d38:	a805                	j	80005d68 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d3a:	fc442783          	lw	a5,-60(s0)
    80005d3e:	0007c863          	bltz	a5,80005d4e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d42:	01a78513          	addi	a0,a5,26
    80005d46:	050e                	slli	a0,a0,0x3
    80005d48:	9526                	add	a0,a0,s1
    80005d4a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d4e:	fd043503          	ld	a0,-48(s0)
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	a0e080e7          	jalr	-1522(ra) # 80004760 <fileclose>
    fileclose(wf);
    80005d5a:	fc843503          	ld	a0,-56(s0)
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	a02080e7          	jalr	-1534(ra) # 80004760 <fileclose>
    return -1;
    80005d66:	57fd                	li	a5,-1
}
    80005d68:	853e                	mv	a0,a5
    80005d6a:	70e2                	ld	ra,56(sp)
    80005d6c:	7442                	ld	s0,48(sp)
    80005d6e:	74a2                	ld	s1,40(sp)
    80005d70:	6121                	addi	sp,sp,64
    80005d72:	8082                	ret
	...

0000000080005d80 <kernelvec>:
    80005d80:	7111                	addi	sp,sp,-256
    80005d82:	e006                	sd	ra,0(sp)
    80005d84:	e40a                	sd	sp,8(sp)
    80005d86:	e80e                	sd	gp,16(sp)
    80005d88:	ec12                	sd	tp,24(sp)
    80005d8a:	f016                	sd	t0,32(sp)
    80005d8c:	f41a                	sd	t1,40(sp)
    80005d8e:	f81e                	sd	t2,48(sp)
    80005d90:	fc22                	sd	s0,56(sp)
    80005d92:	e0a6                	sd	s1,64(sp)
    80005d94:	e4aa                	sd	a0,72(sp)
    80005d96:	e8ae                	sd	a1,80(sp)
    80005d98:	ecb2                	sd	a2,88(sp)
    80005d9a:	f0b6                	sd	a3,96(sp)
    80005d9c:	f4ba                	sd	a4,104(sp)
    80005d9e:	f8be                	sd	a5,112(sp)
    80005da0:	fcc2                	sd	a6,120(sp)
    80005da2:	e146                	sd	a7,128(sp)
    80005da4:	e54a                	sd	s2,136(sp)
    80005da6:	e94e                	sd	s3,144(sp)
    80005da8:	ed52                	sd	s4,152(sp)
    80005daa:	f156                	sd	s5,160(sp)
    80005dac:	f55a                	sd	s6,168(sp)
    80005dae:	f95e                	sd	s7,176(sp)
    80005db0:	fd62                	sd	s8,184(sp)
    80005db2:	e1e6                	sd	s9,192(sp)
    80005db4:	e5ea                	sd	s10,200(sp)
    80005db6:	e9ee                	sd	s11,208(sp)
    80005db8:	edf2                	sd	t3,216(sp)
    80005dba:	f1f6                	sd	t4,224(sp)
    80005dbc:	f5fa                	sd	t5,232(sp)
    80005dbe:	f9fe                	sd	t6,240(sp)
    80005dc0:	d79fc0ef          	jal	ra,80002b38 <kerneltrap>
    80005dc4:	6082                	ld	ra,0(sp)
    80005dc6:	6122                	ld	sp,8(sp)
    80005dc8:	61c2                	ld	gp,16(sp)
    80005dca:	7282                	ld	t0,32(sp)
    80005dcc:	7322                	ld	t1,40(sp)
    80005dce:	73c2                	ld	t2,48(sp)
    80005dd0:	7462                	ld	s0,56(sp)
    80005dd2:	6486                	ld	s1,64(sp)
    80005dd4:	6526                	ld	a0,72(sp)
    80005dd6:	65c6                	ld	a1,80(sp)
    80005dd8:	6666                	ld	a2,88(sp)
    80005dda:	7686                	ld	a3,96(sp)
    80005ddc:	7726                	ld	a4,104(sp)
    80005dde:	77c6                	ld	a5,112(sp)
    80005de0:	7866                	ld	a6,120(sp)
    80005de2:	688a                	ld	a7,128(sp)
    80005de4:	692a                	ld	s2,136(sp)
    80005de6:	69ca                	ld	s3,144(sp)
    80005de8:	6a6a                	ld	s4,152(sp)
    80005dea:	7a8a                	ld	s5,160(sp)
    80005dec:	7b2a                	ld	s6,168(sp)
    80005dee:	7bca                	ld	s7,176(sp)
    80005df0:	7c6a                	ld	s8,184(sp)
    80005df2:	6c8e                	ld	s9,192(sp)
    80005df4:	6d2e                	ld	s10,200(sp)
    80005df6:	6dce                	ld	s11,208(sp)
    80005df8:	6e6e                	ld	t3,216(sp)
    80005dfa:	7e8e                	ld	t4,224(sp)
    80005dfc:	7f2e                	ld	t5,232(sp)
    80005dfe:	7fce                	ld	t6,240(sp)
    80005e00:	6111                	addi	sp,sp,256
    80005e02:	10200073          	sret
    80005e06:	00000013          	nop
    80005e0a:	00000013          	nop
    80005e0e:	0001                	nop

0000000080005e10 <timervec>:
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	e10c                	sd	a1,0(a0)
    80005e16:	e510                	sd	a2,8(a0)
    80005e18:	e914                	sd	a3,16(a0)
    80005e1a:	6d0c                	ld	a1,24(a0)
    80005e1c:	7110                	ld	a2,32(a0)
    80005e1e:	6194                	ld	a3,0(a1)
    80005e20:	96b2                	add	a3,a3,a2
    80005e22:	e194                	sd	a3,0(a1)
    80005e24:	4589                	li	a1,2
    80005e26:	14459073          	csrw	sip,a1
    80005e2a:	6914                	ld	a3,16(a0)
    80005e2c:	6510                	ld	a2,8(a0)
    80005e2e:	610c                	ld	a1,0(a0)
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	30200073          	mret
	...

0000000080005e3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e3a:	1141                	addi	sp,sp,-16
    80005e3c:	e422                	sd	s0,8(sp)
    80005e3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e40:	0c0007b7          	lui	a5,0xc000
    80005e44:	4705                	li	a4,1
    80005e46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e48:	c3d8                	sw	a4,4(a5)
}
    80005e4a:	6422                	ld	s0,8(sp)
    80005e4c:	0141                	addi	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plicinithart>:

void
plicinithart(void)
{
    80005e50:	1141                	addi	sp,sp,-16
    80005e52:	e406                	sd	ra,8(sp)
    80005e54:	e022                	sd	s0,0(sp)
    80005e56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b34080e7          	jalr	-1228(ra) # 8000198c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e60:	0085171b          	slliw	a4,a0,0x8
    80005e64:	0c0027b7          	lui	a5,0xc002
    80005e68:	97ba                	add	a5,a5,a4
    80005e6a:	40200713          	li	a4,1026
    80005e6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e72:	00d5151b          	slliw	a0,a0,0xd
    80005e76:	0c2017b7          	lui	a5,0xc201
    80005e7a:	953e                	add	a0,a0,a5
    80005e7c:	00052023          	sw	zero,0(a0)
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e88:	1141                	addi	sp,sp,-16
    80005e8a:	e406                	sd	ra,8(sp)
    80005e8c:	e022                	sd	s0,0(sp)
    80005e8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	afc080e7          	jalr	-1284(ra) # 8000198c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e98:	00d5179b          	slliw	a5,a0,0xd
    80005e9c:	0c201537          	lui	a0,0xc201
    80005ea0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ea2:	4148                	lw	a0,4(a0)
    80005ea4:	60a2                	ld	ra,8(sp)
    80005ea6:	6402                	ld	s0,0(sp)
    80005ea8:	0141                	addi	sp,sp,16
    80005eaa:	8082                	ret

0000000080005eac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	e426                	sd	s1,8(sp)
    80005eb4:	1000                	addi	s0,sp,32
    80005eb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	ad4080e7          	jalr	-1324(ra) # 8000198c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ec0:	00d5151b          	slliw	a0,a0,0xd
    80005ec4:	0c2017b7          	lui	a5,0xc201
    80005ec8:	97aa                	add	a5,a5,a0
    80005eca:	c3c4                	sw	s1,4(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6105                	addi	sp,sp,32
    80005ed4:	8082                	ret

0000000080005ed6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ed6:	1141                	addi	sp,sp,-16
    80005ed8:	e406                	sd	ra,8(sp)
    80005eda:	e022                	sd	s0,0(sp)
    80005edc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ede:	479d                	li	a5,7
    80005ee0:	06a7c963          	blt	a5,a0,80005f52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ee4:	00016797          	auipc	a5,0x16
    80005ee8:	11c78793          	addi	a5,a5,284 # 8001c000 <disk>
    80005eec:	00a78733          	add	a4,a5,a0
    80005ef0:	6789                	lui	a5,0x2
    80005ef2:	97ba                	add	a5,a5,a4
    80005ef4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ef8:	e7ad                	bnez	a5,80005f62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005efa:	00451793          	slli	a5,a0,0x4
    80005efe:	00018717          	auipc	a4,0x18
    80005f02:	10270713          	addi	a4,a4,258 # 8001e000 <disk+0x2000>
    80005f06:	6314                	ld	a3,0(a4)
    80005f08:	96be                	add	a3,a3,a5
    80005f0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f0e:	6314                	ld	a3,0(a4)
    80005f10:	96be                	add	a3,a3,a5
    80005f12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f1e:	6318                	ld	a4,0(a4)
    80005f20:	97ba                	add	a5,a5,a4
    80005f22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f26:	00016797          	auipc	a5,0x16
    80005f2a:	0da78793          	addi	a5,a5,218 # 8001c000 <disk>
    80005f2e:	97aa                	add	a5,a5,a0
    80005f30:	6509                	lui	a0,0x2
    80005f32:	953e                	add	a0,a0,a5
    80005f34:	4785                	li	a5,1
    80005f36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f3a:	00018517          	auipc	a0,0x18
    80005f3e:	0de50513          	addi	a0,a0,222 # 8001e018 <disk+0x2018>
    80005f42:	ffffc097          	auipc	ra,0xffffc
    80005f46:	47e080e7          	jalr	1150(ra) # 800023c0 <wakeup>
}
    80005f4a:	60a2                	ld	ra,8(sp)
    80005f4c:	6402                	ld	s0,0(sp)
    80005f4e:	0141                	addi	sp,sp,16
    80005f50:	8082                	ret
    panic("free_desc 1");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	84e50513          	addi	a0,a0,-1970 # 800087a0 <syscalls+0x330>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	84e50513          	addi	a0,a0,-1970 # 800087b0 <syscalls+0x340>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>

0000000080005f72 <virtio_disk_init>:
{
    80005f72:	1101                	addi	sp,sp,-32
    80005f74:	ec06                	sd	ra,24(sp)
    80005f76:	e822                	sd	s0,16(sp)
    80005f78:	e426                	sd	s1,8(sp)
    80005f7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f7c:	00003597          	auipc	a1,0x3
    80005f80:	84458593          	addi	a1,a1,-1980 # 800087c0 <syscalls+0x350>
    80005f84:	00018517          	auipc	a0,0x18
    80005f88:	1a450513          	addi	a0,a0,420 # 8001e128 <disk+0x2128>
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	bc8080e7          	jalr	-1080(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f94:	100017b7          	lui	a5,0x10001
    80005f98:	4398                	lw	a4,0(a5)
    80005f9a:	2701                	sext.w	a4,a4
    80005f9c:	747277b7          	lui	a5,0x74727
    80005fa0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fa4:	0ef71163          	bne	a4,a5,80006086 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	43dc                	lw	a5,4(a5)
    80005fae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fb0:	4705                	li	a4,1
    80005fb2:	0ce79a63          	bne	a5,a4,80006086 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fb6:	100017b7          	lui	a5,0x10001
    80005fba:	479c                	lw	a5,8(a5)
    80005fbc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fbe:	4709                	li	a4,2
    80005fc0:	0ce79363          	bne	a5,a4,80006086 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fc4:	100017b7          	lui	a5,0x10001
    80005fc8:	47d8                	lw	a4,12(a5)
    80005fca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fcc:	554d47b7          	lui	a5,0x554d4
    80005fd0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fd4:	0af71963          	bne	a4,a5,80006086 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd8:	100017b7          	lui	a5,0x10001
    80005fdc:	4705                	li	a4,1
    80005fde:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe0:	470d                	li	a4,3
    80005fe2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fe4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fe6:	c7ffe737          	lui	a4,0xc7ffe
    80005fea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    80005fee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ff0:	2701                	sext.w	a4,a4
    80005ff2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff4:	472d                	li	a4,11
    80005ff6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff8:	473d                	li	a4,15
    80005ffa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ffc:	6705                	lui	a4,0x1
    80005ffe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006000:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006004:	5bdc                	lw	a5,52(a5)
    80006006:	2781                	sext.w	a5,a5
  if(max == 0)
    80006008:	c7d9                	beqz	a5,80006096 <virtio_disk_init+0x124>
  if(max < NUM)
    8000600a:	471d                	li	a4,7
    8000600c:	08f77d63          	bgeu	a4,a5,800060a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006010:	100014b7          	lui	s1,0x10001
    80006014:	47a1                	li	a5,8
    80006016:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006018:	6609                	lui	a2,0x2
    8000601a:	4581                	li	a1,0
    8000601c:	00016517          	auipc	a0,0x16
    80006020:	fe450513          	addi	a0,a0,-28 # 8001c000 <disk>
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	cbc080e7          	jalr	-836(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000602c:	00016717          	auipc	a4,0x16
    80006030:	fd470713          	addi	a4,a4,-44 # 8001c000 <disk>
    80006034:	00c75793          	srli	a5,a4,0xc
    80006038:	2781                	sext.w	a5,a5
    8000603a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000603c:	00018797          	auipc	a5,0x18
    80006040:	fc478793          	addi	a5,a5,-60 # 8001e000 <disk+0x2000>
    80006044:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006046:	00016717          	auipc	a4,0x16
    8000604a:	03a70713          	addi	a4,a4,58 # 8001c080 <disk+0x80>
    8000604e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006050:	00017717          	auipc	a4,0x17
    80006054:	fb070713          	addi	a4,a4,-80 # 8001d000 <disk+0x1000>
    80006058:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000605a:	4705                	li	a4,1
    8000605c:	00e78c23          	sb	a4,24(a5)
    80006060:	00e78ca3          	sb	a4,25(a5)
    80006064:	00e78d23          	sb	a4,26(a5)
    80006068:	00e78da3          	sb	a4,27(a5)
    8000606c:	00e78e23          	sb	a4,28(a5)
    80006070:	00e78ea3          	sb	a4,29(a5)
    80006074:	00e78f23          	sb	a4,30(a5)
    80006078:	00e78fa3          	sb	a4,31(a5)
}
    8000607c:	60e2                	ld	ra,24(sp)
    8000607e:	6442                	ld	s0,16(sp)
    80006080:	64a2                	ld	s1,8(sp)
    80006082:	6105                	addi	sp,sp,32
    80006084:	8082                	ret
    panic("could not find virtio disk");
    80006086:	00002517          	auipc	a0,0x2
    8000608a:	74a50513          	addi	a0,a0,1866 # 800087d0 <syscalls+0x360>
    8000608e:	ffffa097          	auipc	ra,0xffffa
    80006092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006096:	00002517          	auipc	a0,0x2
    8000609a:	75a50513          	addi	a0,a0,1882 # 800087f0 <syscalls+0x380>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	76a50513          	addi	a0,a0,1898 # 80008810 <syscalls+0x3a0>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>

00000000800060b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060b6:	7159                	addi	sp,sp,-112
    800060b8:	f486                	sd	ra,104(sp)
    800060ba:	f0a2                	sd	s0,96(sp)
    800060bc:	eca6                	sd	s1,88(sp)
    800060be:	e8ca                	sd	s2,80(sp)
    800060c0:	e4ce                	sd	s3,72(sp)
    800060c2:	e0d2                	sd	s4,64(sp)
    800060c4:	fc56                	sd	s5,56(sp)
    800060c6:	f85a                	sd	s6,48(sp)
    800060c8:	f45e                	sd	s7,40(sp)
    800060ca:	f062                	sd	s8,32(sp)
    800060cc:	ec66                	sd	s9,24(sp)
    800060ce:	e86a                	sd	s10,16(sp)
    800060d0:	1880                	addi	s0,sp,112
    800060d2:	892a                	mv	s2,a0
    800060d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060d6:	00c52c83          	lw	s9,12(a0)
    800060da:	001c9c9b          	slliw	s9,s9,0x1
    800060de:	1c82                	slli	s9,s9,0x20
    800060e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060e4:	00018517          	auipc	a0,0x18
    800060e8:	04450513          	addi	a0,a0,68 # 8001e128 <disk+0x2128>
    800060ec:	ffffb097          	auipc	ra,0xffffb
    800060f0:	af8080e7          	jalr	-1288(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060f8:	00016b97          	auipc	s7,0x16
    800060fc:	f08b8b93          	addi	s7,s7,-248 # 8001c000 <disk>
    80006100:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006102:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006104:	8a4e                	mv	s4,s3
    80006106:	a051                	j	8000618a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006108:	00fb86b3          	add	a3,s7,a5
    8000610c:	96da                	add	a3,a3,s6
    8000610e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006112:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006114:	0207c563          	bltz	a5,8000613e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006118:	2485                	addiw	s1,s1,1
    8000611a:	0711                	addi	a4,a4,4
    8000611c:	25548063          	beq	s1,s5,8000635c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006120:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006122:	00018697          	auipc	a3,0x18
    80006126:	ef668693          	addi	a3,a3,-266 # 8001e018 <disk+0x2018>
    8000612a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000612c:	0006c583          	lbu	a1,0(a3)
    80006130:	fde1                	bnez	a1,80006108 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006132:	2785                	addiw	a5,a5,1
    80006134:	0685                	addi	a3,a3,1
    80006136:	ff879be3          	bne	a5,s8,8000612c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000613a:	57fd                	li	a5,-1
    8000613c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000613e:	02905a63          	blez	s1,80006172 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006142:	f9042503          	lw	a0,-112(s0)
    80006146:	00000097          	auipc	ra,0x0
    8000614a:	d90080e7          	jalr	-624(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    8000614e:	4785                	li	a5,1
    80006150:	0297d163          	bge	a5,s1,80006172 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006154:	f9442503          	lw	a0,-108(s0)
    80006158:	00000097          	auipc	ra,0x0
    8000615c:	d7e080e7          	jalr	-642(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    80006160:	4789                	li	a5,2
    80006162:	0097d863          	bge	a5,s1,80006172 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006166:	f9842503          	lw	a0,-104(s0)
    8000616a:	00000097          	auipc	ra,0x0
    8000616e:	d6c080e7          	jalr	-660(ra) # 80005ed6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006172:	00018597          	auipc	a1,0x18
    80006176:	fb658593          	addi	a1,a1,-74 # 8001e128 <disk+0x2128>
    8000617a:	00018517          	auipc	a0,0x18
    8000617e:	e9e50513          	addi	a0,a0,-354 # 8001e018 <disk+0x2018>
    80006182:	ffffc097          	auipc	ra,0xffffc
    80006186:	0b2080e7          	jalr	178(ra) # 80002234 <sleep>
  for(int i = 0; i < 3; i++){
    8000618a:	f9040713          	addi	a4,s0,-112
    8000618e:	84ce                	mv	s1,s3
    80006190:	bf41                	j	80006120 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006192:	20058713          	addi	a4,a1,512
    80006196:	00471693          	slli	a3,a4,0x4
    8000619a:	00016717          	auipc	a4,0x16
    8000619e:	e6670713          	addi	a4,a4,-410 # 8001c000 <disk>
    800061a2:	9736                	add	a4,a4,a3
    800061a4:	4685                	li	a3,1
    800061a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061aa:	20058713          	addi	a4,a1,512
    800061ae:	00471693          	slli	a3,a4,0x4
    800061b2:	00016717          	auipc	a4,0x16
    800061b6:	e4e70713          	addi	a4,a4,-434 # 8001c000 <disk>
    800061ba:	9736                	add	a4,a4,a3
    800061bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061c4:	7679                	lui	a2,0xffffe
    800061c6:	963e                	add	a2,a2,a5
    800061c8:	00018697          	auipc	a3,0x18
    800061cc:	e3868693          	addi	a3,a3,-456 # 8001e000 <disk+0x2000>
    800061d0:	6298                	ld	a4,0(a3)
    800061d2:	9732                	add	a4,a4,a2
    800061d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061d6:	6298                	ld	a4,0(a3)
    800061d8:	9732                	add	a4,a4,a2
    800061da:	4541                	li	a0,16
    800061dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061de:	6298                	ld	a4,0(a3)
    800061e0:	9732                	add	a4,a4,a2
    800061e2:	4505                	li	a0,1
    800061e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061e8:	f9442703          	lw	a4,-108(s0)
    800061ec:	6288                	ld	a0,0(a3)
    800061ee:	962a                	add	a2,a2,a0
    800061f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061f4:	0712                	slli	a4,a4,0x4
    800061f6:	6290                	ld	a2,0(a3)
    800061f8:	963a                	add	a2,a2,a4
    800061fa:	05890513          	addi	a0,s2,88
    800061fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006200:	6294                	ld	a3,0(a3)
    80006202:	96ba                	add	a3,a3,a4
    80006204:	40000613          	li	a2,1024
    80006208:	c690                	sw	a2,8(a3)
  if(write)
    8000620a:	140d0063          	beqz	s10,8000634a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000620e:	00018697          	auipc	a3,0x18
    80006212:	df26b683          	ld	a3,-526(a3) # 8001e000 <disk+0x2000>
    80006216:	96ba                	add	a3,a3,a4
    80006218:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000621c:	00016817          	auipc	a6,0x16
    80006220:	de480813          	addi	a6,a6,-540 # 8001c000 <disk>
    80006224:	00018517          	auipc	a0,0x18
    80006228:	ddc50513          	addi	a0,a0,-548 # 8001e000 <disk+0x2000>
    8000622c:	6114                	ld	a3,0(a0)
    8000622e:	96ba                	add	a3,a3,a4
    80006230:	00c6d603          	lhu	a2,12(a3)
    80006234:	00166613          	ori	a2,a2,1
    80006238:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000623c:	f9842683          	lw	a3,-104(s0)
    80006240:	6110                	ld	a2,0(a0)
    80006242:	9732                	add	a4,a4,a2
    80006244:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006248:	20058613          	addi	a2,a1,512
    8000624c:	0612                	slli	a2,a2,0x4
    8000624e:	9642                	add	a2,a2,a6
    80006250:	577d                	li	a4,-1
    80006252:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006256:	00469713          	slli	a4,a3,0x4
    8000625a:	6114                	ld	a3,0(a0)
    8000625c:	96ba                	add	a3,a3,a4
    8000625e:	03078793          	addi	a5,a5,48
    80006262:	97c2                	add	a5,a5,a6
    80006264:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006266:	611c                	ld	a5,0(a0)
    80006268:	97ba                	add	a5,a5,a4
    8000626a:	4685                	li	a3,1
    8000626c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000626e:	611c                	ld	a5,0(a0)
    80006270:	97ba                	add	a5,a5,a4
    80006272:	4809                	li	a6,2
    80006274:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006278:	611c                	ld	a5,0(a0)
    8000627a:	973e                	add	a4,a4,a5
    8000627c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006280:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006284:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006288:	6518                	ld	a4,8(a0)
    8000628a:	00275783          	lhu	a5,2(a4)
    8000628e:	8b9d                	andi	a5,a5,7
    80006290:	0786                	slli	a5,a5,0x1
    80006292:	97ba                	add	a5,a5,a4
    80006294:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006298:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000629c:	6518                	ld	a4,8(a0)
    8000629e:	00275783          	lhu	a5,2(a4)
    800062a2:	2785                	addiw	a5,a5,1
    800062a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ac:	100017b7          	lui	a5,0x10001
    800062b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062b4:	00492703          	lw	a4,4(s2)
    800062b8:	4785                	li	a5,1
    800062ba:	02f71163          	bne	a4,a5,800062dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062be:	00018997          	auipc	s3,0x18
    800062c2:	e6a98993          	addi	s3,s3,-406 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800062c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062c8:	85ce                	mv	a1,s3
    800062ca:	854a                	mv	a0,s2
    800062cc:	ffffc097          	auipc	ra,0xffffc
    800062d0:	f68080e7          	jalr	-152(ra) # 80002234 <sleep>
  while(b->disk == 1) {
    800062d4:	00492783          	lw	a5,4(s2)
    800062d8:	fe9788e3          	beq	a5,s1,800062c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062dc:	f9042903          	lw	s2,-112(s0)
    800062e0:	20090793          	addi	a5,s2,512
    800062e4:	00479713          	slli	a4,a5,0x4
    800062e8:	00016797          	auipc	a5,0x16
    800062ec:	d1878793          	addi	a5,a5,-744 # 8001c000 <disk>
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062f6:	00018997          	auipc	s3,0x18
    800062fa:	d0a98993          	addi	s3,s3,-758 # 8001e000 <disk+0x2000>
    800062fe:	00491713          	slli	a4,s2,0x4
    80006302:	0009b783          	ld	a5,0(s3)
    80006306:	97ba                	add	a5,a5,a4
    80006308:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000630c:	854a                	mv	a0,s2
    8000630e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006312:	00000097          	auipc	ra,0x0
    80006316:	bc4080e7          	jalr	-1084(ra) # 80005ed6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000631a:	8885                	andi	s1,s1,1
    8000631c:	f0ed                	bnez	s1,800062fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000631e:	00018517          	auipc	a0,0x18
    80006322:	e0a50513          	addi	a0,a0,-502 # 8001e128 <disk+0x2128>
    80006326:	ffffb097          	auipc	ra,0xffffb
    8000632a:	972080e7          	jalr	-1678(ra) # 80000c98 <release>
}
    8000632e:	70a6                	ld	ra,104(sp)
    80006330:	7406                	ld	s0,96(sp)
    80006332:	64e6                	ld	s1,88(sp)
    80006334:	6946                	ld	s2,80(sp)
    80006336:	69a6                	ld	s3,72(sp)
    80006338:	6a06                	ld	s4,64(sp)
    8000633a:	7ae2                	ld	s5,56(sp)
    8000633c:	7b42                	ld	s6,48(sp)
    8000633e:	7ba2                	ld	s7,40(sp)
    80006340:	7c02                	ld	s8,32(sp)
    80006342:	6ce2                	ld	s9,24(sp)
    80006344:	6d42                	ld	s10,16(sp)
    80006346:	6165                	addi	sp,sp,112
    80006348:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000634a:	00018697          	auipc	a3,0x18
    8000634e:	cb66b683          	ld	a3,-842(a3) # 8001e000 <disk+0x2000>
    80006352:	96ba                	add	a3,a3,a4
    80006354:	4609                	li	a2,2
    80006356:	00c69623          	sh	a2,12(a3)
    8000635a:	b5c9                	j	8000621c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000635c:	f9042583          	lw	a1,-112(s0)
    80006360:	20058793          	addi	a5,a1,512
    80006364:	0792                	slli	a5,a5,0x4
    80006366:	00016517          	auipc	a0,0x16
    8000636a:	d4250513          	addi	a0,a0,-702 # 8001c0a8 <disk+0xa8>
    8000636e:	953e                	add	a0,a0,a5
  if(write)
    80006370:	e20d11e3          	bnez	s10,80006192 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006374:	20058713          	addi	a4,a1,512
    80006378:	00471693          	slli	a3,a4,0x4
    8000637c:	00016717          	auipc	a4,0x16
    80006380:	c8470713          	addi	a4,a4,-892 # 8001c000 <disk>
    80006384:	9736                	add	a4,a4,a3
    80006386:	0a072423          	sw	zero,168(a4)
    8000638a:	b505                	j	800061aa <virtio_disk_rw+0xf4>

000000008000638c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000638c:	1101                	addi	sp,sp,-32
    8000638e:	ec06                	sd	ra,24(sp)
    80006390:	e822                	sd	s0,16(sp)
    80006392:	e426                	sd	s1,8(sp)
    80006394:	e04a                	sd	s2,0(sp)
    80006396:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006398:	00018517          	auipc	a0,0x18
    8000639c:	d9050513          	addi	a0,a0,-624 # 8001e128 <disk+0x2128>
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	844080e7          	jalr	-1980(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063a8:	10001737          	lui	a4,0x10001
    800063ac:	533c                	lw	a5,96(a4)
    800063ae:	8b8d                	andi	a5,a5,3
    800063b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063b6:	00018797          	auipc	a5,0x18
    800063ba:	c4a78793          	addi	a5,a5,-950 # 8001e000 <disk+0x2000>
    800063be:	6b94                	ld	a3,16(a5)
    800063c0:	0207d703          	lhu	a4,32(a5)
    800063c4:	0026d783          	lhu	a5,2(a3)
    800063c8:	06f70163          	beq	a4,a5,8000642a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063cc:	00016917          	auipc	s2,0x16
    800063d0:	c3490913          	addi	s2,s2,-972 # 8001c000 <disk>
    800063d4:	00018497          	auipc	s1,0x18
    800063d8:	c2c48493          	addi	s1,s1,-980 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800063dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063e0:	6898                	ld	a4,16(s1)
    800063e2:	0204d783          	lhu	a5,32(s1)
    800063e6:	8b9d                	andi	a5,a5,7
    800063e8:	078e                	slli	a5,a5,0x3
    800063ea:	97ba                	add	a5,a5,a4
    800063ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063ee:	20078713          	addi	a4,a5,512
    800063f2:	0712                	slli	a4,a4,0x4
    800063f4:	974a                	add	a4,a4,s2
    800063f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063fa:	e731                	bnez	a4,80006446 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063fc:	20078793          	addi	a5,a5,512
    80006400:	0792                	slli	a5,a5,0x4
    80006402:	97ca                	add	a5,a5,s2
    80006404:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006406:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000640a:	ffffc097          	auipc	ra,0xffffc
    8000640e:	fb6080e7          	jalr	-74(ra) # 800023c0 <wakeup>

    disk.used_idx += 1;
    80006412:	0204d783          	lhu	a5,32(s1)
    80006416:	2785                	addiw	a5,a5,1
    80006418:	17c2                	slli	a5,a5,0x30
    8000641a:	93c1                	srli	a5,a5,0x30
    8000641c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006420:	6898                	ld	a4,16(s1)
    80006422:	00275703          	lhu	a4,2(a4)
    80006426:	faf71be3          	bne	a4,a5,800063dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000642a:	00018517          	auipc	a0,0x18
    8000642e:	cfe50513          	addi	a0,a0,-770 # 8001e128 <disk+0x2128>
    80006432:	ffffb097          	auipc	ra,0xffffb
    80006436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
}
    8000643a:	60e2                	ld	ra,24(sp)
    8000643c:	6442                	ld	s0,16(sp)
    8000643e:	64a2                	ld	s1,8(sp)
    80006440:	6902                	ld	s2,0(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret
      panic("virtio_disk_intr status");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	3ea50513          	addi	a0,a0,1002 # 80008830 <syscalls+0x3c0>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
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
